require 'helper'

class TestOneToOne < Test::Unit::TestCase

  class Man < Remodel::Entity
    has_one :wife, :class => 'TestOneToOne::Woman', :reverse => 'husband'
    property :name
  end

  class Woman < Remodel::Entity
    has_one :husband, :class => 'TestOneToOne::Man', :reverse => 'wife'
    property :name
  end

  context "both associations" do
    should "be nil by default" do
      assert_equal nil, Man.new(context).wife
      assert_equal nil, Woman.new(context).husband
    end

    context "setter" do
      setup do
        @bill = Man.create(context, :name => 'Bill')
        @mary = Woman.create(context, :name => 'Mary')
      end

      context "non-nil value" do
        should "also set husband" do
          @bill.wife = @mary
          assert_equal @bill, @mary.husband
        end

        should "also set wife" do
          @mary.husband = @bill
          assert_equal @mary, @bill.wife
        end
      end

      context "nil value" do
        setup do
          @bill.wife = @mary
        end

        should "also clear husband" do
          @bill.wife = nil
          assert_equal nil, @mary.husband
        end

        should "also clear wife" do
          @mary.husband = nil
          assert_equal nil, @bill.wife
        end
      end
    end
  end

end
