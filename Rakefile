require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"
require "bump/tasks"
require "standard/rake"

task lint: :standard

Rake::TestTask.new(:test) do |test|
  test.pattern = "test/*_test.rb"
  test.verbose = true
end

task default: [:test, :lint]
