from snowflake.snowpark.functions import udf

def model(dbt, session):
    # Must be either table or incremental (view is not currently supported)
    dbt.config(materialized = "table")

    # User defined function
    # If you try and define and register the function outside of the main() handler function you will get an error. 
    # TO move it outside, you must only define it there and then register it inside. 
    @udf
    def add_one(x: int) -> int:
        x = 0 if not x else x
        return x + 1

    # DataFrame representing an upstream model
    df = dbt.ref("my_first_dbt_model")

    # Add a new column containing the id incremented by one
    df = df.withColumn("id_plus_one", add_one(df["id"]))

    return df