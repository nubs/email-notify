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
				IO.popen("links --dump --dump-width 160", "r+") {|p| p.write(unquoted_body(to_charset)); p.close_write; p.gets(nil) }
			elsif sub_type == "calendar"
				/^DESCRIPTION:(.*)/.match(unquoted_body(to_charset).gsub(/\n\s/m, ''))[1].gsub(/\\n/, "\n").gsub(/\\(.)/, '\1')
			else
				unquoted_body(to_charset)
			end
		end

		def clean_body(to_charset = 'utf-8')
			body.sub(/\n\s*-+original\s+message.*/im, '').sub(/\n\s*_+\s*\n\s*from:.*/im, '').sub(/^[^\n]+wrote:?\n\s*>/im, '>').gsub(/^\s*>.*/, '').sub(/^\s*(regards|(thanks? (you)?|sincerely))\s*[,!].*/im, '')
		end
	end
end
email = TMail::Mail.parse($stdin.read)

rbot = DRbObject.new_with_uri('druby://overthemonkey.com:7268')
authid = rbot.delegate(nil, "remote login scm !scm1")[:return]
rbot.delegate(authid, "dispatch say nubs \00313email\017 :: \002#{(email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? "" : "TO: ")}#{(email["received"] || email.from != "spencer.rinehart@dominionenterprises.com" ? email.from_addrs : [email.to_addrs, email.cc_addrs, email.bcc_addrs]).flatten.compact.uniq.collect {|a| a.name ? a.name.gsub(/^[ '"]+|[ '"]+$/,'') : a.spec }}\017 :: \00309#{email.subject}\017\n#{email.clean_body.squeeze("\n").split("\n").collect {|l| " "*9 + l.strip }.join("\n")}")
