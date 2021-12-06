/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, GROUP BY, HAVING".

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
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
	FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%';

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

SELECT Suppliers.SupplierID, Suppliers.SupplierName 
	FROM Purchasing.Suppliers AS suppliers
	 left join Purchasing.PurchaseOrders AS purchase
on Suppliers.SupplierID = purchase.SupplierID
and purchase.SupplierID is Null;


/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT orders.OrderID, 
 FORMAT(orders.OrderDate, 'dd.MM.yyyy') AS format_date,
 DATENAME(month, orders.OrderDate) AS month_name,
 DATEPART(QUARTER, orders.OrderDate) AS quarter_num,
 CEILING(MONTH(orders.OrderDate)/4.0) AS part_year,
 customers.CustomerName
	FROM Sales.Customers AS customers 
	 join Sales.Orders AS orders on customers.CustomerID = orders.CustomerID 
	 join Sales.OrderLines AS line on orders.OrderID = line.OrderID
	where  orders.PickingCompletedWhen is not NUll and (UnitPrice>100 or Quantity>20) 
 ORDER BY
DATEPART(QUARTER, orders.OrderDate), 
CEILING(MONTH(orders.OrderDate)/4.0),
orders.OrderDate  
OFFSET 1000 ROWS FETCH NEXT 100 ROWS ONLY;

/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT
DeliveryMethodName, 
ExpectedDeliveryDate, 
SupplierName, 
people.FullName
	FROM Purchasing.Suppliers AS suppliers 
   	 join Purchasing.PurchaseOrders AS purchase on suppliers.SupplierID = purchase.SupplierID 
	 join Application.DeliveryMethods AS method on purchase.DeliveryMethodID = method.DeliveryMethodID 
	 join Application.People AS people on purchase.ContactPersonID = people.PersonID
  WHERE 
  MONTH(ExpectedDeliveryDate) = 1 and 
  YEAR(ExpectedDeliveryDate)=2013 and
  DeliveryMethodName in ('Air Freight','Refrigerated Air Freight') and
  purchase.IsOrderFinalized = 1

/*
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
*/

SELECT TOP 10
 OrderID, InvoiceDate, 
 sales.FullName AS SalesPerson, 
 client.FullName AS ClientPerson
	FROM Sales.Invoices AS orders 
	 join Application.People AS sales on orders.SalespersonPersonID = sales.PersonID 
	 join Application.People AS client on orders.ContactPersonID = client.PersonID
ORDER BY InvoiceDate DESC


/*
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

SELECT client.PersonID, client.FullName, client.PhoneNumber
	FROM Application.People AS client 
	 join Sales.Invoices AS orders on client.PersonID = orders.ContactPersonID 
	 join Sales.InvoiceLines AS lines on orders.OrderID = lines.InvoiceID 
	 join Warehouse.StockItems items on lines.StockItemID = items.StockItemID and
	 items.StockItemName = 'Chocolate frogs 250g'

/*
7. ��������� ������� ���� ������, ����� ����� ������� �� �������
�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ������� ���� �� ����� �� ���� �������
* ����� ����� ������ �� �����

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

select 
  YEAR(InvoiceDate) AS year_number,
  MONTH(InvoiceDate) AS month_number,
  AVG(lines.UnitPrice) AS avg_unitprice,
  SUM(lines.UnitPrice*lines.Quantity) AS sum_sales
	from Sales.Invoices AS invoices 
	join Sales.InvoiceLines AS lines on invoices.InvoiceID = lines.InvoiceID
 GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
 ORDER BY MONTH(InvoiceDate), YEAR(InvoiceDate)

/*
8. ���������� ��� ������, ��� ����� ����� ������ ��������� 10 000

�������:
* ��� ������� (��������, 2015)
* ����� ������� (��������, 4)
* ����� ����� ������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/
SELECT 
  YEAR(InvoiceDate) AS year_number,
  MONTH(InvoiceDate) AS month_number,
  SUM(lines.UnitPrice*lines.Quantity) AS sum_sales
	from Sales.Invoices
	join Sales.InvoiceLines AS lines on invoices.InvoiceID = lines.InvoiceID 
 GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
 HAVING(SUM(lines.UnitPrice*lines.Quantity) > 10000)
 ORDER BY month_number,  year_number

/*
9. ������� ����� ������, ���� ������ �������
� ���������� ���������� �� �������, �� �������,
������� ������� ����� 50 �� � �����.
����������� ������ ���� �� ����,  ������, ������.

�������:
* ��� �������
* ����� �������
* ������������ ������
* ����� ������
* ���� ������ �������
* ���������� ����������

������� �������� � ������� Sales.Invoices � ��������� ��������.
*/

SELECT 
  YEAR(InvoiceDate) AS year_number,
  MONTH(InvoiceDate) AS month_number,
  items.StockItemName AS itemname,
  SUM(lines.UnitPrice*lines.Quantity) AS sum_sales,
  start_sales.mindate,
  SUM(lines.Quantity) AS sum_quantity
	from 	
	Sales.Invoices AS invoices
	join Sales.InvoiceLines AS lines on invoices.InvoiceID = lines.InvoiceID 
	join Warehouse.StockItems AS items on lines.StockItemID = items.StockItemID
	
	join 
		(
		select MIN(InvoiceDate) as mindate, lines.StockItemID  as itemid
			from Sales.Invoices 
			join Sales.InvoiceLines as lines on invoices.InvoiceID = lines.InvoiceID 
		group by  lines.StockItemID 
		) as start_sales on start_sales.itemid=lines.StockItemID

	GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate), items.StockItemName, start_sales.mindate
	HAVING SUM(lines.Quantity)<50
	ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate), items.StockItemName 

-- ---------------------------------------------------------------------------
-- �����������
-- ---------------------------------------------------------------------------
/*
�������� ������� 8-9 ���, ����� ���� � �����-�� ������ �� ���� ������,
�� ���� ����� ����� ����������� �� � �����������, �� ��� ���� ����.
*/

-- ---------------------------------------------------------------------------
-- �������
-- ---------------------------------------------------------------------------

/*
  �������� � ����� ����������� ������ ������� � �������� � ������� ������, 
  � ������ ����� � ��� ��������.

VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS range_month(m) left join

����� ������ "���������" � ���� ������� ���� � MSSQL, range(1,12) ��� ��� ���-�� ) ?
����� ��������� ������ �� �����������
*/