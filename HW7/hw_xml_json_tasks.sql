-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Опционально - если вы знакомы с insert, update, merge, то загрузить эти данные в таблицу Warehouse.StockItems.
Существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 
*/

DECLARE
	@qry nvarchar(500)
	, @idoc INT
	,@xmlDoc XML;

SET @qry = 'SET @xmlDoc = 
			(
				SELECT *
				FROM
                openrowset
				(
					BULK ''C:\xml\StockItems-188-f89807.xml''
					, SINGLE_BLOB
				) AS [xml]
			)';
exec sp_executesql @qry, N'@xmlDoc xml output', @xmlDoc output;                

EXEC sp_xml_preparedocument @iDoc OUTPUT, @xmlDoc;

MERGE INTO Warehouse.StockItems AS tgt
USING
(
	SELECT
		StockItemName
		, SupplierID
		, UnitPackageID
		, OuterPackageID
		, QuantityPerOuter
		, TypicalWeightPerUnit
		, LeadTimeDays
		, IsChillerStock
		, TaxRate
		, UnitPrice
	FROM OPENXML(@idoc, 'StockItems/Item')
	WITH 
	(
		StockItemName nvarchar(100) '@Name'
		, SupplierID int 'SupplierID'
		, UnitPackageID int 'Package/UnitPackageID'
		, OuterPackageID int 'Package/OuterPackageID'
		, QuantityPerOuter int 'Package/QuantityPerOuter'
		, TypicalWeightPerUnit decimal(18,3) 'Package/TypicalWeightPerUnit'
		, LeadTimeDays int 'LeadTimeDays'
		, IsChillerStock bit 'IsChillerStock'
		, TaxRate decimal(18,3) 'TaxRate'
		, UnitPrice decimal(18,3) 'UnitPrice'
	)
) AS src
ON tgt.StockItemName = src.StockItemName
WHEN MATCHED THEN
	UPDATE
	SET
		tgt.SupplierID = src.SupplierID
		, tgt.UnitPackageID = src.UnitPackageID
		, tgt.OuterPackageID = src.OuterPackageID
		, tgt.QuantityPerOuter = src.QuantityPerOuter
		, tgt.TypicalWeightPerUnit = src.TypicalWeightPerUnit
		, tgt.LeadTimeDays = src.LeadTimeDays
		, tgt.IsChillerStock = src.IsChillerStock
		, tgt.TaxRate = src.TaxRate
		, tgt.UnitPrice = src.UnitPrice
WHEN NOT MATCHED THEN
	INSERT
	(
		[StockItemName]
		,[SupplierID]
		,[UnitPackageID]
		,[OuterPackageID]
		,[LeadTimeDays]
		,[QuantityPerOuter]
		,[IsChillerStock]
		,[TaxRate]
		,[UnitPrice]
		,[TypicalWeightPerUnit]
		,[LastEditedBy]
	)
	VALUES 
	(
		src.StockItemName
		, src.SupplierID
		, src.UnitPackageID
		, src.OuterPackageID
		, src.LeadTimeDays
		, src.QuantityPerOuter
		, src.IsChillerStock
		, src.TaxRate
		, src.UnitPrice
		, src.TypicalWeightPerUnit
		, 1
	);

EXEC sp_xml_removedocument @idoc;

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/
--Для выгрузки в xml разрешаем запуск 
EXECUTE sp_configure 'show advanced options', 1;  
GO 
RECONFIGURE;  
GO 
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO
RECONFIGURE;  
GO

DECLARE
	@sqlQuery varchar(1000)
	, @commandText varchar(4000);

SET @sqlQuery = 'SELECT StockItemName AS [@Name], SupplierID AS [SupplierID], UnitPackageID AS [Package/UnitPackageID], OuterPackageID AS [Package/OuterPackageID], QuantityPerOuter AS [Package/QuantityPerOuter], TypicalWeightPerUnit AS [Package/TypicalWeightPerUnit], LeadTimeDays [LeadTimeDays], IsChillerStock AS [IsChillerStock], TaxRate AS [TaxRate], UnitPrice AS [UnitPrice] FROM Warehouse.StockItems FOR XML PATH(''Item''), ROOT(''StockItems'')';

SET @commandText = 'bcp "' + @sqlQuery +'" queryout "C:\xml\StockItems.xml" -S ' +	@@SERVERNAME + ' -d WideWorldImporters -T -c -x -t';

--SELECT @commandText;

EXEC xp_cmdshell  @commandText;


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT
	StockItemID
	, StockItemName
	, JSON_VALUE(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture
	, JSON_VALUE(CustomFields, '$.Tags[0]') as FirstTag
FROM Warehouse.StockItems


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

SELECT
	StockItemID
	, StockItemName
	, STRING_AGG(z.value, ',') AS tags
FROM Warehouse.StockItems
	CROSS APPLY OPENJSON(CustomFields, '$.Tags') t
	CROSS APPLY OPENJSON(CustomFields, '$.Tags') z
WHERE
	t.value = 'Vintage'
GROUP BY
	StockItemID
	, StockItemName;
