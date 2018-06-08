# LA-crime-data-analysis-using-Pig
Apache Sqoop is a goot tool to move large voluminous of structured data. So, in this project, I used sqoop to import crime data happened in 2016 from MySql to HDFS. The file [import.sh](https://github.com/Lanwei02/LA-crime-data-analysis-using-Pig/blob/master/import.sh) contains the sqoop code. (I have changed the real username and password of the server for safety.)

[pig_script.pig](https://github.com/Lanwei02/LA-crime-data-analysis-using-Pig/blob/master/pig_script.pig) is the file of Pig Latin code. Before analyzing, I extracted street name from address column and converted datetime to month, day, week and daypart.
P.S.: All the data I imported occured in 2016
