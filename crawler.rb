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


OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE



def getCookie(agent, uri)
	status = Timeout::timeout(30) {
	 	# Something that should be interrupted if it takes more than 5 seconds...

 	 	pageGetCookie = agent.get(uri,'',nil,
					{
					'Accept'=>'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
					'Accept-Encoding'=>'gzip,deflate,sdch',
					'Accept-Language'=>'en-us,en:q=0.8',
					'Connection'=>'keep-alive',
					'Referer'=>'https://www.google.com/',
					'Host'=>'www.sephora.com', 
					'User-Agent'=>'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.71 Safari/537.36',

					}
		)

		return pageGetCookie['Set-cookie']
	}
end

def getProduct(agent, url)
		puts "GET: " + url;
		product = agent.get(url,'',nil)
			
		return product

end



def isOutOfDomain(link)

	return  (link.to_s.start_with?('http') || link.to_s.start_with?('https'))
		
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


def crawlLink(parentLink)

		page = getProduct($agent, parentLink);
		html =  Nokogiri::HTML(page.body)
		href_links = html.xpath('//*[@href]/@href')

		href_links.each do |link|

			if !isValidLink(link)

				puts "This link jumped ==> "+link.to_s 
			else 

				if link.to_s.end_with?('css') || link.to_s.end_with?('png') || link.to_s.end_with?('js') 
					puts "Asset link ==> "+link.to_s 
					$staticAssets << link
				else 
					#print $websitesScraped
					puts "Link to crawl ===> "+ link.to_s
					$websitesScraped << link.to_s
					$file << link
					crawlLink(link)
				end
			end
		end

		puts $websitesScraped

end


rootUrl = 'https://gocardless.com/en-eu/'
$websitesScraped = Array.new
$staticAssets = Array.new
puts 'Launching GoCardless crawler ...'
$agent = Mechanize.new 
$file = open('myfile.out', 'w')



crawlLink(rootUrl)




