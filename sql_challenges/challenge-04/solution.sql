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