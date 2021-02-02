-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 12/16/2014  Happy Hanukkah
-- Description:	This procedure was created for the custom utilities (Paramit SQL Migration)
-- It will close the KIT for a job
-- right now I will call it one job at a  time. we can change it to close multiple jobs if required.
-- created new form for user to enter a date and impact on GL autoclosekitSQL form
-- all the overissue quantities will be charge to the job (issued)
-- 08/27/15 VL Increase field lengths for @Zresult
-- 06/13/18 Kit process was completly changed. I will comment the code and just 
-- =============================================
CREATE PROCEDURE [dbo].[sp_UtilsAutoCloseKIT]
	-- Add the parameters for the stored procedure here
	@wono char(10)=' ',
	@impactGL bit = 1 ,
	@userid char(8)='Autokit',
	@Updated bit = 1 OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	if @wono=' '
	BEGIN
		SET @Updated=0
		RETURN 
    END
	SET @wono=dbo.padl(ltrim(rtrim(@wono)),10,'0')
    -- Insert statements for procedure here
	declare @WipGlNbr char(13)=' ',@uniq_key char(10),@PRJUNIQUE char(10),@Due_Date smalldatetime,
	@UseSetScrp bit,@StdBldQty Numeric(7,0),@bldQty Numeric(7,0),@TotalStd numeric(13,5),@SetupScrapCost numeric(13,5),@RollupCost numeric(13,5),
	@TotalStdWithoutCEILING  numeric(12,5), @TotalXCost  numeric(12,5), @TotalXCostDiff  numeric(12,5),@IssuUpCost numeric(13,5),
	@mfgrGlNbr char(13),@roundGlNbr char(13),@transDate smalldatetime


/* 06/13/18 YS comment out for now
	set @transDate=getdate()
	select @uniq_key =Uniq_key,@PRJUNIQUE =prjunique,@Due_Date=DUE_DATE,@bldQty=BLDQTY from woentry where wono=@wono
	select @UseSetScrp = UseSetScrp, 
		@StdBldQty=CASE WHEN UseSetScrp=1 THEN StdBldQty ELSE 0 END
	FROM Inventor where uniq_key=@uniq_key
	
	SELECT @WipGlNbr=dbo.fn_GetWIPGl()
	SELECT @mfgrGlNbr=InvSetup.MANU_GL_NO,
		@roundGlNbr=InvSetup.RUNDVAR_GL FROM InvSetup
	if @WipGlNbr=' ' OR @mfgrGlNbr=' ' or @roundGlNbr=' '
	BEGIN
		-- return problem
		SET @Updated=0
		RETURN 
	END
	-- include unallocate code for all records for that work order
	-- unallocate all records allocated to @wono
	BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO Invt_res (Invtres_no, W_key,Uniq_key,[Datetime],Qtyalloc,Wono,Lotcode,Expdate,Reference,Ponum,Saveinit,RefInvtres,SerialNo, SerialUniq)
			SELECT dbo.fn_GenerateUniqueNumber(),A.W_key,A.Uniq_key,@transDate,-A.Qtyalloc,@Wono,
							A.Lotcode,A.Expdate,A.Reference,A.Ponum,@Userid,A.Invtres_no,A.SerialNo, A.SerialUniq
		FROM Invt_res A where A.Wono=@wono and A.Fk_Prjunique=' ' and qtyAlloc>0 and NOT EXISTS (SELECT 1 from Invt_res U where U.REFINVTRES=A.INVTRES_NO and u.wono=@wono)
		-- unallocate all records allocated to a project
		INSERT INTO Invt_res (Invtres_no, W_key,Uniq_key,[Datetime],Qtyalloc,Lotcode,Expdate,Reference,Ponum,Saveinit,RefInvtres,Fk_PrjUnique, SerialNo, SerialUniq)
			SELECT  dbo.fn_GenerateUniqueNumber(), A.W_key,A.Uniq_key,@transDate,-A.Qtyalloc,
					A.Lotcode,A.Expdate,A.Reference,A.Ponum,@Userid,A.Invtres_no,A.Fk_PrjUnique, A.SerialNo, A.SerialUniq
		FROM Invt_res A  
		WHERE A.FK_PRJUNIQUE=@PRJUNIQUE 
		 and qtyAlloc>0 and NOT EXISTS (SELECT 1 from Invt_res U where U.REFINVTRES=A.INVTRES_NO) 
	 END TRY
	 BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	 END CATCH
	 -- unallocate anything that was allocated from wo-wip location to a different work order/project
	BEGIN TRY
		INSERT INTO Invt_res (Invtres_no, W_key,Uniq_key,[Datetime],Qtyalloc,Lotcode,Expdate,Reference,Ponum,Saveinit,RefInvtres,WONO,Fk_PrjUnique, SerialNo, SerialUniq)
			SELECT  dbo.fn_GenerateUniqueNumber(), A.W_key,A.Uniq_key,@transDate,-A.Qtyalloc,
					A.Lotcode,A.Expdate,A.Reference,A.Ponum,@Userid,A.Invtres_no,A.Wono,A.Fk_PrjUnique, A.SerialNo, A.SerialUniq
		FROM Invt_res A  INNER JOIN Invtmfgr M ON A.w_key=m.W_key
		WHERE A.FK_PRJUNIQUE<>@PRJUNIQUE and A.Wono<>@wono AND M.Location= 'WO' + @Wono
		 and qtyAlloc>0 and NOT EXISTS (SELECT 1 from Invt_res U where U.REFINVTRES=A.INVTRES_NO) 
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	 END CATCH 
	-- generate issue records to issue over issue qty to the wor order for serialized parts and none serialized
	BEGIN TRY
		INSERT INTO Invt_Isu (W_key,Uniq_key,IssuedTo,QtyIsu,U_of_meas,Wono,Gl_nbr,LotCode,Expdate,Reference,
					Saveinit,Ponum, Serialno, SerialUniq, UniqMfgrHD, Date, Invtisu_no, StdCost, cModid,is_rel_gl)
		SELECT L.Overw_key,K.Uniq_key,'(WO:'+K.Wono, 1,I.U_of_meas,K.Wono,@WipGlNbr, L.LotCode,L.Expdate,L.Reference,@userid, L.Ponum, 
								S.Serialno, s.SerialUniq, L.UniqMfgrHd, @transDate, dbo.fn_GenerateUniqueNumber(), I.StdCost, 'C',
								case when @impactGL=1 then 0 else 1 END as is_rel_gl
		FROM Kalocate L INNER JOIN Kamain K on l.kaseqnum=K.KASEQNUM
		INNER JOIN Inventor I on K.UNIQ_KEY=I.UNIQ_KEY
		INNER JOIN KalocSer S ON L.UNIQKALOCATE=S.UNIQKALOCATE
		WHERE l.wono=@wono
			and l.OVERW_KEY<>' '
			and l.OVERISSQTY<>0
			and s.IS_OVERISSUED=1
		UNION
		SELECT L.Overw_key,K.Uniq_key,'(WO:'+K.Wono, l.OVERISSQTY,I.U_of_meas,K.Wono,@WipGlNbr, L.LotCode,L.Expdate,L.Reference,'Autokit', L.Ponum, 
								ISNULL(S.Serialno,space(30)),ISNULL(s.SerialUniq,space(10)), L.UniqMfgrHd, @transDate, dbo.fn_GenerateUniqueNumber(), I.StdCost, 'C',
								case when @impactGL=1 then 0 else 1 END as is_rel_gl
		FROM Kalocate L INNER JOIN Kamain K on l.kaseqnum=K.KASEQNUM
		INNER JOIN Inventor I on K.UNIQ_KEY=I.UNIQ_KEY
		LEFT OUTER JOIN KalocSer S ON L.UNIQKALOCATE=S.UNIQKALOCATE
		WHERE l.wono=@wono
			and l.OVERW_KEY<>' '
			and l.OVERISSQTY<>0
			and s.Serialno is null
		
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	 END CATCH
	-- calculate manufacturer variance
	BEGIN TRY

		-- 08/28/15 VL increased qty numeric(9,2) to (12,2), Ext_cost numeric(12,5) to (25,5),Ext_cost_total numeric(13,5) to (25,5)
		--QtyReqWithoutCEILING numeric(9,2) to (16,2), Ext_cost_totalWithoutCEILING numeric(13,5) to (25,5)
		DECLARE @ZResult TABLE (Uniq_key char(10), Part_Sourc char(8), StdCost numeric(13,5),
			Qty numeric(12,2), U_of_meas char(4), Scrap numeric(6,2), SetupScrap numeric(4,0), Phant_Make bit,
			UniqBomNo char(10), Ext_cost numeric(25,5), SetupScrap_Cost numeric(12,5), Ext_cost_total numeric(25,5),
			QtyReqTotal numeric(16,2), StdBldQty numeric(8,0), Ext_costWithoutCEILING numeric(12,5),
			QtyReqWithoutCEILING numeric(16,2), Ext_cost_totalWithoutCEILING numeric(25,5), QtyReqTotalWithoutCEILING numeric(16,2));

		INSERT INTO @ZResult EXEC Sp_RollupCost @Uniq_key, @Due_Date,@StdBldQty, @BldQty

		SELECT @TotalStd=SUM(Ext_cost_total), @SetupScrapCost=SUM(SetupScrap_cost),
			@RollupCost=SUM(Ext_cost_total)+SUM(SetupScrap_cost)*@Bldqty,
			@TotalStdWithoutCEILING = SUM(Ext_cost_totalWithoutCEILING),
			@TotalXCost=SUM(Ext_cost_totalWithoutCEILING)+SUM(SetupScrap_cost)*@Bldqty,
			@TotalXCostDiff =SUM(Ext_cost_total)-SUM(Ext_cost_totalWithoutCEILING)
			FROM @ZResult


		-- find cost of all the issued items

		DECLARE @NewResult TABLE (Uniq_key char(10), Qtyisu numeric(12,2), OldUnitCost numeric(13,5),OldCost numeric(15,5) ,
		NewUnitCost numeric(13,5),Part_Sourc char(10),NewCost numeric(15,5) )
	

		insert into @NewResult EXEC sp_IssuUpCost @wono
		SELECT @IssuUpCost=SUM(ISNULL(NewCost,0.00)) from @NewResult
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	END CATCH
	BEGIN TRY
		IF (@IssuUpCost <> @RollupCost)
		BEGIN	
			INSERT INTO Mfgrvar (UniqMfgVar, Wono, Uniq_key, Issuecost, Bomcost, Totalvar, Initials, 
							Man_gl_nbr, Wip_gl_nbr, [Datetime], VarType,is_rel_gl) 
			VALUES (dbo.fn_GenerateUniqueNumber(), @Wono, @Uniq_key, @IssuUpCost, @RollupCost, @IssuUpCost-@RollupCost, @Userid, 
			@mfgrGlNbr, @WipGlNbr,@transDate, 'MFGRV',case when @impactGL=1 then 0 else 1 END)
		END	---- IF (@IssuUpCost <> @RollupCost)
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	END CATCH
	BEGIN TRY
		---  save rounding variance 
		IF (@TotalXCostDiff <> 0)
		BEGIN	
			INSERT INTO Mfgrvar (UniqMfgVar, Wono, Uniq_key, Issuecost, Bomcost, Totalvar, Initials, 
							Man_gl_nbr, Wip_gl_nbr, [Datetime], Vartype,is_rel_gl) 
			VALUES (dbo.fn_GenerateUniqueNumber(),@Wono, @Uniq_key, @TotalStd, @TotalStdWithoutCEILING, ROUND(@TotalXCostDiff,5), @Userid, 
				@roundGlNbr,@WipGlNbr,@transDate, 'RVAR',case when @impactGL=1 then 0 else 1 END)
		END --- (@TotalXCostDiff <> 0)
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	END CATCH
	BEGIN TRY
		-- update kit status
		UPDATE WoEntry SET KitStatus = 'KIT CLOSED',
				KitCloseDt =  @transDate,
				kitcloseinit =@Userid,
                KitLstChDT =@transDate,
                KitLstChInit = @Userid WHERE Wono=@wono
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT>0
			ROLLBACK TRANSACTION
		SET @Updated=0
		RETURN 
	END CATCH	
	IF @@TRANCOUNT>0
	BEGIN	
		COMMIT
		EXEC spMntUpdLogScript 'sp_UtilsAutoCloseKIT','Utils'
	END					
	*/
END