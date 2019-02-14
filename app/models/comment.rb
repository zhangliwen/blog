class Comment < ApplicationRecord
  belongs_to :article
  belongs_to :user
  after_create :update_article_comment_count

  def update_article_comment_count
    article.update_columns(comment_count: article.comment_count + 1)
  end

end

# == Schema Information
#
# Table name: comments
#
#  id         :bigint(8)        not null, primary key
#  content    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint(8)
#  user_id    :bigint(8)
#
# Indexes
#
#  index_comments_on_article_id  (article_id)
#  index_comments_on_user_id     (user_id)
#
