-- ============================================================
-- Exercise 1 — Find the slow query
-- ============================================================
SELECT * FROM patient_visits WHERE site_id = 3;

/*
Answers:
a) Scan type: TABLE ACCESS FULL. 
   Why? There is currently no index on the site_id column.
b) Cardinality: Low cardinality (only 5 distinct values across the table).
c) Would an index help? No. Because the query returns ~20% of the table,
   the optimizer knows reading the whole table into memory at once (sequential I/O)
   is actually faster than bouncing between an index and the table data (random I/O).
*/

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
-- ============================================================
-- Step 1: Create it
CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query
SELECT * FROM patient_visits 
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

/*
Answers:
a) Does Oracle use the index for this range? Yes, via an INDEX RANGE SCAN.
b) Last 7 days: Yes, it still uses INDEX RANGE SCAN, and executes even faster 
   because it is more selective.
c) Last 700 days: The plan flips back to a TABLE ACCESS FULL.
d) Why range size matters: It comes down to cost. Fetching ~95% of the table 
   via an index is double the work (read index + fetch row). A full table scan 
   is cheaper for large ranges.
*/

-- ============================================================
-- Exercise 3 — Composite index
-- ============================================================
CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

/*
Answers:
a) Does the plan use the composite index? Yes, it perfectly matches the criteria.
b) Querying ONLY on visit_date: No, it generally won't use it. The index is sorted 
   primarily by patient_id. Trying to search it only by date is like trying to find 
   someone by their first name in a phone book sorted by last name.
c) Rule about column order: The "Left-to-Right Prefix Rule". You must put the most 
   frequently queried and most selective (highest cardinality) columns first.
*/

-- ============================================================
-- Exercise 4 — Function that breaks an index
-- ============================================================
-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;

-- This one cannot:
-- SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

/*
Answers:
a) Scan type for the second query: TABLE ACCESS FULL.
b) Why it breaks: The standard index stores native numbers. Applying TO_CHAR() 
   dynamically transforms the data at runtime, so the database can't use its 
   pre-sorted number index.
c) Rewrite to allow index use: Simply drop the function to match native data types:
   SELECT * FROM patient_visits WHERE patient_id = 5432;
*/

-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
-- ============================================================
/*
Answers:
Scenario A (Reporting table, batch ETL, queried by date):
-> Yes, add an index on the date column. Batch loading at night means the index 
   update overhead won't interrupt daytime users, giving analysts massive read 
   performance boosts during the day.

Scenario B (OLTP table, heavy inserts, queried by customer or status):
-> Index customer_id (high cardinality).
-> DO NOT index order_status (low cardinality). The high insert volume (10k/min)
   means every extra index creates massive write overhead. Only index what is crucial.

Scenario C (Patient table, unique email):
-> Create a UNIQUE INDEX on the email column. This provides incredibly fast lookups 
   while simultaneously enforcing a database-level constraint that prevents duplicate 
   email registrations.
*/

-- ============================================================
-- Cleanup
-- ============================================================
DROP INDEX idx_pv_patient_date;
DROP INDEX idx_pv_visit_date;