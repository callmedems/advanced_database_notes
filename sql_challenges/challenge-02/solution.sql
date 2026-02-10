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