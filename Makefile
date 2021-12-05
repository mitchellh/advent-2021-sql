.PHONY: psql
psql: # Open psql shell to DB
	psql postgresql://dev:dev@localhost:5432/dev

.PHONY: reset
reset: # Reset the DB (deletes all data and schema)
	docker compose down
	docker compose up -d
