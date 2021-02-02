-- =============================================
-- Author:		Yelena Shmidt	
-- Create date: 08/05/2009
-- Description:	Calculate ABC based on last calculated EAU. 
-- Place new ABC code into TempAbc table. 
-- Call from ABC code setup module.  
-- 08/26/15 YS mising code for the BUY parts which takes into concideration purchase l-time
-- 09/16/15 VL Update RunningTotal to be 100 for those records which have runningtotal>100 due to rounding issue, also re-write the part that update ABC based on lead time part
-- 09/17/15 VL Found even with ROUND(2), if the total value of all parts are relly big, the part value/total part vale saved in RankPct might become 0.00 
--				Will need to increase Tempabc.RankPct to ROUND(5) to have more acurate result
-- =============================================
CREATE PROCEDURE [dbo].[sp_CalcAbcCode]
	@lcAbcBase char(3) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
SET NOCOUNT ON;
IF @lcAbcBase=''
	BEGIN
	RAISERROR('Programming error! No parameter available to sp_CalcAbcCode procedure. This operation will be cancelled.',1,1)
	RETURN	
END -- @lcAbcBase=''
IF @lcAbcBase='EAU'
	EXEC sp_AbcBasedEAU
ELSE --@lcAbcBase='EAU'
	EXEC sp_AbcBasedOnH

-- Calculate RankPct running total for 'Buy' and 'Make'
DECLARE @ExtCost numeric(10,0),@RankPct numeric(9,5),@RunningTotalB numeric(6,2),@RunningTotalM numeric(6,2),@uniq_key char(10),@Part_sourc char(10);

SET @RunningTotalM =0;
SET @RunningTotalB = 0;

DECLARE BuyABCcursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT Part_sourc,uniq_key,ExtCost,RankPct
FROM TempAbc WHERE ExtCost<>0 ORDER BY Part_sourc,ExtCost 

OPEN BuyABCcursor;



FETCH NEXT FROM BuyABCcursor INTO @Part_sourc,@uniq_key,@ExtCost,@RankPct;
BEGIN TRAN
WHILE @@FETCH_STATUS = 0
BEGIN
	IF @Part_sourc='BUY'
	BEGIN
		SET @RunningTotalB = @RunningTotalB + @RankPct ;
		UPDATE TempAbc SET RunningTotal=CASE WHEN (@RunningTotalB is null) THEN 0 ELSE @RunningTotalB END 
		WHERE Uniq_key=@uniq_key
	END
	ELSE -- @Part_sourc='BUY'
	BEGIN
		-- part_sourc='MAKE'
		SET @RunningTotalM = @RunningTotalM + @RankPct;
		UPDATE TempAbc SET RunningTotal=CASE WHEN (@RunningTotalM is null) THEN 0 ELSE @RunningTotalM END 
		WHERE Uniq_key=@uniq_key
	END  -- -- @Part_sourc='BUY'
    FETCH NEXT FROM BuyABCcursor INTO @Part_sourc,@uniq_key,@ExtCost,@RankPct
 END -- WHILE @@FETCH_STATUS = 0
COMMIT TRAN
CLOSE BuyABCcursor;
DEALLOCATE BuyABCcursor;

-- 09/16/15 VL found the RunningTotal might be more than 100 due to rounding issue, will update all Runningtotal if it's more than 100, so the records can be
-- updated and not left with blank ABC type
UPDATE TempAbc SET Runningtotal = 100 WHERE Runningtotal > 100

-- calculate running total of the AbcPct starting with the latest latter in the alphabet for the category
DECLARE InvtAbcReOrdered CURSOR LOCAL FAST_FORWARD
FOR
select A.AbcSource,Abc_Type,AbcPct,
(SELECT SUM(AbcPct) FROM InvtAbc V WHERE v.AbcSource=A.AbcSource and v.Abc_type>=A.Abc_type) as AbcRunningTotal
FROM InvtABc A 
order by abcsource,Abc_type Desc

OPEN InvtAbcReOrdered;

DECLARE @AbcSource char(4),@Abc_Type char(1),@AbcPct numeric(3,0),@AbcRunningTotal numeric(3,0);
-- pick the last letter first  
FETCH NEXT FROM InvtAbcReOrdered INTO @AbcSource,@Abc_Type,@AbcPct,@AbcRunningTotal;
BEGIN TRAN
WHILE @@FETCH_STATUS = 0
BEGIN
	--find all records that have their Runningtotal fall into range of the AbcPct and populate ABC type 
	UPDATE TempAbc SET ABC=@Abc_Type WHERE TempAbc.Part_sourc=@AbcSource and TempAbc.RunningTotal<=@AbcRunningTotal AND ABC=''
	FETCH NEXT FROM InvtAbcReOrdered INTO @AbcSource,@Abc_Type,@AbcPct,@AbcRunningTotal;
END -- WHILE @@FETCH_STATUS = 0
COMMIT TRAN
CLOSE InvtAbcReOrdered;
DEALLOCATE InvtAbcReOrdered;
--for make parts only check if AbcLt has any values entered and find inventory make parts that have ProdLtDays> AbcLt and ABC>ABC_type and overwrite their ABC code
BEGIN TRAN
-- 09/16/15 VL found the code didn't update TempABC.Abc correctly, if a part is 'C' type, but it's leadtime is bigger than 'A', it should be updated to 'A'
-- based on 9.6.3, but the code below, it randomly update those 'D' parts to 'B' or 'C', will use the scan method like 9.6.3 to be sure it updates correctly
----08/26/15 YS mising code for the BUY parts
--	UPDATE TempABc SET ABC=InvtAbc.Abc_type FROM InvtAbc WHERE TempAbc.Part_sourc='BUY' and InvtAbc.AbcSource='BUY' and InvtAbc.AbcLt>0
--	AND TempAbc.PurLtDays>InvtAbc.AbcLt and TempAbc.Abc>InvtAbc.Abc_type

--	UPDATE TempABc SET ABC=InvtAbc.Abc_type FROM InvtAbc WHERE TempAbc.Part_sourc='MAKE' and InvtAbc.AbcSource='Make' and InvtAbc.AbcLt>0
--	AND TempAbc.ProdltDays>InvtAbc.AbcLt and TempAbc.Abc>InvtAbc.Abc_type

-- {09/16/15 VL start new code to went through ABC code from A, and update tempabc accordingly
DECLARE @ZAbc_Type char(1), @ZAbcLt numeric(4,0), @ZAbcSource char(4)

-- Update ABC affected by Lead time for BUY part
DECLARE ZInvtAbc4UpdLTBUY CURSOR LOCAL FAST_FORWARD
FOR
SELECT Abc_type, AbcLT, AbcSource FROM InvtAbc WHERE AbcSource = 'BUY' ORDER BY Abc_type 

OPEN ZInvtAbc4UpdLTBUY;
FETCH NEXT FROM ZInvtAbc4UpdLTBUY INTO @ZAbc_Type,@ZAbcLt,@ZAbcSource ;
BEGIN TRAN
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE TempAbc SET ABC=@ZAbc_Type, Reason = 'Purch Lead Time' 
		WHERE PurLtDays >= @ZAbcLt AND @ZAbcLt > 0 AND Part_Sourc = 'BUY' AND Abc > @ZAbc_Type
	FETCH NEXT FROM ZInvtAbc4UpdLTBUY INTO @ZAbc_Type,@ZAbcLt,@ZAbcSource ;
END -- WHILE @@FETCH_STATUS = 0
COMMIT TRAN
CLOSE ZInvtAbc4UpdLTBUY;
DEALLOCATE ZInvtAbc4UpdLTBUY;

-- Update ABC affected by Lead time for MAKE part
DECLARE ZInvtAbc4UpdLTMAKE CURSOR LOCAL FAST_FORWARD
FOR
SELECT Abc_type, AbcLT, AbcSource FROM InvtAbc WHERE AbcSource = 'MAKE' ORDER BY Abc_type 

OPEN ZInvtAbc4UpdLTMAKE;
FETCH NEXT FROM ZInvtAbc4UpdLTMAKE INTO @ZAbc_Type,@ZAbcLt,@ZAbcSource ;
BEGIN TRAN
WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE TempAbc SET ABC=@ZAbc_Type, Reason = 'Prod Lead Time' 
		WHERE PurLtDays >= @ZAbcLt AND @ZAbcLt > 0 AND Part_Sourc = 'MAKE' AND Abc > @ZAbc_Type
	FETCH NEXT FROM ZInvtAbc4UpdLTMAKE INTO @ZAbc_Type,@ZAbcLt,@ZAbcSource ;
END -- WHILE @@FETCH_STATUS = 0
COMMIT TRAN
CLOSE ZInvtAbc4UpdLTMAKE;
DEALLOCATE ZInvtAbc4UpdLTMAKE;
-- 09/16/15 VL End}

COMMIT TRAN
END