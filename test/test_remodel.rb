require 'helper'

class TestRemodel < Test::Unit::TestCase

  context "create_context" do
    should "create a context" do
      context = Remodel.create_context('foo')
      assert_equal Remodel::Context, context.class
      assert_equal 'foo', context.key
    end

    should "create a caching context, if specified" do
      context = Remodel.create_context('foo', :caching => true)
      assert_equal Remodel::CachingContext, context.class
      assert_equal 'foo', context.key
    end
  end

end
