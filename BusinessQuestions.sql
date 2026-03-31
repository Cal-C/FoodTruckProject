--a) What days and times were the best sales during the week and month?
--i) Best days
SELECT CAST(p.PurchaseDateTime AS date) AS Date, SUM(l.UnitPrice*l.Quantity) AS total
FROM Purchases AS p
LEFT JOIN LineItems AS l
ON p.PurchaseID = l.PurchaseID
GROUP BY CAST(p.PurchaseDateTime AS date)
ORDER BY total DESC;

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


-- rounded to hour
SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 60) AS SaleHour, SUM(l.UnitPrice*l.Quantity) AS total
FROM Purchases AS p
LEFT JOIN LineItems AS l
ON p.PurchaseID = l.PurchaseID
GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 60)
ORDER BY total DESC;

-- rounded to 15 min
SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 15) AS SaleTime, SUM(l.UnitPrice*l.Quantity) AS total
FROM Purchases AS p
LEFT JOIN LineItems AS l
ON p.PurchaseID = l.PurchaseID
GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 15)
ORDER BY total DESC;

-- rounded to 5 min
SELECT dbo.fn_RoundTime(p.PurchaseDateTime, 5) AS SaleTime, SUM(l.UnitPrice*l.Quantity) AS total
FROM Purchases AS p
LEFT JOIN LineItems AS l
ON p.PurchaseID = l.PurchaseID
GROUP BY dbo.fn_RoundTime(p.PurchaseDateTime, 5)
ORDER BY total DESC;

--b) What menu items (food and drink) were the top sellers each day and each week?
--Daily Top Sellers
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

--Weekly Top Sellers
WITH WeeklyRankings AS (
	SELECT YEAR(p.PurchaseDateTime) AS SalesYear, DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek, Products.ProductName,SUM(l.Quantity) AS NumberSold,
		ROW_NUMBER() OVER(PARTITION BY YEAR(p.PurchaseDateTime), 
		DATEPART(WEEK, p.PurchaseDateTime) ORDER BY SUM(l.Quantity) DESC) AS WeeklyRank 
	FROM LineItems AS l
	LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
	LEFT JOIN Products ON Products.ProductID = l.ProductID
	GROUP BY YEAR(p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime), Products.ProductName
)
SELECT SalesYear, SalesWeek, ProductName AS TopSellingItem, NumberSold
FROM WeeklyRankings
WHERE WeeklyRank = 1
ORDER BY SalesYear DESC, SalesWeek DESC;

--c) What was the daily sales revenue for operations? Weekly sales revenue for the operations?
--Daily Revenues
SELECT CAST(p.PurchaseDateTime AS date) AS Date, SUM(l.UnitPrice * l.Quantity) AS TotalSales
FROM LineItems AS l
LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
GROUP BY CAST(p.PurchaseDateTime AS date)
ORDER BY Date DESC;

--Weekly Revenues
SELECT YEAR(p.PurchaseDateTime) AS SalesYear, DATEPART(WEEK, p.PurchaseDateTime) AS SalesWeek, SUM(l.UnitPrice * l.Quantity) AS TotalWeeklySales
FROM LineItems AS l
LEFT JOIN Purchases AS p ON p.PurchaseID = l.PurchaseID
GROUP BY YEAR(p.PurchaseDateTime), DATEPART(WEEK, p.PurchaseDateTime)
ORDER BY SalesYear DESC, SalesWeek DESC;