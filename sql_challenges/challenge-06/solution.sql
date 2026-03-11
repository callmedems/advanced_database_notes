-- try it 5

--query 1
select colour from my_brick_collection
UNION
select colour from your_brick_collection
order by colour;
--query 2
select shape from my_brick_collection
UNION ALL
select shape from your_brick_collection
order by shape;

--try it 10
--query 1
select shape from my_brick_collection
MINUS
select shape from your_brick_collection;

--query 2
select colour from my_brick_collection
INTERSECT
select colour from your_brick_collection
order by colour;