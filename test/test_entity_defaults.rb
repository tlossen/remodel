require 'helper'

class TestEntityDefaults < Test::Unit::TestCase

  class Bar < Remodel::Entity
    property :simple, :default => 123
    property :array, :default => [1]
    property :hash, :default => { :foo => 1 }
  end

  context "[default values]" do
    should "be returned for missing properties" do
      bar = Bar.new('cx')
      assert_equal 123, bar.simple
    end

    should "be returned for properties that are nil" do
      bar = Bar.new('cx', :simple => 'cool')
      bar.simple = nil
      assert_equal 123, bar.simple
    end

    should "not be returned for given properties" do
      bar = Bar.new('cx', :simple => 'cool')
      assert_equal 'cool', bar.simple
    end

    should "not be stored" do
      bar = Bar.create('cx')
      assert !(/123/ =~ redis.hget('cx', bar.key))
    end

    should "be returned by as_json" do
      bar = Bar.new('cx')
      assert_equal 123, bar.as_json[:simple]
    end
  end

  context "[collections]" do
    setup do
      @bar, @baz = Bar.new('cx'), Bar.new('cx')
    end

    should "not share arrays" do
      @bar.array[0] += 1
      assert_equal [1], @baz.array
    end

    should "not share hashes" do
      @bar.hash[:foo] = 42
      assert_equal 1, @baz.hash[:foo]
    end
  end

end
