module Shikake
	class Spider < Anemone::Core
		USER_AGENT = {
			:pc =>  "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.63 Safari/537.36",
			:sp => "Mozilla/5.0 (iPhone; CPU iPhone OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A403 Safari/8536.25"
		}

		def initialize url
			super
			@root_url = url
			@ignore_url = [
				[%r{(/img/|/upimg/)}i, false],
				[%r{(\.jpe?g$|\.gif$|\.png$|\.pdf$)}i, false]
			]
			@regexp = []
			@kinds = []
			@blueprint = Hash.new

			FileUtils.mkdir_p("tmp/") unless FileTest.exist?("tmp/")
			@tmp_path = "tmp/tmp_#{(0...8).map{(65+rand(26)).chr}.join}.txt"

			@opts.merge!({
				:skip_query_strings => true,
				:delay => 0.6,
				:depth_limit => 8,
				:read_timeout => 20,
				:storage => Anemone::Storage.PStore(@tmp_path),
				:verbose => true
			})
			set_user_agent
			set_root_filter
		end


		def scan
			focus_crawl &set_focus
			on_pages_like(%r{\.html?$}, %r{\.php$}, %r{/$}, &crawl)

			@prof = Shikake::Profile.new
			@prof.kinds = @kinds
			@prof.root_url = @root_url
			@prof.start = Time.now
			run
			@prof.done = Time.now
			@prof
		end

		def train tag_id, blueprint
			@kinds << [tag_id.to_sym, blueprint[:name]] 
			@blueprint[tag_id] = blueprint
		end

		def crawl
			lambda do |page|
				@prof[page.url] = {
					:title => page.doc.title,
					:links => page.links
				}
				@blueprint.keys.each do |kind|
					@prof[page.url] = {kind => find_tags(kind, page)}
				end
			end
		end

		def set_user_agent
			if @root_url.match(%r{(/sp/|/sp$)})
				@opts[:user_agent] = USER_AGENT[:sp]
				#@ignore_url << [%r{(/sp/|/sp$)}, true]
			else
				@opts[:user_agent] = USER_AGENT[:pc]
				@ignore_url << [%r{(/sp/|/sp$)}, false]
			end
		end

		def set_root_filter
			root_filter = Regexp.new(@root_url.gsub(%r{^https?:}, "").gsub(%r{[^/]+\.(html?|php)}, "").gsub(%r{/$}, "") + "/")
			@ignore_url << [root_filter, true]
		end

		def set_focus
			lambda do |page|
				page.links.keep_if do |link|
					href = link.to_s
					@ignore_url.all? do |filter|
						if filter[1]
							href.match(filter[0])
						else
							!href.match(filter[0])
						end
					end
				end
			end
		end

		def find_tags kind, page
			if !@blueprint[kind].nil?
				name = @blueprint[kind][:name]
				selector = @blueprint[kind][:selector]
				before_factory = @blueprint[kind][:before]
				regexp = @blueprint[kind][:regexp]
				after_factory = @blueprint[kind][:val]

				result = []
				page.doc.css(selector).each do |el|
					target = before_factory.call(el)
					match_data = target.to_s.match(regexp) if target
					result << after_factory.call(match_data) if match_data
				end
				result
			end
		end
	end
end
