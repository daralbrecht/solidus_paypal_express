# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'spree_paypal_express/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_paypal_express'
  s.version     = SpreePayPalExpress::VERSION
  s.summary     = 'Adds PayPal Express as a Payment Method to Spree Commerce'
  s.description = s.summary
  s.required_ruby_version = '>= 1.9.3'

  s.author       = 'Spree Commerce'
  s.email        = 'gems@spreecommerce.com'
  s.homepage     = 'http://www.spreecommerce.com'
  s.license      = %q{BSD-3}

  s.files        = `git ls-files`.split("\n")
  s.test_files   = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'solidus_core', '~> 1.0'
  s.add_dependency 'paypal-sdk-rest', '1.4.3'

  s.add_development_dependency 'solidus', '~> 1.0'
  s.add_development_dependency 'solidus_auth_devise', '~> 1.2'
  s.add_development_dependency 'solidus_sample', '~> 1.0'

  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'show_me_the_cookies', '~> 3.1.0'
  s.add_development_dependency 'capybara', '~> 2.6.2'
  s.add_development_dependency 'database_cleaner', '1.5.1'
  s.add_development_dependency 'factory_girl', '~> 4.5.0'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails', '~> 3.4.2'
  s.add_development_dependency 'rspec-activemodel-mocks', '~> 1.0.3'
  s.add_development_dependency 'sass-rails', '~> 5.0.4'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'
  s.add_development_dependency 'better_errors'
  s.add_development_dependency 'binding_of_caller'

  s.add_development_dependency 'pry-rails'
  s.add_development_dependency 'pry-stack_explorer'
  s.add_development_dependency 'awesome_print'
end
