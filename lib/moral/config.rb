module Moral
  class Config
    attr_accessor :balancers
    attr_accessor :heartbeat_nodes
    attr_accessor :heartbeat_config

    def self.instance
      @cfg_instance ||= new
      @cfg_instance
    end

    def initialize
      ENV['MORAL_CONFIG'] ||= 'moral.yml'
      @config = YAML.load(File.read(ENV['MORAL_CONFIG']))
      @balancers = []
      load_heartbeat
      load_balancers
      load_nodes
    end

    def service?(address: nil, port: nil)
      @balancers.each do |balancer|
        return balancer if balancer.address == address && balancer.port == port
      end
      nil
    end

    def load_heartbeat
      # create health_check
      # create healthcheck event
      #
      @heartbeat_config = OpenStruct.new(@config['heartbeat'])
      @heartbeat_config.me.gsub!("${MORAL_HOSTNAME}", ENV['MORAL_HOSTNAME'])
      @heartbeat_nodes = []
      heartbeat_config.hosts.each_with_index do | n, i |
        
        event_config = OpenStruct.new(heartbeat_config.events)
        health_config = OpenStruct.new(heartbeat_config.health)

        events = Moral::HealthChecks::Events.new(
            rise: event_config.rise,
            fall: event_config.fall
          )
        health = Moral::HealthCheck.factory(
            type: health_config.type,
            interval: health_config.interval.to_i,
            dead_on: health_config.dead_on,
            back_on: health_config.back_on,
            definition: health_config.definition,
            events: events
        )
        node = Moral::Node.new(name: n['name'],
                               address: n['address'],
                               port: n['port'],
                               health_check: health)



        health.node = node
        health.events.node = node


        @heartbeat_nodes << node
      end
      binding.pry
    end
    def load_nodes
      @balancers.each do |balancer|
        nodes = @config['balancers'][balancer.name]['nodes']
        nodes.each_pair do |name, options|
          node_config = OpenStruct.new(options)
          health_config = OpenStruct.new(node_config.health)
          event_config = OpenStruct.new(health_config.events)

          events = Moral::HealthChecks::Events.new(
            rise: event_config.rise,
            fall: event_config.fall
          )

          health = Moral::HealthCheck.factory(
            type: health_config.type,
            interval: health_config.interval.to_i,
            dead_on: health_config.dead_on,
            back_on: health_config.back_on,
            definition: health_config.definition,
            events: events
          )

          cl = Moral::Node
          next if node_config.type == 'docker'
          # FIXME: - change cl, if node is docker
          node = Object.const_get(cl.to_s).new(name: name,
                                          routing: node_config.routing,
                                         weight: node_config.weight,
                                          active:  node_config.active,
                                          address: node_config.address,
                                          port: node_config.port,
                                          health_check: health,
                                          balancer: balancer,
                                          payload: node_config.payload || nil)

          health.node = node
          health.events.node = node
          balancer.add_node(node: node)
        end
      end
    end

    def load_balancers
      @config['balancers'].each_pair do |name, options|
        balancer_config = OpenStruct.new(options)
        balancer = Balancer.new(name: name,
                                active: balancer_config.active,
                                protocol: balancer_config.protocol,
                                scheduler: balancer_config.scheduler,
                                address: balancer_config.address,
                                port: balancer_config.port)

        @balancers << balancer
      end
    end
  end
end
