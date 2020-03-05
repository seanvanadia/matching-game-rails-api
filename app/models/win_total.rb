# frozen_string_literal: true

# Win Total Model
class WinTotal < ApplicationRecord
  belongs_to :user

  validates :total, presence: true,
                    numericality: {
                      only_integer: true,
                      greater_than_or_equal_to: 0,
                      less_than_or_equal_to: 100_000_000
                    }
end
