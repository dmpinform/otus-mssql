/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/
INSERT INTO Sales.Customers
       ([CustomerName]
	  ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
select top(5) 
       concat('Client',row_number() over(ORDER BY CustomerId)) 
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy]
 from Sales.Customers


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE from Sales.Customers
where CustomerName = 'Client5'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers set CustomerName = 'Плетнев Дмитрий'
where CustomerName = 'Client4'

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/
select top(10) * into #Cutomers
from Sales.Customers 

update #Cutomers set CustomerName=concat(CustomerName,CustomerID)
where CustomerID<5

select * from #Cutomers 

MERGE Sales.Customers AS tgt
	USING (select
	   CustomerName
      ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy] from #Cutomers) as src
	ON tgt.CustomerName = src.CustomerName
	WHEN MATCHED THEN
		UPDATE SET tgt.CreditLimit = 999999999
	WHEN NOT MATCHED THEN
		INSERT 
       ([CustomerName]
	  ,[BillToCustomerID]
      ,[CustomerCategoryID]
      ,[BuyingGroupID]
      ,[PrimaryContactPersonID]
      ,[AlternateContactPersonID]
      ,[DeliveryMethodID]
      ,[DeliveryCityID]
      ,[PostalCityID]
      ,[CreditLimit]
      ,[AccountOpenedDate]
      ,[StandardDiscountPercentage]
      ,[IsStatementSent]
      ,[IsOnCreditHold]
      ,[PaymentDays]
      ,[PhoneNumber]
      ,[FaxNumber]
      ,[DeliveryRun]
      ,[RunPosition]
      ,[WebsiteURL]
      ,[DeliveryAddressLine1]
      ,[DeliveryAddressLine2]
      ,[DeliveryPostalCode]
      ,[DeliveryLocation]
      ,[PostalAddressLine1]
      ,[PostalAddressLine2]
      ,[PostalPostalCode]
      ,[LastEditedBy])
	VALUES
	   (src.CustomerName
      ,src.BillToCustomerID
      ,src.CustomerCategoryID
      ,src.BuyingGroupID
      ,src.PrimaryContactPersonID
      ,src.AlternateContactPersonID
      ,src.DeliveryMethodID
      ,src.DeliveryCityID
      ,src.PostalCityID
      ,src.CreditLimit
      ,src.AccountOpenedDate
      ,src.StandardDiscountPercentage
      ,src.IsStatementSent
      ,src.IsOnCreditHold
      ,src.PaymentDays
      ,src.PhoneNumber
      ,src.FaxNumber
      ,src.DeliveryRun
      ,src.RunPosition
      ,src.WebsiteURL
      ,src.DeliveryAddressLine1
      ,src.DeliveryAddressLine2
      ,src.DeliveryPostalCode
      ,src.DeliveryLocation
      ,src.PostalAddressLine1
      ,src.PostalAddressLine2
      ,src.PostalPostalCode
      ,src.LastEditedBy)
	  OUTPUT deleted.*, $action, inserted.*;  


/*5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/
-- To allow advanced options to be changed.  
EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  

SELECT @@SERVERNAME
exec master..xp_cmdshell 'bcp "[WideWorldImporters].Application.Cities" out  "D:\bufer.txt" -T -w -t"@$#", -S sqldb'


CREATE TABLE [Application].[Cities_BulkDemo](
	[CityID] [int] NOT NULL,
	[CityName] [nvarchar](50) NOT NULL,
	[StateProvinceID] [int] NOT NULL,
	[Location] [geography] NULL,
	[LatestRecordedPopulation] [bigint] NULL,
	[LastEditedBy] [int] NOT NULL,
	[ValidFrom] [datetime2](7) GENERATED ALWAYS AS ROW START NOT NULL,
	[ValidTo] [datetime2](7) GENERATED ALWAYS AS ROW END NOT NULL,
 CONSTRAINT [PK_Application_Cities] PRIMARY KEY CLUSTERED 
(
	[CityID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [USERDATA],
	PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
) ON [USERDATA] TEXTIMAGE_ON [USERDATA]
WITH
(
SYSTEM_VERSIONING = ON ( HISTORY_TABLE = [Application].[Cities_Archive] )
)
GO


BULK INSERT [WideWorldImporters].[Application].[Cities_BulkDemo]
				   FROM "D:\bufer.txt"
				   WITH 
					 (
						BATCHSIZE = 1000, 
						DATAFILETYPE = 'widechar',
						FIELDTERMINATOR = '@$#',
						ROWTERMINATOR ='\n',
						KEEPNULLS,
						TABLOCK        
					  );


