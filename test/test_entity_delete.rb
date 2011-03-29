require 'helper'

class TestEntityDelete < Test::Unit::TestCase

  class Group < Remodel::Entity
    has_many :members, :class => 'TestEntityDelete::Person'
    has_one :room, :class => 'TestEntityDelete::Room'
    property :name
  end

  class Person < Remodel::Entity
    property :name
  end

  class Room < Remodel::Entity
    property :name
  end

  context "delete" do
    setup do
      redis.flushdb
      @group = Group.create('cx', :name => 'ruby user group')
      @tim = @group.members.create(:name => 'Tim')
      @group.members.create(:name => 'Ben')
      @room = Room.create(:name => 'some office')
      @group.room = @room
      @group.reload
    end

    should "ensure that the entity is persistent" do
      assert_raise(Remodel::EntityNotSaved) { Group.new('cx').delete }
    end

    should "delete the given entity" do
      @group.delete
      assert_nil redis.hget(@group.context, @group.key)
    end

    should "delete any associations in redis" do
      @group.delete
      assert_nil redis.hget(@group.context, "#{@group.key}_members")
      assert_nil redis.hget(@group.context, "#{@group.key}_room")
    end

    context "has_one" do
      should "be nil if deleted" do
        @room.delete
        assert_nil @group.room
      end
    end

    context "has_many" do
      should "be skipped if deleted" do
        @tim.delete
        assert_equal 1, @group.members.count
      end
    end

  end
  
end
