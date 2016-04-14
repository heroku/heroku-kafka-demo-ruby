workers Integer(ENV['WEB_CONCURRENCY'] || 1)
threads 1, 1 # until we've confirmed Poseidon is thread safe

preload_app!

on_worker_boot do
  initialize_kafka
end

port ENV['PORT'] || 9292
environment ENV['RACK_ENV'] || 'development'
