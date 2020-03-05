# frozen_string_literal: true

class AddUserIdToCategoriesImagesAndWinTotals < ActiveRecord::Migration[5.1]
  def change
    add_reference :categories, :user, index: true, foreign_key: true
    add_reference :images, :user, index: true, foreign_key: true
    add_reference :categories_images, :user, index: true, foreign_key: true
    add_reference :win_totals, :user, index: true, foreign_key: true
  end
end
