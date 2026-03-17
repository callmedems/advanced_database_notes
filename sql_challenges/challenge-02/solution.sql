-- LESSON 6
-- Find the domestic and international sales for each movie
SELECT Title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id; -- importante la indentation

-- Show the sales numbers for each movie that did better internationally rather than domestically
SELECT title, domestic_sales, international_sales 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
    WHERE international_sales > domestic_sales;


-- List all the movies by their ratings in descending order
SELECT title, domestic_sales, international_sales, rating 
FROM movies
  JOIN boxoffice
    ON movies.id = boxoffice.movie_id
    ORDER BY rating DESC;


-- LESSON 7
--Find the list of all buildings that have employees
SELECT DISTINCT building FROM employees

--Find the list of all buildings and their capacity
SELECT * FROM buildings

--List all buildings and the distinct employee roles in each building (including empty buildings)
SELECT DISTINCT building_name, role FROM buildings
    LEFT JOIN employees 
        ON building_name = building;


-- LESSON INTERVIEW 
SELECT pages.page_id, page_name FROM pages
LEFT JOIN page_likes ON pages.page_id = page_likes.page_id
WHERE page_likes.page_id IS NULL
ORDER BY pages.page_id ASC;
