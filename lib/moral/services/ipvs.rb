module Moral
  class IPVS
    attr_accessor :cfg
    def initialize
      @cfg = Moral::Config.instance
    end

    def update_table
      # clear_table
      clear_table if ENV['IPVS_CLEAR']
      @table = load_table
      create_table
    end

    def patch_table
      @table = load_table
      create_table
    end

    # def self.service?(addr)
    # FIXME service exist
    # end

    def service?(address: nil, port: nil)
      @table.each do |balancer|
        return balancer if balancer.address == address && balancer.port == port
      end
      nil
    end

    def create_table
      @cfg.balancers.each do |balancer|
        loaded_balancer = service?(address: balancer.address, port: balancer.port)
        # if balancer is disabled
        # check if it is still in current live table
        # if so -> remove
        unless balancer.active
          loaded_balancer&.remove!
          next
        end

        # if it does not already exist in live table
        # create it
        if loaded_balancer
          balancer.update!
          # remove gone nodes
          balancer.nodes.each do |node|
            loaded_node = loaded_balancer.node?(address: node.address, port: node.port)
            unless node.active && node.alive
              node.remove!
              next
            end
            if loaded_balancer.node?(address: node.address, port: node.port)
              # exists
              # node.update!
            else
              # does not exist, create it
              node.create!
            end
          end
          # check nodes, add missing, remove gone ones
          # CHECK changes
          # FIXMEEEE
          balancer.remove_gone!
        else
          balancer.create!
        end
      end
    end

    def load_table
      # REDO with a C/rust plugin
      # sample: -> https://github.com/collectd/collectd/blob/master/src/ipvs.c
      table = []
      headers = []
      svc = nil
      svc_raw = {}
      Moral::Misc.command_block('ipvsadm -L -n') do |stdout, _status|
        stdout.split("\n").each_with_index do |l, i|
          headers.push(l.split) unless i > 2
          next unless i > 2

          packets = l.split
          if ([packets.first] & %w[TCP UDP]).any?
            svc_raw = {}
            packets.each_with_index do |_p, x|
              svc_raw[headers[1][x]] = packets[x]
            end
            addr = svc_raw['LocalAddress:Port'].split(':')

            svc = Balancer.new(
              protocol: svc_raw['Prot'],
              scheduler: svc_raw['Scheduler'],
              active: true,
              address: addr[0],
              port: addr[1].to_i
            )
            table.push(svc)
          else
            server = {}
            packets.each_with_index do |_p, x|
              server[headers[2][x]] = packets[x]
            end
            cl = Moral::Node
            # FIXME - change cl, if node is docker
            addr = server['RemoteAddress:Port'].split(':')
            r = 'm'
            case server['Forward']
            when 'Masq'
              r = 'm'
            when 'Route'
              r = 'g'
            when 'Tunnel'
              r = 'i'
            end

            node = Object.const_get(cl.to_s).new(name: nil,
                                            routing: r,
                                            weight: server['Weight'],
                                            address: addr[0],
                                            port: addr[1].to_i,
                                            health_check: nil,
                                            balancer: svc)

            svc.add_node(node: node)
          end
        end
      end
      table
    end

    def clear_table
      Moral::Misc.command('ipvsadm --clear')
    end
  end
end
