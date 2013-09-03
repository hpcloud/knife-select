# -*- encoding: utf-8 -*-
require File.expand_path('../lib/knife-select/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jon-Paul Sullivan"]
  gem.email         = ["jonpaul.sullivan@hp.com"]
  gem.summary       = "Knife plugin for selecting chef server to interact with"
  gem.description   = gem.summary
  gem.homepage      = "http://www.hpcloud.com"
  gem.license       = "Apache 2.0"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "knife-select"
  gem.require_paths = ["lib"]
  gem.version       = Knife::Select::VERSION
end
