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
				file.write "\n"
				file.write @kinds.map{|kind| print_url_list kind,(kind.first == :univ)}.join("\n")
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

#{@kinds.map{|kind| print_dichotomize kind}.join("\n")}
				EOS
			end

			def print_dichotomize kind
				tag_id, tag_name = kind
				<<-EOS
[#{tag_name}] exists:  #{select(tag_id).length} pages
[#{tag_name}] is none: #{reject(tag_id).length} pages
ids: #{values(tag_id)}
				EOS
			end

			def print_url_list kind, reverse
				tag_id, tag_name = kind
				if !reverse
					<<-EOS
[#{tag_name}]が見つかったURL

#{select(tag_id).keys.join("\n")}

================================================================
					EOS
				else
					<<-EOS
[#{tag_name}]が見つからなかったURL

#{reject(tag_id).keys.join("\n")}

================================================================
					EOS
				end
			end
	end
end
