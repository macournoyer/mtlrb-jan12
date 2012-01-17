require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << '.'
  t.libs << 'test'
  t.pattern = 'test/**_test.rb'
end

task :default => :test

task :complete do
  sh "git co complete -- mio.rb mio/*.rb"
end