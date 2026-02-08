# Build and start the container
docker compose up -d --build

# Run dbt commands inside the container
docker compose exec dbt-duckdb dbt debug        # verify connection
docker compose exec dbt-duckdb dbt deps         # build dependencies
docker compose exec dbt-duckdb dbt seed          # load seed data
docker compose exec dbt-duckdb dbt run           # run models
docker compose exec dbt-duckdb dbt test          # run tests


