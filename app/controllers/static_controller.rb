class StaticController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def about; end

  def privacy; end

  def workflow_viewer
    respond_to do |format|
      format.html { render 'static/workflow_viewer', layout: false }
    end
  end

  def home
    @hide_search_box = true
    @resources = []
    [Event, Material].each do |resource|
      @resources << resource.between_times(Time.zone.now - 2.week, Time.zone.now).limit(5)
    end
    @resources.flatten! if @resources.any?
    @resources.sort_by! { |x| x.created_at }.reverse!
  end
end
