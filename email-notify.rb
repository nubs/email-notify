#!/usr/bin/ruby
require "mail"

email = Mail.new($stdin.read)
addresses = (email["received"] ? email.from : ['TO', email.to, email.cc, email.bcc]).flatten.compact.uniq

def gettextpart(part)
  if part.multipart?
    multiparttexts = part.parts.select {|p| p.multipart? }.map {|p| gettextpart(p) }

    alltextparts = multiparttexts + part.parts

    plaintextparts = alltextparts.select {|p| p.content_type =~ /^text\/plain/ }
    return plaintextparts.first unless plaintextparts.empty?

    htmltextparts = alltextparts.select {|p| p.content_type =~ /^text\/html/ }
    return IO.popen("elinks -dump -dump-charset utf8 -default-mime-type text/html", "r+") {|io|
      io.puts htmltextparts.first.body
      io.close_write
      htmltextparts.first.body = io.read
      htmltextparts.first
    } unless htmltextparts.empty?

    textparts = alltextparts.select {|p| p.content_type =~ /^text\// }
    return textparts.first unless textparts.empty?

    nonmultiparts = alltextparts.select {|p| !p.multipart? }
    return nonmultiparts.first unless nonmultiparts.empty?

    return alltextparts.first
  else
    return part
  end
end

puts "#{email.subject}\n#{addresses.join(",")}\n#{gettextpart(email).body.decoded}"
