$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rubygems'
require 'tire'

extend Tire::DSL

configure do
  url "http://localhost:9200"
end

index 'articles' do
  delete
  create

  puts "Documents:", "-"*80
  [
    { :title => 'One',   :tags => ['ruby'] },
    { :title => 'Two',   :tags => ['ruby', 'python'] },
    { :title => 'Three', :tags => ['java'] },
    { :title => 'Four',  :tags => ['ruby', 'php'] }
  ].each do |article|
    puts "Indexing article: #{article.to_json}"
    store article
  end  

  refresh
end

s = search 'attachments-index' do
  query do
    boolean do
      must { term :hash, '6e961aabb904c6a838603adadfd2ca0a_805888' }
      must { term :hash, '6e961aabb904c6a838603adadfd2ca0a_805888' }
    end
  end
end

s = search 'articles' do
  query do
    b
    string 'T*'
  end

  filter :terms, :tags => ['ruby']

  sort do
    title 'desc'
  end

  facet 'global-tags' do
    terms :tags, :global => true
  end

  facet 'current-tags' do
    terms :tags
  end
end

puts "", "Query:", "-"*80
puts s.to_json

puts "", "Raw JSON result:", "-"*80
puts JSON.pretty_generate(s.response)

puts "", "Try the query in Curl:", "-"*80
puts s.to_curl

puts "", "Results:", "-"*80
s.results.each_with_index do |document, i|
  puts "#{i+1}. #{ document.title.ljust(10) } [id] #{document._id}"
end

puts "", "Facets: tags distribution across the whole database:", "-"*80
s.results.facets['global-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(13)} #{f['count']}"
end

puts "", "Facets: tags distribution for the current query ",
         "(Notice that 'java' is included, because of the filter)", "-"*80
s.results.facets['current-tags']['terms'].each do |f|
  puts "#{f['term'].ljust(13)} #{f['count']}"
end
