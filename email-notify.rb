#!/usr/bin/ruby
require "rubygems"
require "mail"
require "net/smtp"

email = Mail.new($stdin.read)
addresses = (email["received"] ? email.from : ['TO', email.to, email.cc, email.bcc]).flatten.compact.uniq.map {|e| e.gsub(/@dominionenterprises\.com/, '@DE') }.join(",")

def gettextpart(part)
  if part.multipart?
    multiparttexts = part.parts.select {|p| p.multipart? }.map {|p| gettextpart(p) }

    alltextparts = multiparttexts + part.parts

    plaintextparts = alltextparts.select {|p| p.content_type == 'text/plain' }
    return plaintextparts.first unless plaintextparts.empty?

    textparts = alltextparts.select {|p| p.content_type =~ /^text\// }
    return textparts.first unless textparts.empty?

    nonmultiparts = alltextparts.select {|p| !p.multipart? }
    return nonmultiparts.first unless nonmultiparts.empty?

    return alltextparts.first
  else
    return part
  end
end

Net::SMTP.start('smtp.dominionenterprises.com') {|smtp| smtp.send_message "#{email.subject}\n#{addresses}\n#{gettextpart(email).body.decoded}", "anubis@vt.edu", "7576303572@vtext.com" }
