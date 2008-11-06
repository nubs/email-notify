require "rubygems"
require "tmail"
require "drb"

email = TMail::Mail.parse($stdin.read)
#puts email.parts[1].body

DRb.start_service
bot = DRbObject.new(nil, 'druby://10.67.34.23:7666')
bot.send_msg("nubs", "<c: 13>email</c> :: <b>#{(email["received"] ? email.from_addrs : [email.to_addrs, email.cc_addrs, email.bcc_addrs]).flatten.compact.uniq.collect {|a| a.name ? a.name.gsub(/^[ '"]+|[ '"]+$/,'') : a.spec }}</b> :: <c: 09>#{email.subject}</c>")
