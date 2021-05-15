-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO [Sales].[Customers]
(
	[CustomerID]
	,[CustomerName]
	,[BillToCustomerID]
	,[CustomerCategoryID]
	,[PrimaryContactPersonID]
	,[DeliveryMethodID]
	,[DeliveryCityID]
	,[PostalCityID]
	,[AccountOpenedDate]
	,[StandardDiscountPercentage]
	,[IsStatementSent]
	,[IsOnCreditHold]
	,[PaymentDays]
	,[PhoneNumber]
	,[FaxNumber]
	,[WebsiteURL]
	,[DeliveryAddressLine1]
	,[DeliveryPostalCode]
	,[PostalAddressLine1]
	,[PostalPostalCode]
	,[LastEditedBy]
)
SELECT TOP 5
	[CustomerID] + 9999
	,'INSERT ROW' + CAST([CustomerID] + 9999 as varchar(20))
	,[BillToCustomerID]
	,[CustomerCategoryID]
	,[PrimaryContactPersonID]
	,[DeliveryMethodID]
	,[DeliveryCityID]
	,[PostalCityID]
	,[AccountOpenedDate]
	,[StandardDiscountPercentage]
	,[IsStatementSent]
	,[IsOnCreditHold]
	,[PaymentDays]
	,[PhoneNumber]
	,[FaxNumber]
	,[WebsiteURL]
	,[DeliveryAddressLine1]
	,[DeliveryPostalCode]
	,[PostalAddressLine1]
	,[PostalPostalCode]
	,[LastEditedBy]
FROM [Sales].[Customers];

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE TOP (1) FROM [Sales].[Customers] WHERE CustomerName like 'INSERT%';

/*
3. Изменить одну запись, из добавленных через UPDATE
*/
;WITH cust AS
(
	SELECT TOP 1
		CustomerID
		, CreditLimit
	FROM [Sales].[Customers]
	WHERE
		CustomerName like 'INSERT%'
)
UPDATE cust
SET
	CreditLimit = 1111.11;

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE [Sales].[Customers] AS trg 
USING 
(
	SELECT TOP 5 --update
		[CustomerID]
		,[CustomerName] + cast(CustomerID AS varchar(20)) as CustomerName
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[PrimaryContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalPostalCode]
		,[LastEditedBy]
	FROM [Sales].[Customers]
	UNION ALL
	SELECT TOP 5 --insert
		[CustomerID] + 99999 as CustomerID
		, 'Merge insert' + cast([CustomerID] + 99999 AS varchar(20)) AS CustomerName
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[PrimaryContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalPostalCode]
		,[LastEditedBy]
	FROM [Sales].[Customers]
		
)AS src ON trg.CustomerID = src.CustomerID 
	WHEN MATCHED THEN 
		UPDATE
		SET
			CustomerName = src.CustomerName
			, DeliveryMethodID = src.DeliveryMethodID
			, StandardDiscountPercentage = src.StandardDiscountPercentage
	WHEN NOT MATCHED THEN
	INSERT 
	(
		[CustomerID]
		,[CustomerName]
		,[BillToCustomerID]
		,[CustomerCategoryID]
		,[PrimaryContactPersonID]
		,[DeliveryMethodID]
		,[DeliveryCityID]
		,[PostalCityID]
		,[AccountOpenedDate]
		,[StandardDiscountPercentage]
		,[IsStatementSent]
		,[IsOnCreditHold]
		,[PaymentDays]
		,[PhoneNumber]
		,[FaxNumber]
		,[WebsiteURL]
		,[DeliveryAddressLine1]
		,[DeliveryPostalCode]
		,[PostalAddressLine1]
		,[PostalPostalCode]
		,[LastEditedBy]
	) 
	VALUES 
	(
		src.[CustomerID]
		, src.[CustomerName]
		, src.[BillToCustomerID]
		, src.[CustomerCategoryID]
		, src.[PrimaryContactPersonID]
		, src.[DeliveryMethodID]
		, src.[DeliveryCityID]
		, src.[PostalCityID]
		, src.[AccountOpenedDate]
		, src.[StandardDiscountPercentage]
		, src.[IsStatementSent]
		, src.[IsOnCreditHold]
		, src.[PaymentDays]
		, src.[PhoneNumber]
		, src.[FaxNumber]
		, src.[WebsiteURL]
		, src.[DeliveryAddressLine1]
		, src.[DeliveryPostalCode]
		, src.[PostalAddressLine1]
		, src.[PostalPostalCode]
		, src.[LastEditedBy]
	);

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXECUTE sp_configure 'show advanced options', 1;  
GO 
RECONFIGURE;  
GO 
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO
RECONFIGURE;  
GO

--выгрузка
DECLARE
	@commandText varchar(4000);

SET @commandText = 'bcp [Purchasing].[Suppliers] out "C:\xml\suppl.txt" -S ' +	@@SERVERNAME + ' -d WideWorldImporters -T -w -t -k';

EXEC xp_cmdshell  @commandText;

--загрузка
DROP TABLE IF EXISTS [Purchasing].[SuppliersBulkIns]

CREATE TABLE [Purchasing].[SuppliersBulkIns]
(
	[SupplierID] [int] NOT NULL
	, [SupplierName] [nvarchar](100) NOT NULL
	, [SupplierCategoryID] [int] NOT NULL
	, [PrimaryContactPersonID] [int] NOT NULL
	, [AlternateContactPersonID] [int] NOT NULL
	, [DeliveryMethodID] [int] NULL
	, [DeliveryCityID] [int] NOT NULL
	, [PostalCityID] [int] NOT NULL
	, [SupplierReference] [nvarchar](20) NULL
	, [BankAccountName] [nvarchar](50) NULL
	, [BankAccountBranch] [nvarchar](50) NULL
	, [BankAccountCode] [nvarchar](20) NULL
	, [BankAccountNumber] [nvarchar](20) NULL
	, [BankInternationalCode] [nvarchar](20)  NULL
	, [PaymentDays] [int] NOT NULL
	, [InternalComments] [nvarchar](max) NULL
	, [PhoneNumber] [nvarchar](20) NOT NULL
	, [FaxNumber] [nvarchar](20) NOT NULL
	, [WebsiteURL] [nvarchar](256) NOT NULL
	, [DeliveryAddressLine1] [nvarchar](60) NOT NULL
	, [DeliveryAddressLine2] [nvarchar](60) NULL
	, [DeliveryPostalCode] [nvarchar](10) NOT NULL
	, [DeliveryLocation] [geography] NULL
	, [PostalAddressLine1] [nvarchar](60) NOT NULL
	, [PostalAddressLine2] [nvarchar](60) NULL
	, [PostalPostalCode] [nvarchar](10) NOT NULL
	, [LastEditedBy] [int] NOT NULL
	, [ValidFrom] [datetime2](7) NOT NULL
	, [ValidTo] [datetime2](7) NOT NULL
)

BULK INSERT [Purchasing].[SuppliersBulkIns]
FROM "C:\xml\suppl.txt"
WITH 
	(
	BATCHSIZE = 1000, 
	DATAFILETYPE = 'widechar',
	FIELDTERMINATOR = '\t',
	ROWTERMINATOR ='\n',
	KEEPNULLS,
	TABLOCK        
	);

SELECT *
FROM [Purchasing].[SuppliersBulkIns];

DROP TABLE [Purchasing].[SuppliersBulkIns];