require "./lib/predictive_load/version"

Gem::Specification.new do |gem|
  gem.authors = ["Eric Chapweske"]
  gem.email = ["eac@zendesk.com"]
  gem.description = "Predictive loader"
  gem.summary = ""
  gem.homepage = "https://github.com/zendesk/predictive_load"
  gem.license = "Apache License Version 2.0"

  gem.files = `git ls-files lib README.md LICENSE`.split($\)
  gem.name = "predictive_load"
  gem.version = PredictiveLoad::VERSION

  gem.add_runtime_dependency "activerecord", ">= 7.1"
  gem.required_ruby_version = ">= 3.3"
end
