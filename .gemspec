# -*- encoding: utf-8 -*-
require './version'
 
Gem::Specification.new do |s|
  s.name        = "opinionated"
  s.version     = Reamaze::Opinionated::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Lu Wang"]
  s.email       = ["lwang@reamaze.com"]
  s.homepage    = "http://github.com/lunaru/opinionated"
  s.summary     = "Adds defaults and a sensible interface to activerecord-postgres-hstore"

  s.required_rubygems_version = ">= 1.3.6"
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(MIT-LICENSE README.md Gemfile Rakefile)
  s.require_path = 'lib'

  s.add_dependency 'rails', '>= 4.0.0'
end
