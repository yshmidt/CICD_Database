CREATE TABLE [dbo].[BOM_REF] (
    [UNIQBOMNO]          CHAR (10)       CONSTRAINT [DF__BOM_REF__UNIQBOM__125EB334] DEFAULT ('') NOT NULL,
    [REF_DES]            VARCHAR (50)    CONSTRAINT [DF__BOM_REF__REF_DES__1352D76D] DEFAULT ('') NOT NULL,
    [NBR]                NUMERIC (7)     CONSTRAINT [DF__BOM_REF__NBR__1446FBA6] DEFAULT ((0)) NOT NULL,
    [ASSIGN]             CHAR (10)       CONSTRAINT [DF__BOM_REF__ASSIGN__153B1FDF] DEFAULT ('') NOT NULL,
    [BODY]               CHAR (8)        CONSTRAINT [DF__BOM_REF__BODY__162F4418] DEFAULT ('') NOT NULL,
    [XOR]                NUMERIC (10, 5) CONSTRAINT [DF__BOM_REF__XOR__17236851] DEFAULT ((0)) NOT NULL,
    [YOR]                NUMERIC (10, 5) CONSTRAINT [DF__BOM_REF__YOR__18178C8A] DEFAULT ((0)) NOT NULL,
    [ORIENT]             NUMERIC (7, 3)  CONSTRAINT [DF__BOM_REF__ORIENT__190BB0C3] DEFAULT ((0)) NOT NULL,
    [UNIQUEREF]          CHAR (10)       CONSTRAINT [DF__BOM_REF__UNIQUER__19FFD4FC] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [IsSynchronizedFlag] BIT             CONSTRAINT [DF__BOM_REF__IsSynch__6EEDBBCA] DEFAULT ((0)) NULL,
    CONSTRAINT [BOM_REF_PK] PRIMARY KEY CLUSTERED ([UNIQUEREF] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NBR]
    ON [dbo].[BOM_REF]([NBR] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQBOMNO]
    ON [dbo].[BOM_REF]([UNIQBOMNO] ASC);


GO
-- =============================================
-- Author:		Sachin Shevale
-- Create date: 09/14/2014
-- Description:	Update trigger for  table
-- =============================================
CREATE TRIGGER [dbo].[BOM_REF_UPDATE]
   ON  [dbo].[BOM_REF]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE BOM_REF SET 
    -- Insert statements for trigger here
	 IsSynchronizedFlag= 
						CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
					    WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END					
					FROM inserted I inner join deleted D on i.UNIQUEREF =d.UNIQUEREF
					where I.UNIQUEREF =BOM_REF.UNIQUEREF
 --09-24-2015 Delete the Uniquenum from SynchronizationMultiLocationLog table if exists with same UNIQ_KEY so all location pick again
	IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			DELETE FROM SynchronizationMultiLocationLog 
				where EXISTS (Select 1 from Inserted where IsSynchronizedFlag=0 and Inserted.UNIQUEREF=SynchronizationMultiLocationLog.Uniquenum);
			END		
END
GO
-- =============================================
-- Author:		<Vicky Lu>
-- Create date: <04/09/2015>
-- Description:	<A delete trigger is created to log 'BomRefDeletLog' table with detail information about from which machine, deleted date/time stamp to trace why sometimes the bom_ref records were disappeared
----09-14-15- Sachin s remove the above code for record already deleted
-- =============================================
CREATE TRIGGER  [dbo].[BOM_REF_Delete]
   ON  [dbo].[BOM_REF] 
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	INSERT INTO BomRefDeleteLog (Uniqbomno, Ref_des, Nbr, UniqueRef, Userinfo)
		SELECT Uniqbomno, Ref_des, Nbr, UniqueRef, LTRIM(RTRIM(HOST_NAME())) AS Userinfo
			FROM DELETED   
   --DELETE FROM BOM_REF WHERE UNIQUEREF in (SELECT UNIQUEREF FROM Deleted)     
   ----09-14-15- Sachin s remove the above code for record already deleted
      INSERT INTO [dbo].[SynchronizationDeletedRecords]
           ([TableName]
           ,[TableKey]
           ,[TableKeyValue])
     SELECT
           'BOM_REF'
           ,'UNIQUEREF'
           ,Deleted.UNIQUEREF from Deleted
		   
END