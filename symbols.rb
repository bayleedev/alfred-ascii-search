require 'json'
require 'rexml/document'
require 'rexml/element'

data = JSON.parse(File.read('symbols.json'))

class Search
  attr_accessor :data, :search

  def initialize(data)
    @data = data.inject([]) do |memo, el|
      memo.push Item.new(el[0], el[1])
    end
    @search = search
  end

  def find(keyword)
    search = Regexp.new(keyword, 'i')
    matches = @data.select do |item|
      item.match(search)
    end
    Collection.new(matches)
  end
end

class Item
  attr_accessor :key, :value

  BAD_CODES = (0..8).to_a + (11..31).to_a

  def initialize(key, value)
    @key = key
    @value = value
  end

  def match(regex)
    @key.match(regex) or @value.match(regex)
  end

  def display
    if illegal_character?
      "#{key} - #{value}"
    else
      "#{key} &##{key};"
    end
  end

  def uid
    "code-#{key}"
  end

  def to_xml
    item = REXML::Element.new('item', nil, {raw: :all})
    item.add_attribute('arg', key)
    item.add_attribute('uid', uid)
    item.add_element('title').text = display
    item.add_element('subtitle').text = value
    item
  end

  private

  def illegal_character?
    BAD_CODES.include?(key.to_i)
  end
end

class Collection
  attr_accessor :nodes

  def initialize(nodes)
    @nodes = nodes
  end

  def to_xml
    document = REXML::Document.new('<?xml version="1.0"?>')
    items = document.add_element('items')
    nodes.each do |node|
      items << node.to_xml
    end
    document.to_s
  end
end

puts Search.new(data).find(ARGV[0]).to_xml
