module Tire

  class Configuration

    def self.url(value=nil)
      @url = (value ? value.to_s.gsub(%r|/*$|, '') : nil) || @url || ENV['ELASTICSEARCH_URL'] || "http://localhost:9200"
    end

    def self.client(klass=nil)
      @client = klass || @client || HTTP::Client::RestClient
    end

    def self.wrapper(klass=nil)
      @wrapper = klass || @wrapper || Results::Item
    end

    def self.logger(device=nil, options={})
      return @logger = Logger.new(device, options) if device
      @logger || nil
    end

    def self.reset(*properties)
      reset_variables = properties.empty? ? instance_variables : instance_variables.map { |p| p.to_s } & \
                                                                 properties.map { |p| "@#{p}" }
      reset_variables.each { |v| instance_variable_set(v.to_sym, nil) }
    end

    def self.nested_attributes(*args)
      options = args.pop
      if (options && options[:delayed_job] && defined?(Delayed::Job))
        @delayed_job = true
      else
        @delayed_job = false
      end
      if block_given?
        yield
      end
    end

    def self.nest(*args)
      classes_hash = args.pop

      associated_class = Kernel.const_get(classes_hash.keys.first.to_s.camelcase)
      root_classes = [classes_hash.values.first.to_s.camelcase]
      delayed_job = @delayed_job

      root_class_sym = hash.values.first

      root_class = Kernel.const_get(root_class_sym.to_s.camelcase)
      change_attributes = []
      root_class.tire.mapping.each do |key, options|
        if options[:type] == 'object' && key == associated_class.to_s.underscore.to_sym
          change_attributes = change_attributes + options[:properties].keys.map(&:to_s)
        end
      end

      unless associated_class.respond_to? "_tire_refresh_#{root_class.to_s.underscore}_indexes".to_sym
        if delayed_job
          associated_class.send(:define_method, "_tire_refresh_#{root_class.to_s.underscore}_indexes".to_sym) do |&block|
            do_reindex = false
            change_attributes.each do |attribute|
              if self.send("#{attribute}_changed?".to_sym)
                do_reindex = true
                break
              end
            end
            block.call
            Tire::Job::ReindexJob.queue(root_class, associated_class, self.id) if do_reindex
          end
        else
          associated_class.send(:define_method, "_tire_refresh_#{root_class.to_s.underscore}_indexes".to_sym) do |&block|
            do_reindex = false
            change_attributes.each do |attribute|
              if self.send("#{attribute}_changed?".to_sym)
                do_reindex = true
                break
              end
            end
            block.call
            Tire::Job::ReindexJob.new(root_class, associated_class, self.id).perform if do_reindex
          end
        end
        associated_class.set_callback :update, :around, "_tire_refresh_#{root_class.to_s.underscore}_indexes".to_sym
      end
    end
  end
end
