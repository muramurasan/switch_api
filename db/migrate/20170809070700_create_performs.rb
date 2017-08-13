class CreatePerforms < ActiveRecord::Migration[5.0]
  def change
    create_table :performs do |t|
      t.string :service_name, null: false, index: true
      t.datetime :next_notify_at, null: false
      t.datetime :next_down_report_at, null: false
      t.datetime :next_survival_report_at, null: false

      t.timestamps
    end
  end
end
