-- =============================================
-- Author:	Sachin B
-- Create date: 03/12/2018
-- Description:	This procedure will update WO from routing
-- Modification:
-- 04/30/2018 Sachin B Add Try/Catch and Transaction log
-- =============================================
CREATE PROCEDURE [dbo].[UpdateWORoutingWithCurrentTemplateInfo] 

@uniqKey AS CHAR(10) = '', 
@wono AS CHAR(10) = '',
@uniqeRout CHAR(10) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- 04/30/2018 Sachin B Add Try/Catch and Transaction logs
BEGIN TRY                  
	BEGIN TRANSACTION 

	  DECLARE @totalCount INT,@count INT,@deptId CHAR(4), @number NUMERIC(4,0), @uniqNumber CHAR(10), @serialStrt BIT, @firstKey CHAR(10), @RWRKKey CHAR(10), @RWQCKey CHAR(10)
			, @SCRPKey CHAR(10), @lcUniqueRec CHAR(10), @lcNewUniqNbr CHAR(10),@lcTestNo CHAR(10), @lnFgiQty NUMERIC(7,0), @lnScrpQty NUMERIC(7,0), @lnSTAGQty NUMERIC(7,0)
			, @UniqnumberD CHAR(10), @UniqueRecD CHAR(10), @lnRWRKQty NUMERIC(7,0), @lnRWQCQty NUMERIC(7,0),@Dept_idD CHAR(4), @DeptkeyD CHAR(10), @Curr_qtyD NUMERIC(7,0)
			, @lnStagQty2 numeric(7,0),@SerialYes bit, @deptIds char(4), @deptKeys char(10), @currQtyS numeric(7,0), @uniqueRecS char(10), @lnSumWCQty numeric(7,0)
			, @nBldQty numeric(7,0)
			-- declare variable to catch an error
			,@errorMessage NVARCHAR(4000),@errorSeverity INT,@errorState INT;

	SELECT * FROM Inventor WHERE Uniq_key = @uniqKey 
	IF @@ROWCOUNT=0
		BEGIN
		RAISERROR('Inventory record for this work order does not exist.  The updating shop floor traveler process can not continue to update.  This operation will be cancelled.',1,1)
		ROLLBACK TRANSACTION
		RETURN
	END

	/*---------------------------------------------------------------------------------------------------------------*/
	/* Get QuotDept records for this Uniq_key*/
	/*---------------------------------------------------------------------------------------------------------------*/
	DECLARE @ZQuotDept TABLE (nrecno INT IDENTITY, Dept_id CHAR(4), Number NUMERIC(4,0), Uniqnumber CHAR(10), SerialStrt BIT);

	INSERT @ZQuotDept
	SELECT Dept_id, Number, Uniqnumber, SerialStrt FROM QuotDept WHERE Uniq_key = @uniqKey and uniqueRout =@uniqeRout ORDER BY Number

	SET @totalCount = @@ROWCOUNT;
	
	IF (@totalCount>0)
	BEGIN	
		SET @count=0;

		WHILE @totalCount>@count
			BEGIN	
				SET @count=@count+1;
				SELECT @deptId = Dept_id, @number = Number, @uniqNumber = Uniqnumber, @serialStrt = SerialStrt FROM @ZQuotDept WHERE nrecno = @count
				IF (@@ROWCOUNT<>0)
				BEGIN
					IF @deptId = 'STAG'
						SET @firstKey = @uniqNumber
					IF @deptId = 'RWRK'
						SET @RWRKKey = @uniqNumber
					IF @deptId = 'RWQC'
						SET @RWQCKey = @uniqNumber
					IF @deptId = 'SCRP'
						SET @SCRPKey = @uniqNumber
		

					/* Check if Dept_qty record exist for the QuotDept record*/
					SELECT @lcUniqueRec = UniqueRec FROM Dept_qty WHERE Wono = @wono AND Deptkey = @uniqNumber 
			
					/* Find associated record in Dept_qty table*/
					BEGIN
					IF (@@ROWCOUNT<>0)
						UPDATE Dept_qty SET Number = @number, SerialStrt = @serialStrt WHERE UniqueRec = @lcUniqueRec
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
								VALUES (@wono,@deptId,@number,@uniqNumber,@serialStrt,@lcNewUniqNbr)
						END
					END
				END	
			END
	END

	/*---------------------------------------------------------------------------------------------------------------*/
	/* Get all Dept_qty records for this Wono to check if need to delete the record if not in QuotDept*/
	/*---------------------------------------------------------------------------------------------------------------*/
	DECLARE @ZDept_qty TABLE (nrecno INT IDENTITY, Dept_id CHAR(4), Deptkey CHAR(10), Curr_qty NUMERIC(7,0),UniqueRec CHAR(10));

	INSERT @ZDept_qty
	SELECT Dept_id, Deptkey, Curr_qty, UniqueRec FROM Dept_qty WHERE Wono = @wono ORDER BY Number
		
	SET @totalCount = @@ROWCOUNT
	SET @lnFgiQty = 0;
	SET @lnScrpQty =0;
	SET @lnSTAGQty = 0;
	SET @lnRWRKQty = 0
	SET @lnRWQCQty = 0

	IF (@totalCount>0)
	BEGIN	
		SET @count=0;
		WHILE @totalCount>@count
		BEGIN	
			SET @count=@count+1;
			SELECT @Dept_idD = Dept_id, @DeptkeyD = Deptkey, @Curr_QtyD = Curr_Qty, @UniqueRecD = UniqueRec FROM @ZDept_qty WHERE nrecno = @count
		
			IF (@@ROWCOUNT<>0)
			BEGIN
				/* Check if QuotDept record exist for the Dept_qty record*/
				SELECT @UniqnumberD = Uniqnumber FROM QuotDept WHERE Uniq_key = @uniqKey AND uniqueRout =@uniqeRout AND Uniqnumber = @DeptkeyD
						
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
						  IF @Dept_idD = 'SCRP' OR @Dept_idD = 'RWRK' OR @Dept_idD = 'RWQC'
								BEGIN
										IF @Dept_idD = 'SCRP'
										BEGIN
											SET @lnScrpQty = @lnScrpQty + @Curr_QtyD
											UPDATE InvtSer SET ID_Value = @SCRPKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
										END
										IF @Dept_idD = 'RWRK'
										BEGIN
											SET @lnRWRKQty = @lnRWRKQty + @Curr_QtyD
											UPDATE InvtSer SET ID_Value = @RWRKKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
										END
										IF @Dept_idD = 'RWQC'
										BEGIN
											SET @lnRWQCQty = @lnRWQCQty + @Curr_QtyD
											UPDATE InvtSer SET ID_Value = @RWQCKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
										END
								END
							ELSE
								BEGIN
									SET @lnSTAGQty = @lnSTAGQty + @Curr_QtyD
									UPDATE InvtSer SET ID_Value = @firstKey, ActvKey = '' WHERE Wono = @wono AND Id_Key = 'DEPTKEY' AND ID_Value = @DeptkeyD
								END
						END						
					DELETE FROM Dept_Qty WHERE UniqueRec = @UniqueRecD
				END
			END		
		END
	END

	/*---------------------------------------------------------------------------------------------------------------*/
	/* Update curr_qty for these three hard code work center from previous adjust*/
	BEGIN
		IF @lnSTAGQty<>0
		BEGIN
			/** if the start SN work center is deleted, the starting SN work center will be moved to STAG, should move all Dept_qty.curr_qty and
			** InvtSer from all WCs (except FGI and SCRP) back to STAG.
			** if lnStagQty<>0, means some qty has moved back to STAG due to some WCs are deleted, if the WO is serialiezed, will update all dept_qty, invtser before FGI back to STAG*/
			SET @lnStagQty2 = 0;

			SELECT @SerialYes = SerialYes FROM Woentry WHERE Wono = @wono
			IF @SerialYes = 1
			BEGIN
				DECLARE @ZDept_qty4SN TABLE (nrecno INT IDENTITY, Dept_id CHAR(4), Deptkey CHAR(10), Curr_qty NUMERIC(7,0),UniqueRec CHAR(10));
			
				INSERT @ZDept_qty4SN
				SELECT Dept_id, Deptkey, Curr_qty, UniqueRec FROM Dept_qty WHERE Wono = @wono
				AND Dept_id <> 'STAG' AND Dept_id <> 'FGI' AND Dept_id <> 'RWRK' AND Dept_id <> 'RWQC' AND Dept_id <> 'SCRP' AND Curr_Qty <> 0 ORDER BY Number
		
				SET @totalCount = @@ROWCOUNT;
				IF (@totalCount>0)
				BEGIN	
					SET @count=0;
					WHILE @totalCount>@count
					BEGIN	
						SET @count=@count+1;
						SELECT @deptIds = Dept_id, @deptKeys = Deptkey, @currQtyS = Curr_Qty, @UniqueRecS = UniqueRec FROM @ZDept_qty4SN WHERE nrecno = @count

						IF (@@ROWCOUNT<>0)
						BEGIN
							SET @lnStagQty2 = @lnStagQty2 + @currQtyS ;

							/* Set Dept_qty.Curr_qty to 0*/
							UPDATE Dept_qty SET Curr_Qty = 0 WHERE UniqueRec = @UniqueRecS

							/* Change InvtSer to STAG */
							UPDATE InvtSer SET Id_Value = @firstKey, ActvKey = SPACE(10) WHERE Wono = @wono AND Id_key = 'DEPTKEY   ' AND Id_Value = @deptKeys
						END
					END
				END
			END

			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnSTAGQty + @lnStagQty2 WHERE Wono = @wono AND Dept_id = 'STAG'
		END

		IF @lnFgiQty<>0
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnFgiQty WHERE Wono = @wono AND Dept_id = 'FGI'
		END

		IF @lnRWRKQty<>0
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnRWRKQty WHERE Wono = @wono AND Dept_id = 'RWRK'
		END
		IF @lnRWQCQty<>0
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnRWQCQty WHERE Wono = @wono AND Dept_id = 'RWQC'
		END

		IF @lnScrpQty<>0
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + @lnScrpQty WHERE Wono = @wono AND Dept_id = 'SCRP'
		END

		/* Now check if total WC qty is less than Woentry.BuildQty, if yes, need to adjust STAG WC qty*/
		SELECT @lnSumWCQty = ISNULL(SUM(Curr_qty),0) FROM Dept_qty WHERE Wono = @wono
		SELECT @nBldQty = BldQty FROM Woentry WHERE Wono = @wono
		IF @lnSumWCQty < @nBldQty	/*WC total qty less than WO build qty, need to adjust WC STAG qty*/
		BEGIN
			UPDATE Dept_qty SET Curr_Qty = Curr_Qty + (@nBldQty - @lnSumWCQty) WHERE Wono = @wono AND Dept_id = 'STAG'
		END
	END

COMMIT TRANSACTION              
              
END TRY      
      
BEGIN CATCH                          
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION;      
	    SELECT @errorMessage = ERROR_MESSAGE(),
        @errorSeverity = ERROR_SEVERITY(),
        @errorState = ERROR_STATE();
		RAISERROR 
		(	@ErrorMessage, -- Message text.
			 @ErrorSeverity, -- Severity.
			 @ErrorState -- State.
        );
                    
END CATCH       

END	