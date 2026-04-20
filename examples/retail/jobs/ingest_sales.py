"""Bronze ingest: raw sales CSV → delta table."""

df = (
    spark.read
    .option("header", True)
    .csv("s3://retail-raw/sales.csv")
)

df = (
    df.withColumn("qty", F.col("qty").cast("int"))
      .withColumn("unit_price", F.col("unit_price").cast("double"))
      .withColumn("revenue", F.col("qty") * F.col("unit_price"))
      .withColumn("order_ts", F.to_timestamp("order_ts"))
)

df.write.mode("overwrite").saveAsTable("retail.bronze.sales")
print(f"wrote {df.count()} rows to retail.bronze.sales")
