# frozen_string_literal: true

module Api
  module V1
    # V1 Sessions Controller
    class SessionsController < ApplicationController
      before_action :authenticate_user!, only: :destroy
      before_action :logout_if_timedout, except: :create

      # Signin
      def create
        @user = User.where(email: params[:email]).first

        # Renew authentication token on each signin (to forbid
        # simultaneous multiple device signin)
        if @user&.authentication_token
          @user.update_attribute(:authentication_token, nil)
          @user.save
        end

        # If the user's signin capabilities are locked...
        if @user&.signin_locked
          # If the user's signin capabilities have been locked for
          # less than 1 hour...
          if Time.now - @user.locked_at < 3600
            # Render the signin locked error and do not execute the remainder
            # of the method's code
            render_signin_locked_error && return

          # If the user's signin capabilities have been locked for 1 hour or
          # more, allow the user to reattempt signin
          else
            @user.update_attributes(
              signin_locked: false, locked_at: nil, failed_attempts: 0
            )
          end

        end

        # If successful signin...
        if @user&.valid_password?(params[:password])
          # Reset the number of failed attempts to zero
          # if it is not already zero
          @user.update_attribute(:failed_attempts, 0) if @user.failed_attempts != 0

          # Update the last_seen_at attribute
          @user.update_attribute(:last_seen_at, Time.now)

          # Render the user
          render json: @user, status: 201

        # If the submitted user credentials are incorrect...
        else
          # If the submitted email address is that of an existing user...
          if @user
            # Count the submission as a failed login attempt
            @user.update_attribute(:failed_attempts, @user.failed_attempts + 1)

            # If the user has now entered an incorrect password four times,
            # render an error message to warn the user that they
            # only have one attempt remaining
            if @user.failed_attempts == 4
              render(
                json: { errors:
                  'You have one more attempt before your account is locked.' },
                status: 401
              ) && return
            end

            # If the user has now entered an incorrect password five times...
            if @user.failed_attempts == 5
              # Lock the user's signin capabilities
              @user.update_attributes(signin_locked: true, locked_at: Time.now)

              # Render the signin locked error and do not execute
              # the remainder of the method's code
              render_signin_locked_error && return
            end

          end

          # If the submitted user credentials are incorrect,
          # and the user's signin capabilities are not currently locked,
          # render an appropriate error message and unauthorized status code
          render json: { errors:
            'The user information you entered was incorrect.
            Please try again.' },
                 status: 401
        end
      end

      def update
        # Refresh the user's last_seen_at attribute for session timeout purposes
        current_user&.update_attribute(:last_seen_at, Time.now)

        head(:ok)
      end

      # Signout
      def destroy
        current_user.last_seen_at = nil
        current_user&.authentication_token = nil

        # If successful signout...
        if current_user.save
          head(:ok)

        # If error during signout...
        else
          head(:bad_request)
        end
      end

      private

      def render_signin_locked_error
        render json: {
          errors: 'Your account is locked.'
        },
               status: 401
      end
    end
  end
end
