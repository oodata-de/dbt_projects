use role sysadmin;
use database DBT_DEV;
grant usage on database DBT_DEV to role DBT_EXECUTOR_ROLE;
grant usage on schema SCH_DBT_TEST to role DBT_EXECUTOR_ROLE;
grant select on all tables in schema SCH_DBT_TEST to role DBT_EXECUTOR_ROLE;
grant select on future tables in schema SCH_DBT_TEST to role DBT_EXECUTOR_ROLE;

SHOW MASKING POLICIES;

SELECT GET_DDL('MASKING POLICY', 'plcy_str');

DESC MASKING POLICY plcy_st;

DROP MASKING POLICY PLCY_ST;

ALTER TABLE DBT_DEV.SCH_DBT_TEST.PII_MODEL 
MODIFY COLUMN LAST_NAME
SET MASKING POLICY DBT_DEV.SCH_DBT_TEST.PLCY_ST;

ALTER TABLE DBT_DEV.SCH_DBT_TEST.PII_MODEL 
MODIFY COLUMN LAST_NAME
UNSET MASKING POLICY;

---------------------------------------
USE ROLE USERADMIN;
CREATE ROLE ANALYST_ROLE
  COMMENT = 'Role for the analytics users';

USE ROLE SYSADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;
grant usage on database DBT_DEV to role ANALYST_ROLE;
grant usage on schema SCH_DBT_TEST to role ANALYST_ROLE;
grant select on all tables in schema SCH_DBT_TEST to role ANALYST_ROLE;
grant select on future tables in schema SCH_DBT_TEST to role ANALYST_ROLE;

---> set our Role context
 USE ROLE USERADMIN;

-------------------------------------------------------------------------------------------
    -- Step 2: Create our User
        -- CREATE USER: https://docs.snowflake.com/en/sql-reference/sql/create-user
-------------------------------------------------------------------------------------------

---> now let's create a User using various available parameters.
    -- NOTE: please fill out each section below before executing the query

CREATE OR REPLACE USER analyst_user -- adjust user name
    COMMENT = 'Analyst user'
    PASSWORD = 'XXXXX'
    DEFAULT_WAREHOUSE = 'COMPUTE_WH'
    DEFAULT_ROLE = 'ANALYST_ROLE'

USE ROLE SECURITYADMIN;
GRANT ROLE ANALYST_ROLE TO USER analyst_user;

-- grant role SYSADMIN to our User
USE ROLE USERADMIN;
-- grant usage on the COMPUTE_WH warehouse to our SYSADMIN role
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE ANALYST_ROLE;

create masking policy if not exists DBT_DEV.SCH_DBT_TEST.plcy_sch_dbt_test_st as (val string) 
    returns string ->
        case
            when current_role() in ('DBT_EXECUTOR_ROLE', 'ANALYST_ROLE') then
                '********'
            else val
    end;

SELECT *
FROM TABLE(INFORMATION_SCHEMA.POLICY_REFERENCES(ref_entity_name => 'PII_MODEL', ref_entity_domain => 'table'))