require 'rake'
require 'benchmark'

namespace :tire do

  full_comment_import = <<-DESC.gsub(/    /, '')
    Import data from your model using paginate: rake environment tire:import CLASS='MyModel'.

    Pass params for the `paginate` method:
      $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}'

    Force rebuilding the index (delete and create):
      $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}' FORCE=1

    Set target index name:
      $ rake environment tire:import CLASS='Article' INDEX='articles-new'
  DESC
  desc full_comment_import
  task :import do |t|

    def elapsed_to_human(elapsed)
      hour = 60*60
      day  = hour*24

      case elapsed
      when 0..59
        "#{sprintf("%1.2f", elapsed)} seconds"
      when 60..hour-1
        "#{(elapsed/60).floor} minutes and #{(elapsed % 60).floor} seconds"
      when hour..day
        "#{(elapsed/hour).floor} hours and #{(elapsed/60 % hour).floor} minutes"
      else
        "#{(elapsed/hour).round} hours"
      end
    end

    if ENV['CLASS'].to_s == ''
      puts '='*90, 'USAGE', '='*90, full_comment_import, ""
      exit(1)
    end

    klass  = eval(ENV['CLASS'].to_s)
    params = eval(ENV['PARAMS'].to_s) || {}

    params.update :method => 'paginate'

    index = Tire::Index.new( ENV['INDEX'] || klass.tire.index.name )

    if ENV['FORCE']
      puts "[IMPORT] Deleting index '#{index.name}'"
      index.delete
    end

    unless index.exists?
      mapping = MultiJson.encode(klass.tire.mapping_to_hash, :pretty => Tire::Configuration.pretty)
      puts "[IMPORT] Creating index '#{index.name}' with mapping:", mapping
      unless index.create( :mappings => klass.tire.mapping_to_hash, :settings => klass.tire.settings )
        STDERR.puts "[ERROR] There has been an error when creating the index -- elasticsearch returned:",
                    index.response
        exit(1)
      end
    end

    STDOUT.sync = true
    puts "[IMPORT] Starting import for the '#{ENV['CLASS']}' class"
    tty_cols = 80
    total    = klass.count rescue nil
    offset   = (total.to_s.size*2)+8
    done     = 0

    STDOUT.puts '-'*tty_cols
    elapsed = Benchmark.realtime do

      # Add Kaminari-powered "paginate" method
      #
      if defined?(Kaminari) && klass.respond_to?(:page)
        klass.instance_eval do
          def paginate(options = {})
            page(options[:page]).per(options[:per_page]).to_a
          end
        end
      end unless klass.respond_to?(:paginate)

      # Import the documents
      #
      index.import(klass, params) do |documents|

        if total
          done += documents.to_a.size
          # I CAN HAZ PROGREZ BAR LIEK HOMEBRU!
          percent  = ( (done.to_f / total) * 100 ).to_i
          glyphs   = ( percent * ( (tty_cols-offset).to_f/100 ) ).to_i
          STDOUT.print( "#" * glyphs )
          STDOUT.print( "\r"*tty_cols+"#{done}/#{total} | \e[1m#{percent}%\e[0m " )
        end

        # Don't forget to return the documents collection back!
        documents
      end
    end

    puts "", '='*80, "Import finished in #{elapsed_to_human(elapsed)}"
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
        puts  index.delete ? "\e[32mOK\e[0m" : "\e[31mFAILED\e[0m  | #{index.response.body}"
      end

      puts ""

    end

  end

end
