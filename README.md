# DataTalksClub DE Module 04 (Local)

Data Engineering Zoomcamp - Module 4: Analytics Engineering with containerized dbt and DuckDB.

This project builds a complete analytics pipeline for NYC taxi trip data (green and yellow cabs) using a dimensional modeling approach. Raw trip records are transformed through staging, intermediate, and marts layers into business-ready fact and dimension tables.

## Architecture

```text
Raw Data (Parquet)
  |
  v
DuckDB ──► Staging (Views) ──► Intermediate (Tables) ──► Marts (Tables) ──► Reporting (Tables)
               |                      |                       |
        Type casting,          Union green/yellow,     Fact & dimension
        filtering nulls        deduplication,          tables with zone
                               payment enrichment      and vendor context
```

### Data Flow

```text
green_tripdata ──► stg_green_tripdata ──┐
                                        ├──► int_trips_unioned ──► int_trips ──► fct_trips ──► fct_monthly_zone_revenue
yellow_tripdata ──► stg_yellow_tripdata ┘         |                   |              |
                                                  |                   |              ├── dim_zones (pickup/dropoff)
                                      service_type added    payment_type_lookup      └── dim_vendors
```

### Tech Stack

| Tool   | Purpose                         |
|--------|---------------------------------|
| dbt    | Data transformation and testing |
| DuckDB | Embedded OLAP database engine   |
| Docker | Containerized execution         |
| Python | Data ingestion scripts          |

## Project Structure

```text
.
├── docker-compose.yml
├── Dockerfile
├── profiles.yml
├── requirements.txt
├── data/
│   ├── green/                          # Green taxi parquet files
│   ├── yellow/                         # Yellow taxi parquet files
│   └── taxi_rides_ny.duckdb            # DuckDB database
├── notebooks/
│   └── download_and_ingest.py          # Data ingestion script
└── taxi_rides_ny/                      # dbt project
    ├── dbt_project.yml
    ├── packages.yml
    ├── macros/
    │   ├── get_trip_duration_minutes.sql
    │   ├── get_vendor_data.sql
    │   └── safe_cast.sql
    ├── models/
    │   ├── staging/                     # Views - type casting and filtering
    │   │   ├── stg_green_tripdata.sql
    │   │   └── stg_yellow_tripdata.sql
    │   ├── intermediate/               # Tables - union, dedup, enrichment
    │   │   ├── int_trips_unioned.sql
    │   │   └── int_trips.sql
    │   └── marts/                      # Tables - dimensional model
    │       ├── dim_zones.sql
    │       ├── dim_vendors.sql
    │       ├── fct_trips.sql           # Incremental
    │       └── reporting/
    │           └── fct_monthly_zone_revenue.sql
    └── seeds/
        ├── taxi_zone_lookup.csv        # 265 NYC taxi zones
        └── payment_type_lookup.csv     # Payment type descriptions
```

## Models

### Staging

| Model                | Materialization | Description                                                  |
|----------------------|-----------------|--------------------------------------------------------------|
| `stg_green_tripdata` | View            | Standardizes green taxi columns, casts types, filters nulls  |
| `stg_yellow_tripdata`| View            | Standardizes yellow taxi columns, casts types, filters nulls |

### Intermediate

| Model               | Materialization | Description                                                          |
|---------------------|-----------------|----------------------------------------------------------------------|
| `int_trips_unioned` | Table           | Unions green and yellow trips with a `service_type` column           |
| `int_trips`         | Table           | Generates surrogate keys, deduplicates, joins payment descriptions   |

### Marts

| Model                      | Materialization | Description                                                      |
|----------------------------|-----------------|------------------------------------------------------------------|
| `dim_zones`                | Table           | NYC taxi zone dimension (borough, zone, service zone)            |
| `dim_vendors`              | Table           | Vendor dimension (Creative Mobile Technologies, VeriFone Inc.)   |
| `fct_trips`                | Incremental     | Core fact table with trip details, zone context, and duration    |
| `fct_monthly_zone_revenue` | Table           | Aggregated monthly revenue by pickup zone and service type       |

### Macros

| Macro                       | Description                                                          |
|-----------------------------|----------------------------------------------------------------------|
| `get_trip_duration_minutes` | Calculates trip duration in minutes using `dbt.datediff`             |
| `get_vendor_data`           | Maps vendor IDs to company names via a Jinja CASE statement          |
| `safe_cast`                 | Cross-database safe type casting (BigQuery `safe_cast` vs `cast`)    |

## Setup

### Prerequisites

- Docker and Docker Compose

### Build and Start the Container

```bash
docker compose up -d --build
```

### Seed the Data

1. Load reference tables:

```bash
docker compose exec dbt-duckdb dbt seed
```

1. Ingest trip data by running the ingestion script from the `notebooks/` folder:

```bash
python notebooks/download_and_ingest.py
```

### Run dbt Commands

Commands can be executed from outside the container:

```bash
docker compose exec dbt-duckdb dbt debug   # Verify connection
docker compose exec dbt-duckdb dbt deps    # Install dependencies
docker compose exec dbt-duckdb dbt seed    # Load seed data
docker compose exec dbt-duckdb dbt run     # Run models
docker compose exec dbt-duckdb dbt test    # Run tests
docker compose exec dbt-duckdb dbt build   # Run + test combined
```

Alternatively, use the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) VS Code extension:

1. `Shift+Command+P` > **Attach to Running Container**
1. Open the `taxi_rides_ny` folder
1. Run dbt commands directly from the integrated terminal

### Build for Production

```bash
docker compose exec dbt-duckdb dbt build --target prod
```

### Environments

| Target | Memory | Data Scope                      |
|--------|--------|---------------------------------|
| `dev`  | 4 GB   | Sampled (Jan 1 - Feb 1, 2019)   |
| `prod` | 12 GB  | Full dataset                    |

## Dependencies

| Package            | Version          |
|--------------------|------------------|
| dbt-labs/dbt_utils | >=1.3.0, <2.0.0  |
| dbt-labs/codegen   | >=0.14.0, <1.0.0 |
