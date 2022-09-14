Gem::Specification.new do |gem|
  gem.authors       = ["Eric Chapweske"]
  gem.email         = ["eac@zendesk.com"]
  gem.description   = "Predictive loader"
  gem.summary       = %q{}
  gem.homepage      = "https://github.com/zendesk/predictive_load"
  gem.license       = "Apache License Version 2.0"

  gem.files         = `git ls-files lib README.md LICENSE`.split($\)
  gem.name          = "predictive_load"
  gem.version       = '0.5.1'

  gem.add_runtime_dependency "activerecord", ">= 4.2.0", "< 7.0"
  gem.required_ruby_version = ">= 2.4"
end
