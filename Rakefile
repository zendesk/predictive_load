require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"

# Pushing to rubygems is handled by a github workflow
ENV['gem_push'] = 'false'

desc "Format code"
task :fmt do
  sh "rubocop --auto-correct"
end

Rake::TestTask.new(:test) do |test|
  test.pattern = "test/*_test.rb"
  test.verbose = true
end

task default: [:test, :fmt]
