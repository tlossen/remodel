require 'helper'


class Foo < Remodel::Base
  
  property :x

end


class TestBase < Test::Unit::TestCase

  context "foo" do
    should "have property x" do
      foo = Foo.new :x => 23
      assert_equal 23, foo.x
      foo.x += 1
      assert_equal 24, foo.x
    end
  end
  
end
