require 'helper'


class TestHasOne < Test::Unit::TestCase

  class Piece < Remodel::Entity
    has_one :puzzle, :class => 'TestHasOne::Puzzle'
    property :color
  end

  class Puzzle < Remodel::Entity
    property :topic
  end

  context "association getter" do
    should "exist" do
      assert Piece.create(context).respond_to?(:puzzle)
    end

    should "return nil by default" do
      assert_nil Piece.create(context).puzzle
    end

    should "return the associated entity" do
      puzzle = Puzzle.create(context, :topic => 'animals')
      piece = Piece.create(context)
      redis.hset(context.key, "#{piece.key}_puzzle", puzzle.key)
      assert_equal 'animals', piece.puzzle.topic
    end
  end

  context "association setter" do
    should "exist" do
      assert Piece.create(context).respond_to?(:'puzzle=')
    end

    should "store the key of the associated entity" do
      puzzle = Puzzle.create(context)
      piece = Piece.create(context)
      piece.puzzle = puzzle
      assert_equal puzzle.key, redis.hget(context.key, "#{piece.key}_puzzle")
    end

    should "be settable to nil" do
      piece = Piece.create(context)
      piece.puzzle = nil
      assert_nil piece.puzzle
    end

    should "remove the key if set to nil" do
      piece = Piece.create(context)
      piece.puzzle = Puzzle.create(context)
      piece.puzzle = nil
      assert_nil redis.hget(piece.context, "#{piece.key}_puzzle")
    end
  end

  context "reload" do
    should "reset has_one associations" do
      piece = Piece.create(context, :color => 'black')
      piece.puzzle = Puzzle.create(context)
      redis.hdel(context.key, "#{piece.key}_puzzle")
      piece.reload
      assert_nil piece.puzzle
    end
  end

end
