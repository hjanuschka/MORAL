
module Moral
  require 'sinatra/base'
  require 'json'
  class RestAPI < Sinatra::Base
    get '/' do
      Moral::Config.instance.balancers.to_json
    end
    def self.go(mutex, ipvs)
      set :port, 8088
      set :bind, '0.0.0.0'
      set :public_folder, 'public'
      @cfg = Moral::Config.instance
      @mutex = mutex
      @ipvs = ipvs
      start!
    end
  end
end
