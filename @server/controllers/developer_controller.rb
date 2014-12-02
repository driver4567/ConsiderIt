class DeveloperController < ApplicationController  
  respond_to :html

  def change_default_subdomain

    if Rails.env.development?
      session[:default_subdomain] = params['id']
    end


    redirect_to '/'

  end
end