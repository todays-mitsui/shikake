require 'bundler'
Bundler.require


class Shikake
	attr_accessor :url
	@@opts = {:skip_query_strings => true}

	def initialize url
		@url = url
	end

	def crawl_ga_tag crawler
		result = []
		crawler.skip_links_like /(\.jpe?g|\.gif|\.png|\.pdf)$/
		crawler.on_every_page do |page|
			tags = []
			if page.doc
				tags.push(pick_ga_tag page) if pick_ga_tag page
				tags.push(pick_univ_tag page) if pick_univ_tag page
				result.push({:url => page.url, :tags => tags})
			end
		end
		result
	end

	def pick_ga_tag page
		r = /(\[_setAccount.+(UA-\d+-\d+).+\])/
		page.doc.css("script").each do |el|
			return {tag: "ga", id: $2} if r.match(el.text)
		end
		return nil
	end

	def pick_univ_tag page
		r = /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/
		page.doc.css("script").each do |el|
			return {tag: "univ", id: $3} if r.match(el.text)
		end
		return nil
	end

	def show_result pages
		puts "\nresult:"
		puts "\n  #{pages.length} pages."
		pages_ = pages.map {|page| page[:tags]}
		tags = pages_.flatten.compact.uniq
		puts "  #{tags.length} tags exist."
		puts "\n  tags:"
		tags.each {|tag| puts "    #{tag.to_s}"}
		pages.each {|page| puts "  !!No tags in #{page[:url]}" if page[:tags].empty?}
		puts "\ndone."
	end

	def crawlGA
		result = nil
		puts "crawling #{@url}..."
		Anemone.crawl(@url, @@opts) do |crawler|
			result = crawl_ga_tag crawler
		end
		show_result result
	end
end


shi = Shikake.new("http://marimo-dental.com/")
shi.crawlGA
