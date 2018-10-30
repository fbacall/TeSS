module Curation
  extend ActiveSupport::Concern

  included do
    before_action :set_curation_task, only: :update
  end

  #POST /<resource>/1/add_term
  def add_term
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    term = EDAM::Ontology.instance.lookup(params[:uri])
    field = params[:field]

    log_params = { uri: term.uri,
                   field: field,
                   name: term.preferred_label }

    resource.edit_suggestion.accept_suggestion(field, term)
    resource.create_activity :add_term,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/reject_term
  def reject_term
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    term = EDAM::Ontology.instance.lookup(params[:uri])
    field = params[:field]

    log_params = { uri: term.uri,
                   field: field,
                   name: term.preferred_label }

    resource = instance_variable_get("@#{controller_name.singularize}")
    resource.edit_suggestion.reject_suggestion(field, term)
    resource.create_activity :reject_term,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/add_data
  def add_data
    #puts "PARAMS: #{params.inspect}"
    resource = instance_variable_get("@#{controller_name.singularize}")
    #puts "RESOURCE: #{resource.inspect}"
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    resource.edit_suggestion.accept_data(params[:data_field])
    resource.create_activity :add_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  #POST /<resource>/1/reject_data
  def reject_data
    resource = instance_variable_get("@#{controller_name.singularize}")
    authorize resource, :update?

    log_params = {data_field: params[:data_field],
                  data_value: params[:data_value]}

    resource.edit_suggestion.reject_data(params[:data_field])
    resource.create_activity :reject_data,
                             owner: current_user,
                             recipient: resource.user,
                             parameters: log_params
    head :ok
  end

  private

  def curated_resource
    instance_variable_get("@#{controller_name.singularize}")
  end

  def set_curation_task
    curated_resource.related_curation_task = curated_resource.curation_tasks.find(params[:related_curation_task_id]) if params[:related_curation_task_id]
  end

  def resource_or_next_curation_task
    curated_resource.was_curated? ? next_curation_tasks_path : curated_resource
  end
end
