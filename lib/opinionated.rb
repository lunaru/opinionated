require 'opinionated/definition'
require 'opinionated/configuration'
require 'opinionated/helpers'
require 'opinionated/hash'

module Reamaze
  module Opinionated
    def self.included(base)
      base.send :extend, ClassMethods
    end

    # Make methods available to ActiveRecord in the class context
    module ClassMethods
      def preferences(preferential = :preferences, options = {})
        send :include, InstanceMethods

        preferential = Helpers.normalize(preferential)

        # Create accessor methods to our configuration info
        class << self
          attr_accessor :preferential_configuration unless method_defined?(:preferential_configuration)
        end

        # Initialize the configuration to an empty hash
        self.preferential_configuration = {} if self.preferential_configuration.nil?

        # Redefining a preference configuration once defined should not be allowed
        raise ArgumentError, "#{self} class already preferences :#{preferential} defined" if self.preferential_configuration.has_key?(preferential)

        configuration = Configuration.new(self, preferential, options)
        yield configuration if block_given?
        preferential_configuration[preferential] = configuration

        # override hstore Hash with a custom Hash
        class_eval do 
          eval(
            <<-EOS
              def #{preferential}
                h = Reamaze::Opinionated::PrefHash.new self, "#{preferential}"
                h.replace self["#{preferential}"] if self["#{preferential}"]
                h
              end
            EOS
          )
        end
        
        # add form accessible attributes
        configuration.definitions.values.each do |definition|
          class_eval do 
            eval(
              <<-EOS
                def #{preferential}_#{definition.name}=(value)
                  set_preferential('#{preferential}', '#{definition.name}', value, true)
                end
                def #{preferential}_#{definition.name}
                  get_preferential('#{preferential}', '#{definition.name}', true)
                end
                def #{preferential}_#{definition.name}?
                  !!get_preferential('#{preferential}', '#{definition.name}', true)
                end
              EOS
            )
          end
        end
      end
    end

    # Make methods available to ActiveRecord models in the instance context
    module InstanceMethods
      # we can't use alias chaining because Rails loads method_missing dynamically
      def method_missing(id, *args, &block)
        self.class.preferential_configuration.keys.each do |key|
          # checker
          match = /#{key}_(.+)\?/.match(id.to_s)
          return !!get_preferential(key, match[1], true) if match

          # setter
          match = /#{key}_(.+)=/.match(id.to_s)
          return set_preferential key, match[1], args[0], true if match

          # getter
          match = /#{key}_(.+)/.match(id.to_s)
          return get_preferential key, match[1], true if match
        end
        
        super
      end

      def set_preferential(preferential, name, value, do_preprocess = false)
        preferential = Helpers.normalize(preferential)
        name = Helpers.normalize(name)

        # Check to make sure the preferential exists
        raise ArgumentError, "Preference #{preferential} is not defined for class #{self.class}" \
          unless self.class.preferential_configuration.has_key?(preferential)
        
        configuration = self.class.preferential_configuration[preferential]
        definition = configuration.definitions[name]

        # Do preprocess here, type_check and validate can be done as AR validation in
        value = definition.preprocess.call(value) if do_preprocess and definition and definition.has_preprocess

        # Invoke the association
        prefs = ::Hash[self[preferential]] if self[preferential]

        if prefs.blank?
          send(preferential + '=', {name => value})
          prefs = send(preferential)
        else
          prefs[name] = value
          send(preferential + '=', prefs)
        end
        
        prefs[name]
      end

      def get_preferential(preferential, name, do_postprocess = false)
        preferential = Helpers.normalize(preferential)
        name = Helpers.normalize(name)

        # Check to make sure the preferential exists
        raise ArgumentError, "Preference #{preferential} not defined for class #{self.class}" \
          unless self.class.preferential_configuration.has_key?(preferential)
        
        configuration = self.class.preferential_configuration[preferential]
        definition = configuration.definitions[name]

        # Invoke the association
        prefs = self[preferential] if self[preferential]
        prefs = {} if prefs.blank?

        # Try to find what they are looking for
        pref = prefs[name]

        # If the pref isn't found, try to fallback on a default
        if pref.nil? and definition
          # TODO break all these nested if statements out into helper methods, i like prettier code
          # TODO raise an exception if we don't respond to default_through or the resulting object doesn't respond to the preferential
          if definition.has_default_through and respond_to?(definition.default_through) and (through = send(definition.default_through)).blank? == false
            value = through.send(preferential)[name]
          elsif definition.has_default_dynamic
            if definition.default_dynamic.instance_of?(Proc)
              value = definition.default_dynamic.call(self, preferential, name)
            else
              # TODO raise an exception if we don't respond to default_dynamic
              value = send(definition.default_dynamic)
            end
          elsif definition.has_default
            value = Marshal::load(Marshal.dump(definition.default)) # BUGFIX deep cloning default values
          else
            value = nil
          end
        else
          value = pref
        end

        value = definition.postprocess.call(value) if do_postprocess and definition and definition.has_postprocess
        value
      end
    end
  end
end

ActiveRecord::Base.send :include, Reamaze::Opinionated
