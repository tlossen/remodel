require 'helper'

class TestEntityShortnames < Test::Unit::TestCase

  class Bar < Remodel::Entity
    property :foo, :short => 'z'
  end

  context "[short names]" do
    setup do
      @bar = Bar.create('cx', :foo => 42)
    end
    
    should "be used when storing properties" do
      serialized = redis.hget('cx', @bar.key)
      assert !serialized.match(/foo/)
      assert serialized.match(/z/)
    end
    
    should "work in roundtrip" do
      @bar.reload
      assert_equal 42, @bar.foo
    end
    
    should "not be used in as_json" do
      assert !@bar.as_json.has_key?(:z)
      assert @bar.as_json.has_key?(:foo)
    end
    
    should "not be used in inspect" do
      assert !@bar.inspect.match(/z/)
      assert @bar.inspect.match(/foo/)
    end
  end

end
