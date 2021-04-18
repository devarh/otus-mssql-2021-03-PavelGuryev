-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--Подзапрос
SELECT
	p.PersonID
	, p.FullName
FROM Application.People AS p
WHERE
	p.IsSalesperson = 1
	AND NOT EXISTS
	(
		SELECT
			o.OrderID
		FROM Sales.Invoices o
		WHERE
			o.SalespersonPersonID = p.PersonID
			AND o.InvoiceDate = '20150704'
	);
--CTE
WITH ord (idPers) AS
(
	SELECT DISTINCT
		o.SalespersonPersonID
	FROM Sales.Invoices o
	WHERE
		o.InvoiceDate = '20150704'
)
SELECT
	p.PersonID
	, p.FullName
FROM Application.People AS p
	LEFT JOIN ord o ON p.PersonID = o.idPers
WHERE
	o.idPers IS NULL
	AND p.IsSalesperson = 1

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/
--подзапросы
--1
SELECT DISTINCT
	s.StockItemID
	, s.StockItemName
	, s.UnitPrice
FROM [Warehouse].[StockItems] s
WHERE
	s.UnitPrice = 
	(
		SELECT
			MIN(UnitPrice)
		FROM [Warehouse].[StockItems] s2
	);
--2
SELECT DISTINCT
	s.StockItemID
	, s.StockItemName
	, s.UnitPrice
FROM [Warehouse].[StockItems] s
WHERE
	s.UnitPrice <= ALL
	(
		SELECT
			UnitPrice
		FROM [Warehouse].[StockItems] s2
	);
--CTE
WITH minPrice AS
(
	SELECT TOP 1 WITH TIES
		StockItemID
		, StockItemName
	FROM [Warehouse].[StockItems]
	ORDER BY
		UnitPrice
)
SELECT DISTINCT
	s.StockItemID
	, s.StockItemName
	, s.UnitPrice
FROM [Warehouse].[StockItems] s
WHERE
	s.StockItemID = ANY
	(
		SELECT
			StockItemID
		FROM minPrice
	);

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/
--Подзапросы
--1
SELECT
	c.CustomerID
	, c.CustomerName
FROM Sales.Customers c
WHERE
	c.CustomerID IN
	(
		SELECT TOP 5 WITH TIES
			ct.CustomerID
		FROM Sales.CustomerTransactions ct
		ORDER BY
			ct.TransactionAmount DESC
	);
--2
SELECT
	c.CustomerID
	, c.CustomerName
FROM Sales.Customers c
WHERE
	c.CustomerID = ANY
	(
		SELECT TOP 5 WITH TIES
			ct.CustomerID
		FROM Sales.CustomerTransactions ct
		ORDER BY
			ct.TransactionAmount DESC
	);
--CTE
WITH cust AS
(
	SELECT TOP 5 WITH TIES
		ct.CustomerID
	FROM Sales.CustomerTransactions ct
	ORDER BY
		ct.TransactionAmount DESC
)
SELECT DISTINCT
	c.CustomerID
	, c.CustomerName
FROM Sales.Customers c
	JOIN cust ct ON c.CustomerID = ct.CustomerID;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/
--подзапрос
SELECT DISTINCT
	cu.DeliveryCityID
	,
	(
		SELECT
			ci.CityName
		FROM Application.Cities AS ci
		WHERE
			ci.CityID = cu.DeliveryCityID
	) AS City
	, p.PreferredName
FROM Sales.Invoices AS i
	JOIN Sales.Customers AS cu ON i.CustomerID = cu.CustomerID
	JOIN Application.People AS p ON i.PackedByPersonID = p.PersonID
WHERE
	i.InvoiceID IN
	(
		SELECT
			il.InvoiceID
		FROM Sales.InvoiceLines AS il
		WHERE
			il.StockItemID IN
			(
				SELECT TOP 3 WITH TIES
					st.StockItemID
				FROM [WideWorldImporters].[Warehouse].[StockItems] AS st
				ORDER BY
					st.UnitPrice DESC
			)
	);
--CTE
WITH products(ProductID) AS
(
	SELECT TOP 3 WITH TIES
		st.StockItemID
	FROM [WideWorldImporters].[Warehouse].[StockItems] AS st
	ORDER BY
		st.UnitPrice DESC
)
, invoiceInfo AS
(
	SELECT DISTINCT
		i.CustomerID
		, i.PackedByPersonID
	FROM Sales.Invoices AS i
		JOIN Sales.InvoiceLines AS il ON i.InvoiceID = il.InvoiceID
	WHERE
		il.StockItemID IN
		(
			SELECT
				ProductID
			FROM products
		)
)
SELECT DISTINCT
	ci.CityID
	, ci.CityName
	, p.PreferredName
FROM invoiceInfo AS i
	JOIN Sales.Customers AS cu ON i.CustomerID = cu.CustomerID
	JOIN Application.People AS p ON i.PackedByPersonID = p.PersonID
	JOIN Application.Cities AS ci ON ci.CityID = cu.DeliveryCityID;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;

/*
Получаем список счетов, с суммой проданных товаров свыше 27000, с указанием продавца и суммы отгруженных товаров.

Запрос выводит
	ID счета
	, Дату счета
	, Полное имя продавца
	, Суммарную стоимость товара без налога
	, Суммарную стоимость отгруженных товаров
по счетам, в которых указаны товары, суммарная стоимость которых в счете без учета налога превышает 27000
*/
-- --

--Улучшение читаемости
--Первый подзапрос в SELECT-е заменил JOIN-ом. Второй и третий подзапросы заменил на CTE.
WITH sumPickedItems AS
(
	SELECT
		OrderId
		, SUM(PickedQuantity*UnitPrice) TotalSummForPickedItems
	FROM Sales.OrderLines
	WHERE
		OrderId IN 
		(
			SELECT DISTINCT
				Orders.OrderId 
			FROM Sales.Orders
			WHERE
				Orders.PickingCompletedWhen IS NOT NULL	
		)
	GROUP BY
		OrderId
)
, SalesTotals AS
(
		SELECT
			InvoiceId
			, SUM(Quantity*UnitPrice) AS TotalSumm
		FROM Sales.InvoiceLines
		GROUP BY
			InvoiceId
		HAVING SUM(Quantity*UnitPrice) > 27000
)
SELECT 
	i.InvoiceID,
	i.InvoiceDate,
	p.FullName AS SalesPersonName,
	st.TotalSumm AS TotalSummByInvoice, 
	COALESCE(sp.TotalSummForPickedItems,0) AS TotalSummForPickedItems
FROM Sales.Invoices AS i
	JOIN Application.People AS p ON i.SalespersonPersonID = p.PersonID
	JOIN sumPickedItems sp ON i.OrderID = sp.OrderID
	JOIN SalesTotals st ON i.InvoiceID = st.InvoiceID
		
ORDER BY
	TotalSumm DESC;


--Статистика
/*

(затронуто строк: 8)
Таблица "OrderLines". Сканирований 8, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 508, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 790, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 1, пропущено 0.
Таблица "InvoiceLines". Сканирований 8, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 502, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 778, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
Таблица "Orders". Сканирований 5, логических операций чтения 725, физических операций чтения 3, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 667, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 5, логических операций чтения 11994, физических операций чтения 3, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 11366, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "People". Сканирований 5, логических операций чтения 28, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 2, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

(затронуто строк: 23)

(затронута одна строка)

 Время работы SQL Server:
   Время ЦП = 172 мс, затраченное время = 415 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

Время выполнения: 2021-04-17T16:16:08.4486886+03:00

*/
/*
Из статистики видно, что большое количество логических чтений у таблиц Orders и Invoices.
У таблицы Orders это происходит при отборе Orders.PickingCompletedWhen IS NOT NULL, так как по столбцу PickingCompletedWhen отсутствует индекс.
Поэтому для улучшения производительности можно содать некластеризованный индекс по столбцу PickingCompletedWhen.

У таблицы Invoices по столбцам InvoiceDate, SalespersonPersonID и OrderID отсутствует индекс.
После добавления индексов статистика показала следующее:

Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 78 мс, истекшее время = 86 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

(затронуто строк: 8)
Таблица "OrderLines". Сканирований 2, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 345, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 790, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 1, пропущено 0.
Таблица "InvoiceLines". Сканирований 2, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 341, физических операций чтения LOB 3, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 778, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "InvoiceLines". Считано сегментов 1, пропущено 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Orders". Сканирований 1, логических операций чтения 162, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 1, логических операций чтения 187, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "People". Сканирований 1, логических операций чтения 11, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

(затронута одна строка)

 Время работы SQL Server:
   Время ЦП = 94 мс, затраченное время = 148 мс.
Время синтаксического анализа и компиляции SQL Server: 
 время ЦП = 0 мс, истекшее время = 0 мс.

 Время работы SQL Server:
   Время ЦП = 0 мс, затраченное время = 0 мс.

Время выполнения: 2021-04-18T16:22:35.5232450+03:00


Количесто логических чтений уменьшилось.
*/
