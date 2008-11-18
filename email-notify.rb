#!/usr/bin/ruby
require "rubygems"
require "tmail"
require "drb"

module TMail
	class Mail
		# Changed to work with blank file_names for attachments
		def attachments
			if multipart?
				parts.collect { |part| 
					if part.multipart?
						part.attachments
					elsif attachment?(part)
						content   = part.body # unquoted automatically by TMail#body
						file_name = (part['content-location'] && part['content-location'].body) || part.sub_header("content-type", "name") || part.sub_header("content-disposition", "filename")

						attachment = Attachment.new(content)
						attachment.original_filename = file_name.strip if file_name
						attachment.content_type = part.content_type
						attachment
					end
				}.flatten.compact
			end      
		end

		#For multipart/alternative messages, we only want the first one, not all of them
		alias :_body :body
		def body(to_charset = 'utf-8')
			if multipart?
				case sub_type('').downcase
				when "alternative" : parts[0].body(to_charset)
				when "digest" : parts.collect {|p| TMail::Mail.parse(p.body(to_charset)).body }.join("#{"-"*78}\n")
				else
					a=-1;
					parts.collect {|p| (p.multipart? ? p.body(to_charset) : (attachment?(p) ? "<b>Attachment: #{p["content-type"]["name"] || attachments[a+=1].original_filename || "(unnamed)"}</b>\n" : p.body(to_charset)))}.join
				end
			elsif sub_type == "html"
				IO.popen("/home/anubis/projects/email-notify/html2text.py", "r+") {|p| p.write(unquoted_body(to_charset)); p.close_write; p.gets(nil) }
			elsif sub_type == "calendar"
				/^DESCRIPTION:(.*)/.match(unquoted_body(to_charset).gsub(/\n\s/m, ''))[1].gsub(/\\n/, "\n").gsub(/\\(.)/, '\1')
			else
				unquoted_body(to_charset)
			end
		end
	end
end
email = TMail::Mail.parse($stdin.read)

DRb.start_service
bot = DRbObject.new(nil, 'druby://10.67.34.23:7666')
bot.send_msg("nubs", "<c: 13>email</c> :: <b>#{(email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? "" : "TO: ")}#{(email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? email.from_addrs : [email.to_addrs, email.cc_addrs, email.bcc_addrs]).flatten.compact.uniq.collect {|a| a.name ? a.name.gsub(/^[ '"]+|[ '"]+$/,'') : a.spec }}</b> :: <c: 09>#{email.subject}</c>\n#{email.body.squeeze("\n").split("\n").collect {|l| " "*9 + l.strip }.join("\n")}")
