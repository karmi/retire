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
  DESC
  desc full_comment_import
  task :import => :environment do

    STDOUT.sync = true
    TIRE_MODELS = Set.new
    HRULE       = '='*90

    if ENV['CLASS'].to_s != ''
      # Use Models in the ENV Vars
      TIRE_MODELS += ENV['CLASS'].split(',').map { |k| eval k }

    else
      # Find all the classes which call mapping
      puts "\n", "[IMPORT] Preloading Models..."
      Tire::Model::Search::ClassMethods.module_eval do
        def mapping(*args, &block)
          TIRE_MODELS << self.klass
          super(*args, &block)
        end
      end

      # Require everything in the models directory
      Dir.glob(Rails.root.join('app/models/**/*.rb')).each { |path| require path }
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

      puts "\n\n"

      index = klass.tire.index

      # Force delete the index
      if ENV['FORCE']
        puts "[IMPORT] Deleting index '#{index.name}'"
        index.delete
      end

      # Create the index if it doesn't exist
      unless index.exists?
        mapping = MultiJson.encode(klass.tire.mapping_to_hash, :pretty => Tire::Configuration.pretty)
        puts "[IMPORT] Creating index '#{index.name}' with mapping:", mapping
        unless index.create(:mappings => klass.tire.mapping_to_hash, :settings => klass.tire.settings)
          STDERR.puts "[ERROR] There has been an error when creating the index -- elasticsearch returned:",
                      index.response
          exit(1)
        end
      end

      puts "[IMPORT] Starting import for the '#{klass}' class"
      progress_bar = ProgressBar.new(klass.count)

      # Use an indexer scope if it is defined
      klass = klass.indexer if klass.respond_to? :indexer

      # Try and use AR find_in_batches
      if klass.respond_to?(:find_in_batches)
        klass.find_in_batches do |group|
          index.import(group, params) do |documents|
            GC.start
            progress_bar.increment! documents.count
            documents
          end
        end
      elsif klass.respond_to? :all
        index.import(klass.all, params) do |documents|
          GC.start
          progress_bar.increment! documents.count
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
