Create database NYPD_Motor_Vehicle_Collisions
Use NYPD_Motor_Vehicle_Collisions

Select * from dbo.Collisions






--Data Cleaning

--1. Handling NULLs and Missing Values

DELETE FROM Collisions 
WHERE crash_date IS NULL 
   OR latitude IS NULL 
   OR longitude IS NULL
   OR ZIPCODE is null;

UPDATE Collisions 
SET ON_STREET_NAME = 'UNSPECIFIED' 
WHERE ON_STREET_NAME IS NULL;

UPDATE Collisions 
SET VEHICLE_TYPE_CODE_1 = 'Unspecified' 
WHERE VEHICLE_TYPE_CODE_1 IS NULL;

--2. Standardizing Text Fields (Case, Spelling, Whitespace)

UPDATE collisions
SET borough = UPPER(LTRIM(RTRIM(borough)));

UPDATE collisions
SET [CONTRIBUTING_FACTOR_VEHICLE _1] = UPPER(TRIM([CONTRIBUTING_FACTOR_VEHICLE _1]));

UPDATE collisions
SET [VEHICLE_TYPE_CODE_1] = UPPER(TRIM([VEHICLE_TYPE_CODE_1]));

--3.Creating a Combined DateTime Column

--ALTER TABLE collisions
--ADD crash_datetime AS 
--    CONVERT(DATETIME, CONVERT(CHAR(10), crash_date, 112) + ' ' + crash_time) PERSISTED;

--UPDATE collisions SET crash_datetime = CONVERT(datetime, crash_date) + CAST(crash_time AS datetime)

ALTER TABLE collisions
ADD crash_datetime DATETIME;

UPDATE collisions
SET crash_datetime = 
    CAST(crash_date AS DATETIME) + CAST(crash_time AS DATETIME);

--4. Removing Clearly Invalid Rows

DELETE FROM collisions 
WHERE crash_datetime > GETDATE();

-- Removing impossible coordinates (NYC’s latitude ~40.7, longitude ~-74.0). Based on known NYC bounds
DELETE FROM collisions
WHERE latitude < 40.0 OR latitude > 42.0 
   OR longitude < -75.0 OR longitude > -73.0;


--6. Checking for duplicates and using Collision_id since its unique

WITH CTE AS (
  SELECT collision_id,
         ROW_NUMBER() OVER (PARTITION BY collision_id 
                            ORDER BY crash_datetime) AS rn
  FROM collisions
)
DELETE c
FROM collisions AS c
JOIN CTE ON c.collision_id = CTE.collision_id
WHERE CTE.rn > 1;

--7. Creating Indexes for Performance

--i
CREATE NONCLUSTERED INDEX idx_collisions_crashdatetime
ON collisions (crash_datetime);

--ii
CREATE NONCLUSTERED INDEX idx_collisions_borough
ON collisions (borough);

--iii
--Verifying
EXEC sp_helpindex 'collisions';












--Results (Analysis and Findings) (Pages 13–28)

--1. Collision Trends Over Time

SELECT 
  YEAR(crash_date) AS [Year],
  COUNT(*) AS CrashCount
FROM collisions
GROUP BY YEAR(crash_date)
ORDER BY Year desc;

--Indicating how crashes grew annually as percentage

-- “Data from years prior to 2017 was sparse and incomplete. Therefore, analysis of collision trends focuses on the 2017–2024 range, where NYPD reporting is more consistent.”

WITH yearly AS (
  SELECT 
    YEAR(crash_date) AS [Year], 
    COUNT(*) AS CrashCount
  FROM collisions
  WHERE YEAR(crash_date) >= 2017  -- Filter out noisy early years
  GROUP BY YEAR(crash_date)
)
SELECT 
  [Year], 
  CrashCount,
  LAG(CrashCount) OVER (ORDER BY [Year]) AS PrevYearCount,
  ROUND(
    100.0 * (CrashCount - LAG(CrashCount) OVER (ORDER BY [Year])) 
    / NULLIF(LAG(CrashCount) OVER (ORDER BY [Year]), 0), 1
  ) AS PctChange
FROM yearly
ORDER BY [Year];


--2. Spatial Distribution by Borough (Pages 16–18)

SELECT 
  borough,
  COUNT(*) AS CrashCount
FROM collisions
GROUP BY borough
ORDER BY CrashCount DESC;


--3. Time of Day and Day of Week Analysis (Pages 19–21)

SELECT 
  DATEPART(HOUR, crash_time) AS HourOfDay,
  COUNT(*) AS CrashCount
FROM collisions
GROUP BY DATEPART(HOUR, crash_time)
ORDER BY HourOfDay;

--Examining weekdays vs weekends:

SELECT 
  CASE 
    WHEN DATEPART(WEEKDAY, crash_date) IN (1, 7) THEN 'Weekend' 
    ELSE 'Weekday' 
  END AS DayType,
  COUNT(*) AS CrashCount
FROM collisions
GROUP BY 
  CASE 
    WHEN DATEPART(WEEKDAY, crash_date) IN (1, 7) THEN 'Weekend' 
    ELSE 'Weekday' 
  END
ORDER BY DayType;


--With Full day Names
WITH DaySummary AS (
  SELECT 
    DATENAME(WEEKDAY, crash_date) AS DayName,
    DATEPART(WEEKDAY, crash_date) AS DayNumber,
    COUNT(*) AS CrashCount
  FROM collisions
  GROUP BY 
    DATENAME(WEEKDAY, crash_date),
    DATEPART(WEEKDAY, crash_date)
)
SELECT DayName, CrashCount
FROM DaySummary
ORDER BY DayNumber;



--4. Severity: Injuries and Fatalities (Pages 22–24)

SELECT 
  borough,
  SUM([NUMBER_OF_PERSONS _INJURED]) AS TotalInjuries,
  SUM(number_of_persons_killed)  AS TotalKilled
FROM collisions
GROUP BY borough
ORDER BY TotalInjuries DESC;

-- Percentages of crashes that involved a fatality.
SELECT 
  borough,
  COUNT(*) AS CrashCount,
  SUM(CASE WHEN number_of_persons_killed > 0 THEN 1 ELSE 0 END) AS FatalCount,
  ROUND(100.0 * SUM(CASE WHEN number_of_persons_killed > 0 THEN 1 ELSE 0 END) / COUNT(*),1) AS FatalityRatePct
FROM collisions
GROUP BY borough;



--5. Contributing Factors (Pages 25–27)

SELECT TOP 10 
  [CONTRIBUTING_FACTOR_VEHICLE _1] AS Factor,
  COUNT(*) AS CrashCount
FROM collisions
GROUP BY [CONTRIBUTING_FACTOR_VEHICLE _1]
ORDER BY CrashCount DESC;

--Ranking Contributing factors in Each Borough

SELECT Borough, Factor, CrashCount, Rank
FROM (
  SELECT 
    borough AS Borough,
    [CONTRIBUTING_FACTOR_VEHICLE _1] AS Factor,
    COUNT(*) AS CrashCount,
    RANK() OVER (PARTITION BY borough ORDER BY COUNT(*) DESC) AS Rank
  FROM collisions
  GROUP BY borough, [CONTRIBUTING_FACTOR_VEHICLE _1]
) sub
WHERE Rank <= 3
ORDER BY Borough, Rank;


--6. Analysis of weather effects: e.g., comparing crash counts on rainy days vs. clear days by borough.

-- Creating a Weather Table to Join with Collisions

CREATE TABLE weather_data (
    [date] DATE PRIMARY KEY,
    weather VARCHAR(50),           -- e.g., 'Clear', 'Rain', 'Snow'
    temperature DECIMAL(5,2),      -- in Celsius or Fahrenheit
    precipitation DECIMAL(5,2),    -- in mm or inches
    wind_speed DECIMAL(5,2)        -- in km/h or mph
);

--Importing data instead as excell file

Select * from weather_data

--Total crashes by borough and weather type

SELECT 
  c.borough,
  w.weather,
  COUNT(*) AS CrashCount
FROM collisions c
JOIN weather_data w
  ON c.crash_date = w.date
GROUP BY c.borough, w.weather
ORDER BY c.borough, CrashCount DESC;

