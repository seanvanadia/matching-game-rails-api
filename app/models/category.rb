# frozen_string_literal: true

# Category Model
class Category < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :images

  default_scope { order(created_at: :asc) }

  validates :title, presence: true, length: { in: 1..60 }
end
