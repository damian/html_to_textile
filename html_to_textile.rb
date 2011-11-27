require 'rubygems'
require 'nokogiri'
require 'pp'

class HtmlToTextile

  attr_accessor :result, :fragment, :anchor

  INLINE_TAGS = {
    'em' => '_',
    'strong' => '*',
    'cite' => '??',
    'del' => '-',
    'span' => '%'
  }

  BLOCK_TAGS = {
    'p' => '',
    'h1' => 'h1. ',
    'h2' => 'h2. ',
    'h3' => 'h3. ',
    'h4' => 'h4. ',
    'h5' => 'h5. ',
    'h6' => 'h6. '
  }

  SPACER = "\n\n"

  def initialize(fragment)
    @fragment = Nokogiri::HTML.fragment(fragment)
    @result = []
    @anchor = []
  end

  def perform_traversal
    traverse(@fragment)
  end

  def to_textile
    perform_traversal
    @result.join
  end

  private

  # Recursive function to traverse through dom tree
  def traverse(nodes)
    nodes.children.each do |node|
      convert_node_to_textile(node)

      # Recurse over any child elements if any
      traverse(node)

      # Close the current element when all child nodes
      # have been traversed through
      close_node(node)
    end
  end

  # Acts like a router to determine what should be done with
  # each node that's passed to it
  def convert_node_to_textile(node)
    if node.elem?
      create_inline_tag_token(node)
      create_block_tag_token(node)
      handle_anchor_tag_token(node)
    else
      create_text_token(node)
    end
  end

  # Ensures an opened tag is closed correctly
  def close_node(node)
    return unless node.elem?

    close_inline_tag_token(node)
    close_block_tag_token(node)
  end

  # Opens and closes inline tags
  #
  # TODO Modify this function to deal with tag attributes
  def create_inline_tag_token(node)
    add_item(INLINE_TAGS[node.name]) if INLINE_TAGS.key?(node.name)
  end
  alias_method :close_inline_tag_token, :create_inline_tag_token

  # Adds the appropriate block level tag to the stack
  #
  # TODO Modify this function to keep any other html intact - not just divs
  # TODO Modify this function to deal with tag attributes
  def create_block_tag_token(node)
    if BLOCK_TAGS.key?(node.name)
      add_item(SPACER + BLOCK_TAGS[node.name])
    elsif node.name == 'div'
      add_item(SPACER + '<div>')
    end
  end

  def close_block_tag_token(node)
    add_item(SPACER + '</div>') if node.name == 'div'
  end

  # Proxy all calls to this method in case of a macro change
  def add_item(item)
    @result << item
  end

  # Retrieves and stores an anchors href attribute to a temporary
  # array
  def handle_anchor_tag_token(node)
    @anchor << node.attribute('href') if node.name == 'a'
  end

  def create_text_token(node)
    return unless node.text?

    # Remove newline characters specifically as Ruby's strip
    # method also removes whitespace which we want to preserve
    text = node.text.gsub("\n", '')

    return unless text.length

    if @anchor.empty?
      add_item(text)
    else
      # Dealing with an anchor
      anchor = @anchor.pop
      add_item("\"#{text}\":#{anchor}")
    end
  end

end

