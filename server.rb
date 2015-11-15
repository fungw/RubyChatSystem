class SERVER
	require 'thread'
	require 'socket'

	# Setup for server
	address = '0.0.0.0'
	port = ARGV[0] 
	server = TCPServer.open(address, port)
	puts "Server is running on #{address} on port #{port}." 
	student_id = "f3ddcabdebd2d7cfa6c080da06b2b657f36d2ef65406b6b19f3970161e1f5b09"
	active_users = Array.new
	chatrooms = Hash.new

	# Thread pool queue
	thread_pool = Queue.new
	(0..50).to_a.each{|x| thread_pool.push x }
	# Maximum of four threads
	pool = (0...4).map do
		Thread.new do
			begin
				while x = thread_pool.pop(true)
					Thread.start(socket = server.accept) do |client|
						request = client.gets
						STDERR.puts "=====BEGIN====="
						STDERR.puts request
						# GET /echo.php?message=#{user_input} HTTP/1.0\r\n\r\n"
						message = request.split('=')[1].strip
						header = message.split(' ')[0].strip
					 	puts case header
							when "100"
								username = message.split(' ')[1].strip
								chatroom_name = message.split(' ')[2].strip
								response = "USER_REG_OK"
								active_users.push(username)
								chatrooms[username] = chatroom_name	
							when "101"
								username = message.split(' ')[1].strip
								response = "USER_DIS_OK"
								active_users.delete(username)
							when "200"
								msg = message.split(' ')[1].strip
								response = "MSG_OK"
							else
								response = "ERROR UNDEFINED REQUEST"
						end
						STDERR.puts "=====END====="
						client.puts response
						client.close
					end
				end
				rescue ThreadError
				end
			end
	end; "ok"
	# Put thread back into pool
	pool.map(&:join); "ok"
end
