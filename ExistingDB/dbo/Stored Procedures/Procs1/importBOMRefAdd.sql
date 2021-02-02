-- =============================================
-- Author:		David Sharp
-- Create date: 5/2/2012
-- Description:	add import Ref Desg detail
-- 06/03/13 YS modifications to fn_parseRefDesgString() function
-- =============================================
CREATE PROCEDURE [dbo].[importBOMRefAdd]
	-- Add the parameters for the stored procedure here
	@importId uniqueidentifier,
	@rowId uniqueidentifier,
	@refString varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

     -- Insert statements for procedure here
    --06/03/13 YS added nSeq column returned by fn_parseRefDesgString()
	-- I don't think we need an additional table variable				
	--DECLARE @refTable TABLE(rowId uniqueidentifier,ref varchar(50),nSeq int)
	
	--INSERT INTO @refTable(rowId,ref,nSeq)
	--	SELECT rowId,ref,nSeq FROM dbo.fn_parseRefDesgString(@rowId,@refString,',','-')
    
	--INSERT INTO importBOMRefDesg(fkImportId,fkRowId,refDesg)
	--	SELECT @importId,@rowId,ref FROM @refTable
	
	--06/03/13 YS populate RefOrd column with nSeq column from fn_parseRefDesgString
	INSERT INTO importBOMRefDesg(fkImportId,fkRowId,refDesg,RefOrd)
			SELECT DISTINCT @importId,rowId,ref,nSeq FROM dbo.fn_parseRefDesgString(@rowId,@refString,',','-')
END