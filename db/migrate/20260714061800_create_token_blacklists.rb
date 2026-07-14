# frozen_string_literal: true

# Stores JWT IDs (jti) that have been logged out so they cannot be reused.
class CreateTokenBlacklists < ActiveRecord::Migration[8.1]
  def change
    create_table :token_blacklists do |t|
      t.string :jti, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :token_blacklists, :jti, unique: true
  end
end
