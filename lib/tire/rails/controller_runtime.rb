require 'active_support/core_ext/module/attr_internal'

module Tire
  module Rails
    module ControllerRuntime
      extend ActiveSupport::Concern

    protected

      attr_internal :tire_runtime

      def cleanup_view_runtime
        tire_rt_before_render = Tire::Rails::LogSubscriber.reset_runtime
        runtime = super
        tire_rt_after_render = Tire::Rails::LogSubscriber.reset_runtime
        self.tire_runtime = tire_rt_before_render + tire_rt_after_render
        runtime - tire_rt_after_render
      end

      def append_info_to_payload(payload)
        super
        payload[:tire_runtime] = (tire_runtime || 0) + Tire::Rails::LogSubscriber.reset_runtime
      end

      module ClassMethods
        def log_process_action(payload)
          messages, tire_runtime = super, payload[:tire_runtime]
          messages << ("Tire: %.1fms" % tire_runtime.to_f) if tire_runtime
          messages
        end
      end
    end
  end
end
