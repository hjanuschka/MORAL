module Moral
  class DockerNode < Node
    def create!
      # FIXME
      @docker_nodes ||= []
      Moral::App.logger.debug 'DOCKER CREATE'
      # create multiple nodes
      n = Node.new(name: 'ha1', address: '127.0.0.2', port: 811, health_check: @health_check, balancer: @balancer)
      @docker_nodes << n
      n.create!

      n = Node.new(name: 'ha1', address: '127.0.0.2', port: 812, health_check: @health_check, balancer: @balancer)
      @docker_nodes << n
      n.create!
    end

    def remove_gone!
      Moral::App.logger.debug 'DOCKER check if i got removed'
      # @docker_nodes.map(&:remove!)
    end

    def update!
      # find active docker nodes
      # remove gone ones (Docker-ruby)
      # add new ones
    end

    def remove!
      Moral::App.logger.debug 'DOCKER REMOVE'
    end
  end
end
