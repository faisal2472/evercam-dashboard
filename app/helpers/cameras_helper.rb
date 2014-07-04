module CamerasHelper
  def get_evercam_api
    configuration = Rails.application.config
    parameters    = {logger: Rails.logger}
    if current_user
      parameters = parameters.merge(api_id: current_user.api_id,
                                    api_key: current_user.api_key)
    end
    settings      = {}
    begin
      settings = (configuration.evercam_api || {})
    rescue => error
      # Deliberately ignored.
    end
    parameters    = parameters.merge(settings) if !settings.empty?
    Evercam::API.new(parameters)
  end

  def preview(camera, live=false)
    camera_obj = Camera.by_exid(camera['id'])
    if camera_obj.nil?
      preview = nil
    else
      preview = camera_obj.preview
    end
    proxy = "#{EVERCAM_API}cameras/#{camera['id']}/snapshot.jpg?api_id=#{current_user.api_id}&api_key=#{current_user.api_key}"
    begin
      if preview.nil?
        res = get_evercam_api.get_latest_snapshot(camera['id'], true)
        unless res.nil?
          uri = URI::Data.new(res['data'])
          img_class = camera['is_online'] ? 'snap' : ''
          if live
            return "<img class='#{img_class}' data-proxy='#{proxy}' src='#{uri}' width='100%' height='auto'>".html_safe
          else
            return "<img class='#{img_class}' data-proxy='#{proxy}' src='#{uri}' >".html_safe
          end
        end
      else
        data = Base64.encode64(preview).gsub("\n", '')
        uri = URI::Data.new("data:image/jpeg;base64,#{data}")
        img_class = camera['is_online'] ? 'snap' : ''
        if live
          return "<img class='#{img_class}' data-proxy='#{proxy}' src='#{uri}' width='100%' height='auto'>".html_safe
        else
          return "<img class='#{img_class}' data-proxy='#{proxy}' src='#{uri}' >".html_safe
        end
      end
    rescue => error
      Rails.logger.error "Exception caught processing preview request.\nCause: #{error}\n" +
                         error.backtrace.join("\n")
    end

    if live
      "<img class='live' src='#{proxy}' width='100%' height='auto'>".html_safe
    else
      "<img class='live' src='#{proxy}' onerror=\"this.style.display='none'\" alt=''>".html_safe
    end
  end

end
