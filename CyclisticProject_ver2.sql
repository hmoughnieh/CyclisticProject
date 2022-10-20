
-------------------------------------------------------------------------------------------
-------------------------------------- Data Cleaning --------------------------------------
-------------------------------------------------------------------------------------------


-------------------------------------- alter data type in 'start_station_id' from float to varchar to match the other datasets --------------------------------------

alter table Nov21
alter column start_station_id varchar(10)

alter table Apr22
alter column start_station_id varchar(10)

alter table Jul22
alter column start_station_id varchar(10)

-------------------------------------- Create a CTE of yearly data by combining all data for all months --------------------------------------

WITH yearly_data as 
(
SELECT *
FROM Cyclistic_202109
UNION all
SELECT *
FROM Cyclistic_202110
UNION all
SELECT *
FROM Cyclistic_202111
UNION all
SELECT *
FROM Cyclistic_202112
UNION all
SELECT *
FROM Cyclistic_202201
UNION all
SELECT *
FROM Cyclistic_202202
UNION all
SELECT *
FROM Cyclistic_202203
UNION all
SELECT *
FROM Cyclistic_202204
UNION all
SELECT *
FROM Cyclistic_202205
UNION all
SELECT *
FROM Cyclistic_202206
UNION all
SELECT *
FROM Cyclistic_202207
UNION all
SELECT *
FROM Cyclistic_202208
),


-------------------------------------- Remove all data points with NULL values --------------------------------------

NULL_cleaned AS
(
	SELECT *
	FROM yearly_data WHERE start_station_name   NOT LIKE '%NULL%'
						AND end_station_name  NOT LIKE '%NULL%'
							AND start_lat  NOT LIKE '%NULL%'
								AND start_lng  NOT LIKE '%NULL%'
									AND end_lat  NOT LIKE '%NULL%'
										AND end_lng NOT LIKE'%NULL%'
											AND start_station_id NOT LIKE'%NULL%'
),


-------------------------------------- Calculate the total ride length in minutes and assign day of the weel names --------------------------------------

aggre_data AS (
	SELECT *,
    DATEDIFF(MINUTE,started_at, ended_at) as TotalMinutes,
    CASE
      WHEN day_of_week = 2 THEN 'Monday'
      WHEN day_of_week = 3 THEN 'Tuesday'
      WHEN day_of_week = 4 THEN 'Wednesday'
      WHEN day_of_week = 5 THEN 'Thursday'
      WHEN day_of_week = 6 THEN 'Friday'
      WHEN day_of_week = 7 THEN 'Saturday'
	  WHEN day_of_week = 1 THEN 'Sunday'
	END
    AS Day_Week
FROM NULL_cleaned
),


-------------------------------------- Retain only ride ids with 16 alphanumerics with ride lengths above 1 minute --------------------------------------

clean_ride_id_data AS
(
	SELECT *
	FROM aggre_data
	WHERE LEN(ride_id) = 16 AND TotalMinutes > 1
),


-------------------------------------- Clean end & start stations names --------------------------------------

Clean_Table AS
(
	SELECT *,
	TRIM(REPLACE
		(REPLACE
			(end_station_name, '(*)',''),
				'(TEMP)','')) as cln_end_station_name,

	TRIM(REPLACE
		(REPLACE
			(start_station_name, '(*)',''),
				'(TEMP)','')) as cln_start_station_name

	FROM clean_ride_id_data
	WHERE end_station_name NOT LIKE '%(LBS-WH-TEST)%' and start_station_name NOT LIKE '%(LBS-WH-TEST)%' 
)

Select *
Into Final_Table
From Clean_Table



---------------------------------------------------------------------------------------------------------
-------------------------------------- Data Exploration & Analysis --------------------------------------
---------------------------------------------------------------------------------------------------------


-------------------------------------- Count the total number of Casual & Members --------------------------------------

Select member_casual as User_type, count(member_casual) as Count
FROM Final_Table
group by member_casual


-------------------------------------- Daily trend of members --------------------------------------

Select cast(started_at as date) as Rides_Date, member_casual as User_type, sum(TotalMinutes)/60 as total_ride
From Final_Table
group by cast(started_at as date), member_casual

-------------------------------------- Daily number of rides by week day --------------------------------------

Select cast(started_at as date) as Rides_Date, member_casual as User_type, count(ride_id) as num_rides
From Final_Table
group by cast(started_at as date), member_casual


-------------------------------------- Most visited stations --------------------------------------

with station_names as
(
select cln_start_station_name + cln_end_station_name as station_name, member_casual
from Final_Table
)

select top 20 station_name, count(station_name) as Count_visits, member_casual as User_type
from station_names
group by station_name, member_casual
order by Count_visits desc


-------------------------------------- Choice of ride by memebrship type --------------------------------------

Select rideable_type, member_casual, COUNT(rideable_type) as count_rideable_type
From Final_table
group by rideable_type, member_casual





















