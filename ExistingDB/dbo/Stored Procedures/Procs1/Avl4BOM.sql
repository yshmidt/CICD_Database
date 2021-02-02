
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/09/2014
-- Description:	return AVL call from BOM API  
-- Modified: 10/08/14 YS use new tables in place of invtmfhd
-- 10/29/14 YS move orderpref to invtmpnlink
-- Modified: 01/06/2015 DRP: Added @customerStatus Filter
-- =============================================
CREATE PROCEDURE [dbo].[Avl4BOM] 
	-- Add the parameters for the stored procedure here
	@BomParent char(10)=' ', @showSubAssembly bit=0, @IncludeMakeBuy bit=0,@customerStatus varchar (20) = 'All', @UserId uniqueidentifier=NULL

	-- list of parameters:
	-- 1. @BomParent - top level BOM uniq_key 
	-- 2. @showSubAssembly - explode 'MAKE' parts
	-- 2. @IncludeMakeBuy - if showSubAssembly = 1 this parameter indicates if make/buy parts will be exploded as well; if 0 - will not (default 1)
	-- 3. @UserId - check if user allowed to view a bom based on the customer list assigned to a user
	
	--- this sp will 
	----- 1. find BOM information and explode PHANTOM. It will also explode Make parts if @showSubAssembly=1. If the make part has make/buy flag and @IncludeMakeBuy=0, then Make/Buy will not be indented to the next level
	----- 2. Figure out AVL (if internal part, but BOM assigned to a customer, an appropriate consign part AVL will be found
	----- 3. Remove AVL if any AntiAvl are assigned
	AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
		
	declare @tBom table (bomParent char(10),uniqbomno char(10),bomcustno char(10),UNIQ_KEY char(10),Part_sourc char(10) ,
		Make_buy bit,Status char(10),[Level] integer ,
		[path] varchar(max),[sort] varchar(max), CustUniqKey char(10)) ;

	DECLARE @tCustomers tCustomer ;
	--INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid ;
	INSERT INTO @tCustomers EXEC [aspmnxSP_GetCustomers4User] @userid,null,@customerStatus ;

	INSERT INTO @tBom exec miniBomIndented @BomParent, @showSubAssembly, @IncludeMakeBuy 
	--10/08/14 YS use new tables in place of invtmfhd
	;WITH BomWithAvl
  AS
  (
  ---- 10/29/14 YS move orderpref to invtmpnlink
  select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE
 	FROM @tBom B 
	INNER JOIN @tCustomers t on B.bomcustno=t.custno
	--LEFT OUTER JOIN INVTMFHD ON B.CustUniqKey=INVTMFHD.UNIQ_KEY
	LEFT OUTER JOIN InvtMPNLink L ON  B.CustUniqKey=L.UNIQ_KEY
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	WHERE B.CustUniqKey<>' '
	AND M.IS_DELETED =0 
	and L.is_deleted=0
	and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.CustUniqKey and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )
UNION ALL
	select B.*,M.PARTMFGR ,M.MFGR_PT_NO,l.ORDERPREF ,L.UNIQMFGRHD ,M.MatlType as MfgrMatlType,M.MATLTYPEVALUE
	FROM @tBom B 
	INNER JOIN @tCustomers t on B.bomcustno=t.custno
	--LEFT OUTER JOIN INVTMFHD ON B.UNIQ_KEY=INVTMFHD.UNIQ_KEY 
	LEFT OUTER JOIN InvtMPNLink L ON  B.Uniq_Key=L.UNIQ_KEY
	LEFT OUTER JOIN MfgrMaster M ON L.mfgrMasterId=M.MfgrMasterId
	WHERE B.CustUniqKey=' '
	AND M.IS_DELETED =0 
	AND l.is_deleted=0
	--and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =INVTMFHD.PARTMFGR and A.MFGR_PT_NO =Invtmfhd.MFGR_PT_NO )
	and NOT EXISTS (SELECT bomParent,UNIQ_KEY FROM ANTIAVL A where A.BOMPARENT =B.bomParent and A.UNIQ_KEY = B.UNIQ_KEY and A.PARTMFGR =M.PARTMFGR and A.MFGR_PT_NO =M.MFGR_PT_NO )
	)
	
	SELECT   * from BomWithAvl 

END    