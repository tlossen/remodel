require 'helper'

class TestManyToMany < Test::Unit::TestCase

  class Person < Remodel::Entity
    has_many :groups, :class => 'TestManyToMany::Group', :reverse => 'members'
  end

  class Group < Remodel::Entity
    has_many :members, :class => 'TestManyToMany::Person', :reverse => 'groups'
  end

  context "both associations" do
    should "be empty by default" do
      assert_equal [], Person.new.groups
      assert_equal [], Group.new.members
    end
    
    should "have a create method" do
      assert Person.new.groups.respond_to?(:create)
      assert Group.new.members.respond_to?(:create)
    end
  end
  
end
