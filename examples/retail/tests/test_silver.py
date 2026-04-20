"""Example of the pytest fixtures bundled with Dry Run.

Run with:  cd examples/retail && pytest -v

The ``dryrun_spark`` fixture gives you a fresh SparkShim pointed at a
temporary copy of the retail bundle — data files, jobs, notebooks and all
— so tests don't leak into your working ``.dryrun/catalog.duckdb``.
"""
from dryrun.pytest_plugin import assert_row_count, assert_columns


def test_ingest_sales_writes_bronze(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    # assert something exists and has rows
    n = dryrun_spark.sql(
        "SELECT COUNT(*) AS n FROM retail.bronze.sales"
    ).collect()[0]["n"]
    assert n > 0
    assert_columns(dryrun_spark, "retail.bronze.sales",
                   ["order_id", "customer_id", "qty",
                    "unit_price", "revenue", "order_ts"])


def test_silver_joins_customers(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    dryrun_executor.run_job("transform_job")
    df = dryrun_spark.sql(
        "SELECT COUNT(*) AS n, COUNT(DISTINCT country) AS countries "
        "FROM retail.silver.sales_enriched"
    ).collect()[0]
    assert df["n"] > 0
    assert df["countries"] >= 1


def test_gold_revenue_is_positive(dryrun_spark, dryrun_executor):
    dryrun_executor.run_job("ingest_job")
    dryrun_executor.run_job("transform_job")
    total = dryrun_spark.sql(
        "SELECT SUM(revenue) AS total FROM retail.gold.country_daily"
    ).collect()[0]["total"]
    assert total > 0
