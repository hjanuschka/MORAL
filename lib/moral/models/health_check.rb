module Moral
  class HealthCheck < BaseModel
    def initialize(type: 'tcp',
      interval: 10.seconds,
      dead_on: 1,
      back_on: 1,
      definition: nil)

      @type = type
      @interval = interval
      @dead_on = dead_on
      @back_on = back_on
      @definition = definition
    end
  end
end
