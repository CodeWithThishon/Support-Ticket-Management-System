class AddPasswordResetToUsers < ActiveRecord::Migration[6.0]
  attr_accessor :reset_token
  def change
    add_column :users, :reset_digest, :string
    add_column :users, :reset_sent_at, :datetime
  end
end
