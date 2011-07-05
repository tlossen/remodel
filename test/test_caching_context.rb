# encoding: UTF-8
require 'helper'

class Remodel::CachingContext
  attr_accessor :cache
  class << self
    public :new
  end
end

class TestCachingContext < Test::Unit::TestCase

  context "CachingContext" do
    setup do
      @cache = Remodel::CachingContext.new(context)
    end

    context 'hget' do
      should "fetch and cache value" do
        context.expects(:hget).with('x').returns('33')
        assert_equal '33', @cache.hget('x')
        assert_equal '33', @cache.cache['x']
      end

      should "return cached value" do
        @cache.cache['x'] = '42'
        context.expects(:hget).never
        assert_equal '42', @cache.hget('x')
      end

      should "return cached nil" do
        @cache.cache['x'] = nil
        context.expects(:hget).never
        assert_nil @cache.hget('x')
      end
    end

    context 'hmget' do
      should "fetch and cache values" do
        context.expects(:hmget).with('x', 'y', 'z').returns %w[4 5 6]
        assert_equal %w[4 5 6], @cache.hmget('x', 'y', 'z')
        assert_equal %w[4 5 6], @cache.cache.values_at('x', 'y', 'z')
      end

      should 'only fetch uncached values' do
        @cache.cache['y'] = '5'
        context.expects(:hmget).with('x', 'z').returns %w[4 6]
        assert_equal %w[4 5 6], @cache.hmget('x', 'y', 'z')
        assert_equal %w[4 5 6], @cache.cache.values_at('x', 'y', 'z')
      end

      should 'not fetch cached nil values' do
        @cache.cache['y'] = nil
        context.expects(:hmget).with('x', 'z').returns %w[4 6]
        assert_equal ['4', nil, '6'], @cache.hmget('x', 'y', 'z')
        assert_equal ['4', nil, '6'], @cache.cache.values_at('x', 'y', 'z')
      end

      should 'not call redis if all values are cached' do
        @cache.cache['x'] = '4'
        @cache.cache['y'] = '5'
        @cache.cache['z'] = '6'
        context.expects(:hmget).never
        assert_equal %w[4 5 6], @cache.hmget('x', 'y', 'z')
      end
    end

    context 'hset' do
      should 'store value in redis' do
        context.expects(:hset).with('x', '21')
        @cache.hset('x', 21)
      end

      should 'cache value as string' do
        context.expects(:hset).with('x', '21')
        @cache.hset('x', 21)
        assert_equal '21', @cache.cache['x']
      end

      should 'cache nil' do
        context.expects(:hset).with('x', nil)
        @cache.hset('x', nil)
        assert_nil @cache.cache['x']
        assert @cache.cache.has_key?('x')
      end
    end

    context 'hincrby' do
      should 'increment value in redis' do
        context.expects(:hincrby).with('i', 1).returns(3)
        assert_equal 3, @cache.hincrby('i', 1)
      end

      should 'cache result as string' do
        context.expects(:hincrby).with('i', 1).returns(3)
        @cache.hincrby('i', 1)
        assert_equal '3', @cache.cache['i']
      end
    end

    context 'hdel' do
      should 'delete field in redis' do
        context.expects(:hdel).with('x')
        @cache.hdel('x')
      end

      should 'cache nil for field' do
        context.expects(:hdel).with('x')
        @cache.hdel('x')
        assert_nil @cache.cache['x']
        assert @cache.cache.has_key?('x')
      end
    end
  end

end