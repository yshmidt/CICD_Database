-- =============================================
-- Author:  Shivshankar P
-- Create date: 07/25/2018
-- Description:	Get Contract information based upon the part and mfgrPart
-- Shivshankar P 30/10/18 : Added Price column 
-- Shivshankar P 01/11/18: Filtered data based upon the quantity
-- Shivshankar P 03/10/19: Change the UNIQSUPNO as UniqSupNo due to case sensitive
-- Shivshankar P 06/08/20: Remove the where condition and the IF else block to get contact that are nearest to provided @quantity
-- EXEC [MrpContractDetails] 'VITRAMON', 'VJ0805A391KXAMT', 1000, 1, 10
-- =============================================
CREATE PROCEDURE [dbo].[MrpContractDetails] 
@partMfgr VARCHAR(8),
@mfgrPartNo VARCHAR(30),
@quantity INT = 0,
@startRecord INT=1,
@endRecord INT=10

AS
   BEGIN
        SET NOCOUNT ON;
              
				SELECT SUPINFO.supname ,Contr_no ,Quantity, quote_no, StartDate, ExpireDate,Pur_ltime 
						,CONTPRIC.Price , ISNULL(lag(QUANTITY) OVER (ORDER BY quantity),0) AS StartNo
						,Quantity AS Qty , ISNULL(lead(QUANTITY) OVER (ORDER BY quantity),0) AS EndNo 
						,SUPINFO.UNIQSUPNO AS UniqSupNo
						-- Shivshankar P 03/10/19: Change the UNIQSUPNO as UniqSupNo due to case sensitive
				INTO #CONTINFO
				 FROM CONTMFGR 
					 JOIN CONTPRIC ON CONTPRIC.MFGR_UNIQ = CONTMFGR.MFGR_UNIQ
					 JOIN CONTRACT ON CONTRACT.CONTR_UNIQ = CONTMFGR.CONTR_UNIQ
					 JOIN contractHeader ON contractHeader.ContractH_unique = CONTRACT.contractH_unique
					 JOIN SUPINFO ON SUPINFO.UNIQSUPNO = contractHeader.uniqsupno
				  WHERE  CONTMFGR.PARTMFGR = @partMfgr  AND CONTMFGR.MFGR_PT_NO =  @mfgrPartNo
				 --	 WHERE StartNo <=  @quantity AND Qty >= @quantity  -- Shivshankar P 01/11/18: Filtered data based upon the quantity
				 -- Shivshankar P 06/08/20: Remove the where condition and the IF else block to get contact that are nearest to provided @quantity
				IF EXISTS(SELECT 1 FROM #CONTINFO WHERE StartNo <= @quantity AND Qty >= @quantity)
				BEGIN
					SELECT * FROM #CONTINFO WHERE StartNo <= @quantity AND Qty >= @quantity
				END
				ELSE IF EXISTS(SELECT 1 FROM #CONTINFO WHERE @quantity < (SELECT MIN(StartNo) AS mini FROM #CONTINFO))
				BEGIN
					SELECT * FROM #CONTINFO WHERE StartNo > @quantity  ORDER BY QUANTITY ASC
				END
				ELSE IF EXISTS(SELECT 1 FROM #CONTINFO WHERE @quantity > (SELECT MAX(Qty) AS maxi FROM #CONTINFO))
				BEGIN
					SELECT TOP 1 * FROM #CONTINFO WHERE Qty < @quantity  ORDER BY ABS( QUANTITY - @quantity ) ASC
				END

 END

