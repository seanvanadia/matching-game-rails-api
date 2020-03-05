# frozen_string_literal: true

# Image Serializer (without categories)
class ImageWithoutCategoriesSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :image, :image_file_name, :updated_at
end
