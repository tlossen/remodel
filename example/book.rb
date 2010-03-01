class Chapter < Remodel::Entity
  property :title
end

class Book < Remodel::Entity
  has_many :chapters, :class => Chapter
  property :title
  property :year
end

