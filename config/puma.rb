workers 1
threads 1, 1

preload_app!

on_worker_boot do
  initialize_kafka
end

port(ENV.fetch("PORT") { 3000 }, "::")
environment ENV['RACK_ENV'] || 'development'
