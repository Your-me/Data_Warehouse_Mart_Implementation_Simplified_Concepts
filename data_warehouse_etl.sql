--- PREPING THE DATABASE ENVIRONMENT for the first time implementation
--- Subsequent Schedule for running the script will comment out dropping of tables.
--- Based on the TYPE of SCD (Slowly Changing Dimension) Type.
--- Oracle Apex SQL concept was applied, Althrough this project.

DROP TABLE SO_NYR_STAGEAREA CASCADE CONSTRAINTS;
DROP TABLE SO_WYR_STAGEAREA CASCADE CONSTRAINTS;
DROP TABLE S1_NWYCCG_STAGEAREA CASCADE CONSTRAINTS;
DROP table etl_NWYCCG_log CASCADE CONSTRAINTS;
DROP TABLE date_error_log CASCADE CONSTRAINTS; 
DROP TABLE other_error_log CASCADE CONSTRAINTS;
DROP TABLE S2_NWYCCG_STAGEAREA CASCADE CONSTRAINTS;
DROP TABLE S3_NWYCCG_STAGEAREA CASCADE CONSTRAINTS;

--------------------------------------------------------------
DROP TABLE SS_TIME_DIM CASCADE CONSTRAINTS;
DROP TABLE SS_BED_OCCUPANCY_FACT CASCADE CONSTRAINTS;
DROP TABLE SS_CARE_CENTRE_DIM CASCADE CONSTRAINTS;
DROP TABLE SS_WARD_DIM CASCADE CONSTRAINTS;

DROP TABLE temp_time CASCADE CONSTRAINT;
DROP TABLE temp_care_centre;
DROP TABLE TEMP_WARD CASCADE CONSTRAINT;



--------------------------------------------------------------

-- Table Creation --

CREATE TABLE S1_NWYCCG_STAGEAREA(
    ADMISSION_DATE DATE NULL,
    BED_STATUS VARCHAR2(50),
    WARD_CAPACITY INTEGER,
    WARD_ID INTEGER,
    WARD_NAME VARCHAR2(50),
    CARE_CENTRE_NAME VARCHAR2(100),
    TOWN VARCHAR2(100),
    DATASOURCE VARCHAR2(3)
);

CREATE TABLE etl_NWYCCG_log
(issue_id NUMBER(5) NOT NULL, 
table_name VARCHAR2(20),
data_error_code NUMBER(5),
issue_desc VARCHAR2(50),
issue_date DATE, 
issue_status VARCHAR2(20),
status_update_date DATE);


-- Create a Database table to represent the "SS_TIME_DIM" entity.
CREATE TABLE SS_TIME_DIM(
	time_id	INTEGER NOT NULL,
	admission_date	DATE,
	the_month	VARCHAR(3),
	the_year	INTEGER,
	CONSTRAINT	pk_SS_TIME_DIM PRIMARY KEY (time_id)
);

-- Create a Database table to represent the "SS_BED_OCCUPANCY_FACT" entity.
CREATE TABLE SS_BED_OCCUPANCY_FACT(
	report_id	INTEGER NOT NULL,
	fk1_time_id	INTEGER NOT NULL,
	fk2_care_centre_id	INTEGER NOT NULL,
	fk3_ward_id	INTEGER NOT NULL,
	total_occupied_bed	INTEGER,
	total_available_bed	INTEGER,
	bed_to_ward_ratio	INTEGER,
	CONSTRAINT	pk_SS_BED_OCCUPANCY_FACT PRIMARY KEY (report_id)
);

-- Create a Database table to represent the "SS_CARE_CENTRE_DIM" entity.
CREATE TABLE SS_CARE_CENTRE_DIM(
	care_centre_id	INTEGER NOT NULL,
	care_centre_name	VARCHAR(100),
    town VARCHAR(100),
	CONSTRAINT	pk_SS_CARE_CENTRE_DIM PRIMARY KEY (care_centre_id)
);

-- Create a Database table to represent the "SS_WARD_DIM" entity.
CREATE TABLE SS_WARD_DIM(
	ward_id	INTEGER NOT NULL,
	ward_no	INTEGER,
	ward_name	VARCHAR(100),
	ward_capacity	INTEGER,
	valid_from	DATE,
	valid_to	DATE,
	current_flag	VARCHAR(1) DEFAULT 'Y',
	CONSTRAINT	pk_SS_WARD_DIM PRIMARY KEY (ward_id)
);


--------------------------------------------------------------
-- Alter Tables to add fk constraints --

ALTER TABLE SS_BED_OCCUPANCY_FACT ADD CONSTRAINT fk1_SS_BED_OCCUPANCY_FACT_to_SS_TIME_DIM FOREIGN KEY(fk1_time_id) REFERENCES SS_TIME_DIM(time_id);


ALTER TABLE SS_BED_OCCUPANCY_FACT ADD CONSTRAINT fk2_SS_BED_OCCUPANCY_FACT_to_SS_CARE_CENTRE_DIM FOREIGN KEY(fk2_care_centre_id) REFERENCES SS_CARE_CENTRE_DIM(care_centre_id);


ALTER TABLE SS_BED_OCCUPANCY_FACT ADD CONSTRAINT fk3_SS_BED_OCCUPANCY_FACT_to_SS_WARD_DIM FOREIGN KEY(fk3_ward_id) REFERENCES SS_WARD_DIM(ward_id);

-- Extracted just the data we need for bed occupancy per year per ward per care_centre.

---- EXPLORE---
-- I reviewed the tables and the atrributes in both WYR and NYR datasources
-- Eyeballed all required Tables and Attributes into the Data Dictionary.
-- During My Dimensional Modelling Design Stage.

-- So as to put all Data into one table
-- I noticed the data columns are related but some have different column name 
-- so i extracted them separately  
-- created a new temporary table for them before stacking the data on top of each other
-- and some values have different CASE format, they are updated during transformation stage.


--- ==== PROCESS 1 ---
-- EXTRACT NEEDED ATTRIBUTES FROM NYR INTO SO_NYR_STAGEAREA
-- DROP TABLE SO_NYR_STAGEAREA CASCADE CONSTRAINTS;  1
CREATE TABLE SO_NYR_STAGEAREA AS
SELECT 
NYR_ADMISSION.ADMISSION_DATE, 
NYR_BED.BED_STATUS,
--SUM(CASE WHEN WYR_BED.BED_STATUS = 'Occupied' THEN 1 ELSE 0 END) AS OCCUPIED_BEDS,
--SUM(CASE WHEN WYR_BED.BED_STATUS = 'Available' THEN 1 ELSE 0 END) AS AVAILABLE_BEDS,
NYR_WARD.WARD_CAPACITY,
NYR_WARD.WARD_ID,
NYR_WARD.WARD_NAME,
NYR_CARE_CENTRE.CARE_CENTRE_NAME,
NYR_CARE_CENTRE.TOWN
FROM NYR_ADMISSION 
JOIN NYR_BED ON NYR_ADMISSION.BED_ID = NYR_BED.BED_ID
JOIN NYR_WARD ON NYR_BED.WARD_ID = NYR_WARD.WARD_ID
JOIN NYR_CARE_CENTRE ON NYR_WARD.CARE_CENTRE_ID = NYR_CARE_CENTRE.CARE_CENTRE_ID
ORDER BY
NYR_ADMISSION.ADMISSION_DATE,
NYR_CARE_CENTRE.CARE_CENTRE_NAME;

-- I'm going to add a column to show where the data has come from
ALTER TABLE SO_NYR_STAGEAREA
ADD DATASOURCE VARCHAR2(3);
UPDATE SO_NYR_STAGEAREA SET DATASOURCE = 'NYR';


--- ==== PROCESS 2 === ---
-- EXTRACT NEEDED ATTRIBUTES FROM WYR INTO SO_WYR_STAGEAREA
-- DROP TABLE SO_WYR_STAGEAREA CASCADE CONSTRAINTS;  2
CREATE TABLE SO_WYR_STAGEAREA AS
SELECT 
WYR_RESERVATION.ADMISSION_DATE, 
WYR_BED.BED_STATUS,
--SUM(CASE WHEN WYR_BED.BED_STATUS = 'Occupied' THEN 1 ELSE 0 END) AS OCCUPIED_BEDS,
--SUM(CASE WHEN WYR_BED.BED_STATUS = 'Available' THEN 1 ELSE 0 END) AS AVAILABLE_BEDS,
WYR_WARD.WARD_CAPACITY,
WYR_WARD.WARD_NO,
WYR_WARD.WARD_NAME,
WYR_CARE_CENTRE.CARE_CENTRE_NAME,
WYR_CARE_CENTRE.TOWN
FROM WYR_RESERVATION
JOIN WYR_BEDASSIGNED ON WYR_RESERVATION.RESERVATION_ID = WYR_BEDASSIGNED.RESERVATION_ID
JOIN WYR_BED ON WYR_BED.BED_NO = WYR_BEDASSIGNED.BED_NO
JOIN WYR_WARD ON WYR_BED.WARD_NO = WYR_WARD.WARD_NO
JOIN WYR_CARE_CENTRE ON WYR_WARD.CARE_ID = WYR_CARE_CENTRE.CARE_ID
ORDER BY
WYR_RESERVATION.ADMISSION_DATE,
WYR_CARE_CENTRE.CARE_CENTRE_NAME;

-- I'm going to add a column to show where the data has came from
ALTER TABLE SO_WYR_STAGEAREA
ADD DATASOURCE VARCHAR2(5);
UPDATE SO_WYR_STAGEAREA SET DATASOURCE = 'WYR';



-- SELECT * FROM SO_WYR_STAGEAREA;


--- ==== PROCESS 3 ==== ----
--EXTRACT FIRST TABLE INTO S1_NWYCCG_STAGEAREA & MERGE SECOND TABLE TO IT 
--TO CREATE A SINGLE TABLE DURING TRANSFORMATION AND QUALITY CHECKS.
-- NWYCCG --> North & West YorkShire Clinic Commission Group
--DROP TABLE S1_NWYCCG_STAGEAREA CASCADE CONSTRAINTS;  3

-- ADMISSION DATE contains NULL value for reservations that were cancelled, 
-- SO everything is captured for DATA INTEGRITY BEFORE TRANSFORMATION -- GENERAL CARE WARD IN OSCAR CARE HOME LOCATED IN WYR --.
/*
CREATE TABLE S1_NWYCCG_STAGEAREA(
    ADMISSION_DATE DATE NULL,
    BED_STATUS VARCHAR2(50),
    WARD_CAPACITY INTEGER,
    WARD_ID INTEGER,
    WARD_NAME VARCHAR2(50),
    CARE_CENTRE_NAME VARCHAR2(100),
    DATASOURCE VARCHAR2(3)
);
*/

-- MERGED THE DATA FROM BOTH DATA SOURCES
INSERT INTO S1_NWYCCG_STAGEAREA (SELECT * FROM SO_NYR_STAGEAREA);

INSERT INTO S1_NWYCCG_STAGEAREA (SELECT * FROM SO_WYR_STAGEAREA);

-- SELECT * FROM S1_NWYCCG_STAGEAREA


-- Number of rows in S1_STAGEAREA before cleaning?
-- SELECT COUNT(*) FROM S1_NWYCCG_STAGEAREA;

drop sequence ETL_NWYCCG_SEQ;
create sequence ETL_NWYCCG_SEQ
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

-- START of Data Transformations --

-- 2. ETL1_NWYCCG_transforms

-- USING a table to log the changes made to the data,
-- Every Changes, Update,Insert and delete Operations should be recorded in data dictionary.
-- Data Integrity should be maintain for Ethical purposes to avoid human biases.
-- so I am using a trigger and an ‘ETL_log’ table.

-- Solution:
-- log ETL changes (Drop the table for the first Implementation only)
-- Comment it out for subsequent run schedule of the script
DROP table etl_NWYCCG_log CASCADE CONSTRAINTS;


-- Now as part of the ETL - T for transformation, I will do data quality checks and log them in a data issues table
-- I have decided to update S1_NWYCCG_STAGEAREA directly. 


-- DROP TRIGGER S1_NWYCCG_STAGEAREA.trg2_quality_chk ;

-- START of data transformations
CREATE or REPLACE trigger S1_NWYCCG_STAGEAREA.trg2_quality_chk 
  before UPDATE on S1_NWYCCG_STAGEAREA           
  for each row 
begin  
  INSERT INTO etl_NWYCCG_log
  (issue_id,  table_name,  data_error_code,  issue_desc,  issue_date, issue_status, status_update_date)
   VALUES
  (ETL_NWYCCG_SEQ.nextval, 'S1_STAGEAREA', '0', 'Quality checks', SYSDATE, 'completed', SYSDATE);
end;


-- Data Quality checks and transformation on S1_STAGEAREA

-- Quality Check example -	
-- Update the NULL DATE data from admission date , maybe set it to ‘01-01-1111’ before deleting it for tracking purpose?
-- Delete any data with 01-01-1111 as admission date value from the Staging Area during Transformation process.
 
-- QUALITY CHECK
UPDATE S1_NWYCCG_STAGEAREA
SET admission_date = '01-01-1111' 
WHERE 
admission_date IS NULL;

-- 1 row was updated during Quality Check of admission_date.

-- FURTHER QUALITY CHECK FOR RECORD KEEPING. 
-- Any admission_date with 01-01-1111  is cancelled reservation and 
-- will be recorded in the date_error_log file before elimination/removal for further investigation when needed.
drop sequence date_error_SEQ;
create sequence date_error_SEQ
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

--DROP TABLE date_error_log CASCADE CONSTRAINTS;  5
CREATE TABLE date_error_log AS SELECT date_error_SEQ.nextval AS error_id, admission_date, bed_status, ward_capacity,ward_id,ward_name,care_centre_name,datasource 
FROM S1_NWYCCG_STAGEAREA 
WHERE admission_date = '01-01-1111';


-- TRACKING NULL VALUES IN OTHER ATTRIBUTES AM WORKING WITH.
drop sequence other_error_SEQ;
create sequence other_error_SEQ
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

-- DROP TABLE other_error_log CASCADE CONSTRAINTS;
CREATE TABLE other_error_log AS SELECT other_error_SEQ.nextval AS other_error_id, bed_status, ward_capacity,ward_id,ward_name,care_centre_name,datasource 
FROM S1_NWYCCG_STAGEAREA 
WHERE bed_status IS NULL OR ward_capacity IS NULL OR ward_id IS NULL OR ward_name = NULL OR care_centre_name IS NULL;

-- Display the available data in the error log.
SELECT * FROM date_error_log; 


-- TRANSFORMATION
-- The null dates represented with '01-01-1111' needs to be deleted
DELETE FROM S1_NWYCCG_STAGEAREA WHERE admission_date = '01-01-1111';
-- 1 row(s) / records deleted where reservation was canceled

-- Their is inconsistency in CASE of the ward_name and care centre name some are lower and some are capitalized letter. 
-- In WYR, bed_status Occupied is CAPITALIZED so it will be updated to UPPER CASE and other columns too before getting the sum.
-- Recorded in etl_NWYCCG_log. NYR bed_status is already in UPPER CASE format.
-- The admission date has different format too.
UPDATE S1_NWYCCG_STAGEAREA
SET bed_status = UPPER(bed_status),
     ward_name = UPPER(ward_name),
     care_centre_name = UPPER(care_centre_name),
     town = UPPER(town),
     admission_date = TO_DATE(TO_CHAR(admission_date,'MM/DD/YYYY'))
     ;


-- The Aggregated measures need to be derived based on admission date, wardname and care centre
-- ADMISSION DATE IS BROKEN INTO MONTH AND YEAR(HIERARCHICAL DIMENSION) FOR BUSINESS INTELLIGENCE REPORT
-- NEW TEMPORARY STAGING TABLE IS CREATED
-- OCCUPIED BED_STATUS IS COMMON TO BOTH DATASOURCE, BUT AVAILABLE & NOT OCCUPIED ARE USED INTERCHANGEABLY
UPDATE S1_NWYCCG_STAGEAREA
SET bed_status = 'AVAILABLE' 
WHERE 
bed_status = 'NOT OCCUPIED';

-- DERIVED ATTRIBUTES IS BASED ON OCCUPIED VALUE OF BED STATUS for accurate measures and reuseability of code.


--DROP TABLE S2_NWYCCG_STAGEAREA CASCADE CONSTRAINTS;   6
CREATE TABLE S2_NWYCCG_STAGEAREA AS
SELECT 
ADMISSION_DATE,
TO_CHAR(ADMISSION_DATE, 'MON') AS THE_MONTH,
TO_NUMBER(TO_CHAR(ADMISSION_DATE, 'YYYY')) AS THE_YEAR,
SUM(CASE WHEN BED_STATUS = 'OCCUPIED' THEN 1 ELSE 0 END) AS TOTAL_OCCUPIED_BEDS,
-- SUM(CASE WHEN BED_STATUS = 'Available' THEN 1 ELSE 0 END) AS AVAILABLE_BEDS,
-- After critical observation the sum of available beds from the table wont give the accurate number of 
-- avaible beds, so subtracting sum of occupied beds from the ward capacity will be accurate. 
WARD_CAPACITY - (SUM(CASE WHEN BED_STATUS = 'OCCUPIED' THEN 1 ELSE 0 END)) AS TOTAL_AVAILABLE_BEDS,
ROUND((SUM(CASE WHEN BED_STATUS = 'OCCUPIED' THEN 1 ELSE 0 END) / WARD_CAPACITY) * 100,2) AS "BED_TO_WARD_RATIO",
WARD_CAPACITY,
WARD_NAME,
WARD_ID,
CARE_CENTRE_NAME,
TOWN,
DATASOURCE
FROM 
S1_NWYCCG_STAGEAREA
GROUP BY
ADMISSION_DATE,
WARD_CAPACITY,
WARD_NAME,
WARD_ID,
CARE_CENTRE_NAME,
TOWN,
DATASOURCE
ORDER BY 
ADMISSION_DATE,
CARE_CENTRE_NAME;

SELECT * FROM S2_NWYCCG_STAGEAREA;
--before selecting distinct records

SELECT COUNT (*) FROM S2_NWYCCG_STAGEAREA;
-- WE HAVE 29 ROWS FOR NOW

-- FOR PROPER LOADING INTO THE STAR SCHEMA i.e fact table and dimensions 
--A surrogate key will be added to the staging area for easy tracking 
-- WARD_ID will be changed to WARD_NO as a natural key
drop sequence s3_nwyccg_stage_SEQ;
create sequence s3_nwyccg_stage_SEQ
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

-- DROP TABLE S3_NWYCCG_STAGEAREA CASCADE CONSTRAINTS; 7
CREATE TABLE S3_NWYCCG_STAGEAREA AS 
SELECT s3_nwyccg_stage_SEQ.nextval AS STAGE_ID, ADMISSION_DATE,THE_MONTH,THE_YEAR,TOTAL_OCCUPIED_BEDS,TOTAL_AVAILABLE_BEDS, BED_TO_WARD_RATIO,
WARD_CAPACITY, WARD_NAME,WARD_ID AS WARD_NO,CARE_CENTRE_NAME,TOWN,DATASOURCE FROM S2_NWYCCG_STAGEAREA;

--SELECT * FROM S3_NWYCCG_STAGEAREA;

---***********
-- 3. ETL1_BEDOCCUPPANCY_load
---***********
-- Populate the Dimension tables
-- Populate the fact table
-- Now to populate the time_dim
-- FIRST NEED TO SELECT DISTINCT TIME_DIM VALUES
-- A TEMPORARY TABLE WILL BE CREATED FIRST BEFORE LOADING THE TIME_DIM

--DROP TABLE temp_time CASCADE CONSTRAINT;  12
CREATE TABLE temp_time AS SELECT DISTINCT admission_date, the_month, the_year 
FROM S3_NWYCCG_STAGEAREA ORDER BY admission_date;

drop sequence time_id_seq;
create sequence time_id_seq
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

INSERT INTO SS_TIME_DIM(time_id,admission_date,the_month,the_year) 
SELECT time_id_seq.NEXTVAL, admission_date, the_month, the_year FROM temp_time;

SELECT COUNT(*) FROM SS_TIME_DIM;
-- I HAVE 20 ROWS IN THE TIME DIMENSION.


-- Now repeat similar for the care_centre dimension table
--

--DROP TABLE temp_care_centre; 13
CREATE TABLE temp_care_centre AS SELECT DISTINCT care_centre_name,town FROM S3_NWYCCG_STAGEAREA;

DROP sequence care_centree_seq;
create sequence care_centree_seq
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

INSERT INTO SS_CARE_CENTRE_DIM SELECT care_centree_seq.nextval, care_centre_name, town FROM temp_care_centre;

-- FOR WARD DIM SLOWLY CHANGING WILL BE INTRODUCED.
------------------------------------------------------------
-- SCD TYPE 2 WILL BE IMPLEMENTED
-- Ward Capacity is the historical tracked attribute
-- Renovation or Adjustment after Business Intelligence Report Could lead to an Increase or Decrease in Capacity
-- Over the time which could have significant impact on Data Mining Accuracy/Integrity carried out in the Future.
------------------------------------------------------------

--DROP TABLE TEMP_WARD CASCADE CONSTRAINT;  14

CREATE TABLE TEMP_WARD AS
SELECT DISTINCT ward_no,ward_name, ward_capacity
FROM S3_NWYCCG_STAGEAREA;

-- SELECT * FROM TEMP_WARD;

-- Added after the first Merged.
-- UNCOMMENT TO TEST SCD TYPE 2 AFTER THE RUN OF CODE
/*
UPDATE TEMP_WARD 
set ward_capacity = 15
Where ward_no = 1 and ward_name = 'GENERAL CARE';
*/
--  ward_id_seq
drop sequence ward_id_seq;
create sequence ward_id_seq
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

MERGE INTO SS_WARD_DIM swd
USING (SELECT ward_no, ward_name, ward_capacity FROM temp_ward) tw
ON (swd.ward_no = tw.ward_no)
WHEN MATCHED THEN
  UPDATE SET
    swd.current_flag = 'N',
    valid_to = SYSDATE
    where swd.ward_capacity != tw.ward_capacity AND swd.ward_name = tw.ward_name AND swd.ward_no = tw.ward_no
  WHEN NOT MATCHED THEN
  INSERT (ward_id, ward_no, ward_name,ward_capacity, valid_from, valid_to, current_flag)
  VALUES (ward_id_seq.nextval, tw.ward_no, tw.ward_name,tw.ward_capacity, SYSDATE, NULL, 'Y')
  WHERE tw.ward_name IS NOT NULL;
  
-- Noticed the Merge statement does not insert the modified record as new row but the code below handles that.

INSERT INTO SS_WARD_DIM
	(SELECT	ward_id_seq.nextval, ward_no, ward_name,  ward_capacity, sysdate, NULL, 'Y' 
	FROM	temp_ward tw 
	WHERE  ward_no IN
(SELECT ward_no FROM ss_ward_dim swd where swd.ward_no = tw.ward_no and swd.ward_capacity != tw.ward_capacity))
/


---******
---*************
---******
DROP sequence report_id_seq;
create sequence report_id_seq
start with 1
increment by 1
maxvalue 9999999
minvalue 1;

--LOADING THE FACT TABLE AND 
INSERT INTO SS_BED_OCCUPANCY_FACT (SELECT 
    report_id_seq.NEXTVAL,
    SS_TIME_DIM.time_id,
    SS_CARE_CENTRE_DIM.care_centre_id,
    SS_WARD_DIM.ward_id,
    S3_NWYCCG_STAGEAREA.total_occupied_beds,
    S3_NWYCCG_STAGEAREA.total_available_beds,
    S3_NWYCCG_STAGEAREA.bed_to_ward_ratio
FROM S3_NWYCCG_STAGEAREA , SS_TIME_DIM, SS_CARE_CENTRE_DIM, SS_WARD_DIM
WHERE S3_NWYCCG_STAGEAREA.ADMISSION_DATE = SS_TIME_DIM.ADMISSION_DATE AND 
S3_NWYCCG_STAGEAREA.ward_name = SS_WARD_DIM.ward_name AND 
S3_NWYCCG_STAGEAREA.care_centre_name = SS_CARE_CENTRE_DIM.care_centre_name);


--- EXTRACTING RECORDS FOR REPORTS.
--- USING A VIEW TO HOLD THE CONTENT OF REPORT THAT WILL BE GENERATED  AND OR 
-- MATERIALIZED VIEW VIEW SO AS TO SPEED UP QUERY RESULT WHEN THE CENTRALIZED DATABASE BECOMES BIGGER.


DROP VIEW bed_occupancy_report_v;
CREATE VIEW bed_occupancy_report_v AS 
SELECT sbof.report_id, std.admission_date,std.the_year,std.the_month,swd.ward_name,
sccd.care_centre_name,sccd.town,sbof.total_occupied_bed, sbof.total_available_bed, sbof.bed_to_ward_ratio
FROM ss_bed_occupancy_fact sbof, ss_time_dim std, ss_care_centre_dim sccd, ss_ward_dim swd
WHERE sbof.fk1_time_id = std.time_id 
AND sbof.fk2_care_centre_id = sccd.care_centre_id 
AND sbof.fk3_ward_id = swd.ward_id;


/*
DROP MATERIALIZED VIEW report_materialized_view;
CREATE MATERIALIZED VIEW report_materialized_view
AS
SELECT sbof.report_id, std.admission_date,std.the_year,std.the_month,swd.ward_name,
sccd.care_centre_name,sccd.town,sbof.total_occupied_bed, sbof.total_available_bed, sbof.bed_to_ward_ratio
FROM ss_bed_occupancy_fact sbof, ss_time_dim std, ss_care_centre_dim sccd, ss_ward_dim swd
WHERE sbof.fk1_time_id = std.time_id 
AND sbof.fk2_care_centre_id = sccd.care_centre_id 
AND sbof.fk3_ward_id = swd.ward_id;

DROP INDEX idx_BO_report_mv;
CREATE INDEX idx_BO_report_mv 
ON report_materialized_view(admission_date,the_year,care_centre_name,total_occupied_bed,bed_to_ward_ratio)
*/

