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

def isOutOfDomain?(link)  
	return (link.to_s.start_with?('http') || link.to_s.start_with?('https') || link.to_s.include?('www.googletagmanager.com')  || link.to_s.include?('player.vimeo.com') )
end

def hasBeenCrawled?(link)
	return !$pagesCrawled.include?(link.to_s)
end


def isValidLink?(link)
	return !isOutOfDomain?(link.to_s) && hasBeenCrawled?(link)  && !(link =~ /^.*\.gocardless\.com/)
end

def getHrefAndSrcLinks(html)
	return html.xpath('//*[@href]/@href | //*[@src]/@src')
end

def isStaticAsset?(link)
	return link.to_s =~ /(jpg|jpeg|gif|png|css|js|ico|xml|rss|txt|svg|css)$/
end

#This function adds static asset link to the hash of arrays
def addToHash(parentLink, link)

	$staticAssets[parentLink.to_s].push(link.to_s) 
end

def creatingHashKey(parentLink)
		
		$staticAssets[parentLink.to_s] = Array.new
end

def crawlLink(parentLink)

		html = getPage($agent, parentLink);
		links = getHrefAndSrcLinks(html)

		#Hash of arrays: each element of the hash is the page crawled and the array is the static assets of that page.
		creatingHashKey(parentLink)

		links.each do |link|

			if !isValidLink?(link)
				#If link is invalid we don't have to dismmiss this link
			elsif isStaticAsset?(link) 
				addToHash(parentLink, link)
			else 
				puts "To crawl -->"+link.to_s
				$pagesCrawled << link.to_s
				crawlLink(link)
			end 

		end
		

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
	$file.puts $staticAssets
rescue  Mechanize::ResponseCodeError  => ex
	puts "Status code error"+ ex.response_code
	$log.info("Status code error->"+ex.response_code)
end






