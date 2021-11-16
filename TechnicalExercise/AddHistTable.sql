-- The stored procedure creates historical table and trigger to populate it for the given table name.
-- Data is stored in the same set of columns as in the original table.
CREATE PROCEDURE AddHistTable
	@TableName varchar(100) -- table name for which we want to create hist table
AS
BEGIN
	DECLARE @ColumnNamesTable TABLE 
	(
		ColumnName varchar(100), 
		DataType varchar(20), 
		CharacterMaximumLength int
	)

	-- get column data for the table
	INSERT INTO @ColumnNamesTable
	SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = @TableName and COLUMN_NAME <> 'Id'
	ORDER BY ORDINAL_POSITION

	DECLARE @ColumnDefinitionsTable TABLE 
	(
		ColumnDefinition varchar(100)
	)

	-- get column definitions
	INSERT INTO @ColumnDefinitionsTable
	SELECT CASE WHEN CharacterMaximumLength IS NOT NULL
		THEN '[' + ColumnName + '] ' + DataType + '(' + CAST(CharacterMaximumLength AS varchar(10)) + ')'
		ELSE '[' + ColumnName + '] ' + DataType
	END
	FROM @ColumnNamesTable

	-- get column definitions as comma separated list
	DECLARE @ColumnDefinitions varchar(1000)

	SET @ColumnDefinitions = (
	SELECT TOP 1 LEFT(Main.ColumnDefinitions, LEN(Main.ColumnDefinitions)-1)
	FROM (
			SELECT ColDefTable.ColumnDefinition,
			(
				SELECT ColumnDefinition + ', ' AS [text()]
				FROM @ColumnDefinitionsTable
				FOR XML PATH('')
			) [ColumnDefinitions]
			FROM @ColumnDefinitionsTable ColDefTable
		 ) [Main])

	-- get columns as comma separated string
	DECLARE @ColumnNames varchar(1000)

	SET @ColumnNames = (
	SELECT TOP 1 LEFT(Main.ColumnNames, LEN(Main.ColumnNames)-1)
	FROM (
			SELECT ColNamesTable.ColumnName,
			(
				SELECT ColumnName + ', ' AS [text()]
				FROM @ColumnNamesTable
				FOR XML PATH('')
			) [ColumnNames]
			FROM @ColumnNamesTable ColNamesTable
		 ) [Main])

DECLARE @sqlCreateHistTable nvarchar(4000)

DECLARE @HistTableName nvarchar(100) = @TableName + 'Hist'

PRINT 'Creating table ' + @HistTableName

SET @sqlCreateHistTable = 
'CREATE TABLE ' + @HistTableName + '(
	[Id] int IDENTITY(1,1) NOT NULL,
	RecordId int NULL, -- references Id in the original table
	Username varchar(50), -- name of the user who updated data
	ValidFromUtc datetime2, -- when data is valid from (this is insert time for inserts and update time for updates)
	ValidUntilUtc datetime2, -- when data is valid until (this is the update time when data was replaced with the new values and delete time for deletes)
	IsDeleted bit NULL, -- flag indicating if data has beed deleted, if that is set then ValidUntilUtc indicates the deletion time
' + @ColumnDefinitions + '
CONSTRAINT PK_' + @HistTableName + ' PRIMARY KEY CLUSTERED
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]'

EXEC sp_executesql @sqlCreateHistTable

DECLARE @sqlCreateIndex nvarchar(1000)
SET @sqlCreateIndex =
'CREATE NONCLUSTERED INDEX [IDX_' + @HistTableName + '_RecordId] ON [dbo].[' + @HistTableName + ']
(
	[RecordId] ASC
)
INCLUDE([ValidUntilUtc]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]'

EXEC sp_executesql @sqlCreateIndex

PRINT 'Inserting intial values into' + @HistTableName

DECLARE @sqlInsertData nvarchar(4000)
SET @sqlInsertData = 
'INSERT INTO ' + @HistTableName + '(RecordId, Username, ValidFromUtc, ValidUntilUtc, IsDeleted, ' + @ColumnNames + ')
SELECT Id, SYSTEM_USER, GETUTCDATE(), NULL, 0, ' + @ColumnNames + '
FROM ' + @TableName + ' RecordOuter'

EXEC sp_executesql @sqlInsertData

PRINT 'Creating trigger ' + @HistTableName + 'Trigger'

DECLARE @sqlCreateTrigger nvarchar(4000)
SET @sqlCreateTrigger = 
'CREATE TRIGGER ' + @HistTableName + 'Trigger
ON ' + @TableName + '
AFTER UPDATE, INSERT, DELETE
AS
BEGIN
	DECLARE @Id int
	DECLARE @updateTime datetime2(7) = GETUTCDATE()

	IF EXISTS(SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted) -- record was updated
	BEGIN
		-- Update valid until date for the existing hist records to mark they are no longer the current records
		UPDATE ' + @HistTableName + '
		SET ValidUntilUtc = @updateTime
		WHERE RecordId IN (SELECT Id FROM inserted)
		AND ValidUntilUtc IS NULL

		-- Insert new hist records with empty ValidUntilUtc date
		INSERT INTO ' + @HistTableName + ' (RecordId, Username, ValidFromUtc, ValidUntilUtc, IsDeleted, ' + @ColumnNames + ')
		SELECT Id, SYSTEM_USER, @updateTime, NULL, 0, ' + @ColumnNames + '
		FROM inserted RecordOuter
	END

	IF EXISTS(SELECT 1 FROM inserted) AND NOT EXISTS (SELECT 1 FROM deleted) -- record was inserted
	BEGIN
		-- insert new hist records with empty ValidUntilUtc date
		INSERT INTO ' + @HistTableName + ' (RecordId, Username, ValidFromUtc, ValidUntilUtc, IsDeleted, ' + @ColumnNames + ')
		SELECT Id, SYSTEM_USER, @updateTime, NULL, 0, ' + @ColumnNames + '
		FROM inserted RecordOuter
	END

	IF EXISTS(SELECT 1 FROM deleted) AND NOT EXISTS (SELECT 1 FROM inserted) -- record was deleted
	BEGIN
		-- Update valid until date for the existing hist records to mark they are no longer the current records
		UPDATE ' + @HistTableName + '
		SET ValidUntilUtc = @updateTime,
			IsDeleted = 1
		WHERE RecordId IN (SELECT Id FROM deleted)
		AND ValidUntilUtc IS NULL
	END
END'

EXEC sp_executesql @sqlCreateTrigger

END
GO
