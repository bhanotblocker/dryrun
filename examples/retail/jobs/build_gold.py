"""Gold: country-level daily revenue."""

silver = spark.table("retail.silver.sales_enriched")

gold = (
    silver.groupBy("country", "order_date")
          .agg(
              F.sum("revenue").alias("revenue"),
              F.sum("qty").alias("units"),
              F.countDistinct("customer_id").alias("customers"),
          )
          .orderBy("order_date", "country")
)

gold.write.mode("overwrite").saveAsTable("retail.gold.country_daily")
gold.show(20)
