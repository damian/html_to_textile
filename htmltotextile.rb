require 'rubygems'
require 'nokogiri'
require 'pp'

class HTML2Textile

  STRICT_BLOCK_LEVEL = %w[address blockquote center dir div dl
        fieldset form h1 h2 h3 h4 h5 h6 hr isindex menu noframes
        noscript ol p pre table ul]

  LOOSE_BLOCK_LEVEL = %w[dd dt frameset li tbody td tfoot th thead tr]
  BLOCK_LEVEL = STRICT_BLOCK_LEVEL + LOOSE_BLOCK_LEVEL

  TAGS = {
    'blockquote' => 'bq',
    'p' => 'p',
    'code' => '@',
    'h1' => 'h1',
    'h2' => 'h2',
    'h3' => 'h3',
    'h4' => 'h4',
    'h5' => 'h5',
    'h6' => 'h6',
    'li' => ['#', '*'],
  }

  INLINE_TAGS = {
    'strong' => '*',
    'em' => '_',
    'del' => '-',
    'span' => '%'
  }

  SKIPS = ['ul', 'ol']

  attr_accessor :fragment, :result

  def initialize(fragment)
    @fragment = Nokogiri::HTML.fragment(fragment)
    @result = []
  end

  def to_textile
    traverse(@fragment)
    @result.join
  end

  def traverse(node)
    node.children.each do |node|
      new_node(node) if node.elem?
      new_text(node) if node.text?
      traverse(node)
      close_node(node) if node.elem?
    end
  end

  def new_text(elem)
    @result << elem.text if elem.text =~ /\w/
  end

  def new_node(elem)
    if SKIPS.include? elem.name
      return
    end

    if BLOCK_LEVEL.include?(elem.name) && elem.name != "li"
      @result << "\n"
    end

    attrs = elem.attributes.map do |k,v|
      "#{k}='#{v}'" if elem.name != "img"
    end.compact

    if attrs.empty?

      # If its a list item or within a list
      if elem.name == 'li'
        if elem.parent.name == 'ol'
          @result << "#{TAGS[elem.name][0]} " # Ordered list
        else
          @result << "#{TAGS[elem.name][1]} " # Unordered list
        end
      else
        if TAGS.include?(elem.name)
          @result << "#{TAGS[elem.name]}. "
        elsif elem.name == "img"
          src = elem.get_attribute('src')
          @result << "!#{src}!"
        elsif INLINE_TAGS.include?(elem.name)
          @result << "#{INLINE_TAGS[elem.name]}"
        else
          @result << "<#{elem.name}>"
        end
      end

    else
      if INLINE_TAGS.include?(elem.name)
        @result << "#{INLINE_TAGS[elem.name]}"

        attrs = ['class', 'id'].map do |a|
          if elem.key?(a)
            a == 'id' ? "##{elem[a].to_s}" : elem[a].to_s
          end
        end.join
        @result << "(#{attrs})"
      else
        @result << "<#{elem.name} #{attrs.join(' ')}>"
      end
    end
  end

  def close_node(elem)
    if SKIPS.include? elem.name
      spacing(elem)
      return
    end
    if BLOCK_LEVEL.include?(elem.name)
      unless TAGS.include?(elem.name)
        @result << "</#{elem.name}>"
      end
    elsif INLINE_TAGS.include?(elem.name)
      @result << "#{INLINE_TAGS[elem.name]}"
    else
      @result << "</#{elem.name}>" if elem.name != 'img'
    end

    spacing(elem)
  end

  def spacing(elem)
    if BLOCK_LEVEL.include?(elem.name)
      @result << "\n\n"
    end
  end

end

