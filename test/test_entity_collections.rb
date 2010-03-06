require 'helper'

class Foo < Remodel::Entity
  has_many :items, :class => 'Item'
  property :x
  property :y
end

class Item < Remodel::Entity
  belongs_to :foo
  property :name
end

class TestEntity < Test::Unit::TestCase

  context "has_many" do
    context "collection property" do
      should "exist" do
        foo = Foo.create
        assert foo.respond_to?(:items)
      end
    
      should "return an empty list by default" do
        foo = Foo.create
        assert_equal [], foo.items
      end
    
      should "return any existing children" do
        foo = Foo.create
        redis.rpush "#{foo.key}:items", Item.create(:name => 'tim').key
        redis.rpush "#{foo.key}:items", Item.create(:name => 'jan').key
        assert_equal 2, foo.items.size
        assert_equal Item, foo.items[0].class
        assert_equal 'tim', foo.items[0].name
      end
    
      context "create" do
        should "have a create method" do
          foo = Foo.create
          assert foo.items.respond_to?(:create)
        end
      
        should "create and store a new child" do
          foo = Foo.create
          foo.items.create :name => 'bodo'
          foo.items.create :name => 'logo'
          assert_equal 2, foo.items.size
          foo.reload
          assert_equal 2, foo.items.size
          assert_equal Item, foo.items[1].class
          assert_equal 'logo', foo.items[1].name
        end
      end
    end
  end
  
  context "belongs_to" do
    should "have a getter for the parent" do
      item = Item.create
      assert item.foo.nil?
    end
  end
  
end
