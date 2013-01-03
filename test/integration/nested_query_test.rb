require 'test_helper'

module Tire

  class NestedQueryTest < Test::Unit::TestCase
    include Test::Integration

    context 'Nested queries' do

      setup do
        Tire.index('products') do
          delete 

          create :mappings => {
            :product => {
              :name => { :type => 'string' },
              :properties => { :variants => { :type => 'nested', :size => 'string', :color => 'string' } }
            }
          }

          store :type => 'product', :name => 'Duck Shirt',
            :variants => [{ :size => 'M', :color => 'yellow'}, { :size => 'L', :color => 'silver'}]
          store :type => 'product', :name => 'Western Shirt',
            :variants => [{ :size => 'S', :color => 'yellow'}, { :size => 'M', :color => 'silver'}]

          refresh
        end
      end

      should 'search normally on non-nested types' do
        s = Tire.search('products') do
          query do
            boolean do
              must { string 'name:Duck' }
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Duck Shirt', s.results.first.name
      end

      should 'not return results for a standard query on a nested document' do
        s = Tire.search('products') do
          query do
            boolean do
              must { string 'variants.size:M' }
            end
          end
        end

        assert_equal 0, s.results.size
      end

      should 'return a root document when the nested document meets all criteria' do
        s = Tire.search('products') do
          query do
            nested :path => 'variants' do
              query do
                boolean do
                  must { string 'variants.size:M' }
                  must { string 'variants.color:silver'}
                end
              end
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Western Shirt', s.results.first.name
      end

      should 'return a root document when the nested document and standard query match all criteria' do
        s = Tire.search('products') do
          query do
            boolean do
              must { string 'name:Western' }
              must do
                nested :path => 'variants' do
                  query do
                    boolean do
                      must { string 'variants.size:M' }
                      must { string 'variants.color:silver'}
                    end
                  end
                end
              end
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Western Shirt', s.results.first.name
      end

      should 'not return a root document when the nested document and standard query contradict' do
        s = Tire.search('products') do
          query do
            boolean do
              must { string 'name:Duck' }
              must do
                nested :path => 'variants' do
                  query do
                    boolean do
                      must { string 'variants.size:M' }
                      must { string 'variants.color:silver'}
                    end
                  end
                end
              end
            end
          end
        end

        assert_equal 0, s.results.size
      end

      should 'not return a cross-object result' do
        s = Tire.search('products') do
          query do
            nested :path => 'variants' do
              query do
                boolean do
                  must { string 'variants.size:S' }
                  must { string 'variants.color:silver'}
                end
              end
            end
          end
        end

        assert_equal 0, s.results.size
      end

    end
  end

end
