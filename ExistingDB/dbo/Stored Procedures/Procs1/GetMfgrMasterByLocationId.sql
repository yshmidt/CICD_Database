-- =============================================
-- Author:	Sachin shevale
-- Create date: 09/14/15
-- Description:	get MfgrMaster for sync records by sync location id
-- =============================================
CREATE PROCEDURE [dbo].[GetMfgrMasterByLocationId] 
-- parameters for the stored procedure here
	@LocationId INT
AS	
BEGIN
	SELECT 

			MfgrMasterId,PartMfgr
			,mfgr_pt_no  MfgrPtNo
			,mfgrDescript
			,Root
			,marking
			,body
			,pitch
			,part_spec  PartSpec
			,part_pkg  PartPkg
			,uniqpkg
			,is_deleted  IsDeleted
			,MatlType
			,autolocation
			,MATLTYPEVALUE
			,LDISALLOWBUY
			,LDISALLOWKIT
			,SFTYSTK
			,MOISTURE
			,EICCSTATUS
			,LifeCycle
			,PTLENGTH
			,PTWIDTH
			,PTDEPTH
			,ptwt PtWt
			,qtyPerPkg  QtyPerPackage
			,IsSynchronizedFlag

	FROM MfgrMaster cc
	LEFT OUTER JOIN SynchronizationMultiLocationLog sml
	ON cc.MfgrMasterId = sml.UniqueNum
	WHERE cc.IsSynchronizedFlag=0 
	 AND cc.MfgrMasterId NOT IN (SELECT DISTINCT sml.UniqueNum FROM SynchronizationMultiLocationLog sml WHERE sml.LocationId = @LocationId
	 AND sml.IsSynchronizationFlag=1 ) 
			        			
END	