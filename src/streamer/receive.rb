#
# NetFlow stream receiver, originally written by Ben Brock.
#
# TODO
# Store some things as integers, doubles instead of strings.
# Add encryption
#

require 'socket'
require 'csv'
require 'getoptlong'
require 'sequel'

class String
  def numeric?
    return true if self =~ /^\d+$/
    true if Float(self) rescue false
  end
end

def new_schema(db, schema)
  db.create_table?(:netflow) do
    primary_key :id
  end

  schema.map! {|column| column.intern}
  current_schema = db.schema(:netflow).map{|row| row[0]}

  schema.each do |column|
    if !current_schema.include? column
      db.alter_table(:netflow) do
        add_column column, String
      end
    end
  end
end

def insert_entry(db, schema, entry)
  if schema == nil
    puts "Attempting to insert entry with NULL schema."
    puts "You are wrong."
    exit 0
  end

  schema.map! {|column| column.intern}

  new_entry = Hash[schema.zip(entry)]
  db[:netflow].insert(new_entry)

  puts new_entry
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

db = Sequel.mysql('db_netflow', :user => 'root', :password => 'VhbRgEALLqVP ', :host => 'localhost')

while raw_entry = client.gets
  entry = raw_entry.parse_csv

  if !entry[0].numeric?
    schema = entry
    new_schema(db, schema)
  else
    insert_entry(db, schema, entry)
  end
end

client.close
