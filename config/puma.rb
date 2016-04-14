workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads 1, 1 # until we've confirmed Poseidon is thread safe

preload_app!

port ENV['PORT'] || 9292
environment ENV['RACK_ENV'] || 'development'
