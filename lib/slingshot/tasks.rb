require 'rake'
require 'benchmark'

namespace :slingshot do
  desc "Import data from your ActiveModel model: rake environment slingshot:import CLASS='MyModel' PARAMS='{:page => 1}' FORCE=1"
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
      puts "[ERROR] Please provide a class you wish to import data from in a CLASS environment variable."
      exit(1)
    end

    klass  = eval(ENV['CLASS'].to_s)
    params = eval(ENV['PARAMS'].to_s) || {}

    if ENV['FORCE']
      puts "[IMPORT] Deleting index '#{klass.index.name}'"
      klass.index.delete
      puts "[IMPORT] Creating index '#{klass.index.name}' with mapping:",
           Yajl::Encoder.encode(klass.mapping_to_hash, :pretty => true)
      klass.index.create :mappings => klass.mapping_to_hash
    end

    STDOUT.sync = true
    puts "[IMPORT] Starting import for the '#{ENV['CLASS']}' class"
    cols = 80

    STDOUT.puts '-'*cols
    elapsed = Benchmark.realtime do
      eval(ENV['CLASS'].to_s).import(params) do |total, done|

        # I CAN HAZ PROGREZ BAR LIEK HOMEBRU!
        percent  = ( (done.to_f / total) * 100 ).to_i
        STDOUT.print( ("#" * ( percent*((cols-4).to_f/100)).to_i )+" ")
        STDOUT.print("\r"*cols+"#{percent}% ")
      end
    end

    puts "", '-'*80, "Import finished in #{elapsed_to_human(elapsed)}"

  end
end
