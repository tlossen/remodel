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
      @group.members.create(:name => 'Tim')
      @group.members.create(:name => 'Ben')
      @group.room = Room.create(:name => 'some office')
      # TODO: @group.reload
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

  end

end
