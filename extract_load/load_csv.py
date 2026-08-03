import dlt
import pandas as pd
from pathlib import Path
import os


#used for extracting data from source, in this case a local csv file
@dlt.resource(table_name="r2", write_disposition="replace")
def load_csv_resource(file_path: str, **kwargs):
    df = pd.read_csv(file_path, **kwargs)
    yield df


# if __name__ == "__main__":
#     #need to change to current working directory as this is where
#     # dlt looks for .dlt and when using the play button in vscode
#     # it will run from where you are in the terminal, not neccessarily
#     # where this script is resided
#     # working_directory = Path(__file__).parent

#     #if you are using files from .dlt, 
#     # the working directory should be the direct parent of .dlt folder
#     # os.chdir(working_directory)
#     # csv_path = working_directory / "data" / "r2_records.csv"
#     # data = load_csv_resource(csv_path, encoding="latin1")
#     # pipeline = dlt.pipeline(
#     #     pipeline_name='dependency_r2', 
#     #     destination="snowflake",
#     #     dataset_name='sch_dlt_test' #schema
#     #     )
#     #load_info = pipeline.run(data, table_name="r2")
#     # pretty print the information on data that was loaded
#     #print(load_info)


working_directory = Path(__file__).parent
os.chdir(working_directory)
csv_path = working_directory / "data" / "r2_records.csv"

@dlt.source
def r2_source():
    return load_csv_resource(csv_path, encoding="latin1")