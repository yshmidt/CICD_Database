--modify by Shripati for custname, IsAdd, IsEdit  on 7/25/2018
CREATE PROCEDURE [dbo].[Bom_Alt_View] @gUniq_key char(10)=' ', @sUniq_key char(10)=' '
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

  SELECT Bom_alt.*, Inventor.part_class, Inventor.part_type,Inventor.custno, Inventor.part_no, 
	Inventor.revision, Inventor.prod_id, Inventor.custpartno, Inventor.custrev, Inventor.descript,
	-- 09/11/2018 Shripati U change  part_sourc to  Part_sourc
	Inventor.Part_sourc, Inventor.matltype,
	-- 08/18/2018 Shripati U Extra added fields :- PartNoWithRev, CustPartNoWithRev, IsAdd, IsEdit, CUSTNAME and PartNoWithRev and added join for CUSTNAME
	CASE COALESCE(NULLIF(Inventor.REVISION,''), '')
	WHEN '' THEN  LTRIM(RTRIM(Inventor.PART_NO)) 
	ELSE LTRIM(RTRIM(Inventor.PART_NO)) + '/' + Inventor.REVISION 
	END AS PartNoWithRev,
	LTRIM(RTRIM(Inventor.part_class)) + '/' + LTRIM(RTRIM(Inventor.part_type)) +'/'+LTRIM(RTRIM(Inventor.descript)) AS [Description],
	CASE COALESCE(NULLIF(Inventor.CUSTREV,''), '')
	WHEN '' THEN  LTRIM(RTRIM(Inventor.CUSTPARTNO)) 
	ELSE LTRIM(RTRIM(Inventor.CUSTPARTNO)) + '/' + Inventor.CUSTREV 
	END AS CustPartNoWithRev,
	CUSTOMER.CUSTNAME, CAST(0 AS BIT) AS IsAdd, CAST(0 AS BIT) AS IsEdit 
 FROM Bom_alt, Inventor
 LEFT JOIN customer ON Inventor.CUSTNO = CUSTOMER.CUSTNO
 WHERE Inventor.Uniq_key = Bom_alt.Uniq_key
 AND (Bom_alt.Alt_for = @sUniq_Key
 AND Bom_alt.Bomparent = @gUniq_key)

END