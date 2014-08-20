module Shikake
	class Profile
		def initialize
			@profile = {}
		end

		def to_s
			@profile.to_s
		end

		def []= url,hash
			@profile[url] = {} unless @profile[url]
			hash.each do |key,val|
				case key
					when :title
						@profile[url][:title] = val
					else
						@profile[url][key] = [] unless @profile[url][key].instance_of?(Array)
						@profile[url][key].push(val).flatten!
					end
			end
		end
	end
end
