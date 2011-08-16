require 'helper'

class TestEntityShortnames < Test::Unit::TestCase

  class Foo < Remodel::Entity; end

  class Bar < Remodel::Entity
    property :test, :short => 'z'
    has_one  :foo,  :short => 'y', :class => Foo
    has_many :foos, :short => 'x', :class => Foo
  end

  context "property shortnames" do
    setup do
      @bar = Bar.create(context, :test => 42)
    end

    should "be used when storing properties" do
      serialized = redis.hget(context.key, @bar.key)
      assert !serialized.match(/test/)
      assert serialized.match(/z/)
    end

    should "work in roundtrip" do
      @bar.reload
      assert_equal 42, @bar.test
    end

    should "not be used in as_json" do
      assert !@bar.as_json.has_key?(:z)
      assert @bar.as_json.has_key?(:test)
    end

    should "not be used in inspect" do
      assert !@bar.inspect.match(/z/)
      assert @bar.inspect.match(/test/)
    end
  end

  context "has_one shortnames" do
    setup do
      @bar = Bar.create(context, :test => 42)
      @bar.foo = Foo.create(context)
    end

    should "be used when storing" do
      assert_not_nil redis.hget(context.key, "#{@bar.key}_y")
    end

    should "work in roundtrip" do
      @bar.reload
      assert_not_nil @bar.foo
    end
  end

  context "has_many shortnames" do
    setup do
      @bar = Bar.create(context, :test => 42)
      @bar.foos.create
      @bar.foos.create
    end

    should "be used when storing" do
      assert_not_nil redis.hget(context.key, "#{@bar.key}_x")
    end

    should "work in roundtrip" do
      @bar.reload
      assert_equal 2, @bar.foos.size
    end
  end

end
