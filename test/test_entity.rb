require 'helper'

class Foo < Remodel::Entity
  has_many :items
  property :x
  property :y
end

class Item < Remodel::Entity
  belongs_to :foo
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
      redis.flushdb
    end
    
    should "give the entity a key based on the class name" do
      assert_equal 'f:1', Foo.create.key
      assert_equal 'i:1', Item.create.key
      assert_equal 'i:2', Item.create.key
    end
    
    should "store the entity under its key" do
      foo = Foo.create :x => 'hello', :y => false
      assert redis.exists(foo.key)
    end
    
    should "store all properties" do
      foo = Foo.create :x => 'hello', :y => false
      foo = Foo.find(foo.key)
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end
  end
  
  context "save" do
    setup do
      redis.flushdb
    end
    
    should "give the entity a key, if necessary" do
      foo = Foo.new.save
      assert foo.key
    end
    
    should "store the entity under its key" do
      foo = Foo.new :x => 'hello', :y => false
      foo.save
      assert redis.exists(foo.key)
    end

    should "store all properties" do
      foo = Foo.new :x => 'hello', :y => false
      foo.save
      foo = Foo.find(foo.key)
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end
  end
  
  context "find" do
    setup do
      redis.flushdb
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
      assert Foo.new.respond_to?(:key)
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
  
  context "has_many" do
    should "have a getter for the children" do
      foo = Foo.create
      assert_equal [], foo.items
    end
  end
  
  context "belongs_to" do
    should "have a getter for the parent" do
      item = Item.create
      assert item.foo.nil?
    end
  end
  
  context "json" do
    should "serialize to json" do
      foo = Foo.new :x => 42, :y => true
      assert_match /"x":42/, foo.to_json
      assert_match /"y":true/, foo.to_json
    end
    
    should "create from json" do
      foo = Foo.from_json %q({"x":23,"y":false})
      assert_equal 23, foo.x
      assert_equal false, foo.y
    end
    
    should "work in roundtrip" do
      before = Foo.new :x => 42, :y => true
      after = Foo.from_json(before.to_json)
      assert_equal before.x, after.x
      assert_equal before.y, after.y
    end
  end
  
end
