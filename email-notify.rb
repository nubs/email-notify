#!/usr/bin/ruby
require "rubygems"
require "mail"
require "net/smtp"

email = Mail.new($stdin.read)
addresses = (email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? "" : "TO: ") + "#{(email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? email.from : [email.to, email.cc, email.bcc]).flatten.compact.uniq}"

Net::SMTP.start('smtp.dominionenterprises.com') {|smtp| smtp.send_message "From: anubisnotify\nTo: 7576303572@vtext.com\nSubject: Email\n\n#{"#{email.subject}\n#{addresses}\n#{email.body.decoded}"}", "anubis@vt.edu", "7576303572@vtext.com" }
