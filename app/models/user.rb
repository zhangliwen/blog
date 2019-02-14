class User < ApplicationRecord
  include UserSecure
  has_many :login_logs
  has_many :articles
  has_many :comments
  has_many :article_likes

  def sign
    Digest::MD5.hexdigest(password_digest)
  end

  def name
    super || mobile
  end

end

# == Schema Information
#
# Table name: users
#
#  id              :bigint(8)        not null, primary key
#  avatar          :string
#  description     :text
#  last_ip         :string
#  last_login_at   :datetime
#  mobile          :string
#  name            :string
#  password_digest :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
