require 'rake'
require 'ansi/progressbar'
require 'set'

namespace :tire do

  full_comment_import = <<-DESC.gsub(/    /, '')
    Import data from your model using paginate: rake environment tire:import CLASS='MyModel'.

    import all models:
      $ rake tire:import

    Force rebuilding the index (delete and create):
      $ rake tire:import FORCE=1

    Set target classes:
      $ rake tire:import CLASS='Article, Comment'

    OR require a set of files in a directory
      $ rake tire:import DIR='app/models'

  DESC
  desc full_comment_import
  task :import do

    if defined?(Rails)
      puts "[IMPORT] Rails detected, booting environment..."
      Rake::Task["environment"].invoke
    end

    STDOUT.sync = true
    TIRE_MODELS = Set.new
    HRULE       = '='*90

    # Use classes passed with the CLASS env var.
    if (classes = ENV['CLASS']).to_s != ''
      # Use Models in the ENV Vars
      TIRE_MODELS += classes.split(',').map { |k| eval k }
    end

    # Load a directory and use Tire::Search::Model dependants
    if (dir = ENV['DIR']).to_s != ''
      puts "[IMPORT] Loading Directory '#{dir}'"
      Dir.glob(Rails.root.join("#{dir}/**/*.rb")).each { |path| require path }
      TIRE_MODELS = Tire::Model::Search.dependents
    end

    # exit(1) if no models are found!
    puts HRULE, 'USAGE', HRULE, full_comment_import, "" and exit(1) unless TIRE_MODELS.size > 0

    # Import Methods
    TOTAL_COUNT = TIRE_MODELS.map(&:count).reduce(&:+)

    def params
      @params ||= begin
        params = eval(ENV['PARAMS'].to_s) || {}
        params.update :method => 'paginate'
      end
    end

    TIRE_MODELS.each do |klass|

      # Set the Index
      index = ENV['INDEX'].to_s != '' ? Tire::Index.new(ENV['INDEX']) : klass.tire.index

      # Force delete the index
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

      # Add Pagination to the class if it doesn't exist
      if defined?(Kaminari) && klass.respond_to?(:page)
        klass.instance_eval do
          def paginate(options = {})
            page(options[:page]).per(options[:per_page]).to_a
          end
        end
      end unless klass.respond_to?(:paginate)
          documents
        end
      else
        index.import(klass, params) do |documents|
          GC.start
          progress_bar.increment! documents.count
          documents
        end
      end

    end

    puts '[DONE]'

  end

  namespace :index do

    full_comment_drop = <<-DESC.gsub(/      /, '')
      Delete indices passed in the INDEX environment variable; separate multiple indices by comma.

      Pass name of a single index to drop in the INDEX environmnet variable:
        $ rake environment tire:index:drop INDEX=articles

      Pass names of multiple indices to drop in the INDEX or INDICES environmnet variable:
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
