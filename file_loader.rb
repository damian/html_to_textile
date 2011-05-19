require 'htmltotextile'

f = File.open('test.html').read
cl = HTML2Textile.new(f)

File.open("test.textile", "w+") do |f|
  f.puts cl.to_textile
end
