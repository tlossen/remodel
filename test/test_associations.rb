require 'helper'

class Puzzle < Remodel::Entity
  has_many :pieces, :class => 'Piece'
  property :topic
end

class Piece < Remodel::Entity
  has_one :puzzle, :class => 'Puzzle'
  property :color
end

class TestAssociations < Test::Unit::TestCase

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
      
      should "remove the key if set to nil" do
        piece = Piece.create
        piece.puzzle = Puzzle.create
        piece.puzzle = nil
        assert_nil redis.get("#{piece.key}:puzzle")
      end
    end
  end

  context "has_many" do
    
    context "association" do
      should "exist" do
        assert Puzzle.create.respond_to?(:pieces)
      end
    
      should "return an empty list by default" do
        assert_equal [], Puzzle.create.pieces
      end
    
      should "return any existing children" do
        puzzle = Puzzle.create
        redis.rpush "#{puzzle.key}:pieces", Piece.create(:color => 'red').key
        redis.rpush "#{puzzle.key}:pieces", Piece.create(:color => 'blue').key
        assert_equal 2, puzzle.pieces.size
        assert_equal Piece, puzzle.pieces[0].class
        assert_equal 'red', puzzle.pieces[0].color
      end
    
      context "create" do
        should "have a create method" do
          assert Puzzle.create.pieces.respond_to?(:create)
        end
        
        should "work without attributes" do
          puzzle = Puzzle.create
          piece = puzzle.pieces.create
          assert piece.is_a?(Piece)
        end
      
        should "create and store a new child" do
          puzzle = Puzzle.create
          puzzle.pieces.create :color => 'green'
          puzzle.pieces.create :color => 'yellow'
          assert_equal 2, puzzle.pieces.size
          puzzle.reload
          assert_equal 2, puzzle.pieces.size
          assert_equal Piece, puzzle.pieces[1].class
          assert_equal 'yellow', puzzle.pieces[1].color
        end
      end
    end
  end
  
  context "reload" do
    should "reset has_many associations" do
      puzzle = Puzzle.create
      piece = puzzle.pieces.create :color => 'black'
      redis.del "#{puzzle.key}:pieces"
      puzzle.reload
      assert_equal [], puzzle.pieces
    end
    
    should "reset has_one associations" do
      piece = Piece.create :color => 'black'
      piece.puzzle = Puzzle.create
      redis.del "#{piece.key}:puzzle"
      piece.reload
      assert_nil piece.puzzle
    end
  end
  
end
