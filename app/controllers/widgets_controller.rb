class WidgetsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :allow_iframe, only: :live_view_private_widget
  before_filter :normal_cookies_for_ie_in_iframes!, only: :live_view_private_widget
  skip_before_action :verify_authenticity_token, only: [:live_view_widget, :live_view_private_widget]
  skip_before_action :authenticate_user!, only: [:live_view_widget, :live_view_private_widget]
  skip_after_filter :intercom_rails_auto_include, only: [:live_view_widget, :live_view_private_widget]

  include SessionsHelper
  include ApplicationHelper

  def widgets
    current_user
  end

  def widgets_new
    current_user
    load_user_cameras
  end

  def widgets_hikvision
    current_user
    load_user_cameras
  end


  def live_view_widget
    respond_to do |format|
      format.js { render :file => "widgets/live.view.widget.js", :mime_type => Mime::Type.lookup('text/javascript')}
    end
  end

  def live_view_private_widget
    widget_user = nil
    unless params[:api_id].blank? or params[:api_key].blank?
      widget_user = User.where(api_id: params[:api_id], api_key: params[:api_key]).first
      sign_in(widget_user) if widget_user
    end
    if current_user.nil? and widget_user.nil?
      session[:redirect_url] = request.original_url
      redirect_to '/widget_signin'
      return
    end
    begin
      api = get_evercam_api
      api.get_snapshot(params[:camera])
    rescue => error
      @unathorized = error.status_code == 403
      @not_exist = error.status_code == 404
    end
    render :layout => false
  end

end
