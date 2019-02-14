require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
