module ApplicationHelper
  def height
    user_signed_in? && @body_full ? '100vh' : '95vh'
  end

  def localtime(time)
    return if time.nil?
    time.to_time.localtime.strftime '%Y-%m-%d %H:%M:%S'
  end
end
