# Advent of Code 2021 with PostgreSQL

This repository contains my solutions for [Advent of Code 2021](https://adventofcode.com/2021)
using PostgreSQL-specific SQL.

I'm not an expert at SQL (or PostgreSQL) by any means. One of the reasons I
decided to use SQL was to regain some proficiency while also learning some
new concepts. I expect that many of my solutions are suboptimal and there
are likely much _better_ ways (by various definitions) to reach the same
answer. I'd love to hear about those (make an issue) but I won't be merging
any changes since this represents _my_ approach.

**I may not finish!** December is a busy time, I'm doing these as I can,
but I'm not making any commitment to finishing. If I don't finish, I'll
hopefully retroactively solve the problems, but no promises. 😜

## Goals

I had a set of goals with each problem:

* Ingest input directly without any modification.

* Arrive at the solution using a single SQL statement. No `UPDATE` queries
  to transform the data prior to the statement. Huge CTEs to simulate temporary
  tables is totally fine.

* No custom functions (no plpgsql).

* Timebox to 30 minutes per problem for both parts.

If I was creeping up towards my timebox, I broke some of these rules in
the interest of getting to an answer. However, I did my best to stick with
the rules as well as possible. For example, in week 1, I achieved all of the
above except I had to drop into plpgsql for 1 part of 1 problem (on day 3).

## Explanations

I uploaded video explanations for each day I completed to YouTube:

https://www.youtube.com/watch?v=aIVBYKk5adk&list=PL4z1WbdlT5GJqdGnuvoqw4dOdB2etJ6sd

## Usage

Bring up the PostgreSQL database with `docker compose up -d`.

Drop into a PostgreSQL console with `make`.

Run the day: `\i day01/answer.sql;`

