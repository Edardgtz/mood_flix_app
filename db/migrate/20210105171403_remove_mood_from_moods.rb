class RemoveMoodFromMoods < ActiveRecord::Migration[6.0]
  def change
    remove_column :moods, :mood, :string
  end
end
