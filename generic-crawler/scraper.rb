# -*- encoding : utf-8 -*-
require 'net/http'
require 'uri'
require 'open-uri'
require 'rubygems'
require 'hpricot'
require 'cgi'
require 'ruby-debug'
#require 'url_utils'

# USAGE: 
# load './scraper.rb'
# Scraper.run

module Scraper
  SCHOOL = "ncsu"
  OUTPUT_FILE = SCHOOL+"_emails.txt"
  OUTPUT_FILE_NAMES = SCHOOL+"_names_count.txt"
  @counter = 0
  @query_counter = 0
  @name = nil
  @outfile = nil
  @names_count_file = nil

  def self.run
    initialize
    loop_names
  end

  def self.initialize
    puts "Using output file: #{OUTPUT_FILE}"
    @outfile = f = File.open(OUTPUT_FILE,  "a+")   
    @names_count_file = f = File.open(OUTPUT_FILE_NAMES,  "a+")   
  end

  def self.open_url(url)
    url_object = nil
    begin
      url_object = open(url)
    rescue
      puts "Unable to open url: " + url
    end
    return url_object
  end

  def self.loop_names
    load 'names.rb'
    NAMES.each do |name|
      @name = name
      @query_counter += 1
      puts "searching name: #{name} -- QUERY #{@query_counter}: "
      #url = "http://search.msu.edu/people/index.php?fst=#{name}&lst=&nid=&search=Search&type=stu"
      #url = "http://www.nyu.edu/search.directory.html?search=#{name}&filter_base_id=students"
      url = "http://www.ncsu.edu/directory/?lastnametype=starts&lastname=&firstnametype=starts&firstname=#{name}&emailaddresstype=equals&emailaddress=&addresstype=contains&address=&phonenumbertype=ends&phonenumber=&departmenttype=contains&department=&titletype=contains&title=&searchtype=students&matchnicks=on&includevcard=on&order=mixed&style=brief&search=Search"
      #url = "http://auth.uakron.edu/zid/student-dir/index.cgi?state=dosearch&sn=&givenname=#{name}&partial=p"
      #url = "http://www.ucr.edu/find_people.php?term=#{name}&sa=Go&type=student"
      url_object = open_url(url)
      if url_object
        parsed_url = parse_url(url_object).to_plain_text
        if parsed_url
          #find_emails_in_doc(parsed_url) 
          find_links_in_doc(parsed_url)
        else
          show_failed_url(url)
        end
      else
        show_failed_url(url)
      end
    end
  end

  def self.show_failed_url(url)
    puts "\n\n\n\nPROBLEM WITH URL: #{url}\n\n\n\n"
    debugger
  end
  
  def self.parse_url(url_object)
    doc = nil
    begin
      doc = Hpricot(url_object)
    rescue
      puts 'Could not parse url: ' + url_object.base_uri.to_s
    end
    puts 'Crawling url ' + url_object.base_uri.to_s
    return doc
  end

  def self.find_links_in_doc(parsed_url)
    urls = []
    parsed_url.each_line do |s|
      link = s.match(/moreinfo.php\?username=([a-zA-Z0-9\._-]*)*/) 
      if link and link[0]
        link = link[0]
        urls << "http://www.ncsu.edu/directory/"+link
      end
    end
    puts urls.to_s
    
    urls.each do |url|
      url_object = open_url(url)
      if url_object
        parsed_url2 = parse_url(url_object).to_plain_text
        if parsed_url2
          find_emails_in_doc(parsed_url2) 
        else
          show_failed_url(url)
        end
      else
        show_failed_url(url)
      end      
    end
  end

  def self.find_emails_in_doc(parsed_url)
    count_start = @counter
    parsed_url.each_line do |s|
      #email = s.match(/[a-z0-9]*@([a-z]*[\._-]*)*msu.edu/)
      #email = s.match(/[a-z0-9]*@([a-z]*[\._-]*)*nyu.edu/)
      email = s.match(/[a-zA-Z0-9\._-]*@([a-z]*[\._-]*)*ncsu.edu/)
      #email = s.match(/[a-z0-9]*@([a-z]*[\._-]*)*uakron.edu/)
      #email = s.match(/[a-z0-9]*@([a-z]*[\._-]*)*ucr.edu/)
      if email and email[0] and !email[0].include?('help')
        @counter += 1
        email = email[0]
        puts "Saving Email #{@counter}: #{email}"
        @outfile << email + "\n"
      end
    end
    @outfile.flush

    count = @counter - count_start
    names_count = "#{count}#{" "*(5-count.to_s.size)} #{@name}"
    @names_count_file << names_count + "\n"
    @names_count_file.flush
    puts names_count
  end
end
