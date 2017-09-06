# ORMery

ORMery is an object-relational mapping tool built using Ruby, with an SQLite3 database.

To try it out, simply load `songs.rb` into your favorite Ruby REPL (we recommend `pry` but `irb` works just fine).

## Setup

To use your own SQL file, add it to `db_connection.rb` by changing the `SQL_FILE` function like so:

```ruby
SQL_FILE = File.join(ROOT_FOLDER, 'YOUR_FILE.sql')
DB_FILE = File.join(ROOT_FOLDER, 'YOUR_DB.db')
```

In the terminal, run the following command to create the database:

`cat YOUR_FILE.sql | sqlite3 YOUR_DB.db`

Your SQL database is now ready to go!

## Creating and Using Classes

To create your own classes, create a `.rb` file, and add `require_relative 'lib/sql_object'`.

Each class needs to inherit from `SQLObject`. After writing any associations, you must also include the `finalize!` method for any changes to take effect.

Look at `song.rb` for reference!

## Basic Methods

```ruby
Song.all #Returns all songs

Album.find(1) #Finds the album where id = 1
Album.columns #Returns an array of all the columns in the table

Artist.table_name #Returns the name of its SQL table
Artist.table_name = #Change the name of SQL table

```

Class instances can be created, modified, and saved easily:

```ruby
charlie_parker = Artist.new(name: "Charlie Parker") #.new takes in an optional params hash
charlie_parker.save

bud_powell = Artist.new
bud_powell.name = "Bud Powell"
bud_powell.save

```

## Search

To search by a specific column value, use the `.where` method, passing in a hash with the column as a key and the query as the value:

```ruby
Artist.where(name: "John Coltrane") #Returns either an artist object or an empty array if nothing is found
```

## Associations

Write your associations in the class definition, before calling `finalize!`:

```ruby
class Song < SQLObject
  belongs_to :album #First association
  has_one_through :artist, :album, :artist #Second association
  finalize!
end
```

ORMery currently supports three different associations:

* `belongs_to` - Use when a class has a `foreign_id` column pointing to another class's `primary_id` column. Takes a required name, and an optional hash for `class_name`, `primary_key`, `foreign_key`.

* `has_many` - The opposite of `belongs_to`. Use when another class has a column pointing to its own `primary_id`. Takes a required name, and an optional hash for `class_name`, `primary_key`, `foreign_key`.

* `has_one_through` - Connects two `belongs_to` associations. Requires three arguments: `name`, `through_name`, and `source_name`.

In our demo file, Songs belong to Albums, Albums belong to Artists, and Songs have one Artist through Albums.

We can then call these associations as methods:

```ruby
Song.album
Song.artist

Album.songs

Artist.albums
```

## Future Implementations

Here are some features I intend to incorporate in future releases:

* `.first` and `.last` methods
* `.join`
* `has_many_through` and `belongs_to_through` associations
