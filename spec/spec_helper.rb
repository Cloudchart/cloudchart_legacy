# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rspec'
require 'database_cleaner'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include Capybara::DSL
  config.include FactoryGirl::Syntax::Methods
  config.include JsonSpec::Helpers
  config.include Devise::TestHelpers
  # config.order = "random"
  
  Capybara.javascript_driver = :webkit
  DatabaseCleaner.strategy = :truncation
  
  config.before(:each) do
    DatabaseCleaner.clean
    Rails.logger.debug "\n\n-- Started example: #{example.metadata[:full_description]}\n"
    
    case Capybara.current_driver
    when :selenium
      Capybara.current_session.driver.browser.manage.window.resize_to(1424, 900)
    when :webkit
      Capybara.current_session.driver.resize_window(1424, 900)
    end
  end
  
  config.after(:each) do
    Rails.logger.debug "\n\n-- Finished example: #{example.metadata[:full_description]}\n"
  end
end
