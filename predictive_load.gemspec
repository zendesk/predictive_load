Gem::Specification.new do |gem|
  gem.authors = ["Eric Chapweske"]
  gem.email = ["eac@zendesk.com"]
  gem.description = "Predictive loader"
  gem.summary = ""
  gem.homepage = "https://github.com/zendesk/predictive_load"
  gem.license = "Apache License Version 2.0"

  gem.files = `git ls-files lib README.md LICENSE`.split($\)
  gem.name = "predictive_load"
  gem.version = "0.9.0"

  gem.add_runtime_dependency "activerecord", ">= 7.0", "< 7.2"
  gem.required_ruby_version = ">= 3.3"
end
