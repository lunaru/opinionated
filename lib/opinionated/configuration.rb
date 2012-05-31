module Reamaze
  module Opinionated
    class Configuration
      attr_accessor :definitions

      def initialize(klass, preferential, options)
        @klass        = klass
        @preferential = preferential
        @definitions  = {}
      end

      def define(preferential, options = {})
        preferential = Helpers.normalize(preferential)
        raise ArgumentError, "#{@klass} already defines preferences :#{preferential}" if @definitions.has_key?(preferential)
        @definitions[preferential] = Definition.new(preferential, options)
      end
    end
  end
end
