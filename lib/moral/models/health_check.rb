
module Moral
  class HealthCheck < BaseModel
    attr_accessor :state
    attr_accessor :last_check
    attr_accessor :last_state
    attr_accessor :retain_count
    attr_accessor :state_changed
    attr_accessor :back_on
    attr_accessor :interval
    attr_accessor :dead_on
    attr_accessor :node
    attr_accessor :type
    attr_accessor :definition
    attr_accessor :events

    def self.factory(type: 'tcp',
                     interval: 10,
                     dead_on: 1,
                     back_on: 1,
                     definition: nil,
                     node: nil,
                     events: nil)

      # FIXME: if type is http, return instance of HTTP
      cl = self
      cl = Moral::ShellHealthCheck if type == 'shell'
      cl = Moral::HttpHealthCheck if type == 'http'

      cl.new(type: type, interval: interval, dead_on: dead_on, back_on: back_on, definition: definition, node: node, events: events)
   end

    def run!
      # Check if port is reachable
      Timeout.timeout(@definition['timeout'].to_i) do
        s = TCPSocket.new(@node.address, @node.port)
        s.close
        return :good
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        return :bad
      end

      :good
  rescue StandardError => x
    :bad
  end
    def to_h
      h = {
        type: @type,
        interval: @interval,
        dead_on: @dead_on,
        back_on: @back_on,
        definition: @definition,
        node: @node.name,
        state: @state,
        last_state: @last_state,
        last_check: @last_check,
        retain_count: @retain_count,
        events: @events
      }
    end

    def initialize(type: 'tcp',
                   interval: 10.seconds,
                   dead_on: 1,
                   back_on: 1,
                   definition: nil,
                   node: nil,
                   events: nil)

      @type = type
      @interval = interval
      @dead_on = dead_on || 1
      @back_on = back_on || 1
      @definition = definition
      @node = node
      @state = :unknown
      @last_state = :unkown
      @last_check = 0
      @state_changed = false
      @retain_count = 0
      @events = events
    end
  end
end
