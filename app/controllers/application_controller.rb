class ApplicationController < ActionController::Base

  protected
  layout 'base'

  def current_user
    User.current
  end
  helper_method :current_user

  def user_setup
    User.current = find_current_user
  end

  def find_current_user
    if session[:user_id]
      User.active.find_by(id: session[:user_id])
    end
  end

  def logged_user=(user)
    reset_session
    if user&.is_a?(User)
      User.current = user
    else
      User.current = User.anonymous
    end
  end

  def check_if_login_required
    return true if User.current.logged?
    require_login if Setting.login_required?
  end
  
  def escape_for_logging(string)
    string.gsub(/[^0-9a-zA-Z@._\-"\'!\?=\/ ]{1}/, '#')
  end

  def require_login
    unless User.current.logged?
      reset_session
      respond_to do |format|
        format.any(:html, :atom) { redirect_to main_app.signin_path(back_url: login_back_url) }
        format.any(:xml, :js, :json) do
          head :unauthorized,
               'X-Reason' => 'login needed',
               'WWW-Authenticate' => auth_header
        end
        format.all { head :not_acceptable }
      end
      return false
    end
    true
  end

  def require_admin
    return unless require_login
    render_403 unless User.current.admin?
  end

  def deny_access(not_found: false)
    if User.current.logged?
      not_found ? render_404 : render_403
    else
      require_login
    end
  end

  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    context = @project || @projects
    is_authorized = AuthorizationService.new({ controller: ctrl, action: action }, context: context, global: global).call

    unless is_authorized
      if @project && @project.archived?
        render_403 message: :notice_not_authorized_archived_project
      else
        deny_access
      end
    end
    is_authorized
  end
  
  def back_url
    params[:back_url] || request.env['HTTP_REFERER']
  end
  
  def use_layout
    request.xhr? ? false : 'no_menu'
  end

  def render_feed(items, options = {})
    @items = items || []
    @items = @items.sort { |x, y| y.event_datetime <=> x.event_datetime }
    @items = @items.slice(0, Setting.feeds_limit.to_i)
    @title = options[:title] || Setting.app_title
    render template: 'common/feed', layout: false, content_type: 'application/atom+xml'
  end

  def default_breadcrumb
    name = l('label_' + self.class.name.gsub('Controller', '').underscore.singularize + '_plural')
    if name =~ /translation missing/i
      name = l('label_' + self.class.name.gsub('Controller', '').underscore.singularize)
    end
    name
  end
  helper_method :default_breadcrumb

  
  private

  def login_back_url
    if request.get?
      url_for(login_back_url_params)
    else
      url_params = params.permit(:action, :id, :project_id, :controller)

      unless url_params[:controller].to_s.starts_with?('/')
        url_params[:controller] = "/#{url_params[:controller]}"
      end

      url_for(url_params)
    end
  end

end
