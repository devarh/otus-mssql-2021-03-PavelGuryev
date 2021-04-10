/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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

USE WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT
	StockItemID
	, StockItemName
FROM Warehouse.StockItems
WHERE
	StockItemName like 'Animal%'
	OR StockItemName like '%urgent%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT
	s.SupplierID
	, s.SupplierName
FROM Purchasing.Suppliers s
	LEFT JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID
WHERE
	po.PurchaseOrderID IS NULL;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
SET LANGUAGE N'Russian';

SELECT
	o.OrderID
	, CONVERT(varchar(10), o.OrderDate, 104) AS OrderDate
	, DATENAME(MM, o.OrderDate) as orderMonth
	, DATEPART(q, o.OrderDate)  AS "Quarter"
	, CASE
		WHEN MONTH(o.OrderDate) between 1 and 4 THEN 1
		WHEN MONTH(o.OrderDate) between 5 and 8 THEN 2
		WHEN MONTH(o.OrderDate) between 9 and 12 THEN 3
		ELSE 0
	END AS ThirdYear
	, c.CustomerName
FROM Sales.Orders o
	LEFT JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	LEFT JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE
	(
		COALESCE(ol.UnitPrice,0) > 100
		OR COALESCE(ol.Quantity, 0) > 20
	)
	AND o.PickingCompletedWhen IS NOT NULL
ORDER BY
	"Quarter"
	, ThirdYear
	, o.OrderDate;

SELECT
	o.OrderID
	, CONVERT(varchar(10), o.OrderDate, 104) AS OrderDate
	, DATENAME(MM, o.OrderDate) as orderMonth
	, DATEPART(q, o.OrderDate)  AS "Quarter"
	, CASE
		WHEN MONTH(o.OrderDate) between 1 and 4 THEN 1
		WHEN MONTH(o.OrderDate) between 5 and 8 THEN 2
		WHEN MONTH(o.OrderDate) between 9 and 12 THEN 3
		ELSE 0
	END AS ThirdYear
	, c.CustomerName
FROM Sales.Orders o
	LEFT JOIN Sales.OrderLines ol ON o.OrderID = ol.OrderID
	LEFT JOIN Sales.Customers c ON o.CustomerID = c.CustomerID
WHERE
	(
		COALESCE(ol.UnitPrice,0) > 100
		OR COALESCE(ol.Quantity, 0) > 20
	)
	AND o.PickingCompletedWhen IS NOT NULL
ORDER BY
	"Quarter"
	, ThirdYear
	, o.OrderDate
OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT
	dm.DeliveryMethodName
	, po.ExpectedDeliveryDate
	, s.SupplierName
	, p.FullName
FROM Purchasing.Suppliers s
	JOIN Purchasing.PurchaseOrders po ON s.SupplierID = po.SupplierID
	JOIN Application.DeliveryMethods dm ON po.DeliveryMethodID = dm.DeliveryMethodID
	JOIN Application.People p ON po.ContactPersonID = p.PersonID
WHERE
	COALESCE(po.ExpectedDeliveryDate,'19000101') > '20121231'
	AND COALESCE(po.ExpectedDeliveryDate,'19000101') < '20130201'
	AND COALESCE(dm.DeliveryMethodName, '') in ('Air Freight', 'Refrigerated Air Freight')
	AND COALESCE(po.IsOrderFinalized, 0) = 1;
/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP 10
	i.InvoiceID
	, i.InvoiceDate
	, c.CustomerName AS Client
	, p.FullName AS SalesPerson
FROM [Sales].[Invoices] i
	LEFT JOIN Application.People p ON COALESCE(i.SalespersonPersonID,0) = p.PersonID
	LEFT JOIN Sales.Customers c ON COALESCE(i.[CustomerID],0) = c.CustomerID
ORDER BY
	i.InvoiceDate DESC;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT
	c.CustomerID
	, c.CustomerName
	, c.PhoneNumber
FROM [Sales].[Invoices] i
	LEFT JOIN Sales.Customers c ON COALESCE(i.[CustomerID],0) = c.CustomerID
	JOIN [Sales].[InvoiceLines] il ON i.InvoiceID = il.InvoiceID
	JOIN [Warehouse].[StockItems] si ON il.StockItemID = si.StockItemID
WHERE
	si.StockItemName = 'Chocolate frogs 250g';

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
	YEAR(i.[InvoiceDate]) yearInvoice
	, MONTH(i.[InvoiceDate]) monthInvoice
	, AVG(il.ExtendedPrice) sumAverage
	, SUM(il.ExtendedPrice) sumTotal
FROM [Sales].[Invoices] i
	JOIN [Sales].[InvoiceLines] il ON i.[InvoiceID] = il.[InvoiceID]
GROUP BY
	YEAR(i.[InvoiceDate])
	, MONTH(i.[InvoiceDate]);

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
	YEAR(i.[InvoiceDate]) yearInvoice
	, MONTH(i.[InvoiceDate]) monthInvoice
	, SUM(il.ExtendedPrice) sumTotal
FROM [Sales].[Invoices] i
	JOIN [Sales].[InvoiceLines] il ON i.[InvoiceID] = il.[InvoiceID]
GROUP BY
	YEAR(i.[InvoiceDate])
	, MONTH(i.[InvoiceDate])
HAVING 
	SUM(il.ExtendedPrice) > 10000;

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT
	YEAR(i.[InvoiceDate]) yearInvoice
	, MONTH(i.[InvoiceDate]) monthInvoice
	, si.StockItemName
	, SUM(il.ExtendedPrice) sumTotal
	, MIN(i.[InvoiceDate]) dateFirstInvoice
	, SUM(il.Quantity) volTotal
FROM [Sales].[Invoices] i
	JOIN [Sales].[InvoiceLines] il ON i.[InvoiceID] = il.[InvoiceID]
	JOIN [Warehouse].[StockItems] si ON il.StockItemID = si.StockItemID
GROUP BY
	YEAR(i.[InvoiceDate])
	, MONTH(i.[InvoiceDate])
	, si.StockItemName;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
DECLARE @periods TABLE
(
	yearInvoice decimal(4,0)
	, monthInvoice decimal(2,0)
);

WITH listMonth (numberMonth) AS
(
	SELECT 1
	UNION ALL SELECT 2
	UNION ALL SELECT 3
	UNION ALL SELECT 4
	UNION ALL SELECT 5
	UNION ALL SELECT 6
	UNION ALL SELECT 7
	UNION ALL SELECT 8
	UNION ALL SELECT 9
	UNION ALL SELECT 10
	UNION ALL SELECT 11
	UNION ALL SELECT 12
)
, years (yearInvoice) AS
(
	SELECT
		YEAR(i.[InvoiceDate]) yearInvoice
	FROM [Sales].[Invoices] i
	GROUP BY
		YEAR(i.[InvoiceDate])
)
INSERT INTO @periods
SELECT
	yearInvoice
	, numberMonth
FROM years
	CROSS JOIN listMonth;
--запрос из задания 8
SELECT
	p.yearInvoice
	, p.monthInvoice
	, COALESCE(SUM(il.ExtendedPrice),0) sumTotal
FROM @periods p
	LEFT JOIN [Sales].[Invoices] i ON p.yearInvoice = YEAR(i.[InvoiceDate]) AND p.monthInvoice = MONTH(i.[InvoiceDate])
	LEFT JOIN [Sales].[InvoiceLines] il ON i.[InvoiceID] = il.[InvoiceID]
GROUP BY
	p.yearInvoice
	, p.monthInvoice
ORDER BY
	yearInvoice
	, monthInvoice;

--запрос из 9 задания
SELECT
	p.yearInvoice
	, p.monthInvoice
	, COALESCE(si.StockItemName, '') StockItemName
	, COALESCE(SUM(il.ExtendedPrice), 0) sumTotal
	, COALESCE(MIN(i.[InvoiceDate]), '19000101') dateFirstInvoice
	, COALESCE(SUM(il.Quantity), 0) volTotal
FROM @periods p
	LEFT JOIN [Sales].[Invoices] i ON p.yearInvoice = YEAR(i.[InvoiceDate]) AND p.monthInvoice = MONTH(i.[InvoiceDate])
	LEFT JOIN [Sales].[InvoiceLines] il ON i.[InvoiceID] = il.[InvoiceID]
	LEFT JOIN [Warehouse].[StockItems] si ON il.StockItemID = si.StockItemID
GROUP BY
	p.yearInvoice
	, p.monthInvoice
	, COALESCE(si.StockItemName, '')
ORDER BY
	yearInvoice
	, monthInvoice;