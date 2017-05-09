class CollaborationsController < ApplicationController
  before_filter :get_resource
  before_filter :authorize_resource

  respond_to :json

  def create
    @collaboration = @resource.collaborations.create(collaboration_params)

    respond_with(@collaboration)
  end

  def destroy
    Collaboration.find(params[:id]).destroy
    render json: '{}'
  end

  def index
    @collaborations = @resource.collaborations

    respond_with(@collaborations)
  end

  def show
    @collaboration = Collaboration.find(params[:id])

    respond_with(@collaboration)
  end

  private

  # This is really awkward, but there isn't a better way of doing it.
  # Scan the params for the ID of the parent resource, e.g. workflow_id, material_id etc.
  def get_resource
    params.each do |name, value|
      next unless name.end_with?('_id')
      c = begin
            name.chomp('_id').classify.constantize
          rescue
            NameError
          end
      @resource = c.friendly.find(value) if c.method_defined?(:collaborations)
    end
  end

  def authorize_resource
    authorize @resource, :manage?
  end

  def collaboration_params
    params.require(:collaboration).permit(:user_id)
  end
end
