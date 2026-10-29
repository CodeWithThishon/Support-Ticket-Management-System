class CreateTicketActivities < ActiveRecord::Migration[6.0]
  def change
    create_table :ticket_activities do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.text :details

      t.timestamps
    end
  end
end
