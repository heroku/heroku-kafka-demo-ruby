require 'kafka'
require 'sinatra'
require 'json'

KAFKA_TOPIC = "messages"
GROUP_ID = 'heroku-kafka-demo'

KAFKA = Kafka.new(
  seed_brokers: ENV.fetch("KAFKA_URL"),
  ssl_ca_cert: ENV.fetch("KAFKA_TRUSTED_CERT"),
  ssl_client_cert: ENV.fetch("KAFKA_CLIENT_CERT"),
  ssl_client_cert_key: ENV.fetch("KAFKA_CLIENT_CERT_KEY"),
)
PRODUCER = KAFKA.async_producer
CONSUMER = KAFKA.consumer(group_id: GROUP_ID)

RECENT_MESSAGES = []

at_exit { PRODUCER.shutdown }

get '/' do
  erb :index
end

get '/messages' do
  RECENT_MESSAGES.map do |message|
    message.value
  end.to_json
end

post '/messages' do
  PRODUCER.produce(body, topic: KAFKA_TOPIC)
  "received_message"
end

# For the purposes of this demo, just run the consumer inside the web dyno.
# In a real app, this would be in a separate process.
Thread.new do
  CONSUMER.subscribe(KAFKA_TOPIC)
  begin
    CONSUMER.each_message do |message|
      RECENT_MESSAGES << message
      RECENT_MESSAGES.sort_by! {|m| -message.offset}
      RECENT_MESSAGES.take(10)
      puts "received message!"
    end
  rescue => e
    puts "#{e}\n#{e.backtrace.join("\n")}"
  end
end
