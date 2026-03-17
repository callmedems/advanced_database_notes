-- LESSON 10
--      Find the longest time that an employee has been at the studio
SELECT MAX(Years_employed) FROM employees;

--      For each role, find the average number of years employed by employees in that role
SELECT AVG(Years_employed) AS avg_year, Role
FROM employees
GROUP BY Role;

--      Find the total number of employee years worked in each building
SELECT SUM(Years_employed) AS total_year, Building
FROM employees
GROUP BY Building;

-- LESSON 11
--      Find the number of Artists in the studio (without a HAVING clause) 
SELECT COUNT(Role) FROM employees
WHERE Role = "Artist";

--      Find the number of Employees of each role in the studio
SELECT Role, COUNT(Role) FROM employees
GROUP BY Role;

--      Find the total number of years employed by all Engineers
SELECT Role, SUM(Years_employed) FROM employees
WHERE Role = "Engineer";

-- TRY ITS from tutorial
-- FIRST (punto 4)
--  Complete the following query to return the: Number of different shapes & 
--The standard deviation (stddev) of the unique weights

select count (distinct shape),  stddev(distinct weight) from bricks;

-- SECOND (punto 6)
--  Complete the following query to return the total weight for each shape stored in the bricks table
select shape, SUM(weight) from bricks
group by shape;

-- THIRD (punto 8)
-- Complete the following query to find the shapes which have a total weight less than four
select shape, sum(weight)
from BRICKS
group by shape
having sum(weight) < 4;
