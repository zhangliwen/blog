class Article < ApplicationRecord
  belongs_to :user
  has_many :comments
  after_create :update_secret_key

  def update_secret_key
    update_columns(secret_key: Digest::MD5.hexdigest("#{self.id}-#{self.created_at.to_s}"))
  end

  def content_format
    ActionView::Base.full_sanitizer.sanitize(content)
  end

  def picture_url
    c = content.match(/\/\/[^\s]*(jpg|gif|png)/)
    c.present? ? c.to_s : nil
  end
end

# == Schema Information
#
# Table name: articles
#
#  id            :bigint(8)        not null, primary key
#  comment_count :integer          default(0)
#  content       :text
#  like_count    :integer          default(0)
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint(8)
#
# Indexes
#
#  index_articles_on_user_id  (user_id)
#
