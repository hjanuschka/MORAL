require 'rest-client'
module Moral
  class HttpHealthCheck < HealthCheck
    def run!
      url = "#{@definition['protocol']}://#{@node.server_address}#{@definition['endpoint']}"
      begin
        r = RestClient::Request.execute(method: :get, url: url, timeout: @definition['timeout'], headers: @definition['headers'], verify_ssl: false)
        if r.code != @definition['expected']['status']
          puts "BAD STATUS #{r.code} -> #{@definition['expected']['status']}"
          return :bad
        end
        if @definition['expected']['content']
          unless r.body.match(@definition['expected']['content'])
            puts "BAD BODY #{@definition['expected']['content']}"
            return :bad
          end
        end
        return :good
      rescue StandardError => x
        return :bad
      end
    end
  end
end
