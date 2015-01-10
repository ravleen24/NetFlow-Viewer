#
# NetFlow stream receiver, originally written by Ben Brock.
#
# TODO
# Store input in SQL database
# Add encryption
#

require 'socket'
require 'csv'
require 'getoptlong'

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end

opts = GetoptLong.new(
  ['--help', '-h', GetoptLong::NO_ARGUMENT],
  ['--port', '-p', GetoptLong::OPTIONAL_ARGUMENT]
)

port = 4215
host = nil

opts.each do |opt, arg|
  case opt
    when '--help'
      puts <<-EOF
Usage: receive [options] <host>

-h, --help:
    show help

-p <port>
    specify port number; default 4215

host:
    streaming host
      EOF
      exit 0
    when '--port'
      if arg != ''
        port = arg
      end
  end
end

if ARGV.length != 1
  puts "No host specified. Try -h."
  exit 0
end

host = ARGV.shift

client = TCPSocket.new host, port

schema = nil

while raw_entry = client.gets
  entry = raw_entry.parse_csv

  if !entry[0].numeric?
    schema = entry
  else
    # Insert entry into SQL database here
    schema.zip(entry).each do |label, datum|
      printf("%s: %s\n", label, datum)
    end
  end
end

client.close
