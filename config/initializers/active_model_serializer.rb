# frozen_string_literal: true

# Accept data as json even if it does not include an indicative header
Mime::Type.register 'application/json', :json
