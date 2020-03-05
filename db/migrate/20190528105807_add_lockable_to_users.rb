# frozen_string_literal: true

class AddLockableToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :signin_locked, :boolean, default: false
    add_column :users, :locked_at, :datetime
  end
end
