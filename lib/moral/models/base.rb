module Moral
  class BaseModel
    def as_json(_options = {})
      serialized = {}
      self.class.attributes.each do |attribute|
        serialized[attribute] = public_send attribute
      end
      serialized
                    end

    def to_json(*a)
      as_json.to_json *a
            end
  end
end
