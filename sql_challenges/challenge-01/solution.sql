-- FIRST TASK SOLUTION
SELECT Title FROM movies;

-- SECOND TASK SOLUTION
SELECT Director FROM movies;

-- THIRD TASK SOLUTION
SELECT Title, Director FROM movies;

-- FOURTH TASK SOLUTION
SELECT Title, Year FROM movies;

-- FIFTH TASK SOLUTION
SELECT * FROM movies;

-- first task: Find the movie with a row id of 6
SELECT Id, Title FROM movies
WHERE Id = 6;

-- second task: Find the movies released in the years between 2000 and 2010
SELECT * FROM movies
WHERE Year >= 2000
    AND Year <= 2010;

-- third task: Find the movies not released in the years between 2000 and 2010
SELECT * FROM movies
WHERE Year NOT BETWEEN 2000 AND 2010;

-- fourth task: Find the first 5 Pixar movies and their release year
SELECT * FROM movies
WHERE year <= 2003;

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

-- first task: List all directors of Pixar movies (alphabetically), without duplicates 
SELECT DISTINCT Director FROM movies
ORDER BY Director ASC;

--List the last four Pixar movies released (ordered from most recent to least)
SELECT * FROM movies
WHERE YEAR >= 2010
ORDER BY Year DESC;

--List the first five Pixar movies sorted alphabetically
SELECT * FROM movies
ORDER BY Title ASC
LIMIT 5;

--List the next five Pixar movies sorted alphabetically
SELECT * FROM movies
ORDER BY Title ASC
LIMIT 5 OFFSET 5;

-- List all the Canadian cities and their populations
SELECT City, Country, Population FROM north_american_cities
WHERE Country = "Canada";

--Order all the cities in the United States by their latitude from north to south
SELECT * FROM north_american_cities
WHERE country = "United States"
ORDER BY latitude DESC;

--List all the cities west of Chicago, ordered from west to east
SELECT * FROM north_american_cities
WHERE longitude < -87.629798
ORDER BY longitude ASC;

--List the two largest cities in Mexico (by population)
SELECT * FROM north_american_cities
WHERE country = "Mexico"
ORDER BY population DESC
LIMIT 2;

-- List the third and fourth largest cities (by population) in the United States and their population
SELECT * FROM north_american_cities
WHERE country = "United States"
ORDER BY population DESC
LIMIT 2 OFFSET 2;