-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day05 CASCADE;
CREATE SCHEMA day05;

-- Both input_* tables are /raw/ input tables. These are formatted
-- so we can do a raw, unprocessed copy directly from the input files.
CREATE TABLE day05.inputs (
  id      SERIAL,
  points1 TEXT NOT NULL,
  arrow   TEXT NOT NULL,
  points2 TEXT NOT NULL
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day05.inputs (points1, arrow, points2) FROM 'day05/input.txt' WITH (DELIMITER ' ');

WITH points AS (
  -- raw input to real points
  SELECT id,
         ST_MakePoint(p1[1]::int, p1[2]::int) as point1,
         ST_MakePoint(p2[1]::int, p2[2]::int) as point2
  FROM   day05.inputs,
         LATERAL regexp_split_to_array(points1, ',') as p1,
         LATERAL regexp_split_to_array(points2, ',') as p2
), lines AS (
  -- all our lines from points
  SELECT id, ST_MakeLine(point1, point2) as line
  FROM   points
), all_points AS (
  SELECT l.id, geom
  FROM   lines l,
         LATERAL ST_DumpPoints(ST_Segmentize(l.line, 1)) as t(path, geom),
         points p
  WHERE  p.id = l.id AND (
           ST_X(p.point1) = ST_X(p.point2) OR
           ST_Y(p.point1) = ST_Y(p.point2)
         )
), overlapping_points AS (
  SELECT   p1.geom, COUNT(*)
  FROM     all_points p1
  JOIN     all_points p2 ON p1.id <> p2.id AND p1.geom = p2.geom
  GROUP BY p1.geom
)
SELECT COUNT(*) FROM overlapping_points;
