module Moral
  class Node < BaseModel
    attr_accessor :type
    attr_accessor :active
    attr_accessor :routing
    attr_accessor :weight
    attr_accessor :address
    attr_accessor :port
    attr_accessor :name
    attr_accessor :payload
    attr_accessor :health_check
    attr_accessor :alive
    attr_accessor :balancer

    def fall!
      @health_check.events.fall!
      @weight = 0
      update!
    end

    def rise!
      @health_check.events.rise!
      @weight = @config_weight
      update!
    end

    def to_h
      {
         type: @type,
         active: @active,
         routing: @routing,
         weight: @weight,
         address: @address,
         port: @port,
         name: @name,
         payload: @payload,
         health_check: @health_check.to_h,
         alive: @alive,
         balancer: @balancer.name
       }
    end

    def initialize(type: 'node',
                   active: true,
                   routing: 'm',
                   weight: 1,
                   address: nil,
                   port: nil,
                   balancer: nil,
                   name: nil,
                   health_check: nil,
                   payload: nil)

      @type = type
      @active = active
      @routing = routing
      @weight = 0
      @address = address
      @port = port
      @name = name
      @balancer = balancer
      @health_check = health_check
      @payload = payload

      @active = true if @active.nil?
      @alive = true
      @config_weight = weight
    end

    def server_address
      "#{address}:#{port}"
    end

    def remove_gone!
      # Moral::App.logger.debug "check if i got removed #{server_address}"
    end

    def remove!
      Moral::Misc.command("ipvsadm -d -t #{@balancer.service_address} -r #{server_address}")
      @balancer.remove_node!(self)
    end

    def update!
      Moral::Misc.command("ipvsadm -e -t #{@balancer.service_address} -r #{server_address} -#{@routing} -w #{weight}")
    end

    def create!
      Moral::Misc.command("ipvsadm -a -t #{@balancer.service_address} -r #{server_address} -#{@routing} -w #{weight}")
    end
  end
end
