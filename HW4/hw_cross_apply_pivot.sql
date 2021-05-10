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
WITH cust AS
(
	SELECT
		CustomerID
		, SUBSTRING(CustomerName
			, CHARINDEX('(', CustomerName) + 1
			, CHARINDEX(')', CustomerName) - CHARINDEX('(', CustomerName) - 1
		) ShortName
	FROM Sales.Customers
	WHERE
		CustomerID between 2 and 6
)
SELECT
	CONVERT(varchar(10), invMonth, 104) as InvoiceMonth
	, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
FROM
(
	SELECT
		DATEFROMPARTS(YEAR(i.InvoiceDate),MONTH(i.InvoiceDate),1) AS invMonth
		, c.ShortName
		, i.InvoiceID
	FROM Sales.Invoices i
		JOIN cust c ON i.CustomerID = c.CustomerID
) AS src
PIVOT(COUNT(InvoiceID) FOR ShortName IN 
	([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])
) AS p
ORDER BY
	invMonth;

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

SELECT
	custName
	, AddressLine
FROM
(
	SELECT
		c.CustomerName AS custName
		, c.DeliveryAddressLine1
		, c.DeliveryAddressLine2
		, c.PostalAddressLine1
		, c.PostalAddressLine2
	FROM Sales.Customers c
	WHERE
		CustomerName LIKE '%Tailspin Toys%'
)src
UNPIVOT (AddressLine FOR addr IN (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)) AS rslt;

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

SELECT
	CountryID
	, CountryName
	, Code
FROM
(
	SELECT
		CountryID
		, CountryName
		, IsoAlpha3Code
		, CAST(IsoNumericCode as nvarchar(3)) AS IsoNumericCode
	FROM Application.Countries
)src
UNPIVOT (Code FOR someCode IN (IsoAlpha3Code, IsoNumericCode)) AS rslt;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


/*
В запросе использовал максимальную дату продажи, так как если выводить даты, то текущий вариант может выводить
не 2 товара, а один с разными датами. Данную проблему можно решить использовав оконные функции, как показано 
во втором варианте запроса
*/
SELECT
	c.CustomerID
	, c.CustomerName
	, t.StockItemID
	, t.UnitPrice
	, t.OrderDate
FROM Sales.Customers c
	CROSS APPLY
	(
		SELECT TOP 2 WITH TIES
			ol.StockItemID
			, ol.UnitPrice
			, MAX(o.OrderDate) as OrderDate
		FROM
			Sales.Orders o
			JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
		WHERE
			o.CustomerID = c.CustomerID
		GROUP BY
			ol.StockItemID
			, ol.UnitPrice
		ORDER BY
			UnitPrice DESC
	)t


--вариант с оконной функцией
SELECT
	c.CustomerID
	, c.CustomerName
	, t.StockItemID
	, t.UnitPrice
	, t.OrderDate
FROM Sales.Customers c
	CROSS APPLY
	(
		SELECT
			ol.StockItemID
			, ol.UnitPrice
			, o.OrderDate
			, DENSE_RANK() OVER (PARTITION BY o.CustomerID ORDER BY UnitPrice DESC) AS npp
		FROM
			Sales.Orders o
			JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
		WHERE
			o.CustomerID = c.CustomerID
	)t
WHERE
	t.npp < 3