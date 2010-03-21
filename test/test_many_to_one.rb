require 'helper'

class TestManyToOne < Test::Unit::TestCase

  class Puzzle < Remodel::Entity
    has_many :pieces, :class => 'TestManyToOne::Piece', :reverse => 'puzzle'
    property :topic
  end

  class Piece < Remodel::Entity
    has_one :puzzle, :class => 'TestManyToOne::Puzzle'
    property :color
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
          assert_equal 1, puzzle.pieces.size
          puzzle.reload
          assert_equal 1, puzzle.pieces.size
          assert_equal Piece, puzzle.pieces[0].class
          assert_equal 'green', puzzle.pieces[0].color
        end
        
        should "associate the created child with self" do
          puzzle = Puzzle.create :topic => 'provence'
          piece = puzzle.pieces.create :color => 'green'
          assert_equal 'provence', piece.puzzle.topic
        end
      end

      context "add" do
        should "add the given entity to the association" do
          puzzle = Puzzle.create
          piece = Piece.create :color => 'white'
          puzzle.pieces.add piece
          assert_equal 1, puzzle.pieces.size
          puzzle.reload
          assert_equal 1, puzzle.pieces.size
          assert_equal Piece, puzzle.pieces[0].class
          assert_equal 'white', puzzle.pieces[0].color
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
  end
  
end
