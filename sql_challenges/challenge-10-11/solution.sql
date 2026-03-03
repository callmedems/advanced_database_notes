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