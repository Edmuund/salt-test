# handles third-party API integration
module ApiRequest
  require 'typhoeus'

  # handles single requests
  class SingleRequest

    class << self
      attr_accessor :error, :response
    end

    def initialize(url, action, headers, parameters)
      @url                   = url
      @action                = action
      @headers               = headers
      @parameters            = parameters
      SingleRequest.response = nil
      SingleRequest.error    = nil
    end

    def run
      @request = init
      handle
      @request.run
    end

    private

    def init
      Typhoeus::Request.new(@url,
                            method: @action,
                            headers: { 'accept'       => 'application/json',
                                       'content-type' => 'application/json',
                                       'client-id'    => Rails.application.secrets.client_id,
                                       'app-secret'   => Rails.application.secrets.app_secret }.merge!(@headers),
                            params: @parameters, timeout: 20, forbid_reuse: true)
    end

    def handle
      @request.on_complete do |response|
        if response.body != ''
          body = JSON.parse(response.body)
          if response.success?
            SingleRequest.response = body['data']
          else
            @message = body['error_message']
            @message = filter_data
            SingleRequest.error = "Error #{response.code}: #{@message}"
          end
        else
          SingleRequest.error = "Something went wrong. #{response.return_message}."
        end
      end
    end

    def filter_data
      if secret_data?
        filtered    = @message.split("'").join(' ').split
        filtered[3] = '<filtered>'
        filtered.join(' ')
      elsif resource_exists?
        @message.split('with').first.rstrip
      else
        @message
      end
    end

    def secret_data?
      @message.include?('with secret:') ? true : false
    end

    def resource_exists?
      @message.include?('exists with id') ? true : false
    end
  end
end