CREATE PROC [dbo].[EcmainView] @gUniqEcNo AS char(10) = ' '
AS
SELECT Econo, Uniqecno, Ecmain.Uniq_key, Changetype, Ecstatus, Purpose, Ecdescript, Part_class, Part_type, 
	Part_no, Revision, Descript, Ounitcost, Nunitcost, Fgibal, Fgiupdate, Ecmain.Bomcustno, Expdate, 
	Wipupdate, Totmatl, Totlabor, Totmisc, Netmatlchg, Totrwkmatl, Totrwklab, Totrwkmisc, Rwkmatlea,
	Rwkmatlqty, Rwklabea, Rwklabqty, Totrwkcost, Chgstdcost, Newstdcost, Chglbcost, Newlbcost,
	Chgprodno, Newprodno, Chgrev, Newrev, Newserno, Copyphant, Copyabc, 
	Copyordpol, Copyleadtm, Copynote, Copyspec, Copywkctrs, Copywolist, Copytool, Copyouts, Copydocs, 
	Copyinst, Copycklist, Copyssno, Chgdescr, Newdescr, Laborcost, SerialYes, Chgserno, 
	Engineer, Copybmnote, Copyeffdts, Copyrefdes, Copyaltpts, Part_sourc, Opendate, Updateddt, 
	Ecoref, Chgcust, Newcustno, Matl_cost, Totrwkwcst, Totrwkfcst, Newmatlcst, Custname, Ecmain.Bom_note, 
	Ecofile, Ecosource, Effectivedt, Ecolock, Ecolockint, Ecolockdt, Savedt, Saveint, Origindoc,
	Updsoprice, Copyothprc, lCopySupplier, lUpdateMPN
 FROM Ecmain INNER JOIN Inventor
    LEFT OUTER JOIN Customer 
	ON Inventor.Bomcustno = Customer.Custno
	ON Ecmain.Uniq_key = Inventor.Uniq_key
	WHERE Ecmain.Uniqecno = @gUniqEcNo







