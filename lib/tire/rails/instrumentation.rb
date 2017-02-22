module Tire
  module Rails
    module Instrumentation
      extend ActiveSupport::Concern

      included do
        alias_method_chain :perform, :instrumentation
      end

      module InstanceMethods
        def perform_with_instrumentation
          # Wrapper around the Search.perform method that logs search times.
          ActiveSupport::Notifications.instrument("search.tire", :name => 'Tire search', :search => self.to_json) do
            perform_without_instrumentation
          end
        end
      end
    end
  end
end
