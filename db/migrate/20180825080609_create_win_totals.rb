# frozen_string_literal: true

class CreateWinTotals < ActiveRecord::Migration[5.1]
  def change
    create_table :win_totals do |t|
      t.integer :total

      t.timestamps
    end
  end
end
