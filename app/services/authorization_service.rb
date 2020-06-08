class AuthorizationService
  def initialize(permission, context: nil, global: false, user: User.current)
    @permission = permission
    @context = context
    @global = global
    @user = user
  end

  def call
    @user.allowed_to?(@permission, @context, global: @global)
  end
end
