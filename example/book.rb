require File.dirname(__FILE__) + "/../lib/remodel.rb"

class Book < Remodel::Entity
  has_many :chapters, :class => 'Chapter'
  property :title
  property :year
end

class Chapter < Remodel::Entity
  property :title
end

