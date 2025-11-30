use database bench_db;
create or replace schema processing;

DROP TABLE IF EXISTS f_source1;
DROP TABLE IF EXISTS f_source2;
DROP TABLE IF EXISTS f_source3;
DROP TABLE IF EXISTS f_target;

CREATE TABLE f_source1 (
    id          INT,
    col1        STRING,
    col2        INT,
    processdate DATE
);

CREATE TABLE f_source2 (
    id          INT,
    col3        STRING,
    processdate DATE
);

CREATE TABLE f_source3 (
    id          STRING,
    col4        STRING,
    processdate DATE
);

CREATE TABLE f_target (
    id          INT PRIMARY KEY,
    col1        STRING,
    col2        INT,
    col3        STRING,
    col4        STRING,
    processdate DATE
);

INSERT INTO f_source1 (id,col1,col2,processdate) VALUES
    (1,'abc',1122,'2025-01-01'),
    (2,'def',2233,'2025-01-01');

INSERT INTO f_source2 (id,col3,processdate) VALUES
    (1,'xyz','2025-01-01');

INSERT INTO f_source3 (id,col4,processdate) VALUES
    ('xyz', 'f3-xyz', '2025-01-01'),
    ('uvw', 'f3-uvw', '2025-01-01');

