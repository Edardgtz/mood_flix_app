class CreateEntities < ActiveRecord::Migration[6.0]
  def change
    create_table :entities do |t|
      t.string :title_id
      t.string :entity_name
      t.string :entity_type

      t.timestamps
    end
  end
end
