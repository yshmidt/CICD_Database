-- =============================================  
-- Author:  Shivshankar P  
-- Create date: 12/06/2018  
-- Description:  Update MRPACT table  
-- Modify : Shivshankar P 05/25/2020 : Set ActionNotes = '' when we only Update User Field from UI
--          Shivshankar P 06/26/2020 : Added @isSavePS parameter and if @isSavePS = 1 the we will update all the records for the same part and MPN with the same price and supplier
-- =============================================  
CREATE PROCEDURE [dbo].[UpdateMRPACTData]  
(  
	@tMrpUserFields tMrpUserFields READONLY,
	@isSavePS BIT = 0 
)   
AS  
  BEGIN   
  SET NOCOUNT ON;  
   DECLARE @errorMessage NVARCHAR(MAX) ,@errorSeverity INT, @errorState INT  
   -- Modify : Shivshankar P 05/25/2020 : Set ActionNotes = '' when we only Update User Field from UI
        UPDATE MRPACT SET UserReqQty = tMrpAct.UserReqQty, UserPrice = tMrpAct.UserPrice, UserPartMfgr = tMrpAct.UserPartMfgr,  
                         UserMfgrPtNo=tMrpAct.UserMfgrPtNo, UniqSupNo = tMrpAct.UniqSupNo, ActionNotes = ''  
        FROM  MRPACT act 
		JOIN  @tMrpUserFields tMrpAct ON  act.UNIQMRPACT =  tMrpAct.UNIQMRPACT  
		-- Shivshankar P 06/26/2020 : Added @isSavePS parameter and if @isSavePS = 1 the we will update all the records for the same part and MPN with the same price and supplier
		IF(@isSavePS = 1)
		BEGIN
		         UPDATE MRPACT SET UserPrice = tMrpAct.UserPrice, UserPartMfgr = tMrpAct.UserPartMfgr,  
                         UserMfgrPtNo=tMrpAct.UserMfgrPtNo, UniqSupNo = tMrpAct.UniqSupNo, ActionNotes = ''  
				 FROM  MRPACT act 
				 JOIN  @tMrpUserFields tMrpAct ON  act.UNIQ_KEY = tMrpAct.UniqKey 
				 WHERE act.[ACTION]  ='RELEASE PO' AND  ISNULL(act.ActionStatus,'') <> 'Success'
				 AND TRIM(ISNULL(tMrpAct.UniqSupNo, '')) <> ''
				 AND ((TRIM(SUBSTRING(PREFAVL,0,CHARINDEX(' ',act.PREFAVL,0))) = tMrpAct.UserPartMfgr 
				 AND TRIM(RIGHT(SUBSTRING(PREFAVL,CHARINDEX(' ',act.PREFAVL),300),120)) = tMrpAct.UserMfgrPtNo)) 
		END
  END