class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :name
      t.string :mobile
      t.text :description
      t.string :avatar

      t.string :password_digest
      t.string :last_ip
      t.datetime :last_login_at

      t.timestamps
    end
  end
end
