# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept
# cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow origins declared in environment files
    origins Rails.application.config.allowed_cors_origins

    # Allow CRUD methods for resources
    resource '*',
             headers: :any,
             methods: %i[post get put delete]
  end
end
