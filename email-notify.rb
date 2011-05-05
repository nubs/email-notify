#!/usr/bin/ruby
require "mail"

email = Mail.new($stdin.read)
addresses = (email["received"] ? email.from : ['TO', email.to, email.cc, email.bcc]).flatten.compact.uniq

def converttotext(part)
  if part.content_type =~ /^text\/html/
    IO.popen("elinks -dump -dump-charset utf8 -default-mime-type text/html", "r+") {|io|
      io.puts part.body
      io.close_write
      return io.read
    }
  end

  part.body.decoded
end

def gettext(part)
  if part.multipart?
    multiparttexts = part.parts.select {|p| p.multipart? }.map {|p| gettext(p) }

    alltextparts = multiparttexts + part.parts

    plaintextparts = alltextparts.select {|p| p.content_type =~ /^text\/plain/ }
    return plaintextparts.first.body.decoded unless plaintextparts.empty?

    htmltextparts = alltextparts.select {|p| p.content_type =~ /^text\/html/ }
    return converttotext(htmltextparts.first) unless htmltextparts.empty?

    textparts = alltextparts.select {|p| p.content_type =~ /^text\// }
    return textparts.first.body.decoded unless textparts.empty?

    nonmultiparts = alltextparts.select {|p| !p.multipart? }
    return nonmultiparts.first.body.decoded unless nonmultiparts.empty?

    return alltextparts.first.body.decoded
  else
    return converttotext(part)
  end
end

puts "#{email.subject}\n#{addresses.join(",")}\n#{gettext(email)}"
