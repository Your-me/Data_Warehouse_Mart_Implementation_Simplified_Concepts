# Data_Warehouse_Mart_Implementation_Simplified_Concepts
North and West Yorkshire Clinical Commission Group (INFORMATION SYSTEM) FICTIONAL Concept.

# INTRODUCTION

## North and West Yorkshire Clinical Commission Group (INFORMATION SYSTEM) Concept

North and West Yorkshire Clinical Commission Group (NWYCCG) needs an information system for managing the social and healthcare operations of the medical facilities that they are controlling. They are using six care homes from the Leeds City Council as a test case to produce a system to improve elderly patients' experiences and provide high-quality care recovery period support. A system will be developed to measure:

- **Care home effectiveness** in terms of bed occupancy and the recovery period. As a Business Intelligence consultant, I am expected to implement a system that integrates WYR and NYR health data, as well as the social care case database.
- **Support for doctors and social care services**, where doctors need to see the social care services provided to a patient, and social workers and service providers need to have access to the healthcare record.

As a Business Intelligence Consultant and Data Scientist, based on my previous meeting with NWYCCG and one of the stakeholders (LEEDS CITY COUNCIL HEALTH DEPARTMENT DIRECTOR), not forgetting others who were not present that will be using the information system, I realized the best solution to the current situation is a CENTRALIZED DATABASE SYSTEM and DATA WAREHOUSING system, which fits perfectly for generating decision-making reports.

## DATA WAREHOUSE DESIGN

I used BEAM (Business Event and Analysis Modelling) and CRISP methodology to develop the Kimball Dimensional Data Mart/Warehouse. BEAM ensures the stakeholders are involved in the Data Warehouse development from inception to completion, starting with 7W dimensional questions: Who, What, When, Where, How many, Why, and How; to describe the business events they need to measure (Corr & Stagnitto, 2012). CRISP was used since it is a project about data mining.

The stakeholder is interested in the bed occupancy KPI, as it can help in the strategic decision-making of budget allocation.

Since BEAM and Ralph Kimball's data warehouse design is based on incremental design, or in other words, agile methodology, and considering the trust issues facing the HEALTHCARE SECTOR, the people involved will cooperate when they see the effect of the system being built as soon as possible.

Based on the BED OCCUPANCY KPI, the first DATA MART that will be built will answer questions around the following descriptions or dimensions:

- Total number of occupied beds based on time and Care Centre hierarchy
- Total number of available beds based on time and Care Centre hierarchy
- Bed occupancy rate (occupied bed to ward ratio in percentage) per care center per month.

![Fig_1](/Images/Fig_1.png)

## DATA WAREHOUSE IMPLEMENTATION PLANNING

A design of the proposed Data Warehouse has been presented about seven weeks ago, containing information on what the implementation and development would look like. After carefully observing the existing Online Transactional Processing System in the pioneer regions: North Yorkshire and West Yorkshire, the existing available databases show three care homes per region, making six care homes altogether.

![WYR_script confirmation for loading the data store](/Images/Fig_2.png)

![NYR_script confirmation for loading the data store](/Images/Fig_3.png)

After reviewing the tables available in the two databases, I was able to identify the tables and attributes needed for the current data mart KPI. Based on this, I developed a star schema.

![Initial Star Schema for Bed Occupancy](/Images/Fig_4.png)

After another meeting with NWCCG and the stakeholders, the star schema was revised to address slowly changing dimensions (SCD). The generated report will be used for effective decision-making regarding Care Home Infrastructure. We all agreed to track the capacity of all the wards in the two regions over time. Since future data mining integrity and accuracy need to be ensured, I introduced the concept of BIG PAPA FRAMEWORK guidelines for developing information systems that are ethical (Mason, 1986, as cited in Young et al., 2020), so that service users and the general public can trust the system with their information.

![Revised Star Schema with type 2 SCD](/Images/Fig_5.png)

## DATA WAREHOUSE IMPLEMENTATION DESIGN

Using the Qsee tool, I performed forward engineering of my star schema and imported it into Oracle Apex. This Data Warehouse system will be developed with ORACLE APEX, which is quite popular among the home care centres in the two regions. The lowest granularity of this Star Schema is the ADMISSION DATE. This enables the centralized system to manage some addictive, semi-addictive, and non-additive measurements combined (Kimball, 1998).

The lowest level (grain) of detail will help in aggregating or rolling up some business decision-making.

- **TASK 1: ETL (Extraction, Transform, and Load) Documentation**

  After the forward engineering process, the ETL process followed. Referring back to the flow diagram above, Online Transaction Processing Systems (OLTP) data are usually dirty and sometimes inconsistent, especially when we have collections of multiple data stores that are not all standardized to the same format. As a Data Scientist, it is one of our numerous duties to clean dirty data and avoid the issue of garbage in, garbage out.

  ### EXTRACTION:
  All the needed attributes or columns from each database, consisting of multiple tables, are extracted from the OLTP Data Stores into a Staging Area inside Oracle Apex with several temporary tables. North Yorkshire database attributes needed in the star schema are extracted into a temporary table called SO_NYR_STAGEAREA using multiple join statements. The following attributes are extracted:
  Admission_Date, Bed_Status, Ward_Capacity, Ward_Id, Ward_Name, Care_Centre_Name, Town, and ‘DataSource’ was added for future tracking of attribute sources.

  ![SO NYR STAGEAREA](/Images/Fig_6.png)

  West Yorkshire Database attributes needed in the star schema are extracted into a temporary table called SO_WYR_STAGEAREA using multiple join statements. The following attributes are extracted:
  Admission_Date, Bed_Status, Ward_Capacity, Ward_No, Ward_Name, Care_Centre_Name, Town, and ‘DataSource’ was added for future tracking of attribute sources.
  
  **NOTE**: Ward_No instead of Ward_Id will be used as the “natural” key for tracking the slowly changing dimension attributes, and the values in the Bed_Status attributes are not the same as those in the first table. Transformation will address this.

  ![SO WYR STAGEAREA](/Images/Fig_7.png)

  #### Merging of the Two Tables into One Temporary Table in the Staging Area
  The two tables are merged into a single table. During this process, the Ward_Id from SO_NYR_STAGEAREA was changed to Ward_No based on the attribute name they were loaded into in S1_NWYCCG_STAGEAREA for a seamless transformation process.

- ## TRANSFORMATION

  Data Integrity Issues, Data Quality, Transformation, and Audits are addressed at this stage.

  **Transforming Process 1**

  1. A trigger was created to track any adjustments, such as updates, to data on the S1_NWYCCG_STAGEAREA table.
  2. Cancelled reservations were captured as NULL for admission dates in WYR. To address this issue and track it for future reference, I converted all null values to the date value “01-01-1111” and created a `date_error_log` to store them. This will be noted in the data dictionary as well. After storing them, I ensured future occurrences would be well managed.
  
  ![DATE ERROR LOG](/Images/Fig_8.png)

  3. I addressed the occurrence of null values in any of the attributes I was working with and created a log table called `other_error_log` for this purpose. None were detected for now, but it will keep a record of future occurrences.
  4. I noticed the admission date format was different (e.g., MM-DD-YYYY, DD-MM-YYYY). Using the function `TO_DATE(TO_CHAR(admission_date, 'MM-DD-YYYY'))`, I was able to standardize all admission date formats.
  5. The alphabetical case of the values in Bed_Status was mixed. The same was true for Ward_Name, Care_Centre_Name, and Town. To handle this situation now and in the future, I used the function `UPPER(column_name)` to convert everything to uppercase.
  6. Bed_Status has values “OCCUPIED” and “NOT_OCCUPIED” in NYR and “AVAILABLE” and “OCCUPIED” in WYR. Everything was standardized to “OCCUPIED” and “NOT_OCCUPIED” for the two regions with an update statement, as shown in the table below.

  ![S1_NWYCCG_STAGEAREA for Data quality transformation](/Images/Fig_9.png)

  ### Transformation Process 2: Grouping Admission Date into Hierarchy and Calculating Derived Values for Measurement in fact_table

  1. Admission date was used to derive THE_MONTH & THE_YEAR time dimension attributes using the `TO_CHAR()` function.
  2. TOTAL_OCCUPIED_BEDS measure was derived from Bed_Status occupied values using a `CASE()` function.
  3. After critical observation, the sum of available beds from the table wouldn't give an accurate number of available beds, so subtracting the sum of occupied beds from the ward capacity was used for accuracy.

  **Note**: When using aggregate functions, the "GROUP BY" keyword is used, especially when calculating along hierarchies. "HAVING" is used when there are certain clauses.

  The diagram below shows the output from the transformation.

  ![NWYCCG_STAGEAREA](/Images/Fig_10.png)

  Finally, in the transformation stage, a surrogate key was introduced to give the records a unique key. The table is called S1_NWYCCG_STAGEAREA, just for record purposes or future use.

- ## LOADING

  The forward-engineered tables from the QSEE tool will be loaded at this stage from the transformation staging area temporary table. To handle duplicate records, a temporary table is created for all dimensions tables: one as `temp_Care`, one as `temp_Time`, and one as `temp_Ward`, using `SELECT DISTINCT` to create the temporary table. This also facilitates the introduction of surrogate keys into the dimension table.

  A list of sequences was created to serve this purpose as well, and we have been using SEQUENCE to automatically increment our primary keys, which are unique identifiers from the beginning of this SQL script. Before creating most of our tables, we drop them with cascading constraints to avoid unexpected errors while running our code as a BATCH SCRIPT.

  The images of loaded Dimension tables using the above procedures follow below:

  1. **TIME_DIM**

     ![Loaded Time_DIm from Staging Area](/Images/Fig_11.png)

  2. **CARE_CENTRE_DIM**

     ![Loaded Care_Centre_Dim](/Images/Fig_12.png)

  3. **WARD_DIM**

     The Slowly Changing Dimension. The stakeholders want us to track the history of this dimension. It is a historically significant dimension, and the attribute being monitored over time is the WARD CAPACITY, which at the moment is 20 beds per ward. SCD TYPE 2 is applied. We want to keep a record of every change in the capacity at any given point in time. This type of SCD could grow easily because a new row is added for every change in the value of WARD CAPACITY. I used three flags to track it, namely “valid_from”, “valid_to”, and “current_flag” – with a default value of Y for the current capacity and N if the capacity has changed. The concept I used was to create two scripts. One will run only at the launch of the Data Warehouse System, and the second script will be scheduled for repeated automatic running every 30 days for now, based on stakeholders' requests. For this exercise, I have code that updates the ward capacity of the ICU ward in the second script to test if the code is working.

     ![Combine_DWMA_code-the 1st script.](/Images/Fig_13.png)

     Ran the Script the First Time

     ![Ward DIm Before Updating the ICU value.](/Images/Fig_14.png)

     I will run the second script now. DROP and CREATE WARD statements were commented out. I updated the ICU capacity within the script.

     ![SCD_SCRIPT that will be scheduled to execute every month.](/Images/Fig_15.png)

     Checking the WARD DIM for changes.

     ![Ward_DIm after Type2 SCD was applied](/Images/Fig_16.png)

  4. **The BED OCCUPANCY FACT TABLE**

     A report table was generated based on the lowest granularity level of admission date. The Fact table is made up of the surrogate key called `report_id`, the foreign keys from the dimensions, and the measures that make up the report. Based on the relationship between the Fact table's primary key and the dimensions' foreign keys, the measures can be described by the combination of dimensions or parts of the dimensions. This is based on the concept of Additive, Semi-Additive, or Non-Additive measures. A sample of the fact table is displayed below.

     ![SS_Bed_Occupancy_fact](/Images/Fig_17.png)

  5. **VIEW bed_occupancy_report_v**

     A view was created based on a query to select all the records in the fact table. These records will be downloaded as Excel and used for the Online Analytical Processing Report or Decision Support System. A sample is shown below.

     ![Bed_occupancy_report_v VIEW.](/Images/Fig_18.png)

# OLAP (ONLINE ANALYTICS PROCESSING SYSTEM Using Oracle View Report and Excel Dashboard)

Online analytical processing and data warehousing are two important factors used together in decision support systems, and it is one of the most popular combinations in Business Intelligence for effective support systems (Jaroli & Masson, 2017). Due to the nature of the reports generated from Online Transactional Processing systems and the effect the final decision could have on a business or its users, the online transaction processing system cannot handle it effectively. Since OLTP systems help manage the day-to-day operations of the business, OLAP systems dig deeper into historical information that can be generated from the use of data collected by OLTP systems.

Leung et al. (2020) discussed big data, machine learning, and healthcare, and they concluded that knowledge gained from epidemiological data using data science methods such as machine learning, data mining, and online analytical processing has helped researchers, epidemiologists, and executives make strategic moves to gain an understanding of several diseases and has led them to ways of mitigating, managing, and preventing many diseases. The predictability and prescriptive abilities possessed by the field of data science are very positive, although we cannot forget about the ethical issues that accompany it.

After generating the report from the Fact table in the Bed Occupancy Data Mart from the Dimensional warehouse produced using the Ralph Kimball approach, the flow diagram above shows that this is the back end. The front end is what OLAP systems provide, and I am using the PIVOT table in Microsoft Excel for this project.

One important thing to note is that correlation does not mean causation, so when data mining is done on available data, more effort should be put into understanding causation and not just correlation.

![Report Generated from the Fact_table Query View in Oracle Apex.](/Images/Fig_19.png)

# DASHBOARD PRODUCED FROM OLAP

![SIMPLIFIED OLAP DASHBOARD](/Images/Fig_20.png)

## OBSERVATIONS FROM THE DASHBOARD

- The bed occupancy rate at LBU Care Home is the highest despite the fact that it is a Care Home that only started its operation in 2023, according to the visualization from the generated data.
- Followed by WELL BEING CARE HOME. BEWAN and ALTRON CARE HOME have the lowest occupancy rates, even though Bewan has been in operation longer than Altron. The Leeds City Health Director would want to know why Bewan has been under-utilized.
- The Fourth Quarter is usually the season with the highest patronage in most of the care homes. That visualization gives the decision-makers some insight into the next strategic decision.

## REFLECTION ON CASE STUDY DEVELOPMENT APPROACH

According to Khan and Sayed (2015), the application of health informatics has seen exceptional acceptance in areas of healthcare management, diagnosis, clinical care, pharmacy, nursing, and public health. Health Informatics can be defined as the incorporation and automation of healthcare services with the engagement of information systems by information technology professionals like data scientists, software developers, cloud solution architects, and many others. It helps manage resources and employ methods to improve the collection, storage, and business intelligence reports in medical research (Khan & Sayed, 2015). It is no longer news in the current era of big data that the data available as a result of technological advancement is coming in rapidly, in various forms, in huge amounts, and all other characteristics of big data are undeniable. North and West Yorkshire Clinical Commission Group would want to benefit from the advancement in technology as well to help in decision-making.

The best solution to the current situation is a CENTRALIZED DATABASE SYSTEM and DATA WAREHOUSING system, which fits perfectly for generating a decision-making system. RALPH KIMBALL DATA MART BUS ARCHITECTURE WITH LINKED DIMENSIONAL DATAMART ARCHITECTURE. With the current OLTP database used, a 2-Tier Architecture will be used for now, and as more data marts are added to the central data warehouse, middleware will be introduced, and the architecture will be upgraded to a three-tier architecture. Hub and Spoke Architecture by Bill Inmon will take a longer time to be implemented, and users preferred a system they are fully involved in. So with the combination of CRISP and BEAM methodology, the stakeholders will be carried along using the 7W’s (questions) as stated above during the design stage (Corr & Stagnitto, 2012). Agile methodology towards the development of smaller units of a bigger project, user and stakeholder-oriented.

A Data Lake is a system for gathering unstructured, semi-structured, or sometimes structured data that have no current use or recognition within an organization or enterprise. This is done using low-cost technologies that aid in the extraction, cleaning, transforming, and loading of the data into an archive. The main purpose of a Data Lake is to provide a cost-effective solution for storing large volumes of data that may or may not have immediate value to the organization (Fang, 2015).

Once data is available, it is placed into the Data Lake in its original format and is available to everyone in the enterprise for analysis. It helps save the cost of loading data into subject area data marts (Fang, 2015). This method simply uses Extract, Load, and Transform (ELT). Additionally, many cloud service providers are offering this at a cheaper rate.

According to a recent study, utilizing a data lake approach with Big Data technologies is recommended to gather data for analysis. The platform described here facilitates the collection, storage, integration, and analysis of data, as well as the visualization of results.

Combining data from a wide range of data sources is an effective solution in data mining because it is believed that the bigger the data, the easier it can generate a pattern (Mehmood et al., 2019). Most times, this leads to a bigger bias in data because every dataset has its own inconsistencies. Merging multiple datasets multiplies the level of inconsistency. Analysis of data leads to statistically proven results and works well for prediction and prescription purposes. It will also aid data mining purposes for the care centre when they start gaining trust from users with the type of data provided.

Fang (2015) concluded that the combination of Data Warehouse and Data Lake is the best solution for companies and enterprises dealing with Big Data. Having structured historical data is important for some business decisions.

Users' privacy needs to be considered while developing a centralized solution. Due to this ethical issue, I suggested the use of the Big Papa Framework guidelines for developing the Business Intelligence system. Big-Papa stands for Behavioural Surveillance, Interpretation and Governance, Privacy, Accuracy, Property, and Accessibility. All these factors are to be considered in the health sector because of the type of data involved. I suggested that all the users involved be informed and a user consent form be provided. For the available data, we will enforce the highest authentication level. Only accountable and responsible users will be given access to the system, and individual users' views will be based on their level of privilege.

As a Data Scientist, I tried my best not to allow my subjectivity to cloud my judgement or design, and I work towards objectivity. I now know that bigger data is not always better, although this is a debatable opinion.

## References

- Corr, L., & Stagnitto, J. (2012). *Agile Data Warehouse Design*. Leeds: DecisionOne Press.

- Jaroli, P. & Masson, P. (2017). *Data Warehousing and OLAP Technology (Data Warehousing)*. International Journal of Engineering Trends and Technology, 51 (1) September, pp. 45–50.

- Khan, S. I., & Sayed, A. (2015). Development of National Health Data Warehouse for Data Mining. *Database Systems Journal*, 3-11.

- Kimball, R. (1998). *The Data Warehouse Lifecycle Toolkit*. New York, Wiley.

- Young, Jacob & Smith, Tyler & Zheng, Shawn. (2020). Call Me BIG PAPA: An Extension of Mason's Information Ethics Framework to Big Data. *2020*, 17-41. 10.17705/3jmwa.000059.

- Leung, C. K., Chen, Y., Hoi, C. S. H., Shang, S. & Cuzzocrea, A. (2020). Machine Learning and OLAP on Big COVID-19 Data. *2020 IEEE International Conference on Big Data (Big Data)*, December.

- Mehmood, H., Gilman, E., Cortes, M., Kostakos, P., Byrne, A., Valta, K., Tekes, S. & Riekki, J. (2019). Implementing Big Data Lake for Heterogeneous Data Sources. *2019 IEEE 35th International Conference on Data Engineering Workshops (ICDEW)*, April.

- Fang, H. (2015). Managing data lakes in big data era: What's a data lake and why has it become popular in data management ecosystems. In *2015 IEEE International Conference on Cyber Technology in Automation, Control, and Intelligent Systems (CYBER)* (pp. 820-824). IEEE.
```
