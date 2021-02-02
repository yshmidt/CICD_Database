CREATE PROC [dbo].[Bom_hdr_view] @gUniq_key AS char(10) = ''
AS
SELECT Uniq_key, Part_class, Part_type, Part_no, Revision, Prod_id, Descript, Bom_status, Bom_note, 
	Bom_lastdt, Part_sourc, Status, U_of_meas, Bomcustno, Perpanel, Stdbldqty, Usesetscrp, Bomlock, 
	Bomlockinit, Bomlockdt, Bomlastinit, Matltype, Bominactdt, Bominactinit
	FROM Inventor
	WHERE Uniq_key = @gUniq_key


