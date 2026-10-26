class CreateTickets < ActiveRecord::Migration[6.0]
  def change
    create_table :tickets do |t|
      t.string :ticket_number
      t.string :title
      t.text :description
      t.references :requester, null: false, foreign_key: true
      t.references :assignee, null: false, foreign_key: true
      t.string :priority
      t.string :status
      t.text :resolution_summary
      t.datetime :resolved_at
      t.datetime :closed_at

      t.timestamps
    end
  end
end
