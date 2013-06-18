# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../lib/', __FILE__))
require 'yonce/version'

Gem::Specification.new do |s|
  s.name        = 'yonce'
  s.version     = Yonce::VERSION
  s.homepage    = 'http://example.com/'
  s.summary     = 'All the single ladies!'
  s.description = 'All the single ladies!'

  s.author  = 'Denis Defreyne'
  s.email   = 'denis.defreyne@stoneship.org'
  s.license = 'MIT'

  s.required_ruby_version = '>= 1.9.3'

  s.files              = Dir['[A-Z]*'] +
                         Dir['{bin,lib,tasks,test}/**/*'] +
                         [ 'yonce.gemspec' ]
  s.executables        = [ 'yonce' ]
  s.require_paths      = [ 'lib' ]
end
