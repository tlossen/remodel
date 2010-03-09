require 'helper'

class Item < Remodel::Entity
  property :time, :mapper => Remodel::TimeMapper
  property :date, :mapper => Remodel::DateMapper
end

class TestMappers < Test::Unit::TestCase

  context "create" do
    setup do
      @item = Item.create :time => Time.at(1234567890), :date => Date.parse("1972-06-16")
    end
    
    should "store unmapped values" do
      assert_equal Time, @item.instance_eval { @attributes[:time].class }
      assert_equal Date, @item.instance_eval { @attributes[:date].class }
    end
    
    should "not change mapped values" do
      assert_equal Time.at(1234567890), @item.time
      assert_equal Date.parse("1972-06-16"), @item.date
    end

    should "not change mapped values after reload" do
      @item.reload
      assert_equal Time.at(1234567890), @item.time
      assert_equal Date.parse("1972-06-16"), @item.date
    end
    
    should "serialize mapped values correctly" do
      json = redis.get(@item.key)
      assert_match /1234567890/, json
      assert_match /"1972-06-16"/, json
    end
    
  end
  
end
