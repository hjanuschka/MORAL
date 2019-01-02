module Moral
  class Balancer < BaseModel
    attr_accessor :protocol
    attr_accessor :scheduler
    attr_accessor :address
    attr_accessor :port
    attr_accessor :name
    attr_accessor :active
    attr_accessor :nodes

    def initialize(protocol: 'TCP',
      scheduler: 'rr',
      active: true,
      address: nil,
      port: nil,
      name: nil)
      @protocol = protocol
      @scheduler = scheduler
      @address = address
      @port = port.to_i
      @name = name
      @active = active

      @active = true if @active.nil?

      # FIXME default values, random
      @nodes = []
    end

    def update!
      # FIXME
    end

    def node?(address: nil, port: nil)
      @nodes.each do |node|
        return node if node.address == address && node.port = port
      end
      nil
    end

    def service_address
      "#{address}:#{port}"
    end

    def remove_gone!
      @nodes.each(&:remove_gone!)
    end
    def remove!
      @nodes.each(&:remove!)
      Moral::Misc.command("ipvsadm -D -t #{service_address}")
    end

    def create!
      # FIXME check existance
      Moral::Misc.command("ipvsadm -A -t #{service_address}  -s #{@scheduler}")
      @nodes.each do |node|
        next unless node.active
        node.create!
      end
    end

    def add_node(node: nil)
      @nodes << node
    end
  end
end
