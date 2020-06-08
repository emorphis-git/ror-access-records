require 'digest/sha1'

class User < Principal
  USER_FORMATS_STRUCTURE = {
    firstname_lastname:       [:firstname, :lastname],
    firstname:                [:firstname],
    lastname_firstname:       [:lastname, :firstname],
    lastname_coma_firstname:  [:lastname, :firstname],
    username:                 [:login]
  }.freeze


  validates_presence_of :login,
                        :firstname,
                        :lastname,
                        :mail,
                        unless: Proc.new { |user| user.is_a?(AnonymousUser) || user.is_a?(DeletedUser) || user.is_a?(SystemUser) }

  validates_uniqueness_of :login, if: Proc.new { |user| !user.login.blank? }, case_sensitive: false
  validates_uniqueness_of :mail, allow_blank: true, case_sensitive: false
  validates_format_of :login, with: /\A[a-z0-9_\-@\.+ ]*\z/i
  validates_length_of :login, maximum: 256
  validates_length_of :firstname, :lastname, maximum: 30
  validates_format_of :mail, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true
  validates_length_of :mail, maximum: 60, allow_nil: true
  validates_confirmation_of :password, allow_nil: true
 
  after_save :update_password
  scope :admin, -> { where(admin: true) }

  scope :newest, -> { not_builtin.order(created_on: :desc) }

  def current_password
    passwords.first
  end

  def password_expired?
    current_password.expired?
  end

  # create new password if password was set
  def update_password
    if password && auth_source_id.blank?
      new_password = passwords.build(type: UserPassword.active_type.to_s)
      new_password.plain_password = password
      new_password.save

      # force reload of passwords, so the new password is sorted to the top
      passwords.reload

      clean_up_former_passwords
    end
  end

  def admin; false end

  def allowed_to?(action, context, options = {})
    authorization_service.call(action, context, options).result
  end

  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password, session = nil)
    # Make sure no one can sign in with an empty password
    return nil if password.to_s.empty?
    user = find_by_login(login)
    user = if user
             try_authentication_for_existing_user(user, password, session)
           else
             try_authentication_and_create_user(login, password)
    end
    unless prevent_brute_force_attack(user, login).nil?
      user.log_successful_login if user && !user.new_record?
      return user
    end
    nil
  end

  def self.try_authentication_for_existing_user(user, password, session = nil)
    activate_user! user, session if session

    if user.auth_source
      return nil unless user.auth_source.authenticate(user.login, password)
    else
      return nil unless user.check_password?(password)
      return nil if user.force_password_change
      return nil if user.password_expired?
    end
    user
  end

  def self.activate_user!(user, session)
    if session[:invitation_token]
      token = Token::Invitation.find_by_plaintext_value session[:invitation_token]
      invited_id = token&.user&.id

      if user.id == invited_id
        user.activate!
        token.destroy
        session.delete :invitation_token
      end
    end
  end

  def self.try_to_autologin(key)
    token = Token::AutoLogin.find_by_plaintext_value(key)
    # Make sure there's only 1 token that matches the key
    if token
      if (token.created_on > Setting.autologin.to_i.day.ago) && token.user && token.user.active?
        token.user.log_successful_login
        token.user
      end
    end
  end

  # Formats the user's name.
  def name(formatter = nil)
    case formatter || Setting.user_format

    when :firstname_lastname      then "#{firstname} #{lastname}"
    when :lastname_firstname      then "#{lastname} #{firstname}"
    when :lastname_coma_firstname then "#{lastname}, #{firstname}"
    when :firstname               then firstname
    when :username                then login

    else
      "#{firstname} #{lastname}"
    end
  end

  def status_name
    STATUSES.keys[status].to_s
  end

  def activate
    self.status = STATUSES[:active]
  end

  def register
    self.status = STATUSES[:registered]
  end

  
  def check_password?(clear_password, update_legacy: true)
    if auth_source_id.present?
      auth_source.authenticate(login, clear_password)
    else
      return false if current_password.nil?
      current_password.matches_plaintext?(clear_password, update_legacy: update_legacy)
    end
  end

  def log_failed_login
    log_failed_login_count
    log_failed_login_timestamp
    save
  end

  def log_successful_login
    update_attribute(:last_login_on, Time.now)
  end

  
end
