/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
	FROM Warehouse.StockItems
WHERE StockItemName like '%urgent%' or StockItemName like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT Suppliers.SupplierID, Suppliers.SupplierName 
	FROM Purchasing.Suppliers AS suppliers
	 left join Purchasing.PurchaseOrders AS purchase
on Suppliers.SupplierID = purchase.SupplierID
and purchase.SupplierID is Null;


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
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
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
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
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT client.PersonID, client.FullName, client.PhoneNumber
	FROM Application.People AS client 
	 join Sales.Invoices AS orders on client.PersonID = orders.ContactPersonID 
	 join Sales.InvoiceLines AS lines on orders.OrderID = lines.InvoiceID 
	 join Warehouse.StockItems items on lines.StockItemID = items.StockItemID and
	 items.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
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
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
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
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
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
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

-- ---------------------------------------------------------------------------
-- Решение
-- ---------------------------------------------------------------------------

/*
  Добавить с левым соединением список месяцев и сравнить с месяцем продаж, 
  в идеале нужно и год добавить.

VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS range_month(m) left join

Может объект "календарь" в виде таблицы есть в MSSQL, range(1,12) или еще что-то ) ?
чтобы статичные списки не прописывать
*/