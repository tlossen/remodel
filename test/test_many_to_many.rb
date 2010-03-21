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
      assert_equal [], Person.new.groups
      assert_equal [], Group.new.members
    end
    
    context "create" do
      should "add a new group to both associations" do
        tim = Person.create :name => 'tim'
        rugb = tim.groups.create :name => 'rug-b'
        assert_equal [tim], rugb.members
      end
      
      should "add a new person to both associations" do
        rugb = Group.create :name => 'rug-b'
        tim = rugb.members.create :name => 'tim'
        assert_equal [rugb], tim.groups
      end
    end
    
    context "add" do
      setup do
        @tim = Person.create :name => 'tim'
        @rugb = Group.create :name => 'rug-b'
      end
      
      should "add a new group to both associations" do
        @tim.groups.add(@rugb)
        assert_equal [@tim], @rugb.members
      end
      
      should "add a new person to both associations" do
        @rugb.members.add(@tim)
        assert_equal [@rugb], @tim.groups
      end
    end
  end
  
end
