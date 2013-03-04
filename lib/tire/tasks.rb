require 'rake'
require 'set'

namespace :tire do

  import_desc = <<-DESC.gsub(/    /, '')
    Import data from your model using paginate: rake environment tire:import CLASS='MyModel'.

    Pass params for the `paginate` method:
      $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}'

    Force rebuilding the index (delete and create):
      $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}' FORCE=1

    Set target index name:
      $ rake environment tire:import CLASS='Article' INDEX='articles-new'
  DESC

  import_all_desc = <<-DESC.gsub(/    /, '')
    TODO: Describe Import all...
  DESC

  namespace :import do

    HRULE = '='*90

    def build_index(index, klass)
      # Delete the index if force is passed
      if ENV['FORCE']
        puts "[IMPORT] Deleting index '#{index.name}'"
        index.delete
      end

      # Create the index if it doesn't exist
      unless index.exists?
        mapping = MultiJson.encode(klass.tire.mapping_to_hash, :pretty => Tire::Configuration.pretty)
        puts "[IMPORT] Creating index '#{index.name}' with mapping:",
             mapping
        unless index.create(:mappings => klass.tire.mapping_to_hash, :settings => klass.tire.settings)
          STDERR.puts "[ERROR] There has been an error when creating the index -- elasticsearch returned:",
                      index.response
          exit(1)
        end
      end
    end

    # Add Pagination to the class if it doesn't exist
    def add_pagination_to_klass(klass)
      if defined?(Kaminari) && klass.respond_to?(:page)
        klass.instance_eval do
          def paginate(options = {})
            page(options[:page]).per(options[:per_page])
          end
        end
      end unless klass.respond_to?(:paginate)
    end

    def create_progress_bar(klass)
      require 'progress_bar'
      ProgressBar.new klass.count
    rescue LoadError
      puts <<-INFO.gsub(/        /, '') unless @progress_bar_message_shown
        [IMPORT] To display a progress bar add the following to your Gemfile:

                   gem 'progress_bar', require: false

        INFO
      @progress_bar_message_shown = true
      # Create a stub so that progress_bar methods dont raise errors
      progress_bar_stub
    rescue NoMethodError
      puts "[IMPORT] #{klass} does not respond to count. Skipping progress bar"
      progress_bar_stub
    end

    def progress_bar_stub
      @progress_bar_stub ||= Module.new do
        def self.method_missing(*args)
          self
        end
      end
    end

    def do_import(index, klass, params)
      build_index index, klass
      add_pagination_to_klass klass
      puts "[IMPORT] Starting import for the '#{klass}' class"
      progress_bar = create_progress_bar klass
      # Use the model importer if it exists for this class
      if klass.ancestors.include?(Tire::Model::Search)
        options = params.update({ :index => index.name })
        klass.tire.import options do |documents|
          document_count = documents.to_a.size
          progress_bar.increment! document_count
          documents
        end
      else
        # Try and import the class normally
        index.import(klass, params) do |documents|
          document_count = documents.to_a.size
          progress_bar.increment! document_count
          documents
        end
      end
    end

    desc import_desc
    task :model do
      STDOUT.sync = true

      # Load the environment if Rails exists
      if defined?(Rails)
        puts "[IMPORT] Rails detected, booting environment..."
        Rake::Task["environment"].invoke
      end

      # Raise and exit if no class is defined.
      if ENV['CLASS'].to_s == ''
        puts HRULE, 'USAGE', HRULE, import_desc, ""
        exit(1)
      end

      # Get the klass
      klass  = eval(ENV['CLASS'].to_s)

      # Set the Params
      params = eval(ENV['PARAMS'].to_s) || {}
      params.update :method => 'paginate'

      # Set the index
      index = Tire::Index.new(ENV['INDEX'] || klass.tire.index.name)

      # Do the import
      do_import(index, klass, params)
      puts '[DONE]'

    end

    desc import_all_desc
    task :all do
      STDOUT.sync = true

      # Load the environment if Rails exists
      if defined?(Rails)
        puts "[IMPORT] Rails detected, booting environment..."
        Rake::Task["environment"].invoke
      end

      # Set the directory to load
      dir = ENV['DIR'].to_s != '' ? ENV['DIR'] : 'app/models'

      puts "[IMPORT] Loading Directory '#{dir}'"
      Dir.glob(Rails.root.join("#{dir}/**/*.rb")).each { |path| require path }

      # Set the Params
      params = eval(ENV['PARAMS'].to_s) || {}
      params.update :method => 'paginate'

      # Import All the classes
      Tire::Model::Search.dependents.each do |klass|
        index = klass.tire.index

        # Do the import
        do_import(index, klass, params)
      end

      puts '[DONE]'

    end

  end

  task :import => ["import:model"]

  namespace :index do

    full_comment_drop = <<-DESC.gsub(/      /, '')
      Delete indices passed in the INDEX environment variable; separate multiple indices by comma.

      Pass name of a single index to drop in the INDEX environment variable:
        $ rake environment tire:index:drop INDEX=articles

      Pass names of multiple indices to drop in the INDEX or INDICES environment variable:
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
