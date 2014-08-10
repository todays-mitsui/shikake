require 'bundler'
Bundler.require


class Shikake < Anemone::Core
	def initialize url
		super
		@opts = {
			:skip_query_strings => true,
			:skip_link_patterns => [/\.jpe?g$/i, /\.gif$/i, /.png$/i, /\.pdf$/i]
		}
	end

	def scan
		on_every_page &scan_atag
		@start_time = Time.now.to_i
		run
		@end_time = Time.now.to_i
		puts "#{@end_time - @start_time}秒かかりました。"
		@scan_result
	end

	def scan_atag
		@scan_result = Atags.new
		lambda do |page|
			@scan_result.push(page.url, page.atags) if page.doc
			#if page.doc
			#	a = page.atags
			#	puts page.url
			#	p a
			#	@scan_result.push(page.url, a)
			#end
		end
	end

	class Anemone::Page
		@atags = false

		def atags
			find_atag unless @atags
			@atags
		end

		def find_atag
			r_ga = /(\[_setAccount.+(UA-\d+-\d+).+\])/
			r_univ = /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/
			@atags = []
			@doc.css("script").each do |el|
				@atags << {kind: :univ, id: $3} if r_univ.match(el.text)
				@atags << {kind: :ga, id: $2} if r_ga.match(el.text)
			end
		end
	end
end

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
	
	def push(url, tags)
		if tags && !tags.empty?
			stock_tag(url, tags)
		else
			stock_no_tag(url)
		end
	end

	private

		def stock_tag(url, tags)
			if @tag_pages.include?(url)
				@tag_pages[url] += tags
			else
				@tag_pages[url] = tags
			end
		end

		def stock_no_tag(url)
			@no_tag_pages << url unless @tag_pages.include?(url) || @no_tag_pages.include?(url)
		end
end

if ARGV[0]
	shikake = Shikake.new(ARGV[0])
	scan_result = shikake.scan
	result = <<-EOD
url:          #{ARGV[0]}
all pages:    #{scan_result.pages.length} pages
tag pages:    #{scan_result.tag_pages.length} pages
no tag pages: #{scan_result.no_tag_pages.length} pages
tags:         #{scan_result.tags}
	EOD
	puts result
	File.open("log/scan_result.txt", "w+") do |file|
		file.write result
		file.write "\n"
		file.write scan_result.no_tag_pages.join("\n")
	end
end
