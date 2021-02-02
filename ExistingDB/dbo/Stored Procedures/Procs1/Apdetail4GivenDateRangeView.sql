CREATE PROCEDURE [dbo].[Apdetail4GivenDateRangeView] 
	-- Add the parameters for the stored procedure here
	@ldBeginDate char(10), @ldEndDate char(10), @lcApSatus char(15)='' ,@cHoldStatus char(10)=''
AS
-- 09/29/16 VL added code for FC to show more fields
-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--12/19/12 YS added cHoldStatus parameter
    -- Insert statements for procedure here
	-- 09/29/16 VL Added to get FC fields or not based on FC is installed or not
	DECLARE @lFCInstalled bit, @HCSymbol char(3) = ''
	SELECT @lFCInstalled = dbo.fn_IsFCInstalled()
	-- 06/20/17 VL changed fn_GetHomeCurrency to use fn_GetFunctionalCurrency
	SELECT @HCSymbol = Symbol FROM Fcused WHERE Fcused.Fcused_uniq = dbo.fn_GetFunctionalCurrency()

	IF @lFCInstalled = 0
		BEGIN
		IF (@lcApSatus='') 
			SELECT Item_no, Item_desc, Qty_each, Price_each, Item_Total, Is_Tax, ISNULL(TaxTabl.Taxdesc, SPACE(25)) AS Taxdesc, ISNULL(ApdetailTax.Tax_rate,0) AS Tax_rate, Gl_nbr, Apdetail.UniqApHead,Due_Date,Apdetail.UniqApdetl 
				From Apmaster,Supinfo, Apdetail LEFT OUTER JOIN ApdetailTax ON Apdetail.UniqApdetl = ApdetailTax.UniqApdetl
				LEFT OUTER JOIN Taxtabl ON ApdetailTax.Tax_id = Taxtabl.Tax_id
				where supinfo.uniqsupno=apmaster.uniqsupno 
				AND Apmaster.UniqAphead = Apdetail.UniqAphead
				and lPrepay <> 1
				and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
				and CAST(Due_date as date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) 
		ELSE
			SELECT Item_no, Item_desc, Qty_each, Price_each, Item_Total, Is_Tax, ISNULL(TaxTabl.Taxdesc, SPACE(25)) AS Taxdesc, ISNULL(ApdetailTax.Tax_rate,0) AS Tax_rate, Gl_nbr, Apdetail.UniqApHead,Due_Date,Apdetail.UniqApdetl 
				From Apmaster,Supinfo, Apdetail LEFT OUTER JOIN ApdetailTax ON Apdetail.UniqApdetl = ApdetailTax.UniqApdetl
				LEFT OUTER JOIN Taxtabl ON ApdetailTax.Tax_id = Taxtabl.Tax_id
				where supinfo.uniqsupno=apmaster.uniqsupno 
				AND Apmaster.UniqAphead = Apdetail.UniqAphead
				and lPrepay <> 1
				and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
				and CAST(Due_date as Date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) and ApStatus=@lcApSatus
		END
	ELSE
		BEGIN
		IF (@lcApSatus='') 
			SELECT Item_no, Item_desc, Qty_each, Price_eachFC, Item_TotalFC, Price_each, Item_Total, Is_Tax, ISNULL(TaxTabl.Taxdesc, SPACE(25)) AS Taxdesc, ISNULL(ApdetailTax.Tax_rate,0) AS Tax_rate, Gl_nbr, Apdetail.UniqApHead,Due_Date,Apdetail.UniqApdetl 
				From Apmaster,Supinfo, Apdetail LEFT OUTER JOIN ApdetailTax ON Apdetail.UniqApdetl = ApdetailTax.UniqApdetl
				LEFT OUTER JOIN Taxtabl ON ApdetailTax.Tax_id = Taxtabl.Tax_id
				where supinfo.uniqsupno=apmaster.uniqsupno 
				AND Apmaster.UniqAphead = Apdetail.UniqAphead
				and lPrepay <> 1
				and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
				and CAST(Due_date as date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) 
		ELSE
			SELECT Item_no, Item_desc, Qty_each, Price_eachFC, Item_TotalFC, Price_each, Item_Total, Is_Tax, ISNULL(TaxTabl.Taxdesc, SPACE(25)) AS Taxdesc, ISNULL(ApdetailTax.Tax_rate,0) AS Tax_rate, Gl_nbr, Apdetail.UniqApHead,Due_Date,Apdetail.UniqApdetl 
				From Apmaster,Supinfo, Apdetail LEFT OUTER JOIN ApdetailTax ON Apdetail.UniqApdetl = ApdetailTax.UniqApdetl
				LEFT OUTER JOIN Taxtabl ON ApdetailTax.Tax_id = Taxtabl.Tax_id
				where supinfo.uniqsupno=apmaster.uniqsupno 
				AND Apmaster.UniqAphead = Apdetail.UniqAphead
				and lPrepay <> 1
				and CHOLDSTATUS=CASE WHEN @cHoldStatus ='' then CHOLDSTATUS else @cHoldStatus end
				and CAST(Due_date as Date) between CAST(@ldBeginDate as date) and cast(@ldEndDate as date) and ApStatus=@lcApSatus
		END
END