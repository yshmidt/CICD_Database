-- Batch submitted through debugger: SQLQuery1.sql|7|0|C:\Users\Alena\AppData\Local\Temp\~vsC311.sql


-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <11/10/09>
-- Description:	<Debug trigger>
-- =============================================
CREATE PROCEDURE  [dbo].[Debug_trigger] 
	--@nUniqueId as int,@nUpdateQty as numeric(12,2)=600
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--debug delete trigger for gl_nbrs
	--delete from gl_nbrs where gl_nbr='1415000-00-00' 
	-- debug insert trigger
	--insert into gl_nbrs (gl_nbr) VALUES ('1111111-00-00')	
	-- devug update for invtsetup
	--DECLARE @lRecVer as TimeStamp	
--	SELECT @lRecVer=RecVer from InvtSetup
	--SET TRANSACTION ISOLATION LEVEL SNAPSHOT
	--BEGIN TRANSACTION
--	update Invtsetup SET lUseIpKey=@lIpKeyUpdate WHERE RecVer=@lRecVer
	--DECLARE @RecRev as Timestamp, 
	--DECLARE @lcQty_oh as numeric(12,2)
	----SELECT @RecRev= RecRev,@lcQty_oh=Qty_oh from TestTable where uniqueid=@nUniqueId 
	--SELECT @lcQty_oh=Qty_oh from TestTable where uniqueid=@nUniqueId 
	--SELECT @lRecVer= RecRev from TestTable where uniqueid=@nUniqueId
	--UPDATE TestTable SET QTY_oh=Qty_oh+@nUpdateQty where uniqueid=@nUniqueId 
	--COMMIT
	--SELECT @@ROWCOUNT	
	--SELECT @lcQty_oh= Qty_oh from TestTable where uniqueid=@nUniqueId
	--SELECT @@ROWCOUNT	
	--UPDATE INVENTOR SET LABORCOST = 2.00 where UNIQ_KEY='_01F15SZ7Z'
	 -- test deleted trigger for inventor table
	 --DELETE FROM Inventor WHERE Uniq_key='_01F15SZPJ'
	  INSERT INTO Invt_rec(W_KEY,UNIQ_KEY,[DATE],QTYREC,COMMREC,GL_NBR,INVTREC_NO,U_OF_MEAS,SAVEINIT,TRANSREF,UNIQMFGRHD) VALUES ('_2ZK1B7U0L','_2ZK1B6IIB',CAST('07/22/2010 16:23:31' AS SmallDateTime),         20.00,'BEGINNING RAW MATL. INV.','1380000-00-00','_2ZL0Z4TF7','EACH','ONE','Test update fail','_2ZK1B7JTR')
	--COMMIT
END