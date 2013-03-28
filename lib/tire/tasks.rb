require 'rake'
require 'ansi/progressbar'

module Tire
  module Tasks

    module Import
      HRULE = '='*90

      def delete_index(index)
        puts "[IMPORT] Deleting index '#{index.name}'"
        index.delete
      end

      def create_index(index, klass)
        unless index.exists?
          mapping = MultiJson.encode(klass.tire.mapping_to_hash, :pretty => Tire::Configuration.pretty)
          puts "[IMPORT] Creating index '#{index.name}' with mapping:", mapping
          unless index.create(:mappings => klass.tire.mapping_to_hash, :settings => klass.tire.settings)
            puts "[ERROR] There has been an error when creating the index -- Elasticsearch returned:",
                        index.response
            exit(1)
          end
        end
      end

      def add_pagination_to_klass(klass)
        if defined?(Kaminari) && klass.respond_to?(:page)
          klass.instance_eval do
            def paginate(options = {})
              page(options[:page]).per(options[:per_page])
            end
          end
        end unless klass.respond_to?(:paginate)
      end

      def progress_bar(klass, total=nil)
        @progress_bars ||= {}

        if total
          @progress_bars[klass.to_s] ||= ANSI::Progressbar.new(klass.to_s, total)
        else
          @progress_bars[klass.to_s]
        end
      end

      def import_model(index, klass, params)
        unless progress_bar(klass)
          puts "[IMPORT] Importing '#{klass.to_s}'"
        end
        klass.tire.import(params) do |documents|
          progress_bar(klass).inc documents.size if progress_bar(klass)
          documents
        end
        progress_bar(klass).finish if progress_bar(klass)
      end

      extend self
    end

  end
end

namespace :tire do

  import_model_desc = <<-DESC.gsub(/    /, '')
    Import data from your model (pass name as CLASS environment variable).

      $ rake environment tire:import:model CLASS='MyModel'

    Pass params for the `import` method:
      $ rake environment tire:import:model CLASS='Article' PARAMS='{:page => 1}'

    Force rebuilding the index (delete and create):
      $ rake environment tire:import:model CLASS='Article' FORCE=1

    Set target index name:
      $ rake environment tire:import:model CLASS='Article' INDEX='articles-new'
  DESC

  import_all_desc = <<-DESC.gsub(/    /, '')
    Import all indices from `app/models` (or use DIR environment variable).

      $ rake environment tire:import:all DIR=app/models
  DESC

  task :import => 'import:model'

  namespace :import do
    desc import_model_desc
    task :model do
      if defined?(Rails)
        puts "[IMPORT] Rails detected, loading environment..."
        Rake::Task["environment"].invoke
      end

      if ENV['CLASS'].to_s == ''
        puts HRULE, 'USAGE', HRULE, import_model_desc, ""
        exit(1)
      end

      klass  = eval(ENV['CLASS'].to_s)
      params = eval(ENV['PARAMS'].to_s) || {}
      total  = klass.count rescue nil

      if ENV['INDEX']
        index = Tire::Index.new(ENV['INDEX'])
        params[:index] = index.name
      else
        index = klass.tire.index
      end

      Tire::Tasks::Import.add_pagination_to_klass(klass)
      Tire::Tasks::Import.progress_bar(klass, total) if total

      Tire::Tasks::Import.delete_index(index) if ENV['FORCE']
      Tire::Tasks::Import.create_index(index, klass)

      Tire::Tasks::Import.import_model(index, klass, params)

      puts '[IMPORT] Done.'
    end

    desc import_all_desc
    task :all do
      if defined?(Rails)
        puts "[IMPORT] Rails detected, loading environment..."
        Rake::Task["environment"].invoke
      end

      dir    = ENV['DIR'].to_s != '' ? ENV['DIR'] : Rails.root.join("app/models")
      params = eval(ENV['PARAMS'].to_s) || {}

      puts "[IMPORT] Loading models from: #{dir}"
      Dir.glob(File.join("#{dir}/**/*.rb")).each do |path|
        require path

        model_filename = path[/#{Regexp.escape(dir.to_s)}\/([^\.]+).rb/, 1]
        klass          = model_filename.classify.constantize

        # Skip if the class doesn't have Tire integration
        next unless klass.respond_to?(:tire)

        total  = klass.count rescue nil

        Tire::Tasks::Import.add_pagination_to_klass(klass)
        Tire::Tasks::Import.progress_bar(klass, total) if total

        index = klass.tire.index
        Tire::Tasks::Import.delete_index(index) if ENV['FORCE']
        Tire::Tasks::Import.create_index(index, klass)

        Tire::Tasks::Import.import_model(index, klass, params)
        puts
      end

      puts '[Import] Done.'
    end

  end

  namespace :index do

    full_comment_drop = <<-DESC.gsub(/      /, '')
      Delete indices passed in the INDEX/INDICES environment variable; separate multiple indices by comma.

        $ rake environment tire:index:drop INDEX=articles
        $ rake environment tire:index:drop INDICES=articles-2011-01,articles-2011-02

    DESC
    desc full_comment_drop
    task :drop do
      index_names = (ENV['INDEX'] || ENV['INDICES']).to_s.split(/,\s*/)

      if index_names.empty?
        puts '='*90, 'USAGE', '='*90, full_comment_drop, ""
        exit(1)
      end

      index_names.each do |name|
        index = Tire::Index.new(name)
        print "* Deleting index \e[1m#{index.name}\e[0m... "
        puts index.delete ? "\e[32mOK\e[0m" : "\e[31mFAILED\e[0m  | #{index.response.body}"
      end

      puts ""

    end

  end

end
