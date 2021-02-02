-- =============================================
-- Author:		Yelena Shmidt
-- Create date: ??
-- Description:	Part leveling and mrp_code column updating for MRP and costroll module
-- Modified: 09/15/15 YS avoid updating records with the same code. This ways LastChangeDt in the Inventor table will not be aupdated
-- when mrp_code is the column that is changed.
-- 09/28/15 YS remove calculation for the @lnMaxLevel, because if the level did not change at all the variable will not get any value.
-- 11/08/15 YS update all the buy and consign parts with mrp_code 0. Found in the Paramit data that the code was other than 0 created problem for the buy parts on the Sales Order
-- 12/15/17 VL changed from CTE cursor to table variable, and change NOT IN to NOT EXISTS to speed up
-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
-- 01/02/18 VL Found still has to use CTE for PartLevel that will have loop to find all next levels, the new code seems only speed  10 seconds (50 sec to 40 sec)
-- 01/02/18 VL Changed from using table variable to temp table, because wanted to add index to speed up, but only SQL2014 can add regular index on table variable
---01/19/19 YS part_no is now 35 characters
-- =============================================
CREATE PROCEDURE [dbo].[Sp_Levelparts]
@cModule  varchar(20)='MRP'
AS
	-- Add the SELECT statement with parameter references here
BEGIN
-- 12/15/17 VL create table variable to replace CTE cursor to speed up
-- 01/02/18 VL comment out @PartLevel table variable
--DECLARE @PartLevel TABLE (Bomparent char(10),Part_no char(25),Revision char(8), Uniq_Key char(10),Part_sourc char(10),Make_buy bit,BOM_STATUS char(10), Mrp_Code numeric(2,0))
--DECLARE @LevlReverse TABLE (Part_no char(25), REVISION char(8),UNIQ_KEY char(10),PART_SOURC char(10),MAKE_BUY bit, Mrp_code numeric(2,0), MaxCode numeric(2,0))
--,
					-- 12/25/17 YS none unique index cannot be created for the table variable prio to SQL 2014. I will create an unique index, but need to check if the speed is still improved.
		--- looking at the code inserted in this table assuming that uniq__key is unique and not null
				--INDEX Uniq_key NONCLUSTERED (Uniq_key))
				--UNIQUE NONCLUSTERED (Uniq_key))
-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable
IF OBJECT_ID('tempdb..#LevlReverse') IS NOT NULL
    DROP TABLE #LevlReverse
---01/19/19 YS part_no is now 35 characters
CREATE TABLE #LevlReverse (Part_no char(35), REVISION char(8),UNIQ_KEY char(10),PART_SOURC char(10),MAKE_BUY bit, Mrp_code numeric(2,0), MaxCode numeric(2,0))
CREATE NONCLUSTERED INDEX IDX ON #LevlReverse (Uniq_key)


declare @lnMaxLevel int =1

BEGIN TRANSACTION
BEGIN TRY

--11/08/15 YS remove mrp_code from buy parts, not sure how the code got populated in the first place
UPDATE Inventor set mrp_code=0 where (PART_SOURC='BUY' or part_sourc='CONSG') and mrp_code<>0

-- 12/15/17 VL changed from CTE to table variable to speed up
-- 01/02/18 VL changed back to use CTE for PartLevel because it can loop to find
;WITH PartLevel 
AS
(
SELECT CAST('' as CHAR(10)) as Bomparent,Part_no,Revision, Uniq_Key,Part_sourc,Make_buy,Inventor.BOM_STATUS, cast(1 as Integer) AS Mrp_Code 
	FROM Inventor 
	WHERE (Part_Sourc = 'MAKE' OR Part_Sourc='PHANTOM' )
	--AND Uniq_Key NOT IN (SELECT Uniq_Key FROM Bom_Det ) 
	AND NOT EXISTS (SELECT Uniq_Key FROM Bom_Det WHERE Bom_det.uniq_key = Inventor.Uniq_key) 
	UNION All
	SELECT  B.BomParent,I.Part_no,I.REVISION, B.Uniq_Key,I.PART_SOURC,I.MAKE_BUY,P.BOM_STATUS,  P.Mrp_Code+1 
		FROM Bom_Det B INNER JOIN  PartLevel P ON B.BomParent = P.Uniq_Key 
		INNER JOIN Inventor I ON I.UNIQ_KEY =B.UNIQ_KEY 
		WHERE (I.Part_Sourc = 'MAKE' OR I.Part_Sourc='PHANTOM'  ) )
-- 01/02/18 VL comment out the code that created on 12/15/17 with table variable @PartLevel
--,
--LevlReverse AS
--(SELECT	PART_NO,REVISION,UNIQ_KEY,PART_SOURC,MAKE_BUY,MAX(Mrp_code) as Mrp_code,(SELECT MAX(Mrp_code) from PartLevel) as MaxCode  
--	from PartLevel GROUP BY PART_NO,REVISION,UNIQ_KEY,PART_SOURC,MAKE_BUY)
---- 12/15/17 VL also changed from NOT IN to NOT EXISTS
--INSERT INTO @PartLevel
--SELECT CAST('' as CHAR(10)) as Bomparent,Part_no,Revision, Uniq_Key,Part_sourc,Make_buy,Inventor.BOM_STATUS, cast(1 as Integer) AS Mrp_Code 
--	FROM Inventor 
--	WHERE (Part_Sourc = 'MAKE' OR Part_Sourc='PHANTOM' )
--	AND NOT EXISTS (SELECT Uniq_Key FROM Bom_Det WHERE Bom_det.uniq_key = Inventor.Uniq_key) 
--	UNION All
--	SELECT  B.BomParent,I.Part_no,I.REVISION, B.Uniq_Key,I.PART_SOURC,I.MAKE_BUY,P.BOM_STATUS,  P.Mrp_Code+1 
--		FROM Bom_Det B INNER JOIN  @PartLevel P ON B.BomParent = P.Uniq_Key 
--		INNER JOIN Inventor I ON I.UNIQ_KEY =B.UNIQ_KEY 
--		WHERE (I.Part_Sourc = 'MAKE' OR I.Part_Sourc='PHANTOM'  ) 

-- 01/02/18 VL changed to save to temp table
INSERT INTO #LevlReverse 
	SELECT	PART_NO,REVISION,UNIQ_KEY,PART_SOURC,MAKE_BUY,MAX(Mrp_code) as Mrp_code,(SELECT MAX(Mrp_code) from PartLevel) as MaxCode  
	from PartLevel GROUP BY PART_NO,REVISION,UNIQ_KEY,PART_SOURC,MAKE_BUY

UPDATE INVENTOR SET MRP_CODE=l.MaxCode+1-l.Mrp_code
		-- 09/28/15 YS remove calculation for the lnMaxLevel because if the level did not change at all the variable will not get any value.
		--,@lnMaxLevel=l.MaxCode 
		FROM #LevlReverse L where Inventor.UNIQ_KEY=l.UNIQ_KEY  
			-- 09/15/15 YS avoid updating records with the same code. 
			and Inventor.MRP_CODE<>l.MaxCode+1-l.Mrp_code
IF @cModule='COSTROLL'
BEGIN
	-- 09/28/15 YS  calculate lnMaxLevel here.
	SELECT @lnMaxLevel=MAX(Mrp_code) from Inventor
	IF EXISTS (select 1 from ROLLMAKE )
		UPDATE ROLLMAKE  SET RunDate=GETDATE(),MaxLevel=@lnMaxLevel,CurLevel=1;
	ELSE
		INSERT INTO RollMake (Uniq_field,RunDate,MaxLevel,CurLevel) VALUES (dbo.fn_GenerateUniqueNumber(),GETDATE(),@lnMaxLevel,1);
END


-- 01/02/18 VL use temp table instead of table variable, Paramit is still using SQL2012 and can not use regular index on table variable, drop temp tables
IF OBJECT_ID('tempdb..#LevlReverse') IS NOT NULL
    DROP TABLE #LevlReverse


END TRY

BEGIN CATCH
	RAISERROR('Error occurred in cost roll leveling. This operation will be cancelled.',1,1)
	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
END CATCH

IF @@TRANCOUNT > 0
    COMMIT TRANSACTION;


END
	