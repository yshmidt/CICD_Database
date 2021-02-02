-- =============================================
-- Author:		Vicky Lu
-- Create date: 
-- Description:	This procedure will update WO from routing
-- Modification:
-- 03/24/16	VL:	Changed 'FGI ' to 'FGI' when the code tried to get old FGI qty, for some reasons, with a space ('FGI ') the code skipped through, has to change to 'FGI'
-- 03/28/16 VL: Added code to update RWRK and RWQC
-- =============================================
CREATE PROCEDURE [dbo].[sp_UpdWoRouting] @cUniq_key AS char(10) = '', @cWono AS char(10) = ''
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @lnCount int, @lnTotalNo int, @Dept_id char(4), @Number numeric(4,0), @Uniqnumber char(10), @SerialStrt bit,
		@lcFirstKey char(10), @lcFGIKey char(10), @lcSCRPKey char(10), @lcUniqueRec char(10), @Activ_Id char(4), 
		@Numbera numeric(4,0), @UniqNumber2 char(10), @UniqNbra char(10), @lcUniqueRecId char(10), @lcNewUniqNbr char(10),
		@lcNewUniqNbr2 char(10),@lcTestNo char(10), @Dept_idD char(4), @DeptkeyD char(10), @Curr_qtyD numeric(7,0),
		@lnFgiQty numeric(7,0), @lnScrpQty numeric(7,0), @lnSTAGQty numeric(7,0), @UniqnumberD char(10), @UniqueRecD char(10),
		@DeptkeyA char(10), @ActvKeyA char(10), @UniqueRecIdA char(10), @UniqnbraA char(10), @ChkDeptkey char(10), @lnSumWCQty numeric(7,0),
		@lnTotalNo2 int, @lnTotalNo3 int, @lnTotalNo4 int, @lnTotalNo5 int, @lnCount2 int, @lnCount3 int, @lnCount4 int, @lnCount5 int,
		@lcShopfl_Chk char(25), @lcShopfl_chk2 char(25), @lcNewUniqNbr3 char(10), @ToolRel bit, @ToolRelInt char(8), @ToolReldt smalldatetime,
		@PDMRel bit, @PDMRelInt char(8), @PDMRelDt smalldatetime, @RoutRel bit, @RoutRelInt char(8), @RoutRelDt smalldatetime, 
		@lnTotalNo6 int, @lnCount6 int, @lcDept_activ char(4),@lcUniqnumber2 char(10), @lnNumber2 numeric(4,0), @lcChklst_tit char(30), 
		@Uniqnbra2 char(10), @lcNewUniqNbr4 char(10),@lcChklst_tit2 char(30), @lnStagQty2 numeric(7,0), @lnTotalNo7 int, @lnCount7 int,
		@SerialYes bit, @Dept_idS char(4), @DeptkeyS char(10), @Curr_QtyS numeric(7,0), @UniqueRecS char(10),@lcNewUniqNbr5 char(10),
		@lcNewUniqNbr6 char(10), @lcNewUniqNbr7 char(10), @lcNewUniqNbr8 char(10), @lcNewUniqNbr9 char(10), @llSerialYesWo bit, @llSerialYesInvt bit,
		@nBldQty numeric(7,0), @lcUniq_keyChk char(10), @lnRWRKQty numeric(7,0), @lnRWQCQty numeric(7,0), @lcRWRKKey char(10), @lcRWQCKey char(10) ;


-- 07/14/15 VL added to check if inventor exist, if not, just return error in case inventor record is deleted, but woentry record exists
SELECT @lcUniq_keyChk = Uniq_key FROM Inventor WHERE Uniq_key = @cUniq_key 
IF @@ROWCOUNT=0
	BEGIN
	RAISERROR('Inventory record for this work order does not exist.  The updating shop floor traveler process can not continue to update.  This operation will be cancelled.',1,1)
	ROLLBACK TRANSACTION
	RETURN
END

/*---------------------------------------------------------------------------------------------------------------*/
/* Get QuotDept records for this Uniq_key*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZQuotDept TABLE (nrecno int identity, Dept_id char(4), Number numeric(4,0), Uniqnumber char(10), SerialStrt bit);
INSERT @ZQuotDept
	SELECT Dept_id, Number, Uniqnumber, SerialStrt
		FROM QuotDept
		WHERE Uniq_key = @cUniq_key
		ORDER BY Number

SET @lnTotalNo = @@ROWCOUNT;
	
IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @Dept_id = Dept_id, @Number = Number, @Uniqnumber = Uniqnumber, @SerialStrt = SerialStrt
			FROM @ZQuotDept WHERE nrecno = @lnCount
		IF (@@ROWCOUNT<>0)
		BEGIN
			IF @Dept_id = 'STAG'
				SET @lcFirstKey = @Uniqnumber
			IF @Dept_id = 'FGI'
				SET @lcFGIKey = @Uniqnumber
			-- 03/28/16 VL added RWRK and RWQC code
			IF @Dept_id = 'RWRK'
				SET @lcRWRKKey = @Uniqnumber
			IF @Dept_id = 'RWQC'
				SET @lcRWQCKey = @Uniqnumber
			IF @Dept_id = 'SCRP'
				SET @lcSCRPKey = @Uniqnumber
		

			/* Check if Dept_qty record exist for the QuotDept record*/
			SELECT @lcUniqueRec = UniqueRec
				FROM Dept_qty
				WHERE Wono = @cWono 
				AND Deptkey = @Uniqnumber 
			
			/* Find associated record in Dept_qty table*/
			BEGIN
			IF (@@ROWCOUNT<>0)
				UPDATE Dept_qty SET Number = @Number, SerialStrt = @SerialStrt WHERE UniqueRec = @lcUniqueRec
			ELSE
				BEGIN
					WHILE (1=1)
					BEGIN
						EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT
						SELECT @lcTestNo = UniqueRec FROM Dept_qty WHERE UniqueRec = @lcNewUniqNbr
						IF (@@ROWCOUNT<>0)
							CONTINUE
						ELSE
							BREAK
					END
					INSERT INTO Dept_qty (Wono,Dept_id,Number,DeptKey,SerialStrt, UniqueRec) 
						VALUES (@cWono,@Dept_id,@Number,@Uniqnumber,@SerialStrt,@lcNewUniqNbr)
				END
			END
		END	
	END
END

/*---------------------------------------------------------------------------------------------------------------*/
/* Get QuotDpdt records for this Uniq_key*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZQuotDpdt TABLE (nrecno int identity, Activ_Id char(4), Numbera numeric(4,0),UniqNumber char(10), UniqNbra char(10));
INSERT @ZQuotDpdt
	SELECT Activ_Id, Numbera, UniqNumber, UniqNbra
		FROM QuotDpdt
		WHERE Uniq_key = @cUniq_key
		ORDER BY UniqNumber, Numbera

SET @lnTotalNo2 = @@ROWCOUNT;

IF (@lnTotalNo2>0)
BEGIN	
	SET @lnCount2=0;
	WHILE @lnTotalNo2>@lnCount2
	BEGIN	
		SET @lnCount2=@lnCount2+1;
		SELECT @Activ_id = Activ_id, @Numbera = Numbera, @Uniqnumber2 = Uniqnumber, @UniqNbra = UniqNbra
			FROM @ZQuotDpdt WHERE nrecno = @lnCount2
		IF (@@ROWCOUNT<>0)
		BEGIN

			/* Check if Dept_qty record exist for the QuotDept record*/
			SELECT @lcUniqueRecid = UniqueRecid
				FROM Actv_qty
				WHERE Wono = @cWono 
				AND Deptkey = @Uniqnumber2 
				AND Actvkey = @UniqNbra
			
			BEGIN
			/* Find associated record in Dept_qty table*/
			IF (@@ROWCOUNT<>0)
				UPDATE Actv_qty SET Numbera = @Numbera WHERE UniqueRecid = @lcUniqueRecid
			ELSE
				BEGIN
					WHILE (1=1)
					BEGIN
						EXEC sp_GenerateUniqueValue @lcNewUniqNbr2 OUTPUT
						SELECT @lcTestNo = UniqueRecId FROM Actv_Qty WHERE UniqueRecId = @lcNewUniqNbr2
						IF (@@ROWCOUNT<>0)
							CONTINUE
						ELSE
							BREAK
					END
					INSERT INTO Actv_qty (Wono,Activ_ID,Numbera,DeptKey,ActvKey, UniqueRecId)
					VALUES (@cWono,@Activ_Id,@Numbera,@Uniqnumber2,@UniqNbra,@lcNewUniqNbr2)
				END
			END
		END	
	END
END

/*---------------------------------------------------------------------------------------------------------------*/
/* Get all Dept_qty records for this Wono to check if need to delete the record if not in QuotDept*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZDept_qty TABLE (nrecno int identity, Dept_id char(4), Deptkey char(10), Curr_qty numeric(7,0),UniqueRec char(10));
INSERT @ZDept_qty
	SELECT Dept_id, Deptkey, Curr_qty, UniqueRec
		FROM Dept_qty
		WHERE Wono = @cWono
		ORDER BY Number
		
SET @lnTotalNo3 = @@ROWCOUNT;
SET @lnFgiQty = 0;
SET @lnScrpQty =0;
SET @lnSTAGQty = 0;
-- 03/28/16 VL added RWRK and RWQC qty
SET @lnRWRKQty = 0
SET @lnRWQCQty = 0

IF (@lnTotalNo3>0)
BEGIN	
	SET @lnCount3=0;
	WHILE @lnTotalNo3>@lnCount3
	BEGIN	
		SET @lnCount3=@lnCount3+1;
		SELECT @Dept_idD = Dept_id, @DeptkeyD = Deptkey, @Curr_QtyD = Curr_Qty, @UniqueRecD = UniqueRec
			FROM @ZDept_qty WHERE nrecno = @lnCount3
		IF (@@ROWCOUNT<>0)
		BEGIN
			/* Check if QuotDept record exist for the Dept_qty record*/
			SELECT @UniqnumberD = Uniqnumber
				FROM QuotDept
				WHERE Uniq_key = @cUniq_key
				AND Uniqnumber = @DeptkeyD
						
			/* Can not find associated record in QuotDept table and Dept_qty.Curr_Qty > 0, need to adjust*/
			IF (@@ROWCOUNT=0)
			BEGIN
				IF @Curr_QtyD > 0
					BEGIN
					IF @Dept_idD = 'FGI'
						BEGIN
							SET @lnFgiQty = @lnFgiQty + @Curr_QtyD
						END
					ELSE
						-- 03/28/16 VL added code to update RWRK and RWQC
						IF @Dept_idD = 'SCRP' OR @Dept_idD = 'RWRK' OR @Dept_idD = 'RWQC'
							BEGIN
								IF @Dept_idD = 'SCRP'
									BEGIN
									SET @lnScrpQty = @lnScrpQty + @Curr_QtyD
									UPDATE InvtSer SET ID_Value = @lcSCRPKey, ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
								END
								IF @Dept_idD = 'RWRK'
									BEGIN
									SET @lnRWRKQty = @lnRWRKQty + @Curr_QtyD
									UPDATE InvtSer SET ID_Value = @lcRWRKKey, ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
								END
								IF @Dept_idD = 'RWQC'
									BEGIN
									SET @lnRWQCQty = @lnRWQCQty + @Curr_QtyD
									UPDATE InvtSer SET ID_Value = @lcRWQCKey, ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
								END
							END
						ELSE
							BEGIN
								SET @lnSTAGQty = @lnSTAGQty + @Curr_QtyD
								UPDATE InvtSer SET ID_Value = @lcFirstKey, ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
							END
					END		
				
				/*Delete Dept_qty record*/
				DELETE FROM Dept_Qty WHERE UniqueRec = @UniqueRecD
			END
		END		
	END
END

/*---------------------------------------------------------------------------------------------------------------*/
/* Get all Actv_qty records for this Wono to check if need to delete the record if not in QuotDpdt*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZActv_qty TABLE (nrecno int identity, Deptkey char(10), ActvKey char(10), UniqueRecId char(10));
INSERT @ZActv_qty
	SELECT Deptkey, Actvkey, UniqueRecId
		FROM Actv_Qty
		WHERE Wono = @cWono
		ORDER BY Deptkey
		
SET @lnTotalNo4 = @@ROWCOUNT;

IF (@lnTotalNo4>0)
BEGIN	
	SET @lnCount4=0;
	WHILE @lnTotalNo4>@lnCount4
	BEGIN	
		SET @lnCount4=@lnCount4+1;
		SELECT @DeptkeyA = Deptkey, @ActvkeyA = ActvKey, @UniqueRecIdA = UniqueRecId
			FROM @ZActv_qty WHERE nrecno = @lnCount4
		IF (@@ROWCOUNT<>0)
		BEGIN
			/* Check if QuotDept record exist for the Dept_qty record*/
			SELECT @UniqnbraA = Uniqnbra
				FROM QuotDpdt
				WHERE Uniq_key = @cUniq_key
				AND Uniqnumber = @DeptkeyA
				AND Uniqnbra = @ActvkeyA
						
			/* Can not find associated record in QuotDept table and Dept_qty.Curr_Qty > 0, need to adjust*/
			IF (@@ROWCOUNT=0)
			BEGIN
				/* now, not in quotdpdt, will try to check the actv_qty.deptkey exist in dept_qty, if yes, 
					will just update acve_qty.actvkey, otherwise, if not exist in dept_qty, will change to STAG work center*/
				SELECT @ChkDeptkey = Deptkey 
					FROM Dept_qty
					WHERE Wono = @cWono
					AND Deptkey = @DeptkeyA
				
				IF (@@ROWCOUNT<>0) /*find associated deptkey for this actv_qty*/
					BEGIN
						UPDATE InvtSer SET ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyA AND Actvkey = @ActvkeyA
					END
				ELSE
				/* didnt' find associated deptkey will change to use STAG*/
					BEGIN
						UPDATE InvtSer SET Id_Value = @lcFirstKey, ActvKey = '' WHERE Wono = @cWono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyA AND Actvkey = @ActvkeyA
					END

				
				/*Delete Dept_qty record*/
				DELETE FROM Actv_qty WHERE UniqueRecId = @UniqueRecIdA;
			END
		END		
	END
END

/*---------------------------------------------------------------------------------------------------------------*/
/* Update curr_qty for these three hard code work center from previous adjust*/
BEGIN
	IF @lnSTAGQty<>0
	BEGIN
		/** 10/16/09 VL fix an issue, if the start SN work center is deleted, the starting SN work center will be moved to STAG, should move all Dept_qty.curr_qty and
		** InvtSer from all WCs (except FGI and SCRP) back to STAG.
		** if lnStagQty<>0, means some qty has moved back to STAG due to some WCs are deleted, if the WO is serialiezed, will update all dept_qty, invtser before FGI back to STAG*/
		SET @lnStagQty2 = 0;

		SELECT @SerialYes = SerialYes 
			FROM Woentry
			WHERE Wono = @cWono
		IF @SerialYes = 1
		BEGIN
			DECLARE @ZDept_qty4SN TABLE (nrecno int identity, Dept_id char(4), Deptkey char(10), Curr_qty numeric(7,0),UniqueRec char(10));
			INSERT @ZDept_qty4SN
			-- 03/28/16 VL added RWRK and RWQC
			SELECT Dept_id, Deptkey, Curr_qty, UniqueRec
				FROM Dept_qty
				WHERE Wono = @cWono
				AND Dept_id <> 'STAG'
				AND Dept_id <> 'FGI'
				AND Dept_id <> 'RWRK'
				AND Dept_id <> 'RWQC'
				AND Dept_id <> 'SCRP'
				AND Curr_Qty <> 0
				ORDER BY Number
		
			SET @lnTotalNo7 = @@ROWCOUNT;
			IF (@lnTotalNo7>0)
			BEGIN	
				SET @lnCount7=0;
				WHILE @lnTotalNo7>@lnCount7
				BEGIN	
					SET @lnCount7=@lnCount7+1;
					SELECT @Dept_idS = Dept_id, @DeptkeyS = Deptkey, @Curr_QtyS = Curr_Qty, @UniqueRecS = UniqueRec
						FROM @ZDept_qty4SN WHERE nrecno = @lnCount7
					IF (@@ROWCOUNT<>0)
					BEGIN
						SET @lnStagQty2 = @lnStagQty2 + @Curr_QtyS ;

						/* Set Dept_qty.Curr_qty to 0*/
						UPDATE Dept_qty SET Curr_Qty = 0 WHERE UniqueRec = @UniqueRecS

						/* Change InvtSer to STAG */
						UPDATE InvtSer SET Id_Value = @lcFirstKey, ActvKey = SPACE(10) 
								WHERE Wono = @cWono
								AND Id_key = 'DEPTKEY   '
								AND Id_Value = @DeptkeyS

						/* Update Actv_qty */
						UPDATE Actv_qty SET Curr_qty = 0
								WHERE Wono = @cWono
								AND DeptKey = @DeptkeyS
					END
				END
			END
		END

		UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnSTAGQty + @lnStagQty2 WHERE Wono = @cWono AND Dept_id = 'STAG'
	END

	IF @lnFgiQty<>0
	BEGIN
		UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnFgiQty WHERE Wono = @cWono AND Dept_id = 'FGI'
	END
	-- 03/28/16 VL added RWRK and RWQC
	IF @lnRWRKQty<>0
	BEGIN
		UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnRWRKQty WHERE Wono = @cWono AND Dept_id = 'RWRK'
	END
	IF @lnRWQCQty<>0
	BEGIN
		UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnRWQCQty WHERE Wono = @cWono AND Dept_id = 'RWQC'
	END
	-- 03/28/16 VL End}

	IF @lnScrpQty<>0
	BEGIN
		UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnScrpQty WHERE Wono = @cWono AND Dept_id = 'SCRP'
	END

	/* Now check if total WC qty is less than Woentry.BuildQty, if yes, need to adjust STAG WC qty*/
	SELECT @lnSumWCQty = ISNULL(SUM(Curr_qty),0) FROM Dept_qty WHERE Wono = @cWono
	SELECT @nBldQty = BldQty FROM Woentry WHERE Wono = @cWono
	IF @lnSumWCQty < @nBldQty	/*WC total qty less than WO build qty, need to adjust WC STAG qty*/
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + (@nBldQty - @lnSumWCQty) WHERE Wono = @cWono AND Dept_id = 'STAG'
		END
END


/*---------------------------------------------------------------------------------------------------------------*/
/* Update Assychk*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZAssyChk TABLE (nRecno int identity, Uniq_key char(10), Shopfl_chk char(25));	
INSERT @ZAssyChk
	SELECT Uniq_key, Shopfl_chk
		FROM AssyChk
		WHERE Uniq_key = @cUniq_Key
		ORDER BY Shopfl_Chk

SET @lnTotalNo5 = @@ROWCOUNT
IF (@lnTotalNo5 > 0)
	BEGIN	
		SET @lnCount5=0;
		WHILE @lnTotalNo5>@lnCount5
		BEGIN	
			SET @lnCount5=@lnCount5+1;
			SELECT @lcShopfl_chk = Shopfl_chk
				FROM @ZAssyChk WHERE nRecno = @lnCount5
			IF (@@ROWCOUNT<>0)
			BEGIN
				SELECT @lcShopfl_chk2 = Shopfl_chk
					FROM JbShpChk
					WHERE Wono = @cWono
					AND Shopfl_Chk = @lcShopfl_chk
				IF (@@ROWCOUNT=0)	/* not update in JbShpChk, will insert */

				BEGIN
				WHILE (1=1)
					BEGIN
						EXEC sp_GenerateUniqueValue @lcNewUniqNbr3 OUTPUT
						SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr3
						IF (@@ROWCOUNT<>0)
							CONTINUE
						ELSE
							BREAK
					END	
				INSERT INTO JbShpChk (Wono, Shopfl_chk, JbShpchkUk) 
					VALUES (@cWono, @lcShopfl_chk, @lcNewUniqNbr3)
				END
			END
		END
	END

/* Check hard code in Jbshpchk*/
SELECT @ToolRel = ToolRel, @ToolRelInt = ToolRelInt, @ToolReldt = ToolReldt, @PDMRel = PDMRel, @PDMRelInt = PDMRelInt, @PDMRelDt = PDMRelDt,
		 @RoutRel = RoutRel, @RoutRelInt = RoutRelInt, @RoutRelDt = RoutRelDt
	FROM Inventor
	WHERE Uniq_key = @cUniq_key

BEGIN
	/*KIT IN PROCESS*/
	SELECT @lcShopfl_chk2 = Shopfl_chk
		FROM JbShpChk
		WHERE Wono = @cWono
		AND Shopfl_Chk = 'KIT IN PROCESS           '
	IF @@ROWCOUNT = 0
	BEGIN
		WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr5 OUTPUT
				SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr5
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
		INSERT INTO JbShpChk (Wono, Shopfl_chk, JbShpchkUk) 
			VALUES (@cWono, 'KIT IN PROCESS', @lcNewUniqNbr5)
	END


	/*KIT COMPLETED*/
	SELECT @lcShopfl_chk2 = Shopfl_chk
		FROM JbShpChk
		WHERE Wono = @cWono
		AND Shopfl_Chk = 'KIT COMPLETED            '
	IF @@ROWCOUNT = 0
	BEGIN
		WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr6 OUTPUT
				SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr6
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
		INSERT INTO JbShpChk (Wono, Shopfl_chk, JbShpchkUk) 
			VALUES (@cWono, 'KIT COMPLETED', @lcNewUniqNbr6)
	END


	/*TOOL/FIXTURE RELEASED*/
	SELECT @lcShopfl_chk2 = Shopfl_chk
		FROM JbShpChk
		WHERE Wono = @cWono
		AND Shopfl_Chk = 'TOOL/FIXTURE RELEASED    '
	IF @@ROWCOUNT = 0
		BEGIN
		WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr7 OUTPUT
				SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr7
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
			INSERT INTO Jbshpchk (Wono, Shopfl_chk, ChkFlag, ChkInit, ChkDate, JbShpchkUk)
				VALUES (@cWono, 'TOOL/FIXTURE RELEASED',@ToolRel,@ToolRelInt,@ToolReldt, @lcNewUniqNbr7)
		END
	ELSE
		BEGIN
			UPDATE Jbshpchk SET ChkFlag = @ToolRel, ChkInit = @ToolRelInt, ChkDate = @ToolReldt WHERE Wono = @cWono AND Shopfl_Chk = 'TOOL/FIXTURE RELEASED    '
		END


	/*PDM RELEASED*/
	SELECT @lcShopfl_chk2 = Shopfl_chk
		FROM JbShpChk
		WHERE Wono = @cWono
		AND Shopfl_Chk = 'PDM RELEASED             '
	IF @@ROWCOUNT = 0
		BEGIN
		WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr8 OUTPUT
				SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr8
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
			INSERT INTO Jbshpchk (Wono, Shopfl_chk, ChkFlag, ChkInit, ChkDate, JbShpchkUk)
				VALUES (@cWono, 'PDM RELEASED',@PDMRel,@PDMRelInt,@PDMRelDt,@lcNewUniqNbr8)
		END
	ELSE
		BEGIN
			UPDATE Jbshpchk SET ChkFlag = @PDMRel, ChkInit = @PDMRelInt, ChkDate = @PDMRelDt WHERE Wono = @cWono AND Shopfl_Chk = 'PDM RELEASED             '
		END


	/*TRAVELER RELEASED*/
	SELECT @lcShopfl_chk2 = Shopfl_chk
		FROM JbShpChk
		WHERE Wono = @cWono
		AND Shopfl_Chk = 'TRAVELER RELEASED        '
	IF @@ROWCOUNT = 0
		BEGIN
		WHILE (1=1)
			BEGIN
				EXEC sp_GenerateUniqueValue @lcNewUniqNbr9 OUTPUT
				SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr9
				IF (@@ROWCOUNT<>0)
					CONTINUE
				ELSE
					BREAK
			END	
			INSERT INTO Jbshpchk (Wono, Shopfl_chk, ChkFlag, ChkInit, ChkDate,JbShpchkUk)
				VALUES (@cWono, 'TRAVELER RELEASED',@RoutRel,@RoutRelInt,@RoutRelDt,@lcNewUniqNbr9)
		END
	ELSE
		BEGIN
			UPDATE Jbshpchk SET ChkFlag = @PDMRel, ChkInit = @PDMRelInt, ChkDate = @PDMRelDt WHERE Wono = @cWono AND Shopfl_Chk = 'PDM RELEASED             '
		END

/* Now check if extra jbshpchk record should be deleted*/

	DELETE FROM JbShpChk
		WHERE Wono = @cWono
		AND ShopFl_Chk NOT IN 
			(SELECT Shopfl_Chk
				FROM AssyChk
				WHERE Uniq_key = @cUniq_key)
		AND ShopFl_Chk <> 'KIT IN PROCESS           '
		AND ShopFl_Chk <> 'KIT COMPLETED            '
		AND ShopFl_Chk <> 'TOOL/FIXTURE RELEASED    '
		AND ShopFl_Chk <> 'PDM RELEASED             '
		AND ShopFl_Chk <> 'TRAVELER RELEASED        '

END

/*---------------------------------------------------------------------------------------------------------------*/
/* Update Wrkcklst*/
/*---------------------------------------------------------------------------------------------------------------*/
DECLARE @ZWrkCkLst TABLE (nRecno int identity, Dept_activ char(4), Uniqnumber char(10), Number numeric(4,0), Chklst_tit char(30), Uniqnbra char(10));
INSERT @ZWrkCkLst
SELECT Dept_activ, Uniqnumber, Number, Chklst_tit, Uniqnbra
		FROM WrkCkLst
		WHERE Uniq_key = @cUniq_Key;

SET @lnTotalNo6 = @@ROWCOUNT;
IF (@lnTotalNo6 > 0)
	BEGIN	
		SET @lnCount6=0;
		WHILE @lnTotalNo6>@lnCount6
		BEGIN	
			SET @lnCount6=@lnCount6+1;
			SELECT @lcDept_activ = Dept_activ,
					@lcUniqnumber2 = Uniqnumber,
					@lnNumber2 = Number,
					@lcChklst_tit = Chklst_tit,
					@Uniqnbra2 = Uniqnbra
				FROM @ZWrkCkLst WHERE nRecno = @lnCount6

			IF (@@ROWCOUNT<>0)
			BEGIN
				SELECT @lcChklst_tit2 = Chklst_tit
					FROM Jshpchkl
					WHERE Wono = @cWono
					AND Chklst_tit = @lcChklst_tit
					AND Deptkey = @lcUniqnumber2
					AND Uniqnbra = @Uniqnbra2
				IF (@@ROWCOUNT=0)	/* not update in JbShpChk, will insert */
					BEGIN
						WHILE (1=1)
						BEGIN
							EXEC sp_GenerateUniqueValue @lcNewUniqNbr4 OUTPUT
							SELECT @lcTestNo = JshpchkUk FROM JShpChkL WHERE JshpchkUk = @lcNewUniqNbr4
							IF (@@ROWCOUNT<>0)
								CONTINUE
							ELSE
								BREAK
						END	
						INSERT INTO JShpChkL (Wono, Dept_activ, Number, ChkLst_tit, Deptkey, Uniqnbra, JshpChkUk)
							VALUES (@cWono, @lcDept_activ, @lnNumber2, @lcChklst_tit, @lcUniqnumber2, @Uniqnbra2, @lcNewUniqNbr4)
					END
			END
		END
	END

/* Check extra Jshpchkl record, and delete */
BEGIN
	DELETE FROM JshpChkL
		WHERE Wono = @cWono
		AND Chklst_tit+DeptKey+UniqNbra NOT IN
			(SELECT Chklst_tit+UniqNumber+UniqNbra 
				FROM WrkckLst
				WHERE Uniq_key=@cUniq_key)

END


END	




--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------





