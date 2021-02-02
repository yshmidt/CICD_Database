-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SP_debugInitFieldsCHange] 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    	-- local variables

	
DECLARE @lnCount Int, @sql nvarchar(1000)
DECLARE @Tables Table (Table_name char(20),column_name char(20),nrecno int identity) ;
INSERT INTO @Tables select  Table_name,column_name from information_schema.columns 
	where column_name LIKE '%init%' and character_maximum_length=8 order by table_name;


-- remove index that are using initials 
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_LGT]') AND name = N'LOG_INIT')
		DROP INDEX [LOG_INIT] ON [dbo].[DEPT_LGT] WITH ( ONLINE = OFF )
	
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_LGT]') AND name = N'TIME_IN')
		DROP INDEX [TIME_IN] ON [dbo].[DEPT_LGT] WITH ( ONLINE = OFF )	

	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_LGT]') AND name = N'TIME_OUT')
		DROP INDEX [TIME_OUT] ON [dbo].[DEPT_LGT] WITH ( ONLINE = OFF )
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_LGT]') AND name = N'WODEPTTMNO')
		DROP INDEX [WODEPTTMNO] ON [dbo].[DEPT_LGT] WITH ( ONLINE = OFF )
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_LGT]') AND name = N'WONO')
		DROP INDEX [WONO] ON [dbo].[DEPT_LGT] WITH ( ONLINE = OFF )

	
	
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_CUR]') AND name = N'TIME_IN')
		DROP INDEX [TIME_IN] ON [dbo].[DEPT_CUR] WITH ( ONLINE = OFF )

	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_CUR]') AND name = N'TIME_OUT')
		DROP INDEX [TIME_OUT] ON [dbo].[DEPT_CUR] WITH ( ONLINE = OFF )

	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_CUR]') AND name = N'WODEPTTMNO')
		DROP INDEX [WODEPTTMNO] ON [dbo].[DEPT_CUR] WITH ( ONLINE = OFF )

	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[DEPT_CUR]') AND name = N'WONO')
		DROP INDEX [WONO] ON [dbo].[DEPT_CUR] WITH ( ONLINE = OFF )

	
	IF  EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[APCHKMST]') AND name = N'SAVEINIT')
		DROP INDEX SAVEINIT ON [dbo].[APCHKMST] WITH ( ONLINE = OFF )


set @lnCount=0;
WHILE (@lnCount<=@@IDENTITY)
BEGIN
	SET @lnCount=@lnCount+1
	
	

	SELECT @sql = 'ALTER TABLE '+ Table_name + 'ALTER COLUMN '+ Column_name +' char(3)' From @Tables where nRecno=@lnCount  ;
	if @@ROWCOUNT<>0
	begin
     execute sp_executesql @sql
	end
	-- rebuild index if exists
	--check if index that uses the column, which we need to alter is exists.
	SELECT @sql = 'ALTER INDEX ' + i.[name] +' ON '+ t.name+' REBUILD '
			FROM SYS.INDEXES AS i INNER JOIN SYS.TABLES AS t 
			ON i.[object_id] = t.[object_id]
			INNER JOIN SYS.INDEX_COLUMNS AS ic 
			ON i.[object_id] = ic.[object_id] 
			AND i.index_id = ic.index_id
			INNER JOIN SYS.Columns as c
			ON ic.[object_id] = c.[object_id] 
			AND ic.[Column_id]=c.[Column_id]
			INNER JOIN @Tables as tc ON t.name=tc.Table_name  
			WHERE t.[type] = 'U' 
			AND c.name LIKE '%init%'
			AND t.Is_MS_Shipped = 0
			AND i.Is_Hypothetical = 0 
			and tc.nRecno=@lnCount ;

	if @@ROWCOUNT<>0
	begin
     execute sp_executesql @sql
	end
			
END	
-- recreate index
CREATE NONCLUSTERED INDEX [LOG_INIT] ON [dbo].[DEPT_LGT] 
(
	[LOG_INIT] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [TIME_IN] ON [dbo].[DEPT_LGT] 
(
	[WONO] ASC,
	[DEPT_ID] ASC,
	[LOG_INIT] ASC,
	[DATE_IN] ASC,
	[TIME_IN] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [TIME_OUT] ON [dbo].[DEPT_LGT] 
(
	[WONO] ASC,
	[DEPT_ID] ASC,
	[LOG_INIT] ASC,
	[DATE_OUT] ASC,
	[TIME_OUT] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [WODEPTTMNO] ON [dbo].[DEPT_LGT] 
(
	[LOG_INIT] ASC,
	[WONO] ASC,
	[DEPT_ID] ASC,
	[NUMBER] ASC,
	[TMLOG_NO] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
CREATE NONCLUSTERED INDEX [WONO] ON [dbo].[DEPT_LGT] 
(
	[LOG_INIT] ASC,
	[WONO] ASC,
	[DEPT_ID] ASC,
	[NUMBER] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]



CREATE NONCLUSTERED INDEX [TIME_OUT]
	ON [dbo].[DEPT_CUR] ([WONO], [DEPT_ID], [LOG_INIT], [DATE_OUT], [TIME_OUT])
	ON [PRIMARY]

CREATE NONCLUSTERED INDEX [WODEPTTMNO]
	ON [dbo].[DEPT_CUR] ([LOG_INIT], [WONO], [DEPT_ID], [NUMBER], [TMLOG_NO])
	ON [PRIMARY]


CREATE NONCLUSTERED INDEX [WONO]
	ON [dbo].[DEPT_CUR] ([LOG_INIT], [WONO], [DEPT_ID], [NUMBER])
	ON [PRIMARY]

CREATE NONCLUSTERED INDEX [SAVEINIT]
	ON [dbo].[APCHKMST] ([SAVEINIT])
	ON [PRIMARY]

END