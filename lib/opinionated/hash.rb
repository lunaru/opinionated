module Reamaze
  module Opinionated
    class Hash < ::Hash
      def initialize(owner, preferential)
        @owner = owner
        @preferential = preferential
      end

      def [] key
        @owner.get_preferential @preferential, key.to_s, true
      end

      def []= key, value
        @owner.set_preferential @preferential, key.to_s, value, true
        super key.to_s, value
      end

      def method_missing(id, *args, &block)
        match = /(.+)=$/.match id.to_s
        return self[match[1]] = args[0] if match
        
        match = /(.+)\?$/.match id.to_s
        return !!self[match[1]] if match
        
        self[id]
      end 
    end
  end
end