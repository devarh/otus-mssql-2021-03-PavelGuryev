use [WideWorldImporters];

-- ������ �� ���������� �������������
DROP FUNCTION IF EXISTS dbo.fn_Trim
GO
DROP AGGREGATE IF EXISTS dbo.StringAggDistinct
GO
DROP ASSEMBLY IF EXISTS HWAssembly

---- �������� CLR
exec sp_configure 'show advanced options', 1;
GO
reconfigure;
GO

exec sp_configure 'clr enabled', 1;
exec sp_configure 'clr strict security', 0 
GO

---- clr strict security 
---- 1 (Enabled): ���������� Database Engine ������������ �������� PERMISSION_SET � ������� 
---- � ������ ���������������� �� ��� UNSAFE. �� ���������, ������� � SQL Server 2017.

reconfigure;
GO

---- ��� ����������� �������� ������ � EXTERNAL_ACCESS ��� UNSAFE
ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON; 

---- ���������� dll 
---- �������� ���� � �����!
CREATE ASSEMBLY HWAssembly
FROM 'D:\sqlClr.dll'
WITH PERMISSION_SET = SAFE;

--�������� � ������������� �������
CREATE FUNCTION dbo.fn_Trim(@Name nvarchar(max))  
RETURNS nvarchar(max)
AS EXTERNAL NAME [HWAssembly].[ScalarFunctions].fnTrim

SELECT dbo.fn_Trim('   ffvfvg     ');

--�������� � ������������� ���������� �������
CREATE AGGREGATE dbo.StringAggDistinct (@resultStr nvarchar(200), @delimeter nvarchar(5)) RETURNS nvarchar(max)  
EXTERNAL NAME [HWAssembly].StringAggDistinct;

;WITH l AS
(
	SELECT TOP (50) 
		CityName
	FROM [WideWorldImporters].[Application].[Cities]
)
SELECT dbo.StringAggDistinct(CityName,'; ') FROM l