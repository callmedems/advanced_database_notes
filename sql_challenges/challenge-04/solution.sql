-- 3 try it
select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median ( weight ) over (
         partition by shape
       ) median_weight_per_shape
from   bricks b
order  by shape, weight, brick_id;

-- 5 try it
select b.brick_id, b.weight,
       round ( avg ( weight ) over (
         order by brick_id
       ), 2 ) running_average_weight
from   bricks b
order  by brick_id;

-- 9 try it 
select b.*,
       min ( colour ) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count (*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from   bricks b
order by weight;

-- datalemur problem
WITH salary_ranks AS (
  SELECT 
    d.department_name,
    e.name,
    e.salary,
    DENSE_RANK() OVER (
      PARTITION BY d.department_name 
      ORDER BY e.salary DESC
    ) as ranking
  FROM employee e
  JOIN department d 
    ON e.department_id = d.department_id
)
SELECT 
  department_name,
  name,
  salary
FROM salary_ranks
WHERE ranking <= 3
ORDER BY department_name ASC, salary DESC, name ASC;