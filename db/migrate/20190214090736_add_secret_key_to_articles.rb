class AddSecretKeyToArticles < ActiveRecord::Migration[5.2]
  def change
    add_column :articles, :secret_key, :string
  end
end
