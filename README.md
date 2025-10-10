Welcome to your new dbt project!

## Getting Started

To get started with this dbt project:

1. **Clone the repository** to your local machine.
2. **Install dbt** if you haven't already. Refer to the [dbt documentation](https://docs.getdbt.com/docs/installation) for installation instructions.
3. **Set up your profiles directory** (see below).
4. **Configure your connection** in your `profiles.yml` file.
5. **Run dbt commands** as needed (see the command reference table below).

## Setup

To specify a custom profiles directory for dbt, set the `DBT_PROFILES_DIR` environment variable.

**PowerShell:**
```powershell
$env:DBT_PROFILES_DIR = "C:\path\to\your\profiles"
```

**Bash (Linux/macOS):**
```bash
export DBT_PROFILES_DIR="/path/to/your/profiles"
```

To make these changes persistent, add the lines to your PowerShell profile script (e.g., `$PROFILE`) or your Bash profile (e.g., `~/.bashrc` or `~/.bash_profile`).

---

## dbt Command Reference

| Command | Explanation |
|---------|-------------|
| `dbt debug` | Test connections; checks profiles and `dbt_project.yml`. |
| `dbt deps` | Install dependencies/packages; run at the beginning of pipeline. pulls the most recent version of the dependencies listed in your packages.yml from git. dbt generates a package-lock.yml file in the root of your project. This file records the exact resolved versions (including commit SHAs) of all packages defined in your packages.yml. The package-lock.yml file ensures consistent and repeatable installs across all environments. When you run dbt deps, dbt installs packages based on the versions locked in the package-lock.yml. To maintain consistency, commit the package-lock.yml file to version control. This guarantees consistency across all environments and for all developers|
| `dbt deps --upgrade` | manually trigger an upgrade of installed packages. This may introduce build inconsistencies unless carefully managed |
| `dbt deps --add-package dbt-labs/dbt_utils@1.0.0` | add package directly with CLI |
| `dbt source freshness` | Check freshness of source models. |
| `dbt seed` | Load seed files to tables, by default, data will be loaded in a table with the same name as the CSV file |
| `dbt seed --full-refresh` | Reload all seed files, drop and recreate existing tables. |
| `dbt run` | Run all models. |
| `dbt run -select bronze` | Run all models in the `bronze` folder. |
| `dbt run --model my_second_dbt_model` | Run a specific model. |
| `dbt run -s +my_second_dbt_model` | Run models and their parent dependencies. |
| `dbt run -s "tag:my_tag"` | Run models with a specific tag. |
| `dbt run -s "state:modified"` | Run only modified models (`new`, `old`, `unmodified` also available). |
| `dbt run -s "result:error"` | Run models that errored in the last run. |
| `dbt run -s "source:raw+"` | Run models downstream of the `raw` source. |
| `dbt test` | Run all tests. |
| `dbt test -s model_name --store-failures` | Generate a table for every test in a schema. |
| `dbt test -s model_name` | Run tests for a specific model. |
| `dbt test -s "test_type:unit"` | Run only unit tests (`data`, `singular`, `generic` also available). |
| `dbt test -s source:*` | Run tests for all sources. |
| `dbt test -s source:abc_bank.*` | Run the tests on all the tables in the abc_bank source |
| `dbt snapshot` | Run all snapshots. |
| `dbt snapshot -s customer_snapshot` | Create a specified snapshot. |
| `dbt run-operation grant_select --args '{role: reporter}'` | Run a macro from the CLI. Used to invoke a macro defined within your dbt project or a dbt package |
| `dbt build -s "resource_type:models"` | Build only models. build = run + test|
| `dbt build -s STG_ABC_BANK_POSITION+` | Build the specified model and all downstream dependencies. |
| `dbt docs generate` | Generate documentation. Build catalog and writes to target\catalog.json|
| `dbt docs serve` | Host documentation locally. Explore the lineage graph in the docs UI. |

---

Selection examples:
- Upstream and downstream of model: `--select +model_name+`
- Exclude upstream+downstream: `--exclude +model_name+`

---

### Example: Returning a Value from a Macro to the CLI

You can use the `return` statement in your macro to output a value to the CLI. For example, create a macro in `macros/example_macro.sql`:

```sql
{% macro return_hello() %}
    {{ return('Hello from dbt macro!') }}
{% endmacro %}
```

Run the macro from the CLI:

```sh
dbt run-operation return_hello
```

This will print `Hello from dbt macro!` in your terminal.

---

## WAP in One Environment

- Run audit model
- Run test
- Run production model

---

## Test

- Data tests are run on objects already in your database. If they fail, you already have the bad data.
- Tests have the following specific configurations as properties in a YAML file for a generic test, but they can be applied to any tests with a config() block or, generally, in the main config file.
- Generic test config options: `where`, `severity: error|warn`, `error_if`, `warn_if`, `store_failures`, `limit`.
<test_name>:
    <argument_name>: <argument_value>
    config:
    where: <string> # limits the test to the rows that satisfy the where clause passed as a string
    severity: error | warn
    error_if: <string> # default is != 0
    warn_if: <string> # default is != 0
    fail_calc: <string> # configures the aggregation function applied to the test query to report the errors. The default is count(*),
    store_failures: true | false
    limit: <integer>

---

## Automation

- Pre and Post tasks

---

## General

- Staging tables reference sources. The `staging` folder contains the SQL and YAML for staging. Sources are defined in the YAML. If all source models are in the same YAML, that file can get bloated quickly. Decide between individual YAML files for each model vs. one YAML per sub-folder.
- Constraints are contracts. If constraints fail, models are not materialized.
- You may want to store or publish the results of the data source freshness check. Capture the result or extract it from the JSON files generated by the execution and publish it.
- The `source` function allows you to reference a table or view that has not been created by dbt. Source is just made of a metadata definition in a YAML file

