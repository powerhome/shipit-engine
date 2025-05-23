# frozen_string_literal: true

module ApiHelper
  private

  def authenticate!(client = @client || :spy)
    client = shipit_api_clients(client) if client.is_a?(Symbol)
    @client ||= client
    request.headers['Authorization'] = "Basic #{Base64.encode64(client.authentication_token)}"
  end
end

module Shipit
  class ApiControllerTestCase < ActionController::TestCase
    private

    def process(_action, **kwargs)
      kwargs[:as] ||= :json if kwargs[:method] != "GET"
      super
    end
  end
end
