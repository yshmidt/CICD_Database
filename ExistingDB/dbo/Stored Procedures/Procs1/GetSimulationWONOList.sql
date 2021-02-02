-- =============================================
-- Author:		Rajendra K	
-- Create date: <11/05/2018>
-- Description:Get simulation WONO Data
-- Satish B: 12/20/2018 Replace 'Canceled' with Cancel
-- Satish B: 01/02/2019 Add if block for WONO for PO and add existing part in ELSE block
-- EXEC GetSimulationWONOList '0000000111',1,1,1000,'',10000
-- =============================================
--exec [GetSimulationWONOList] @IsWOForPo=false
--[GetSimulationWONOList] 1
CREATE PROCEDURE [dbo].[GetSimulationWONOList]
@IsWOForPo bit = 0
AS
BEGIN
SET NOCOUNT ON
	-- Satish B: 01/02/2019 Add if block for WONO for PO and add existing part in ELSE block
	IF(@IsWOForPo = 1)
		BEGIN
			SELECT W.UNIQ_KEY AS UniqKey
				   ,W.WONO AS WONO
				   ,W.BLDQTY AS Quantity
					--Satish B: 12/20/2018 Replace 'Canceled' with Cancel
					FROM WOENTRY W WHERE OPENCLOS NOT IN('Closed','Cancel') 
		END
	ELSE
		BEGIN
			SELECT W.UNIQ_KEY AS UniqKey
				   ,W.WONO AS WONO
				   ,W.BLDQTY AS Quantity
					--Satish B: 12/20/2018 Replace 'Canceled' with Cancel
					FROM WOENTRY W WHERE OPENCLOS NOT IN('Admin Hold','Mfg Hold','Closed','Cancel') 
					AND W.WONO NOT IN (SELECT WONO FROM KAMAIN)
		END
END