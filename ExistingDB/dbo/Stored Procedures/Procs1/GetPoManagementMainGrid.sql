-- =============================================  
-- Author:Satish B  
-- Create date: 08/21/2017  
-- Description : get Po Management main grid data  
-- Modified : 10/05/2017 Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search  
--          : 10/05/2017 Satish B : Change the INNER join to LEFT join  
--          : 10/05/2017 Satish B : Added join of aspnet_Profile  
--          : 10/05/2017 Satish B : Change the INNER join to LEFT join  
--          : 11/07/2017 Satish B : Select I_LINK from POMAIN table  
--          : 12/19/2017 Satish B : Select Fchist_key and funcFcUsed_uniq and UNIQSUPNO from POMAIN  
--          : 1/08/2018 Satish B : Change filter from poitem.PART_TYPE='MRO' to poitem.POITTYPE='MRO'  
--          : 1/12/2018 Satish B : Removed the filter of PO Status  
--          : 07/12/2018 YS increase size of the supname column from 30 to 50  
--   : 07/18/2018 Satish B : Select Terms field from pomain  
--   : 08/03/2018 Satish B : Select Fob,ShipVia,ShipCharge field from pomain  
--   : 10/05/2018 Satish B : Select IsApproveProcess field from pomain  
--   : 11/16/2018 Satish B :Added Parameter Status to implement filter search against status  
--   : 11/16/2018 Satish B: Added extra filter @status  
--   : 11/19/2018 Satish B : Added filter to get the po result against selected status  
--   : 11/19/2018 : Satish B : Added filter to get Part_No against selected status  
--   : 11/19/2018 : Satish B : Added filter to get Mro_Part_No against selected status  
--   : 11/19/2018 : Satish B : Added filter to get Mfgr_Part_No against selected status  
--   : 12/12/2018 : Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search  
--   : 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
--   : 05/20/2019 : Satish B : Selecting  Username instead of initials  
--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
--   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
-- exec GetPoManagementMainGrid 'T00000000001861','','','',' ','',1,500,0  
-- =============================================  
CREATE PROCEDURE GetPoManagementMainGrid  
 @poNumber char(15)='',  
 @partNumber char(10) ='',  
 -- 07/12/2018 YS increase size of the supname column from 30 to 50  
 @supplier char(50) ='',  
 @mfgrPtNo char(30) ='',  
 @mroPtNo char(30) ='',  
 @buyer char(10) ='',  
 --11/16/2018 Satish B :Added Parameter Status to implement filter search against status  
 @status char(10) ='',  
 @startRecord int =1,  
    @endRecord int =10,   
 @outTotalNumberOfRecord int OUTPUT,
 @usedId  UNIQUEIDENTIFIER = NULL--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
 AS  
 BEGIN  
  SET NOCOUNT ON 
  --   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
   DECLARE @tSupplier Table (UniqSupno char(10),SUPNAME char(50),R_LINK char(10),C_LINK char(10),Supid char(10),Fcused_Uniq char(10),Terms char(15))  
   INSERT INTO @tSupplier EXECUTE GetAspMnxUserSuppliers @usedId
  
 --11/16/2018 Satish B: Added extra filter @status  
 IF(ISNULL(@partNumber,'') ='' AND  ISNULL(@mfgrPtNo,'') ='' AND  ISNULL(@mroPtNo ,'') ='' AND ISNULL(@status,'')<>'')  
   BEGIN  
    SELECT COUNT(pomain.PONUM) AS RowCnt -- Get total counts   
    INTO #tempPoMainGidData  
    FROM POMAIN pomain  
    INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	--INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	--   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	  INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO 
    --10/05/2017 Satish B : Change the INNER join to LEFT join  
    --LEFT JOIN aspnet_Profiles aspnetProf ON aspnetProf.UserId= pomain.aspnetBuyer  
    LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    --10/05/2017 Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search  
    --WHERE ((@poNumber IS NULL OR @poNumber='') OR (pomain.PONUM =@poNumber))  
    --   AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME =@supplier))  
    --   AND ((@buyer IS NULL OR @buyer='') OR (aspnetProf.Initials =@buyer))  
--   : 12/12/2018 : Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search    
    WHERE  ((ISNULL(@poNumber ,'') ='' AND 1=1)  OR (ISNULL(@poNumber ,'')  <> '' and  pomain.PONUM =@poNumber))   
    AND ((ISNULL(@supplier ,'') ='' AND 1=1)  OR (ISNULL(@supplier ,'')  <> '' and supinfo.SUPNAME =@supplier))   
    AND ((ISNULL(@buyer ,'') ='' AND 1=1)  OR (ISNULL(@buyer ,'')  <> '' and aspnetUsers.UserName =@buyer))   
  
     --11/19/2018 Satish B : Added filter to get the po result against selected status  
     AND  
      ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
       (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
       (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
       (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))   
              
    SELECT pomain.PONUM AS PONumber  
     ,pomain.PODATE AS PODate  
     ,pomain.POSTATUS AS Status  
     -- 05/20/2019 : Satish B : Selecting  Username instead of initials  
     --,aspnetProf.Initials As Buyer  
     ,aspnetUsers.UserName As Buyer  
     ,supinfo.SUPNAME AS Supplier  
     ,pomain.CONUM AS CONum  
     ,pomain.POUNIQUE AS PoUnique  
     ,IsFcInstall=dbo.fn_IsFCInstalled()  
     --11/07/2017 Satish B : Select I_LINK from POMAIN table  
     ,pomain.I_LINK AS ILink  
     --12/19/2017 Satish B : Select Fchist_key and funcFcUsed_uniq and UNIQSUPNO from POMAIN  
     ,ISNULL(pomain.Fchist_key,'') AS TrFcHistKey  
     ,ISNULL(pomain.funcFcUsed_uniq,'') AS FuncFcHistKey  
     ,pomain.UNIQSUPNO  
     --07/18/2018 Satish B : Select Terms field from pomain  
     ,pomain.Terms  
      --08/03/2018 Satish B : Select Fob,ShipVia,ShipCharge field from pomain  
     ,pomain.Fob  
     ,pomain.ShipVia  
     ,pomain.ShipCharge  
     --10/05/2018 Satish B : Select IsApproveProcess field from pomain  
     ,pomain.IsApproveProcess  
    FROM POMAIN pomain  
    INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	--INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	--   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO 
    --10/05/2017 Satish B : Change the INNER join to LEFT join  
    --LEFT JOIN aspnet_Profiles aspnetProf ON aspnetProf.UserId= pomain.aspnetBuyer  
    -- 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
    LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
     --10/05/2017 Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search  
    --WHERE ((@poNumber IS NULL OR @poNumber='') AND  (@supplier IS NULL OR @supplier='') AND (@buyer IS NULL OR @buyer='') OR   
    -- (pomain.POSTATUS <> 'CLOSED' AND pomain.POSTATUS <> 'CANCEL' AND pomain.POSTATUS <> 'ARCHIVED'))  
    -- OR (((@poNumber IS NULL OR @poNumber='') OR (pomain.PONUM =@poNumber))  
    --   AND ((@supplier IS NULL OR @supplier='') OR (supinfo.SUPNAME =@supplier))  
    --   AND ((@buyer IS NULL OR @buyer='') OR (aspnetProf.Initials =@buyer)))  
       
     WHERE  
  --12/12/2018 : Satish B : Change the WHERE condition to avoid record with status CLOSED,CANCEL and ARCHIVED initially and display record with all status on search  
      ((ISNULL(@poNumber ,'') ='' AND 1=1)  OR (ISNULL(@poNumber ,'')  <> '' and  pomain.PONUM =@poNumber))   
    AND ((ISNULL(@supplier ,'') ='' AND 1=1)  OR (ISNULL(@supplier ,'')  <> '' and supinfo.SUPNAME =@supplier))   
    AND ((ISNULL(@buyer ,'') ='' AND 1=1)  OR (ISNULL(@buyer ,'')  <> '' and aspnetUsers.UserName =@buyer))   
     AND  
      ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
       (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
       (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
       (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))  
        
    ORDER BY pomain.PODATE DESC   
    OFFSET(@startRecord-1) ROWS  
    FETCH NEXT @EndRecord ROWS ONLY;  
  
    SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoMainGidData) -- Set total count to Out parameter   
   END  
  ELSE IF(@partNumber <>'')  
   BEGIN  
    SELECT COUNT(pomain.PONUM) AS RowCnt -- Get total counts   
    INTO #tempPartNumberData  
    FROM POMAIN pomain  
     INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO
	 --   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	 --INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId 
	 INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO 
     INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
     INNER JOIN INVENTOR inventor ON poitem.UNIQ_KEY = inventor.UNIQ_KEY  
     --10/05/2017 Satish B : Added join of aspnet_Profile  
     LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE inventor.PART_NO LIKE '%'+RTRIM(@partNumber)+'%'  
     --11/19/2018 : Satish B : Added filter to get Part_No against selected status  
    AND   
     ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
      (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
      (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
      (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))  
     
    
    SELECT DISTINCT CAST(dbo.fremoveLeadingZeros(pomain.PONUM) AS VARCHAR(MAX)) AS PONumber  
     ,pomain.PODATE AS PODate  
     ,pomain.POSTATUS AS Status  
     -- 05/20/2019 : Satish B : Selecting  Username instead of initials  
     --,aspnetProf.Initials As Buyer  
     ,aspnetUsers.UserName As Buyer  
     ,supinfo.SUPNAME AS Supplier  
     ,pomain.CONUM AS CONum  
     ,pomain.POUNIQUE AS PoUnique  
     ,IsFcInstall=dbo.fn_IsFCInstalled()  
     --11/07/2017 Satish B : Select I_LINK from POMAIN table  
     ,pomain.I_LINK AS ILink  
     --12/19/2017 Satish B : Select Fchist_key and funcFcUsed_uniq and UNIQSUPNO from POMAIN  
     ,ISNULL(pomain.Fchist_key,'') AS TrFcHistKey  
     ,ISNULL(pomain.funcFcUsed_uniq,'') AS FuncFcHistKey  
     ,pomain.UNIQSUPNO  
     --07/18/2018 Satish B : Select Terms field from pomain  
     ,pomain.Terms  
      --08/03/2018 Satish B : Select Fob,ShipVia,ShipCharge field from pomain  
     ,pomain.Fob  
     ,pomain.ShipVia  
     ,pomain.ShipCharge  
     --10/05/2018 Satish B : Select IsApproveProcess field from pomain  
     ,pomain.IsApproveProcess  
    FROM POMAIN pomain  
     INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	 --   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	 --INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	 --   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	 INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO   
     INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
     INNER JOIN INVENTOR inventor ON poitem.UNIQ_KEY = inventor.UNIQ_KEY  
     --10/05/2017 Satish B : Change the INNER join to LEFT join  
     --LEFT JOIN aspnet_Profiles aspnetProf ON aspnetProf.UserId= pomain.aspnetBuyer  
      -- 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
     LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE inventor.PART_NO LIKE '%'+RTRIM(@partNumber)+'%'  
    --11/19/2018 : Satish B : Added filter to get Part_No against selected status  
   AND   
    ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
     (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
     (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
     (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))  
     
    ORDER BY pomain.PODATE DESC   
    OFFSET(@startRecord-1) ROWS  
    FETCH NEXT @EndRecord ROWS ONLY;  
  
    SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPartNumberData) -- Set total count to Out parameter   
   END  
  ELSE IF(@mroPtNo <>'')  
   BEGIN  
   SELECT COUNT(pomain.PONUM) AS RowCnt -- Get total counts   
    INTO #tempPoMainMroData  
    FROM POMAIN pomain  
     INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO
	 --   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers 
	 --INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	 --   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	 INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO  
     INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
     --10/05/2017 Satish B : Change the INNER join to LEFT join  
      -- 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
     LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE poitem.PART_NO LIKE '%'+RTRIM(@mroPtNo)+'%'   
    --1/08/2018 Satish B : Change filter from poitem.PART_TYPE='MRO' to poitem.POITTYPE='MRO'  
          AND poitem.POITTYPE='MRO' --AND poitem.PART_TYPE='MRO'   
       --11/19/2018 : Satish B : Added filter to get Mro_Part_No against selected status  
    AND  
     ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
      (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
      (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
      (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))  
    
    SELECT CAST(dbo.fremoveLeadingZeros(pomain.PONUM) AS VARCHAR(MAX)) AS PONumber  
     ,pomain.PODATE AS PODate  
     ,pomain.POSTATUS AS Status  
     -- 05/20/2019 : Satish B : Selecting  Username instead of initials  
     --,aspnetProf.Initials As Buyer  
     ,aspnetUsers.UserName As Buyer  
     ,supinfo.SUPNAME AS Supplier  
     ,pomain.CONUM AS CONum  
     ,pomain.POUNIQUE AS PoUnique  
     ,IsFcInstall=dbo.fn_IsFCInstalled()  
     --11/07/2017 Satish B : Select I_LINK from POMAIN table  
     ,pomain.I_LINK AS ILink  
     --12/19/2017 Satish B : Select Fchist_key and funcFcUsed_uniq fand UNIQSUPNO rom POMAIN  
     ,ISNULL(pomain.Fchist_key,'') AS TrFcHistKey  
     ,ISNULL(pomain.funcFcUsed_uniq,'') AS FuncFcHistKey  
     ,pomain.UNIQSUPNO  
     --07/18/2018 Satish B : Select Terms field from pomain  
     ,pomain.Terms  
      --08/03/2018 Satish B : Select Fob,ShipVia,ShipCharge field from pomain  
     ,pomain.Fob  
     ,pomain.ShipVia  
     ,pomain.ShipCharge  
     --10/05/2018 Satish B : Select IsApproveProcess field from pomain  
     ,pomain.IsApproveProcess  
    FROM POMAIN pomain  
     INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	 --   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	 --INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	 --   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	 INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO   
     INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
     --10/05/2017 Satish B : Change the INNER join to LEFT join  
     --LEFT JOIN aspnet_Profiles aspnetProf ON aspnetProf.UserId= pomain.aspnetBuyer  
      -- 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
     LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE (poitem.PART_NO LIKE '%'+RTRIM(@mroPtNo)+'%'   
    --1/08/2018 Satish B : Change filter from poitem.PART_TYPE='MRO' to poitem.POITTYPE='MRO'  
          AND poitem.POITTYPE='MRO') --poitem.PART_TYPE='MRO'  
       --11/19/2018 : Satish B : Added filter to get Mro_Part_No against selected status  
    AND  
     ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
      (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
      (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
      (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))   
     
    ORDER BY pomain.PODATE DESC   
    OFFSET(@startRecord-1) ROWS  
    FETCH NEXT @EndRecord ROWS ONLY;  
  
    SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoMainMroData) -- Set total count to Out parameter   
   END  
  ELSE IF(@mfgrPtNo <>'')  
   BEGIN  
   SELECT COUNT(pomain.PONUM) AS RowCnt -- Get total counts   
    INTO #tempPoMainMfgrData  
    FROM POMAIN pomain  
    INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	--INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId 
	--   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers 
	INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO 
    INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
    INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poitem.UNIQMFGRHD  
    INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId  
    --10/05/2017 Satish B : Change the INNER join to LEFT join  
    LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE mfgrmaster.mfgr_pt_no LIKE '%'+RTRIM(@mfgrPtNo)+'%'  
    --11/19/2018 : Satish B : Added filter to get Mfgr_Part_No against selected status  
    AND  
     ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
      (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
      (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
      (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))   
    
    SELECT CAST(dbo.fremoveLeadingZeros(pomain.PONUM) AS VARCHAR(MAX)) AS PONumber  
     ,pomain.PODATE AS PODate  
     ,pomain.POSTATUS AS Status  
     -- 05/20/2019 : Satish B : Selecting  Username instead of initials  
     --,aspnetProf.Initials As Buyer  
     ,aspnetUsers.UserName As Buyer  
     ,supinfo.SUPNAME AS Supplier  
     ,pomain.CONUM AS CONum  
     ,pomain.POUNIQUE AS PoUnique  
     ,IsFcInstall=dbo.fn_IsFCInstalled()  
     --11/07/2017 Satish B : Select I_LINK from POMAIN table  
     ,pomain.I_LINK AS ILink  
    --12/19/2017 Satish B : Select Fchist_key and funcFcUsed_uniq and UNIQSUPNO from POMAIN  
     ,ISNULL(pomain.Fchist_key,'') AS TrFcHistKey  
     ,ISNULL(pomain.funcFcUsed_uniq,'') AS FuncFcHistKey  
     ,pomain.UNIQSUPNO  
     --07/18/2018 Satish B : Select Terms field from pomain  
     ,pomain.Terms  
      --08/03/2018 Satish B : Select Fob,ShipVia,ShipCharge field from pomain  
     ,pomain.Fob  
     ,pomain.ShipVia  
     ,pomain.ShipCharge  
     --10/05/2018 Satish B : Select IsApproveProcess field from pomain  
     ,pomain.IsApproveProcess  
    FROM POMAIN pomain  
    INNER JOIN SUPINFO supinfo ON supinfo.UNIQSUPNO=pomain.UNIQSUPNO 
	--   : 08/24/2020 : Rajendra K : Added @usedId parameter and join with aspmnx_UserSuppliers
	--INNER JOIN aspmnx_UserSuppliers aspsup ON aspsup.FkUniqSupNo = supinfo.UNIQSUPNO AND FkUserId = @usedId
	--   : 08/27/2020 : Rajendra K : Removed join with aspmnx_UserSuppliers and added @tSupplier table and join to get supplier from GetAspMnxUserSuppliers
	INNER JOIN @tSupplier aspsup ON aspsup.UNIQSUPNO = supinfo.UNIQSUPNO 
    INNER JOIN POITEMS  poitem ON pomain.PONUM = poitem.PONUM  
    INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poitem.UNIQMFGRHD  
    INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId  
    --10/05/2017 Satish B : Change the INNER join to LEFT join  
     -- 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of initials  
    LEFT JOIN aspnet_Users aspnetUsers ON aspnetUsers.UserId= pomain.aspnetBuyer  
    WHERE (mfgrmaster.mfgr_pt_no LIKE '%'+RTRIM(@mfgrPtNo)+'%')   
    --11/19/2018 : Satish B : Added filter to get Mfgr_Part_No against selected status  
    AND  
     ((@status= 1 AND pomain.POSTATUS IN ('NEW','EDITING')) OR  
      (@status= 2 AND pomain.POSTATUS IN ('OPEN')) OR  
      (@status= 3 AND pomain.POSTATUS IN ('OPEN','NEW','EDITING'))OR  
      (@status= 4 AND pomain.POSTATUS IN ('CLOSED','CANCEL')))  
     
    ORDER BY pomain.PODATE DESC   
    OFFSET(@startRecord-1) ROWS  
    FETCH NEXT @EndRecord ROWS ONLY;  
  
    SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoMainMfgrData) -- Set total count to Out parameter   
   END  
END                       