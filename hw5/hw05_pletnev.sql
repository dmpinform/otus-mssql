/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

select inv.InvoiceID, cust.CustomerName, inv.InvoiceDate as invoice_data, line.Quantity*line.UnitPrice as price,

(
select SUM(line1.Quantity*line1.UnitPrice) as pm
from Sales.Invoices as inv1
JOIN Sales.InvoiceLines as line1 on inv1.InvoiceID=line1.InvoiceID
where YEAR(inv1.InvoiceDate)>=2015 and
MONTH(inv1.InvoiceDate)<=MONTH(inv.InvoiceDate) and YEAR(inv1.InvoiceDate) <= YEAR(inv.InvoiceDate)
) as unitmonth 

from Sales.Invoices as inv
JOIN Sales.InvoiceLines as line on inv.InvoiceID=line.InvoiceID
JOIN Sales.Customers as cust ON inv.CustomerID=cust.CustomerID

where YEAR(inv.InvoiceDate)>=2015
order by invoice_data 


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/


select inv.InvoiceID, cust.CustomerName, inv.InvoiceDate as invoice_data, line.Quantity*line.UnitPrice as price, 
SUM(line.Quantity*line.UnitPrice) OVER(order by YEAR(inv.InvoiceDate),MONTH(inv.InvoiceDate))  as priceunits
from Sales.Invoices as inv
JOIN Sales.InvoiceLines as line on inv.InvoiceID=line.InvoiceID
JOIN Sales.Customers as cust ON inv.CustomerID=cust.CustomerID
where YEAR(inv.InvoiceDate)>=2015
order by invoice_data 


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
select * from(
select YEAR(InvoiceDate) as Y,MONTH(InvoiceDate) as M, st.StockItemName, SUM(Quantity) as Quant,
ROW_NUMBER() OVER (PARTITION BY MONTH(InvoiceDate) order by SUM(Quantity) DESC) as Topitems
from 
Sales.Invoices as inv JOIN
Sales.InvoiceLines as line ON inv.InvoiceID = line.InvoiceID
JOIN Warehouse.StockItems as st ON
line.StockItemID = st.StockItemID 
where YEAR(InvoiceDate) = 2016
group by  MONTH(InvoiceDate),st.StockItemName,YEAR(InvoiceDate)
) as mt
where Topitems<3


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select si.StockItemID, StockItemName, Brand, UnitPrice,
ROW_NUMBER() OVER (PARTITION BY substring(StockItemName,1,1) ORDER BY StockItemName) as row_num_first_sumb,
SUM(sih.QuantityOnHand) OVER () as sum_quant_all,
SUM(sih.QuantityOnHand) OVER (PARTITION BY substring(StockItemName,1,1)) as sum_quant_first_sumb,
LEAD(si.StockItemID) OVER (ORDER BY StockItemName) next_id,
LAG(si.StockItemID) OVER (ORDER BY StockItemName) prev_id,
LAG(si.StockItemName,2,'No items') OVER (ORDER BY StockItemName) prev_id,
NTILE(30) OVER(ORDER BY si.TypicalWeightPerUnit DESC) AS Quartile   
from Warehouse.StockItems si 
JOIN Warehouse.StockItemHoldings sih ON si.StockItemID=sih.StockItemID
order by StockItemName
/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
select sales_id,sales_name,client_id,client_name,sales_date,sum_sale from(
select 
sales.PersonID as sales_id, sales.FullName as sales_name, 
client.PersonID as client_id,client.FullName as client_name, 
inv.InvoiceDate as sales_date,SUM(lines.Quantity*lines.UnitPrice) as sum_sale,
ROW_NUMBER() OVER(PARTITION BY sales.PersonID ORDER BY inv.InvoiceDate DESC) rn
from Sales.Invoices as inv 
JOIN Sales.InvoiceLines as lines ON inv.InvoiceID=lines.InvoiceID
JOIN Application.People client ON client.PersonID=inv.CustomerID
JOIN Application.People sales ON sales.PersonID=inv.SalespersonPersonID
group by
sales.PersonID, sales.FullName, client.PersonID,client.FullName,inv.InvoiceDate
) as tt 
where rn=1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
select cid, CustName, stockid ,price, dates from 
(
SELECT cust.CustomerID as cid, cust.CustomerName as CustName,StockItemID as stockid, lin.UnitPrice as price, max(inv.InvoiceDate) as dates,
  ROW_NUMBER() OVER(PARTITION BY cust.CustomerID ORDER BY lin.UnitPrice DESC) as rn
  FROM Sales.Customers cust 
  JOIN  Sales.orders ord ON ord.CustomerID = cust.CustomerID    
  JOIN Sales.Invoices inv ON ord.OrderID=inv.OrderID 
  JOIN Sales.InvoiceLines lin ON inv.InvoiceID=lin.InvoiceID
  group by cust.CustomerID,cust.CustomerName, StockItemID, lin.UnitPrice  
  ) as t
  where rn<3
  order by custname, rn 

--Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 