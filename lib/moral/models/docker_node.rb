module Moral
  class DockerNode < Node
    def update!
      puts 'DOCKER UPDATE'
    end

    def create!
      # FIXME
      binding.pry
      @docker_nodes ||=[]
      puts 'DOCKER CREATE'
      # create multiple nodes
      n = Node.new(name: 'ha1', address: '127.0.0.2', port: 811, health_check: @health_check, balancer: @balancer)
      @docker_nodes << n
      n.create!

      n = Node.new(name: 'ha1', address: '127.0.0.2', port: 812, health_check: @health_check, balancer: @balancer)
      @docker_nodes << n
      n.create!
    end


    def remove_gone!
      puts "DOCKER check if i got removed"
      #@docker_nodes.map(&:remove!)
    end

    def update!
      # find active docker nodes
      # remove gone ones (Docker-ruby)
      # add new ones
    end

    def remove!
      puts 'DOCKER REMOVE'
    end
  end
end
