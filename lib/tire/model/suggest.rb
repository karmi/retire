module Tire
  module Model
    module Suggest
      module ClassMethods
        def suggest(*args, &block)
          default_options = {:type => document_type, :index => index.name}

          if block_given?
            options = args.shift || {}
          else
            query, options = args
            options ||= {}
          end

          options = default_options.update(options)

          s = Tire::Suggest::Suggest.new(options.delete(:index), options)

          if block_given?
            block.arity < 1 ? s.instance_eval(&block) : block.call(s)
          else
            s.suggestion 'default_suggestion' do
              text query
              completion 'suggest'
            end
          end

          s.results

        end
      end
    end
  end
end
