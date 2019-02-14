class CreateComments < ActiveRecord::Migration[5.2]
  def change
    create_table :comments do |t|
      t.references :article
      t.references :user
      t.string :content

      t.timestamps
    end
  end
end
