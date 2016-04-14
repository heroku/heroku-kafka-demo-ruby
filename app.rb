require 'kafka'
require 'sinatra'
require 'json'
require 'active_support/notifications'

KAFKA_TOPIC = "messages"
GROUP_ID = 'heroku-kafka-demo'

def initialize_kafka
  $kafka = Kafka.new(
    seed_brokers: ENV.fetch("KAFKA_URL"),
    ssl_ca_cert: ENV.fetch("KAFKA_TRUSTED_CERT"),
    ssl_client_cert: ENV.fetch("KAFKA_CLIENT_CERT"),
    ssl_client_cert_key: ENV.fetch("KAFKA_CLIENT_CERT_KEY"),
  )
  $producer = $kafka.async_producer(delivery_interval: 1)
  $consumer = $kafka.consumer(group_id: GROUP_ID)
  $recent_messages = []
  start_consumer
  start_metrics

  at_exit { $producer.shutdown }
end

get '/' do
  erb :index
end

get '/messages' do
  $recent_messages.map do |message|
    {
      partition: message.partition,
      offset: message.offset,
      value: message.value
    }
  end.to_json
end

post '/messages' do
  if request.body.size > 0
    request.body.rewind
    message = request.body.read
    $producer.produce(message, topic: KAFKA_TOPIC)
    "received_message: #{message}"
  else
    status 400
    "message was empty"
  end
end

def start_consumer
  Thread.new do
    $consumer.subscribe(KAFKA_TOPIC)
    begin
      $consumer.each_message do |message|
        $recent_messages << message
        $recent_message.shift
        puts "consumer received message! local message count: #{$recent_messages.size} offset=#{message.offset} recent_offsets=#{$recent_messages.map(&:offset).join(',')}"
      end
    rescue => e
      puts "#{e}\n#{e.backtrace.join("\n")}"
    end
  end
end

def start_metrics
  Thread.new do
    ActiveSupport::Notifications.subscribe(/.*\.kafka$/) do |*args|
      event = ActiveSupport::Notifications::Event.new(*args)
      formatted = event.payload.map {|k,v| "#{k}=#{v}"}.join(' ')
      puts "at=#{event.name} #{formatted}"
    end
  end
end
