
module Moral
  require 'sinatra/base'
  require "sinatra/json"
  require 'json'
  class RestAPI < Sinatra::Base
    get '/balancers' do
      r = []
      settings.cfg.balancers.each do | b |
        r << b.to_h
      end
      json r
    end
    get '/balancers/:name' do
      r = nil
      settings.cfg.balancers.each do | b |
        next unless b.name == params[:name]
        r = b.to_h
      end
      json r
    end


    get '/balancers/:name/nodes' do
      r = []
      settings.cfg.balancers.each do | b |
        next unless b.name == params[:name]
        b.nodes.each do | n |
          r << n.to_h
        end
      end
      json r
    end


    get '/balancers/:name/nodes/:node_name' do
      r = nil
      settings.cfg.balancers.each do | b |
        next unless b.name == params[:name]
        b.nodes.each do | n |
          next unless n.name == params[:node_name]
          r = n.to_h
        end
      end
      json r
    end

    post '/balancers' do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]
      balancer = Balancer.new(name: payload['name'],
                                active: payload['active'],
                                protocol: payload['protocol'],
                                scheduler: payload['scheduler'],
                                address: payload['address'],
                                port: payload['port'])

      settings.mutex.synchronize do
          settings.cfg.balancers << balancer
          settings.ipvs.update_table
      end
      json  balancer.to_h

    end

    post '/balancers/:name/node' do
      r = nil
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]
      b = nil
      settings.cfg.balancers.each do | c |
        next unless c.name == params[:name]
        b = c
        break
      end

          health = Moral::HealthCheck.factory(
            type: payload['health_check']['type'],
            interval: payload['health_check']['interval'].to_i,
            dead_on: payload['health_check']['dead_on'],
            back_on: payload['health_check']['back_on'],
            definition: payload['health_check']['definition']
          )

          cl = Moral::Node
          # FIXME: - change cl, if node is docker
          node = Object.const_get(cl.to_s).new(name: payload['name'],
                                          routing: payload['routing'],
                                          weight: payload['weight'],
                                          active:  payload['active'],
                                          address: payload['address'],
                                          port: payload['port'],
                                          health_check: health,
                                          balancer: b,
                                          payload: payload['payload'] || nil)

          health.node = node

        settings.mutex.synchronize do
          b.add_node(node: node)
          settings.ipvs.update_table
        end

        json node.to_h
    end

    delete '/balancer/:name' do
      settings.mutex.synchronize do
        idx = nil
        b = nil
        settings.cfg.balancers.each_with_index do | balancer, index |
          if balancer.name == params[:name]
            idx = index
            b = balancer
          end
        end
        b.remove!

        json true
      end
    end


    delete '/balancer/:name/node/:node_name' do
      settings.mutex.synchronize do
        idx = nil
        b = nil
        settings.cfg.balancers.each_with_index do | balancer, index |
          if balancer.name == params[:name]
            idx = index
            b = balancer
          end
        end
        b.nodes.each_with_index do | node, index |
            if node.name == params[:node_name]
                node.remove!
            end
        end
        json true
      end
    end



    get '/' do
      Moral::Config.instance.balancers.to_json
    end
    def self.go(mutex, ipvs)
      set :port, 8088
      set :bind, '0.0.0.0'
      set :public_folder, 'public'
      set :cfg, Moral::Config.instance
      set :mutex, mutex
      set :ipvs, ipvs
      start!
    end
  end
end
