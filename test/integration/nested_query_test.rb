require 'test_helper'

module Tire

  class NestedQueryTest < Test::Unit::TestCase
    include Test::Integration

    context 'Nested queries' do

      setup do
        @index = Tire.index('products-test') do
          delete

          create mappings: {
                   product: {
                      properties: {
                        name:     { type: 'string' },
                        variants: { type: 'nested', size: 'string', color: 'string' }
                      }
                    }
                  }

          store type: 'product',
                name: 'Duck Shirt',
                variants: [{ size: 'M', color: 'yellow'}, { size: 'L', color: 'silver'}]
          store type: 'product',
                name: 'Western Shirt',
                variants: [{ size: 'S', color: 'yellow'}, { size: 'M', color: 'silver'}]

          refresh
        end
      end

      # teardown { @index.delete }

      should "not return a results when properties match for different objects" do
        s = Tire.search @index.name do
          query do
            nested path: 'variants' do
              query do
                boolean do
                  # No product matches size "S" and color "silver"
                  must { match 'variants.size',  'S' }
                  must { match 'variants.color', 'silver'}
                end
              end
            end
          end
        end

        assert_equal 0, s.results.size
      end

      should "return all matching documents when nested documents meet criteria" do
        s = Tire.search @index.name do
          query do
            nested path: 'variants' do
              query do
                match 'variants.size', 'M'
              end
            end
          end
        end

        assert_equal 2, s.results.size
      end

      should "return matching document when a nested document meets all criteria" do
        s = Tire.search @index.name do
          query do
            nested path: 'variants' do
              query do
                boolean do
                  must { match 'variants.size',  'M' }
                  must { match 'variants.color', 'silver'}
                end
              end
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Western Shirt', s.results.first.name
      end

      should "return matching document when both the query and nested document meet all criteria" do
        s = Tire.search @index.name do
          query do
            boolean do
              must do
                match 'name', 'Western'
              end
              must do
                nested path: 'variants' do
                  query do
                    match 'variants.size',  'M'
                  end
                end
              end
            end
          end
        end

        assert_equal 1, s.results.size
        assert_equal 'Western Shirt', s.results.first.name
      end

      should "not return results when the query and the nested document contradict" do
        s = Tire.search @index.name do
          query do
            boolean do
              must do
                match 'name', 'Duck'
              end
              must do
                nested path: 'variants' do
                  query do
                    boolean do
                      must { match 'variants.size',  'M' }
                      must { match 'variants.color', 'silver'}
                    end
                  end
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
