module Shikake
	class Profile
		def initialize
			@profile = {}
		end

		def to_s
			@profile.to_s
		end

		def [] url
			@profile[url]
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


		def select key
			@profile.select do |url,prof|
				is_key_exist = prof.include?(key) && !prof[key].empty?
				!block_given? || yield(prof[key]) if is_key_exist
			end
		end

		def reject key
			@profile.reject do |url,prof|
				is_key_exist = prof.include?(key) && !prof[key].empty?
				!block_given? || yield(prof[key]) if is_key_exist
			end
		end


		def values key
			@profile.map{|url,prof| prof[key]}.flatten.compact.uniq
		end
	end
end
