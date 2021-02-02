		-- =============================================
		-- Author:		Vicky Lu	
		-- Create date: <04/25/13>
		-- Description:	<return the part number information with passed in part_no, revision data, used in SO import validation checking
		-- =============================================
		CREATE PROCEDURE [dbo].[sp_GetPartInformationByPart_noRevision] 
			-- Add the parameters for the stored procedure here
			@ltPart_noRevision AS tPart_noRevision READONLY
		AS
		BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

		SELECT *
			FROM INVENTOR 
			WHERE Part_no+UPPER(Revision) IN
				(SELECT part_no+UPPER(Revision) 
					FROM @ltPart_noRevision T) 
			AND Inventor.Part_sourc<>'CONSG' 
			AND Inventor.Status='Active'
			
		END