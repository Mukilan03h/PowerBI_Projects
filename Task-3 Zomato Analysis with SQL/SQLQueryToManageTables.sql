use ZomatoAnalysis1;

WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Restaurant_ID ORDER BY (SELECT NULL)) AS row_num
    FROM dbo.zomato
)
DELETE FROM CTE
WHERE row_num > 1;


--Null Values

UPDATE dbo.zomato
SET City = 'Unknown'
WHERE City IS NULL;

-- Trim spaces from string columns
UPDATE dbo.zomato
SET Restaurant_Name = LTRIM(RTRIM(Restaurant_Name)),
    City = LTRIM(RTRIM(City)),
    Address = LTRIM(RTRIM(Address)),
    Locality = LTRIM(RTRIM(Locality)),
    Locality_Verbose = LTRIM(RTRIM(Locality_Verbose)),
    Cuisines = LTRIM(RTRIM(Cuisines)),
    Currency = LTRIM(RTRIM(Currency)),
    Has_Table_booking = LTRIM(RTRIM(Has_Table_booking)),
    Has_Online_delivery = LTRIM(RTRIM(Has_Online_delivery)),
    Is_delivering_now = LTRIM(RTRIM(Is_delivering_now)),
    Switch_to_order_menu = LTRIM(RTRIM(Switch_to_order_menu)),
    Aggregate_rating = LTRIM(RTRIM(Aggregate_rating)),
    Rating_color = LTRIM(RTRIM(Rating_color)),
    Rating_text = LTRIM(RTRIM(Rating_text));


-- Identifying rows with NULLs in non-NULLable columns
SELECT *
FROM dbo.zomato
WHERE Restaurant_ID IS NULL
   OR Restaurant_Name IS NULL
 
   OR City IS NULL
   OR Address IS NULL
   OR Locality IS NULL
   OR Locality_Verbose IS NULL
   OR Longitude IS NULL
   OR Latitude IS NULL
   OR Average_Cost_for_two IS NULL
   OR Currency IS NULL
   OR Has_Table_booking IS NULL
   OR Has_Online_delivery IS NULL
   OR Is_delivering_now IS NULL
   OR Switch_to_order_menu IS NULL
   OR Price_range IS NULL
   OR Aggregate_rating IS NULL
   OR Rating_color IS NULL
   OR Rating_text IS NULL
   OR Votes IS NULL;

-- Check for invalid values in numeric columns
SELECT *
FROM dbo.zomato
WHERE Longitude < -180 OR Longitude > 180
   OR Latitude < -90 OR Latitude > 90
   OR TRY_CAST(Aggregate_rating AS float) < 0 OR TRY_CAST(Aggregate_rating AS float) > 5
   OR Votes < 0;


select * from dbo.zomato;


ALTER TABLE dbo.zomato
DROP COLUMN Country_Code;

--Creating Restaurant Table

CREATE TABLE dbo.Restaurants (
    Restaurant_ID int PRIMARY KEY,
    Restaurant_Name nvarchar(MAX) NOT NULL,
    Average_Cost_for_two int NOT NULL,
    Currency nvarchar(MAX) NOT NULL,
    Has_Table_booking nvarchar(MAX) NOT NULL,
    Has_Online_delivery nvarchar(MAX) NOT NULL,
    Is_delivering_now nvarchar(MAX) NOT NULL,
    Switch_to_order_menu nvarchar(MAX) NOT NULL,
    Price_range int NOT NULL
);

--Creating Locations Table
CREATE TABLE dbo.Locations (
    Location_ID int IDENTITY(1,1) PRIMARY KEY,
    Restaurant_ID int FOREIGN KEY REFERENCES dbo.Restaurants(Restaurant_ID),
    City nvarchar(MAX) NOT NULL,
    Address nvarchar(MAX) NOT NULL,
    Locality nvarchar(MAX) NOT NULL,
    Locality_Verbose nvarchar(MAX) NOT NULL,
    Longitude decimal(18, 10) NOT NULL,
    Latitude decimal(18, 10) NOT NULL
);



--Creating Cusines Table
CREATE TABLE dbo.Cuisines (
    Cuisine_ID int IDENTITY(1,1) PRIMARY KEY,
    Restaurant_ID int FOREIGN KEY REFERENCES dbo.Restaurants(Restaurant_ID),
    Cuisine nvarchar(MAX) NOT NULL
);


--Creating Ratings Table
CREATE TABLE dbo.Ratings (
    Rating_ID int IDENTITY(1,1) PRIMARY KEY,
    Restaurant_ID int FOREIGN KEY REFERENCES dbo.Restaurants(Restaurant_ID),
    Aggregate_rating nvarchar(MAX) NOT NULL,
    Rating_color nvarchar(MAX) NOT NULL,
    Rating_text nvarchar(MAX) NOT NULL,
    Votes int NOT NULL
);

--Inserting Restaurant Table
INSERT INTO dbo.Restaurants (Restaurant_ID, Restaurant_Name, Average_Cost_for_two, Currency, Has_Table_booking, Has_Online_delivery, Is_delivering_now, Switch_to_order_menu, Price_range)
SELECT DISTINCT Restaurant_ID, Restaurant_Name, Average_Cost_for_two, Currency, Has_Table_booking, Has_Online_delivery, Is_delivering_now, Switch_to_order_menu, Price_range
FROM dbo.zomato;


--Inserting Locations Table
INSERT INTO dbo.Locations (Restaurant_ID, City, Address, Locality, Locality_Verbose, Longitude, Latitude)
SELECT Restaurant_ID, City, Address, Locality, Locality_Verbose, Longitude, Latitude
FROM dbo.zomato;


--Inserting into Cuisines Table
INSERT INTO dbo.Cuisines (Restaurant_ID, Cuisine)
SELECT Restaurant_ID, TRIM(value) AS Cuisine
FROM dbo.zomato
CROSS APPLY STRING_SPLIT(Cuisines, ',');


--Inserting into Ratings Table
INSERT INTO dbo.Ratings (Restaurant_ID, Aggregate_rating, Rating_color, Rating_text, Votes)
SELECT Restaurant_ID, Aggregate_rating, Rating_color, Rating_text, Votes
FROM dbo.zomato;


SELECT TOP 10 *
FROM dbo.Restaurants;

SELECT TOP 10 *
FROM dbo.Locations;

SELECT TOP 10 *
FROM dbo.Cuisines;

SELECT TOP 10 *
FROM dbo.Ratings;


-- Original table row count
SELECT COUNT(*) AS OriginalRowCount
FROM dbo.zomato;

-- New tables row counts
SELECT COUNT(*) AS RestaurantRowCount FROM dbo.Restaurants;
SELECT COUNT(*) AS LocationRowCount FROM dbo.Locations;
SELECT COUNT(*) AS CuisineRowCount FROM dbo.Cuisines;
SELECT COUNT(*) AS RatingRowCount FROM dbo.Ratings;


-- Check cuisine counts in the original table
SELECT Restaurant_ID, COUNT(*) AS CuisineCount
FROM dbo.zomato
CROSS APPLY STRING_SPLIT(Cuisines, ',')
GROUP BY Restaurant_ID;


-- Count cuisines in the new table
SELECT Restaurant_ID, COUNT(*) AS CuisineCount
FROM dbo.Cuisines
GROUP BY Restaurant_ID;

-- Ensure every cuisine has a corresponding restaurant
SELECT c.Restaurant_ID
FROM dbo.Cuisines c
LEFT JOIN dbo.Restaurants r ON c.Restaurant_ID = r.Restaurant_ID
WHERE r.Restaurant_ID IS NULL;

