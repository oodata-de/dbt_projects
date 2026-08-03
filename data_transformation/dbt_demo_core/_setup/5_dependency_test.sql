-- create raw table
CREATE TABLE r1 (id INT, val VARCHAR);
CREATE TABLE r2 (id INT, val VARCHAR);
CREATE TABLE r3 (id INT, val VARCHAR);
CREATE TABLE r4 (id INT, val VARCHAR);

-- Insert Initial Data
INSERT INTO r1 VALUES (1, 'A'), (2, 'B');
INSERT INTO r2 VALUES (1, 'X'), (2, 'Y');
INSERT INTO r3 VALUES (1, 'M'), (2, 'N');
INSERT INTO r4 VALUES (1, 'Q'), (2, 'R');

-- -- Create Dimension Models (dbt models)
-- -- d1.sql
-- SELECT r1.id, r1.val AS r1_val, r2.val AS r2_val
-- FROM r1
-- JOIN r2 ON r1.id = r2.id

-- -- d2.sql
-- SELECT r2.id, r2.val AS r2_val, r3.val AS r3_val
-- FROM r2
-- JOIN r3 ON r2.id = r3.id

-- -- Create Fact Models (dbt models)
-- -- f1.sql
-- SELECT r2.id, r2.val, d1.r1_val, d1.r2_val
-- FROM r2
-- JOIN {{ ref('d1') }} d1 ON r2.id = d1.id

-- -- f2.sql
-- SELECT d1.id, d1.r1_val, d2.r3_val, r4.val AS r4_val
-- FROM {{ ref('d1') }} d1
-- JOIN {{ ref('d2') }} d2 ON d1.id = d2.id
-- JOIN r4 ON d1.id = r4.id

-- -- Test Update Propagation
-- UPDATE r2 SET val = 'Z' WHERE id = 1;

-- -- Test Adding New Data
-- INSERT INTO r3 VALUES (3, 'P');
-- INSERT INTO r2 VALUES (3, 'S');

