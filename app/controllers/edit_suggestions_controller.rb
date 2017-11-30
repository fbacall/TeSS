class EditSuggestionsController < ApplicationController

  def create
    type = params[:type]
    id = params[:id]
    record = type.constantize.find(id)

    if record
      # TODO: Create the edit suggestion here
      save = false
      suggestion = EditSuggestion.new(:suggestible_type => type, :suggestible_id => id, :data_fields => {})
      Material.suggested_fields.each do |f|
        value = params[type.downcase][f]
        if value.is_a?(Array)
          value = value.reject! { |s| s.strip.empty? || s.nil? }
        end
        unless value.blank? or value == 'notspecified'
          suggestion[:data_fields][f] = params[type.downcase][f]
          save = true
        end
      end
      if save
        suggestion.save!
        redirect_to record, notice: 'Thanks, your edit suggestions have been recorded and will be reviewed.'
      else
        redirect_to record, notice: 'Sorry, your edit suggestions appeared to be blank and haven\'t been recorded.'
      end
    else
      redirect_to materials_path, notice: 'Sorry, something went wrong with your request.'
    end


  end

end