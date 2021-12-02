-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day01 CASCADE;
CREATE SCHEMA day01;

CREATE TABLE day01.inputs (
  id    SERIAL,
  value INTEGER NOT NULL,

  -- We expect this to be true for all inputs
  CHECK (value > 0)
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day01.inputs (value) FROM 'day01/input.txt' WITH (FORMAT 'text');

-- We use a CTE to store temporary data. A subquery would also work since
-- we don't reference the CTE multiple times, but I find CTEs to be clearer.
--
-- The lagdata table uses window functions to peek into the previous value
-- (using `lag` by ID). We then just count the results that an increasing value.
WITH lagdata AS (
  SELECT   value,
           lag(value) over (ORDER BY id) as prev
  FROM     day01.inputs
  ORDER BY id
  OFFSET   1
)
SELECT COUNT(*)
FROM   lagdata
WHERE  value > prev;
