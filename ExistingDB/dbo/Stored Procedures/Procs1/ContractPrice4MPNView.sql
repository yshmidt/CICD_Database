-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 06/05/2012  
-- Description: Get ContractPrice4MPN (useing for generatin PO from MRP)  
-- 10/30/13 YS added expiredate and startdate  
--12/31/2013 SP added contpric.PRIC_UNIQ
--02/02/17 YS modifed contract tables
-- =============================================  
CREATE PROCEDURE [dbo].[ContractPrice4MPNView]  
 -- Add the parameters for the stored procedure here  
 @lcUniq_key char(10)=' ',  
 @lcUniqSUpno char(10)=' ',   
 @lcPartMfgr char(8)=' ',  
 @lcMfgr_pt_no  char(30)=' '  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
  
    -- Insert statements for procedure here  
    -- 10/30/13 YS added expiredate and startdate  
    --12/31/2013 contpric.PRIC_UNIQ retrived for PO details update.
	--02/02/17 YS modifed contract tables
 SELECT contract.uniq_key,h.contr_no,h.[EXPIREDATE],h.STARTDATE,
  mfgr_pt_no,contmfgr.contr_uniq,contmfgr.mfgr_uniq,contpric.quantity,contpric.price,contpric.PRIC_UNIQ   
 FROM contmfgr INNER JOIN contpric on contpric.mfgr_uniq =contmfgr.mfgr_uniq  
 INNER JOIN [CONTRACT] on contmfgr.contr_uniq =contract.contr_uniq  
 INNER JOIN ContractHeader H on contract.contractH_unique=h.contractH_unique
 WHERE contract.uniq_key = @lcUniq_key   
 AND h.UniqSupno =@lcUniqSUpno   
 AND contmfgr.partmfgr = @lcPartMfgr   
 AND contmfgr.mfgr_pt_no = @lcMfgr_pt_no   
   
   
END