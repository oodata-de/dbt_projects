# dbt Python models don't use Jinja to render compiled code.
# You don't have to explicitly import the Snowflake Snowpark Python library, dbt will do that for you
# what materializations are supported??


def model(dbt, session):
    # Must be either table or incremental (view is not currently supported)
    dbt.config(materialized = "table")

    # DataFrame representing an upstream model
    df = dbt.ref("my_first_dbt_model")
    return df

# This is what snowflake runs
# CREATE  OR  REPLACE  TRANSIENT  TABLE  dbt_dev.sch_dbt_test.my_first_python_model("ID" BIGINT)    AS  SELECT  * 
#  FROM (
#  SELECT  *  FROM dbt_dev.sch_dbt_test.my_first_dbt_model
# )

# it cerates all the templating
# WITH my_first_python_model__dbt_sp AS PROCEDURE ()
# RETURNS STRING
# LANGUAGE PYTHON
# RUNTIME_VERSION = '3.9'
# PACKAGES = ('snowflake-snowpark-python')
# HANDLER = 'main'
# EXECUTE AS CALLER
# AS
# $$

# import sys
# sys._xoptions['snowflake_partner_attribution'].append("dbtLabs_dbtPython")


# # dbt Python models don't use Jinja to render compiled code.
# # You don't have to explicitly import the Snowflake Snowpark Python library, dbt will do that for you
# # what materializations are supported??


# def model(dbt, session):
#     # Must be either table or incremental (view is not currently supported)
#     dbt.config(materialized = "table")

#     # DataFrame representing an upstream model
#     df = dbt.ref("my_first_dbt_model")
#     return df


# # This part is user provided model code
# # you will need to copy the next section to run the code
# # COMMAND ----------
# # this part is dbt logic for get ref work, do not modify

# def ref(*args, **kwargs):
#     refs = {"my_first_dbt_model": "dbt_dev.sch_dbt_test.my_first_dbt_model"}
#     key = '.'.join(args)
#     version = kwargs.get("v") or kwargs.get("version")
#     if version:
#         key += f".v{version}"
#     dbt_load_df_function = kwargs.get("dbt_load_df_function")
#     return dbt_load_df_function(refs[key])


# def source(*args, dbt_load_df_function):
#     sources = {}
#     key = '.'.join(args)
#     return dbt_load_df_function(sources[key])


# config_dict = {}


# class config:
#     def __init__(self, *args, **kwargs):
#         pass

#     @staticmethod
#     def get(key, default=None):
#         return config_dict.get(key, default)

# class this:
#     """dbt.this() or dbt.this.identifier"""
#     database = "dbt_dev"
#     schema = "sch_dbt_test"
#     identifier = "my_first_python_model"
    
#     def __repr__(self):
#         return 'dbt_dev.sch_dbt_test.my_first_python_model'


# class dbtObj:
#     def __init__(self, load_df_function) -> None:
#         self.source = lambda *args: source(*args, dbt_load_df_function=load_df_function)
#         self.ref = lambda *args, **kwargs: ref(*args, **kwargs, dbt_load_df_function=load_df_function)
#         self.config = config
#         self.this = this()
#         self.is_incremental = False

# # COMMAND ----------





# def materialize(session, df, target_relation):
#     # make sure pandas exists
#     import importlib.util
#     package_name = 'pandas'
#     if importlib.util.find_spec(package_name):
#         import pandas
#         if isinstance(df, pandas.core.frame.DataFrame):
#             session.use_database(target_relation.database)
#             session.use_schema(target_relation.schema)
#             # session.write_pandas does not have overwrite function
#             df = session.createDataFrame(df)
    
#     df.write.mode("overwrite").save_as_table('dbt_dev.sch_dbt_test.my_first_python_model', table_type='transient')


# def main(session):
#     dbt = dbtObj(session.table)
#     df = model(dbt, session)
#     materialize(session, df, dbt.this)
#     return "OK"


  
# $$
# CALL my_first_python_model__dbt_sp()
# /* {"app": "dbt", "dbt_version": "1.10.11", "profile_name": "dbt_demo_core", "target_name": "dev", "node_id": "model.dbt_demo_core.my_first_python_model"} */;