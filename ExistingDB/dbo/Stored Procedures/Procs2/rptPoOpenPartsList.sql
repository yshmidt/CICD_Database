-- =============================================
-- Author:		David Sharp
-- Create date: 03/28/2018
-- Description:	Get a list of parts on the selected PO
-- =============================================
CREATE PROCEDURE [dbo].[rptPoOpenPartsList]
	-- Add the parameters for the stored procedure here
	@lcPoNum as varchar (15) = ''
	,@userId uniqueidentifier = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT	CASE WHEN POITEMS.UNIQ_KEY = '' THEN RTRIM(LTRIM(POITEMS.PART_NO)) ELSE RTRIM(LTRIM(I1.PART_NO)) END AS PART_NO
			--,CASE WHEN POITEMS.UNIQ_KEY = '' then CAST ('' as CHAR(8)) else I1.REVISION end as REVISION		
		FROM	POMAIN
				INNER JOIN POITEMS ON POMAIN.PONUM = POITEMS.PONUM
				LEFT OUTER JOIN INVENTOR as I1 on poitems. UNIQ_KEY = I1.UNIQ_KEY
		WHERE	POMAIN.POSTATUS = 'OPEN'
				AND POITEMS.LCANCEL <> 1
				AND POITEMS.ORD_QTY-POITEMS.ACPT_QTY <> 0.00
				AND POMAIN.PONUM = dbo.padl(@lcPoNum,15,'0')
END