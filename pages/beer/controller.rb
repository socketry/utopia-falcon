
prepend Actions

def bottles(n)
	n == 1 ? "#{n} bottle" : "#{n} bottles"
end

# Browsers don't show streaming content until a certain threshold has been met. For most browers, it's about 1024 bytes. So, we have a comment of about that length which we feed to the client before streaming actual content. For more details see https://stackoverflow.com/questions/16909227
COMMENT = "<!--#{'-' * 1024}-->"

# To test this example with the curl command-line tool, you'll need to add the `--no-buffer` flag or set the COMMENT size to the required 4096 bytes in order for curl to start streaming. 
# curl http://localhost:9292/ --no-buffer

on 'index' do |request|
	task = Async::Task.current
	body = Async::HTTP::Body::Writable.new
	
	count = (request.params['count'] || 99).to_i
	
	body.write("<!DOCTYPE html><html><head><title>#{count} Bottles of Beer</title></head><body>")
	
	task.async do |task|
		body.write(COMMENT)
		
		count.downto(1) do |i|
			puts "#{bottles(i)} of beer on the wall..."
			body.write("<p>#{bottles(i)} of beer on the wall, ")
			task.sleep(0.1)
			body.write("#{bottles(i)} of beer, ")
			task.sleep(0.1)
			body.write("take one down and pass it around, ")
			task.sleep(0.1)
			body.write("#{bottles(i-1)} of beer on the wall.</p>")
			task.sleep(0.1)
			body.write("<script>var child; while (child = document.body.firstChild) child.remove();</script>")
		end
		
		body.write("</body></html>")
	rescue
		puts "Remote end closed connection: #{$!}"
	ensure
		body.close
	end
	
	succeed! status: 200,
		headers: {'content-type' => 'text/html; charset=utf-8'},
		body: body
end
