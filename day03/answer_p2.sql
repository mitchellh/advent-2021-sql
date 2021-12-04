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

-- Break down our characters
DROP TABLE IF EXISTS characters;
CREATE TEMPORARY TABLE characters AS (
  SELECT  id,
          char,
          index
  FROM    day03.inputs,
          LATERAL unnest(regexp_split_to_array(value, ''))
             WITH ORDINALITY
             AS   t(char, index)
);

-- decode decodes the input characters by looking for most common or
-- least common next bits. acc is the current accumulation. Call this
-- with an empty acc to start it'll return the result.
CREATE OR REPLACE FUNCTION day03.decode(acc TEXT, most_common BOOL)
RETURNS TEXT
AS $$
DECLARE
  ids    INTEGER[];
  common TEXT;
BEGIN
  -- Find all inputs that start with our acc, these are the only ones
  -- we care about.
  ids := ARRAY(
    SELECT id
    FROM   day03.inputs
    WHERE  char_length(value) >= char_length(acc)+1 AND
           value LIKE acc || '%'
  );

  -- If we didn't find anything then we're done.
  IF coalesce(array_length(ids, 1), 0) = 0 THEN
    RETURN acc;
  END IF;

  -- If we have exactly one result, we're also done
  IF array_length(ids, 1) = 1 THEN
    RETURN (SELECT value FROM day03.inputs WHERE id = ids[1]);
  END IF;

  -- Find the most common character in our current index
  SELECT   mode() WITHIN GROUP (ORDER BY c.char DESC)
  FROM     characters c
  WHERE    c.index = (char_length(acc) + 1) AND
           c.id = ANY(ids)
  INTO STRICT common;

  -- If we're looking for least common, flip the mode
  IF NOT most_common THEN
    IF common = '1' THEN
      common := '0';
    ELSE
      common := '1';
    END IF;
  END IF;

  RETURN (SELECT day03.decode(acc || common, most_common));
END;
$$ LANGUAGE plpgsql;

-- compute all the results
\echo 'PART 2 RESULTS';
WITH strings AS (
  SELECT day03.decode('', true) as oxygen,
         day03.decode('', false) as co2
), decimals AS (
  SELECT lpad(oxygen, 32, '0')::bit(32)::int as oxygen_dec,
         lpad(co2, 32, '0')::bit(32)::int as co2_dec
  FROM   strings
)
SELECT *, oxygen_dec * co2_dec as answer
FROM   strings, decimals;
