-- =============================================
-- Author:		Vicky Lu
-- Create date: 08/26/2009
-- Description:	This procedure will figure out what matltype should be saved to inventor.matltype from all invtmfhd.matltype and the logic setup
-- Modified: 10/10/14 YS replace invtmfhd table with 2 new tables
-- =============================================
CREATE PROCEDURE [dbo].[sp_GetOneInvMatlType] @cUniq_key AS char(10) = '', @cMatType char(10) OUTPUT
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Declare all variables
DECLARE @UqInvMatTp char(10), @InvMatlType char(10), @cChkMatlType char(10), @ReturnMatlType char(10);
DECLARE @lnCount int,@lnTotalNo int, @lnLogic1 int, @lnLogic2 int, @lnLogic3 int;
SET @ReturnMatlType = 'Unk';
SET @lnCount = 0;
SET @lnLogic1 = 0;
SET @lnLogic2 = 0;
SET @lnLogic3 = 0;

-- Create table variable for Invtmfhd to get all MatlType to figure out what's the MatlType for Inventor table
DECLARE @ZInvtMfhdMatTpChk TABLE (MatlType char(10));
--10/10/14 YS replace invtmfhd table with 2 new tables
--INSERT @ZInvtMfhdMatTpChk
--	SELECT UPPER(MatlType) AS MatlType
--		FROM Invtmfhd
--		WHERE Uniq_key = @cUniq_key
--		AND Is_Deleted = 0;

INSERT @ZInvtMfhdMatTpChk
	SELECT UPPER(MatlType) AS MatlType
		FROM MfgrMaster M 	
	WHERE EXISTS (SELECT 1 from InvtMpnLink L 
					WHERE Uniq_key = @cUniq_key and l.mfgrMasterId=M.MfgrMasterId and l.is_deleted=0)
	AND M.Is_Deleted = 0;

-- Create zMatTpLoicView table variable from MatTpLogicView sp
DECLARE @zMatTpLoicView Table (Uqmtlogic char(10),Uqinvmattp char(10),Uqavlmattp char(10),Invmatltype char(10),
	Invmatltypedesc char(30),Avlmatltype char(10),Avlmatltypedesc char(30),Logic int) ;
INSERT @zMatTpLoicView EXEC MatTpLogicView;
 
-- Create ZinvMatlTp for all inventory material types
DECLARE @ZInvMatlTp TABLE (nrecno int identity, UqInvMatTp char(10),InvMatlType char(10));
INSERT @ZInvMatlTp
	SELECT UqInvMatTp, InvMatlType
	FROM InvMatlTp
	ORDER BY CheckOrder;

SET @lnTotalNo = @@ROWCOUNT;

IF (@lnTotalNo>0)
BEGIN	
	SET @lnCount=0;
	WHILE @lnTotalNo>@lnCount
	BEGIN	
		SET @lnCount=@lnCount+1;
		SELECT @UqInvMatTp=UqInvMatTp,@InvMatlType=InvMatlType
			FROM @ZInvMatlTp WHERE nrecno = @lnCount;
		IF (@@ROWCOUNT<>0)
			/*-- Check if any material type is not in ALL but in NOT, if return 0 record means, it does have ALL as logic, will use this logic */
			/*-- First check if has ALL logic first, otherwise even the @@ROWCOUNT=0 doesn't mean we should use this Matltype*/
			SELECT @cChkMatlType = AvlMatlType 
				FROM @zMatTpLoicView
				WHERE Uqinvmattp = @UqInvMatTp 
				AND Logic = 1
			IF (@@ROWCOUNT > 0)
				BEGIN
				/* Not in Logic 1 but in logic 3*/
				SELECT @cChkMatlType = MatlType 
					FROM @ZInvtMfhdMatTpChk 
					WHERE MatlType NOT IN 
						(SELECT UPPER(AvlMatlType) 
							FROM @zMatTpLoicView 
							WHERE Uqinvmattp = @UqInvMatTp 
							AND Logic = 1) 
				SET @lnLogic1 = @@ROWCOUNT;

				SELECT @cChkMatlType = MatlType 
					FROM @ZInvtMfhdMatTpChk 
					WHERE MatlType IN 
						(SELECT UPPER(AvlMatlType) 
							FROM @zMatTpLoicView 
							WHERE Uqinvmattp = @UqInvMatTp 
							AND Logic = 3)
				SET @lnLogic3 = @@ROWCOUNT;

				IF (@lnLogic1+@lnLogic3 = 0)
					BEGIN
						SET @ReturnMatlType = @InvMatlType ;
						BREAK;
					END
				END
			/*-- Check if any material type is not in ALL but in NOT, if return 0 record means, it does have ALL as logic, will use this logic */
			/*-- Second, check if has INC logic first, otherwise even the @@ROWCOUNT=0 doesn't mean we should use this Matltype*/
			SELECT @cChkMatlType = AvlMatlType 
				FROM @zMatTpLoicView
				WHERE Uqinvmattp = @UqInvMatTp 
				AND Logic = 2
			IF (@@ROWCOUNT > 0)
				BEGIN
				/* in Logic 1, Logic 3, but not in logic2)*/
				SELECT @cChkMatlType = MatlType 
					FROM @ZInvtMfhdMatTpChk 
					WHERE MatlType IN 
						(SELECT UPPER(AvlMatlType) 
							FROM @zMatTpLoicView 
							WHERE Uqinvmattp = @UqInvMatTp 
							AND Logic = 1) 
				SET @lnLogic1 = @@ROWCOUNT;

				SELECT @cChkMatlType = MatlType 
					FROM @ZInvtMfhdMatTpChk 
					WHERE MatlType IN 
						(SELECT UPPER(AvlMatlType) 
							FROM @zMatTpLoicView 
							WHERE Uqinvmattp = @UqInvMatTp 
							AND Logic = 3) 
				SET @lnLogic3 = @@ROWCOUNT;

				SELECT @cChkMatlType = MatlType 
					FROM @ZInvtMfhdMatTpChk 
					WHERE MatlType NOT IN 
						(SELECT UPPER(AvlMatlType) 
							FROM @zMatTpLoicView 
							WHERE Uqinvmattp = @UqInvMatTp 
							AND Logic = 2)
				SET @lnLogic2 = @@ROWCOUNT;

				IF (@lnLogic1 + @lnLogic2 + @lnLogic3 = 0)
					BEGIN
						SET @ReturnMatlType = @InvMatlType ;
						BREAK;
					END
				END
			
	END	/* WHILE @lnTotalNo>@lnCount */

END /*(@lnTotalNo<>0)*/

SET @cMatType = @ReturnMatlType ;

END