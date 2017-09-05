require_relative 'lib/sql_object'

DBConnection.reset

class Artist < SQLObject
  has_many :albums
  finalize!
end

class Album < SQLObject
  belongs_to :artist
  has_many :songs
  finalize!
end

class Song < SQLObject
  belongs_to :album
  has_one_through :artist, :album, :artist
  finalize!
end
