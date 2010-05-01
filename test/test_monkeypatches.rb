require 'helper'

class TestMonkeypatches < Test::Unit::TestCase

  context "Boolean" do
    should "be the superclass of both true and false" do
      assert true.is_a?(Boolean)
      assert false.is_a?(Boolean)
    end
  end

  context "Class[]" do
    should "return given Class objects" do
      assert_equal String, Class[String]
    end

    should "return the Class object for a given String" do
      assert_equal String, Class['String']
    end

    should "return the Class object for a given Symbol" do
      assert_equal String, Class[:String]
    end

    should "work for nested classes" do
      assert_equal Remodel::Entity, Class['Remodel::Entity']
    end
  end

end
