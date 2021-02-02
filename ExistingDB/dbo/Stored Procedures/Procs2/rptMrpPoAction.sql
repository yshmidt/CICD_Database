
-- =============================================
-- Author:			Debbie
-- Create date:		11/08/2012
-- Description:		Created for the MRP Action Report ~ PO Actions within MRP
-- Reports:			mrprpt1.rpt 
-- Modifications:	10/01/13 YS remove @lcWhere and add all the new parameters
--					10/30/13 DRP:  in order to get the PO Action report to only display PO Actions for results we had to remove the @mrpAction from the parameters
--								   and declared it within the procedure.
--- 03/28/17 YS changed length of the part_no column from 25 to 35
-- =============================================
CREATE PROCEDURE  [dbo].[rptMrpPoAction]
		---10/01/13 YS remove @lcWhere
		--@lcWhere varchar(max)= '1=1'	-- this will actually be populated from the MRP Filter screen, using Vicky's code
		-- 10/01/13 YS Beginning of new parameters. All parameters have default value and are optional
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		@StartPartNo char(35)=' ',
		@EndPartNo char(35)=' ',
		@Buyer char(3)=' ',
		@PartClass char(8)=' ',
		@partType char(8)=' ',
		@partStatus varchar(10)='All',
		@MrCode varchar(20)=' ',
		--@mrpAction varchar(50)='All PO Actions',	--10/30/13 DRP:  REMOVED FROM PARAMETER   
	--- possible values for mrpAction
	-- 'All Actions' - default
	-- 'All PO Actions'
	-- 'All WO Actions'
	-- 'Pull-Ins'
	-- 'Push-Outs'
	-- 'Release PO'
	-- 'Release WO'
	-- 'Cancel PO'
	-- 'Cancel WO'
		@ProjectUnique char(10)=' ',
		@LastActionDate smalldatetime=NULL
		-- 10/01/13 YS End of new parameters.
		--- 03/28/17 YS changed length of the part_no column from 25 to 35
		,@lcBomParentPart char(35)=''	-- this is the Bom Parent Part.  This too will be populated by the MRP Filter Screen.
		,@lcBomPArentRev char(8)=''		-- this is the BOM Revision.  This too will be populated by the MRP Filter screen.
	
aS
BEGIN

--10/30/13 DRP:  moved from the parameters and declared it here. 
declare @mrpAction varchar(50)='All PO Actions'

--10/01/13 YS populate default if nothing is entered 
IF @LastActionDate is null  -- get default
 		select @LastActionDate=cast (mpssys.viewdays + getdate() as date) from mpssys
 		
--declaring the table so that it can be populated using Yelena Stored Procedured called MrpFullActionView
--- 03/28/17 YS changed length of the part_no column from 25 to 35
	Declare @MrpActionView as table (Uniq_key char(10),Part_class char(8),Part_Type char(8),Part_no char(35),Revision char(8)
									,CustPartNo char(35),CustRev char(8),Descript char(45),Part_sourc char(10),UniqMrpAct char(10))
	---- 10/01/13 YS New parameters in place of @lcWhere.								
	--Insert into @MrpActionView exec MrpFullActionView @lcWhere,@lcBomParentPart,@lcBomPArentRev
	INSERT INTO @MrpActionView EXEC MrpFullActionView 
									@StartPartNo, @EndPartNo,
									@Buyer, @PartClass, @partType, 
									@partStatus, @MrCode, 
									@mrpAction, @ProjectUnique, @LastActionDate, 
									@lcBomParentPart , @lcBomPArentRev

--Below will gather all of the MRP Action information that pertain to PO Actions
	select	m.PART_NO,m.revision,m.PART_CLASS,m.PART_TYPE,m.DESCRIPT,i.U_OF_MEAS,i.PUR_UOFM,MrpAct.* ,micssys.LIC_NAME,MPSSYS.MRPDATE
	from	@MrpActionView M 
			inner join INVENTOR I on m.Uniq_key = i.uniq_key 
			INNER JOIN MRPACT on M.UniqMrpAct = Mrpact.UniqMrpAct
			cross join MICSSYS 
			cross join MPSSYS
			--10/01/13 YS mrp action default for this report to all PO Action and will be returned by @MrpActionView
	--where	CHARINDEX('PO',Action)<>0
	ORDER BY PART_CLASS,Part_no,REVISION,DTTAKEACT
	
end
								