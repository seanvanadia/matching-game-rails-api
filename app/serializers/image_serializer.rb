# frozen_string_literal: true

# Image Serializer
class ImageSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :image, :image_file_name, :updated_at
  has_many :categories
end
