class CreateLoginLogs < ActiveRecord::Migration[5.2]
  def change
    create_table :login_logs do |t|
      t.references :user
      t.string :ip

      t.timestamps
    end
  end
end
