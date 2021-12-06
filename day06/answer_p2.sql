-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day06 CASCADE;
CREATE SCHEMA day06;

-- Raw input
CREATE TABLE day06.inputs (
  line    TEXT NOT NULL
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day06.inputs (line) FROM 'day06/input.txt';

-- We had to modify part 1 to "slice" our inputs. I chose to slice by 64
-- since that it pretty fast. I couldn't figure out a way to do this in one
-- query performantly because you can't aggregate in a recursive CTE.
WITH RECURSIVE initial AS (
  SELECT timer::int
  FROM   day06.inputs,
         LATERAL unnest(regexp_split_to_array(line, ',')) as timer
), spawn1 AS (
  -- base case: our initial timers, and a countdown
  SELECT 256 as days_remaining,
         timer
  FROM   initial

  UNION ALL

  -- recursive case: decrement timer, spawn
  -- terminating case: timer is 0

  SELECT days_remaining - 1,
         newtimer
  FROM   spawn1,
         LATERAL unnest(CASE
           WHEN timer = 0 THEN ARRAY[6,8]
           ELSE ARRAY[timer-1]
         END) as newtimer
  WHERE  days_remaining > 192
), slice2 AS (
  SELECT days_remaining, timer, COUNT(*)
  FROM   spawn1
  GROUP BY days_remaining, timer
), spawn2 AS (
  SELECT * FROM slice2

  UNION ALL

  SELECT days_remaining - 1,
         newtimer,
         count
  FROM   spawn2,
         LATERAL unnest(CASE
           WHEN timer = 0 THEN ARRAY[6,8]
           ELSE ARRAY[timer-1]
         END) as newtimer
  WHERE  days_remaining > 128 AND days_remaining <= 192
), slice3 AS (
  SELECT days_remaining, timer, SUM(count) as count
  FROM   spawn2
  GROUP BY days_remaining, timer
), spawn3 AS (
  SELECT * FROM slice3

  UNION ALL

  SELECT days_remaining - 1,
         newtimer,
         count
  FROM   spawn3,
         LATERAL unnest(CASE
           WHEN timer = 0 THEN ARRAY[6,8]
           ELSE ARRAY[timer-1]
         END) as newtimer
  WHERE  days_remaining > 64 AND days_remaining <= 128
), slice4 AS (
  SELECT days_remaining, timer, SUM(count) as count
  FROM   spawn3
  GROUP BY days_remaining, timer
), spawn4 AS (
  SELECT * FROM slice4

  UNION ALL

  SELECT days_remaining - 1,
         newtimer,
         count
  FROM   spawn4,
         LATERAL unnest(CASE
           WHEN timer = 0 THEN ARRAY[6,8]
           ELSE ARRAY[timer-1]
         END) as newtimer
  WHERE  days_remaining > 0 AND days_remaining <= 64
)
SELECT   sum(count)
FROM     spawn4
WHERE    days_remaining = 0;
;
