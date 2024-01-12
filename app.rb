# frozen_string_literal: true

require 'rdkafka'
require 'sinatra'
require 'json'
require 'active_support'
require 'tempfile'

KAFKA_TOPIC = ENV.fetch('KAFKA_TOPIC', 'messages')
GROUP_ID = ENV.fetch('KAFKA_CONSUMER_GROUP', 'heroku-kafka-demo')

def initialize_kafka
  tmp_ca_file = Tempfile.new('ca_certs')
  tmp_ca_file.write(ENV.fetch('KAFKA_TRUSTED_CERT'))
  tmp_ca_file.close

  $producer = Rdkafka::Config.new({
    :"bootstrap.servers" => ENV.fetch('KAFKA_URL').gsub('kafka+ssl://', ''),
    :"security.protocol" => "ssl",
    :"ssl.ca.location" => tmp_ca_file.path,
    :"ssl.key.pem" => ENV.fetch('KAFKA_CLIENT_CERT_KEY'),
    :"ssl.certificate.pem" => ENV.fetch('KAFKA_CLIENT_CERT'),
    :"enable.ssl.certificate.verification" => false,
  }).producer

  # Connect a consumer. Consumers in Kafka have a "group" id, which
  # denotes how consumers balance work. Each group coordinates
  # which partitions to process between its nodes.
  # For the demo app, there's only one group, but a production app
  # could use separate groups for e.g. processing events and archiving
  # raw events to S3 for longer term storage
  $consumer = Rdkafka::Config.new({
    :"bootstrap.servers" => ENV.fetch('KAFKA_URL').gsub('kafka+ssl://', ''),
    :"security.protocol" => "ssl",
    :"ssl.ca.location" => tmp_ca_file.path,
    :"ssl.key.pem" => ENV.fetch('KAFKA_CLIENT_CERT_KEY'),
    :"ssl.certificate.pem" => ENV.fetch('KAFKA_CLIENT_CERT'),
    :"enable.ssl.certificate.verification" => false,
    :"group.id" => GROUP_ID,
  }).consumer

  $recent_messages = []
  start_consumer

  at_exit do
    $producer.close
    tmp_ca_file.unlink
  end
end

get '/' do
  erb :index
end

# This endpoint accesses in memory state gathered
# by the consumer, which holds the last 10 messages received
get '/messages' do
  content_type :json
  $recent_messages.map do |message, metadata|
    {
      offset: message.offset,
      partition: message.partition,
      message: message.value,
      topic: message.topic,
      metadata: metadata
    }
  end.to_json
end

# A sample producer endpoint.
# It receives messages as http bodies on /messages,
# and posts them directly to a Kafka topic.
post '/messages' do
  if request.body.size.positive?
    request.body.rewind
    message = request.body.read
    $producer.produce(payload: message, topic: KAFKA_TOPIC).wait
    "received_message: #{message}"
  else
    status 400
    body 'message was empty'
  end
end

# The consumer subscribes to the topic, and keeps the last 10 messages
# received in memory, so the webapp can send them back over the api.
#
# Consumer group management in Kafka means that this app won't work correctly
# if you run more than one dyno - Kafka will balance out the consumed partition
# between processes, and the web API will return reads from arbitrary workers,
# which will be incorrect.
def start_consumer
  Thread.new do
    $consumer.subscribe(KAFKA_TOPIC)
    begin
      $consumer.each do |message|
        $recent_messages << [message, {received_at: Time.now.iso8601}]
        $recent_messages.shift if $recent_messages.length > 10
        puts "consumer received message! local message count: #{$recent_messages.size} offset=#{message.offset}"
      end
    rescue Exception => e
      puts 'CONSUMER ERROR'
      puts "#{e}\n#{e.backtrace.join("\n")}"
      exit(1)
    end
  end
end
