# Data_Warehouse_Mart_Implementation_Simplified_Concepts
North and West Yorkshire Clinical Commission Group (INFORMATION SYSTEM) FICTIONAL Concept.

Markdown

Collapse
# INTRODUCTION
## North and West Yorkshire Clinical Commission Group (INFORMATION SYSTEM) FICTIONAL concept
North and West Yorkshire Clinical Commission Group (NWYCCG) needs an information system for managing the social and healthcare operation of medical facilities that they are controlling and they using 6 care homes from the Leeds city council for a test case to produce a system to improve elderly patients experience and provide high-quality care recovery period support. A System will be developed to measure;
- 1. Care home effectiveness in terms of bed occupancy and the recovery period. As a Business Intelligence consultant am expected to implement a system that integrates WYR and NYR health data, as well as social care case database. 
- 2. Support for doctors and social care services, where doctors need to see the social care services provided to a patient, and social workers and service providers need to have access to the health care record.
As a Business Intelligence Consultant and a Data Scientist based on my previous meeting NWYCCG and one of the stakeholder ( LEEDS CITY COUNCIL HEALTH DEPARTMENT DIRECTOR), not forgetting others that were not present that will be using the information system. I realised the best solution to the current situation is a CENTRALIZED DATABASE SYSTEM, and DATA WAREHOUSING system, fits perfectly for generating decision making reports.

## DATA WAREHOUSE DESIGN
I used BEAM (Business Event and Analysis Modelling) and CRISP methodology to arrive at developing (Kimball Dimensional Data Mart/ Warehouse). Because BEAM ensures the stakeholders are carried along in the Data Warehouse development from the inception to the end, starting with 7W dimensional types questions: Who, What, When, Where, How many, Why and How; to describe business event he needs to measure (Corr & Stagnitto, 2012). Crisp was used since it is a project about data mining.
The Stakeholder is interested in the bed occupancy KPI, so that it can help in strategic decision-making of budget allocation.
Since BEAM and Ralph Kimball data warehouse design is based on incremental design or in other words agile methodology. Considering the kind of trust issue facing HEALTHCARE SECTOR. The people involved will corporate, when they see the effect of the system being built as soon as possible.
Based on the BED OCCUPANCY KPI, the first DATA MART that will be built, will answer question around the following description or dimension.
- 1.	Total number of occupied beds based on time and Care Centre hierarchy 
- 2.	Total number of available beds based on time and Care Centre hierarchy
- 3.	Bed occupancy rate (occupied bed to ward ratio in percentage) per care-center per months.

![Fig_1 ](/Images/Fig_1.png)


## DATA WAREHOUSE IMPLEMENTATION PLANNING
A design of the proposed Data Warehouse Design has been presented about 7 weeks ago. Containing the information on what the implementation and development would look like. After carefully observing the existing Online Transactional Processing System, in the pioneer regions: North Yorkshire and West Yorkshire. The existing available databases are showing 3 care homes per region making 6 care homes all together.

![WYR_script confirmation for loading the data store ](/Images/Fig_2.png)

![NYR_script confirmation  for loading the data store ](/Images/Fig_3.png)

After reviewing the tables available in the 2 databases, I was able to come up with tables and attributes needed for the current data mart KPI. Based on this I came up with a star schema.

![Initial Star Schema for Bed Occupancy ](/Images/Fig_4.png)

After another meeting with NWCCG and the stakeholders, the star schema was revised to take care of slowly changing dimensions (SCD). The report generated will be used for effective decision-making as regards the Care Home Infrastructure. We all agreed to track the capacity of all the wards in the two regions over time, and since future data mining integrity and accuracy are to be put in place, because I introduced the concept of BIG PAPA FRAMEWORK guidelines for developing information systems that are ethical to them (Mason, 1986, as cited in Young et al., 2020), so the service users and the people in general can trust the system with their information’s.

![Revised Star Schema with type 2 SCD ](images/Fig_5.png)

## DATA WAREHOUSE IMPLEMENTATION DESIGN
Using the Qsee tool I did a forward engineering of my star schema and I imported it into Oracle Apex. This Data Warehouse system will be developed with ORACLE APEX. It is quite popular among the Home care centres in the two regions. The lowest granularity of this Star Schema is the ADMISSION DATE. This enables the Centralized system to take care of some addictive, semi-addictive and non-additive measurements combined (Kimball, 1998).
The lowest level (grain) of details will help in aggregating or rolling up some business decision-making.
- TASK 1: ETL (Extraction, Transform and Load) Documentation.
After the forward engineering process, The ETL process followed. Referring back to the flow diagram above. Online Transaction Processing Systems (OLTP) data are usually dirty, and sometimes inconsistent, and when we have collections of multiple data stores that are not all standardized to the same format. As a Data Scientist, it is one of our numerous duties to clean dirty and avoid the issue of garbage in garbage out.
- ### EXTRACTION:
All the needed attributes or columns from each database consisting of multiple tables are extracted from the OLTP Data Stores into a Staging Area inside the Oracle Apex with Several Temporary tables.
North Yorkshire database attributes needed in the star schema are extracted into a temporary table called SO_NYR_STAGEAREA using multiple join statements. The following attributes are extracted;
Admission_Date, Bed_Status, Ward_Capacity, Ward_Id, Ward_Name, Care_Centre_Name, Town, and ‘DataSource’ was added for future tracking attributes source.

![SO_NYR_STAGEAREA ](images/Fig_6.png)

West Yorkshire Database, attributes needed in the star schema are extracted into a temporary table called SO_WYR_STAGEAREA using multiple join statements. The following attributes are extracted;
Admission_Date, Bed_Status, Ward_Capacity, Ward_No, Ward_Name, Care_Centre_Name, Town, and ‘DataSource’ was added for future tracking attributes source.
**NOTE** :   Ward_No instead of Ward_Id and this will be used as “natural” key for tracking the slowly changing dimension attributes and the values in Bed_status attributes are not the same as we have in the first table. Transformation will take care of this.

![SO_WYR_STAGEAREA ](images/Fig_7.png)

#### Merging Of The Two Tables Into One Temporary Table In The Staging Area
The two tables are merged into a single table, during this process the ward_id from SO_NYR_STAGEAREA was changed to ward_no based on the attribute name they were loaded into in S1_NWYCCG_STAGEAREA for a seamless transformation process.

- ## TRANSFORMATION
Data Integrity Issues, Data Quality, Transformation and Audits are attended to at this stage
Transforming Process 1
- 1. A trigger was created to track any adjustment to like update of data on the S1_NWYCCG_STAGEAREA table.
- 2. Cancelled reservation was captured as NULL for admission date in WYR. To take care of this issue and track it for future reference, I converted all the null values to a date value “01-01-1111’ and I created a date_error_log date to store them this will be noted in the data dictionary as well. After storing it, I made sure future occurrences would be well taken care of too.

![DATE ERROR LOG ](images/Fig_8.png)

- 3. I took care of the occurrence of a null value in any of the attributes am working with and created a log table called other_error_log table for this purpose. None was detected for now but it will keep a record of future occurrences. 
- 4. I noticed the admission date format was different (e.g. MM-DD-YYYY, DD-MM-YYYY).So using the function TO_DATE (TO_CHAR (admission_date, ’MM-DD-YYYY’)) I was able to STANDADIZE all the admission date format.
- 5. The alphabetical case of the values in bed_status was mixed of all cases, same with ward_name, care_centre_name,and town. To handle this type of the situation now and in the future, I used the function column_name = UPPER(column_name) to change of everything to a capital letter.
- 6. The bed_status has Values “OCCUPIED” and “NOT_OCCUPIED” in NYR and It has “AVAILABLE” and “OCCUPIED” in WYR. Everything was standardized to  “OCCUPIED” and “NOT_OCCUPIED” for the two region with and Update statement. 
As shown in the table below.




![S1_NWYCCG_STAGEAREA for Data quality transformation ](images/Fig_9.png)

- ### Transformation Process 2: Grouping Admission date into Hierarchy and calculating the derived values for measurement in fact_table.
1.	Admission date was used to derive THE_MONTH & THE_YEAR time dimension attributes using TO_CHAR () function.
2.	TOTAL_OCCUPIED_BEDS measure was derived from bed_status occupied values. Using a CASE () function.
3.	After critical observation the sum of available beds from the table won't give the accurate number of available beds, so subtracting the sum of occupied beds from the ward capacity will be accurate.
**Note**: When using aggregate functions, A” Group by” keyword is used, especially when calculating along hierarchies. “Having” comes in when there are or are some clauses.  
The diagram below is using the output from the transformation.


![NWYCCG_STAGEAREA: TRANSFORMATION ADMISSION DATREE INTO A HIERARCHIES AND CALCULATED MEASURES FOR FACT TABLE ](images/Fig_10.png)
Finally, in the transformation stage, a surrogate key was introduced to give the records a unique key. The table is called S1_NWYCCG_STAGEAREA. Just for record purposes or future use.

- ## LOADING
The forward-engineered tables from the QSEE tool will be loaded at this stage from the transformation staging area temporary table.
To take care of duplicate records a temporary table is created for all dimensions tables. One as temp_Care, one as temp_Time, one  temp_Ward, using ‘SELECT DISTINCT’ to create the temporary table.
It also makes the introduction of surrogate keys into the dimension table easier.
List of Sequences was created to serve this purpose as well and we have being using SEQUENCE to automatically increment our primary keys which are unique identifiers from the beginning of this code sql script.
Before creating most of our tables we drop them with cascading constraints. To avoid uninvited errors while running our code as BATCH-SCRIPT.
The images of loaded Dimension tables using the above procedures, follows below;

- 1.	**TIME_DIM**

![Loaded Time_DIm from Staging Area ](images/Fig_11.png)

- 2.	**CARE_CENTRE_DIM**

![Loaded Care_Centre_Dim from staging Arera ](images/Fig_12.png)

- 3.	**WARD_DIM**
The Slowly Changing Dimension, The Stakeholders want us to track the history of this dimension. It is the historically significant dimension and the attribute being monitored over time is the WARD CAPACITY which at the moment is 20 beds per ward. SCD TYPE 2 is applied. The wants to keep a record of every change in the capacity at any given point in time. This type of SCD could get bigger easily because a new row is added for every in the value of the WARD CAPACITY and I used 3 flags to track it, namely “valid_from”,” valid_to”, and “current_flag” – has a default value of Y for the current capacity and N if the capacity has changed. The concept I used was to create two Scripts. One will only run at the launch of the Data Warehouse System and the Second Script will be scheduled for repeated automatic running every 30 days for now based on STAKEHOLDERS' request. For this exercise, I have a code that updated the ward capacity of the ICU ward in the second script to test if the code is working.


![Combine_DWMA_code-the 1st script. ](images/Fig_13.png)

Ran the Script the First Time

![Ward DIm Before Updating the ICU value. ](images/Fig_14.png)

I will run the second Script now now. DROP and CREATE WARD statement was commented out. I updated the ICU capacity will code in the Script.

![SCD_SCRIPT that will be scheduled to execute every month. ](images/Fig_15.png)

Checking the WARD DIM for changes.

![Ward_DIm after Type2 SCD was applied ](images/Fig_16.png)


- 4.	 **The BED OCCUPANCY FACT TABLE.**
A report table was generated based on the lowest granularity level of admission date. The Fact table was made up of the Surrogate key called report_id, the foreign key from the Dimensions and the measures that made up the report. Based on the relationship between the Fact table primary key and the dimensions foreign key. The measures can be described by the combination of dimensions or part of the dimension. Based on the concept of Addictive, Semi-Addictive or Non-Addictive measures. A sample of the fact table is displayed below.

![SS_Bed_Occupancy _fact ](images/Fig_17.png)

- 5.	**VIEW bed_occupancy_report_v.**
A view was created based on a query to select all the records in the fact table, and these records will be downloaded as Excel and used for the Online Analytics Processing Report or Decision Support System. A sample is shown below.

![Bed_occupancy_report_v VIEW.](images/Fig_18.png)


# OLAP (ONLINE ANALYTICS PROCESSING SYSTEM using Oracle View Report and Excel Dashboard).
Online analytical processing and Data warehousing are two important factors that are used together in decision support systems and it is one of the most popular combination in Business Intelligence for effective support systems (Jaroli & Masson, 2017). Due to the nature of the report generated from Online Transactional processing systems and the effect the final decision could have on a business or users involved, the online transaction processing system cannot handle it effectively. Since OLTP systems help to handle day to day operation of the business.  OLAP systems dig deeper into historical information that can be generated from the use of data collected by OLTP systems.
Leung et al., (2020) discussed big data, machine learning and healthcare, and they concluded that knowledge gotten from the epidemiological by using data science methods such as Machine learning, data mining, and online analytical processing has helped researchers, epidemiologists and the executives making strategic moves to gain an understanding of several diseases and has led them to get a way of mitigating, managing and preventing a lot of disease. The predictability and the prescriptive ability possessed by the field of data science are so positive, although we cannot forget about the ethical issues that accompany it.
After generating the report from the Fact table in the Bed Occupancy Data-mart from the Dimensional warehouse produced using Ralph Kimball approach. From the flow diagram above we can see this is the back end. The front end is what OLAP systems provide and am using the PIVOT table in MICROSOFT EXCEL for this project.
One important thing to take note of is that Correlation does not mean Causation, so when data mining is done on available data, more effort should be put in the causation and not just the correlation.


![Report Generated from the Fact_table Query View in oracle apex. ](images/Fig_19.png)

# DASHBOARD PRODUCED FROM OLAP
![SIMPLIFIED OLAP DASHBOARD FOR BED OCCUPANCY FOR NORTH AND WEST YORKSHIRE CLINIC COMMISSION GROUP ](images/Fig_20.png)


## OBSERVATIONS FROM THE DASHBOARD.
- The bed occupancy rate at LBU Care home is the highest despite the fact that it is a Care Home that has only started its operation in 2023 according to the visualization from the generated data. 
- Followed by WELL BEING CARE HOME. BEWAN and ALTRON CARE HOME have the lowest occupancy rates, even though Bewan has been in operation earlier than Altron. The Leeds City Health director would want to know why Bewan has been under-utilized.
- The Fourth Quarter is usually the season with the highest patronage in most of the care homes. That visualization gives the decision-makers some insight into the next strategic decision.


## REFLECTION ON CASE STUDY DEVELOPMENT APPROACH
According to Khan and Sayed (2015), the application of health informatics as seen an exceptional acceptance in areas of healthcare management, diagnosis, clinical care, pharmacy, nursing, and public health. And health Informatics can be defined as the incorporation and automation of healthcare services with the engagement of information systems, by Information technology professionals like data scientists, software developers, cloud solution architects and many others. It helps to manage resources and employ methods to improve the collection, storage, and business intelligence reports in medical research (Khan & Sayed, 2015). It is no longer a news in the current era of big data that the data available as a result of technological advancement is coming in at a rapid, various form, huge amount and all other characteristics of big data is undeniable. North and West Yorkshire Clinical Commission group would want to benefit from the advancement in technology as well to help in decision making.
The best solution to the current situation is a CENTRALIZED DATABASE SYSTEM, and DATA WAREHOUSING system, fits perfectly for generating decision making system. RALPH KIMBALL DATA MART BUS ARCHITECTURE WITH LINKED DIMENSIONAL DATAMART ARCHITECTURE. With the current OLTP database used, 2 –Tier Architecture will be used for now and as more data marts is added to the central data warehouse a middleware will be introduced and the architecture will be upgraded to three-tier architecture. Hub and Spoke Architecture by Bill Inmon will take a longer time to be implemented and users preferred a system they are fully involved in. So with the combination of CRISP and BEAM methodology. The stakeholder will be carried along using the 7w’s (questions) as stated above during the design stage  (Corr & Stagnitto, 2012). Agile methodology towards development of smaller units of a bigger project user and stakeholder oriented. 
A Data Lake is a system for gathering unstructured, semi-structured, or sometimes structured data that have no current use or recognition within an organization or enterprise. This is done using low-cost technologies that aid in the extraction, cleaning, transforming, and loading of the data into an archive. The main purpose of Data Lake is to provide a cost-effective solution for storing large volumes of data that may or may not have immediate value to the organization (Fang, 2015).
Once data is available they are placed into Data Lake in their original format and available to everyone in the enterprise for analysis. It helps to save the cost of loading data into subject area data mart (Fang, 2015). This method simply uses Extract Load and Transform ELT. And a lot of Cloud Service provider are offering this are a cheaper rate.
According to a recent study by a research, utilizing a data lake approach with Big Data technologies is recommended to gather data for analysis. The platform described here facilitates the collection, storage, integration, and analysis of data, as well as the visualization of results. 
Combining data from a wide range of data sources is effective solution in data mining because it is believed the bigger the data the easier it can be generate a pattern (Mehmood et al., 2019). Most times this leads to a bigger bias in data, because every data has its own inconsistency merging of multiple datasets multiplies the level of Inconsistency. Analysis of data leads to a statistically proved result and will work well for prediction and prescription purposes. And it will also aid data mining purpose for the care centre when they start gaining trust from users with the type of data provided.
Fang (2015) concluded that the combination of Data Warehouse and Data Lake is the best solution for Companies and Enterprises dealing with Big Data. Having a structured historical data is important for some business decisions.
Users privacy needs to be consider while developing a centralized solution and due to this ethical issue I suggested the use of Big papa frame guideline why developing the Business Intelligence system. Big-Papa stands for Behavioural Surveillance, Interpretation and Governance, Privacy, Accuracy, Property and Accessible. All this factors are to be considered in health sector because of the type of data involved. So I suggested that all the users involved be informed and a user consent form be provided. And for the data available we will enforce highest authentication level. Only accountable and responsible users will be given access to the system. And individual users view will be based on level of privilege.
As a Data scientist I tried my best not to allow my subjectivity to cloud my judgement or design and I work towards objectivity. And I now know bigger data is not always a better. **Although, it is debatable opinion.**



## References

- Corr, L., & Stagnitto, J. (2012). *Agile Data Warehouse Design*. Leeds: DecisionOne Press.

- Jaroli, P. & Masson, P. (2017). *Data Warehousing and OLAP Technology (Data Warehousing)*. International Journal of Engineering Trends and Technology, 51 (1) September, pp. 45–50.

- Khan, S. I., & Sayed, A. (2015). Development of National Health Data Warehouse for Data Mining. *Database Systems Journal*, 3-11.

- Kimball, R. (1998). *The Data Warehouse Lifecycle Toolkit*. New York, Wiley.

- Young, Jacob & Smith, Tyler & Zheng, Shawn. (2020). Call Me BIG PAPA: An Extension of Mason's Information Ethics Framework to Big Data. *2020*, 17-41. 10.17705/3jmwa.000059.

- Leung, C. K., Chen, Y., Hoi, C. S. H., Shang, S. & Cuzzocrea, A. (2020). Machine Learning and OLAP on Big COVID-19 Data. *2020 IEEE International Conference on Big Data (Big Data)*, December.

- Mehmood, H., Gilman, E., Cortes, M., Kostakos, P., Byrne, A., Valta, K., Tekes, S. & Riekki, J. (2019). Implementing Big Data Lake for Heterogeneous Data Sources. *2019 IEEE 35th International Conference on Data Engineering Workshops (ICDEW)*, April.

- Fang, H. (2015). Managing data lakes in big data era: What's a data lake and why has it become popular in data management ecosystem. In *2015 IEEE International Conference on Cyber Technology in Automation, Control, and Intelligent Systems (CYBER)* (pp. 820-824). IEEE.