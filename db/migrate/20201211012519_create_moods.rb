class CreateMoods < ActiveRecord::Migration[6.0]
  def change
    create_table :moods do |t|
      t.string :mood
      t.string :title_id

      t.timestamps
    end
  end
end
