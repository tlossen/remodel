require 'helper'

class Foo < Remodel::Entity
  property :x
  property :y
end

class TestEntity < Test::Unit::TestCase

  context "new" do
    should "set properties" do
      foo = Foo.new :x => 1, :y => 2
      assert 1, foo.x
      assert 2, foo.y
    end
    
    should "ignore undefined properties" do
      foo = Foo.new :z => 3
      assert foo.instance_eval { !@attributes.key? :z }
    end
  end
  
  context "create" do
    setup do
      Remodel.redis.flushdb
    end
    
    should "give the entity a key" do
      foo = Foo.create :x => 'hello', :y => false
      assert_equal 1, foo.key
    end
    
    should "store the entity in redis" do
      foo = Foo.create :x => 'hello', :y => false
      assert Remodel.redis.get(foo.key)
    end
  end
  
  context "save" do
    setup do
      Remodel.redis.flushdb
    end
    
    should "store the entity in redis" do
      foo = Foo.new
      foo.x = 42
      foo.save
      assert 1, foo.key
      assert Remodel.redis.get(foo.key)
    end
  end
  
  context "find" do
    setup do
      Remodel.redis.flushdb
      @foo = Foo.create :x => 'hello', :y => 123
    end
    
    should "load an entity from redis" do
      foo = Foo.find(@foo.key)
      assert_equal foo.x, @foo.x
      assert_equal foo.y, @foo.y
    end
    
    should "raise NotFound if the key does not exist" do
      assert_raise(Remodel::NotFound) { Foo.find(23) }
    end
  end

  context "properties" do
    should "always have a property key" do
      foo = Foo.new
      assert foo.key.nil?
    end
    
    should "have property x" do
      foo = Foo.new
      foo.x = 23
      assert_equal 23, foo.x
      foo.x += 10
      assert_equal 33, foo.x
    end
    
    should "not have property z" do
      foo = Foo.new
      assert_raise(NoMethodError) { foo.z }
      assert_raise(NoMethodError) { foo.z = 42 }
    end
  end
  
  context "json" do
    should "serialize to json" do
      foo = Foo.new :x => 42, :y => true
      assert_equal %q({"x":42,"y":true}), foo.to_json
    end
    
    should "create from json" do
      foo = Foo.from_json %q({"x":23,"y":false})
      assert_equal 23, foo.x
      assert_equal false, foo.y
    end
  end
  
end
