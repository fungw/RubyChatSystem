require 'thread'
require 'socket'
require 'benchmark'
require 'timeout'

class Pool
    def initialize(size)
        @size = size
        @jobs = Queue.new

        @pool = Array.new(@size) do |i|
            Thread.new do
                Thread.current[:id] = i

                catch(:exit) do
                    loop do
                        job, args = @jobs.pop
                        job.call(*args)
                    end
                end
            end
        end
    end

    def schedule(*args, &block)
        @jobs << [block, args]
    end

    def shutdown
        @size.times do
            schedule { throw:exit }
        end

        @pool.map(&:join)
        end
    end

    if $0 == __FILE__
end

class DATABASE
    def initialize() 
        $users = { }
        $chatroom = { }
        $last_chatroom = { }
    end
   
   def setUser ( join_id, client_name )
        STDERR.puts "Inserting user #{client_name} with ID of #{join_id}"
        $users[join_id] = client_name
   end
   
   def getUser ( join_id )
        user_return = $users[join_id.to_s] 
   end
   
   def setUserRoom ( join_id, room_ref )
        STDERR.puts "Inserting user #{join_id} in room #{room_ref}"
        $chatroom[join_id] = room_ref
   end
   
   def getUserRoom ( join_id )
        room = $chatroom[join_id]
   end
   
   def setLastChatroom ( join_id, room_ref )
        STDERR.puts "Inserting last chatroom to the user #{join_id} into #{room_ref}"
        $last_chatroom[join_id] = room_ref
   end
   
   def getLastChatroom ( join_id )
        last_room = $last_chatroom[join_id]
   end
   
   def removeUserChatroom ( join_id, room_ref )
       STDERR.puts "#{join_id} deleting from #{room_ref}"
       $chatroom.delete( join_id )
       STDERR.puts "#{join_id} deleted from #{room_ref}"
   end
   
end

class SERVER
    $database = DATABASE.new
    
    def serverStart(port = '443') 
        address = '0.0.0.0'
        
        server = TCPServer.open(address, port)
        puts "Server is running on #{address} on port #{port}.\n" 
        
        serverRun server
    end
    
    def serverRun ( server )
        p = Pool.new(20)
        25.times do |i|
            p.schedule do |client|
                STDERR.puts "Waiting for client..."
                client = server.accept
                    loop do 
                        STDERR.puts "Client connected"
                        status = Timeout::timeout(60000) {
                            server_request = client.gets
                        }
                        STDERR.puts "Retrieving request"
                        server_response = parseRequest status, client
                        client.puts server_response
                        if server_response.include? "JOINED_CHATROOM"
                            server_chat_request = client_ip client, server_response
                            client.puts server_chat_request
                            STDERR.puts "\nRESPONSE SENT:\n"
                            STDERR.puts "=====BEGIN====="
                            STDERR.puts server_chat_request
                            STDERR.puts "======END======\n"
                        end
                        if server_response.include? "LEFT_CHATROOM"
                            user_receipt = get_left_chatroom server_response
                            client.puts user_receipt
                            STDERR.puts "\nRESPONSE SENT:\n"
                            STDERR.puts "=====BEGIN====="
                            STDERR.puts user_receipt
                            STDERR.puts "======END======\n"
                        end
                    end
            end #do  
            at_exit { p.shutdown }
        end
    end
    
    def parseRequest ( client_request, client )
        # STDERR.puts "#{Thread.current[:id]}"
        STDERR.puts "\nREQUEST RECEIVED:\n"
        STDERR.puts "=====BEGIN====="
        STDERR.puts client_request
        STDERR.puts "======END======\n"
        if client_request.include? "KILL_SERVICE"
            STDERR.puts "Kill the server, DIE!"
            exit!
        end
        header = client_request.split(' ')[0].strip
        puts case header 
            when /HELO/
                respond = helo client_request
            when /JOIN_CHATROOM/
                respond = join_chatroom client_request
            when /LEAVE_CHATROOM/
                respond = leave_chatroom client_request, client
            when /KILL_SERVICE/
                exit
            else
                respond = "ERROR UNDEFINED REQUEST"
        end
        STDERR.puts "\nRESPONSE SENT:\n"
        STDERR.puts "=====BEGIN====="
        STDERR.puts respond
        STDERR.puts "======END======\n"
        respond
    end
    
    def helo ( respond )
        student_id = "f3ddcabdebd2d7cfa6c080da06b2b657f36d2ef65406b6b19f3970161e1f5b09"
        respond_helo =  "#{respond}IP:54.84.121.47\nPort:#{443}\nStudentID:#{student_id}"
    end
    
    def join_chatroom ( respond )
        server_ip = Socket::getaddrinfo(Socket.gethostname,"echo",Socket::AF_INET)[0][3]
        server_port = "443"
        room_ref = Random.new_seed.to_s
        join_id = Random.new_seed.to_s
        $database.setUserRoom( join_id, room_ref )
        room_id = respond.split('JOIN_CHATROOM:')[1].strip
        respond_join = "JOINED_CHATROOM:#{room_id}\nSERVER_IP:#{server_ip}\nPORT:#{server_port}\nROOM_REF:#{room_ref}\nJOIN_ID:#{join_id}\n"
    end  
    
    def client_ip ( client, join_chatroom_user ) 
        client_ip = client.gets
        client_port = client.gets
        client_name_request = client.gets
        client_name = client_name_request.split('CLIENT_NAME:')[1].strip
        join_chatroom_id = join_chatroom_user.split('JOIN_ID:')[1].strip
        $database.setUser( join_chatroom_id, client_name )
        client_room_ref = $database.getUserRoom( join_chatroom_id )
        chat_response = "CHAT:#{client_room_ref}\nCLIENT_NAME:#{client_name}\nMESSAGE:#{client_name} has joined this chatroom.\n\n"
    end
    
    def leave_chatroom ( respond, client )
        client_join_id_request = client.gets
        client_name_request = client.gets
        leave_room_ref = respond.split('LEAVE_CHATROOM:')[1].strip
        leave_name = client_name_request.split('CLIENT_NAME:')[1].strip
        leave_join_id = client_join_id_request.split('JOIN_ID:')[1].strip
        client_room_ref = $database.getUserRoom( leave_join_id )
        $database.removeUserChatroom( leave_join_id, leave_room_ref )
        $database.setLastChatroom( leave_join_id, leave_room_ref )
        respond = "LEFT_CHATROOM:#{leave_room_ref}\nJOIN_ID:#{leave_join_id}\n"
    end
    
    def get_left_chatroom ( respond )
        left_join = respond.split('JOIN_ID:')[1].strip
        left_name = $database.getUser( left_join )
        left_room = $database.getLastChatroom( left_join )
        respond = "CHAT:#{left_room}\nCLIENT_NAME:#{left_name}\nMESSAGE:#{left_name}\n\n" 
    end

    serverClass = SERVER.new
    serverClass.serverStart ARGV[0]
end