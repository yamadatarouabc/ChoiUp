class CreateMaterials < ActiveRecord::Migration[7.2]
  def change
    create_table :materials do |t|
      t.string :title, null: false, limit: 100
      t.string :url, null: false
      t.text :description, limit: 65535

      t.timestamps
    end

    add_index :materials, :url
  end
end
