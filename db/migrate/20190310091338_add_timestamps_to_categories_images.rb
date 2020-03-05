# frozen_string_literal: true

class AddTimestampsToCategoriesImages < ActiveRecord::Migration[5.1]
  def change
    add_column :categories_images, :created_at, :datetime
    add_column :categories_images, :updated_at, :datetime
  end
end
