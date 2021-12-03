-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day02 CASCADE;
CREATE SCHEMA day02;

-- use an enum to validate the inputs
CREATE TYPE day02.direction AS ENUM (
  'forward', 'down', 'up'
);

CREATE TABLE day02.inputs (
  id        SERIAL,
  direction day02.direction NOT NULL,
  value     INTEGER NOT NULL,

  -- We expect this to be true for all inputs
  CHECK (value > 0)
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day02.inputs (direction, value) FROM 'day02/input.txt' WITH (DELIMITER ' ');

-- movement: calculate our sums of each movement direction individually
-- position: use movement to calculate final position
-- final: show the position and the answer by multiplying the results
\echo 'PART 1 RESULTS';
WITH movement AS (
  SELECT sum(value) FILTER (WHERE direction = 'forward') as forward,
         sum(value) FILTER (WHERE direction = 'down') as down,
         sum(value) FILTER (WHERE direction = 'up') as up
  FROM   day02.inputs
), position AS (
  SELECT forward as x, (down - up) as y
  FROM   movement
)
SELECT x, y, x * y as answer
FROM   position;

-- movement: accumulate rolling sum of down/up alongside inputs
-- aim: calculate aim at each point along with depth change (aim * x)
-- position: sum our forward movement, sum our depths
-- final: show results, multiply for desired input
\echo 'PART 2 RESULTS';
WITH movement AS (
  SELECT *,
         COALESCE(SUM(value)
           FILTER (WHERE direction = 'down')
           OVER   (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0)
           AS     down_acc,
         COALESCE(SUM(value)
           FILTER (WHERE direction = 'up')
           OVER   (ORDER BY id ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0)
           AS     up_acc
  FROM day02.inputs
  ORDER BY id
),
aim AS (
  SELECT id, direction, value,
         (down_acc - up_acc) as aim,
         (down_acc - up_acc) * value as depth_delta
  FROM   movement
  WHERE  direction = 'forward'
),
position AS (
  SELECT sum(value) as x, sum(depth_delta) as y
  FROM   aim
)
SELECT x, y, x * y as answer
FROM   position;
