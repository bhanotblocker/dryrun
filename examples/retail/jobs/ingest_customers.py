"""Bronze ingest: customers CSV → delta table."""

df = spark.read.option("header", True).csv("s3://retail-raw/customers.csv")
df = df.withColumn("signup_date", F.to_date("signup_date"))
df.write.mode("overwrite").saveAsTable("retail.bronze.customers")
print(f"wrote {df.count()} customers")
