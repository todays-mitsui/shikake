require 'bundler'
Bundler.require

require './lib/profile'
require './lib/profile_print'
require './lib/spider'

REGEXP = {
	:ga           => /(\[.*_setAccount.+(UA-\d+-\d+).+\])/i,
	:univ         => /(ga\s*\(\s*('create'|"create").*(UA-\d+-\d+).+;)/im,
	:disp_feat    => /ga\s*\(\s*('require'|"require")\s*,\s*('displayfeatures'|"displayfeatures")\s*\)/i,
	:old_event    => /_?gaq.push\s*\(\s*(\[('_trackEvent'|"_trackEvent").*\])\s*\)/i,
	:new_event    => /(ga\s*\(('send'|"send").*,.*('event'|"event").*\))/i,
	:old_pv       => /_?gaq.push\s*\(\s*(\[('_trackPageview'|"_trackPageview").*\])\s*\)/i,
	:new_pv       => /ga\s*(\(('send'|"send").*,.*('pageview'|"pageview").*\))/i,
	:g_adwords_cv => /google_conversion_id\s*=\s*(\d+).+google_conversion_label\s*=\s*["'](\w*)["'].+google_remarketing_only\s*=\s*false/im,
	:g_remarke    => /google_conversion_id\s*=\s*(\d+).+google_conversion_label\s*=\s*["'](\w*)["'].+google_remarketing_only\s*=\s*true/im,
	:yss_cv       => /yahoo_conversion_id\s*=\s*(\d+).+yahoo_conversion_label\s*=\s*["'](\w*)["']/im,
	:ydn_remarke  => /yahoo_retargeting_id\s*=\s*["'](\w+)["'].+yahoo_retargeting_label\s*=\s*["'](\w*)["']/im,
	:ydn_cv       => %r{sccount_id\s*=\s*["']([\w\.]+)["'].+//b90\.yahoo\.co\.jp/c\?}im,
	:ytm          => %r{"//s\.yjtag\.jp/tag\.js#(site=[^"]+)"},
}

if ARGV[0].nil? || !%r{^https?://.+}.match(ARGV[0])
	puts "スキャンするURLを指定してください。"
else
	spider = Shikake::Spider.new(ARGV[0])

	spider.train(:ga ,{
		:name => "GoogleAnalytics",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:ga],
		:val => lambda{|el,md| "id: #{md[2]}"}
	})
	spider.train(:univ ,{
		:name => "UniversalAnalytics",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:univ],
		:val => lambda{|el,md| "id: #{md[3]}, displayfeatures: #{el.text.match(REGEXP[:disp_feat]) ? 'YES' : 'NO'}"}
	})
	spider.train(:ytm ,{
		:name => "Yahoo!TagManager",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:ytm],
		:val => lambda{|el,md| "id: #{md[1]}"}
	})
	spider.train(:old_event ,{
		:name => "OldTrackEvent",
		:selector => "a",
		:before => lambda{|el| el.attribute("onclick")},
		:regexp => REGEXP[:old_event],
		:val => lambda{|el,md| "id: #{md[1]}, href: \"#{el.attribute("href")}\""}
	})
	spider.train(:new_event ,{
		:name => "NewTrackEvent",
		:selector => "a",
		:before => lambda{|el| el.attribute("onclick")},
		:regexp => REGEXP[:new_event],
		:val => lambda{|el,md| "id: #{md[1]}, href: \"#{el.attribute("href")}\""}
	})
	spider.train(:old_pv ,{
		:name => "OldTrackPageview",
		:selector => "a",
		:before => lambda{|el| el.attribute("onclick")},
		:regexp => REGEXP[:old_pv],
		:val => lambda{|el,md| "id: #{md[1]}, href: \"#{el.attribute("href")}\""}
	})
	spider.train(:new_pv ,{
		:name => "NewTrackPageview",
		:selector => "a",
		:before => lambda{|el| el.attribute("onclick")},
		:regexp => REGEXP[:new_pv],
		:val => lambda{|el,md| "id: #{md[1]}, href: \"#{el.attribute("href")}\""}
	})
	spider.train(:g_adwords_cv ,{
		:name => "GoogleAdWordsConversion",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:g_adwords_cv],
		:val => lambda{|el,md| "id: #{md[1]}, label: #{md[2].empty? ? '無し' : md[2]}"}
	})
	spider.train(:g_remarke ,{
		:name => "GoogleAdWordsRemarketing",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:g_remarke],
		:val => lambda{|el,md| "id: #{md[1]}, label: #{md[2].empty? ? '無し' : md[2]}"}
	})
	spider.train(:yss_cv ,{
		:name => "YSS_Conversion",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:yss_cv],
		:val => lambda{|el,md| "id: #{md[1]}, label: #{md[2].empty? ? '無し' : md[2]}"}
	})
	spider.train(:ydn_remarke ,{
		:name => "YDN_Remarketing",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:ydn_remarke],
		:val => lambda{|el,md| "id: #{md[1]}, label: #{md[2].empty? ? '無し' : md[2]}"}
	})
	spider.train(:ydn_cv ,{
		:name => "YDN_Conversion",
		:selector => "script",
		:before => lambda{|el| el.text},
		:regexp => REGEXP[:ydn_cv],
		:val => lambda{|el,md| "id: #{md[1]}"}
	})

	spider.scan.show.save
end


