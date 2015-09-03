#!/usr/local/bin/ruby -w

# Ruby beautifier, version 1.3, 04/03/2006
# Copyright (c) 2006, P. Lutus
# Released under the GPL

require 'getoptlong'

$tabSize = 4
$tabStr = " "

opts = GetoptLong.new( 
                      [ "--tabwidth", "-t", GetoptLong::OPTIONAL_ARGUMENT ] 
                      ) 

opts.each do |opt, arg| 
  case opt
  when '--tabwidth'
    $tabSize = arg.to_i
  end
end

# indent regexp tests

$indentExp = [
  /^module\b/,
  /(=\s*|^)if\b/,
  /(=\s*|^)until\b/,
  /(=\s*|^)for\b/,
  /(=\s*|^)unless\b/,
  /(=\s*|^)while\b/,
  /(=\s*|^)begin\b/,
  /(=\s*|^)case\b/,
  /\bthen\b/,
  /^class\b/,
  /^rescue\b/,
  /^def\b/,
  /\bdo\b/,
  /^else\b/,
  /^elsif\b/,
  /^ensure\b/,
  /\bwhen\b/,
  /\{[^\}]*$/,
  /\[[^\]]*$/
]

# outdent regexp tests

$outdentExp = [
  /^rescue\b/,
  /^ensure\b/,
  /^elsif\b/,
  /^end\b/,
  /^else\b/,
  /\bwhen\b/,
  /^[^\{]*\}/,
  /^[^\[]*\]/
]

def makeTab(tab)
  return (tab < 0)?"":$tabStr * $tabSize * tab
end

def addLine(line,tab)
  line.strip!
  line = makeTab(tab)+line if line.length > 0
  return line + "\n"
end

def beautifyRuby(path)
  commentBlock = false
  multiLineArray = Array.new
  multiLineStr = ""
  tab = 0
  source = File.read(path)
  dest = ""
  source.split("\n").each do |line|
    # combine continuing lines
    if(!(line =~ /^\s*#/) && line =~ /[^\\]\\\s*$/)
           multiLineArray.push line
         multiLineStr += line.sub(/^(.*)\\\s*$/,"\\1")
         next
       end

       # add final line
       if(multiLineStr.length > 0)
multiLineArray.push line
multiLineStr += line.sub(/^(.*)\\\s*$/,"\\1")
      end

      tline = ((multiLineStr.length > 0)?multiLineStr:line).strip
      if(tline =~ /^=begin/)
         commentBlock = true
      end
      if(commentBlock)
         # add the line unchanged
         dest += line + "\n"
      else
         commentLine = (tline =~ /^#/)
         if(!commentLine)
            # throw out sequences that will
            # only sow confusion
            tline.gsub!(/\/.*?\//,"")
            tline.gsub!(/%r\{.*?\}/,"")
            tline.gsub!(/%r(.).*?\1/,"")
            tline.gsub!(/\\\"/,"'")
            tline.gsub!(/".*?"/,"\"\"")
            tline.gsub!(/'.*?'/,"''")
            tline.gsub!(/#\{.*?\}/,"")
            $outdentExp.each do |re|
               if(tline =~ re)
                  tab -= 1
                  break
               end
            end
         end
         if (multiLineArray.length > 0)
            multiLineArray.each do |ml|
               dest += addLine(ml,tab)
            end
            multiLineArray.clear
            multiLineStr = ""
         else
            dest += addLine(line,tab)
         end
         if(!commentLine)
            $indentExp.each do |re|
               if(tline =~ re && !(tline =~ /\s+end\s*$/))
                  tab += 1
                  break
               end
            end
         end
      end
      if(tline =~ /^=end/)
         commentBlock = false
      end
   end
   if(source != dest)
      # make a backup copy
      File.open(path + "~","w") { |f| f.write(source) }
      # overwrite the original
      File.open(path,"w") { |f| f.write(dest) }
   end
   if(tab != 0)
      STDERR.puts "#{path}: Indentation error: #{tab}"
   end
end

if(!ARGV[0])
  ARGV[0] = STDIN
  STDERR.puts "usage: Ruby filenames to beautify."
  exit 0
end

ARGV.each do |path|
   beautifyRuby(path)
end
