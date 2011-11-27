require 'rubygems'
require 'pp'
require './html_to_textile'

describe HtmlToTextile do

  before do
    @str = '<p>world</p>'
    @con = HtmlToTextile.new(@str)
  end

  describe "intialisation" do
    it "should intialize result to an array" do
      @con.result.should be_a(Array)
    end

    it "should initialize result to an empty array" do
      @con.result.should have(0).items
    end

    it "should intialise fragment to a DocumentFragment" do
      @con.fragment.should be_a(Nokogiri::HTML::DocumentFragment)
    end

  end

  describe "fragment traversal" do
    before do
      @con.perform_traversal
    end

    it "should append to the result array for each node in the traversal" do
      @con.result.should have(2).items
    end
  end

  describe "single paragraph tag to textile conversion" do
    before do
      @con.perform_traversal
    end

    it "should start a new paragragh with a newline character" do
      @con.result[0].should == HtmlToTextile::SPACER
    end
  end

  describe "double paragraph tag to textile conversion" do
    before do
      @con = HtmlToTextile.new('<p>Wreckin\' Bar</p><p>(Ra Ra Ra)</p>')
      @con.perform_traversal
    end

    it "should start a new paragragh with a newline character" do
      @con.result[0].should == HtmlToTextile::SPACER
    end

    it "should add a text node of Wreckin' Bar to result" do
      @con.result[1].should == "Wreckin' Bar"
    end

    it "should start a new paragragh with a newline character" do
      @con.result[2].should == HtmlToTextile::SPACER
    end

    it "should add a text node of (Ra Ra Ra) to result" do
      @con.result[3].should == "(Ra Ra Ra)"
    end
  end

  describe "plain text to textile conversion" do
    before do
      @con = HtmlToTextile.new('world')
      @con.perform_traversal
    end

    it "should add a text node to result as plain text" do
      @con.result[0].should == 'world'
    end
  end

  describe "convert a header with level 1 to h1. followed by a space" do
    before do
      @con = HtmlToTextile.new('<h1>Hello</h1>')
      @con.perform_traversal
    end

    it "should add h1. to result" do
      @con.result[0].should include(HtmlToTextile::BLOCK_TAGS['h1'])
    end

    it "should add Hello to result" do
      @con.result[1].should == 'Hello'
    end
  end

  describe "convert headers to the letter h suffixed by the level of header it encounters followed by a dot and a space" do
    before do
      @con = HtmlToTextile.new('<h2>Wetsuit</h2><h4>Family friend</h4><h7>Lightwood</h7>')
      @con.perform_traversal
    end

    it "should add a h2 to the result" do
      @con.result[0].should include(HtmlToTextile::BLOCK_TAGS['h2'])
    end

    it "should add Wetsuit to the result" do
      @con.result[1].should == 'Wetsuit'
    end

    it "should add a h4 to the result" do
      @con.result[2].should include(HtmlToTextile::BLOCK_TAGS['h4'])
    end

    it "should add Family friend to result" do
      @con.result[3].should == 'Family friend'
    end

    it "should not add a h7 to the result" do
      @con.result[4].should_not include('h7. ')
      @con.result[4].should == 'Lightwood'
      @con.result.should have(5).items
    end
  end

  describe "inline tags" do
    before do
      @con = HtmlToTextile.new('<p>Family friend <em>Lightwood</em> damn rights</p>')
      @con.perform_traversal
    end

    it "should add a newline to result" do
      @con.result[0].should == HtmlToTextile::SPACER
    end

    it "should prefix Lightwood with an underscore" do
      @con.result[2].should == HtmlToTextile::INLINE_TAGS['em']
    end

    it "should suffix Lightwood with an underscore" do
      @con.result[4].should == HtmlToTextile::INLINE_TAGS['em']
    end
  end

end

