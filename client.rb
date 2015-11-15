class CLIENT
	#Ruby client for echo.php server.
	#Tested and working on localhost.
	#Wesley Fung
	require 'socket'

	hostname = '0.0.0.0'
	port = 8080
	status_codes = Array[100, 200, 300, 400]

	logged_in = false;
	while logged_in == false do 
		puts "What's your nickname?"
		CLIENT_NAME = gets.chomp
		puts "Chatroom name? Enter for randomly generated chatroom name."
		user_chat_name = gets.chomp
		if user_chat_name.empty?
			JOIN_CHATROOM = Random.new_seed
		elsif
			JOIN_CHATROOM = user_chat_name
		end
		
		request = "GET /echo.php?message=#{status_codes.at(0)} #{JOIN_CHATROOM} 0 0 #{CLIENT_NAME} HTTP/1.0\r\n\r\n"
		socket = TCPSocket.open(hostname, port)
		socket.print(request)
		response = socket.read
		if response<=>"USER_REG_OK" then
			print "Welcome #{CLIENT_NAME}, you are now logged in!\n"
			logged_in = true;
		end
	end

	loop do 
		puts "MSG:"
		user_input = gets.chomp
		request = "GET /echo.php?message=#{status_codes.at(1)} #{user_input} HTTP/1.0\r\n\r\n"
		socket = TCPSocket.open(hostname, port)
		socket.print(request)
		response = socket.read
		if response<=>"MSG_OK" then
			print "SENT"
		end
	end
end
