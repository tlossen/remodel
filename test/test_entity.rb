require 'helper'

class Foo < Remodel::Entity
  property :x
  property :y
end

class Bar < Remodel::Entity
  property :d, :default => 123
end

class TestEntity < Test::Unit::TestCase

  context "new" do
    should "set properties" do
      foo = Foo.new(context, :x => 1, :y => 2)
      assert_equal 1, foo.x
      assert_equal 2, foo.y
    end

    should "ignore undefined properties" do
      foo = Foo.new(context, :z => 3)
      assert foo.instance_eval { !@attributes.key? :z }
    end

    should "not set the key" do
      foo = Foo.new(context, :x => 23)
      assert_equal nil, foo.key
    end

    should "not set the id" do
      foo = Foo.new(context, :x => 23)
      assert_equal nil, foo.id
    end
  end

  context "create" do
    setup do
      redis.flushdb
    end

    should "work without attributes" do
      foo = Foo.create(context)
      assert foo.is_a?(Foo)
    end

    should "give the entity a key based on the class name" do
      assert_equal 'f1', Foo.create(context).key
      assert_equal 'b1', Bar.create(context).key
      assert_equal 'b2', Bar.create(context).key
    end

    should "give the entity an id which is unique per entity class" do
      assert_equal 1, Foo.create(context).id
      assert_equal 1, Bar.create(context).id
      assert_equal 2, Bar.create(context).id
    end

    should "store the entity under its key" do
      foo = Foo.create(context, :x => 'hello', :y => false)
      assert redis.hexists(context.key, foo.key)
    end

    should "store all properties" do
      foo = Foo.create(context, :x => 'hello', :y => false)
      foo.reload
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end

    should "not store the key as a property" do
      foo = Foo.create(context, :x => 'hello', :y => false)
      assert !(/f1/ =~ redis.hget(context.key, foo.key))
    end
  end

  context "save" do
    setup do
      redis.flushdb
    end

    should "give the entity a key, if necessary" do
      foo = Foo.new(context).save
      assert foo.key
    end

    should "store the entity under its key" do
      foo = Foo.new(context, :x => 'hello', :y => false)
      foo.save
      assert redis.hexists(context.key, foo.key)
    end

    should "store all properties" do
      foo = Foo.new(context, :x => 'hello', :y => false)
      foo.save
      foo.reload
      assert_equal 'hello', foo.x
      assert_equal false, foo.y
    end

    should "not store nil values" do
      foo = Foo.new(context, :x => nil, :y => false)
      foo.save
      foo.reload
      assert_nil foo.x
      assert_equal '{"y":false}', redis.hget(context.key, foo.key)
    end
  end

  context "reload" do
    setup do
      @foo = Foo.create(context, :x => 'hello', :y => true)
    end

    should "reload all properties" do
      redis.hset(context.key, @foo.key, %q({"x":23,"y":"adios"}))
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
      redis.hdel(context.key, @foo.key)
      assert_raise(Remodel::EntityNotFound) { @foo.reload }
    end

    should "raise EntityNotSaved if the entity was never saved" do
      assert_raise(Remodel::EntityNotSaved) { Foo.new(context).reload }
    end
  end

  context "update" do
    setup do
      redis.flushdb
      @foo = Foo.create(context, :x => 'Tim', :y => true)
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
      foo = Foo.new(context, :x => 42, :y => true)
      assert_match /"x":42/, foo.to_json
      assert_match /"y":true/, foo.to_json
    end
  end

  context "as_json" do
    should "serialize into a hash" do
      foo = Foo.create(context, :x => 42, :y => true)
      expected = { :id => foo.id, :x => 42, :y => true }
      assert_equal expected, foo.as_json
    end
  end

  context "#set_key_prefix" do
    should "use the given key prefix" do
      class Custom < Remodel::Entity; set_key_prefix 'my'; end
      assert_match /^my\d+$/, Custom.create(context).key
    end

    should "ensure that the prefix is letters only" do
      assert_raise(Remodel::InvalidKeyPrefix) do
        class InvalidPrefix < Remodel::Entity; set_key_prefix '666'; end
      end
    end

    should "ensure that the class is a direct subclass of entity" do
      assert_raise(Remodel::InvalidUse) do
        class InvalidSetPrefix < Foo; set_key_prefix 'x'; end
      end
    end
  end

  context "#find" do
    setup do
      redis.flushdb
      @foo = Foo.create(context, :x => 'hello', :y => 123)
      Foo.create(context, :x => 'hallo', :y => 124)
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
      assert_raise(Remodel::EntityNotFound) { Foo.find(context, 'x66') }
    end

    should "reject an id which does not exist" do
      assert_raise(Remodel::EntityNotFound) { Foo.find(context, 66) }
    end
  end

  context "properties" do
    should "have property x" do
      foo = Foo.new(context)
      foo.x = 23
      assert_equal 23, foo.x
      foo.x += 10
      assert_equal 33, foo.x
    end

    should "not have property z" do
      foo = Foo.new(context)
      assert_raise(NoMethodError) { foo.z }
      assert_raise(NoMethodError) { foo.z = 42 }
    end

    context "types" do
      should "work with nil" do
        foo = Foo.create(context, :x => nil)
        assert_equal nil, foo.reload.x
      end

      should "work with booleans" do
        foo = Foo.create(context, :x => false)
        assert_equal false, foo.reload.x
      end

      should "work with integers" do
        foo = Foo.create(context, :x => -42)
        assert_equal -42, foo.reload.x
      end

      should "work with floats" do
        foo = Foo.create(context, :x => 3.141)
        assert_equal 3.141, foo.reload.x
      end

      should "work with strings" do
        foo = Foo.create(context, :x => 'hello')
        assert_equal 'hello', foo.reload.x
      end

      should "work with lists" do
        foo = Foo.create(context, :x => [1, 2, 3])
        assert_equal [1, 2, 3], foo.reload.x
      end

      should "work with hashes" do
        hash = { 'a' => 17, 'b' => 'test' }
        foo = Foo.create(context, :x => hash)
        assert_equal hash, foo.reload.x
      end
    end
  end

  context "#restore" do
    should "restore an entity from json" do
      before = Foo.create(context, :x => 42, :y => true)
      after = Foo.restore(context, before.key, before.to_json)
      assert_equal before.key, after.key
      assert_equal before.x, after.x
      assert_equal before.y, after.y
    end
  end

end
