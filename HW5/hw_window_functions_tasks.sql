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
;WITH cte AS
(
	SELECT
		YEAR(i.InvoiceDate) invoiceYear
		, MONTH(i.InvoiceDate) invoiceMonth
		, SUM(il.ExtendedPrice) as sumMonth
	FROM Sales.Invoices i
		JOIN Sales.InvoiceLines il ON il.InvoiceID = i.InvoiceID
	WHERE
		i.InvoiceDate >= '20150101'
	GROUP BY
		YEAR(i.InvoiceDate)
		, MONTH(i.InvoiceDate)
)
SELECT
	i.InvoiceID
	, c.CustomerName
	, i.InvoiceDate
	, invSum.sumInvoice
	,
	(
		SELECT
			SUM(cte.sumMonth)
		FROM cte
		WHERE
			cte.invoiceYear <= YEAR(i.InvoiceDate)
			AND cte.invoiceMonth <= MONTH(i.InvoiceDate)
	)
FROM Sales.Invoices i
	JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	CROSS APPLY
	(
		SELECT
			SUM(il.ExtendedPrice) as sumInvoice
		FROM Sales.InvoiceLines il
		WHERE
			il.InvoiceID = i.InvoiceID
		GROUP BY
			il.InvoiceID
	)invSum
WHERE
	i.InvoiceDate > '20150101'
ORDER BY
	i.InvoiceDate
	, i.InvoiceID;

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

SELECT
	i.InvoiceID
	, c.CustomerName
	, i.InvoiceDate
	, invSum.sumInvoice
	, SUM(invSum.sumInvoice) OVER (ORDER BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)) AS cumulativeTotal
FROM Sales.Invoices i
	JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
	CROSS APPLY
	(
		SELECT
			SUM(il.ExtendedPrice) as sumInvoice
		FROM Sales.InvoiceLines il
		WHERE
			il.InvoiceID = i.InvoiceID
		GROUP BY
			il.InvoiceID
	)invSum
WHERE
	i.InvoiceDate > '20141231'
ORDER BY
	i.InvoiceDate
	, i.InvoiceID;

--Статистика без оконной функции
/*
(затронуто строк: 31440)
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Workfile". Сканирований 8, логических операций чтения 128, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 128, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 2, логических операций чтения 353, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 157, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Customers". Сканирований 1, логических операций чтения 40, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 31, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "InvoiceLines". Сканирований 1, логических операций чтения 5003, физических операций чтения 3, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 3859, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

 Время работы SQL Server:
   Время ЦП = 172 мс, затраченное время = 700 мс.
*/

--Статистика с оконной функцией
/*
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Workfile". Сканирований 8, логических операций чтения 128, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 128, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 2, логических операций чтения 353, физических операций чтения 2, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 342, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Customers". Сканирований 1, логических операций чтения 40, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 31, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "InvoiceLines". Сканирований 1, логических операций чтения 5003, физических операций чтения 3, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 4978, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

 Время работы SQL Server:
   Время ЦП = 234 мс, затраченное время = 757 мс.
*/

/*
В итоге у меня получились одинаковые статистики запросов.
*/

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;WITH volSalesByMonth AS
(
	SELECT
		MONTH(i.InvoiceDate) as invMonth
		, il.StockItemID
		, si.StockItemName
		, SUM(il.Quantity) AS volSales
		, ROW_NUMBER() OVER (PARTITION BY MONTH(i.InvoiceDate) ORDER BY MONTH(i.InvoiceDate), SUM(il.Quantity) DESC) AS volRank
	FROM Sales.Invoices as i
		JOIN Sales.InvoiceLines il ON i.InvoiceID = il.InvoiceID
		JOIN Warehouse.StockItems si ON il.StockItemID = si.StockItemID
	WHERE
		i.InvoiceDate between '20160101' and '20161231'
	GROUP BY
		MONTH(i.InvoiceDate)
		, il.StockItemID
		, si.StockItemName
)
SELECT
	invMonth
	, StockItemName
	, volSales
FROM volSalesByMonth
WHERE
	volRank < 3
ORDER BY
	invMonth
	, volSales DESC;

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

SELECT
	si.StockItemID
	, si.StockItemName
	, COALESCE(si.Brand,'') AS Brand
	, si.UnitPrice
	, ROW_NUMBER() OVER (PARTITION BY SUBSTRING(si.StockItemName, PATINDEX('%[A-z]%', si.StockItemName), 1) ORDER BY si.StockItemName) as rankFirstLetter
	, COUNT(*) OVER() AS volTotal
	, COUNT(*) OVER(PARTITION BY SUBSTRING(si.StockItemName, PATINDEX('%[A-z]%', si.StockItemName), 1)) AS volFirstLetter
	, LEAD(si.StockItemID) OVER(ORDER BY si.StockItemName) as nextItemID
	, LAG(si.StockItemID) OVER(ORDER BY si.StockItemName) as prevItemID
	, LAG(si.StockItemName, 2, 'No items') OVER(ORDER BY si.StockItemName) as prevTwoItemName
	, NTILE(30) OVER(ORDER BY si.TypicalWeightPerUnit) AS RankWeight
FROM Warehouse.StockItems AS si;

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

;WITH inv AS 
(
	SELECT DISTINCT
		i.SalespersonPersonID
		, FIRST_VALUE(i.CustomerID) OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC) AS lastCustomerID
		, FIRST_VALUE(i.InvoiceID) OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC) AS lastInvoiceID
		, FIRST_VALUE(i.InvoiceDate) OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC) AS lastInvoiceDate
		, FIRST_VALUE(s.sumInvoice) OVER (PARTITION BY i.SalespersonPersonID ORDER BY i.InvoiceDate DESC, i.InvoiceID DESC) AS lastSumInvoice
	FROM Sales.Invoices i
		CROSS APPLY
		(
			SELECT
				SUM(il.ExtendedPrice) AS sumInvoice
			FROM Sales.InvoiceLines il
			WHERE
				il.InvoiceID = i.InvoiceID
		)s
)
SELECT
	p.PersonID AS EmployeeID
	, p.FullName
	, inv.lastCustomerID
	, c.CustomerName
	, inv.lastInvoiceDate
	, inv.lastSumInvoice
FROM Application.People p
	JOIN inv ON p.PersonID = inv.SalespersonPersonID
	JOIN Sales.Customers c ON inv.lastCustomerID = c.CustomerID
WHERE
	P.IsEmployee = 1;

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
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
	t.npp < 3;
