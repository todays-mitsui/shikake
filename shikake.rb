require 'bundler'
Bundler.require


class Shikake < Anemone::Core

	@@regexps = {
		:sp => %r{(/sp/|/sp$)},
		:img_dir => %r{(/img/|/upimg/)},
		:img_file => %r{(\.jpe?g$|\.gif$|\.png$|\.pdf$)}
	}
	@@tmp_path = "tmp/tmp_#{(0...8).map{(65+rand(26)).chr}.join}.txt"

	def initialize url
		super
		@opts = {
			:skip_query_strings => true,
			:delay => 0.5,
			:storage => Anemone::Storage.PStore(@@tmp_path),
			:verbose => true
		}
		if %r|/sp/|.match(url) || %r|/sp$|.match(url)
			@opts[:user_agent] = "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"
		else
			@opts[:user_agent] = "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36"
		end
	end

	def scan
		focus_crawl &set_focus
		on_pages_like /(\.html?|\.php|\/)$/, &scan_tag

		@start_time = Time.now.to_i
		run
		@end_time = Time.now.to_i

		puts "#{@end_time - @start_time}秒かかりました。"
		@scan_result
	end

	def scan_tag
		@scan_result = Atags.new
		lambda do |page|
			@scan_result.push(page.url, page.doc.title, page.tags) if page.doc
		end
	end

	def set_focus
		lambda do |page|
			page.links.keep_if do |link|
				!(link.to_s.match(@@regexps[:img_dir]) || link.to_s.match(@@regexps[:img_file]))
			end
			page.links.keep_if do |link|
				if sp?
					link.to_s.match(@@regexps[:sp])
				else
					!link.to_s.match(@@regexps[:sp])
				end
			end
		end
	end

	def sp?
		@urls.any? {|url| @@regexps[:sp].match(url.to_s)}
	end

	class Anemone::Page
		@tags = false

		def tags
			find_tags unless @tags
			@tags
		end

		def find_tags
			r_ga_old = /(\[.*_setAccount.+(UA-\d+-\d+).+\])/i
			r_ga_new = /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/i
			r_event_old = /_?gaq.push\s*\(\s*(\[('_trackEvent'|"_trackEvent").*\])\s*\)/i
			r_event_new = /(ga\s*\(('send'|"send").*,.*('event'|"event").*\))/i
			r_callcv_old = /_?gaq.push\s*\(\s*(\[('_trackPageview'|"_trackPageview").*\])\s*\)/i
			r_callcv_new = /ga\s*(\(('send'|"send").*,.*('pageview'|"pageview").*\))/i
			@tags = Hash.new {|hash, key| hash[key] = []}
			@doc.css("script").each do |el|
				@tags[:ga] << {id: $2} if r_ga_old.match(el.text)
				@tags[:univ] << {id: $3} if r_ga_new.match(el.text)
			end
			@doc.css("a").each do |el|
				@tags[:event_old] << {tag: $1, val: el.inner_text} if r_event_old.match(el.attribute("onclick"))
				@tags[:event_new] << {tag: $1, val: el.inner_text} if r_event_new.match(el.attribute("onclick"))
				@tags[:callcv_old] << {tag: $1, val: el.inner_text} if r_callcv_old.match(el.attribute("onclick"))
				@tags[:callcv_new] << {tag: $1, val: el.inner_text} if r_callcv_new.match(el.attribute("onclick"))
			end
		end
	end
end

class Atags
	@@kinds = [:ga, :univ, :event_old, :event_new, :callcv_old, :callcv_new]

	def initialize
		@tags = Hash.new {|hash, key| hash[key] = {}}
	end

	def pages
		@tags.keys
	end

	@@kinds.each do |kind|
		define_method "#{kind}_pages" do
			@tags.select{|key, val| val[kind] && !val[kind].empty?}.keys
		end

		define_method "no_#{kind}_pages" do
			@tags.select{|key, val| !val[kind] || val[kind].empty?}.keys
		end
	end

	def ga_tags
		@tags.map{|key, val| val[:ga].map{|tag| tag[:id]} if val[:ga]}.flatten.compact.uniq
	end
	def univ_tags
		@tags.map{|key, val| val[:univ].map{|tag| tag[:id]} if val[:univ]}.flatten.compact.uniq
	end

	def event_old_tags
		@tags.map{|key, val| val[:event_old].map{|tag| tag[:tag]} if val[:event_old]}.flatten.compact.uniq
	end
	def event_new_tags
		@tags.map{|key, val| val[:event_new].map{|tag| tag[:tag]} if val[:event_new]}.flatten.compact.uniq
	end

	def callcv_old_tags
		@tags.map{|key, val| val[:callcv_old].map{|tag| tag[:tag]} if val[:callcv_old]}.flatten.compact.uniq
	end
	def callcv_new_tags
		@tags.map{|key, val| val[:callcv_new].map{|tag| tag[:tag]} if val[:callcv_new]}.flatten.compact.uniq
	end

	def ga_tags_url
		@tags.map{|url, val| url if val[:ga]}.compact
	end
	def no_univ_tags_url
		@tags.map{|url, val| url if !val[:univ]}.compact
	end
	def event_old_tags_url
		@tags.map{|url, val| "url: #{url}\ntag: #{val[:event_old].map{|tag| tag[:tag]}}\n" if val[:event_old]}.compact
	end
	def event_new_tags_url
		@tags.map{|url, val| "url: #{url}\ntag: #{val[:event_new].map{|tag| tag[:tag]}}\n" if val[:event_new]}.compact
	end
	def callcv_old_tags_url
		@tags.map{|url, val| "url: #{url}\ntag: #{val[:callcv_old].map{|tag| tag[:tag]}}\n" if val[:callcv_old]}.compact
	end
	def callcv_new_tags_url
		@tags.map{|url, val| "url: #{url}\ntag: #{val[:callcv_new].map{|tag| tag[:tag]}}\n" if val[:callcv_new]}.compact
	end

	def push(url, title, tags)
		tags.each do |kind, val|
			@tags[url][kind] = [] unless @tags[url][kind]
			@tags[url][kind] += val
		end
		@tags[url][:title] = title
	end
end

root_url = ARGV[0]

if root_url
	filename = root_url.gsub(/[\\\/:*?"<>|]/, "").gsub(/^https?/, "")
	filepath = "log/#{filename}.txt"

	FileUtils.mkdir_p("tmp/") unless FileTest.exist?("tmp/")

	shikake = Shikake.new(root_url)
	scan_result = shikake.scan
	result = <<-EOD
date:               #{DateTime.now.strftime "%Y-%m-%d %H:%M:%S"}

url:                #{root_url}
all pages:          #{scan_result.pages.length} pages

ga tags:            #{scan_result.ga_pages.length} pages
no ga tags:         #{scan_result.no_ga_pages.length} pages
tag ids:            #{scan_result.ga_tags}        

univ tags:          #{scan_result.univ_pages.length} pages
no univ tags:       #{scan_result.no_univ_pages.length} pages
tag ids:            #{scan_result.univ_tags}

old event tags:     #{scan_result.event_old_pages.length} pages
no old event tags:  #{scan_result.no_event_old_pages.length} pages
tag ids:            #{scan_result.event_old_tags}        

new event tags:     #{scan_result.event_new_pages.length} pages
no new event tags:  #{scan_result.no_event_new_pages.length} pages
tag ids:            #{scan_result.event_new_tags}        

old callcv tags:    #{scan_result.callcv_old_pages.length} pages
no old callcv tags: #{scan_result.no_callcv_old_pages.length} pages
tag ids:            #{scan_result.callcv_old_tags}        

new callcv tags:    #{scan_result.callcv_new_pages.length} pages
no new callcv tags: #{scan_result.no_callcv_new_pages.length} pages
tag ids:            #{scan_result.callcv_new_tags}        
	EOD
	puts ""
	puts result
	FileUtils.mkdir_p("log/") unless FileTest.exist?("log/")
	File.open(filepath, "w+") do |file|
		file.write result
		file.write "\n"
		file.write "以下のページに旧GoogleAnalyticsタグが見つかりました。\n\n"
		file.write scan_result.ga_tags_url.join("\n") + "\n"
		file.write "=================================================================\n"
		file.write "\n"
		file.write "以下のページにはユニバーサルAnalyticsタグが見つかりませんでした。\n\n"
		file.write scan_result.no_univ_tags_url.join("\n") + "\n"
		file.write "=================================================================\n"
		file.write "\n"
		file.write "以下の旧イベントタグが見つかりました。\n\n"
		file.write scan_result.event_old_tags_url.join("\n")
		file.write "=================================================================\n"
		file.write "\n"
		file.write "以下の新イベントタグが見つかりました。\n\n"
		file.write scan_result.event_new_tags_url.join("\n")
		file.write "=================================================================\n"
		file.write "\n"
		file.write "以下の旧Call CVタグが見つかりました。\n\n"
		file.write scan_result.callcv_old_tags_url.join("\n")
		file.write "=================================================================\n"
		file.write "\n"
		file.write "以下の新Call CVタグが見つかりました。\n\n"
		file.write scan_result.callcv_new_tags_url.join("\n")
		file.write "=================================================================\n"
	end
	puts "\n#{File.expand_path(filepath)}"
	puts "に結果を保存しました。"
else
	puts "サイトのURLを指定して実行してください。"
	puts "例:"
	puts "ruby #{$0} http://www.example.com/"
end
