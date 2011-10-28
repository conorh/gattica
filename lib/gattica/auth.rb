require 'net/http'
require 'net/https'

module Gattica
  
  # Authenticates a user against the Google Client Login system
  
  class Auth
    
    include Convertible

    SCRIPT_NAME = '/accounts/ClientLogin'
    HEADERS = { 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Ruby Net::HTTP' }   # Google asks that you be nice and provide a user-agent string
    OPTIONS = { :source => 'gattica', :service => 'analytics' }                                    # Google asks that you provide the name of your app as a 'source' parameter in your POST

    attr_reader :tokens
  
    # Try to authenticate the user
    def initialize(http, user)
      options = OPTIONS.merge(user.to_h)
      options.extend HashExtensions

      response, data = http.post(SCRIPT_NAME, options.to_query, HEADERS)
      data = response.body if data == "" || data.nil? # Ruby 1.9.3 http.post does not return the body

      if response.code != '200'
        case response.code
        when '403'
          raise GatticaError::CouldNotAuthenticate, 'Your email and/or password is not recognized by the Google ClientLogin system (status code: 403)'
        else
          raise GatticaError::UnknownAnalyticsError, response.body + " (status code: #{response.code})"
        end
      end
      @tokens = parse_tokens(data)
    end
  
  
    private
    
    # Parse the authentication tokens out of the response and makes them available as a hash
    #
    # tokens[:auth] => Google requires this for every request (added to HTTP headers on GET requests)
    # tokens[:sid]  => Not used
    # tokens[:lsid] => Not used
    
    def parse_tokens(data)
      tokens = {}
      data.split("\n").each do |t|
        tokens.merge!({ t.split('=').first.downcase.to_sym => t.split('=').last })
      end
      return tokens
    end
  
  end
end
