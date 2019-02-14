module UserSecure
  extend ActiveSupport::Concern
  included do
    attr_reader :password
    validates_length_of :password, minimum: 8, allow_blank: false, allow_nil: true
    validates_confirmation_of :password, if: -> { password.present? }

    PASSWORD_SPLIT = '$'.freeze

    class << self
    end

    def authenticate(unencrypted_password)
      encrypted_password(unencrypted_password, password_salt) == self.password_digest.split(PASSWORD_SPLIT)[0] && self
    end

    def password=(unencrypted_password)
      if unencrypted_password.nil?
        self.password_digest = nil
      elsif unencrypted_password.present?
        @password            = unencrypted_password
        salt                 = SecureRandom.hex(6)
        self.password_digest = "#{encrypted_password(unencrypted_password, salt)}#{PASSWORD_SPLIT}#{salt}"
      end
    end

    def password_confirmation=(unencrypted_password)
      @password_confirmation = unencrypted_password
    end


    def password_salt
      self.password_digest.split(PASSWORD_SPLIT)[1]
    end

    def encrypted_password(unencrypted_password, salt)
      Digest::SHA256.hexdigest("#{unencrypted_password}#{salt}")
    end
  end
end
