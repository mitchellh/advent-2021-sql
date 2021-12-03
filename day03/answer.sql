-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.inputs (
  id        SERIAL,
  value     TEXT NOT NULL
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day03.inputs (value) FROM 'day03/input.txt';

-- characters: split string into one row for each character
-- common: use mode() aggregate to find most common value for each index
-- result: combine most common values, convert to binary, convert to int
--   to find epsilon, I pad with 1 and then bit flip to get the least common.
WITH characters AS (
  SELECT  id,
          char,
          index
  FROM    day03.inputs,
          LATERAL unnest(regexp_split_to_array(value, ''))
             WITH ORDINALITY
             AS   t(char, index)
), common AS (
  SELECT   c.index, mode() WITHIN GROUP (ORDER BY c.char) as char
  FROM     characters c
  GROUP BY c.index
), result AS (
  SELECT string_agg(char, '') as string,
         lpad(string_agg(char, ''), 32, '0')::bit(32)::int as gamma,
         (~ lpad(string_agg(char, ''), 32, '1')::bit(32))::int as epsilon
  FROM   common
)
SELECT gamma, epsilon, gamma * epsilon as answer
FROM   result;
