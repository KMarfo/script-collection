#!/usr/local/bin/ruby
# $Id: makecheckinglinks.rb 27 2009-06-16 13:28:59Z johnmignault $
require 'rexml/document'
include REXML
require 'getoptlong'
require 'csv'

infile = ''
outfile = ''
pagetitle = 'Link checks'
opts = GetoptLong.new(
                      [ "--file", "-f", GetoptLong::REQUIRED_ARGUMENT ],
                      [ "--out", "-o",  GetoptLong::REQUIRED_ARGUMENT ]
                      )

opts.each do |opt, arg|
  case opt
  when '--file'
    infile = arg.to_s

  when '--out'
    outfile = arg.to_s
  end
end

doc = Document.new

xmldec = XMLDecl.new()
xmldec.encoding=('UTF-8')
doc.add(xmldec)

doc.add(REXML::DocType.new('html', 'PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"'))
index_html = Element.new("html")
index_html.attributes['xmlns'] = 'http://www.w3.org/1999/xhtml'
head = Element.new("head")
title = Element.new("title")
text = Text.new(pagetitle)
title.add(text)
head.add(title)
index_html.add(head)
body = Element.new("body")

div = Element.new("div")
h1 = Element.new("h1")
h1.text = pagetitle

div.add(h1)


CSV.open(infile, "r").each do |line|
  begin
    line[1].split(/;/).each do |url|
      url.sub!(/^u /, '')
      url.sub!(/^[^h]ttp/, 'http')
      url.strip!
      link = Element.new("a")
      link.attributes['href'] = url
      link.text = line[0] + ' - ' + line[2] + ' - ' + line[3]
      div.add(link)
      div.add(Element.new("br"))
    end
  rescue
    puts line 
    puts "error: " + $!.message
  end
end

body.add(div)
index_html.add(body)
doc.add(index_html)
doc.write(File.new(outfile, 'w'))
