# frozen_string_literal: true

# Category Serializer
class CategorySerializer < ActiveModel::Serializer
  attributes :id, :created_at, :title
  has_many :images

  def images
    # If a page of images has been requested,
    # render the page of the user's images
    if @instance_options[:start_index]
      object.images[@instance_options[:start_index], @instance_options[:num_imgs]]

    # If specific indexes have been requested, render the imgs_arr
    elsif @instance_options[:img_indexes]
      imgs_arr

    # Else render all the user's images
    else
      object.images
    end
  end

  private

  def imgs_arr
    arr = []

    # Define the array of specific images requested
    @instance_options[:img_indexes].each do |img_index|
      arr.push(object.images[img_index.to_i])
    end

    # Return the array
    arr
  end
end
