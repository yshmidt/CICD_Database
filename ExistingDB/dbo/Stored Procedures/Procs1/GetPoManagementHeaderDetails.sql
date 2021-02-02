-- =============================================
-- Author:Satish B
-- Create date: 08/21/2017
-- Description : get Po Management main header details
-- Modified : 10/09/2017 Satish B : Check null for FH.Askprice
--          : 10/11/2017 Satish B : Replace aspnet_Profile.INNER JOIN With aspnet_Profile.LEFT JOIN
--          : 11/07/2017 Satish B : Comment selection of pomain.CONFIRMBY and select pomain.CONFNAME
--          : 11/07/2017 Satish B : Select CONFNAME from CCONTACT
--          : 11/07/2017 Satish B : Added join of CCONTACT table with pomain
--          : 12/01/2017 Satish B : CAST  POTOTAL and POTAX as varchar
--          : 12/04/2017 Satish B : Select SHIPCHG ,IS_SCTAX and SCTAXPCT,UNIQSUPNO,R_LINK,C_LINK,B_LINK,SUPID,LFREIGHTINCLUDE  columns
--          : 12/28/2017 Satish B : Remove white space
--          : 01/04/2018 Satish B : Change selection of FUNCTIONAL currency from F.Currency To Func.Currency
--          : 01/04/2018 Satish B : Added extra join of FCUSED to select functional currency
--			: 07/12/2018 Satish B : Remove middle name from conf name
--			: 09/06/2018 Satish B : Select IsApproveProcess from POMAIN table
--			: 05/20/2019 Satish B : Replace join aspnet_Profiles with aspnet_Users to display Username instead of User initials
-- exec GetPoManagementHeaderDetails 'T00000000001859'
-- : 12/10/2018 Satish B: added "aspnetProf.UserId" field 
-- : 12/13/2018 Satish B: Increased the POTOTAL and POTAX as varchar for casting
-- =============================================
CREATE PROCEDURE GetPoManagementHeaderDetails
	@poNumber char(15) =1
 AS
 BEGIN
	 SET NOCOUNT ON	 
	 SELECT 
	 --11/07/2017 Satish B : Comment selection of pomain.CONFIRMBY and select pomain.CONFNAME
	   --pomain.CONFIRMBY,
	 	 supinfo.STATUS
		,supinfo.SUPNAME
		,pomain.PONUM
		,pomain.PODATE
		,pomain.CONUM
		,pomain.POSTATUS
		,pomain.POPRIORITY
		--12/01/2017 Satish B : CAST  POTOTAL and POTAX as varchar
		--12/13/2018 Increased the POTOTAL and POTAX as varchar for casting
		,CAST(pomain.POTOTAL AS VARCHAR(50)) AS POTOTAL
		,CAST(pomain.POTAX AS VARCHAR(50)) AS POTAX
		,pomain.pototalFC
		,pomain.POTAXFC
		--,aspnetProf.Initials
		,aspnetUser.UserName AS BUYER
		,supinfo.Fcused_Uniq
		--01/04/2018 Satish B : Change selection of FUNCTIONAL currency from F.Currency To Func.Currency
		,ISNULL(Func.Currency,'') AS FUNCTIONAL
		,ISNULL(F.Currency,'') AS TRANSACTIONAL
		--10/09/2017 Satish B : Check null for FH.Askprice
		,ISNULL(FH.Askprice,0) AS ER
		--,FH.Askprice AS ER
		 --11/07/2017 Satish B : Select CONFNAME from CCONTACT
		 --12/28/2017 Satish B : Remove white space
		 --07/12/2018 Satish B : Remove middle name from conf name
		 --(RTRIM(LTRIM(c.MIDNAME))) +' '
		,ISNULL((RTRIM(LTRIM(c.FIRSTNAME))) +' '+ (RTRIM(LTRIM(c.LASTNAME))),'') AS CONFNAME
		--12/04/2017 Satish B : Select SHIPCHG ,IS_SCTAX and SCTAXPCT,UNIQSUPNO,R_LINK,C_LINK,B_LINK,SUPID,LFREIGHTINCLUDE columns
		,pomain.SHIPCHG
		,pomain.IS_SCTAX
		,pomain.SCTAXPCT
		,supinfo.UNIQSUPNO
		,supinfo.SUPID
		,pomain.R_LINK
		,pomain.C_LINK
		,pomain.B_LINK
		,pomain.LFREIGHTINCLUDE
		-- 09/06/2018 Satish B : Select IsApproveProcess from POMAIN table
		,pomain.IsApproveProcess
		--Satish B: added "aspnetProf.UserId" field 
		--,aspnetProf.UserId
		,aspnetUser.UserId
	  FROM POMAIN pomain
	  INNER JOIN  SUPINFO supinfo ON pomain.UNIQSUPNO=supinfo.UNIQSUPNO
	  --10/11/2017 Satish B : Replace aspnet_Profile.INNER JOIN With aspnet_Profile.LEFT JOIN
	  -- 05/20/2019 Satish B : Replace join aspnet_Profiles with aspnet_Users to display Username instead of User initials
	  --LEFT JOIN aspnet_Profile aspnetProf ON aspnetProf.UserId= pomain.aspnetBuyer
	  LEFT JOIN aspnet_Users aspnetUser ON aspnetUser.UserId= pomain.aspnetBuyer
	  LEFT JOIN FCUSED  F ON supinfo.Fcused_Uniq = F.FcUsed_Uniq
	  --01/04/2018 Satish B : Added extra join of FCUSED to select functional currency
	  LEFT JOIN FCUSED  Func ON Func.Fcused_Uniq = pomain.funcFcUsed_uniq
	  LEFT JOIN FcHistory FH ON FH.Fchist_key = dbo.getLatestExchangeRate(F.Fcused_Uniq)
	   --11/07/2017 Satish B : Added join of CCONTACT table with pomain
	  LEFT JOIN CCONTACT c on c.CID =pomain.CONFNAME
	  WHERE pomain.PONUM=@poNumber
 END