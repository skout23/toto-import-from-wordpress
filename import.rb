#!/usr/bin/env ruby

require 'rubygems'
require 'hpricot'
require 'time'
require 'toto'

file = File.new(ARGV[0])

doc = Hpricot( File.open(file) )
nginx_rewrite = File.open('./rewrite.nginx', 'w')
rack_rewrite = File.open('./rewrite.rack', 'w')

(doc/"item").each do |item|
if item.search("wp:post_type").first.inner_text == "post" and item.search("wp:status").first.inner_text == "publish" then

#  I did not need to export comments, so I just ignored them for now, however here they are
#  comments = item.search("wp:comment_approved").reject {|ct| ct.inner_text != "1" }.size
#  pingbacks = item.search("wp:comment_type").reject {|ct| ct.inner_text != "pingback" }.size
  is_private = ( item.search("wp:status").first.inner_text == "private" )
#  has_comments = ( comments > 0 && comments > pingbacks )
  tags = item.search("category[@domain='post_tag']").collect{|n| n[:nicename]}.uniq
  tags = tags.map { |t| t.downcase }.sort.uniq
  # will need this once toto will be able to handle categories
  #category = item.search("category[@domain='category']").collect{|n| n[:nicename]}.uniq
  #category = category.map { |t| t.downcase }.sort.uniq.join('/')
  #category = '' if category == "uncategorized"
  
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

  new_url = "/#{time.strftime("%Y/%m/%d")}#{'-' + slug if slug}"
  nginx_rewrite.puts "rewrite ^/(?p=|archives/)#{post_id} #{new_url} permanent;\n"
  rack_rewrite.puts "r301 %r{/(?p=|archives/)#post_id)}, '#new_url'\n"
  
  begin 
    newpost = File.open(path,'w')
    newpost.puts "---\ntitle: #{title.chomp}\n"
# Should be able to pull your toto config here, but just in case I made it static for me.
    newpost.puts "author: YOUR_AUTHOR"
    newpost.puts "tags: #{tags.join(', ')}\n"
# If you use a differing format for the date, you might need to change this strftime
    newpost.puts "date: #{time.strftime("%d/%m/%Y")}"
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




