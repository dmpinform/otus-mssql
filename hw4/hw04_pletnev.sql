/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

SELECT *  FROM
(
  SELECT FORMAT(DATEADD(DAY, 1, EOMONTH(InvoiceDate, -1)),'dd.MM.yyyy') AS InvoiceMonth, 
  REPLACE(REPLACE(cust.CustomerName,'Tailspin Toys (',''),')','') as custname,
  lin.Quantity as Quantity
  FROM Sales.Customers cust 
  JOIN Sales.orders ord ON cust.CustomerID=ord.CustomerID
  JOIN Sales.Invoices inv ON ord.OrderID=inv.OrderID 
  JOIN Sales.InvoiceLines lin ON inv.InvoiceID=lin.InvoiceID
  where cust.CustomerID in (2,3,4,5,6)
) as mt
PIVOT
( 
  SUM(Quantity)
  FOR custname in ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])
) AS pt
order by CAST(InvoiceMonth AS DATE)



/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
select CustomerName, Addres as AddressLine  from
(select  CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
from Sales.Customers cust) as t
UNPIVOT (
Addres for AddressLine in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)
) as unp


/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/
select CountryID, CountryName, Code
from
(
	select CountryID, CountryName, 
	CAST(IsoAlpha3Code AS CHAR) AS IsoAlpha3Code, 
	CAST(IsoNumericCode AS CHAR) AS IsoNumericCode
	from Application.Countries as countries
) as t1
UNPIVOT
(
	Code FOR codeunion in ([IsoAlpha3Code], [IsoNumericCode])
) as piv

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

 SELECT cust.CustomerID, cust.CustomerName as CustName,StockItemID, ca.price, invoicedate
  FROM Sales.Customers cust
  CROSS APPLY(
  select top 2
  lin.UnitPrice as price, ord.CustomerID, lin.StockItemID, max(inv.InvoiceDate) as invoicedate
  FROM Sales.orders ord
  JOIN Sales.Invoices inv ON ord.OrderID=inv.OrderID 
  JOIN Sales.InvoiceLines lin ON inv.InvoiceID=lin.InvoiceID
  where ord.CustomerID = cust.CustomerID
  group by lin.UnitPrice,ord.CustomerID, lin.StockItemID
  order by price DESC,invoicedate
  ) as ca
  order by custname 

