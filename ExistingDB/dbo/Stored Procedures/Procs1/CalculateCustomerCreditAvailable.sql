-- =============================================
-- Author: Nilesh Sa
-- Create date: 01-30-2017
-- Description:	Calculate Credit available of all customer
-- exec CalculateCustomerCreditAvailable '',0,'49F80792-E15E-4B62-B720-21B360E3108A'
-- Nilesh sa 2/25/2019 Added FC conversion for credit available 
-- Nilesh sa 2/28/2019 : Added FcUsedUniq column in a table
-- Nilesh sa 2/28/2019 Added FC conversion
-- Nilesh Sa 3/05/2019 : Fetch customer based on user id
-- Nilesh Sa 3/05/2019 Remove Customer status condition
-- Nilesh Sa 3/06/2018 Check for trans balance first
-- 06/20/2019 YS provide customer list from the calling procedure. Use tCustomer - table type to provide the table information 
-- 03/25/2020 YS Remove limit<>0 to allow to see all the customers with and without credit available
-- 03/25/2020 YS no need for the @serid parameter 
-- 04/29/2020 YS CustName is 50 characters. Thank you Debbie
-- =============================================
CREATE PROCEDURE [dbo].[CalculateCustomerCreditAvailable]
     --DECLARE
     -- Nilesh sa 2/25/2019 Added FC conversion 
     @currencyType CHAR(10) ='', -- Empty - Functional Currency,P - Presentation Currency, F - Multi Currency    
     @lLatestRate BIT = 0 ,-- @lLatestRate = 0 => Original Exchange Rate and @lLatestRate = 1 => Most Recent Exchange Rate   
     -- 06/20/2019 YS new parameter tCustomer type
	 @tCustomerList tCustomer READONLY
	-- 03/25/2020 YS no need for the @serid parameter 
	 --@userId uniqueidentifier  = null -- 3/5/2019 Nilesh Added  @userId parameter 
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @lnCredLimit NUMERIC,@lnBalance NUMERIC(20,2),@lnNotPostAmt NUMERIC,@lnOpenOrder NUMERIC,@SaleDsctPct NUMERIC,
	        			@IsCustInAcctsrec varchar(10),@IsCustInPlmain varchar(10),@MAXID INT, @Counter INT,@lcCustno CHAR(10)
					,@lFCInstalled BIT -- Nilesh sa 2/25/2019 Added FC conversion for credit available
					,@fcUsedUniq CHAR(10); -- Nilesh sa 2/28/2019 : Added FcUsedUniq column in a table  
    
	-- 04/29/2020 YS CustName is 50 characters. 
      DECLARE @customerTable TABLE(CustName CHAR(50),CustNo CHAR(10),CreditLimit NUMERIC(20,2),CreditAvailable NUMERIC(20,2),FcUsedUniq CHAR(10),RowId INT IDENTITY(1,1));
	-- Nilesh sa 2/28/2019 : Added FcUsedUniq column in a table

	INSERT INTO @customerTable
	SELECT c.CustName,c.CustNo,c.Credlimit,CAST(0 AS NUMERIC(20,2)) as CreditAvailable,c.FcUsed_uniq FROM CUSTOMER C
	---06/20/19 YS  use the table provided by the calling SP. This table will lsit only customers thta are available to the user
	--and the data is populated using aspmnxSP_GetCustomers4User SP
	INNER JOIN @tCustomerList t on c.CUSTNO=t.custno
	--JOIN aspmnx_UserCustomers ON  aspmnx_UserCustomers.fkCustno=Customer.CUSTNO  AND fkUserId = @UserId  
	 -- Nilesh Sa 3/05/2019 : Fetch customer based on user id
	--03/25/20 YS remove creditlimit condition
	--WHERE 
	-- STATUS='active' AND  -- Nilesh Sa 3/5/2019 Remove Customer status condition
	--03/25/20 YS remove creditlimit condition, remove order by
	---c.CREDLIMIT <> 0 
	--ORDER BY c.CUSTNAME

	-- Nilesh sa 2/25/2019 Added FC conversion for credit available
	DECLARE @fcUsedViewTable TABLE(FcUsedUniq CHAR(10),Country VARCHAR(60),CURRENCY VARCHAR(40), Symbol VARCHAR(3) ,Prefix VARCHAR(7),UNIT VARCHAR(10),Subunit VARCHAR(10),  
      Thou_sep VARCHAR(1),Deci_Sep VARCHAR(1),Deci_no NUMERIC(2,0),AskPrice NUMERIC(13,5),AskPricePR NUMERIC(13,5),FcHist_key CHAR(10),FcdateTime SMALLDATETIME);    
    
      SELECT @lFCInstalled = dbo.fn_IsFCInstalled()  
	
	IF @lFCInstalled = 1
	BEGIN
	      -- Fetch FCUsed data and inserting to temp table   
		;WITH ZMaxDate AS  
		 (SELECT MAX(Fcdatetime) AS Fcdatetime, FcUsed_Uniq  
		  FROM FcHistory   
		  GROUP BY Fcused_Uniq),  
		 ZFCPrice AS   
		 (SELECT FcHistory.AskPrice, AskPricePR, FcHistory.FcUsed_Uniq, FcHist_key, FcHistory.Fcdatetime  
		  FROM FcHistory, ZMaxDate  
		  WHERE FcHistory.FcUsed_Uniq = ZMaxDate.FcUsed_Uniq  
		  AND FcHistory.Fcdatetime = ZMaxDate.Fcdatetime)  
 
		  INSERT INTO @fcUsedViewTable  
		  SELECT FcUsed.FCUsed_Uniq, Country, CURRENCY, Symbol, Prefix, UNIT, Subunit, Thou_sep, Deci_Sep, Deci_no,   
		  ISNULL(AskPrice,0) AS AskPrice, ISNULL(AskPricePR,0) AS AskPricePR, FcHist_key, FcdateTime  
		  FROM FCUsed LEFT OUTER JOIN ZFCPrice  
		  ON FcUsed.FcUsed_Uniq = ZFCPrice.FcUsed_Uniq  
		  ORDER BY Country  
	END  

	SET @COUNTER = 1
	SELECT @MAXID = COUNT(*) FROM @customerTable

	WHILE (@COUNTER <= @MAXID)
	BEGIN
		--DO THE PROCESSING HERE 
		SELECT @lcCustno = CustNo, @lnCredLimit = ISNULL(CreditLimit,0),@fcUsedUniq = FcUsedUniq
		FROM @customerTable WHERE RowId = @COUNTER

		-- Modified : 07-18-2017  Satish B : Check weather the selected customer is present in Acctsrec table or not. If yes then calculate @lnBalance else set @lnBalance to zero
		SET @IsCustInAcctsrec = (SELECT TOP 1 CUSTNO FROM Acctsrec WHERE Custno =@lcCustno)

		IF(@IsCustInAcctsrec IS NULL) 
		  BEGIN
			SET @lnBalance=0;
		  END
		ELSE
		  BEGIN
		-- Nilesh sa 2/25/2019 Added FC conversion for credit available
		     IF @lFCInstalled = 1 AND @currencyType = 'P'    
		     BEGIN  
				    IF @lLatestRate = 0   
					BEGIN  
						SELECT @lnBalance= 
						CASE WHEN ISNULL(SUM(AcctsRec.InvtotalFC-ArCreditsFC),0) = 0 THEN 0  -- Nilesh Sa 3/06/2018 Check for trans balance first
						ELSE SUM(INVTOTALPR - ARCREDITSPR) END 
						FROM Acctsrec WHERE Custno =@lcCustno
					END
				    ELSE
					BEGIN  
						SELECT @lnBalance= 
						CASE WHEN ISNULL(SUM(AcctsRec.InvtotalFC-ArCreditsFC),0) = 0 THEN 0  
						ELSE SUM(INVTOTALFC - ARCREDITSFC) / fc.AskPricePR  END
						FROM Acctsrec
						LEFT OUTER JOIN @fcUsedViewTable fc ON fc.FcUsedUniq = @fcUsedUniq 
						-- Nilesh sa 2/28/2019 Added FC conversion
						WHERE Custno =@lcCustno
						GROUP BY fc.AskPricePR
					END
			END
			ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
					BEGIN 
						 SELECT @lnBalance= SUM(INVTOTALFC - ARCREDITSFC) FROM Acctsrec WHERE Custno =@lcCustno                    
					END
			ELSE 
			 BEGIN 
				     IF @lLatestRate = 0   
						BEGIN  
						   SELECT @lnBalance= SUM(INVTOTAL - ARCREDITS) FROM Acctsrec WHERE Custno =@lcCustno                    
						END
				    ELSE
						BEGIN  
							SELECT @lnBalance= 
							CASE WHEN ISNULL(SUM(AcctsRec.InvtotalFC-ArCreditsFC),0) = 0 THEN 0  
							ELSE SUM(INVTOTALFC - ARCREDITSFC) / fc.AskPrice END
							FROM Acctsrec
							LEFT OUTER JOIN @fcUsedViewTable fc ON fc.FcUsedUniq = @fcUsedUniq
							-- Nilesh sa 2/28/2019 Added FC conversion
							WHERE Custno =@lcCustno
							GROUP BY fc.AskPrice
						END 
			 END
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
		-- Nilesh sa 2/25/2019 Added FC conversion for credit available
		     IF @lFCInstalled = 1 AND @currencyType = 'P'    
		     BEGIN  
				IF @lLatestRate = 0   
				BEGIN  
					SELECT @lnNotPostAmt=
					CASE WHEN ISNULL(SUM(INVTOTALFC),0) = 0 THEN 0
					ELSE SUM(INVTOTALPR) END
					FROM Plmain WHERE Print_Invo = 0 AND Custno = @lcCustno

				END
				ELSE
				BEGIN  
					SELECT @lnNotPostAmt=SUM(INVTOTALFC)/ fc.AskPricePR FROM Plmain	
					LEFT OUTER JOIN @fcUsedViewTable fc ON fc.FcUsedUniq = @fcUsedUniq
					-- Nilesh sa 2/28/2019 Added FC conversion 
					WHERE Print_Invo = 0 AND Custno = @lcCustno
					GROUP BY fc.AskPricePR
				END
			END
			ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
				BEGIN 
					 SELECT @lnNotPostAmt=SUM(INVTOTALFC) FROM Plmain WHERE Print_Invo = 0 AND Custno = @lcCustno               
				END
			ELSE 
			 BEGIN 
				IF @lLatestRate = 0   
					BEGIN  
					   SELECT @lnNotPostAmt=SUM(InvTotal) FROM Plmain WHERE Print_Invo = 0 AND Custno = @lcCustno              
					END
				ELSE
					BEGIN  
					   SELECT @lnNotPostAmt= SUM(INVTOTALFC)/ fc.AskPrice 
					   FROM Plmain	
					   LEFT OUTER JOIN @fcUsedViewTable fc ON fc.FcUsedUniq = @fcUsedUniq
					   -- Nilesh sa 2/28/2019 Added FC conversion
					   WHERE Print_Invo = 0 AND Custno = @lcCustno
					   GROUP BY fc.AskPrice
					END 
			 END
		  END	

	
		-- assign 0 to @lnOpenOrder
		SET @lnOpenOrder=0
		--- check if need to calculate open order amount
		SELECT @SaleDsctPct = s.Discount FROM SALEDSCT s JOIN CUSTOMER c ON s.SALEDSCTID=c.SALEDSCTID AND c.CUSTNO=@lcCustno
   
           -- Nilesh sa 2/25/2019 Added FC conversion for credit available
		IF @lFCInstalled = 1 AND @currencyType = 'P'    
		     BEGIN  
				    IF @lLatestRate = 0   
					BEGIN  
						SELECT @lnOpenOrder=
								SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN 
								(CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0 ELSE PRICEPR END * Balance) 
								WHEN SOPRICES.FLAT = 0 and Quantity>ShippedQty THEN (CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0.00 ELSE PRICEPR END *(Quantity-ShippedQty)) 
								WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN CASE WHEN ISNULL(PRICEFC,0) = 0 THEN 0.00 ELSE PRICEPR END
								ELSE 0.00 END ,2))
							FROM SOMAIN, SODETAIL, SOPRICES
							WHERE ORD_TYPE = 'Open'
							AND SOMAIN.SONO = SODETAIL.SONO
							AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN	
							AND CUSTNO = @lcCustno        
					END
				    ELSE
					BEGIN  
						   SELECT @lnOpenOrder=
								SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (PRICEFC*Balance) 
								WHEN SOPRICES.FLAT = 0 and Quantity>ShippedQty THEN (PRICEFC*(Quantity-ShippedQty)) 
								WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN PRICEFC
								ELSE 0.00 END ,2)) / fc.AskPricePR
							FROM SOMAIN, SODETAIL, SOPRICES,@fcUsedViewTable fc 
							WHERE ORD_TYPE = 'Open'
							AND SOMAIN.SONO = SODETAIL.SONO
							AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN	
							AND CUSTNO = @lcCustno        
							AND  fc.FcUsedUniq = @fcUsedUniq -- Nilesh sa 2/28/2019 Added FC conversion
							GROUP BY fc.AskPricePR
					END
			END
			ELSE IF @lFCInstalled = 1 AND @currencyType = 'F'    
					BEGIN 
						 SELECT @lnOpenOrder=
								SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (PRICEFC*Balance) 
								WHEN SOPRICES.FLAT = 0 and Quantity>ShippedQty THEN (PRICEFC*(Quantity-ShippedQty)) 
								WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN PRICEFC
								ELSE 0.00 END ,2))
							FROM SOMAIN, SODETAIL, SOPRICES
							WHERE ORD_TYPE = 'Open'
							AND SOMAIN.SONO = SODETAIL.SONO
							AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN	
							AND CUSTNO = @lcCustno                   
					END
			ELSE 
			 BEGIN 
				     IF @lLatestRate = 0   
						BEGIN  
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
						END
				    ELSE
						BEGIN  
						    SELECT @lnOpenOrder=
								SUM(ROUND(CASE WHEN SOPRICES.FLAT = 0 and RecordType = 'P' THEN (PRICEFC*Balance) 
								WHEN SOPRICES.FLAT = 0 and Quantity>ShippedQty THEN (PRICEFC*(Quantity-ShippedQty)) 
								WHEN SOPRICES.FLAT = 1 and Sodetail.SHIPPEDQTY=0 THEN PRICEFC
								ELSE 0.00 END ,2)) / fc.AskPrice
							FROM SOMAIN, SODETAIL, SOPRICES,@fcUsedViewTable fc 
							WHERE ORD_TYPE = 'Open'
							AND SOMAIN.SONO = SODETAIL.SONO
							AND SODETAIL.UNIQUELN = SOPRICES.UNIQUELN	
							AND CUSTNO = @lcCustno        
							AND  fc.FcUsedUniq = @fcUsedUniq -- Nilesh sa 2/28/2019 Added FC conversion
							GROUP BY fc.AskPrice
						END 
			 END

		SET @lnOpenOrder = ROUND(isnull(@lnOpenOrder,0.00)*((100 - ISNULL(@SaleDsctPct,0))/100),2) -- Nilesh sa 1/19/2018 Check Isnull for ISNULL

		IF @lFCInstalled = 1
		BEGIN
			UPDATE c1 
			SET CreditAvailable  = 
			ISNULL(CASE WHEN @currencyType = 'P' AND @lFCInstalled = 1 THEN @lnCredLimit/FC.AskPricePR
				WHEN @currencyType = 'F' AND @lFCInstalled = 1 THEN @lnCredLimit
				WHEN @currencyType = ''  AND @lFCInstalled = 1 THEN @lnCredLimit/fc.AskPrice END,0) - 
			ISNULL(@lnBalance,0)- ISNULL(@lnNotPostAmt,0) - ISNULL(@lnOpenOrder,0) 
			FROM	@customerTable c1
			JOIN @fcUsedViewTable fc ON c1.FcUsedUniq = fc.FcUsedUniq
			WHERE CustNo = @lcCustno
		END
		ELSE
		BEGIN
			UPDATE @customerTable 
			SET CreditAvailable  = 
			ISNULL(@lnCredLimit,0) - ISNULL(@lnBalance,0)- ISNULL(@lnNotPostAmt,0) - ISNULL(@lnOpenOrder,0) 
			WHERE CustNo = @lcCustno
		END

		SET @COUNTER = @COUNTER + 1
	END
	SELECT CustName,CustNo,CreditAvailable FROM @customerTable
END