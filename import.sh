sqoop import \
--connect jdbc:mysql://fordbuan6346.caog2tqbzzhd.us-west-2.rds.amazonaws.com/buan6346 \
--driver com.mysql.jdbc.Driver \
--username xxxx \
--password xxxx \
-m 1 \
--table la_crime \
--columns "DR_NUMBER,DATE_REPORTED,DATE_OCCURED,TIME_OCCURED,AREA_ID,AREA_NAME,REPORTING_DISTRICT,CRIME_CODE,CRIME_CODE_DESC,VICTIM_AGE,VICTIM_GENDER,VICTIM_DESCENT,ADDRESS,CROSS_STREET,AUTO_ID" \
--where "DATE_OCCURED like '%2016%'" \
--target-dir /user/root/assignment1 \

