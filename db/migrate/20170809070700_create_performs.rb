class CreatePerforms < ActiveRecord::Migration[5.0]
  def change
    create_table :performs do |t|
      t.string :service_name, null: false, index: true
      t.datetime :next_check_at, null: false

      t.timestamps
    end
  end
end
