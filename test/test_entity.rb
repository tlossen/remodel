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
    
    should "not set the key" do
      foo = Foo.new :x => 23
      assert_equal nil, foo.key
    end
    
    should "not set the id" do
      foo = Foo.new :x => 23
      assert_equal nil, foo.id      
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
    
    should "give the entity an id which is unique per entity class" do
      assert_equal 1, Foo.create.id
      assert_equal 1, Bar.create.id
      assert_equal 2, Bar.create.id
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

    should "not store the key as a property" do
      foo = Foo.create :x => 'hello', :y => false
      assert !(/f:1/ =~ redis.get(foo.key))
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
  
  context "reload" do
    setup do
      @foo = Foo.create :x => 'hello', :y => true
    end

    should "reload all properties" do
      redis.set @foo.key, %q({"x":23,"y":"adios"})
      @foo.reload
      assert_equal 23, @foo.x
      assert_equal 'adios', @foo.y
    end
    
    should "keep the key" do
      key = @foo.key
      @foo.reload
      assert_equal key, @foo.key
    end
    
    should "stay the same object" do
      id = @foo.object_id
      @foo.reload
      assert_equal id, @foo.object_id
    end
    
    should "raise EntityNotFound if the entity does not exist any more" do
      redis.del @foo.key
      assert_raise(Remodel::EntityNotFound) { @foo.reload }
    end
    
    should "raise EntityNotSaved if the entity was never saved" do
      assert_raise(Remodel::EntityNotSaved) { Foo.new.reload }
    end
  end
  
  context "update" do
    setup do
      redis.flushdb
      @foo = Foo.create :x => 'Tim', :y => true
    end
    
    should "set the given properties" do
      @foo.update(:x => 12, :y => 'Jan')
      assert_equal 12, @foo.x
      assert_equal 'Jan', @foo.y
    end
    
    should "save the entity" do
      @foo.update(:x => 12, :y => 'Jan')
      @foo.reload
      assert_equal 12, @foo.x
      assert_equal 'Jan', @foo.y
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
  end
  
  context "restore" do
    should "restore an entity from json" do
      before = Foo.create :x => 42, :y => true
      after = Foo.restore(before.key, before.to_json)
      assert_equal before.key, after.key
      assert_equal before.x, after.x
      assert_equal before.y, after.y
    end
  end
  
end
