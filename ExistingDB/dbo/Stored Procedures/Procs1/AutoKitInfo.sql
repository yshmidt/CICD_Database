
-- =============================================
-- Author:		Mahesh B
-- Create date: 1/23/2019
-- Description:	Get the data for Auto-kit process with constraints.   
-- 09/23/2019 Rajendra K : Added parameter @allowAutokit to ignore AllowAutokit
-- Exec AutoKitInfo '0009856123',1
-- =============================================
CREATE PROCEDURE AutoKitInfo 
	@woNumber AS CHAR(10),
	@allowAutokit AS BIT = 1-- 09/23/2019 Rajendra K : Added parameter @allowAutokit to ignore AllowAutokit
AS
BEGIN

	 SET NOCOUNT ON;

	 SELECT I.uniq_key AS UniqKey,
	        K.KASEQNUM, 
            k.WONO AS WorkOrder, 
		    I.useipkey AS UseIpKey,  
            I.SERIALYES AS Serialyes, 
			ISNULL(PT.LOTDETAIL,0) AS IsLotted, 
			K.ShortQty
	 FROM  KAMAIN K 
	 INNER JOIN INVENTOR I ON K.UNIQ_KEY=I.UNIQ_KEY AND K.WONO= @woNumber AND K.IGNOREKIT = 0  AND  K.SHORTQTY > 0
     INNER JOIN PartClass pc on i.PART_CLASS = pc.part_class 
	 AND ((@allowAutokit = 1 AND pc.AllowAutokit = 1) OR (@allowAutokit = 0 AND 1=1))-- 09/23/2019 Rajendra K : Added parameter @allowAutokit to ignore AllowAutokit
	 LEFT JOIN PARTTYPE PT ON I.PART_CLASS = PT.PART_CLASS AND I.PART_TYPE = PT.PART_TYPE    
END