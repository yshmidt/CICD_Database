
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/29/2014
-- Description:	procedure to modify schedule on the existsing PO using upload 
-- requested by Paramit added to Upload2PO.prg
--12/16/14 YS missed rollback
--12/17/14 YS fixed where close
--02/07/17 VL added FC and functional currency code
-- 06/01/17 VL added functional currency code
--07/12/18 YS supname changed size from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[SP_POUpdateSchedule]
	-- Add the parameters for the stored procedure here
	@tSchdUpdate tPoSchdUpdate READONLY,
	@desktopUserInitials char(8),
	@ApproveINvtAmt	numeric(15,5)=0,
	@ApproveMroAmt numeric(15,5)=0,
	-- user will be asked in the calling program  if they want to increase CO when @lAssignNewCo=0
	-- will pass 1 if @lAssignNewCo=1, have to check later for individual PO what the current status to decide if the Co needs to be changed
	@IncreaseCO bit =0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		--04/09/14 YS added autoapprove,@nSignatures code when uploaded from PO
		-- 04/18/14 YS added @poStatus and @conum
	DECLARE @lValid bit=1,@AutoAppr4UpLoad bit,@nSignatures int,
			@AutoPoNum bit ,@nReturnCode int=0,@lAssignNewCo bit,
			@nIncreaseCO int ,    ---- will assign 0 if no increase and 1 to increase by 1 
			@lNeed2Approve bit , --- will assign 1 if approval needed and 0 if not
			@APPRVVALUE int , --- read from podeflts if 1 - approval based on the original order value, 2- based on current balance
			@UniqSupno char(10),@ponum char(15)=' ',@oldPonum char(15),@PoStatus varchar(10),@coNum numeric(3,0),
			@CurrChange varchar(max)

	--02/27/14 YS remove records from prior error log for the upload

	DELETE FROM importPoErrors

	-- variable to hold an error information

	DECLARE @ERRORNUMBER Int= 0
		,@ERRORSEVERITY int=0
		,@ERRORPROCEDURE varchar(max)=''
		,@ERRORLINE int =0
		,@ERRORMESSAGE varchar(max)=' '

	SELECT @AutoPoNum = Micssys.XxPoNoSys from MICSSYS
	--04/09/14 YS added autoapprove code when uploaded from PO
	select @AutoAppr4UpLoad=AutoAppr4UpLoad, 
		@nSignatures=PoDeflts.Signatures,
		@lAssignNewCo = podeflts.LASSIGNNEWCO,
		@APPRVVALUE = podeflts.APPRVVALUE
	FROM PoDeflts

	
	-- validate data
	DECLARE @tImport tPoSchdUpdate

	INSERT INTO @tImport SELECT * FROM @tSchdUpdate
	UPDATE @tImport SET Part_no = UPPER(RTRIM(LTRIM(Part_no))),
			Revision = RTRIM(LTRIM(Revision)),
			Itemno = CASE WHEN Itemno<>' ' THEN dbo.PADL(RTRIM(Itemno),3,'0') ELSE ItemNo END,
			Ponum=CASE WHEN POnum=' ' OR PONUM is null THEN space(15) 
						ELSE dbo.padl(UPPER(LTRIM(RTRIM(PONUM))),15,'0') END


	-- validate uniqdetno
	SELECT uniqdetno 
		  FROM @tImport t
	      WHERE NOT EXISTS (SELECT 1 from poitschd p where p.UNIQDETNO=t.uniqdetno)
		  
	IF @@ROWCOUNT <> 0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Invalid Schedule Record Identifier.',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0

	END -- @@ROWCOUNT <> 0
	--- validate ponum
	SELECT t.ponum as UploadPoNum, schd.ponum AS dataPonum
		  FROM @tImport t
		    JOIN poitschd schd ON t.uniqdetno = schd.uniqdetno
		  WHERE t.Ponum <> schd.Ponum
	IF @@ROWCOUNT <> 0
	BEGIN
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('PO Number does not match scheduled PO Number.',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		set @lValid =0

	END -- @@ROWCOUNT <> 0	

	---- mValidateMatchSupplier
	--07/12/18 YS supname changed size from 30 to 50
	SELECT t.Ponum,t.SupName,ISNULL(S.Supname,space(50)) as Supname ,ISNULL(p.Uniqsupno,space(10)) as Uniqsupno
		FROM @tImport t INNER JOIN Pomain P ON t.Ponum=P.Ponum
		LEFT OUTER JOIN Supinfo S ON P.UniqSupno=S.UniqSupno
		WHERE UPPER(RTRIM(S.Supname))<>UPPER(RTRIM(LTRIM(t.Supname))) OR t.Supname=' '
	
	IF @@ROWCOUNT <> 0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Supplier entered into the XL file doesn''t match to the supplier entered in the PO module.',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		
		set @lValid =0
	END --- IF @@ROWCOUNT <> 0	

	-- validate entered part
	SELECT t.part_no AS upldPart, t.revision as upldRevision, inv.part_no as DataPart, inv.revision as DataRevision
		  FROM @tImport t
		    JOIN poitschd schd ON t.uniqdetno = schd.uniqdetno
		    JOIN poitems poit ON schd.uniqlnno = poit.uniqlnno and POITTYPE='Invt Part'
		    JOIN inventor inv ON poit.uniq_key = inv.uniq_key
		  WHERE t.part_no <> Inv.Part_no OR t.Revision <> Inv.Revision
	UNION
	SELECT t.part_no AS upldPart, t.revision as upldRevision, poit.part_no as DataPart, poit.revision as DataRevision
		  FROM @tImport t
		    JOIN poitschd schd ON t.uniqdetno = schd.uniqdetno
		    JOIN poitems poit ON schd.uniqlnno = poit.uniqlnno and POITTYPE<>'Invt Part'
    WHERE t.part_no <> poit.Part_no OR t.Revision <> poit.Revision
	IF @@ROWCOUNT <> 0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Part No/Revision does not match PO Part No/Revision entered in the PO module',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		
		set @lValid =0
	END --- IF @@ROWCOUNT <> 0	
	---mValidateItemNo
	SELECT t.itemno AS upldItemNo, poit.itemno AS dataItemNo
		  FROM @tImport t
		    JOIN poitschd schd ON t.uniqdetno = schd.uniqdetno
		    JOIN poitems poit ON schd.uniqlnno = poit.uniqlnno
		  WHERE t.ItemNo <> poit.ItemNo
	IF @@ROWCOUNT <> 0
	BEGIN
		
		INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Item No does not match scheduled Item No',1)
		set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
							WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
		
		set @lValid =0
	END --- IF @@ROWCOUNT <> 0	
	IF @lValid=1
	BEGIN
		-- update schedule
		BEGIN TRANSACTION
		BEGIN TRY
			UPDATE Poitschd set schd_date =t.schd_date from @timport t where t.uniqdetno=poitschd.UNIQDETNO
		END TRY
		BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION

			INSERT INTO importPoErrors (ErrorMessage)
				VALUES 
			('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
			'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
			'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
			'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
			'Error Message: '+@ERRORMESSAGE)
			return -1

		END CATCH
		BEGIN TRY
		DECLARE cPoNum CURSOR FORWARD_ONLY FOR
			SELECT Distinct t.PoNum,Pomain.Postatus,Pomain.Conum
				FROM @tImport t inner join Pomain on t.ponum=pomain.ponum
			OPEN cPonum
			FETCH cPoNum INTO @ponum,@postatus,@coNum
			WHILE (@@fetch_status = 0)
			BEGIN
			-- check if rolling the change order automatically
				select @nIncreaseCo = 
					CASE WHEN @lAssignNewCo=0 and @IncreaseCO=1 and @postatus<>'NEW' and @postatus<>'PENDING' THEN 1
					WHEN @lAssignNewCo=0 and @IncreaseCO=0 and @postatus<>'NEW' and @postatus<>'PENDING' THEN 0
					WHEN @lAssignNewCo=0 or @postatus='NEW' or @postatus='PENDING' Then 0
					WHEN @POSTATUS='OPEN' OR @postatus='CANCEL' THEN 1 ELSE 1 END
				
				-- check if need approval
				select @lNeed2Approve =
				CASE WHEN @AutoAppr4UpLoad = 0 THEN 0
					 WHEN @postatus='NEW' or @postatus='PENDING' or @postatus='EDITING' Then 0	
					 ELSE 1 END		
				 
				-- if approval is required check the amount allowed to approved vs amount on the PO
				If (@lNeed2Approve = 1)
				BEGIN	
					SELECT Ponum,Poittype, CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END AS Amt
						FROM PoItems
					WHERE Poittype<>'MRO'
					and Poitems.ponum=@ponum
					GROUP BY Ponum,PoitType
					HAVING CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END>@ApproveINvtAmt 
					UNION 
					SELECT Ponum,Poittype,CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END AS Amt
					FROM PoItems
					WHERE Poittype='MRO'
					and Poitems.ponum=@ponum
					GROUP BY PONUM,PoitType
					HAVING CASE WHEN @APPRVVALUE=1 THEN SUM(CostEach*Ord_qty) ELSE SUM(CostEach*(poitems.Ord_qty-poitems.ACPT_QTY)) END>@ApproveMroAmt  
				
					IF @@ROWCOUNT <>0
					BEGIN
						--12/16/14 YS missed rollback
						IF @@TRANCOUNT>0
						ROLLBACK TRANSACTION

						INSERT INTO importPoErrors (ErrorMessage,stopUpload) VALUES ('Add Item Upload: The total of PO # '+@ponum+' exceeds your approval limit.',1)
						set @nReturnCode=CASE WHEN @nReturnCode=0 THEN 2
								WHEN @nReturnCode=3 THEN 5
							ELSE 2 END
						GOTO RETURNCODE 
					END -- IF @@ROWCOUNT <>0
				END  -- (@lNeed2Approve = 1) 
				--- update POmain 
				-- if not auto approve re-set approval names
				-- work on status and approval name; here the logic
				--1. Auto Approve On 
				--   Original Status = 'OPEN' or 'CLOSED' or 'CANCEL' - New status ='OPEN', both  approval names entered
				--   Original Status = 'NEW' or 'PENDING' or 'EDITING' - New Status is 'NEW', 'NEW' , 'EDITING' correspondingly, both approval names cleared. 
				--   Even if auto approve but the po was in 'EDITING' prior to adding new items and was  not approve, has to be manually approve
				--2. Auto Approve Off
				--   Original Status = 'OPEN' or 'CLOSED' or 'CANCEL' - New status ='EDITING', both approval names cleared
				--   Original Status = 'NEW' or 'PENDING' or 'EDITING' - New Status is 'NEW', 'NEW' , 'EDITING' correspondingly, both approval names cleared .  
				UPDATE Pomain SET 
					POmain.VERINIT = @desktopUserInitials ,
					Pomain.PoTotal = PI.POTotal +Pomain.ShipChg,
					-- 06/01/17 VL comment out the PoTax code, it's not calculated by Pomain.Tax_pct, it's calculated from poitemstax, will update in next sql statement
					--Pomain.PoTax = PI.TaxTotal+CASE WHEN Pomain.ShipChg=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChg * POmain.ScTaxPct)/100,2) END,
					-- 02/07/17 VL added FC and functional currency code
					Pomain.PoTotalFC = PI.POTotalFC +Pomain.ShipChgFC,
					-- 06/01/17 VL comment out the PoTax code, it's not calculated by Pomain.Tax_pct, it's calculated from poitemstax, will update in next sql statement
					--Pomain.PoTaxFC = PI.TaxTotalFC+CASE WHEN Pomain.ShipChgFC=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChgFC * POmain.ScTaxPct)/100,2) END,
					Pomain.PoTotalPR = PI.POTotalPR +Pomain.ShipChgPR,
					-- 06/01/17 VL comment out the PoTax code, it's not calculated by Pomain.Tax_pct, it's calculated from poitemstax, will update in next sql statement
					--Pomain.PoTaxPR = PI.TaxTotalPR+CASE WHEN Pomain.ShipChgPR=0 OR POmain.ScTaxPct=0 THEN 0 ELSE ROUND((POmain.ShipChgPR * POmain.ScTaxPct)/100,2) END

					Pomain.FinalName = CASE WHEN POSTATUS='NEW' OR POSTATUS='PENDING' OR POSTATUS='EDITING' THEN ' '
											WHEN @lNeed2Approve=1 AND (POSTATUS = 'OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN @desktopUserInitials 
											ELSE ' ' END,
					Pomain.AppvName = CASE WHEN POSTATUS='NEW' OR POSTATUS='PENDING' OR POSTATUS='EDITING' THEN ' '
											WHEN @lNeed2Approve=1 AND (POSTATUS = 'OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN @desktopUserInitials 
											ELSE ' ' END,
					Pomain.Postatus = CASE WHEN @lNeed2Approve=1 AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN 'OPEN' 
											WHEN Pomain.POSTATUS = 'NEW' OR POSTATUS='PENDING' THEN 'NEW' 
											WHEN POSTATUS='EDITING' THEN 'EDITING'
											WHEN @lNeed2Approve=0 AND (Pomain.PoStatus='OPEN' OR Pomain.PoStatus='CLOSED' OR Pomain.PoStatus='CANCEL') THEN 'EDITING'
										ELSE Pomain.Postatus END ,
					Pomain.Conum = Pomain.Conum+@nIncreaseCO 
								-- 02/07/17 VL added FC and functional currency code
								FROM (SELECT SUM(ROUND(CostEach * Ord_qty,2)) as POTotal, SUM(ROUND((CostEach * Ord_qty * Tax_Pct)/100,2)) as TaxTotal,
										SUM(ROUND(CostEachFC * Ord_qty,2)) as POTotalFC, SUM(ROUND((CostEachFC * Ord_qty * Tax_Pct)/100,2)) as TaxTotalFC,
										SUM(ROUND(CostEachPR * Ord_qty,2)) as POTotalPR, SUM(ROUND((CostEachPR * Ord_qty * Tax_Pct)/100,2)) as TaxTotalPR   
												FROM Poitems WHERE Ponum=@ponum) PI
					WHERE Pomain.Ponum=@ponum

				-- {06/01/17 VL added code to update Potax from poitemstax table and also consider ShipChg and ScTaxPct
				UPDATE Pomain SET	POTAX = Tax.TotalTax + CASE WHEN (ShipChg = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChg*ScTaxPct/100,2) END,
									PoTaxfc = tax.TotalTaxFc + CASE WHEN (ShipChgFC = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgFC*ScTaxPct/100,2) END,
									PoTaxPR = tax.TotalTaxPR + CASE WHEN (ShipChgPR = 0 OR Is_ScTax = 0) THEN 0 ELSE ROUND(ShipChgPR*ScTaxPct/100,2) END
					FROM Pomain p inner join (
						SELECT t.ponum, t.uniqlnno,ROUND(ISNULL(SUM(d.ExtAmt*t.tax_rate/100),0.00),2) as TotalTax,
							case when dbo.fn_IsFCInstalled()=1 then ROUND(isnull(SUM(ExtAmtFC*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxFc,
							case when dbo.fn_IsFCInstalled()=1 then ROUND(isnull(SUM(ExtAmtPR*Tax_rate/100),0.00),2) else 0.00 end as TotalTaxPR
						from poitemsTax t 
						cross apply (select i.IS_TAX, i.ORD_QTY*costeach as ExtAmt,i.ORD_QTY*costeachfc as ExtAmtFc, i.ORD_QTY*costeachPR as ExtAmtPR, uniqlnno from poitems I where i.UNIQLNNO=t.uniqlnno and i.ponum = @ponum and I.IS_TAX=1) D
						where tax_rate<>0 and d.IS_TAX=1
						GROUP BY  t.ponum,t.uniqlnno
						) Tax on p.ponum= tax.ponum
					WHERE p.Ponum = @Ponum
				-- 06/01/17 VL End}


				-- change order
								
			   SELECT @CurrChange = 'CO # :'+CONVERT(char(3), Pomain.Conum)+', Date/Time: '+CONVERT(varchar(30),getdate(),126)+
							', By User: '+RTRIM(@desktopUserInitials)+', PO Total:$'+ CONVERT(varchar(15),Pomain.POTOTAL)+
							'. Changes were made using XL automation for adding new items to an existing PO. List of changes:'
							FROM Pomain WHERE PONUM=@ponum
				--12/17/14 YS fixed were 
				SELECT @CurrChange = @CurrChange +CHAR(13)+CHAR(9)+
						'Schedule Date for Item Number '+CONVERT(varchar(3),D.ITEMNO) +
						CASE WHEN D.UNIQ_KEY <>' ' THEN ', Part # '+RTRIM(I.Part_no)+	
															CASE WHEN i.REVISION<>' ' THEN ', Rev '+RTRIM(I.Revision) ELSE '' END
								WHEN D.UNIQ_KEY = ' ' and D.Part_no<>' ' THEN ', Part # '+RTRIM(D.Part_no)
								WHEN D.UNIQ_KEY = ' ' and D.Descript<>' ' THEN ', Part '+RTRIM(D.Descript)
								ELSE '' END +' changed.'								
						FROM @tImport t INNER JOIN Poitschd S on t.uniqdetno=s.UNIQDETNO 
						INNER JOIN Poitems D on d.UNIQLNNO=S.UNIQLNNO
						LEFT OUTER JOIN INVENTOR I on D.UNIQ_KEY =I.uniq_key WHERE t.PONUM=@ponum Order By d.ITEMNO 		
				Update POMAIN SET CurrChange =@CurrChange where PONUM=@ponum
					
				FETCH cPoNum INTO @ponum,@postatus,@coNum	 	
			END  --  (@@fetch_status = 0)
			--04/23/14 YS close cursor
			CLOSE cPoNum
			DEALLOCATE cPoNum
	END TRY
	BEGIN CATCH
		SELECT @ERRORNUMBER =ISNULL(ERROR_NUMBER(),0)
				,@ERRORSEVERITY =ISNULL(ERROR_SEVERITY(),0)
				,@ERRORPROCEDURE = ISNULL(ERROR_PROCEDURE(),' ')
				,@ERRORLINE = ISNULL(ERROR_LINE(),0)
				,@ERRORMESSAGE =ISNULL(ERROR_MESSAGE(),'')
		
			IF @@TRANCOUNT>0
				ROLLBACK TRANSACTION
			INSERT INTO importPoErrors (ErrorMessage)
				VALUES ('Error #: '+CONVERT(char,@ERRORNUMBER)+CHAR(13)+
				'Error Severity: '+CONVERT(char,@ERRORSEVERITY)+CHAR(13)+
				'Error Procedure: ' +@ERRORPROCEDURE +CHAR(13)+
				'Error Line: ' +convert(char,@ERRORLINE)+CHAR(13)+
				'Error Message: '+@ERRORMESSAGE)
			return -1
	END CATCH
	IF @@TRANCOUNT>0
		COMMIT TRANSACTION
	-- use GOTO LABEL to alter the execution
	GOTO RETURNCODE
	END -- if @lValid=1 
	--  use GOTO LABEL to alter the execution
	-- define LABEL 
	RETURNCODE: 
	SELECT @nReturnCode as ReturnCode
END