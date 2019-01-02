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
      @weight = weight
      @address = address
      @port = port
      @name = name
      @balancer = balancer
      @health_check = health_check
      @payload = payload

      @active = true if @active.nil?
    end

    def server_address
      "#{address}:#{port}"
    end

    def remove_gone!
      puts "check if i got removed #{server_address}"
    end
    def remove!
      Moral::Misc.command("ipvsadm -d -t #{@balancer.service_address} -r #{server_address}")
    end

    def update!
      Moral::Misc.command("ipvsadm -e -t #{@balancer.service_address} -r #{server_address} -#{@routing} -w #{weight}")
    end

    def create!
      Moral::Misc.command("ipvsadm -a -t #{@balancer.service_address} -r #{server_address} -#{@routing} -w #{weight}")
    end
  end
end
