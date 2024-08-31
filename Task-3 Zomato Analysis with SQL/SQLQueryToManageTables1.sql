use ZomatoAnalysis1;


select * from dbo.zomato;


-- Remove duplicates based on Restaurant_ID
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY Restaurant_ID ORDER BY (SELECT NULL)) AS rn
    FROM dbo.Zomato
)
DELETE FROM CTE
WHERE rn > 1;

-- #output: 0 rows affected

-- Handle null values
UPDATE dbo.Zomato
SET Cuisines = 'Unknown'
WHERE Cuisines IS NULL;

-- #output: 9 rows affected

UPDATE dbo.Zomato
SET Has_Table_booking = 'No'
WHERE Has_Table_booking IS NULL;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Has_Online_delivery = 'No'
WHERE Has_Online_delivery IS NULL;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Is_delivering_now = 'No'
WHERE Is_delivering_now IS NULL;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Switch_to_order_menu = 'No'
WHERE Switch_to_order_menu IS NULL;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Aggregate_rating = 0.0
WHERE Aggregate_rating IS NULL;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Votes = 0
WHERE Votes IS NULL;

-- #output: 0 rows affected

-- Standardize boolean values
UPDATE dbo.Zomato
SET Has_Table_booking = CASE WHEN Has_Table_booking = 'Yes' THEN 1 ELSE 0 END;

-- #output: 9551 rows affected

UPDATE dbo.Zomato
SET Has_Online_delivery = CASE WHEN Has_Online_delivery = 'Yes' THEN 1 ELSE 0 END;

-- #output: 9551 rows affected

UPDATE dbo.Zomato
SET Is_delivering_now = CASE WHEN Is_delivering_now = 'Yes' THEN 1 ELSE 0 END;

-- #output: 9551 rows affected

UPDATE dbo.Zomato
SET Switch_to_order_menu = CASE WHEN Switch_to_order_menu = 'Yes' THEN 1 ELSE 0 END;

-- #output: 9551 rows affected

-- Ensure data integrity for numeric columns
UPDATE dbo.Zomato
SET Average_Cost_for_two = 0
WHERE Average_Cost_for_two < 0;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Price_range = 1
WHERE Price_range < 1 OR Price_range > 4;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Aggregate_rating = 0
WHERE Aggregate_rating < 0 OR Aggregate_rating > 5;

-- #output: 0 rows affected

UPDATE dbo.Zomato
SET Votes = 0
WHERE Votes < 0;

-- #output: 0 rows affected



--Data Validation

-- Ensure no remaining null values
SELECT 
    COUNT(*) AS TotalNulls
FROM dbo.Zomato
WHERE 
    Cuisines IS NULL OR
    Average_Cost_for_two IS NULL OR
    Currency IS NULL OR
    Price_range IS NULL OR
    Aggregate_rating IS NULL OR
    Votes IS NULL;

-- Check if there are any out-of-range values
SELECT 
    COUNT(*) AS OutOfRangePriceRange
FROM dbo.Zomato
WHERE Price_range < 1 OR Price_range > 4;

SELECT 
    COUNT(*) AS OutOfRangeAggregateRating
FROM dbo.Zomato
WHERE Aggregate_rating < 0 OR Aggregate_rating > 5;



SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Zomato';




-- Create Restaurant Table
CREATE TABLE Restaurant (
    Restaurant_ID INT PRIMARY KEY,
    Restaurant_Name VARCHAR(255),
    Country_Code VARCHAR(2),
    City VARCHAR(100),
    Address VARCHAR(255),
    Locality VARCHAR(100),
    Locality_Verbose VARCHAR(255),
    Longitude FLOAT,
    Latitude FLOAT
);

-- Insert data into Restaurant Table
INSERT INTO Restaurant (Restaurant_ID, Restaurant_Name, Country_Code, City, Address, Locality, Locality_Verbose, Longitude, Latitude)
SELECT Restaurant_ID, Restaurant_Name, Country_Code, City, Address, Locality, Locality_Verbose, Longitude, Latitude
FROM dbo.Zomato;

-- Create Cuisine Table
CREATE TABLE Cuisine (
    Cuisine_ID INT PRIMARY KEY,
    Cuisine_Name VARCHAR(255)
);

-- Insert data into Cuisine Table
INSERT INTO Cuisine (Cuisine_Name)
SELECT DISTINCT Cuisines
FROM dbo.Zomato;

-- Create Price Range Table
CREATE TABLE PriceRange (
    Price_Range_ID INT PRIMARY KEY,
    Price_Range INT
);

-- Insert data into Price Range Table
INSERT INTO PriceRange (Price_Range)
SELECT DISTINCT Price_range
FROM dbo.Zomato;

-- Create Rating Table
CREATE TABLE Rating (
    Rating_ID INT PRIMARY KEY,
    Rating_Color VARCHAR(20),
    Rating_Text VARCHAR(50)
);

-- Insert data into Rating Table
INSERT INTO Rating (Rating_Color, Rating_Text)
SELECT DISTINCT Rating_color, Rating_text
FROM dbo.Zomato;

-- Create ZomatoFact Table
CREATE TABLE ZomatoFact (
    ZomatoFact_ID INT PRIMARY KEY,
    Restaurant_ID INT,
    Cuisine_ID INT,
    Price_Range_ID INT,
    Rating_ID INT,
    Average_Cost_for_two INT,
    Currency VARCHAR(3),
    Has_Table_booking BIT,
    Has_Online_delivery BIT,
    Is_delivering_now BIT,
    Switch_to_order_menu BIT,
    Aggregate_rating FLOAT,
    Votes INT,
    FOREIGN KEY (Restaurant_ID) REFERENCES Restaurant(Restaurant_ID),
    FOREIGN KEY (Cuisine_ID) REFERENCES Cuisine(Cuisine_ID),
    FOREIGN KEY (Price_Range_ID) REFERENCES PriceRange(Price_Range_ID),
    FOREIGN KEY (Rating_ID) REFERENCES Rating(Rating_ID)
);
-- Insert data into ZomatoFact Table
INSERT INTO ZomatoFact (
    Restaurant_ID, Cuisine_ID, Price_Range_ID, Rating_ID, 
    Average_Cost_for_two, Currency, Has_Table_booking, Has_Online_delivery, 
    Is_delivering_now, Switch_to_order_menu, Aggregate_rating, Votes
)
SELECT 
    Z.Restaurant_ID,
    COALESCE(C.Cuisine_ID, 0),  -- Handle NULL Cuisine_ID
    COALESCE(P.Price_Range_ID, 0),  -- Handle NULL Price_Range_ID
    COALESCE(R.Rating_ID, 0),  -- Handle NULL Rating_ID
    Z.Average_Cost_for_two,
    Z.Currency,
    CASE WHEN Z.Has_Table_booking = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN Z.Has_Online_delivery = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN Z.Is_delivering_now = 'Yes' THEN 1 ELSE 0 END,
    CASE WHEN Z.Switch_to_order_menu = 'Yes' THEN 1 ELSE 0 END,
    Z.Aggregate_rating,
    Z.Votes
FROM dbo.Zomato Z
LEFT JOIN Cuisine C ON Z.Cuisines = C.Cuisine_Name
LEFT JOIN PriceRange P ON Z.Price_range = P.Price_Range
LEFT JOIN Rating R ON Z.Rating_color = R.Rating_Color AND Z.Rating_text = R.Rating_Text;
