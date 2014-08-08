require 'bundler'
Bundler.require


#class Shikake
#	attr_accessor :url
#	@@opts = {:skip_query_strings => true}
#
#	def initialize url
#		@url = url
#	end
#
#	def crawl_ga_tag crawler
#		result = []
#		crawler.skip_links_like /(\.jpe?g|\.gif|\.png|\.pdf)$/
#		crawler.on_every_page do |page|
#			tags = []
#			if page.doc
#				tags.push(pick_ga_tag page) if pick_ga_tag page
#				tags.push(pick_univ_tag page) if pick_univ_tag page
#				result.push({:url => page.url, :tags => tags})
#			end
#		end
#		result
#	end
#
#	def pick_ga_tag page
#		r = /(\[_setAccount.+(UA-\d+-\d+).+\])/
#		page.doc.css("script").each do |el|
#			return {tag: "ga", id: $2} if r.match(el.text)
#		end
#		return nil
#	end
#
#	def pick_univ_tag page
#		r = /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/
#		page.doc.css("script").each do |el|
#			return {tag: "univ", id: $3} if r.match(el.text)
#		end
#		return nil
#	end
#
#	def show_result pages
#		puts "\nresult:"
#		puts "\n  #{pages.length} pages."
#		pages_ = pages.map {|page| page[:tags]}
#		tags = pages_.flatten.compact.uniq
#		puts "  #{tags.length} tags exist."
#		puts "\n  tags:"
#		tags.each {|tag| puts "    #{tag.to_s}"}
#		pages.each {|page| puts "  !!No tags in #{page[:url]}" if page[:tags].empty?}
#		puts "\ndone."
#	end
#
#	def crawlGA
#		result = nil
#		puts "crawling #{@url}..."
#		Anemone.crawl(@url, @@opts) do |crawler|
#			p crawler.class
#			result = crawl_ga_tag crawler
#		end
#		show_result result
#	end
#end

class Shikake2
	attr_reader :url, :opts

	def initialize(url)
		@url = url
		@opts = {}
		set_opts({skip_query_strings: true})
	end

	def scan_tag
		Anemone.crawl(@url, @opts, &shikake)
	end

	def set_opts opt
		@opts.merge! opt
	end

	private

		def shikake
			lambda{|crawler| 
				crawler.skip_links_like /(\.jpe?g|\.gif|\.png|\.pdf)$/
				crawler.on_every_page do |page|
					puts page.url if page.doc
				end
			}
		end
end

s2 = Shikake2.new("http://www.city.fukuoka.lg.jp/")
s2.scan_tag

class Atags
	def initialize
		@tag_pages = {}
		@no_tag_pages = []
	end

	def pages
		@tag_pages.keys + @no_tag_pages
	end
	
	def tag_pages
		@tag_pages.keys
	end

	def no_tag_pages
		@no_tag_pages
	end

	def tags
		@tag_pages.values.flatten.uniq
	end

	def tag_ids
		tags.map{|tag| tag[:id]}.uniq
	end
	
	def push(url, kind = nil, id = nil)
		if kind && id
			stock_tag(url, kind, id)
		else
			stock_no_tag(url)
		end
	end

	private

		def stock_tag(url, kind, id)
			if @tag_pages.include?(url)
				@tag_pages[url] << ({:kind => kind, :id => id})
			else
				@tag_pages[url] = [] << {:kind => kind, :id => id}
			end
		end

		def stock_no_tag(url)
			@no_tag_pages << url unless @tag_pages.include?(url) || @no_tag_pages.include?(url)
		end
end

tags = Atags.new
tags.push("a", :a, 1)
tags.push("b", nil, 2)
tags.push("a", :c, nil)
tags.push("d", :d, 4)
p tags
p tags.pages
p tags.tag_pages
p tags.no_tag_pages
p tags.tags
p tags.tag_ids

#shi = Shikake.new("http://marimo-dental.com/")
#shi.crawlGA

