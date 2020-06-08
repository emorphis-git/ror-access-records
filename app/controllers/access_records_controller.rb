class AccessRecordsController < ApplicationController
  include PaginationHelper
  layout :choose_layout
  include Concerns::Layout
  before_action :find_request_for_access
  before_action :find_access_record_object, except: %i[new create index]
  before_action :find_project_from_association, except: %i[new create index]
  before_action :find_project, only: %i[new create]
  before_action :authorize, except: [:index]
  before_action :find_optional_project, only: [:index]
  accept_key_auth :index
  before_action :require_admin

  def index
    if(check_path)
      scope = @project ? @project.access_records : AccessRecord.all
      @access_records = scope.merge(AccessRecord.latest_for(current_user, count: 0))
                    .page(page_param)
                    .per_page(per_page_param)

      respond_to do |format|
        format.html do
          render layout: layout_non_or_no_menu
        end
        format.atom do
          render_feed(@access_records,
                      title: (@project ? @project.name : Setting.app_title) + ": #{l(:label_client)}")
        end
      end
    else
      @access_records = ::AccessRecord.page(page_param).per_page(per_page_param) 
    end
  end

  current_menu_item :index do
    :access_records
  end

  def new
    @path = request.fullpath
    if(check_path)
      @access_record = AccessRecord.new(project: @project)
    else
      access_record = []
      @access_record = AccessRecord.new
      @projects = get_project(access_record)
      @clients = get_client
    end
  end 

  def edit
    @path = request.fullpath
    @access_record = AccessRecord.find(params[:id])
    @clients = get_client
    @projects = get_project(@access_record)
  end

  def create
    @access_record = AccessRecord.new(project: @project)
    @access_record.attributes = access_record_params
    if @access_record.save
      if(check_path)
        redirect_to access_records_path
      else
        redirect_to project_access_records_path
      end
    else
      render 'new'
    end
  end

  def update
    @access_record = AccessRecord.find(params[:id])
    
    if (@access_record.update(access_record_params))
      if(check_path)
        redirect_to access_records_path
      else
        redirect_to project_access_records_path
      end
    else
      render 'edit'
    end
  end

  def show
    @access_record = AccessRecord.find(params[:id])
  end

  def destroy
    @access_record = AccessRecord.find(params[:id])
    @access_record.destroy if @access_record
    unless check_path
      redirect_to access_records_path
    else
      redirect_to project_access_records_path
    end
  end

  def get_project_by_client
    client = Client.find(params[:id])
    @projects = client.projects
    respond_to do |format|
      format.json { render json: @projects }
    end

  end

  def show_local_breadcrumb
    true
  end

  def find_request_for_access
    check_path ? require_admin :  authorize
   end

  def choose_layout
    'admin' unless check_path    
    end
  end

  def find_project_from_association
    return true  unless check_path
    render_404 unless @object.present?
    @project = @object.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_access_record_object
    return true unless check_path
    @news = @object = AccessRecord.find(params[:id].to_i)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    return true unless check_path)
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def check_path
    @path = request.fullpath
    return @path.include? ('project') ? true : false 
  end
  
  private
    def access_record_params
      params.require(:access_record).permit(:client_id, :project_id, :access_type, :host_address, :port, :username, :password, :description )    
    end

  def get_client
    Client.all
  end

  def get_project(access_record)
    access_record.blank? ? Project.all :  Project.where("client_id = ?", access_record.client_id)
  end

end
