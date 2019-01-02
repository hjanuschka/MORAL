module Moral
  class Config
    attr_accessor :balancers

    def initialize
      ENV['MORAL_CONFIG'] ||= 'moral.yml'
      @config = YAML.load_file(ENV['MORAL_CONFIG'])
      @balancers = []
      load_balancers
      load_nodes
    end

    def service?(address: nil, port: nil)
      @balancers.each do |balancer|
        binding.pry
        return balancer if balancer.address == address && balancer.port == port
      end
      nil
    end

    def load_nodes
      @balancers.each do |balancer|
        nodes = @config['balancers'][balancer.name]['nodes']
        nodes.each_pair do |name, options|
          node_config = OpenStruct.new(options)
          health_config = OpenStruct.new(node_config.health)
          hl = Moral::HealthCheck
          health = Object.const_get(hl.to_s).new(
            type: health_config.type,
            interval: health_config.interval,
            dead_on: health_config.dead_on,
            back_on: health_config.back_on,
            definition: health_config.definition
          )

          cl = Moral::Node
          cl = Moral::DockerNode if node_config.type == 'docker'
          # FIXME - change cl, if node is docker
          node = Object.const_get(cl.to_s).new(name: name,
                                          routing: node_config.routing,
                                          weight: node_config.weight,
                                          active:  node_config.active,
                                          address: node_config.address,
                                          port: node_config.port,
                                          health_check: health,
                                          balancer: balancer,
                                          payload: node_config.payload || nil)

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
