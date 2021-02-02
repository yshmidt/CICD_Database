-- =============================================
-- Author: Satish B
-- Create date: <09/06/2017>
-- Description:	<Get PO Status main grid data>
-- Modified : 09/13/2017 : Satish B : Added parameter @mfgrPartNo and @workOrder 
-- Modified : 09/13/2017 : Satish B : Check empty for @partNumber,@mroPartNo,@mfgrPartNo,@workOrder
-- Modified : 09/13/2017 : Satish B : Added filter of mfgrPartNo
-- Modified : 09/13/2017 : Satish B : Select RowCnt as count instade of COUNT(1)
-- Modified : 09/13/2017 : Satish B : Added filter for @workOrder
-- Modified : 09/14/2017 : Satish B Change selection of ConfirmTo,Phone,Email
-- Modified : 09/14/2017 : Satish B : Added join of CCONTACT table
-- Modified : 10/04/2017 : Satish B : Added filter of POSTATUS <> ARCHIVED'
-- Modified : 10/04/2017 : Satish B : Replace inner join of aspnet_profile with left join
-- Modified : 1/19/2018 : Satish B : Removed extra blank space from FirstName
-- Modified : 05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
--Modified 	: 05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
--Modified 	: 05/20/2019 : Satish B : Filtering data by Username  instead of Firstname and LastName
-- Exec GetPOStatusGridData '','','','Jill Craft','','','',1,100000,0
-- 07/12/2018 YS increase size of the supname column from 30 to 50
-- =============================================
CREATE PROCEDURE [dbo].[GetPOStatusGridData] 
	-- Add the parameters for the stored procedure here
	@poNumber nvarchar(15) = '' ,
	@partNumber nvarchar(35) = '' ,
	-- 07/12/2018 YS increase size of the supname column from 30 to 50
	@supplier nvarchar(50) = '' ,
	@buyer nvarchar(35) = '' ,
	@mroPartNo nvarchar(30) = '' ,
	--09/13/2017 : Satish B : Added parameter @mfgrPartNo and @workOrder 
	@mfgrPartNo nvarchar(30) = '' ,
	@workOrder nvarchar(30) = '' ,
	@startRecord int =1,
    @endRecord int =10,
	@outTotalNumberOfRecord int OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	--09/13/2017 : Satish B : Check empty for @partNumber,@mroPartNo,@mfgrPartNo,@workOrder
	 IF(@partNumber ='' AND @mroPartNo='' AND @mfgrPartNo='' AND @workOrder='')
		 BEGIN
			SELECT COUNT(pm.PONUM) AS RowCnt -- Get total counts 
				INTO #tempPoStatusDetails 
			FROM POMAIN pm
			--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
			--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
			--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
			LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
			INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
			INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
			--09/14/2017 Satish B : Added join of CCONTACT table
			LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
			WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND
			--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
			pm.POSTATUS <> 'ARCHIVED' AND
					       ((@poNumber IS NULL OR @poNumber='') OR (pm.PONUM =@poNumber))
					   AND ((@supplier IS NULL OR @supplier='') OR (si.SUPNAME =@supplier))
					   --1/19/2018 : Satish B : Removed extra blank space from FirstName
					   --05/20/2019 : Satish B : Filtering data by Username  instead of Firstname and LastName
					   --AND ((@buyer IS NULL OR @buyer='') OR (RTRIM(ap.FirstName) + (ap.LastName) = REPLACE(@buyer,' ','')))
					   AND ((ISNULL(@buyer ,'') ='' AND 1=1)  OR (ISNULL(@buyer ,'')  <> '' and ap.UserName =@buyer)) 

			SELECT CAST(dbo.fremoveLeadingZeros(pm.PONUM) AS VARCHAR(MAX)) AS PONumber
			 --05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
				--,CONCAT(ap.FirstName, ' ', ap.LastName) as Buyer
				,ap.UserName As Buyer
				,si.SUPNAME as Supplier
				,pm.POSTATUS as Status
				,pm.PODATE as PODate
				--09/14/2017 Satish B Change selection of ConfirmTo,Phone,Email
				--,sb.SHIPTO as ConfirmTo
				--,sb.PHONE as Phone
				--,sb.E_MAIL as Email 
				,(ct.FIRSTNAME +''+ct.LASTNAME) as ConfirmTo
				,ct.HOMEPHONE as Phone
				,ct.EMAIL as Email 
			FROM POMAIN pm
			--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
			--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
			--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
			LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
			INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
			INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
			--09/14/2017 Satish B : Added join of CCONTACT table
			LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
			WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
			--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
			pm.POSTATUS <> 'ARCHIVED' AND
			((@poNumber IS NULL OR @poNumber='') OR (pm.PONUM =@poNumber))
				   AND ((@supplier IS NULL OR @supplier='') OR (si.SUPNAME =@supplier))
				    --1/19/2018 : Satish B : Removed extra blank space from FirstName
					--05/20/2019 : Satish B : Filtering data by Username  instead of Firstname and LastName
				   --AND ((@buyer IS NULL OR @buyer='') OR (RTRIM(ap.FirstName) + (ap.LastName) = REPLACE(@buyer,' ','')))
				   AND ((ISNULL(@buyer ,'') ='' AND 1=1)  OR (ISNULL(@buyer ,'')  <> '' and ap.UserName =@buyer)) 
			ORDER BY pm.PONUM
			OFFSET(@startRecord-1) ROWS
			FETCH NEXT @EndRecord ROWS ONLY;
			SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoStatusDetails) 
		 END
	 ELSE IF(@partNumber <>'')
		 BEGIN
				SELECT COUNT(1) AS RowCnt -- Get total counts 
					INTO #tempPoStatusWhenPart
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN INVENTOR invt on invt.UNIQ_KEY = poit.UNIQ_KEY
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
				pm.POSTATUS <> 'ARCHIVED' AND
					       invt.PART_NO LIKE '%'+RTRIM(@partNumber)+'%'

				SELECT 
				--CONCAT(ap.FirstName, ' ', ap.LastName) as Buyer
				 --05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
					ap.UserName As Buyer
					,si.SUPNAME as Supplier
					,CAST(dbo.fremoveLeadingZeros(pm.PONUM) AS VARCHAR(MAX)) AS PONumber
					,pm.POSTATUS as Status
					,pm.PODATE as PODate
				--09/14/2017 Satish B Change selection of ConfirmTo,Phone,Email
				--,sb.SHIPTO as ConfirmTo
				--,sb.PHONE as Phone
				--,sb.E_MAIL as Email 
				,(ct.FIRSTNAME +''+ct.LASTNAME) as ConfirmTo
				,ct.HOMEPHONE as Phone
				,ct.EMAIL as Email 
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN INVENTOR invt on invt.UNIQ_KEY = poit.UNIQ_KEY
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
						   pm.POSTATUS <> 'ARCHIVED' AND
					       invt.PART_NO LIKE '%'+RTRIM(@partNumber)+'%'
				ORDER BY pm.PONUM
				OFFSET(@startRecord-1) ROWS
				FETCH NEXT @EndRecord ROWS ONLY;
				--09/13/2017 : Satish B : Select RowCnt as count instade of COUNT(1)
				SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoStatusWhenPart) 
			END
	 ELSE IF(@mroPartNo <>'')
		 BEGIN
				SELECT COUNT(1) AS RowCnt -- Get total counts 
				INTO #tempPoStatusWhenMro
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  poit.PART_NO LIKE '%'+RTRIM(@mroPartNo)+'%' AND poit.PART_TYPE='MRO' 
				SELECT 
				 --05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
				--CONCAT(ap.FirstName, ' ', ap.LastName) as Buyer
					ap.UserName As Buyer
					,si.SUPNAME as Supplier
					,CAST(dbo.fremoveLeadingZeros(pm.PONUM) AS VARCHAR(MAX)) AS PONumber
					,pm.POSTATUS as Status
					,pm.PODATE as PODate
				--09/14/2017 Satish B Change selection of ConfirmTo,Phone,Email
				--,sb.SHIPTO as ConfirmTo
				--,sb.PHONE as Phone
				--,sb.E_MAIL as Email 
				,(ct.FIRSTNAME +''+ct.LASTNAME) as ConfirmTo
				,ct.HOMEPHONE as Phone
				,ct.EMAIL as Email 
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  poit.PART_NO LIKE '%'+RTRIM(@mroPartNo)+'%' AND poit.PART_TYPE='MRO' 
				ORDER BY pm.PONUM
				OFFSET(@startRecord-1) ROWS
				FETCH NEXT @EndRecord ROWS ONLY;
				SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoStatusWhenMro) 
			END
	--09/13/2017 : Satish B : Added filter of mfgrPartNo
	 ELSE IF(@mfgrPartNo <>'')
		 BEGIN
		    SELECT COUNT(1) AS RowCnt -- Get total counts 
				INTO #tempPoStatusWhenMfgrPart
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poit.UNIQMFGRHD
				INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  mfgrmaster.mfgr_pt_no LIKE '%'+RTRIM(@mfgrPartNo)+'%'
				SELECT 
				--05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
				--CONCAT(ap.FirstName, ' ', ap.LastName) as Buyer
					ap.UserName As Buyer
					,si.SUPNAME as Supplier
					,CAST(dbo.fremoveLeadingZeros(pm.PONUM) AS VARCHAR(MAX)) AS PONumber
					,pm.POSTATUS as Status
					,pm.PODATE as PODate
				--09/14/2017 Satish B Change selection of ConfirmTo,Phone,Email
				--,sb.SHIPTO as ConfirmTo
				--,sb.PHONE as Phone
				--,sb.E_MAIL as Email 
				,(ct.FIRSTNAME +''+ct.LASTNAME) as ConfirmTo
				,ct.HOMEPHONE as Phone
				,ct.EMAIL as Email 
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poit.UNIQMFGRHD
				INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  mfgrmaster.mfgr_pt_no LIKE '%'+RTRIM(@mfgrPartNo)+'%'
				ORDER BY pm.PONUM
				OFFSET(@startRecord-1) ROWS
				FETCH NEXT @EndRecord ROWS ONLY;
				--09/13/2017 : Satish B : Select RowCnt as count instade of COUNT(1)
				SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoStatusWhenMfgrPart) 
		END
		--09/13/2017 : Satish B : Added filter for @workOrder
		ELSE IF(@workOrder <>'')
		 BEGIN
		    SELECT COUNT(1) AS RowCnt -- Get total counts 
				INTO #tempPoStatusWhenWo
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poit.UNIQMFGRHD
				INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId
				INNER JOIN POITSCHD ps on ps.UNIQLNNO=poit.UNIQLNNO
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  ps.REQUESTTP='WO Alloc' and ps.WOPRJNUMBER LIKE '%'+RTRIM(@workOrder)+'%'
				SELECT 
				--05/20/2019 : Satish B : Selecting  Username instead of Firstname and LastName
				--CONCAT(ap.FirstName, ' ', ap.LastName) as Buyer
					ap.UserName As Buyer
					,si.SUPNAME as Supplier
					,CAST(dbo.fremoveLeadingZeros(pm.PONUM) AS VARCHAR(MAX)) AS PONumber
					,pm.POSTATUS as Status
					,pm.PODATE as PODate
				--09/14/2017 Satish B Change selection of ConfirmTo,Phone,Email
				--,sb.SHIPTO as ConfirmTo
				--,sb.PHONE as Phone
				--,sb.E_MAIL as Email 
				,(ct.FIRSTNAME +''+ct.LASTNAME) as ConfirmTo
				,ct.HOMEPHONE as Phone
				,ct.EMAIL as Email 
				FROM POMAIN pm
				INNER JOIN poitems poit on pm.PONUM = poit.PONUM
				--10/04/2017 Satish B : Replace inner join of aspnet_profile with left join
				--05/20/2019 : Satish B : Replace Join aspnet_Profiles with aspnet_Users for filterring grid and displaying Username instead of FirstName and LastName
				--LEFT JOIN aspnet_profile ap on pm.aspnetBuyer = ap.UserId
				LEFT JOIN aspnet_Users ap on pm.aspnetBuyer = ap.UserId
				INNER JOIN supinfo si on pm.C_LINK = si.C_LINK
				INNER JOIN SHIPBILL sb on pm.C_LINK = sb.LINKADD
				INNER JOIN InvtMPNLink mpn on mpn.uniqmfgrhd=poit.UNIQMFGRHD
				INNER JOIN MfgrMaster mfgrmaster on mfgrmaster.MfgrMasterId=mpn.MfgrMasterId
				INNER JOIN POITSCHD ps on ps.UNIQLNNO=poit.UNIQLNNO
				--09/14/2017 Satish B : Added join of CCONTACT table
			    LEFT JOIN CCONTACT ct on ct.CID= pm.CONFNAME
				WHERE pm.POSTATUS <> 'CLOSED' AND pm.POSTATUS <> 'CANCEL' AND 
				--10/04/2017 Satish B : Added filter of POSTATUS <> ARCHIVED'
					  pm.POSTATUS <> 'ARCHIVED' AND
					  ps.REQUESTTP='WO Alloc' and ps.WOPRJNUMBER LIKE '%'+RTRIM(@workOrder)+'%'
				ORDER BY pm.PONUM
				OFFSET(@startRecord-1) ROWS
				FETCH NEXT @EndRecord ROWS ONLY;
				SET @outTotalNumberOfRecord = (SELECT RowCnt FROM #tempPoStatusWhenWo) 
		END
END