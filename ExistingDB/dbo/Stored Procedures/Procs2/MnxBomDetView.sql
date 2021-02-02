CREATE PROC [dbo].MnxBomDetView 
@lcBomParent AS char(10) = ' ', @UserId uniqueidentifier=NULL, @gridId varchar(50) = null
	
	-- list of parameters:
	-- 1. @lcBomParent - Top level BOM Unique key
	-- 2. @UserId - for now is optional will be ignored if null. Will be used by WEB fron to identify if the user has rights to see the BOM.
	-- 3. @gridId - optional web application is using it to customize grid display
AS
SELECT Item_no, I.Part_sourc,CASE WHEN I.part_sourc='CONSG' THEN I.Custpartno ELSE I.Part_no END  AS ViewPartNo,
CASE WHEN I.part_sourc='CONSG' THEN I.Custrev ELSE I.Revision END AS ViewRev,
I.Part_class, I.Part_type, I.Descript, Qty, I.Part_no, I.Revision, I.CustPartno, I.Custrev, BomParent, Bom_det.Uniq_key,
Dept_id, Item_note, Offset, Term_dt, Eff_dt, Used_inKit,I.Custno, I.Inv_note, I.U_of_meas, I.Scrap, I.Setupscrap,
UniqBomno, I.Phant_Make, I.StdCost, I.Make_buy, I.Status ,
isnull(CustI.CUSTPARTNO,space(25)) as CustomerPartno,isnull(CustI.CUSTREV,SPACE(8)) as CustomerRev,ISNULL(CustI.UNIQ_KEY,SPACE(10)) as CustUniqKey  
	FROM Bom_det INNER JOIN Inventor I ON Bom_det.Uniq_key = I.Uniq_key
	INNER JOIN INVENTOR M ON Bom_det.BOMPARENT =M.UNIQ_KEY 
	LEFT OUTER JOIN INVENTOR CustI ON Bom_det.UNIQ_KEY =CustI.INT_UNIQ and M.BOMCUSTNO=CustI.CUSTNO  
	WHERE Bom_det.BomParent = @lcBomParent
	ORDER BY Item_no
IF NOT @gridId IS NULL
		EXEC MnxUserGetGridConfig @userId, @gridId