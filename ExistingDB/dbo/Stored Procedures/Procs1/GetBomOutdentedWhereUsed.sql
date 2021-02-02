-- =============================================
-- Author:	Shivshankar P
-- Create date:  10/24/2017
-- Description:	This was created for Bill Of Material Outdented Where Used (bomrpt7)
-- 10/24/2017 Shivshankar P :  Added columns and removed filter by 'Phantom'
-- 02/13/2018 Shivshankar P :  Get data against the Uniq_key
-- 06/18/2018 Sachin B : Get Qty,Bomparent Column in Select
-- 16/11/2018 Rajendra K : Added item_no in select list 
-- GetBomOutdentedWhereUsed '_1LR0NALAS'
-- =============================================
CREATE PROC [dbo].[GetBomOutdentedWhereUsed]
--declare 
 @lcuniq_key CHAR(10) =''
,@customerStatus VARCHAR (20) = 'All'	--This is used to pass the customer status to the [aspmnxSP_GetCustomers4User] below.
,@userId UNIQUEIDENTIFIER= null

AS 
BEGIN 

	SET NOCOUNT ON;
	-- 06/18/2018 Sachin B : Get Qty,Bomparent Column in Select
	;WITH BomOutdented
	AS
	(
			SELECT	m.Part_no,m.Revision,m.PART_CLASS +  '/' +  m.PART_TYPE +  '/' +LEFT(m.Descript,19) AS Descript,m.PART_SOURC,Bom_det.BomParent,m.Bomcustno,
					m.BOM_STATUS  AS Bom_Status,Bom_det.TERM_DT AS Term_Dt,Bom_det.EFF_DT AS Eff_Dt,m.[STATUS] AS [Status],Qty,UniqBomNo
					,Bom_det.ITEM_NO AS Item_no -- 16/11/2018 Rajendra K : Added item_no in select list			   
			FROM	Bom_det 
			INNER JOIN Inventor M ON Bom_det.Bomparent = M.Uniq_key
			LEFT JOIN DEPTS ON bom_det.DEPT_ID = depts.DEPT_ID 
			WHERE Bom_det.Uniq_key = @lcUniq_key

		UNION ALL

			SELECT M2.part_no,M2.Revision,m2.PART_CLASS +  '/' +m2.PART_TYPE +  '/' +LEFT(M2.Descript,19) AS Descript,m2.PART_SOURC,B2.BomParent, m2.BOMCUSTNO,
					m2.BOM_STATUS  AS Bom_Status,B2.TERM_DT AS Term_Dt,B2.EFF_DT AS Eff_Dt,m2.[STATUS] AS [Status],B2.Qty,B2.UniqBomNo,
				   B2.ITEM_NO AS Item_no -- 16/11/2018 Rajendra K : Added item_no in select list
			FROM	BomOutdented AS P 
			INNER JOIN BOM_DET B2 ON P.BomParent =B2.Uniq_key AND B2.UNIQ_KEY =@lcuniq_key -- 02/13/2018 Shivshankar P :  Get data against the Uniq_key
			INNER JOIN INVENTOR M2 ON B2.BOMPARENT =M2.UNIQ_KEY
			INNER JOIN DEPTS d2 ON b2.DEPT_ID = d2.DEPT_ID  
			WHERE	(P.PART_SOURC='MAKE')
	)
	-- 06/18/2018 Sachin B : Get Qty,Bomparent Column in Select
	SELECT CASE COALESCE(NULLIF(Revision,''), '')
	WHEN '' THEN  LTRIM(RTRIM(Part_no)) 
	ELSE LTRIM(RTRIM(Part_no)) + '/' + Revision 
	END AS Part_no,
	Descript,custname,ISNULL(c.custname,SPACE(35)) AS custname,	Bom_Status,Term_Dt,Eff_Dt,E.[Status],Qty,Bomparent,UniqBomNo 
	,Item_no -- 16/11/2018 Rajendra K : Added item_no in select list 
	FROM BomOutdented E 
	LEFT OUTER JOIN Customer C ON e.bomcustno=c.custno
	GROUP BY Part_no,Revision,Descript,custname , Bom_Status,Term_Dt,Eff_Dt,E.[Status],Qty,Bomparent,UniqBomNo,Item_no
	
END
