/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "03 - ����������, CTE, ��������� �������".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
����� WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ��� ���� �������, ��� ��������, �������� ��� �������� ��������:
--  1) ����� ��������� ������
--  2) ����� WITH (��� ����������� ������)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. �������� ����������� (Application.People), ������� �������� ������������ (IsSalesPerson), 
� �� ������� �� ����� ������� 04 ���� 2015 ����. 
������� �� ���������� � ��� ������ ���. 
������� �������� � ������� Sales.Invoices.
*/

-- 1.1
;WITH PersonCTE (personid) AS
(
SELECT SalespersonPersonID FROM Sales.Invoices 
WHERE DAY(InvoiceDate)=4 and MONTH(InvoiceDate)=7 and YEAR(InvoiceDate)=2015
)

SELECT people.PersonID, people.FullName
	FROM  Application.People AS people 
	LEFT JOIN PersonCTE ON people.PersonID=PersonCTE.personid
	where  people.IsSalesperson=1 and PersonCTE.personid is NULL

-- 1.2
SELECT people.PersonID, people.FullName
	FROM  Application.People AS people
	WHERE people.IsSalesperson=1 and people.PersonID not in 
		(SELECT SalespersonPersonID FROM Sales.Invoices 
		WHERE DAY(InvoiceDate)=4 and MONTH(InvoiceDate)=7 and YEAR(InvoiceDate)=2015);


/*
2. �������� ������ � ����������� ����� (�����������). �������� ��� �������� ����������. 
�������: �� ������, ������������ ������, ����.
*/

-- 2.1 CTE MIN
;WITH Minprice (price) AS
(
SELECT MIN(UnitPrice) AS minprice from Warehouse.StockItems
)

SELECT stock.StockItemID, stock.StockItemName, stock.UnitPrice
FROM Warehouse.StockItems AS stock 
JOIN Minprice AS minstock
ON   stock.UnitPrice=minstock.price
ORDER BY stock.StockItemID;

-- 2.2 MIN
SELECT stock.StockItemID, stock.StockItemName, stock.UnitPrice
FROM Warehouse.StockItems AS stock 
JOIN (SELECT MIN(UnitPrice) AS minprice from Warehouse.StockItems) AS minstock
ON   stock.UnitPrice=minstock.minprice
ORDER BY stock.StockItemID;

-- 2.3 ALL
SELECT stock.StockItemID, stock.StockItemName, stock.UnitPrice
FROM Warehouse.StockItems AS stock 
JOIN Purchasing.Suppliers AS suppl ON suppl.SupplierID=stock.SupplierID
where UnitPrice <= ALL (SELECT UnitPrice AS minprice from Warehouse.StockItems si)
ORDER BY stock.StockItemID;


/*
3. �������� ���������� �� ��������, ������� �������� �������� ���� ������������ �������� 
�� Sales.CustomerTransactions. 
����������� ��������� �������� (� ��� ����� � CTE). 
*/

-- 3.1 CTE
;WITH persontop (custname, number, maxamount) AS
(
select CustomerName, PhoneNumber, max(ct.TransactionAmount) AS maxamount
FROM Sales.CustomerTransactions ct
  JOIN  Sales.Customers cust 
  ON ct.CustomerID=cust.CustomerID
WHERE ct.IsFinalized=1 
GROUP BY CustomerName, PhoneNumber
)

SELECT TOP 5
custname, number, maxamount
from persontop
order by maxamount DESC;

-- 3.2 JOIN MAX
select distinct TOP 5
CustomerName, PhoneNumber, maxamount
FROM Sales.CustomerTransactions ct
  JOIN  Sales.Customers cust 
  ON ct.CustomerID=cust.CustomerID
  JOIN (select max(ct.TransactionAmount) AS maxamount, CustomerID from Sales.CustomerTransactions ct group by ct.CustomerID) as maxam
  ON ct.CustomerID=maxam.CustomerID
  order by maxamount DESC;


/*
4. �������� ������ (�� � ��������), � ������� ���� ���������� ������, 
�������� � ������ ����� ������� �������, � ����� ��� ����������, 
������� ����������� �������� ������� (PackedByPersonID).
*/
-- 1 CTE JOIN
;WITH topstock (StockItemID) AS
(SELECT TOP 3 StockItemID FROM Warehouse.StockItems AS stock ORDER BY stock.UnitPrice DESC)

select distinct citi.CityID, citi.CityName,
(select FullName from Application.People where inv.PackedByPersonID=PersonID) AS PackedBy from 
Sales.Invoices AS inv 
	JOIN Sales.InvoiceLines AS lines ON lines.InvoiceID=inv.InvoiceID
	JOIN Sales.Customers AS cust ON inv.CustomerID=cust.CustomerID
	JOIN Application.Cities AS citi ON citi.CityID=cust.PostalCityID
    JOIN topstock ON lines.StockItemID = topstock.StockItemID
order by citi.CityName;

-- 2 IN
select distinct citi.CityID, citi.CityName,
(select FullName from Application.People where inv.PackedByPersonID=PersonID) AS PackedBy from 
Sales.Invoices AS inv 
	JOIN Sales.InvoiceLines AS lines ON lines.InvoiceID=inv.InvoiceID
	JOIN Sales.Customers AS cust ON inv.CustomerID=cust.CustomerID
	JOIN Application.Cities AS citi ON citi.CityID=cust.PostalCityID
where lines.StockItemID IN
(SELECT TOP 3 StockItemID FROM Warehouse.StockItems AS stock ORDER BY stock.UnitPrice DESC)
order by citi.CityName;
-- ---------------------------------------------------------------------------
-- ������������ �������
-- ---------------------------------------------------------------------------
-- ����� ��������� ��� � ������� ��������� ������������� �������, 
-- ��� � � ������� ��������� �����\���������. 
-- �������� ������������������ �������� ����� ����� SET STATISTICS IO, TIME ON. 
-- ���� ������� � ������� ��������, �� ����������� �� (����� � ������� ����� ��������� �����). 
-- �������� ���� ����������� �� ������ �����������. 

-- 5. ���������, ��� ������ � ������������� ������
SET STATISTICS IO ON;  

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,

	SalesTotals.TotalSumm AS TotalSummByInvoice, 

	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems

FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

-- --����������� --

-- ������ ������� ����������� � ������ ������� �� ���� > 27000
-- � ��������� ��������� �������, ���� ������ ���������

WITH SalestotalCTE (InvoiceID, TotalSumm) AS
(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000),

TotalPickedCTE (InvoiceID, TotalSum) AS
(SELECT invoces.InvoiceID,SUM(olines.PickedQuantity*olines.UnitPrice) AS TotalSum
		FROM Sales.OrderLines AS olines 
		JOIN Sales.Orders AS orders ON olines.OrderID=orders.OrderID
		JOIN Sales.Invoices AS invoces ON invoces.OrderID = orders.OrderID
		WHERE orders.PickingCompletedWhen IS NOT NULL
		GROUP BY invoces.InvoiceID)

SELECT distinct
	invoice.InvoiceID, 
	invoice.InvoiceDate,
	People.FullName AS SalesPersonName,
	total.TotalSumm AS TotalSummByInvoice,
	picked.TotalSum AS TotalSummForPickedItems
FROM 
Sales.Invoices AS invoice
JOIN Application.People AS people ON people.PersonID = invoice.SalespersonPersonID
JOIN SalestotalCTE AS total ON invoice.InvoiceID = total.InvoiceID
JOIN TotalPickedCTE AS picked ON picked.InvoiceID = invoice.InvoiceID 
