class ChangeTopicsTopicGroupIdToNotNull < ActiveRecord::Migration[8.1]
  def change
    change_column_null :topics, :topic_group_id, false
  end
end
