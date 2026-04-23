USE CJIK_FoodTruck;
Go

--a) What days and times were the best sales during the week and month?
--i) Best days
--1) By Week
SELECT 
    DATENAME(WEEKDAY, PurchaseDateTime) AS DayOfWeek,
    COUNT(*) AS TotalSales,
    SUM(LineItems.Quantity * LineItems.UnitPrice) AS Revenue
FROM Purchases
JOIN LineItems ON Purchases.PurchaseID = LineItems.PurchaseID
GROUP BY DATENAME(WEEKDAY, PurchaseDateTime)
ORDER BY Revenue DESC;

SELECT 
    DATEPART(HOUR, PurchaseDateTime) AS HourOfDay,
    COUNT(*) AS TotalSales,
    SUM(LineItems.Quantity * LineItems.UnitPrice) AS Revenue
FROM Purchases
JOIN LineItems ON Purchases.PurchaseID = LineItems.PurchaseID
GROUP BY DATEPART(HOUR, PurchaseDateTime)
ORDER BY Revenue DESC;

SELECT 
    DAY(PurchaseDateTime) AS DayOfMonth,
    COUNT(*) AS TotalSales,
    SUM(LineItems.Quantity * LineItems.UnitPrice) AS Revenue
FROM Purchases
JOIN LineItems ON Purchases.PurchaseID = LineItems.PurchaseID
GROUP BY DAY(PurchaseDateTime)
ORDER BY Revenue DESC;

SELECT 
    DATENAME(MONTH, PurchaseDateTime) AS MonthName,
    SUM(LineItems.Quantity * LineItems.UnitPrice) AS TotalRevenue
FROM Purchases
JOIN LineItems ON Purchases.PurchaseID = LineItems.PurchaseID
GROUP BY DATENAME(MONTH, PurchaseDateTime)
ORDER BY TotalRevenue DESC;

