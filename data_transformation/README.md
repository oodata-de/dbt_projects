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
| `dbt source freshness --select source:dependency` | Check freshness of source models. Behind the scenes, dbt uses the freshness properties to construct a select query|
| `dbt compile --inline "select * from {{ ref('raw_orders') }}"` | Display the compiled code of arbitrary dbt-SQL query in CLI |
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
| `dbt build -s state:modified+` | Build all modeified models and everythign downstream. More relevant for CI/ testing during development. Avoid rebuilding entore dbt projects. In CI, dbt clone forst before run eg  `dbt clone --select state:modified+, config.materialized:incremental,state:old` |
| `dbt build --select source_status:fresher+` |build and test models downstream of fresher sources. Run dbt source freshness first. Using these commands in order makes sure models update with the latest data. This eliminates wasted compute cycles on unchanged data and builds models only when necessary.|
| `dbt build -s STG_ABC_BANK_POSITION+` | Build the specified model and all downstream dependencies. |
| `dbt docs generate` | Generate documentation. Build catalog and writes to target\catalog.json|
| `dbt docs serve` | Host documentation locally. Explore the lineage graph in the docs UI. |
| `dbt parse` | parses and validates the contents of your dbt project, If your project contains Jinja or YAML syntax errors, the command will fail.  doesn’t require a connection to your data warehouse to generate a manifest file, as opposed to commands like dbt compile; fast and consistent across any environments you run it in |
| `dbt parse --no-partial-parse` | run parse on whole project from scrtach (not since last update). Generates perf_info.json in target dir|
| `dbt clone --select state:modified+,config.materialized:incremental,state:old ` | Clone all of the pre-existing incremental models that have been modified or are downstream of another model that has been modified |

---



### dbt selection syntax — quick reference
| Selector | Syntax | Example | Notes |
|---------:|:------:|:-------:|:-----|
| name | `--select <name>` | `--select my_model` | Select model/table by name |
| package | `package:<pkg>` | `--select package:dbt_utils` | Select resources from a package |
| resource_type | `resource_type:<type>` | `--select resource_type:models` | types: models, seeds, snapshots, tests, sources |
| path | `path:<dir>` | `--select path:staging/customers` | Files under directory |
| source | `source:<source>.<table>` | `--select source:raw+` | Run all models that select from raw sources |
| fqn | `fqn:<fully.qualified.name>` | `--select fqn:my_proj.pkg.my_model` | Fully qualified name |
| tag | `tag:<tag>` | `--select tag:monthly` | Select by tag. |
| group | `group:<group>` | `--select "group:finance"` | Select models defined within a group, can be set on config block - group='GROUP_NAME' |
| config | `config.<key>:<val>` | `--select config.materialized:incremental` | Select nodes with a config key/value eg select all incremental model |
| test_type | `test_type:<value>` | `--select test_type:singular` | Select tests by type (singular/generic/data) |
| result | `result:<value>` | `--select result:fail --state path/to/artifacts ` | select nodes based on last run results. Values: `error`, `success`, `skipped`, `fail`, `warn`, `pass`. [`run`, `test`, `build`, `seed`] must have been performed in order to create the result on which a result selector operates  |
| state | `state:<value>` | `--select state:modified` | Nodes whose state changed compared to a previous manifest. Common values: `new`, `modified`, `unchanged`, `old`. Use with `--state` & previous manifest |
| source_status | `source_status:<val>` | `--select source_status:fresher+ --state path/to/prod/artifacts` | select models downstream of fresher sources (use after running source freshness). After `dbt source freshness`. signal dbt to run and test only on the fresher sources and their children |
| named selector | `<name>` | `--selector team_a` | Reference named selector in selectors.yml entry |
| db/schema/namespace | `database:<db>` etc. | `--select database:analytics schema:raw` | When using non-default namespaces |


| Operators & combining | Syntax | Example | Notes |
|:---------------------:|:------:|:-------:|:-----|
| Upstream | `+node` | `--select +my_model` | immediate parents |
| Downstream | `node+` | `--select my_model+` | immediate children |
| Both / hop | `+node+` | `--select +my_model+` | node + one-hop parents & children |
| Repeat + | `++node++` | expand hops | more hops with more `+` |
| Intersection (AND) | separate selectors with a space | `--select tag:staging config.materialized:table` | nodes that have both the tag staging AND are materialized as table |
| Union (OR) | comma-separated | `--select tag:staging,tag:mart` | nodes with either tag |
| Exclude | `--exclude <selector>` | `--select tag:mart --exclude tag:deprecated` | subtract nodes safely |
| Trailing + on states | `state:modified+` | `--select state:modified+` | include downstream of state selector |

Examples
- `dbt run --select +tag:monthly+` — monthly models + upstream and downstream. If multiple models have same upstream, refresh is triggered once  
- `dbt build --select source:raw.orders+ --exclude tag:experimental` — downstream of raw.orders except experimental  
- `dbt test --select state:modified,tag:CI` — modified OR CI-tagged nodes
- `dbt run --select @my_team --exclude +@skip_list` — 
- `dbt run --select @ model` - @model means “the model and its entire family (all parents and children).”
- `dbt run --select "result:<status>+" state:modified+ --defer --state ./<dbt-artifact-path>` - tate and result selectors can also be combined in a single invocation of dbt to capture errors from a previous run OR any new or modified models.
- `dbt build --select "1+result:fail+" --state path/to/artifacts` reruns the models associated with failed tests and all downstream dependencies

Quick tips
- Prefer named selectors (selectors.yml) for complex reusable selection logic across CI and local runs.  
- Use `--exclude` for safe subtraction.  
- Use `source_status:` and `dbt source freshness` together to trigger runs only when sources have fresher data.
- Use `--state` (and a previous run/manifest) when using `state:` selectors to compare against a baseline.
- Named selectors and files: use `@name` to refer to selectors.yml entries; you can also compose them (`--select @group_a,tag:x +@group_b`).
- dbt overwrites the manifest.json file during parsing, which means when you reference --state from the target/ directory, you may encounter a warning indicating that the saved manifest wasn't found. Avoid setting --state and --target-path to the same path with state-dependent features like --defer and state:modified as it can lead to non-idempotent behavior and won't work as expected
- `--select` is for node selection syntax (models, seeds, tests, etc.), using operators like tag:, path:, model_name:, @ (graph expansion), etc. Named selectors (defined in selectors.yml) are not referenced with --select. They require the --selector flag.


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
- Sources make it possible to name and describe the data loaded into your warehouse by your Extract and Load tools. Help defines linage of data, test assumptions about source data and calculate freshness of your source data. Using sources unlocks the ability to run source freshness reporting to make sure your raw data isn't stale. Defined in .yml files nested under a sources: key. By default, schema will be the same as name. Add schema only if you want to use a source name that differs from the existing schema
- It's important that your freshness jobs run frequently enough to snapshot data latency in accordance with your SLAs. EG If your SLA is 1 hour, run source snapshot every 30 minutes. Set source freshness snapshots to 30 minutes to check for source freshness, then run a job which rebuilds every hour to rebuild model. This setup retrieves all the models and rebuild them in one attempt if their source freshness has expired. 

