# frozen_string_literal: true

class CreateJoinTableImageCategory < ActiveRecord::Migration[5.1]
  def change
    create_join_table :images, :categories do |t|
      t.index %i[image_id category_id]
      t.index %i[category_id image_id]
    end
  end
end
