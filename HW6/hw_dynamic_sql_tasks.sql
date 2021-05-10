-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


DECLARE
	@dml AS NVARCHAR(MAX)
	, @ColumnName AS NVARCHAR(MAX);

SELECT 
	@ColumnName = ISNULL(@ColumnName + ',', '') + QUOTENAME(CustomerName)
FROM Sales.Customers
ORDER BY
	CustomerName;

SET @dml = 
  N'SELECT
	CONVERT(varchar(10), invMonth, 104) as InvoiceMonth
	, ' + @ColumnName + ' 
	FROM
	(
		SELECT
			DATEFROMPARTS(YEAR(i.InvoiceDate),MONTH(i.InvoiceDate),1) AS invMonth
			, c.CustomerName
			, i.InvoiceID
		FROM Sales.Invoices i
			JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	) AS src
	PIVOT(COUNT(InvoiceID) FOR CustomerName IN (' + @ColumnName + ')) AS p
	ORDER BY
		invMonth;';

EXEC sp_executesql @dml;
