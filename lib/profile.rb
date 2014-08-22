module Shikake
	class Profile
		def initialize profile={}
			@profile = profile
		end

		def to_s
			@profile.to_s
		end

		def length
			@profile.length
		end

		def [] url
			@profile[url.to_sym]
		end

		def []= url,hash
			@profile[url] = {} unless @profile[url]
			hash.each do |key,val|
				key = key.to_sym
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

		#def find_all regexp
		#	map do |url,prof|
		#		
		#	end
		#end

		#def find_helper regexp,hash
		#	hash.inject({}) do |memo,(kind,val)|
		#		if val.instance_of? Array
		#			val.select!{|item| item.to_s.match(regexp)}
		#			memo[] unless val.empty?
		#		else
		#			val.to_s
		#	end
		#end

		def map(*args)
			@profile.inject({}) do |memo,(url,prof)|
				if args.empty?
					memo[url] = yield(url,prof)
				else
					key = args.first.to_sym
					return memo unless prof.include? key
					if block_given?
						memo[url] = yield(url,prof[key]) 
					else
						memo[url] = prof[key]
					end
				end
				memo
			end
		end
	end
end
