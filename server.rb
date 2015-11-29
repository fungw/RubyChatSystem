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
					    while true do
    						request = client.gets
    						STDERR.puts "=====BEGIN====="
    						STDERR.puts "REQUEST RECEIVED: " + request
    						# GET /echo.php?message=#{user_input} HTTP/1.0\r\n\r\n"
    						header = request.split(' ')[0].strip
    				# 		STDERR.puts header
    						puts case header 
    						    when "HELO"
    						        STDERR.puts 'HELO message received'
    						        response = "#{request}IP:54.208.167.157\nPort:#{443}\nStudentID:#{student_id}"
    						    when /JOIN_CHATROOM/
    						        SERVER_IP = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
    						        SERVER_PORT = "443"
    						        ROOM_REF = Random.new_seed.to_s
    						        JOIN_ID = Random.new_seed.to_s
    						        STDERR.puts 'JOINED_CHATROOM message received'
    						        room_id = request.split('JOIN_CHATROOM:')[1].strip
    						        response = "JOINED_CHATROOM:" + room_id + "\nSERVER_IP:" + SERVER_IP + "\nPORT:" + SERVER_PORT + "\nROOM_REF:" + ROOM_REF + "\nJOIN_ID:" + JOIN_ID
    						    when /CLIENT_IP/
    						        request = client.gets
    						        STDERR.puts "REQUEST RECEIVED: " + request
    						        request = client.gets
    						        STDERR.puts "REQUEST RECEIVED: " + request
    						        CLIENT_NAME = request.split('CLIENT_NAME:')[1].strip
    						        response = "CHAT:" + ROOM_REF + "\nCLIENT_NAME:" + CLIENT_NAME + "\nMESSAGE:" + CLIENT_NAME + " has joined this chatroom."
    						    when /LEAVE_CHATROOM/
    						        response = "LEFT_CHATROOM:" + ROOM_REF + "\nJOIN_ID:" + JOIN_ID
    						    when /KILL_SERVICE/
    						        exit
    						    else
    						        response = "ERROR UNDEFINED REQUEST"
    						end
    						STDERR.puts "=====END====="
    					 	STDERR.puts 
						    client.puts response
						end
					end
				end
				rescue ThreadError
				end
			end
	end; "ok"
	# Put thread back into pool
	pool.map(&:join); "ok"
end
