class CreateReviewTopics < ActiveRecord::Migration[7.2]
  def change
    create_table :review_topics do |t|
      t.references :review, null: false, foreign_key: true
      t.references :topic,  null: false, foreign_key: true

      t.timestamps
    end
    add_index :review_topics, [ :review_id, :topic_id ], unique: true
  end
end
