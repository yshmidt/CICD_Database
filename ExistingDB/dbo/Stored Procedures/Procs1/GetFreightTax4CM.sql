-- =============================================
-- Modification
-- 03/05/15 VL added 5 tax logical fields, also added them into return SQL result
-- 03/11/15 VL added 9th and 10th parameters for FC
-- 10/31/16 VL added PR fields
-- 03/07/17 VL Remove ROUND() when calculting foreign type 'E' tax when sttx = 1, don't round() for each two record, round at the end
-- =============================================

CREATE Procedure [dbo].[GetFreightTax4CM]
			@lcInvPacklistNo as char(10) = ' ', 
			--@pcPlUniqlnk as char(10) = ' ',  -- this parameter is not in use
			@pccustno AS char(10),
			--@pIsForeignTax as bit = 0, -- 02/21/12 YS figure out if need foreign tax here
			@pcmType as Char(1) = 'I', 
			@pIsStandAloneRMA as bit = 0,
			@pcLinkAdd as char(10) = ' ', 
			@llFTaxOnly as bit = 0, 
			@pnInvfreightamt as numeric(12,2) = 0.00,
			@pnfreightAmt as numeric(12,2) = 0.00, 
			@pnInvfreightamtFC as numeric(12,2) = 0.00,
			@pnfreightAmtFC as numeric(12,2) = 0.00,
			@pnInvfreightamtPR as numeric(12,2) = 0.00,
			@pnfreightAmtPR as numeric(12,2) = 0.00 
			--@gcInv_link as char(10) = ' ', -- this parameter is not in use
			--@pcPackListNo as char(10) = ' '-- use @lcInvPacklistNo - a original pacl=king list number. Also save it b/c this is the one that we create a CM for, not RMA receiver if CM was created by RMA
 

AS
BEGIN

DECLARE @pIsForeignTax bit=0
SELECT @pIsForeignTax =ForeignTax  
		FROM ShipBill 
		WHERE LinkAdd = @pcLinkAdd

--02/07/12 YS added defaults to the table variable to avoid null values
-- 03/05/15 VL added 5 tax logical fields
-- 03/11/15 VL added FC fields
-- 10/31/16 VL added PR fields
DECLARE @pShipTax1 as Table (YesNo bit Default 1, InvoiceNo char(10) Default ' ', PacklistNO char(10) default ' ', 
	Tax_Id char(8) default ' ', TaxDesc char(25) default ' ', linkAdd Char(10) default ' ', Gl_Nbr_in char(13) default ' ', Gl_Nbr_out char(13) default ' ', 
	Tax_rate numeric(12,4) default 0.00,Tax_amt numeric(12,4) default 0.00, Tax_amtFC numeric(12,4) default 0.00, tax_Type char(1) default ' ', TxTypeForn char(1) default ' ',
	Ptprod bit, PtFrt bit, StProd bit, StFrt bit, Sttx bit, Tax_amtPR numeric(12,4) default 0.00)



IF (@pIsForeignTax = 0)
		-- 04/25/07 VL found if the credit memo is from invoice, the credit memo sales tax has to be the same as invoice ;
		--				sales tax, so no need to find current tax rate, just use invoice tax amount, if cmtype= "M", then calculate tax from current setup
		-- 09/18/07 VL added one more criteria because now change Cmtype back to "I" even the RMA is stand alone RMA
BEGIN	
	IF (@pcmType='I' and @pIsStandAloneRMA=0)  --&& so it's not stand alone RMA, it's associated with invoice
		-- 05/10/07 VL found the NOT IN should be "Zshptax1" cursor, not ZstdTax1 cursor, also minor change in SQL to prevent error
		-- 05/08/07 VL use lcInvPacklistno intead of THISFORM.pcPacklistno because if the CM is created from RMA receiver, the packlistno is the RMA receiverno, not original PK no		
		-- 05/11/07 VL found for some reason using NOT IN... in one SQL didn't work right, so separate to two SQLs
		-- 05/14/07	VL fund out still need to calculate tax amount, can not get tax amt directly from invstdtx, but can get the old rate to calculate
		-- 07/16/07 VL added EMPTY(Invoiceno) to filter out previous created CM for same invoice
	BEGIN
		-- 03/11/15 VL added FC fields
		-- 10/31/16 VL added PR fields
		INSERT INTO @pShipTax1 (yesNo,PackListNo,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate,Tax_amt, Tax_amtFC, Tax_type, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR ) 
		SELECT CAST(1 as bit) AS YesNo,PackListNo, 
			@pcLinkAdd AS LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate, 
			CASE WHEN @llFTaxOnly=1 THEN 
				ROUND(@pnInvfreightamt*Tax_rate/100,2)  
				ELSE ROUND(@pnfreightAmt*Tax_rate/100,2) END as Tax_amt, 
			CASE WHEN @llFTaxOnly=1 THEN 
				ROUND(@pnInvfreightamtFC*Tax_rate/100,2)  
				ELSE ROUND(@pnfreightAmtFC*Tax_rate/100,2) END as Tax_amtFC, 
			Tax_type, PtProd, PtFrt, StProd, StFrt, Sttx,
			CASE WHEN @llFTaxOnly=1 THEN 
				ROUND(@pnInvfreightamtPR*Tax_rate/100,2)  
				ELSE ROUND(@pnfreightAmtPR*Tax_rate/100,2) END as Tax_amtPR
			FROM Invstdtx 
			WHERE Packlistno = @lcInvPacklistno 
			AND Invoiceno = ' '
			AND Tax_Type = 'C' 
			SELECT * from @pShipTax1
		END					
	ELSE  -- (@pcmType='I' and @pIsStandAloneRMA=0)	
		-- 03/13/07 VL found the NOT IN should be "Zshptax1" cursor, not ZstdTax1 cursor
		-- 04/03/07 VL added ROUND(), it caused 1 cent difference
		-- 05/11/07 VL found for some reason using NOT IN... in one SQL didn't work right, so separate to two SQLs
		-- 02/07/12 YS added begin / end inside this ELSE. Otherwise SELECT * from @pShipTax1 will be called even though the ELSE branch did not run.
		BEGIN
		-- 03/11/15 VL added FC fields
		-- 10/31/16 VL added PR fields
		INSERT INTO @pShipTax1 (yesNo,PackListNo,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate,Tax_amt,Tax_amtFC, Tax_type, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR ) 
		SELECT CAST(1 as bit) AS  yesno,@lcInvPacklistno AS PackListNo,@pcLinkAdd AS LinkAdd,
				ShipTax.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
				TaxTabl.Gl_nbr_out,ShipTax.Tax_rate,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamt*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmt*ShipTax.Tax_rate/100,2) END as Tax_amt,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtFC*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtFC*ShipTax.Tax_rate/100,2) END as Tax_amtFC, 
				ShipTax.Taxtype AS Tax_Type, ShipTax.PtProd, ShipTax.PtFrt, 
				ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtPR*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtPR*ShipTax.Tax_rate/100,2) END as Tax_amtPR
				FROM ShipTax,TaxTabl
				WHERE ShipTax.LinkAdd = @pcLinkAdd 
				AND ShipTax.Custno = @pccustno 
				AND ShipTax.TaxType = 'C'
				AND ShipTax.Tax_id=TaxTabl.Tax_id
			SELECT * from @pShipTax1
		END
	END -- (@pcmType='I' and @pIsStandAloneRMA=0)

ELSE -- (@pIsForeignTax = 0)
		-- 04/25/07 VL found if the credit memo is from invoice, the credit memo sales tax has to be the same as invoice ;
		--				sales tax, so no need to find current tax rate, just use invoice tax amount, if cmtype= "M", then calculate tax from current setup
		-- 09/18/07 VL added one more criteria because now change Cmtype back to "I" even the RMA is stand alone RMA
BEGIN
	
	DECLARE @pShipTaxTblE as Table (PtProd bit,StProd bit ,StTx bit,PtFrt bit,StFrt bit,Tax_Rate numeric(8,4),TaxType char(1),Tax_id char(8))
	

	-- 03/05/15 VL changed, if @pCmType = 'I' AND @pIsStandAloneRMA=0, will insert @pShipTaxTblE from Invstdtx which has original tax setting, otherwise, still from fn_ShipTaxForeignView
	BEGIN
	IF @pcmType = 'I' AND @pIsStandAloneRMA=0 
		BEGIN
			INSERT INTO @pShipTaxTblE SELECT TOP 1 PtProd,StProd,StTx,PtFrt,StFrt,Tax_Rate, TxTypeForn AS Taxtype,Tax_id
				FROM Invstdtx 
				WHERE Packlistno = @lcInvPacklistno   
				AND Invoiceno=' '
				AND Tax_Type = 'C' 
				AND TxTypeForn = 'E'
				ORDER BY Packlistno
		END
	ELSE
		BEGIN
			--03/08/12 YS use table-valued function (inline function)
			--INSERT INTO  @pShipTaxTblE EXEC ShipTaxForeignView @pcCustno,'E',@pcLinkAdd
			INSERT INTO @pShipTaxTblE SELECT * FROM fn_ShipTaxForeignView(@pcCustno,'E',@pcLinkAdd)
		END
	END		
	-- 03/05/15 VL End}

	DECLARE @pShipTaxTblP as Table (PtProd bit,StProd bit ,StTx bit,PtFrt bit,StFrt bit,Tax_Rate numeric(8,4),TaxType char(1),TAX_id char(8))
	--03/08/12 YS use table-valued function (inline function)
	
	--INSERT INTO  @pShipTaxTblP EXEC ShipTaxForeignView @pcCustno,'P',@pcLinkAdd
	INSERT INTO @pShipTaxTblP SELECT * FROM fn_ShipTaxForeignView(@pcCustno,'P',@pcLinkAdd)
	
	
	IF @pcmType = 'I' AND @pIsStandAloneRMA=0 	-- so it's not stand alone RMA, it's associated with invoice
	BEGIN
		IF ((SELECT StTx FROM @pShipTaxTblE)=0)  -- no secondary tax applied to the primary tax
		BEGIN	
			-- 03/05/15 VL chaned to only use invstdtx because now dall 5 tax setting are saved in invstdtx
			--INSERT INTO @pShipTax1 (yesNo,PackListNo,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			--Gl_nbr_out,Tax_rate,Tax_amt,Tax_type, TxTypeForn ) 
			--SELECT CAST(1 as bit) AS YesNo,PackListNo, 
			--	@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,
			--	Gl_nbr_out,Invstdtx.Tax_rate, 
			--	CASE WHEN @llFTaxOnly=1 THEN 
			--		ROUND(@pnInvfreightamt*InvstdTx.Tax_rate/100,2)  
			--		ELSE ROUND(@pnfreightAmt*InvstdTx.Tax_rate/100,2) END as Tax_amt,Tax_type, TxTypeForn
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblP P
			--		CROSS JOIN @pShipTaxTblE E
			--	WHERE Packlistno = @lcInvPacklistno 
			--	AND Invoiceno = ' '
			--	AND Tax_Type = 'C'
			--	AND ((TxTypeForn = 'P' AND TxTypeForn =P.TaxType AND P.PtProd=1) 
			--		OR (TxTypeForn = 'E' AND TxTypeForn =E.TaxType AND  E.StProd=1)) 
			-- 03/11/15 VL added FC fields
			-- 10/31/16 VL added PR fields
			INSERT INTO @pShipTax1 (yesNo,PackListNo,LinkAdd,Tax_id,TaxDesc,Gl_nbr_in,
			Gl_nbr_out,Tax_rate,Tax_amt, Tax_amtFC, Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR) 
			SELECT CAST(1 as bit) AS YesNo,PackListNo, 
				@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,
				Gl_nbr_out,Invstdtx.Tax_rate, 
				CASE WHEN @llFTaxOnly=1 THEN 
					ROUND(@pnInvfreightamt*InvstdTx.Tax_rate/100,2)  
					ELSE ROUND(@pnfreightAmt*InvstdTx.Tax_rate/100,2) END as Tax_amt,
				CASE WHEN @llFTaxOnly=1 THEN 
					ROUND(@pnInvfreightamtFC*InvstdTx.Tax_rate/100,2)  
					ELSE ROUND(@pnfreightAmtFC*InvstdTx.Tax_rate/100,2) END as Tax_amtFC, 
				Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx,
				CASE WHEN @llFTaxOnly=1 THEN 
					ROUND(@pnInvfreightamtPR*InvstdTx.Tax_rate/100,2)  
					ELSE ROUND(@pnfreightAmtPR*InvstdTx.Tax_rate/100,2) END as Tax_amtPR
				FROM Invstdtx
				WHERE Packlistno = @lcInvPacklistno 
				AND Invoiceno = ' '
				AND Tax_Type = 'C'
				AND ((TxTypeForn = 'P' AND PtProd=1) 
					OR (TxTypeForn = 'E' AND StProd=1)) 
			SELECT * from @pShipTax1
		END	-- ((SELECT StTx FROM @pShipTaxTblE)=0)
		
		ELSE -- ((SELECT StTx FROM @pShipTaxTblE)=0)
			-- Has Secondary tax set up and StTx = .T., has to get primary tax first, then use it to calcualte with 2nd tax
			-- Get Primary tax first
			-- 07/16/07 VL added EMPTY(Invoiceno) to filter out previous created CM for same invoice
		BEGIN
			-- YS BEGIN  Bill here the code I've created
			;WITH Zfrtaxinfo AS
			(
			-- 03/05/15 VL chaned to only use invstdtx because now dall 5 tax setting are saved in invstdtx
			--SELECT CAST(1 as bit) AS YesNo,Invstdtx.PackListNo,
			--	@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,
			--	Gl_nbr_out,Invstdtx.Tax_rate,
			--	CASE WHEN @llFTaxOnly=1 THEN
			--		ROUND(@pnInvfreightamt*Invstdtx.Tax_rate/100,2)
			--		ELSE ROUND(@pnfreightAmt*Invstdtx.Tax_rate/100,2) END as Tax_amt,
			--	Tax_Type, TxTypeForn
			--	FROM Invstdtx CROSS JOIN @pShipTaxTblP P 
			--	WHERE Packlistno = @lcInvPacklistno 
			--	AND Invoiceno = ' '
			--	AND Tax_Type = 'C' 
			--	AND TxTypeForn = 'P' 				
			--	AND P.PtFrt = 1
			-- 03/11/15 VL added FC fields
			-- 10/31/16 VL added PR fields
			SELECT CAST(1 as bit) AS YesNo,Invstdtx.PackListNo,
				@pcLinkAdd AS LinkAdd,Invstdtx.Tax_id,TaxDesc,Gl_nbr_in,
				Gl_nbr_out,Invstdtx.Tax_rate,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamt*Invstdtx.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmt*Invstdtx.Tax_rate/100,2) END as Tax_amt,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtFC*Invstdtx.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtFC*Invstdtx.Tax_rate/100,2) END as Tax_amtFC,
				Tax_Type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx,
				CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtPR*Invstdtx.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtPR*Invstdtx.Tax_rate/100,2) END as Tax_amtPR
				FROM Invstdtx
				WHERE Packlistno = @lcInvPacklistno 
				AND Invoiceno = ' '
				AND Tax_Type = 'C' 
				AND TxTypeForn = 'P' 				
				AND PtFrt = 1
			)	,
			zTaxDetail AS
			(	
				-- 03/05/15 VL chaned to only use invstdtx because now dall 5 tax setting are saved in invstdtx
				--SELECT 	CASE WHEN @llFTaxOnly=1 THEN
				--	ROUND(@pnInvfreightamt*Invstdtx.Tax_rate/100,2)
				--	ELSE ROUND(@pnfreightAmt*Invstdtx.Tax_rate/100,2) END as Tax_amt,
				--	Invstdtx.Tax_Id
				--	FROM Invstdtx CROSS JOIN @pShipTaxTblE E
				--	WHERE Packlistno = @lcInvPacklistno 
				--	AND Invoiceno = ' ' 
				--	AND Tax_Type = 'C'
				--	AND TxTypeForn = 'E' 				
				--	AND E.StFrt = 1
				--UNION ALL 
				--SELECT CASE WHEN @llFTaxOnly=1 THEN 
				--		ROUND(@pnInvfreightamt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2)
				--		ELSE ROUND(@pnfreightAmt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2) END AS Tax_Amt, 
				--		Invstdtx.Tax_id 
				--		FROM Invstdtx CROSS JOIN Zfrtaxinfo F	
				--			CROSS JOIN @pShipTaxTblE E
				--		WHERE Invstdtx.Packlistno = @lcInvPacklistno 
				--		AND Invoiceno=' '
				--		AND Invstdtx.Tax_Type = 'C'
				--		AND Invstdtx.TxTypeForn = 'E'				
				--		AND E.StTx =1
				-- 03/11/15 VL added FC fields
				-- 10/31/16 VL added PR fields
				-- 03/07/17 VL not ROUND() in calculatint two type 'E' type (sttx = 1 situation) for each record, will add ROUND() when sum of the type 'E' so don't round() separately for two 'E' records
				SELECT 	
					--CASE WHEN @llFTaxOnly=1 THEN
					--ROUND(@pnInvfreightamt*Invstdtx.Tax_rate/100,2)
					--ELSE ROUND(@pnfreightAmt*Invstdtx.Tax_rate/100,2) END as Tax_amt,
					--CASE WHEN @llFTaxOnly=1 THEN
					--ROUND(@pnInvfreightamtFC*Invstdtx.Tax_rate/100,2)
					--ELSE ROUND(@pnfreightAmtFC*Invstdtx.Tax_rate/100,2) END as Tax_amtFC,
					CASE WHEN @llFTaxOnly=1 THEN
					@pnInvfreightamt*Invstdtx.Tax_rate/100
					ELSE @pnfreightAmt*Invstdtx.Tax_rate/100 END as Tax_amt,
					CASE WHEN @llFTaxOnly=1 THEN
					@pnInvfreightamtFC*Invstdtx.Tax_rate/100
					ELSE @pnfreightAmtFC*Invstdtx.Tax_rate/100 END as Tax_amtFC,
					Invstdtx.Tax_Id, PtProd, PtFrt, StProd, StFrt, Sttx,
					--CASE WHEN @llFTaxOnly=1 THEN
					--ROUND(@pnInvfreightamtPR*Invstdtx.Tax_rate/100,2)
					--ELSE ROUND(@pnfreightAmtPR*Invstdtx.Tax_rate/100,2) END as Tax_amtPR
					CASE WHEN @llFTaxOnly=1 THEN
					@pnInvfreightamtPR*Invstdtx.Tax_rate/100
					ELSE @pnfreightAmtPR*Invstdtx.Tax_rate/100 END as Tax_amtPR
					FROM Invstdtx
					WHERE Packlistno = @lcInvPacklistno 
					AND Invoiceno = ' ' 
					AND Tax_Type = 'C'
					AND TxTypeForn = 'E' 				
					AND StFrt = 1
				UNION ALL 
				-- 10/31/16 VL added PR fields
				-- 03/07/17 VL not ROUND() in calculatint two type 'E' type (sttx = 1 situation) for each record, will add ROUND() when sum of the type 'E' so don't round() separately for two 'E' records
				SELECT 
						--CASE WHEN @llFTaxOnly=1 THEN 
						--ROUND(@pnInvfreightamt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2)
						--ELSE ROUND(@pnfreightAmt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2) END AS Tax_Amt, 
						--CASE WHEN @llFTaxOnly=1 THEN 
						--ROUND(@pnInvfreightamtFC*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2)
						--ELSE ROUND(@pnfreightAmtFC*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2) END AS Tax_AmtFC,
						CASE WHEN @llFTaxOnly=1 THEN 
						@pnInvfreightamt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100)
						ELSE @pnfreightAmt*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100) END AS Tax_Amt, 
						CASE WHEN @llFTaxOnly=1 THEN 
						@pnInvfreightamtFC*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100)
						ELSE @pnfreightAmtFC*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100) END AS Tax_AmtFC,
						Invstdtx.Tax_id, Invstdtx.PtProd, Invstdtx.PtFrt, Invstdtx.StProd, Invstdtx.StFrt, Invstdtx.Sttx,
						--CASE WHEN @llFTaxOnly=1 THEN 
						--ROUND(@pnInvfreightamtPR*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2)
						--ELSE ROUND(@pnfreightAmtPR*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100),2) END AS Tax_AmtPR
						CASE WHEN @llFTaxOnly=1 THEN 
						@pnInvfreightamtPR*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100)
						ELSE @pnfreightAmtPR*(F.Tax_rate/100)*(Invstdtx.Tax_Rate/100) END AS Tax_AmtPR
						FROM Invstdtx CROSS JOIN Zfrtaxinfo F	
						WHERE Invstdtx.Packlistno = @lcInvPacklistno 
						AND Invoiceno=' '
						AND Invstdtx.Tax_Type = 'C'
						AND Invstdtx.TxTypeForn = 'E'				
						AND Invstdtx.StTx =1
					)	,
					ZTaxSum as
					(
					-- 10/31/16 VL added PR fields
					-- 03/07/17 VL added ROUND() here to round for the sum of two type 'E' records
					--SELECT ISNULL(SUM(Tax_amt),0.00) AS Tax_amt, ISNULL(SUM(Tax_amtfC),0.00) AS Tax_amtFC, ISNULL(SUM(Tax_amtPR),0.00) AS Tax_amtPR
					SELECT ROUND(ISNULL(SUM(Tax_amt),0.00),2) AS Tax_amt, ROUND(ISNULL(SUM(Tax_amtfC),0.00),2) AS Tax_amtFC, ROUND(ISNULL(SUM(Tax_amtPR),0.00),2) AS Tax_amtPR
						FROM zTaxDetail
					),
					ZFtaxDist AS
					(
					SELECT DISTINCT	CAST(1 as bit) AS yesno,PackListNo, 
						@pcLinkAdd AS LinkAdd,Tax_id,
						TaxDesc,Gl_nbr_in,Gl_nbr_out,Tax_rate,'C' AS Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx
					FROM Invstdtx
					WHERE Packlistno = @lcInvPacklistNo 
					AND Invoiceno =' '
					AND Tax_Type = 'C'
					AND TxTypeForn = 'E'	
					)
					-- 03/09/12 VL changed the field sequences which are used in sp_cmemo_total INSERT
					-- 03/11/15 VL added FC fields
					-- 10/31/16 VL added PR fields
					SELECT yesno, SPACE(10) AS Invoiceno, PackListNo, Tax_id, TaxDesc, LinkAdd,
						Gl_nbr_in ,Gl_nbr_out, Tax_rate, S.Tax_amt, S.Tax_amtFC, 'C' AS Tax_type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, S.Tax_amtPR
						FROM ZFtaxDist D CROSS JOIN  ZTaxSum S
					UNION ALL
					SELECT YesNo, SPACE(10) AS Invoiceno, PackListNo, Tax_id, TaxDesc, LinkAdd,
						Gl_nbr_in, Gl_nbr_out, Tax_rate, Tax_amt, Tax_amtFC, Tax_Type, TxTypeForn, PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR
					FROM Zfrtaxinfo
			--- YS END  Bill here the code I've created		
		END -- -- ((SELECT StTx FROM @pShipTaxTblE)=0)
		
	END -- @pcmType = 'I' AND @pIsStandAloneRMA=0
	ELSE -- @pcmType = 'I' AND @pIsStandAloneRMA=0
	IF ((SELECT StTx FROM @pShipTaxTblE)=0)  -- no secondary tax applied to the primary tax
	BEGIN
		-- 04/03/07 VL added ROUND(), it caused 1 cent difference
		-- 05/11/07 VL found for some reason using NOT IN... in one SQL didn't work right, so separate to two SQLs	
		-- 03/09/12 VL changed the field sequences which are used in sp_cmemo_total INSERT		
		-- 03/11/15 VL added FC fields
		-- 10/31/16 VL added PR fields
		SELECT CAST(1 as bit) AS yesno, SPACE(10) AS Invoiceno, @lcInvPacklistNo as PackListNo,
			ShipTax.Tax_id,TaxTabl.TaxDesc, @pcLinkAdd AS LinkAdd, TaxTabl.Gl_nbr_in, TaxTabl.Gl_nbr_out,
			ShipTax.Tax_rate,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamt*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmt*ShipTax.Tax_rate/100,2) END as Tax_amt,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtFC*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtFC*ShipTax.Tax_rate/100,2) END as Tax_amtFC,
			'C' AS Tax_type, ShipTax.Taxtype AS TxTypeForn, ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtPR*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtPR*ShipTax.Tax_rate/100,2) END as Tax_amtPR
			FROM ShipTax,TaxTabl
			WHERE ShipTax.LinkAdd = @pcLinkAdd 
			AND ShipTax.Custno = @pccustno 
			AND ((ShipTax.TaxType = 'P' AND ShipTax.PtFrt = 1) 
			OR (ShipTax.TaxType = 'E' AND ShipTax.StFrt = 1)) 
			AND ShipTax.Tax_id=TaxTabl.Tax_id
						
			
	END 
	ELSE 
		--secondary tax set up and StTx = .T., has to get primary tax first, then use it to calcualte with 2nd tax
		-- 03/13/07 VL added TxTypeForn for tax type of foreign tax
		-- Get primary tax first
		-- 04/03/07 VL added ROUND(), it caused 1 cent difference
		-- 05/11/07 VL found for some reason using NOT IN... in one SQL didn't work right, so separate to two SQLs		
	BEGIN
	; WITH zFrtaxinfo AS
		(
		-- 03/11/15 VL added FC fields
		-- 10/31/16 VL added PR fields
		SELECT CAST(1 as bit) AS yesno,@lcInvPacklistNo AS PackListNo,@pcLinkAdd AS LinkAdd,
			ShipTax.Tax_id,TaxTabl.TaxDesc,TaxTabl.Gl_nbr_in,
			TaxTabl.Gl_nbr_out,ShipTax.Tax_rate,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamt*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmt*ShipTax.Tax_rate/100,2) END as Tax_amt,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtFC*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtFC*ShipTax.Tax_rate/100,2) END as Tax_amtFC,
			'C' AS Tax_type, ShipTax.Taxtype AS TxTypeForn, ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx,
			CASE WHEN @llFTaxOnly=1 THEN
					ROUND(@pnInvfreightamtPR*ShipTax.Tax_rate/100,2)
					ELSE ROUND(@pnfreightAmtPR*ShipTax.Tax_rate/100,2) END as Tax_amtPR
			FROM ShipTax,TaxTabl
			WHERE ShipTax.LinkAdd =@pcLinkAdd 
			AND ShipTax.Custno = @pccustno 
			AND ShipTax.TaxType = 'P' AND ShipTax.PtFrt = 1
			AND ShipTax.Tax_id=TaxTabl.Tax_id
		) ,
		-- 04/02/07 VL changed to use PtFrt to see if need to calculate, it should based on PtFrt, not StFrt
		-- 04/02/07 VL only calculated secondary frt tax if PtFrt is .T.
		-- 03/12/07 VL change the Stax calculation again
		-- Prod $100. Freight 10, GST 6%, PST 7.5%, GST:(100+10)*0.06=6.6, PST:(100+10)*1.06*0.075=8.745
		-- Prod tax:=100*0.06+100*1.06*0.075 or 100(0.06*0.075+0.06+0.075)=13.95, Freight tax:10*0.06+10*1.06*0.075 or 10*(0.06*0.075+0.06+0.075)=1.395
		-- Prod tax PTax: 100*.006 = 6, STax: 100*(0.06*0.075+0.075) = 7.95
		-- Freight Tax Ptax:10*0.06 = 0.6, STax:10*(0.06*0.075+0.075) = 0.795
		-- 04/03/07 VL added ROUND(), it caused 1 cent difference
		-- 05/11/07 VL found for some reason using NOT IN... in one SQL didn't work right, so separate to two SQLs		
		-- 07/24/07 VL changed from ZPtax.PtFrt to StFrt and changed to 2 SQL
		-- 03/11/15 VL added FC fields
		-- 10/31/16 VL added PR fields
		zTaxDetail AS
			(	
		SELECT 	
			-- 03/07/17 VL not ROUND() in calculatint two type 'E' type (sttx = 1 situation) for each record, will add ROUND() when sum of the type 'E' so don't round() separately for two 'E' records
			--CASE WHEN @llFTaxOnly=1 THEN
			--ROUND(@pnInvfreightamt*ShipTax.Tax_rate/100,2)
			--ELSE ROUND(@pnfreightAmt*ShipTax.Tax_rate/100,2) END as Tax_amt,
			--CASE WHEN @llFTaxOnly=1 THEN
			--ROUND(@pnInvfreightamtFC*ShipTax.Tax_rate/100,2)
			--ELSE ROUND(@pnfreightAmtFC*ShipTax.Tax_rate/100,2) END as Tax_amtFC,
			CASE WHEN @llFTaxOnly=1 THEN
			@pnInvfreightamt*ShipTax.Tax_rate/100
			ELSE @pnfreightAmt*ShipTax.Tax_rate/100 END as Tax_amt,
			CASE WHEN @llFTaxOnly=1 THEN
			@pnInvfreightamtFC*ShipTax.Tax_rate/100
			ELSE @pnfreightAmtFC*ShipTax.Tax_rate/100 END as Tax_amtFC,
			ShipTax.Tax_Id, ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx, 
			--CASE WHEN @llFTaxOnly=1 THEN
			--ROUND(@pnInvfreightamtPR*ShipTax.Tax_rate/100,2)
			--ELSE ROUND(@pnfreightAmtPR*ShipTax.Tax_rate/100,2) END as Tax_amtPR
			CASE WHEN @llFTaxOnly=1 THEN
			@pnInvfreightamtPR*ShipTax.Tax_rate/100
			ELSE @pnfreightAmtPR*ShipTax.Tax_rate/100 END as Tax_amtPR
			FROM ShipTax INNER JOIN TaxTabl ON ShipTax.Tax_id=TaxTabl.Tax_id
			WHERE ShipTax.Custno = @pccustno 
			AND ShipTax.TaxType = 'E' 
			AND ShipTax.StFrt = 1
		UNION ALL 
			-- 10/31/16 VL added PR fields
			-- 03/07/17 VL not ROUND() in calculatint two type 'E' type (sttx = 1 situation) for each record, will add ROUND() when sum of the type 'E' so don't round() separately for two 'E' records
			SELECT 
				--CASE WHEN @llFTaxOnly=1 THEN 
				--ROUND(@pnInvfreightamt*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2)
				--ELSE ROUND(@pnfreightAmt*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2) END AS Tax_Amt, 
				--CASE WHEN @llFTaxOnly=1 THEN 
				--ROUND(@pnInvfreightamtFC*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2)
				--ELSE ROUND(@pnfreightAmtFC*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2) END AS Tax_AmtFC,
				CASE WHEN @llFTaxOnly=1 THEN 
				@pnInvfreightamt*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100)
				ELSE @pnfreightAmt*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100) END AS Tax_Amt, 
				CASE WHEN @llFTaxOnly=1 THEN 
				@pnInvfreightamtFC*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100)
				ELSE @pnfreightAmtFC*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100) END AS Tax_AmtFC,
				 Shiptax.Tax_id, ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx,
				--CASE WHEN @llFTaxOnly=1 THEN 
				--ROUND(@pnInvfreightamtPR*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2)
				--ELSE ROUND(@pnfreightAmtPR*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100),2) END AS Tax_AmtPR
				CASE WHEN @llFTaxOnly=1 THEN 
				@pnInvfreightamtPR*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100)
				ELSE @pnfreightAmtPR*(F.Tax_rate/100)*(ShipTax.Tax_Rate/100) END AS Tax_AmtPR
				FROM ShipTax INNER JOIN TaxTabl ON ShipTax.Tax_id=TaxTabl.Tax_id
					CROSS JOIN zFrtaxinfo F
				WHERE ShipTax.LinkAdd = @pcLinkAdd 
				AND ShipTax.Custno = @pccustno 
				AND ShipTax.TaxType = 'E'
				AND ShipTax.Sttx = 1
		) ,
		ZTaxSum as
					(
					-- 10/31/16 VL added PR fields
					-- 03/07/17 VL added ROUND() here to round for the sum of two type 'E' records
					--SELECT ISNULL(SUM(Tax_amt),0.00) AS Tax_amt, ISNULL(SUM(Tax_amtFC),0.00) AS Tax_amtFC, ISNULL(SUM(Tax_amtPR),0.00) AS Tax_amtPR
					SELECT ROUND(ISNULL(SUM(Tax_amt),0.00),2) AS Tax_amt, ROUND(ISNULL(SUM(Tax_amtFC),0.00),2) AS Tax_amtFC, ROUND(ISNULL(SUM(Tax_amtPR),0.00),2) AS Tax_amtPR
						FROM zTaxDetail
					),				
		ZFtaxDist AS
					(
			SELECT DISTINCT	CAST(1 as bit) AS yesno,@lcInvPacklistNo AS PackListNo, 
					@pcLinkAdd AS LinkAdd,ShipTax.Tax_id,
					T.TaxDesc,T.Gl_nbr_in,T.Gl_nbr_out,ShipTax.Tax_rate,'C' AS Tax_type, ShipTax.Taxtype AS TxTypeForn,
					ShipTax.PtProd, ShipTax.PtFrt, ShipTax.StProd, ShipTax.StFrt, ShipTax.Sttx
				FROM ShipTax INNER join TaxTabl T ON ShipTax.Tax_id=T.Tax_id	
				WHERE ShipTax.LinkAdd = @pcLinkAdd 
					AND ShipTax.Custno = @pccustno 
					AND ShipTax.TaxType = 'E' 
					)
				-- 03/09/12 VL changed the field sequences which are used in sp_cmemo_total INSERT	
				-- 03/11/15 VL added FC fields		
				-- 10/31/16 VL added PR fields
				SELECT yesno,SPACE(10) AS Invoiceno, PackListNo, Tax_id, TaxDesc, LinkAdd, 
					Gl_nbr_in,Gl_nbr_out,Tax_rate, S.Tax_amt, S.Tax_amtFC, 'C' AS Tax_type, TxTypeForn,
					D.PtProd, D.PtFrt, D.StProd, D.StFrt, D.Sttx, S.Tax_amtPR
						FROM ZFtaxDist D CROSS JOIN  ZTaxSum S
					UNION ALL
					SELECT YesNo, SPACE(10) AS Invoiceno, PackListNo, Tax_id, TaxDesc, LinkAdd,
						Gl_nbr_in,Gl_nbr_out,Tax_rate, Tax_amt, Tax_amtFC, Tax_Type, TxTypeForn,
						PtProd, PtFrt, StProd, StFrt, Sttx, Tax_amtPR
					FROM Zfrtaxinfo				
		END
	END
	
	
END -- (@pIsForeignTax = 0)