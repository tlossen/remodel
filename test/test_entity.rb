require 'helper'

class Foo < Remodel::Entity
  property :x
  property :y
end

class Bar < Remodel::Entity
  property :d, :default => 123
end

class TestEntity < Test::Unit::TestCase

  context "[default values]" do
    should "be returned for missing properties" do
      bar = Bar.new('cx')
      assert_equal 123, bar.d
    end

    should "be returned for properties that are nil" do
      bar = Bar.new('cx', :d => 'cool')
      bar.d = nil
      assert_equal 123, bar.d
    end

    should "not be returned for given properties" do
      bar = Bar.new('cx', :d => 'cool')
      assert_equal 'cool', bar.d
    end

    should "not be stored" do
      bar = Bar.create('cx')
      assert !(/123/ =~ redis.hget('cx', bar.key))
    end

    should "be returned by as_json" do
      bar = Bar.new('cx')
      assert_equal 123, bar.as_json[:d]
    end
  end

  context "new" do
    should "set properties" do
      foo = Foo.new('cx', :x => 1, :y => 2)
      assert_equal 1, foo.x
      assert_equal 2, foo.y
    end

    should "ignore undefined properties" do
      foo = Foo.new('cx', :z => 3)
      assert foo.instance_eval { !@attributes.key? :z }
    end

    should "not set the key" do
      foo = Foo.new('cx', :x => 23)
      assert_equal nil, foo.key
    end

    should "not set the id" do
      foo = Foo.new('cx', :x => 23)
      assert_equal nil, foo.id
    end
  end

  context "create" do
    setup do
      redis.flushdb
    end

    should "work without attributes" do
      foo = Foo.create('cx')
      assert foo.is_a?(Foo)
    end

    should "give the entity a key based on the class name" do
      assert_equal 'f1', Foo.create('cx').key
      assert_equal 'b1', Bar.create('cx').key
      assert_equal 'b2', Bar.create('cx').key
    end

    should "give the entity an id which is unique per entity class" do
      assert_equal 1, Foo.create('cx').id
      assert_equal 1, Bar.create('cx').id
      assert_equal 2, Bar.create('cx').id
    end

    should "store the entity under its key" do
      foo = Foo.create('cx', :x => 'hello', :y => false)
      assert redis.hexists('cx', foo.key)
    end

    should "store all properties" do
      foo = Foo.create('cx', :x => 'hello', :y => false)
      foo.reload
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end

    should "not store the key as a property" do
      foo = Foo.create('cx', :x => 'hello', :y => false)
      assert !(/f:1/ =~ redis.hget('cx', foo.key))
    end
  end

  context "save" do
    setup do
      redis.flushdb
    end

    should "give the entity a key, if necessary" do
      foo = Foo.new('cx').save
      assert foo.key
    end

    should "store the entity under its key" do
      foo = Foo.new('cx', :x => 'hello', :y => false)
      foo.save
      assert redis.hexists(foo.context, foo.key)
    end

    should "store all properties" do
      foo = Foo.new('cx', :x => 'hello', :y => false)
      foo.save
      foo.reload
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end
  end

  context "reload" do
    setup do
      @foo = Foo.create('cx', :x => 'hello', :y => true)
    end

    should "reload all properties" do
      redis.hset @foo.context, @foo.key, %q({"x":23,"y":"adios"})
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
      redis.hdel @foo.context, @foo.key
      assert_raise(Remodel::EntityNotFound) { @foo.reload }
    end

    should "raise EntityNotSaved if the entity was never saved" do
      assert_raise(Remodel::EntityNotSaved) { Foo.new('cx').reload }
    end
  end

  context "update" do
    setup do
      redis.flushdb
      @foo = Foo.create('cx', :x => 'Tim', :y => true)
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

  context "to_json" do
    should "serialize to json" do
      foo = Foo.new('cx', :x => 42, :y => true)
      assert_match /"x":42/, foo.to_json
      assert_match /"y":true/, foo.to_json
    end
  end

  context "as_json" do
    should "serialize into a hash" do
      foo = Foo.create('cx', :x => 42, :y => true)
      expected = { :id => foo.id, :x => 42, :y => true }
      assert_equal expected, foo.as_json
    end
  end

  context "#set_key_prefix" do
    should "use the given key prefix" do
      class Custom < Remodel::Entity; set_key_prefix 'my'; end
      assert_match /^my\d+$/, Custom.create('cx').key
    end

    should "ensure that the prefix is letters only" do
      assert_raise(Remodel::InvalidKeyPrefix) do
        class InvalidPrefix < Remodel::Entity; set_key_prefix '666'; end
      end
    end
  end

  context "#find" do
    setup do
      redis.flushdb
      @foo = Foo.create('cx', :x => 'hello', :y => 123)
      Foo.create('cx', :x => 'hallo', :y => 124)
    end

    should "find and load an entity by key" do
      foo = Foo.find(@foo.context, @foo.key)
      assert_equal foo.x, @foo.x
      assert_equal foo.y, @foo.y
    end

    should "find and load an entity by id" do
      foo = Foo.find(@foo.context, @foo.id)
      assert_equal foo.x, @foo.x
      assert_equal foo.y, @foo.y
    end

    should "reject a key which does not exist" do
      assert_raise(Remodel::EntityNotFound) { Foo.find('cx', 'x66') }
    end

    should "reject an id which does not exist" do
      assert_raise(Remodel::EntityNotFound) { Foo.find('cx', 66) }
    end
  end

  context "properties" do
    should "have property x" do
      foo = Foo.new('cx')
      foo.x = 23
      assert_equal 23, foo.x
      foo.x += 10
      assert_equal 33, foo.x
    end

    should "not have property z" do
      foo = Foo.new('cx')
      assert_raise(NoMethodError) { foo.z }
      assert_raise(NoMethodError) { foo.z = 42 }
    end

    context "types" do
      should "work with nil" do
        foo = Foo.create('cx', :x => nil)
        assert_equal nil, foo.reload.x
      end

      should "work with booleans" do
        foo = Foo.create('cx', :x => false)
        assert_equal false, foo.reload.x
      end

      should "work with integers" do
        foo = Foo.create('cx', :x => -42)
        assert_equal -42, foo.reload.x
      end

      should "work with floats" do
        foo = Foo.create('cx', :x => 3.141)
        assert_equal 3.141, foo.reload.x
      end

      should "work with strings" do
        foo = Foo.create('cx', :x => 'hello')
        assert_equal 'hello', foo.reload.x
      end

      should "work with lists" do
        foo = Foo.create('cx', :x => [1, 2, 3])
        assert_equal [1, 2, 3], foo.reload.x
      end

      should "work with hashes" do
        hash = { 'a' => 17, 'b' => 'test' }
        foo = Foo.create('cx', :x => hash)
        assert_equal hash, foo.reload.x
      end
    end
  end

  context "#restore" do
    should "restore an entity from json" do
      before = Foo.create('cx', :x => 42, :y => true)
      after = Foo.restore(before.context, before.key, before.to_json)
      assert_equal before.key, after.key
      assert_equal before.x, after.x
      assert_equal before.y, after.y
    end
  end

end
