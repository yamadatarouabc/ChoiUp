class CreateReviews < ActiveRecord::Migration[7.2]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :material, null: false, foreign_key: true
      t.integer :start_level, null: false
      t.integer :difficulty_rating, null: false
      t.text :comment
      
      t.timestamps
    end

    # 同じユーザーが同じ教材に複数回評価できないようにする
    add_index :reviews, [ :user_id, :material_id ], unique: true
  end
end
