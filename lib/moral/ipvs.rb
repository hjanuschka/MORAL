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
      @weight = parameters['Weight'].to_i
      @active_connections = parameters['ActiveConn'].to_i
      @inactive_connections = parameters['InActConn'].to_i
      @service = parameters['service']
    end

    def remove!
      cmd = "ipvsadm -d -t #{@service.local_address} -r #{@remote_address}"
      IPVS.command(cmd) do |stdout, status|
      end
    end

    def create!
      # create nodes
      cmd = "ipvsadm -a -t #{@service.local_address} -r #{@remote_address} -#{@forward}"
      IPVS.command(cmd) do |stdout, status|
      end
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

    def create!
      # Create Service
      cmd = "ipvsadm -A -t  #{@local_address} -s #{@scheduler}"
      IPVS.command(cmd) do |stdout, status|
      end
      @nodes.each(&:create!)
    end

    def node?(address)
      @nodes.each do |node|
        return node if node.remote_address == address
      end
      nil
    end

    def add_node(parameters: {})
      parameters['service'] = self
      n = IPVSServer.new(parameters: parameters)
      @nodes.push(n)
      n
    end
  end
  class IPVS
    def self.flush
      command('ipvsadm --clear')
    end

    def self.service?(service)
      table.each do |svc|
        return svc if svc.local_address == service
      end
      nil
    end

    def self.table
      # REDO with a C/rust plugin
      # sample: -> https://github.com/collectd/collectd/blob/master/src/ipvs.c
      @table = []
      headers = []
      svc = nil
      svc_raw = {}
      command('ipvsadm -L -n') do |stdout, _status|
        stdout.split("\n").each_with_index do |l, i|
          headers.push(l.split) unless i > 2
          next unless i > 2

          packets = l.split
          if ([packets.first] & %w[TCP UDP]).any?
            svc_raw = {}
            packets.each_with_index do |_p, x|
              svc_raw[headers[1][x]] = packets[x]
            end
            svc = IPVSService.new(parameters: svc_raw)
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
