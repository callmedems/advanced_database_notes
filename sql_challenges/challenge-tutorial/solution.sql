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