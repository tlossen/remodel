require File.dirname(__FILE__) + "/../lib/remodel.rb"

class Book < Remodel::Entity
  has_many :chapters, :class => 'Chapter'
  property :title, :class => String
  property :year, :class => Integer
end

class Chapter < Remodel::Entity
  property :title, :class => String
end

