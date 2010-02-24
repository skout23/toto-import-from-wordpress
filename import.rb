#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'time'
require 'toto'

file = File.new(ARGV[0])

doc = Hpricot( File.open(file) )

(doc/"item").each do |item|
if item.search("wp:post_type").first.inner_text == "post" and item.search("wp:status").first.inner_text == "publish" then

#  I did not need to export comments, so I just ignored them for now, however here they are
#  comments = item.search("wp:comment_approved").reject {|ct| ct.inner_text != "1" }.size
#  pingbacks = item.search("wp:comment_type").reject {|ct| ct.inner_text != "pingback" }.size
  is_private = ( item.search("wp:status").first.inner_text == "private" )
#  has_comments = ( comments > 0 && comments > pingbacks )
  tags = item.search("category[@domain='tag']").collect(&:inner_text).uniq
  tags = tags.map { |t| t.downcase }.sort.uniq
  
  next if item.search("wp:post_type").first.inner_text != "post"
  
  post_id = item.search("wp:post_id").first.inner_text.to_i
  title = item.search("title").first.inner_text.gsub(/:/, '')
  slug = title.empty?? nil : title.strip.slugize
  time = Time.parse item.search("wp:post_date").first.inner_text
  link = item.search("link").first.inner_text
  
  content = item.search("content:encoded").first.inner_text.to_s
 
  if content.strip.empty?
    puts "Failed to parse postId #{post_id}:#{title}"
    next
  end
  
# If you use a differing format for the slug, you should change this strftime
  path = "./articles/#{time.strftime("%Y-%m-%d")}#{'-' + slug if slug}.txt"
  
  begin 
    newpost = File.open(path,'w')
    newpost.puts "---\ntitle: #{title.chomp}\n"
# Should be able to pull your toto config here, but just in case I made it static for me.
    newpost.puts "author: YOUR_AUTHOR"
# If you use a differing format for the date, you might need to change this strftime
    newpost.puts "date: #{time.strftime("%d/%m/%Y")}"
# if in the future toto handles tags or the like in a default manner I will update this accordingly
    #newpost.puts "tags: #{tags}\n" if !tags.nil? and !tags.empty?
    newpost.puts "\n\n\n"
    newpost.puts content
  rescue Exception => e  
    puts e.message  
    puts e.backtrace.inspect  
    puts "ERROR! could not save post #{title}"
    exit
  end  
end
end




