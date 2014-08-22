require 'minitest/unit'
require 'nokogiri'
require 'anemone'
require_relative '../lib/spider'
require_relative '../lib/profile'

MiniTest::Unit.autorun

class TestSpider < MiniTest::Unit::TestCase
	REGEXP = {
		:ga => /(\[.*_setAccount.+(UA-\d+-\d+).+\])/i,
		:univ => /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/i
	}

	def setup
		spider = Shikake::Spider.new("")
		spider.train(:ga ,{
			:name => "GoogleAnalytics",
			:selector => "script",
			:before => lambda{|el| el.text},
			:regexp => REGEXP[:ga],
			:val => lambda{|md| "id: #{md[2]}"}
		})
		spider.train(:univ ,{
			:name => "UniversalAnalytics",
			:selector => "script",
			:before => lambda{|el| el.text},
			:regexp => REGEXP[:univ],
			:val => lambda{|md| "id: #{md[3]}, displayfeatures: YES"}
		})
		@prof = spider.scan
	end

	def teardown
		@prof = nil
	end

	def test_basic
		p @prof.instance_variables
	end

end
