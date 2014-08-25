module Shikake
	class Profile

		def show
			puts common
			self
		end

		def save
			FileUtils.mkdir_p("log/") unless FileTest.exist?("log/")
			filename = @root_url.gsub(%r{https?://}, "").gsub(%r{/$}, "").gsub(%r{[\\:;*?"<>|]}, "").gsub(%r{/}, "__")
			filepath = "log/#{filename}[#{@start.strftime"%Y%m%d_%H%M%S"}].txt"
			File.open(filepath, "w+") do |file|
				file.write common
				file.write "\n\n"
				file.write @blueprint.map{|tag_id,attribute| print_url_list tag_id,attribute}.join
			end
			puts <<-EOS
#{File.expand_path(filepath)}
に結果を保存しました。
			EOS
			self
		end

		private

			def common
			 <<-EOS

スキャン日時: #{@start.strftime "%Y-%m-%d %H:%M:%S"}
所要時間:     #{(@done - @start).to_i}秒

ルートURL:    #{@root_url}
ページ数:     #{length} pages

#{@blueprint.map{|tag_id,attribute| print_dichotomize tag_id, attribute}.join("\n")}
				EOS
			end

			def print_dichotomize tag_id, attribute
				<<-EOS
[#{attribute[:name]}] exists:  #{select(tag_id).length} pages
[#{attribute[:name]}] is none: #{reject(tag_id).length} pages
ids: #{values(tag_id)}
				EOS
			end

			def print_url_list tag_id, attribute
				if attribute[:required]
					urls = reject(tag_id)
					if !urls.empty?
						<<-EOS
[#{attribute[:name]}]が見つからなかったURL

#{urls.keys.join("\n")}

================================================================

						EOS
					end
				else
					urls = select(tag_id)
					if !urls.empty?
						<<-EOS
[#{attribute[:name]}]が見つかったURL

#{print_url_list_helper(urls, tag_id, attribute[:verbose]).join("\n")}

================================================================

						EOS
					end
				end
			end

			def print_url_list_helper urls, tag_id, is_verbose
				if is_verbose
					urls.map do |url,value|
						"#{url}\n#{value[tag_id]}\n"
					end
				else
					urls.keys
				end
			end
	end
end
