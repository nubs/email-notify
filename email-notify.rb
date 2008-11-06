#TODO:
# * MIME
#   * binary attachments (quoted-printable/base64)
#   * text attachments
#   * alternative/mixed
#   * inline/attachments
#   * message attachments (forwarding, digests)
#   * related attachments (images, etc)
#   * signatures/encrypted content
#   * form data
# * encoded headers - utf8, etc.
# * strip replies
# * to groups : rfc2822 3.4
# * comments in headers
# * multi-address from
# * Follow references/in-reply-to

def process_headers(lines)
	headers,prev = Hash.new([]), ["",""]
	headerlines, body = lines[0..lines.index("\n")-1], lines[lines.index("\n")+1, lines.length]
	headerlines.join.gsub(/\n\s+/, " ").split("\n").each {|h|
		md = /([^:]*):(.*)/.match(h)
		header,value = md[1].strip.downcase, [md[2].strip]

		value = value[0].split(/\s*[,;]\s*/).inject([]) {|addresses, a| puts a; ((md = /^[^<]+/.match(a)) || (md = /[^<@]+@[^>]+/.match(a)) ? addresses << md[0].gsub(/^[ '"]+|[ '"]+$/, '') : addresses) } if ["from", "to", "cc"].include?(header)

		headers[header] = headers[header] | value
	}

	[headers, body]
end

headers, body = process_headers(readlines)

headers.each {|k,v| puts "#{k} : #{v.inspect}" }
#p body
