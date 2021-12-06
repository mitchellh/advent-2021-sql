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

WITH RECURSIVE initial AS (
  SELECT timer::int
  FROM   day06.inputs,
         LATERAL unnest(regexp_split_to_array(line, ',')) as timer
), spawn AS (
  -- base case: our initial timers, and a countdown
  SELECT 80 as days_remaining,
         timer
  FROM   initial

  UNION ALL

  -- recursive case: decrement timer, spawn
  -- terminating case: timer is 0

  SELECT days_remaining - 1,
         newtimer
  FROM   spawn,
         LATERAL unnest(CASE
           WHEN timer = 0 THEN ARRAY[6,8]
           ELSE ARRAY[timer-1]
         END) as newtimer
  WHERE  days_remaining > 0
)
SELECT   COUNT(*)
FROM     spawn
WHERE    days_remaining = 0;
;
