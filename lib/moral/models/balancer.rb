module Moral
  class Balancer < BaseModel
    attr_accessor :protocol
    attr_accessor :scheduler
    attr_accessor :address
    attr_accessor :port
    attr_accessor :name
    attr_accessor :active

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

      # FIXME: default values, random
      @nodes = []
    end

    def to_h
      h = {
           protocol: @protocol,
           scheduler: @scheduler,
           address: @address,
           port: @port,
           name: @name,
           active: @active,
           nodes: []
          }
      nodes.each do |n|
        h[:nodes] << n.to_h
      end
      h
    end

    def nodes
      fin = []
      @nodes.each do |no|
        fin << no if no.type == 'node'
      end
      fin
    end

    def update!
      # FIXME
    end

    def remove_node!(node)
      @nodes.delete(node)
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

    def delete_node_at(index)
      @nodes.each_with_index do |n, index|
        next unless n.type == 'node'

        @nodes.delete_at(index)
      end
    end

    def remove!
      @nodes.each(&:remove!)
      Moral::Misc.command("ipvsadm -D -t #{service_address}")
      Moral::Config.instance.balancers.delete(self)
    end

    def create!
      # FIXME: check existance
      Moral::Misc.command("ipvsadm -A -t #{service_address}  -s #{@scheduler}")
      @nodes.each do |node|
        next unless node.active && node.alive

        node.create!
      end
    end

    def add_node(node: nil)
      @nodes << node
    end
  end
end
