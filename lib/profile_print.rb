module Shikake
	class Profile

		def show
			puts "#{common}done."
		end

		private

			def common
			 <<-EOS

スキャン日時: #{@start.strftime "%Y-%m-%d %H:%M:%S"}
所要時間:     #{(@done - @start).to_i}秒

ルートURL:    #{@root_url}
ページ数:     #{length} pages

#{@kinds.map{|kind| dichotomize kind}.join("\n")}
				EOS
			end

			def dichotomize kind
				tag_id, tag_name = kind
				<<-EOS
[#{tag_name}] exists:  #{select(tag_id).length} pages
[#{tag_name}] is none: #{reject(tag_id).length} pages
ids: #{values(tag_id)}
				EOS
			end
	end
end
