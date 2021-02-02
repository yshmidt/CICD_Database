-- =============================================
-- Author:		David Sharp
-- Create date: 10/18/2012
-- Description:	gets a list of Open orders for receiving
-- =============================================
CREATE PROCEDURE bcPOReceivingPODetailsGet
	-- Add the parameters for the stored procedure here
	@ponum varchar(15)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @ponum = RIGHT('000000000000000' + @ponum,15)
    -- Insert statements for procedure here
	SELECT it.PONUM,it.ITEMNO,it.ORD_QTY-it.ACPT_QTY BALANCE,it.PARTMFGR,it.MFGR_PT_NO,i.PART_NO,i.REVISION,i.DESCRIPT,it.OVERAGE,sc.SCHD_DATE,sc.REQ_DATE,sc.BALANCE,sc.SCHDNOTES,
		sc.REQUESTTP,sc.REQUESTOR,w.WAREHOUSE,sc.LOCATION,sc.WOPRJNUMBER,sc.SCHD_DATE,sc.REQ_DATE,sc.ORIGCOMMITDT,it.NOTE1 PONOTE,it.FIRSTARTICLE,it.INSPEXCEPT,it.INSPEXCEPTION,
		it.INSPEXCINIT,it.INSPEXCDT,it.INSPECTIONOTE,it.INSPEXCDOC,i.MATLTYPE,p.AUTODT,p.FGIEXPDAYS,i.SERIALYES,i.CERT_REQ,i.CERT_TYPE
		FROM POITEMS it INNER JOIN POITSCHD sc ON it.UNIQLNNO=sc.UNIQLNNO
			INNER JOIN INVENTOR i ON i.uniq_key=it.uniq_key
			INNER JOIN WAREHOUS w ON w.UNIQWH=sc.UNIQWH
			INNER JOIN PARTTYPE p ON p.PART_CLASS=i.PART_CLASS AND p.PART_TYPE=i.PART_TYPE
		WHERE it.LCANCEL=0 AND sc.BALANCE>0 AND it.PONUM=@ponum
END