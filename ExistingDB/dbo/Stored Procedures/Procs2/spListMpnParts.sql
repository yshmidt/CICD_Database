-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/19/13
-- Description:	Universal list of manufacturer parts (MPN), designed to use in the pick list .net
-- modified: 11/27/13 YS change to search for @filter if provided anywhere in the mpn, not just in the beginning.
-- 10/10/14 YS replace invtmfhd with 2 new tables
--			 01/28/15 DS changed filter from @filter to @paramFilter
--			 02/11/2015 DRP:  the changes above made by David "changed filter from @filter to @paramFilter" did not work with the Cloud version. 
--- Changed it back to @filter and 02/17/2015 changed it back again. . .
 -- =============================================
CREATE PROCEDURE [dbo].[spListMpnParts] 
	-- Add the parameters for the stored procedure here
	@uniq_key varchar(max)='',   --- if empty list MPNs for all parts, could be a comma separated values , e.g. '_U34567890,_U91345678'
	@showdeleted bit = 0,   --- by default do not show deleted MPNs
	@paramFilter varchar(max)='',                     -- if filter is empty - return all records 
	@userid uniqueidentifier =null -- for future uses
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- 11/27/13 YS trim the filter
	SET @paramFilter=RTRIM(@paramFilter);
	DECLARE @UniqKey TABLE (uniq_key char(10));
	IF @uniq_key <>''
		INSERT INTO @UniqKey SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@uniq_key  ,',')
		
    -- Insert statements for procedure here
	-- 10/10/14 YS replace invtmfhd with 2 new tables
	--SELECT distinct PartMfgr,Mfgr_pt_no	
	--	from INVTMFHD M LEFT OUTER JOIN @UniqKey U on m.UNIQ_KEY =u.uniq_key
	--	where IS_DELETED=@showdeleted
	--	and 1= case when (@uniq_key<>'' and u.uniq_key IS not null) or @uniq_key ='' THEN 1 else 0 end
	--	and 1=CASE WHEN @paramFilter='' then 1 
	--		--11/27/13 YS change to search for @filter if provided anywhere in the mpn, not just in the beginning.
	--			--when LEFT(mfgr_pt_no,len(rtrim(@filter)))=@filter then 1 else 0 end
	--		when PATINDEX('%'+@paramFilter+'%',mfgr_pt_no)<>0 then 1 else 0 end	
	SELECT distinct PartMfgr,Mfgr_pt_no	
		from MfgrMaster M INNER JOIN InvtMPNLink L ON M.MfgrMasterId=L.mfgrMasterId
		LEFT OUTER JOIN @UniqKey U on l.UNIQ_KEY =u.uniq_key
		where L.IS_DELETED=@showdeleted 
		and 1= case when (@uniq_key<>'' and u.uniq_key IS not null) or @uniq_key ='' THEN 1 else 0 end
		and 1=CASE WHEN @paramFilter='' then 1 
			--11/27/13 YS change to search for @filter if provided anywhere in the mpn, not just in the beginning.
				--when LEFT(mfgr_pt_no,len(rtrim(@filter)))=@filter then 1 else 0 end
			when PATINDEX('%'+@paramFilter+'%',mfgr_pt_no)<>0 then 1 else 0 end			
		
			
END