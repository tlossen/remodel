require 'helper'


class Foo < Remodel::Entity
  
  property :x
  property :y

end


class TestEntity < Test::Unit::TestCase

  context "properties" do
    should "have property x" do
      foo = Foo.new :x => 23
      assert_equal 23, foo.x
      foo.x += 1
      assert_equal 24, foo.x
    end
  end
  
  context "json" do
    should "serialize to json" do
      foo = Foo.new :x => 42, :y => true
      assert_equal %q({"x":42,"y":true}), foo.to_json
    end
    
    should "create from json" do
      foo = Foo.from_json %q({"x":23,"y":false})
      assert_equal 23, foo.x
      assert_equal false, foo.y
    end
  end
  
end
