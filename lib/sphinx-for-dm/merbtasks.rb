namespace :sphinx do
  desc 'Start Sphinx Server'
  task :start do
    p 'Starting...'
    system('cd config; searchd; cd ..')
  end

  desc 'Stop Sphinx Server'
  task :stop do
    p 'Stopping...'
    system('cd config; searchd --stop; cd ..')
  end

  desc 'Restart Sphinx Server'
  task :restart do
    p 'Restarting...'
    system('cd config; searchd --stop; searchd; cd ..')
  end

  desc 'Index Sphinx Server'
  task :index do
    p 'Indexing...'
    system('cd config; indexer --quiet --all; cd ..')
  end

  desc 'Reindex Sphinx Server'
  task :reindex do
    p 'Reindexing...'
    system('cd config; indexer --rotate --quiet --all; cd ..')
  end
end
