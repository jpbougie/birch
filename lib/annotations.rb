class Element
  include MongoMapper::EmbeddedDocument
  key :_type, String
end

class Ellipse < Element
  [:cx, :cy, :rx, :ry].each do |k|
    key k, Integer
  end
end

class Line < Element
  [:x, :y, :x2, :y2].each do |k|
    key k, Integer
  end
end

class Rect < Element
  [:x, :y, :width, :height].each do |k|
    key k, Integer
  end
end

class Text < Element
  [:x, :y].each do |k|
    key k, Integer
  end
  
  key :value, String
end
