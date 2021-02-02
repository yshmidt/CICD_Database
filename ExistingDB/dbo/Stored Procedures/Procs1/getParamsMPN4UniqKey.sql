-- =============================================
-- Author:		Yelena
-- Create date:	03/25/2015
-- Description:	procedure to get list of MPNs for a given uniq_key
-- Modifaction: 
-- =============================================
CREATE PROCEDURE [dbo].[getParamsMPN4UniqKey] 
--declare
	@lcUniq_key char(10) = ' ',
	@paramFilter varchar(200) = null		--- first 3+ characters entered by the user
	,@top int = null							-- if not null return number of rows indicated
	,@userId uniqueidentifier = null

AS
BEGIN

-- get list of AML for the associated with a given uniq_key


	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	if (@top is not null)
		select top(@top) M.MfgrMasterId as Value,  RTRIM(M.Mfgr_pt_no)+' '+ RTRIM(M.Partmfgr) AS Text 
		from	MfgrMaster M INNER JOIN InvtMpnLink L on m.mfgrmasterid=L.mfgrmasterid
		WHERE L.uniq_key=@lcUniq_key	
		and M.is_deleted=0 and l.is_deleted=0
		and (@paramFilter is null OR  M.Mfgr_pt_no like '%'+@paramFilter+ '%')
		ORDER BY M.mfgr_pt_no
			
	else
		select M.MfgrMasterId as Value,  RTRIM(M.Mfgr_pt_no)+' '+ RTRIM(M.Partmfgr) AS Text 
		from	MfgrMaster M INNER JOIN InvtMpnLink L on m.mfgrmasterid=L.mfgrmasterid
		WHERE L.uniq_key=@lcUniq_key	
		and M.is_deleted=0 and l.is_deleted=0
		and (@paramFilter is null OR  M.Mfgr_pt_no like '%'+@paramFilter+ '%')
		ORDER BY M.mfgr_pt_no
		
END