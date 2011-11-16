require 'rake'
require 'benchmark'

namespace :tire do

  usage = <<-DESC
          Import data from your model using paginate: rake environment tire:import CLASS='MyModel'

          Pass params for the `paginate` method:
            $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}'

          Use a method other than `paginate` (only use if your db operates batch retrievals natively):
            $ rake environment tire:import CLASS='Article' FINDER_METHOD='all'

          Force rebuilding the index (delete and create):
            $ rake environment tire:import CLASS='Article' PARAMS='{:page => 1}' FORCE=1

          Set target index name:
            $ rake environment tire:import CLASS='Article' INDEX='articles-new'
    
  DESC

  desc usage.split("\n").first.to_s
  task :import do

    def elapsed_to_human(elapsed)
      hour = 60*60
      day  = hour*24

      case elapsed
      when 0..59
        "#{sprintf("%1.5f", elapsed)} seconds"
      when 60..hour-1
        "#{elapsed/60} minutes and #{elapsed % 60} seconds"
      when hour..day
        "#{elapsed/hour} hours and #{elapsed % hour} minutes"
      else
        "#{elapsed/hour} hours"
      end
    end

    if ENV['CLASS'].to_s == ''
      puts '='*80, 'USAGE', '='*80, usage.gsub(/          /, '')
      exit(1)
    end

    klass  = eval(ENV['CLASS'].to_s)
    params = eval(ENV['PARAMS'].to_s) || {}
    finder_method = ENV['FINDER_METHOD'] || 'paginate'

    index = Tire::Index.new( ENV['INDEX'] || klass.tire.index.name )

    if ENV['FORCE']
      puts "[IMPORT] Deleting index '#{index.name}'"
      index.delete
    end

    unless index.exists?
      mapping = defined?(Yajl) ? Yajl::Encoder.encode(klass.tire.mapping_to_hash, :pretty => true) :
                                 MultiJson.encode(klass.tire.mapping_to_hash)
      puts "[IMPORT] Creating index '#{index.name}' with mapping:", mapping
      index.create :mappings => klass.tire.mapping_to_hash, :settings => klass.tire.settings
    end

    STDOUT.sync = true
    puts "[IMPORT] Starting import for the '#{ENV['CLASS']}' class"
    tty_cols = 80
    total    = klass.count rescue nil
    offset   = (total.to_s.size*2)+8
    done     = 0

    STDOUT.puts '-'*tty_cols
    elapsed = Benchmark.realtime do
      index.import(klass, finder_method, params) do |documents|

        if total
          done += documents.size
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
end
