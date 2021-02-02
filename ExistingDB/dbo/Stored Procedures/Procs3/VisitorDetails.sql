-- =============================================
-- Author: Nilesh s
-- Create date: 10/09/2014
-- Description:	 Get Visitor details based on badgeId
--[VisitorDetails] 'MX1002' 
-- =============================================
Create  procedure [dbo].[VisitorDetails] 
	@p_BadgeId nvarchar(50) = NULL
	 as
	  BEGIN
		  SELECT *
		 FROM MnxVisitorLog
		 WHERE badgeCode = @p_BadgeId
		 ORDER BY visitId
	  END