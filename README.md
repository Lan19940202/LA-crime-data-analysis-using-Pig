# LA-crime-data-analysis-using-Pig
Apache Sqoop is a goot tool to move large voluminous of structured data. So, in this project, I used sqoop to import crime data happened in 2016 from MySql to HDFS. The file  'import.sh' contains the sqoop code. (I have changed the real username and password of the server for safety.)
'pig_script.pig' is the file of Pig Latin code. First, I extracted some meaningful information form the original data set which are:
* 1. Extracted street name from address column;
* 2. Convert datetime to month, day, week and daypart;
* 3.
P.S.: All the data I imported occured in 2016
