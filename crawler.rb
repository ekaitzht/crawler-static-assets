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
		page = agent.get(url,'',nil)		
		return Nokogiri::HTML(page.body)
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
	return !isOutOfDomain(link.to_s) && !$pagesCrawled.include?(link.to_s)  && !(link =~ /^.*\.gocardless\.com/)
end

def getHrefAndSrcLinks(html)
	return html.xpath('//*[@href]/@href | //*[@src]/@src')
end

def isStaticAsset(link)
	return link.to_s =~ /(jpg|jpeg|gif|png|css|js|ico|xml|rss|txt|svg|css)$/
end

#This function adds static asset link to the hash of arrays
def addToHash(link)
	$staticAssets["hashIndex-"+parentLink.to_s].push(link.to_s) 
end

def crawlLink(parentLink)

		html = getPage($agent, parentLink);
		src_hrefs = getHrefAndSrcLinks(html)

		#Hash of arrays: each element of the hash is the page crawled and the array is the static assets of that page.
		$staticAssets["hashIndex-"+parentLink] = Array.new

		src_hrefs.each do |link|

			if !isValidLink(link)
			elsif isStaticAsset(link)  
				addToHash(link)
			else 
				$pagesCrawled << link.to_s
				crawlLink(link)
			end 

		end
		$file.puts $staticAssets

end


#**************************  MAIN FUNCTION ****************************#
$staticAssets = Hash.new
rootUrl = 'https://gocardless.com'
$pagesCrawled = Array.new
$agent = Mechanize.new 
$file = open('myfile.out', 'w')
$pagesCrawled << '/'

begin
	crawlLink(rootUrl)
rescue  Mechanize::ResponseCodeError  => ex
	puts "Status code error"+ ex.response_code
	$log.info("Status code error->"+ex.response_code)
end






