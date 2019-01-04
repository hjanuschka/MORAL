module Moral
  class BaseModel
    def as_json options = {}
          serialized = Hash.new
              self.class.attributes.each do |attribute|
                      serialized[attribute] = self.public_send attribute
                          end
                  serialized
                    end

      def to_json *a
            as_json.to_json *a
              end
  end
end
