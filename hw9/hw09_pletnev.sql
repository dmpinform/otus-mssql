/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/
GO  
CREATE FUNCTION Sales.Superclient()  
RETURNS int  
WITH EXECUTE AS CALLER  
AS  
BEGIN  
     DECLARE @MAX int;  
     select @MAX =  (select TOP(1) maxs
					FROM    (select SUM(Sales.InvoiceLines.Quantity * Sales.InvoiceLines.UnitPrice) AS maxs, 
					Sales.Customers.CustomerName
					FROM  Sales.Invoices INNER JOIN
					Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID INNER JOIN
					Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
					GROUP BY Sales.Customers.CustomerName) AS derivedtbl_1
					ORDER BY maxs DESC);
     RETURN(@MAX);  
END;  

SELECT Sales.Superclient() AS 'Super';   

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/


CREATE PROCEDURE Sales.Sumsales      
    @CustomerId int  
AS   

    SET NOCOUNT ON;  
	select SUM(Sales.InvoiceLines.Quantity * Sales.InvoiceLines.UnitPrice) AS maxs, 
					Sales.Customers.CustomerName
					FROM  Sales.Invoices INNER JOIN
					Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID INNER JOIN
					Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID and  
					Sales.Invoices.CustomerID = @CustomerId
					GROUP BY Sales.Customers.CustomerName;
GO

EXEC Sales.Sumsales @CustomerId =1;  
GO


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

CREATE PROCEDURE Sales.Superclient_proсedure   
AS   

    SET NOCOUNT ON;  
	    select TOP(1) maxs
		FROM    (select SUM(Sales.InvoiceLines.Quantity * Sales.InvoiceLines.UnitPrice) AS maxs, 
		Sales.Customers.CustomerName
		FROM  Sales.Invoices INNER JOIN
		Sales.InvoiceLines ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID INNER JOIN
		Sales.Customers ON Sales.Invoices.CustomerID = Sales.Customers.CustomerID
		GROUP BY Sales.Customers.CustomerName) AS derivedtbl_1
		ORDER BY maxs DESC
GO

/*
Функция
*/
SELECT Sales.Superclient() AS 'Super'; 
/*
Такая же процедура
*/
EXEC Sales.Superclient_proсedure 
GO

/*Судя по плану процедура дороже,  видимо это связано с 
разным алгоритмом выполнения функции и процедуры
*/


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

--встроенная функция с табличным значением
GO
CREATE FUNCTION Application.CountryInfo(@countryid int)  
RETURNS TABLE  
AS  
RETURN   
(  
    SELECT  CountryName, FormalName, Continent FROM  Application.Countries
	where CountryId = @countryid
	
);  
GO    


select country.CountryID, info.Continent, info.CountryName, info.FormalName
from Application.Countries country
Cross apply Application.CountryInfo(country.CountryID) AS info



/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
