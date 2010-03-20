require File.dirname(__FILE__) + "/../lib/remodel.rb"

class Book < Remodel::Entity
  has_many :chapters, :class => 'Chapter', :reverse => :book
  property :title, :class => 'String'
  property :year, :class => 'Integer'
end

class Chapter < Remodel::Entity
  has_one :book, :class => Book
  property :title, :class => String
end

