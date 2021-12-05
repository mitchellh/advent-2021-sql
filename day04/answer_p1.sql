-- Put everything in a schema so its easy to reset. This also makes
-- this automatically reset so we can just run it many times.
DROP SCHEMA IF EXISTS day04 CASCADE;
CREATE SCHEMA day04;

-- Both input_* tables are /raw/ input tables. These are formatted
-- so we can do a raw, unprocessed copy directly from the input files.
CREATE TABLE day04.input_numbers (
  line TEXT NOT NULL
);

CREATE TABLE day04.input_boards (
  id   SERIAL,
  line TEXT NOT NULL
);

-- Use \COPY rather than COPY so its client-side in psql
\COPY day04.input_numbers FROM 'day04/input_numbers.txt' WITH (DELIMITER 'X');
\COPY day04.input_boards (line) FROM 'day04/input_boards.txt' WITH (DELIMITER 'X');

--\COPY day04.input_numbers FROM 'day04/sample_numbers.txt' WITH (DELIMITER 'X');
--\COPY day04.input_boards (line) FROM 'day04/sample_boards.txt' WITH (DELIMITER 'X');

WITH numbers AS (
  -- convert our line of draws into a list of number and order
  SELECT index, number::int
  FROM   day04.input_numbers,
         LATERAL unnest(regexp_split_to_array(line, ','))
           WITH ORDINALITY
           AS   t(number, index)
), boards_split AS (
  -- use the newline to split each board into a dedicated ID
  -- also calculate the row using the same mechanism
  SELECT *,
         (sum(CASE WHEN line = '' THEN 1 ELSE 0 END) OVER (ORDER BY id)) + 1 as board_id,
         (sum(CASE WHEN line <> '' THEN 1 ELSE -5 END) OVER (ORDER BY id)) as row
  FROM   day04.input_boards
), boards AS (
  -- take the split boards and now split columns to assign col numbers
  SELECT board_id,
         row,
         col,
         number::int
  FROM   boards_split,
         LATERAL unnest(regexp_split_to_array(trim(line), '\s+'))
           WITH ORDINALITY
           AS   t(number, col)
  WHERE  line <> ''
), boards_fk AS (
  -- replace all our numbers in our boards with their order
  SELECT b.board_id,
         b.row,
         b.col,
         n.index as pick_order
  FROM   boards b
  LEFT JOIN numbers n ON n.number = b.number
  ORDER BY board_id, row, col
), winning_row AS (
  -- all rows ordered by the one that won first
  SELECT   board_id,
           row,
           sum(pick_order),
           max(pick_order) as most_recent
  FROM     boards_fk
  GROUP BY board_id, row
  ORDER BY most_recent
), winning_col AS (
  -- all columns ordered by the one that won first
  SELECT   board_id,
           col,
           sum(pick_order),
           max(pick_order) as most_recent
  FROM     boards_fk
  GROUP BY board_id, col
  ORDER BY most_recent
), winning_row_unmarked AS (
  -- calculate the sum of the unmarked numbers left on the winning rows
  SELECT    w.board_id,
            w.row,
            w.most_recent as winning_pick,
            sum(n.number) as remainder_sum
  FROM      winning_row w
  LEFT JOIN boards_fk b ON  b.board_id = w.board_id
                        AND b.row <> w.row
                        AND b.pick_order > w.most_recent
  LEFT JOIN numbers n   ON n.index = b.pick_order
  GROUP BY  w.board_id, w.row, w.most_recent
  ORDER BY  w.most_recent
), winning_col_unmarked AS (
  -- calculate the sum of the unmarked numbers left on the winning col
  SELECT    w.board_id,
            w.col,
            w.most_recent as winning_pick,
            sum(n.number) as remainder_sum
  FROM      winning_col w
  LEFT JOIN boards_fk b ON  b.board_id = w.board_id
                        AND b.col <> w.col
                        AND b.pick_order > w.most_recent
  LEFT JOIN numbers n   ON n.index = b.pick_order
  GROUP BY  w.board_id, w.col, w.most_recent
  ORDER BY  w.most_recent
), possible_answers AS (
  -- get the possible col and row answer
  (SELECT w.board_id,
         'row: ' || w.row as desc,
         w.most_recent as winning_pick,
         n.number as most_recent,
         rem.remainder_sum,
         n.number * rem.remainder_sum as answer
  FROM   winning_row_unmarked rem
  JOIN   winning_row w ON w.board_id = rem.board_id
  JOIN   numbers n ON n.index = w.most_recent
  ORDER BY rem.winning_pick
  LIMIT  1)

  UNION

  (SELECT w.board_id,
         'col: ' || w.col as desc,
         w.most_recent as winning_pick,
         n.number as most_recent,
         rem.remainder_sum,
         n.number * rem.remainder_sum as answer
  FROM   winning_col_unmarked rem
  JOIN   winning_col w ON w.board_id = rem.board_id
  JOIN   numbers n ON n.index = w.most_recent
  ORDER BY rem.winning_pick
  LIMIT  1)
)
SELECT   *
FROM     possible_answers
ORDER BY winning_pick
LIMIT    1 ;
