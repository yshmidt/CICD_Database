-- =============================================
-- Author:Satish B
-- Create date: 11-17-2016
-- Description:	Calculate And Get Credit Limit For Customer
-- Modified : 12-05-2016  Satish B : Get @CalOpenOrd value from setting tables
-- Modified : 07-18-2017  Satish B  : Declare variables @IsCustInAcctsrec varchar(10) and @IsCustInPlmain varchar(10)
-- Modified : 07-18-2017  Satish B : Check weather the selected customer is present in Acctsrec table or not. If yes then calculate @lnBalance else set @lnBalance to zero
-- Modified : 07-18-2017  Satish B : Check weather the selected customer is present in Plmain table or not. If yes then calculate @@lnNotPostAmt else set @@lnNotPostAmt to zero
-- Modified : 10-12-2017  Satish B : Check ISNULL
-- Nilesh sa : 01/19/2018 Added left join to get setting value 
-- Nilesh sa : 01/19/2018 Check Isnull for ISNULL
-- CalculateCustomerCreditLimit '0000000330'
-- =============================================
CREATE PROCEDURE CalculateCustomerCreditLimit
	@lcCustno varchar(50)=''
	--@CalOpenOrd bit
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @lnAvailableCred varchar(50),@lnCredLimit numeric,@lnBalance numeric(20,2),@lnNotPostAmt numeric,@lnOpenOrder numeric,@SaleDsctPct numeric,@CalOpenOrd bit,
	        -- Modified : 07-18-2017 Satish B  : Declare variables @IsCustInAcctsrec varchar(10) and @IsCustInPlmain varchar(10)
			@IsCustInAcctsrec varchar(10),@IsCustInPlmain varchar(10)

	SELECT @lnCredLimit=Credlimit FROM CUSTOMER  WHERE CUSTNO=@lcCustno
	-- Modified : 07-18-2017  Satish B : Check weather the selected customer is present in Acctsrec table or not. If yes then calculate @lnBalance else set @lnBalance to zero
	SET @IsCustInAcctsrec = (SELECT TOP 1 CUSTNO FROM Acctsrec WHERE Custno =@lcCustno)
	IF(@IsCustInAcctsrec IS NULL) 
	  BEGIN
			SET @lnBalance=0;
	  END
	ELSE
	  BEGIN
			SELECT @lnBalance= SUM(InvTotal - ArCredits) FROM Acctsrec WHERE Custno =@lcCustno
	  END
	
	
	-- 12/02/16 YS if you are working on the packing list in the edit mode, this calculation will include the packing list that you are working on
	--- if the price or number of lines are changed this caluclation will produce incorrect result. If you are taking this into concideration elsewere disregard my comments
	-- Modified : 07-18-2017  Satish B : Check weather the selected customer is present in Plmain table or not. If yes then calculate @@lnNotPostAmt else set @@lnNotPostAmt to zero
	SET @IsCustInPlmain = (SELECT TOP 1 CUSTNO FROM Plmain WHERE Custno =@lcCustno)
	IF(@IsCustInPlmain IS NULL) 
	  BEGIN
			SET @lnNotPostAmt=0;
	  END
	ELSE
	  BEGIN
			SELECT @lnNotPostAmt=SUM(InvTotal) FROM Plmain	WHERE Print_Invo = 0 AND Custno = @lcCustno
	  END
	
	
	---- 12/02/16 YS if @CalOpenOrd is 0 we do not need to run the code below. Another question is why do you pass @CalOpenOrd as aparameter, instead of getting the value inside this SP?
	-- assign 0 to @lnOpenOrder
	SET @lnOpenOrder=0
	--- check if need to calculate open order amount

	--12/05/16 Satish B : Get @CalOpenOrd value from setting tables
	 SET @CalOpenOrd=(SELECT ISNULL(w.settingValue,m.settingValue) FROM mnxSettingsManagement m -- Nilesh sa 1/19/2018 -- Added left join to get setting value 
         LEFT JOIN wmSettingsManagement w ON m.settingid=w.settingId
         WHERE m.settingname='CalOpenOrd')
	IF @CalOpenOrd=1
	BEGIN
	
		SELECT @SaleDsctPct = s.Discount FROM SALEDSCT s JOIN CUSTOMER c ON s.SALEDSCTID=c.SALEDSCTID AND c.CUSTNO=@lcCustno
   
			SELECT @lnOpenOrder=
   			SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (Price*Balance) 
				WHEN SOPRICES.FLAT = 0 and Quantity>ShippedQty THEN (Price*(Quantity-ShippedQty)) 
				WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN Price
				ELSE 0.00 END ,2))
			FROM SOMAIN, SODETAIL, SOPRICES
			WHERE ORD_TYPE = 'Open'
			AND SOMAIN.SONO = SODETAIL.SONO
			AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN	
			AND CUSTNO = @lcCustno

		--SET @lnOpenOrder = ROUND((ISNULL(@ZSoAmt1, 0) + ISNULL(@ZSoAmt2,0))*(( 100 - @SaleDsctPct)/100),2)
		SET @lnOpenOrder = ROUND(isnull(@lnOpenOrder,0.00)*((100 - ISNULL(@SaleDsctPct,0))/100),2) -- Nilesh sa 1/19/2018 Check Isnull for ISNULL
	END ---if(@CalOpenOrd=1)
	 --10-12-2017  Satish B : Check ISNULL
	--SELECT @lnCredLimit - @lnBalance- @lnNotPostAmt - @lnOpenOrder as AvailableCredit
	SELECT ISNULL(@lnCredLimit,0) - ISNULL(@lnBalance,0)- ISNULL(@lnNotPostAmt,0) - ISNULL(@lnOpenOrder,0) as AvailableCredit
END