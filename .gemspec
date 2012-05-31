# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'version'
 
Gem::Specification.new do |s|
  s.name        = "opinionated"
  s.version     = Reamaze::Opinionated::VERSION::STRING
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Lu Wang"]
  s.email       = ["lwang@reamaze.com"]
  s.homepage    = "http://github.com/lunaru/opinionated"
  s.summary     = "Adds defaults and a sensible interface to activerecord-postgres-hstore"

  s.required_rubygems_version = ">= 1.3.6"
 
  s.files        = Dir.glob("{bin,lib}/**/*") + %w(MIT-LICENSE README.md Gemfile Gemfile.lock Rakefile)
  s.require_path = 'lib'
end