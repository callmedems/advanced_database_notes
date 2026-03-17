-- first task: Find all Toy Story Movies
SELECT * FROM movies
WHERE Title LIKE "%Toy Story%";

-- second task: Find all the movies directed by John Lasseter
SELECT * FROM movies
WHERE Director = "John Lasseter";

-- third task: Find all the movies (and director) not directed by John Lasseter
SELECT * FROM movies
WHERE Director != "John Lasseter";

-- fourth task: Find all the WALL-* movies
SELECT * FROM movies
WHERE Title LIKE "WALL-_";