#!/usr/bin/env ruby

# http://gist.github.com/267149 (mathias meyer)

require 'socket'
host = ARGV[0] || 'localhost'
port = ARGV[1] || '6379'

trap(:INT) {
  exit
}

puts "Connecting to #{host}:#{port}"
begin
  sock = TCPSocket.new(host, port)
  sock.setsockopt Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1

  sock.write("monitor\r\n")

  while line = sock.gets
    puts line
  end
rescue Errno::ECONNREFUSED
  puts "Connection refused"
end
