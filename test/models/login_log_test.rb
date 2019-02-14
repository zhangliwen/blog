require 'test_helper'

class LoginLogTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: login_logs
#
#  id         :bigint(8)        not null, primary key
#  ip         :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint(8)
#
# Indexes
#
#  index_login_logs_on_user_id  (user_id)
#
