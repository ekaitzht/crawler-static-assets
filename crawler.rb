#!/bin/env ruby
# encoding: utf-8
# by Ekaitz Hernandez
$LOAD_PATH << '.'

require 'uri'
require 'net/http'
require 'json'
require 'nokogiri'
require 'open-uri'
require 'openssl'
require 'date'
require 'time'
require 'fileutils'
require 'csv'
require 'mechanize'
require 'set'


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE




def getPage(agent, url)
		product = agent.get(url,'',nil)		
		return product
end

def isOutOfDomain(link)  
	return  (link.to_s.start_with?('http') || link.to_s.start_with?('https') || link.to_s.include?('www.googletagmanager.com')  || link.to_s.include?('player.vimeo.com') )
end



def blackList(link)
	blackListDomains = ["https://gocardless.com","https://plus.google.com","https://accounts.google.com/","/en-eu/"]
	forbidden = false
	blackListDomains.each do |linkBlackList|

		if(link.to_s.start_with?(linkBlackList)) 
			return true
		end
	end
	return forbidden
end

def isValidLink(link)
	return !isOutOfDomain(link.to_s) && !$websitesScraped.include?(link.to_s) 
end

def getHrefAndSrcLinks()
	return html.xpath('//*[@href]/@href | //*[@src]/@src')
end


def crawlLink(parentLink)

		page = getPage($agent, parentLink);
		html =  Nokogiri::HTML(page.body)
		src_hrefs = getHrefAndSrcLinks()

		puts "Parentlink to hash->" + parentLink
		$staticAssets["hashIndex-"+parentLink] = Array.new

		src_hrefs.each do |link|

			if !isValidLink(link)
				#puts "This link jumped ==> "+link.to_s 
			elsif  link.to_s =~ /(jpg|jpeg|gif|png|css|js|ico|xml|rss|txt|svg|css)$/
				
				if(!$staticAssets["hashIndex-"+parentLink.to_s].include?(link.to_s))
					$staticAssets["hashIndex-"+parentLink.to_s].push(link.to_s) 
				end
			else 
				#puts "Link to crawl ===> "+ link.to_s
				$websitesScraped << link.to_s
				crawlLink(link)
			end
		end
		$file.puts $staticAssets

end


#**************************  MAIN FUNCTION ****************************#
$staticAssets = Hash.new
rootUrl = 'https://gocardless.com'
$websitesScraped = Array.new
puts 'Launching GoCardless crawler ...'
$agent = Mechanize.new 
$file = open('myfile.out', 'w')

begin
	crawlLink(rootUrl)
rescue  Mechanize::ResponseCodeError  => ex
	puts "Status code error"+ ex.response_code
	$log.info("Status code error->"+ex.response_code)
end






