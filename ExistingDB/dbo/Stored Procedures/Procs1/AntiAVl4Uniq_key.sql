﻿-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 06/23/2010
-- Description:	Find all records in AntiAvl table for specific uniq_key
-- =============================================
CREATE PROCEDURE [dbo].[AntiAVl4Uniq_key] 
	-- Add the parameters for the stored procedure here
	@lcUniq_key char(10)=' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    
	SELECT BomParent,Uniq_key,PartMfgr,Mfgr_pt_no,UNIQANTI  
	from ANTIAVL
	WHERE Uniq_key=@lcUniq_key 
END
