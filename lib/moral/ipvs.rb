require 'open3'
module Moral
  class IPVSServer
    attr_accessor :remote_address
    attr_accessor :forward
    attr_accessor :weight
    attr_accessor :active_connections
    attr_accessor :inactive_connections
    attr_accessor :service

    def initialize(parameters: {})
      @remote_address = parameters['RemoteAddress:Port']
      @forward = parameters['Forward']
      @weight = parameters['weight']
      @active_connections = parameters['ActiveConn']
      @inactive_connections = parameters['InActConn']
      @service = parameters['service']
    end
    def create!()

    end
  end
  class IPVSService
    attr_accessor :nodes
    attr_accessor :local_address
    attr_accessor :scheduler
    attr_accessor :proto

    def initialize(parameters: {})
      @proto = parameters['Prot']
      @local_address = parameters['LocalAddress:Port']
      @scheduler = parameters['Scheduler']
      @nodes ||= []
    end

    def create!()
      # create via ipvsadm
      # call create! on each node
    end
    def add_node(parameters: {})
      parameters['service'] = self
      n = IPVSServer.new(parameters: parameters)
      @nodes.push(n)
    end
  end
  class IPVS
    def self.flush
      command("ipvsadm --clear")
    end
    def self.table
      # REDO with a C/rust plugin
      # sample: -> https://github.com/collectd/collectd/blob/master/src/ipvs.c
      @table = []
      headers = []
      svc = {}
      command('ipvsadm -L -n') do |stdout, _status|
        stdout.split("\n").each_with_index do |l, i|

          headers.push(l.split) unless i > 2
          next unless i > 2
          packets = l.split
          if ([packets.first] & %w[TCP UDP]).any?
            packets.each_with_index do |_p, x|
              svc[headers[1][x]] = packets[x]
            end
            svc = IPVSService.new(parameters: svc)
            @table.push(svc)
          else
            server = {}
            packets.each_with_index do |_p, x|
              server[headers[2][x]] = packets[x]
            end
            svc.add_node(parameters: server)
          end
        end
      end
      @table
    end

    def self.command(command)
      stdout_str, status = Open3.capture2("#{command} 2>&1")
      yield(stdout_str, status)
    end
  end
end
