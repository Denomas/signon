class Superadmin::SupportedPermissionsController < Superadmin::BaseController
  respond_to :html

  before_filter :load_application

  def new
    @supported_permission = @application.supported_permissions.build
  end

  def edit
    @supported_permission = SupportedPermission.find(params[:id])
  end

  def create
    @supported_permission = @application.supported_permissions.build(supported_permission_parameters)
    if @supported_permission.save
      redirect_to superadmin_application_supported_permissions_path,
        notice: "Successfully added permission #{@supported_permission.name} to #{@application.name}"
    else
      render :new
    end
  end

  def update
    @supported_permission = SupportedPermission.find(params[:id])
    if @supported_permission.update_attributes(supported_permission_parameters)
      redirect_to superadmin_application_supported_permissions_path,
        notice: "Successfully updated permission #{@supported_permission.name}"
    else
      render :edit
    end
  end

private

  def load_application
    @application = ::Doorkeeper::Application.find(params[:application_id])
  end

  def supported_permission_parameters
    params[:supported_permission].slice(:name, :delegatable)
  end

end
