CREATE DATABASE SupplyManagement;

Use SupplyManagement;

----CREATE CUSTOMER TABLE--------------------

CREATE TABLE Customer(
CustomerID INT PRIMARY KEY,
CustomerName varchar(50) NOT NULL,
City varchar(50) NOT NULL);

----CREATE TABLE ORDER------------------------

CREATE TABLE Orders(
OrderID INT PRIMARY KEY,
CustomerID INT NOT NULL,
OrderDate DATE NOT NULL,
Amount DECIMAL(10,2) NOT NULL,
FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) );

--------CREATE TABLE PRODUCT-------------------------

CREATE TABLE Product
(ProductID INT PRIMARY KEY,
ProductName VARCHAR(50) NOT NULL,
Category VARCHAR(50) NOT NULL,
Price DECIMAL(10,2) NOT NULL );

--------CREATE TABLE ORDER ITEM--------------------------

CREATE TABLE OrderItem
( OrderID INT NOT NULL,
ProductID INT NOT NULL,
Quantity INT NOT NULL,
UnitPrice DECIMAL(10,2) NOT NULL,
FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
FOREIGN KEY (ProductID) REFERENCES Product(ProductID) );

-------------------DATA INSERTION-------------------------------------------------

------------Insert Data into Customer Table---------------------------------------

INSERT INTO Customer (CustomerID, CustomerName, City)
VALUES (1, 'John Doe', 'New York'),
(2, 'Jane Smith', 'Los Angeles'),
(3, 'Michael Lee', 'Chicago'),
(4, 'Alice Johnson', 'Seattle'),
(5, 'David Miller', 'Houston'),
(6, 'Emily Garcia', 'Miami');



------------Insert Data into Order Table-----------------------------------------------

INSERT INTO Orders(OrderID, CustomerID, OrderDate, Amount)
VALUES (1, 1, '2023-10-25', 100.00),
(2, 2, '2023-11-10', 150.00),
(3, 1, '2023-11-15', 200.00),
(4, 3, '2023-11-20', 350.00),
(5, 4, '2023-11-25', 220.00),
(6, 5, '2023-12-01', 180.00),
(7, 2, '2023-12-05', 80.00);----------------Insert Data into Product Table------------------------------

INSERT INTO Product (ProductID, ProductName, Category, Price)
VALUES (1, 'Shirt', 'Clothing', 20.00),
(2, 'Pants', 'Clothing', 30.00),
(3, 'Laptop', 'Electronics', 500.00),
(4, 'Headphones', 'Electronics', 100.00),
(5, 'Book', 'Stationery', 15.00),
(6, 'Pen', 'Stationery', 2.00),
(7, 'Mouse', 'Electronics', 40.00);


-------------Insert Data into OrderItem -----------------------------

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice)
VALUES (1, 1, 2, 20.00),
(1, 2, 1, 30.00),
(2, 3, 1, 500.00),
(3, 4, 2, 100.00),
(4, 1, 3, 20.00),
(4, 3, 2, 500.00),
(5, 2, 4, 30.00),
(5, 5, 10, 15.00),
(6, 4, 3, 100.00),(6, 6, 20, 2.00),
(7, 3, 1, 500.00),
(7, 7, 2, 40.00);--------------------------SQL Subqueries-----------------------------------------------

--------- ----Find all customers who placed an order with a total amount exceeding the average order amount-------------------

SELECT c.CustomerID,c.CustomerName,o.Amount
FROM Customer c,Orders o
WHERE o.Amount > (SELECT AVG(o.Amount) FROM orders o);


--------------List all products with a total quantity sold greater than 10 across all orders----------------------------------

SELECT p.ProductID,p.ProductName,oi.Quantity
FROM Product p,orderItem oi
WHERE oi.Quantity > 10;



--------------Retrieve the names of cities with customers who have placed orders containing at least two different categories of products------SELECT DISTINCT c.City
FROM Customer c
JOIN OrderItem oi ON c.CustomerID = oi.OrderID
JOIN Product p ON oi.ProductID = p.ProductID
WHERE c.CustomerID IN (
    SELECT oi.OrderID
    FROM OrderItem oi
    JOIN Product p ON oi.ProductID = p.ProductID
    GROUP BY oi.OrderID
    HAVING COUNT(DISTINCT p.Category) >= 2
);-------------Find the top 2 customers (by total order amount) from each city--------------------------
With CustomerOrderTotals as(
SELECT
c.CustomerID,c.CustomerName,c.City,sum(o.Amount) as totalOrderAmount,
Row_number() over (Partition by c.city order by sum(o.Amount) DESC) AS RowNum
FROM Customer c 
JOIN Orders o on
c.CustomerID = o.CustomerID
GROUP BY c.CustomerID,c.CustomerName,c.City
)
Select City,CustomerID,CustomerName,
totalOrderAmount
from CustomerOrderTotals
where RowNum <=2
Order by city,totalOrderAmount Desc;


-------------------Calculate the total revenue generated from each product category-----------------------

-- Step 1: Calculate the average price of a laptop
WITH LaptopAverage AS (
    SELECT AVG(Price) AS AvgLaptopPrice
    FROM Product
    WHERE ProductName = 'Laptop'
),
-- Step 2: Calculate the total order amount for each order
OrderTotals AS (
    SELECT 
        o.OrderID,
        SUM(oi.Quantity * oi.UnitPrice) AS TotalOrderAmount
    FROM Orders o
    JOIN OrderItem oi ON o.OrderID = oi.OrderID
    GROUP BY o.OrderID
)
-- Step 3: Find orders where the total order amount is less than the average laptop price
SELECT 
    ot.OrderID,
    ot.TotalOrderAmount
FROM OrderTotals ot
CROSS JOIN LaptopAverage la
WHERE ot.TotalOrderAmount < la.AvgLaptopPrice;



-------Find the customer who has placed the most orders--------


SELECT Top 1 c.CustomerID,c.CustomerName,Count(OrderId) as TotalOrderPlaced
 from Customer c
 JOIN Orders o
 on c.CustomerID= o.CustomerID
 GROUP BY c.CustomerID,c.CustomerName
 ORDER BY TotalOrderPlaced DESC;


-------------Identify the product(s) in each order that contributes to the highest total order amount------------------WITH ProductContribution AS (
    SELECT 
        oi.OrderID,
        p.ProductID,
        p.ProductName,
        p.Category,
        (oi.Quantity * oi.UnitPrice) AS ContributionAmount,
        RANK() OVER (PARTITION BY oi.OrderID ORDER BY (oi.Quantity * oi.UnitPrice) DESC) AS RankInOrder
    FROM OrderItem oi
    JOIN Product p ON oi.ProductID = p.ProductID
)
SELECT 
    OrderID,
    ProductID,
    ProductName,
    Category,
    ContributionAmount
FROM ProductContribution
WHERE RankInOrder = 1
ORDER BY OrderID;

