use [WideWorldImporters];

-- Чистим от предыдущих экспериментов
DROP FUNCTION IF EXISTS dbo.fn_Trim
GO
DROP AGGREGATE IF EXISTS dbo.StringAggDistinct
GO
DROP ASSEMBLY IF EXISTS HWAssembly

---- Включаем CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

---- clr strict security 
---- 1 (Enabled): заставляет Database Engine игнорировать сведения PERMISSION_SET о сборках 
---- и всегда интерпретировать их как UNSAFE. По умолчанию, начиная с SQL Server 2017.

reconfigure;
GO

---- Для возможности создания сборок с EXTERNAL_ACCESS или UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

---- Подключаем dll 
---- Измените путь к файлу!
CREATE ASSEMBLY HWAssembly
FROM 'D:\sqlClr.dll'
WITH PERMISSION_SET = SAFE;

--Создание и использование функции
CREATE FUNCTION dbo.fn_Trim(@Name nvarchar(max))  
RETURNS nvarchar(max)
AS EXTERNAL NAME [HWAssembly].[ScalarFunctions].fnTrim

SELECT dbo.fn_Trim('   ffvfvg     ');

--Создание и использование агрегатной функции
CREATE AGGREGATE dbo.StringAggDistinct (@resultStr nvarchar(200), @delimeter nvarchar(5)) RETURNS nvarchar(max)  
EXTERNAL NAME [HWAssembly].StringAggDistinct;

;WITH l AS
(
	SELECT TOP (50) 
		CityName
	FROM [WideWorldImporters].[Application].[Cities]
)
SELECT dbo.StringAggDistinct(CityName,'; ') FROM l