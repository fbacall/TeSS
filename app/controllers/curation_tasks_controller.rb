class CurationTasksController < ApplicationController
  before_action :check_curator
  before_action :set_curation_task, only: :show
  before_action :set_breadcrumbs

  def index
    # Sorting by `completed_by_id` puts unresolved tasks at the top!
    @curation_tasks = CurationTask.order('completed_by_id DESC, priority DESC').all
  end

  def show
  end

  def next
    task = CurationTask.queue_for_user(current_user).first
    if task
      redirect_to task
    else
      flash[:notice] = 'No more curation tasks remaining'
      redirect_to curation_tasks_path
    end
  end

  private

  def set_curation_task
    @curation_task = CurationTask.find_by_id(params[:id])
  end

  def check_curator
    unless current_user && (current_user.is_admin? || current_user.is_curator?)
      handle_error(:forbidden, 'This page is only visible to curators.')
    end
  end
end
