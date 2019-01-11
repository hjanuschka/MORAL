require 'rest-client'
module Moral
  class HttpHealthCheck < HealthCheck
    def run!
      url = "#{@definition['protocol']}://#{@node.server_address}#{@definition['endpoint']}"
      begin
        r = RestClient::Request.execute(method: :get, url: url, timeout: @definition['timeout'], headers: @definition['headers'])
        if r.code != @definition['expectet']['status']
          puts "BAD STATUS #{r.code} -> #{@definition['expectet']['status']}"
          return :bad
        end
        unless r.body.match(@definition['expectet']['content'])
          puts "BAD BODY #{@definition['expectet']['content']}"
          return :bad
        end
        return :good
      rescue StandardError => x
        return :bad
      end
    end
  end
end
