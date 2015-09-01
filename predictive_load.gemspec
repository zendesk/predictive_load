Gem::Specification.new do |gem|
  gem.authors       = ["Eric Chapweske"]
  gem.email         = ["eac@zendesk.com"]
  gem.description   = "Predictive loader"
  gem.summary       = %q{}
  gem.homepage      = ""
  gem.license       = "Apache License Version 2.0"

  gem.files         = `git ls-files lib README.md LICENSE`.split($\)
  gem.name          = "predictive_load"
  gem.version       = '0.1.2'
  gem.add_development_dependency "activerecord", ">= 3.2.0", "< 4.0.0"
end
