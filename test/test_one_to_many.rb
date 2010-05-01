require 'helper'


class TestOneToMany < Test::Unit::TestCase

  class Piece < Remodel::Entity
    has_one :puzzle, :class => 'TestOneToMany::Puzzle', :reverse => 'pieces'
    property :color
  end

  class Puzzle < Remodel::Entity
    has_many :pieces, :class => 'TestOneToMany::Piece'
    property :topic
  end

  context "has_one" do
    context "association getter" do
      should "exist" do
        assert Piece.create.respond_to?(:puzzle)
      end

      should "return nil by default" do
        assert_nil Piece.create.puzzle
      end

      should "return the associated entity" do
        puzzle = Puzzle.create :topic => 'animals'
        piece = Piece.create
        redis.set("#{piece.key}:puzzle", puzzle.key)
        assert_equal 'animals', piece.puzzle.topic
      end
    end

    context "association setter" do
      should "exist" do
        assert Piece.create.respond_to?(:'puzzle=')
      end

      should "store the key of the associated entity" do
        puzzle = Puzzle.create
        piece = Piece.create
        piece.puzzle = puzzle
        assert_equal puzzle.key, redis.get("#{piece.key}:puzzle")
      end

      should "add the entity to the reverse association" do
        puzzle = Puzzle.create
        piece = Piece.create
        piece.puzzle = puzzle
        assert_equal 1, puzzle.pieces.size
      end

      should "be settable to nil" do
        piece = Piece.create
        piece.puzzle = nil
        assert_nil piece.puzzle
      end

      should "remove the key if set to nil" do
        piece = Piece.create
        piece.puzzle = Puzzle.create
        piece.puzzle = nil
        assert_nil redis.get("#{piece.key}:puzzle")
      end

      should "remove the entity from the reverse association if set to nil" do
        puzzle = Puzzle.create
        piece = Piece.create
        piece.puzzle = puzzle
        piece.puzzle = nil
        puzzle.reload
        assert_equal 0, puzzle.pieces.size
      end
    end
  end

  context "reload" do
    should "reset has_one associations" do
      piece = Piece.create :color => 'black'
      piece.puzzle = Puzzle.create
      redis.del "#{piece.key}:puzzle"
      piece.reload
      assert_nil piece.puzzle
    end
  end

end
