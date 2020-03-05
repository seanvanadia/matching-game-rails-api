# frozen_string_literal: true

ruby '2.6.3', patchlevel: '62'

source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'
# Use postgreSQL as the database for Active Record
gem 'pg', '~> 1.1', '>= 1.1.4'
# Use Puma as the app server
gem 'puma', '~> 4.1'
# Provide CORS support for the application
gem 'rack-cors', '~> 1.0', '>= 1.0.3'
# Use active model serializers to serialize application data
gem 'active_model_serializers', '~> 0.10.10'
# Use paperclip for image handling
gem 'paperclip', '~> 6.1'
# Use AWS S3 for image storage
gem 'aws-sdk-s3', '~> 1.46'
# Use devise and simple_token_authentication for authentcation
gem 'devise', '~> 4.7'
gem 'simple_token_authentication', '~> 1.16'
# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', '~> 1.2019', '>= 1.2019.2'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution
  # and get a debugger console
  gem 'byebug', '~> 11.0', '>= 11.0.1', platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Listen listens to file modifications and notifies you about the changes
  gem 'listen', '~> 3.1', '>= 3.1.5'
  # Brakeman detects security vulnerabilities in Ruby on Rails applications
  gem 'brakeman', '~> 4.6', '>= 4.6.1'
  # Rubocop is an automatic Ruby code style checking tool
  gem 'rubocop', '~> 0.74.0'
  # Spring speeds up development by keeping your application
  # running in the background
  gem 'spring', '~> 2.1'
  # Spring watcher listen makes spring watch files using the listen gem
  gem 'spring-watcher-listen', '~> 2.0', '>= 2.0.1'
end
