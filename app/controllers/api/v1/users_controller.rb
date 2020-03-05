# frozen_string_literal: true

module Api
  module V1
    # V1 Users Controller
    class UsersController < ApplicationController
      before_action :authenticate_user!, only: :destroy
      before_action :logout_if_timedout, only: :destroy

      # Signup
      def create
        # Create a new win total equal to zero for the new user
        win_total = WinTotal.new(total: 0)

        # Create the new user based on the submitted email and password
        @user = User.new(
          email: params[:email],
          password: params[:password],
          win_total: win_total
        )

        # If the signup is successful...
        if @user.save
          render json: @user

        # If there is an error during signup...
        else
          render json: { errors: @user.errors.full_messages }, status: 422
        end
      end

      # Destroy User
      def destroy
        destroy_user_data_obj = destroy_all_user_data

        # If all destroy requests were successful...
        if destroy_user_data_obj[:all_destroyed]
          head(:ok)
        else

          # If there were errors during the destroy requests,
          # render the errors as json...
          render json:
            destroy_user_data_obj[:destroy_reqs].map(&:errors),
                 status: 400
        end
      end

      private

      def destroy_all_user_data
        user = current_user
        destroy_reqs = []
        all_destroyed = true # Set to true initially as a reference point
        user_atts = [user.categories, user.images, user.win_total, user]

        # Destroy user's categories, images, win_total, and the user itself
        user_atts.each_with_index do |att, i|
          next unless att

          destroy_req = i.zero? || i == 1 ? att.destroy_all : att.destroy
          destroy_reqs << destroy_req
          all_destroyed &&= destroy_req
        end

        { all_destroyed: all_destroyed, destroy_reqs: destroy_reqs }
      end
    end
  end
end
