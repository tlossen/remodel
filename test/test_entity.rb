require 'helper'

class Foo < Remodel::Entity
  property :x
  property :y
end

class Bar < Remodel::Entity; end

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
  
  context "reload" do
    should "reload all properties" do
      foo = Foo.create :x => 'hello', :y => true
      redis.set foo.key, %q({"x":23,"y":"adios"})
      foo.reload
      assert_equal 23, foo.x
      assert_equal 'adios', foo.y
    end
  end
  
  context "create" do
    setup do
      redis.flushdb
    end
    
    should "work without attributes" do
      foo = Foo.create
      assert foo.is_a?(Foo)
    end
    
    should "give the entity a key based on the class name" do
      assert_equal 'f:1', Foo.create.key
      assert_equal 'b:1', Bar.create.key
      assert_equal 'b:2', Bar.create.key
    end
    
    should "store the entity under its key" do
      foo = Foo.create :x => 'hello', :y => false
      assert redis.exists(foo.key)
    end
    
    should "store all properties" do
      foo = Foo.create :x => 'hello', :y => false
      foo.reload
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
      foo.reload
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end
  end
  
   context "#set_key_prefix" do
     should "use the given key prefix" do
       class Custom < Remodel::Entity; set_key_prefix 'my'; end
       assert_match /^my:\d+$/, Custom.create.key
     end
     
     should "ensure that the prefix is letters only" do
       assert_raise(Remodel::InvalidKeyPrefix) do
         class InvalidPrefix < Remodel::Entity; set_key_prefix '666'; end
       end
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
    
    should "raise EntityNotFound if the key does not exist" do
      assert_raise(Remodel::EntityNotFound) { Foo.find(23) }
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
    
    context "types" do
      should "work with nil" do
        foo = Foo.create :x => nil
        assert_equal nil, foo.reload.x
      end
      
      should "work with booleans" do
        foo = Foo.create :x => false
        assert_equal false, foo.reload.x
      end
      
      should "work with integers" do
        foo = Foo.create :x => -42
        assert_equal -42, foo.reload.x
      end
      
      should "work with floats" do
        foo = Foo.create :x => 3.141
        assert_equal 3.141, foo.reload.x
      end
      
      should "work with strings" do
        foo = Foo.create :x => 'hello'
        assert_equal 'hello', foo.reload.x
      end

      should "work with lists" do
        foo = Foo.create :x => [1, 2, 3]
        assert_equal [1, 2, 3], foo.reload.x
      end
      
      should "work with hashes" do
        hash = { 'a' => 17, 'b' => 'test' }
        foo = Foo.create :x => hash
        assert_equal hash, foo.reload.x
      end
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
