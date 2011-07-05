require 'helper'

class TestManyToMany < Test::Unit::TestCase

  class Person < Remodel::Entity
    has_many :groups, :class => 'TestManyToMany::Group', :reverse => 'members'
    property :name
  end

  class Group < Remodel::Entity
    has_many :members, :class => 'TestManyToMany::Person', :reverse => 'groups'
    property :name
  end

  context "both associations" do
    should "be empty by default" do
      assert_equal [], Person.new(context).groups
      assert_equal [], Group.new(context).members
    end

    context "create" do
      should "add a new group to both associations" do
        tim = Person.create(context, :name => 'tim')
        rugb = tim.groups.create :name => 'rug-b'
        assert_equal [tim], rugb.members
      end

      should "add a new person to both associations" do
        rugb = Group.create(context, :name => 'rug-b')
        tim = rugb.members.create :name => 'tim'
        assert_equal [rugb], tim.groups
      end
    end

    context "add" do
      setup do
        @tim = Person.create(context, :name => 'tim')
        @rugb = Group.create(context, :name => 'rug-b')
      end

      should "add a new group to both associations" do
        @tim.groups.add(@rugb)
        assert_equal [@tim], @rugb.members
        assert_equal [@rugb], @tim.groups
      end

      should "add a new person to both associations" do
        @rugb.members.add(@tim)
        assert_equal [@tim], @rugb.members
        assert_equal [@rugb], @tim.groups
      end
    end

    context "remove" do
      setup do
        @tim = Person.create(context, :name => 'tim')
        @rugb = @tim.groups.create(:name => 'rug-b')
        @erlang = @tim.groups.create(:name => 'erlang')
        @aws = @tim.groups.create(:name => 'aws')
      end

      should "remove a group from both associations" do
        @tim.groups.remove(@erlang)
        assert_equal [@rugb, @aws], @tim.groups
        assert_equal [], @erlang.members
      end

      should "remove a person from both associations" do
        @erlang.members.remove(@tim)
        assert_equal [@rugb, @aws], @tim.groups
        assert_equal [], @erlang.members
      end

    end
  end

end
