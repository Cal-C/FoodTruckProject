-- Make Sure DB is not already being used, Delete DB if it already exsists, kick off other users, 
-- and remake the DB with nothing in it, then begin using it
USE Master;
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'CJIK_FoodTruck')
BEGIN
    ALTER DATABASE CJIK_FoodTruck SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE CJIK_FoodTruck;
END
CREATE DATABASE CJIK_FoodTruck;
USE CJIK_FoodTruck;

-- Create Tables for DB
CREATE TABLE Workers(
	WorkerID int IDENTITY(1,1) PRIMARY KEY,
	LastName varchar(127) NOT NULL,
    FirstName varchar(127) NOT NULL,
    HourlyWage smallmoney NOT NULL
        --Minimum hourly wage is $15
        CONSTRAINT CK_Workers_MinWage CHECK (HourlyWage >= 15.00),
    BeginWorkDate date NOT NULL,
    EndWorkDate date
);

CREATE TABLE Trucks(
    TruckID int IDENTITY(1,1) PRIMARY KEY,
    Name varchar(255) NOT NULL,
    OpenedDate date NOT NULL,
    ClosedDate date
)


CREATE TABLE Shifts(
    ShiftID int IDENTITY(1,1) PRIMARY KEY,
    WorkerID int NOT NULL,
    TruckID int NOT NULL,
    StartDateTime datetime NOT NULL,
    EndDateTime datetime NOT NULL,

    --Ensure that FKs actually point to something
    CONSTRAINT FK_Shifts_Workers
    FOREIGN KEY (WorkerID) REFERENCES Workers(WorkerID),
    CONSTRAINT FK_Shifts_Trucks
    FOREIGN KEY (TruckID) REFERENCES Trucks(TruckID)
);

CREATE TABLE Products(
    ProductID int IDENTITY(1,1) PRIMARY KEY,
    ProductName varchar(127) NOT NULL,
    TruckID int NOT NULL,
    Cost smallmoney NOT NULL,
    Category varchar(31) NOT NULL 
        --Since trucks can only sell Food or Drink
        CONSTRAINT CK_Product_Category 
        CHECK (Category IN ('Food', 'Drink')),
    SoldAfterDate date NOT NULL,
    RetiredOnDate date,

    CONSTRAINT FK_Products_Trucks
    FOREIGN KEY (TruckID) REFERENCES Trucks(TruckID)
);

CREATE TABLE Purchases(
    PurchaseID int IDENTITY(1,1) PRIMARY KEY,
    PurchaseDateTime datetime NOT NULL,
    PaymentMethod varchar(31) NOT NULL
        CONSTRAINT CK_Purchases_Method
        CHECK (PaymentMethod IN ('Debit', 'Credit')),
    SatisfactionRating tinyint,
    TruckID  int NOT NULL,
    CONSTRAINT FK_Purchases_Trucks
    FOREIGN KEY (TruckID) REFERENCES Trucks(TruckID)
)


CREATE TABLE LineItems(
    LineItemID int IDENTITY(1,1) PRIMARY KEY,
    Quantity tinyint NOT NULL,
    --storing Unit Price in case the price of a product changes over time we want to make sure that old financial data remians accurate.
    UnitPrice smallmoney NOT NULL,
    ProductID int NOT NULL,
    PurchaseID int NOT NULL,
    CONSTRAINT FK_LineItems_Products
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT FK_LineItems_Purchases
    FOREIGN KEY (PurchaseID) REFERENCES Purchases(PurchaseID)
)