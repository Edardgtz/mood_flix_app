class AddSentimentScoreToMoods < ActiveRecord::Migration[6.0]
  def change
    add_column :moods, :sentiment_score, :decimal, :precision => 20, :scale => 15 
  end
end
