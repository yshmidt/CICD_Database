-- =============================================
-- Author:		Shivshankar Patil
-- Create date: <05/10/16>
-- Description:	<Get part number details used in kitting related to work order number> 
-- Modification
   -- 02/23/2017 Rajendra K : Get ITAR
   -- 07/10/2017 Rajendra K : Added Columns k.DEPT_ID and k.BOMPARENT in select and Group by list(Used for Update kit) 
   -- 08/11/2017 Rajendra K : Added condition to get valid records from InvtMfgr table
   -- 10/31/2017 Rajendra K : Removed condition 'invtMf.QTY_OH > 0' to get all manufacturers  
   -- 12/22/2017 Rajendra K : applied Naming conventions 
-- Exce GetKitMainGridData '0000000200'
-- =============================================
CREATE PROC [dbo].[GetKitMainGridData] 
@woNumber AS CHAR(10)
AS
BEGIN
	SET NOCOUNT ON;
		SELECT  K.DEPT_ID  --07/10/2017 Rajendra K : Added Columns k.DEPT_ID and k.BOMPARENT in select and Group by list(Used for Update kit) 
			   ,K.BOMPARENT AS Bomparent
			   ,K.Kaseqnum
			   ,I.PART_NO 
			   ,I.PART_CLASS 
			   ,I.PART_TYPE
			   ,I.DESCRIPT
			   ,K.allocatedQty
			   ,K.ACT_QTY
			   ,K.SHORTQTY
			   ,I.uniq_key 
			   ,K.IGNOREKIT AS IsChecked
			   ,(K.SHORTQTY+(K.ACT_QTY+K.allocatedQty)) AS Required
			   ,(SUM(ISNULL(InvtMf.QTY_OH, 0))-SUM(ISNULL(InvtMf.RESERVED, 0))) + SUM(ISNULL(Intres.QTYALLOC, 0)) AS AvailableQty
			   ,I.ITAR --02/23/17 Rajendra K : Added to display column in KitSummary grid
		FROM INVENTOR I
			 RIGHT JOIN KAMAIN K ON K.UNIQ_KEY=I.UNIQ_KEY 
			 INNER JOIN WOENTRY W ON W.WONO=K.WONO
			 LEFT  JOIN INVTMFGR InvtMf ON InvtMf.UNIQ_KEY=K.UNIQ_KEY 
			 --AND invtMf.QTY_OH > 0 --10/31/2017 Rajendra K : Removed this condition to get all manufacturers  
			 AND InvtMf.NETABLE = 1 AND InvtMf.InStore = 0 AND InvtMf.IS_DELETED = 0 -- 08/11/2017 Rajendra K : Added this condition to get valid records --from InvtMfgr table
			 LEFT  JOIN INVT_RES Intres ON Intres.WONO = k.WONO
		WHERE k.WONO= @woNumber
		GROUP BY K.KASEQNUM 
				,I.PART_NO
				,I.PART_CLASS
				,I.PART_TYPE
				,I.DESCRIPT
				,K.allocatedQty
				,K.ACT_QTY
				,K.SHORTQTY
			    ,I.uniq_key 
				,K.IGNOREKIT
				,I.ITAR
				,K.BOMPARENT --07/10/2017 Rajendra K : Added Columns k.DEPT_ID and k.BOMPARENT in select and Group by list(Used for Update kit)
				,K.DEPT_ID
END