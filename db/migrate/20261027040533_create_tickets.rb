class CreateTickets < ActiveRecord::Migration[6.0]
  def change
    create_table :tickets do |t|
      t.string :ticket_number, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.references :requester, null: false, foreign_key: {to_table: :users}
      t.references :assignee, foreign_key: { to_table: :users }
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "open"
      t.text :resolution_summary
      t.datetime :resolved_at
      t.datetime :closed_at

      t.timestamps
    end
    add_index :tickets, :ticket_number, unique: true
  end
end
