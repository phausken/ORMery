CREATE TABLE songs (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  album_id INTEGER NOT NULL,

  FOREIGN KEY(album_id) REFERENCES album(id)
);

CREATE TABLE albums (
  id INTEGER PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  artist_id INTEGER NOT NULL,

  FOREIGN KEY(artist_id) REFERENCES artist(id)
);

CREATE TABLE artists (
  id INTEGER PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

INSERT INTO
  artists (id, name)
VALUES
  (1, "Miles Davis"), (2, "John Coltrane"), (3, "Charles Mingus");

INSERT INTO
  albums (id, title, artist_id)
VALUES
  (1, "Kind of Blue", 1),
  (2, "Miles Smiles", 1),
  (3, "Blue Trane", 2),
  (4, "Giant Steps", 2),
  (5, "Mingus Ah Um", 3),
  (6, "Blues and Roots", 3);

INSERT INTO
  songs (id, title, album_id)
VALUES
  (1, "So What", 1),
  (2, "Blue in Green", 1),
  (3, "Footprints", 2),
  (4, "Orbit", 2),
  (5, "Moments Notice", 3),
  (6, "Lady Bird", 3),
  (7, "Mr. P.C.", 4),
  (8, "Countdoown", 4),
  (9, "Goodbye Pork Pie Hat", 5)
  (10, "Better Git It In Your Soul", 5)
  (11, "Wednesday Night Prayer Meeting", 6)
  (12, "My Jelly Roll Soul", 6)
