# frozen_string_literal: true

module Api
  module V1
    # V1 Win Total Controller
    class WinTotalController < ApplicationController
      before_action :authenticate_user!
      before_action :logout_if_timedout
      before_action :set_win_total

      def index
        render json: @win_total
      end

      def update
        # If the win total is successfully updated...
        if @win_total.update_attributes(win_total_params)
          render json: @win_total, status: :ok

        # If there was an error updating the win total...
        else
          render json: { errors: @win_total.errors.full_messages }, status: 400
        end
      end

      private

      def set_win_total
        @win_total = current_user.win_total
      end

      def win_total_params
        params.permit(:total)
      end
    end
  end
end
