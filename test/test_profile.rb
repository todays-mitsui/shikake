require 'minitest/unit'
require_relative '../lib/profile'

MiniTest::Unit.autorun

class TestProfile < MiniTest::Unit::TestCase
	def setup
		@prof = Shikake::Profile.new
		@prof["url/with/tags"] = {:title => "title_url/with/tags", :tags => ["tag01", "tag02"], :score => [1, 2] , :empty_prop => []}
		@prof["url/with/links"] = {:title => "title_url/with/links", :links => ["link01", "link02"], :score => [2, 3]}
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

	def test_values
		assert_equal ["title_url/with/tags",  "title_url/with/links"], @prof.values(:title)
		assert_equal [3, 2, 1].sort, @prof.values(:score).sort
	end
end
