--0. Load Data:

draft = load 'assignment1/part-m-00000' USING PigStorage (',') as (DR_NUMBER:chararray, DATE_REPORTED:chararray, DATE_OCCURED:chararray, TIME_OCCURED:int, AREA_ID:int,AREA_NAME:chararray, REPORTING_DISTRICT:int, CRIME_CODE:int, CRIME_CODE_DESC:chararray, VICTIM_AGE:int, VICTIM_GENDER:chararray, VICTIM_DESCENT:chararray, ADDRESS:chararray, CROSS_STREET:chararray, AUTO_ID:int);

--1. Output1:

--1.1 DateTime format:
draft_output1 = foreach draft generate ToDate(DATE_OCCURED,'MM/dd/yyyy') AS (date:DateTime), DR_NUMBER, AREA_ID, AREA_NAME, ADDRESS, TIME_OCCURED, CRIME_CODE, CRIME_CODE_DESC;

--1.2 Generate YEAR, MONTH, WEEK and DAY_PART:
-- draft_output1_2 = foreach draft_output1 generate GetMonth(date) AS MONTH, GetYear(date) AS YEAR, DR_NUMBER, AREA_ID, AREA_NAME, ADDRESS, (CASE ToString(date,'E') WHEN 'Mon' THEN 'M' WHEN 'Tue' THEN 'T' WHEN 'Wed' THEN 'w' WHEN 'Thu' THEN 'R' WHEN 'Fri' THEN 'F' WHEN 'Sat' THEN 'S' ELSE 'U' END) AS DAY_OF_WEEK, (CASE TIME_OCCURED WHEN 0000 THEN 'MIDNIGHT' WHEN 1200 THEN 'NOON' ELSE (TIME_OCCURED > 1200 ? 'Evening' : 'Morning') END) AS DAY_PART, CRIME_CODE, CRIME_CODE_DESC;

draft_output1_2 = foreach draft_output1 generate GetMonth(date) AS MONTH, GetYear(date) AS YEAR, DR_NUMBER, AREA_ID, AREA_NAME, ADDRESS, (CASE ToString(date,'E') WHEN 'Mon' THEN 'M' WHEN 'Tue' THEN 'T' WHEN 'Wed' THEN 'w' WHEN 'Thu' THEN 'R' WHEN 'Fri' THEN 'F' WHEN 'Sat' THEN 'S' ELSE 'U' END) AS DAY_OF_WEEK, (TIME_OCCURED > 1200 ? 'Evening' : 'Morning') AS DAY_PART, CRIME_CODE, CRIME_CODE_DESC;


--1.3 Generate STREET:

street = FOREACH draft_output1_2 GENERATE DR_NUMBER, ADDRESS AS A;
street1 = FOREACH street GENERATE DR_NUMBER, STRSPLIT(A, '        ',2) AS A;
street2 = FOREACH street1 GENERATE DR_NUMBER, A.$0 AS A, A.$1 AS T;
street3 = FOREACH street2 GENERATE DR_NUMBER, STRSPLIT(A, '  ',2) AS A, T AS T; 
street4 = FOREACH street3 GENERATE DR_NUMBER, (SIZE(A)==1?A.$0:A.$1) AS A, T AS T;
STREET5 = FOREACH street4 GENERATE DR_NUMBER, $1 AS (STREET:chararray), T AS (T:chararray);
STREET6 = FOREACH STREET5 GENERATE DR_NUMBER, (T is null ? STREET : CONCAT(STREET, T)) AS STREET;

street_draft = JOIN draft_output1_2 BY (DR_NUMBER), STREET6 BY (DR_NUMBER) USING 'replicated';


final_draft = FOREACH street_draft GENERATE (draft_output1_2::DR_NUMBER), MONTH, YEAR, AREA_ID, AREA_NAME, STREET, DAY_OF_WEEK, DAY_PART, CRIME_CODE, CRIME_CODE_DESC;

-- 1.4 Group:
group1_1 = GROUP final_draft BY (MONTH, YEAR, AREA_ID, AREA_NAME, STREET, DAY_OF_WEEK, DAY_PART);


group1_2 = GROUP final_draft BY (MONTH, YEAR, AREA_ID, AREA_NAME, STREET, DAY_OF_WEEK, DAY_PART, CRIME_CODE, CRIME_CODE_DESC);


-- 1.5 Count crime_total:
count_crime_total = FOREACH group1_1 GENERATE group, COUNT(final_draft) AS CRIME_TOTAL;
count_crime_total2 = FOREACH count_crime_total GENERATE group.$0, group.$1, group.$2, group.$3, group.$4, group.$5, group.$6, CRIME_TOTAL AS CRIME_TOTAL;

-- 1.6 Count unique_crime_total:
unique_crime_total = foreach group1_2 {
crime_unique = distinct final_draft.CRIME_CODE;
UNIQUE_CRIME_COUNT = COUNT(crime_unique);
GENERATE group.$0, group.$1, group.$2, group.$3, group.$4, group.$5, group.$6, UNIQUE_CRIME_COUNT AS UNIQUE_CRIME_TOTAL;
}

-- 1.7 Count top_crime_count:

count_top_crime = FOREACH group1_2 GENERATE group.$0 AS MONTH, group.$1 AS YEAR, group.$2 AS AREA_ID, group.$3 AS AREA_NAME, group.$4 AS STREET, group.$5 AS DAY_OF_WEEK, group.$6 AS DAY_PART,  group.$7 AS CRIME_CODE, group.$8 AS CRIME_CODE_DESC, COUNT(final_draft) AS unique_crime_number;

count_top_crime2 = GROUP count_top_crime BY ($0, $1, $2, $3, $4, $5, $6);

GET_TOP_CRIME_COUNT = FOREACH count_top_crime2 
{ MAX = MAX(count_top_crime.unique_crime_number);
GENERATE group.$0 AS MONTH, group.$1 AS YEAR, group.$2 AS AREA_ID, group.$3 AS AREA_NAME, group.$4 AS STREET, group.$5 AS DAY_OF_WEEK, group.$6 AS DAY_PART, MAX AS TOP_CRIME_COUNT;
}

-- 1.8 Get final output1:
-- 1.8.1 Get crime_code:

JND_FOR_CRIME_CODE = JOIN count_top_crime BY ($0, $1, $2, $3, $4, $5, $6), GET_TOP_CRIME_COUNT BY ($0, $1, $2, $3, $4, $5, $6);



MODIFIED_JND_FOR_CRIME_CODE = FOREACH JND_FOR_CRIME_CODE GENERATE $0 AS MONTH, $1 AS YEAR, $2 AS AREA_ID, $3 AS AREA_NAME, $4 AS STREET, $5 AS DAY_OF_WEEK, $6 AS DAY_PART, $7 AS CRIME_CODE, $8 AS CRIME_CODE_DESC, $9 AS unique_crime_number, $17 AS TOP_CRIME_COUNT;


GROUPED_JND = GROUP MODIFIED_JND_FOR_CRIME_CODE BY ($0, $1, $2, $3, $4, $5, $6, $7, $8);


MODIFIED_JND_FOR_CRIME_CODE2 = FOREACH GROUPED_JND {
count = FILTER MODIFIED_JND_FOR_CRIME_CODE BY (MODIFIED_JND_FOR_CRIME_CODE.TOP_CRIME_COUNT==MODIFIED_JND_FOR_CRIME_CODE.unique_crime_number);
GENERATE group.$0 AS MONTH, group.$1 AS YEAR, group.$2 AS AREA_ID, group.$3 AS AREA_NAME, group.$4 AS STREET, group.$5 AS DAY_OF_WEEK, group.$6 AS DAY_PART, group.$7 AS CRIME_CODE, group.$8 AS CRIME_CODE_DESC, MODIFIED_JND_FOR_CRIME_CODE.TOP_CRIME_COUNT AS TOP_CRIME_COUNT;
}


TOP_CRIME_COUNT = FOREACH MODIFIED_JND_FOR_CRIME_CODE2 GENERATE MONTH, YEAR, AREA_ID, AREA_NAME, STREET, DAY_OF_WEEK, DAY_PART, CRIME_CODE, CRIME_CODE_DESC, FLATTEN(TOP_CRIME_COUNT) AS TOP_CRIME_COUNT;

-- 1.8.2 join:

JND = JOIN TOP_CRIME_COUNT BY ($0, $1, $2, $3, $4, $5, $6), unique_crime_total BY ($0, $1, $2, $3, $4, $5, $6), count_crime_total2 BY ($0, $1, $2, $3, $4, $5, $6);
DESCRIBE JND;

-- 1.8.3 select needed columns:
final_output1 = FOREACH JND GENERATE $0 AS MONTH, $1 AS YEAR, $2 AS AREA_ID, $3 AS AREA_NAME, $4 AS STREET, $5 AS DAY_OF_WEEK, $6 AS DAY_PART, $17 AS UNIQUE_CRIME_TOTAL, $25 AS CRIME_TOTAL, $7 AS CRIME_CODE, $8 AS CRIME_CODE_DESC, $9 AS TOP_CRIME_COUNT;


STORE final_output1 INTO '/assignment1_pig/output1' USING PigStorage(',');


-- 1.9 Answer 1: 

answer1_group = GROUP final_output1 BY (MONTH, STREET);

answer1_sum = FOREACH answer1_group {
sum = SUM(final_output1.CRIME_TOTAL);
GENERATE group.$0 AS MONTH, group.$1 AS STREET, sum AS crime_amount;}

answer1_group2_2 = GROUP answer1_sum BY MONTH;

answer1_max_2 = FOREACH answer1_group2_2 GENERATE group AS MONTH, MAX(answer1_sum.crime_amount) AS max_amount;

answer1_JOIN_2 = JOIN answer1_max_2 BY (MONTH, max_amount), answer1_sum BY (MONTH, crime_amount);


answer1_2 = FOREACH answer1_JOIN_2 GENERATE answer1_max_2::MONTH AS MONTH, answer1_sum::STREET AS STREET, answer1_max_2::max_amount AS MAX_AMOUNT;

--------------------------------------------------------------------------------------------------

--2. Output2:
--2.1 DateTime format:
draft_output2 = foreach draft generate ToDate(DATE_OCCURED,'MM/dd/yyyy') AS (date:DateTime), VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, TIME_OCCURED, CRIME_CODE, CRIME_CODE_DESC;

--2.2 Generate YEAR, MONTH, WEEK and DAY_PART:
draft_output2_2 = foreach draft_output2 generate GetMonth(date) AS MONTH, GetYear(date) AS YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, (CASE ToString(date,'E') WHEN 'Mon' THEN 'M' WHEN 'Tue' THEN 'T' WHEN 'Wed' THEN 'w' WHEN 'Thu' THEN 'T' WHEN 'Fri' THEN 'F' WHEN 'Sat' THEN 'S' ELSE 'U' END) AS DAY_OF_WEEK, (TIME_OCCURED > 1200 ? 'Evening' : 'Morning') AS DAY_PART, CRIME_CODE, CRIME_CODE_DESC;



--2.3 Group:
group2_1 = GROUP draft_output2_2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART);

group2_2 = GROUP draft_output2_2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART, CRIME_CODE, CRIME_CODE_DESC);
--2.4 Count:
unique_crime_permonth2 = foreach group2_1 {
crime_unique = distinct draft_output2_2.CRIME_CODE;
UNIQUE_CRIME_COUNT = COUNT(crime_unique);
GENERATE FLATTEN(group),  UNIQUE_CRIME_COUNT AS UNIQUE_CRIME_TOTAL;
}


count_percrime_permonth2 = foreach group2_2 {
CRIME_NO = COUNT(draft_output2_2.CRIME_CODE);
generate group.$0 AS MONTH, group.$1 AS YEAR, group.$2 AS VICTIM_GENDER, group.$3 AS VICTIM_DESCENT, group.$4 AS AREA_ID, group.$5 AS AREA_NAME, group.$6 AS DAY_OF_WEEK, group.$7 AS DAY_PART, group.$8 AS CRIME_CODE, group.$9 AS CRIME_CODE_DESC , CRIME_NO AS COUNT_CRIME;
}

count_top_crime2 = GROUP count_percrime_permonth2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART);

count_top_crime2_2 = FOREACH count_top_crime2 {
MAX = MAX(count_percrime_permonth2.COUNT_CRIME);
GENERATE group.$0 AS MONTH, group.$1 AS YEAR, group.$2 AS VICTIM_GENDER, group.$3 AS VICTIM_DESCENT, group.$4 AS AREA_ID, group.$5 AS AREA_NAME, group.$6 AS DAY_OF_WEEK, group.$7 AS DAY_PART, MAX AS TOP_CRIME_COUNT;
}



JND = JOIN count_percrime_permonth2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART), count_top_crime2_2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART) USING 'replicated';



JND_2 =FOREACH JND GENERATE $0 AS MONTH, $1 AS YEAR, $2 AS VICTIM_GENDER, $3 AS VICTIM_DESCENT, $4 AS AREA_ID, $5 AS AREA_NAME, $6 AS DAY_OF_WEEK, $7 AS DAY_PART, $8 AS TOP_CRIME_CODE, $9 AS TOP_CRIME_DESC, $19 AS TOP_CRIME_COUNT;

JND_3 = JOIN JND_2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART), unique_crime_permonth2 BY (MONTH, YEAR, VICTIM_GENDER, VICTIM_DESCENT, AREA_ID, AREA_NAME, DAY_OF_WEEK, DAY_PART);



final_output2 = FOREACH JND_3 GENERATE $0 AS MONTH, $1 AS YEAR, $2 AS VICTIM_GENDER, $3 AS VICTIM_DESCENT, $4 AS AREA_ID, $5 AS AREA_NAME, $6 AS DAY_OF_WEEK, $7 AS DAY_PART, $19 AS UNIQUE_CRIME_TOTAL, $8 AS TOP_CRIME_CODE, $9 AS TOP_CRIME_DESC, $10 AS TOP_CRIME_COUNT;

STORE final_output2 INTO '/assignment1_pig/output2' USING PigStorage(',');

-- 2.5 Answer2:

answer2_group = GROUP final_output2 BY (MONTH, AREA_ID, AREA_NAME);

answer2_getmax = FOREACH answer2_group {
max = MAX(final_output2.UNIQUE_CRIME_TOTAL);
GENERATE group.$0 AS MONTH, group.$1 AS AREA_ID, group.$2 AS AREA_NAME, max AS max1;}

answer2_group2 = GROUP answer2_getmax BY MONTH;

answer2_getmax2 = FOREACH answer2_group2{
max2 = MAX(answer2_getmax.max1);
GENERATE group AS MONTH, max2 AS MAX_UNIQUE_CRIME;}

answer2_join = JOIN answer2_getmax2 BY (MONTH, MAX_UNIQUE_CRIME), answer2_getmax BY (MONTH, max1);


answer2 = FOREACH answer2_join GENERATE answer2_getmax2::MONTH AS MONTH, answer2_getmax::AREA_ID AS AREA_ID, answer2_getmax::AREA_NAME AS AREA_NAME, answer2_getmax2::MAX_UNIQUE_CRIME AS MAX_UNIQUE_CRIME;

---------------------------------------------------------------

--3. Output3:
--3.1 DateTime format:

draft_output3 = foreach draft generate ToDate(DATE_OCCURED,'MM/dd/yyyy') AS (date:DateTime), VICTIM_GENDER, CRIME_CODE, CRIME_CODE_DESC;

--3.2 Generate YEAR, MONTH, WEEK:
draft_output3_2 = foreach draft_output3 generate CRIME_CODE, CRIME_CODE_DESC, GetMonth(date) AS MONTH, GetYear(date) AS YEAR, (CASE ToString(date,'E') WHEN 'Mon' THEN 'M' WHEN 'Tue' THEN 'T' WHEN 'Wed' THEN 'w' WHEN 'Thu' THEN 'T' WHEN 'Fri' THEN 'F' WHEN 'Sat' THEN 'S' ELSE 'U' END) AS DAY_OF_WEEK, VICTIM_GENDER;


--3.3 Group by CRIME_CODE, CRIME_CODE_DESC, MONTH, YEAR, DAY_OF_WEEK:
group3_1 = GROUP draft_output3_2 BY (CRIME_CODE, CRIME_CODE_DESC, MONTH, YEAR, DAY_OF_WEEK);


--3.4 Get the output3:

VICTIM_TOTAL_BY_CRIME = FOREACH group3_1 {
count_f = FILTER draft_output3_2 BY (VICTIM_GENDER=='F');
count_m = FILTER draft_output3_2 BY (VICTIM_GENDER=='M');
GENERATE FLATTEN(group), COUNT(count_m) AS MALE_VICTIM_COUNT, COUNT(count_f) AS FEMALE_VICTIM_COUNT;
}


--3.5 Store:

STORE VICTIM_TOTAL_BY_CRIME INTO '/assignment1_pig/output3' USING PigStorage(',');

-- 3.6 Answer3:

month_total_group = GROUP VICTIM_TOTAL_BY_CRIME BY (group::CRIME_CODE, group::CRIME_CODE_DESC, group::MONTH);

month_total_sum = FOREACH month_total_group{
sum = SUM(VICTIM_TOTAL_BY_CRIME.MALE_VICTIM_COUNT);
GENERATE group.$0 AS CRIME_CODE, group.$1 AS CRIME_CODE_DESC, group.$2 AS MONTH, sum AS MALE_VICTIM_COUNT_SUM;}


MONTH_VICTIM = GROUP month_total_sum BY MONTH;

MAX_MALE = FOREACH MONTH_VICTIM{
MAX = MAX(month_total_sum.MALE_VICTIM_COUNT_SUM);
GENERATE FLATTEN(group) AS MONTH, MAX as MAX;
}

MAX_MALE_JOIN = JOIN MAX_MALE BY (MONTH, MAX), month_total_sum BY (MONTH, MALE_VICTIM_COUNT_SUM);

--MAX_MALE_JOIN: {MAX_MALE::MONTH: int,MAX_MALE::MAX: long,month_total_sum::CRIME_CODE: int,month_total_sum::CRIME_CODE_DESC: chararray,month_total_sum::MONTH: int,month_total_sum::MALE_VICTIM_COUNT_SUM: long}

ANSWER3 = FOREACH MAX_MALE_JOIN GENERATE $0 AS MONTH, $1 AS MAX_MALE_VICTIM_COUNT, $2 AS CRIME_CODE, $3 AS CRIME_CODE_DESC;



