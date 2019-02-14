require 'test_helper'

class ArticleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: articles
#
#  id            :bigint(8)        not null, primary key
#  comment_count :integer          default(0)
#  content       :text
#  like_count    :integer          default(0)
#  secret_key    :string
#  title         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :bigint(8)
#
# Indexes
#
#  index_articles_on_user_id  (user_id)
#
