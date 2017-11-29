class EditSuggestionsController < ApplicationController

  def create
    @type = params[:type]
    @id = params[:id]
    @record = @type.constantize.find(@id)
    if @record
      render :text => "Well, that worked: #{@record.inspect}"
    else
      render :text => "FRC"
    end


  end

end