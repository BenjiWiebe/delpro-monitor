#!/usr/bin/ruby
require 'tiny_tds'
require 'sqlite3'

require_relative 'config.rb'

def get_live_data
  client = TinyTds::Client.new(DBCONFIG)
  results = client.execute('SELECT b.Number, a.ActivityID, b.TransponderID FROM AnimalActivitySetting AS a JOIN BasicAnimal AS b ON a.Animal = b.OID where activityid > 0 or transponderid > 0 ORDER BY b.Number ASC')
  current = {}
  results.each do |rec|
    current[rec["Number"]] = {act: rec["ActivityID"], tran: rec["TransponderID"]}
  end
  return current
end

records = get_live_data

db = SQLite3::Database.new('data.db')

# Here we look at all the records in the database from the last run.
# For each cow number, we see if the current numbers are still the same as what's in the database.
# If it's the same, we delete it from the hash 'curr'.  Afterwards, 'curr' will contain only the changed records.
db.execute('SELECT number,activityid,transponderid from recent') do |row|
  rec = records[row[0]]

  # if it hasn't been in the DB previously, we need to start with an empty hash.
  if rec.nil?
    records[row[0]] = rec = {}
  end
  
  # N.B. TinyTDS getting data from MS SQL gets the activity and transponder IDs as numbers. SQLite can't store numbers that big except as strings,
  # hence the conversion to strings for comparison's sake.  Also, since one side or the other might be nil (which converts to "") we need to to_s both of them.
  if rec[:act].to_s == row[1].to_s and rec[:tran].to_s == row[2].to_s
    records.delete row[0] # no change in data, delete it from the changeset, no need to insert anything to the database
  else
    # add the old data (only the changed fields), and it'll carry over the new data cause it's already in the hash
    rec[:oldact] = row[1] if rec[:oldact] != row[1]
    rec[:oldtran] = row[2] if rec[:oldtran] != row[2]
  end
end

ts = Time.now.iso8601
evtstmt = db.prepare('INSERT INTO events (number,oldactivityid,newactivityid,oldtransponderid,newtransponderid,timestamp) values (:number,:oldact,:act,:oldtran,:tran,:ts)')
updstmt = db.prepare('REPLACE INTO recent (number,activityid,transponderid) values (:number,:act,:tran)')
db.transaction do
  records.each do |number,data|
    data[:ts] = ts
    data[:number] = number
    evtstmt.execute data

    # annoyingly, sqlite3 gem doesn't like it if we have unused params in the hash...
    data.delete :oldact
    data.delete :oldtran
    data.delete :ts
    updstmt.execute data
  end
end
updstmt.close
evtstmt.close
db.close

puts "#{records.count} changes recorded."
if records.count > 1
  require 'net/http'
  d = "Activity/transponder changed for #{records.each_key.to_a.join(',')}"
  u = URI(get_ntfy_url(URI.encode_uri_component(d))
  Net::HTTP.get(uri)
end
