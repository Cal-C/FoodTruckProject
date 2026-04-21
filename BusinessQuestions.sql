--a) What days and times were the best sales during the week and month?
--i) Best days
--1) By Week
-- including year in grouping/partitioning here in case code is ran over a longer time frame, this is done in future groupings for the same reason
-- year is not included in final select statements as it is not relevant for our current data and junks up final outputs, but could be added by a future analyst as data spans years
WITH WeeklyRankings AS (
    SELECT CAST(p.PurchaseDateTime AS DATE) AS SaleDate, SUM(l.UnitPrice * l.Quantity) AS DailyTotal, DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek,
        ROW_NUMBER() OVER(
            PARTITION BY DATEPART(YEAR, p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime) 
            ORDER BY SUM(l.UnitPrice * l.Quantity) DESC
        ) AS WeeklyRank
    FROM Purchases AS p
    LEFT JOIN LineItems AS l ON p.PurchaseID = l.PurchaseID
    GROUP BY CAST(p.PurchaseDateTime AS DATE), DATEPART(YEAR, p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime)
)
SELECT SalesWeek, SaleDate, DailyTotal
FROM WeeklyRankings
WHERE WeeklyRank = 1
ORDER BY SaleDate;

-- 2) By Month
WITH MonthlyRankings AS (
    SELECT CAST(p.PurchaseDateTime AS DATE) AS SaleDate, SUM(l.UnitPrice * l.Quantity) AS DailyTotal, DATEPART(MONTH, p.PurchaseDateTime) AS SalesMonth,
        ROW_NUMBER() OVER(
            PARTITION BY DATEPART(YEAR, p.PurchaseDateTime), DATEPART(MONTH, p.PurchaseDateTime)
            ORDER BY SUM(l.UnitPrice * l.Quantity) DESC
        ) AS MonthlyRank
    FROM Purchases AS p
    LEFT JOIN LineItems AS l ON p.PurchaseID = l.PurchaseID
    GROUP BY CAST(p.PurchaseDateTime AS DATE), DATEPART(YEAR, p.PurchaseDateTime), DATEPART(MONTH, p.PurchaseDateTime)
)
SELECT SalesMonth, SaleDate, DailyTotal
FROM MonthlyRankings
WHERE MonthlyRank = 1
ORDER BY SaleDate;

--ii)Best Times
--Time Rounding Func
--surrounding func creation and deletion in GOs lets function creation happen by seperating batches
GO
--deleting function if it exsists
DROP FUNCTION IF EXISTS dbo.fn_RoundTime;
GO

CREATE FUNCTION dbo.fn_RoundTime 
(
    @InputTime DATETIME,
    @IntervalMinutes INT
)
RETURNS TIME(0) 
AS
BEGIN
    DECLARE @RoundedTime TIME(0);
    
    SET @RoundedTime = CAST(DATEADD(MINUTE, (DATEDIFF(MINUTE, 0, CAST(@InputTime AS time)) / @IntervalMinutes) * @IntervalMinutes, 0) AS TIME(0));
    
    RETURN @RoundedTime;
END;

GO

--1) Best 15 min sale time by week
WITH WeeklyTimeRankings AS (
    SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 15) AS SaleTime, DATEPART(YEAR, p.PurchaseDateTime) AS SalesYear, DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek, SUM(l.UnitPrice * l.Quantity) AS Total,
        ROW_NUMBER() OVER(
            PARTITION BY DATEPART(YEAR, p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime)
            ORDER BY SUM(l.UnitPrice * l.Quantity) DESC
        ) AS TimeRank
    FROM Purchases AS p
    LEFT JOIN LineItems AS l ON p.PurchaseID = l.PurchaseID
    GROUP BY 
        dbo.fn_RoundTime(p.PurchaseDateTime, 15), 
        DATEPART(YEAR, p.PurchaseDateTime), 
        DATEPART(WEEK, p.PurchaseDateTime)
)
SELECT SalesWeek, SaleTime, Total
FROM WeeklyTimeRankings
WHERE TimeRank = 1
ORDER BY SalesYear, SalesWeek;

--2) Best 15 min sale time by month
WITH MonthlyTimeRankings AS (
    SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 15) AS SaleTime, DATEPART(YEAR, p.PurchaseDateTime) AS SalesYear, DATEPART(MONTH, p.PurchaseDateTime) AS SalesMonth, SUM(l.UnitPrice * l.Quantity) AS Total,
        ROW_NUMBER() OVER(
            PARTITION BY DATEPART(YEAR, p.PurchaseDateTime), DATEPART(MONTH, p.PurchaseDateTime) 
            ORDER BY SUM(l.UnitPrice * l.Quantity) DESC
        ) AS TimeRank
    FROM Purchases AS p
    LEFT JOIN LineItems AS l ON p.PurchaseID = l.PurchaseID
    GROUP BY 
        dbo.fn_RoundTime(p.PurchaseDateTime, 15), 
        DATEPART(YEAR, p.PurchaseDateTime), 
        DATEPART(MONTH, p.PurchaseDateTime)
)
SELECT SalesMonth, SaleTime, Total
FROM MonthlyTimeRankings
WHERE TimeRank = 1
ORDER BY SalesYear, SalesMonth;


--legacy code that identifies the best sale times across different increments, disregarding week or month. This functions similarly to the subqueries in a)ii) but without the rank/partition logic.
-- rounded to hour
--SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 60) AS SaleHour, SUM(l.UnitPrice*l.Quantity) AS total
--FROM Purchases AS p
--LEFT JOIN LineItems AS l
--ON p.PurchaseID = l.PurchaseID
--GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 60)
--ORDER BY total DESC;

-- rounded to 15 min
--SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 15) AS SaleTime, SUM(l.UnitPrice*l.Quantity) AS total
--FROM Purchases AS p
--LEFT JOIN LineItems AS l
--ON p.PurchaseID = l.PurchaseID
--GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 15)
--ORDER BY total DESC;

-- rounded to 5 min
--SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 5) AS SaleTime, SUM(l.UnitPrice*l.Quantity) AS total
--FROM Purchases AS p
--LEFT JOIN LineItems AS l
--ON p.PurchaseID = l.PurchaseID
--GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 5)
--ORDER BY total DESC;

--b) What menu items (food and drink) were the top sellers each day and each week?
--i)Daily Top Sellers
WITH DailyRankings AS (
	SELECT CAST(p.PurchaseDateTime AS date) AS Date, Products.ProductName, SUM(l.Quantity) AS NumberSold,
		ROW_NUMBER() OVER(PARTITION BY CAST(p.PurchaseDateTime AS date) ORDER BY SUM(l.Quantity) DESC) AS DailyRank
	FROM LineItems AS l
	LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
	LEFT JOIN Products ON Products.ProductID = l.ProductID
	GROUP BY CAST(p.PurchaseDateTime AS date), Products.ProductName
)
SELECT Date, ProductName AS TopSellingItem, NumberSold
FROM DailyRankings
WHERE DailyRank = 1
ORDER BY Date DESC;

--ii)Weekly Top Sellers
WITH WeeklyRankings AS (
	SELECT YEAR(p.PurchaseDateTime) AS SalesYear, DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek, Products.ProductName,SUM(l.Quantity) AS NumberSold,
		ROW_NUMBER() OVER(PARTITION BY YEAR(p.PurchaseDateTime), 
		DATEPART(WEEK, p.PurchaseDateTime) ORDER BY SUM(l.Quantity) DESC) AS WeeklyRank 
	FROM LineItems AS l
	LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
	LEFT JOIN Products ON Products.ProductID = l.ProductID
	GROUP BY YEAR(p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime), Products.ProductName
)
SELECT SalesWeek, ProductName AS TopSellingItem, NumberSold
FROM WeeklyRankings
WHERE WeeklyRank = 1
ORDER BY SalesYear DESC, SalesWeek DESC;

--c) What was the daily sales revenue for operations? Weekly sales revenue for the operations?
--i)Daily Revenues
SELECT CAST(p.PurchaseDateTime AS date) AS Date, SUM(l.UnitPrice * l.Quantity) AS TotalSales
FROM LineItems AS l
LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
GROUP BY CAST(p.PurchaseDateTime AS date)
ORDER BY Date DESC;

--ii)Weekly Revenues
SELECT DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek, SUM(l.UnitPrice * l.Quantity) AS TotalWeeklySales
FROM LineItems AS l
LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
GROUP BY YEAR(p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime)
ORDER BY YEAR(p.PurchaseDateTime) DESC, SalesWeek DESC;