class CreateTopicGroups < ActiveRecord::Migration[8.1]
  def up
    create_table :topic_groups do |t|
      t.string :name, null: false, limit: 50
      t.timestamps
    end
    add_index :topic_groups, :name, unique: true

    add_reference :topics, :topic_group, foreign_key: { on_delete: :restrict }

    execute <<~SQL
      INSERT INTO topic_groups (name, created_at, updated_at)
        SELECT name, NOW(), NOW() FROM topics
    SQL

    execute <<~SQL
      UPDATE topics SET topic_group_id = topic_groups.id
        FROM topic_groups WHERE topics.name = topic_groups.name
    SQL
  end

  def down
    remove_reference :topics, :topic_group, foreign_key: true
    drop_table :topic_groups
  end
end
