#!/usr/bin/ruby
require 'tiny_tds'
require 'sqlite3'
require 'pry'

require_relative 'dbconfig.rb'

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
  
  if rec[:act] == row[1] and rec[:tran] == row[2]
    records.delete row[0] # no change in data, delete it from the changeset, no need to insert anything to the database
  else
    rec[:oldact] = row[1] # add the old data, and it'll carry over the new data cause it's already in the hash
    rec[:oldtran] = row[2]
  end
end

ts = Time.now.iso8601
stmt = db.prepare('INSERT INTO events (number,oldactivityid,newactivityid,oldtransponderid,newtransponderid,timestamp) values (:number,:oldact,:act,:oldtran,:tran,:ts)')
db.transaction do
  records.each do |number,data|
    data[:ts] = ts
    data[:number] = number
    stmt.execute data
  end
end
stmt.close
db.close

puts "#{records.count} changes recorded."
