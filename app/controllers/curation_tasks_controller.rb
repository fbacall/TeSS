class CurationTasksController < ApplicationController
  before_action :check_curator
  before_action :set_breadcrumbs

  def index
    @curation_tasks = CurationTask.order('priority DESC').all
  end

  def show
    @curation_task = CurationTask.find_by_id(params[:id])
  end

  private

  def check_curator
    unless current_user && (current_user.is_admin? || current_user.is_curator?)
      handle_error(:forbidden, 'This page is only visible to curators.')
    end
  end
end
