# frozen_string_literal: true

module Api
  module V1
    # V1 Application Controller
    class ApplicationController < ActionController::API
      # Application controller will handle token authentication
      # for the user model. Devise fallback is disabled for security purposes.
      acts_as_token_authentication_handler_for User, fallback: :none

      # When called, log the user out if their session has timed out
      def logout_if_timedout
        # Make sessions timeout after 30 minutes without a request
        return unless
        current_user.last_seen_at && Time.now - current_user.last_seen_at > 1800

        current_user.last_seen_at = nil
        current_user&.authentication_token = nil

        # If successful signout...
        if current_user.save
          render_timeout_logout_json

        # If error during signout...
        else
          head(:bad_request)
        end
      end

      private

      def render_timeout_logout_json
        render json:
          {
            errors: ['Your session expired. Please sign in again to continue.']
          },
               status: 401
      end
    end
  end
end
