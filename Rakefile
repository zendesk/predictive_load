require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"

desc "Format code"
task :fmt do
  sh "rubocop --auto-correct"
end

Rake::TestTask.new(:test) do |test|
  test.pattern = "test/*_test.rb"
  test.verbose = true
end

task default: [:test, :fmt]
