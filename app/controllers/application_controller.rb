class ApplicationController < ActionController::Base
  include PublicActivity::StoreController

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def solr_search(model_name, search_params, facet_fields, selected_facets)
    model_name.search do
      #Set the search parameter
      fulltext search_params

      #Add all facet_fields as facets
      facet_fields.each{|ff| facet ff}

      #Go through the selected facets and apply them and their facet_values
      if model_name == Event
        facet 'start'
        unless selected_facets.keys.include?('include_expired') and selected_facets['include_expired'] == true
          with('start').greater_than(Time.zone.now)
        end

      end

      selected_facets.each do |facet_title, facet_value|
        if facet_title != 'include_expired'
          if facet_value.is_a?(Array)
            facet_value.each do |fv|
              with(facet_title, fv)
            end
          else
            with(facet_title, facet_value) #Filter by only selected facets
          end
        end
      end
    end
  end
end
