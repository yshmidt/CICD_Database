-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <06/03/2011>
-- Description:	<Micssys Some Information>
-- 06/04/15 YS added uniquerec
-- =============================================
CREATE PROCEDURE [dbo].[MicssysSumInfoView]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT Micssys.Field145,MICSSYS.FIELD146,MICSSYS.Field148,MICSSYS.TREESET,
		MICSSYS.LIC_NAME,MICSSYS.LIC_DATE,MICSSYS.LADDRESS1,
		MICSSYS.LADDRESS2,MICSSYS.LIC_NO,
		MICSSYS.LCITY,MICSSYS.LCOUNTRY,MICSSYS.LSTATE,LZIP,LPHONE,LFAX ,
		MICSSYS.farrago,Micssys.Crony,Micssys.M8,Micssys.forestall,
		Micssys.CVE,Micssys.LVE ,Field9,UniqueRec
		FROM Micssys
END