require 'minitest/unit'
require_relative '../lib/profile'

MiniTest::Unit.autorun

class TestProfile < MiniTest::Unit::TestCase
	def setup
		@prof = Shikake::Profile.new
		@prof["url/with/tags"] = {:title => "title_url/with/tags", :tags => ["tag01", "tag02"], :score => [1, 2] , :empty_prop => []}
		@prof["url/with/links"] = {:title => "title_url/with/links", :links => ["link01", "link02"], :score => [2, 3]}
	end

	def teardown
		@prof = nil
	end

	def test_select
		assert_equal ["url/with/tags"], @prof.select(:tags).keys
	end

	def test_select_empty_prop
		assert_equal [], @prof.select(:empty_prop).keys
	end

	def test_reject
		assert_equal ["url/with/links"], @prof.reject(:tags).keys
	end

	def test_reject_empty_prop
		assert_equal ["url/with/tags", "url/with/links"], @prof.reject(:empty_prop).keys
	end

	def test_dichotomized
		assert_equal @prof.length, (@prof.select(:tags).length + @prof.reject(:tags).length)
	end

	def test_values
		assert_equal ["title_url/with/tags",  "title_url/with/links"], @prof.values(:title)
		assert_equal [3, 2, 1].sort, @prof.values(:score).sort
	end

	def test_map
		assert_equal true, ({"url/with/tags" => [1, 2], "url/with/links" => [2, 3]} == @prof.map(:score))
	end

	def test_map_with_block
		assert_equal true, ({"url/with/tags" => [1, 4], "url/with/links" => [4, 9]} == (@prof.map(:score) {|url,scores| scores.map {|score| score * score}}))
	end

	def test_find_all
		p @prof.find_all /tag/
		puts @prof.instance_variables
		#assert @prof.find_all(/01/)
	end
end
