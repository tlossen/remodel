require 'helper'

class Foo < Remodel::Entity
  property :x
  property :y
end

class Bar < Remodel::Entity
  property :d, :default => 123
end

class TestContext < Test::Unit::TestCase

  context "in_context" do
    should "execute a block in the given context" do
      Remodel.in_context 'a' do
        Foo.create
      end
      assert redis.hexists 'a', 'f:1'
    end
    
    should "not change the context permanently" do
      Remodel.context = 'a'
      Remodel.in_context 'b' do
        2 + 2
      end
      assert_equal 'a', Remodel.context
    end
  end

end
