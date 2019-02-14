class CreateArticles < ActiveRecord::Migration[5.2]
  def change
    create_table :articles do |t|
      t.references :user
      t.string :title
      t.text :content
      t.integer :comment_count, default: 0
      t.integer :like_count, default: 0

      t.timestamps
    end
  end
end
