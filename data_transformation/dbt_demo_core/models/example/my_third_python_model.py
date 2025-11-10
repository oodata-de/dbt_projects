import snowflake.snowpark.types as T
import snowflake.snowpark.functions as F
import numpy

def register_udf_add_random():
    add_random = F.udf(
        # use 'lambda' syntax, for simple functional behavior
        lambda x: x + numpy.random.normal(),
        return_type=T.FloatType(),
        input_types=[T.FloatType()]
    )
    return add_random

def model(dbt, session):

    dbt.config(
        materialized = "table",
        packages = ["numpy"]
    )
    temps_df = dbt.ref("my_first_dbt_model")
    temps_df = temps_df.withColumn("float_id", F.col("id") + 0.1)

    add_random = register_udf_add_random()

    # warm things up, who knows by how much
    df = temps_df.withColumn("id_plus_random", add_random("float_id"))
    return df