require 'helper'

class Item < Remodel::Entity
  property :time, :mapper => Remodel::TimeMapper
end

class TestMappers < Test::Unit::TestCase

  context "create" do
    setup do
      @item = Item.create :time => Time.at(1234567890)
    end
    
    should "not change" do
      assert_equal Time.at(1234567890), @item.time
      assert_equal "Fri Feb 13 23:31:30 UTC 2009", @item.time.utc.to_s
    end

    should "not change after reload" do
      @item.reload
      assert_equal Time.at(1234567890), @item.time
      assert_equal "Fri Feb 13 23:31:30 UTC 2009", @item.time.utc.to_s
    end
    
    should "serialize time as integer value" do
      assert_match /1234567890/, redis.get(@item.key)
    end
    
  end
  
end
