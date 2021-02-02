CREATE TABLE [dbo].[TestTable] (
    [UniqueID] INT        IDENTITY (1, 1) NOT NULL,
    [CustName] CHAR (25)  CONSTRAINT [DF_TestTable_CustName] DEFAULT ('') NOT NULL,
    [Qty_oh]   NCHAR (10) CONSTRAINT [DF_TestTable_Qty_oh] DEFAULT ((0)) NOT NULL,
    [recrev]   ROWVERSION NOT NULL
);


GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <05/20/10>
-- Description:	<This is an update test triiger>
-- =============================================
CREATE TRIGGER [dbo].[Test_update]
   ON  [dbo].[TestTable]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	

	DECLARE @lnQtyOld as Numeric(12,2),@lnQtyOnDisk as Numeric(12,2),@lnQtyInUpdate as Numeric(12,2)
	--DECLARE @RecRevOld as timestamp, @RecRevDisk As TimeStamp, @RecRevinUpdate As TimeStamp
	
	SELECT @lnQtyOld=Qty_oh FROm DELETED
	--SELECT @RecRevOld=RecRev FROm DELETED
	SELECT @lnQtyOnDisk=Qty_oh FROM TestTable 
	--SELECT @RecRevDisk=RecRev  FROM TestTable 
	SELECT @lnQtyInUpdate=Qty_oh FROM Inserted
	--SELECT @RecRevinUpdate=RecRev FROM Inserted

--	IF (@lnQtyOld IS NULL)
--	BEGIN
--		 raiserror('While you were working, another user has changed the data',1,1)
--		return
--	END

	--IF (@lnQtyOld=@lnQtyOnDisk)
	--BEGIN
	--	update TestTable set CustName=Inserted.Custname,Qty_oh=Inserted.Qty_oh FROM Inserted where Inserted.Uniqueid=TestTable.UniqueID
	--END	
	
END
