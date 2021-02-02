--========================================================================================================================================================================    
--Author:  <Debbie>    
--Create date: <07/21/2017>    
--Description: <Compiles the details for the Inventory Labels>    
--Used On:     <{invtxreflbl}    
--Modified: 07/21/2017 DRP:  created this label that is actually an Internal Part number lable but includes the Customer CPN information as a Cross Reference.   
--        W_key will be displayed on the label in BarCode formation and the W_key will be for the Internal Part number locations.     
-- But We use the Customer Selection to get the Labels out of the system.     
--03/01/18 YS lotcode size change to 25    
-- 10/11/19 VL changed part_no from char(25) to char(35)   
-- 05/21/2020 Satyawan H: Removed INVTMFHD table from JOIN and added InvtMPNLink and MfgrMaster in JOIN modfied selected fields
--EXEC [dbo].[rptInternalInvtPartWxrefLbl] @lcUniq_keyStart='_0570LPNF2',@lcUniq_keyEnd='_0570OU9XG',
--										   @lcCustNo='0000001005',@lcLoc='',@userId='49F80792-E15E-4B62-B720-21B360E3108A'
--========================================================================================================================================================================    
    
CREATE PROCEDURE [dbo].[rptInternalInvtPartWxrefLbl]
	 @lcUniq_keyStart char(10)= ''    
	,@lcUniq_keyEnd char(10)= ''    
	--,@lcType as char (20) = 'Consigned' --where the user would specify Internal, Internal & In Store, In Store, Consigned    
	,@lcCustNo as varchar (max) = ''    
	,@lcLoc as varchar(17) = ''    
	,@lcUniqWH varchar(max)='All'--12/07/15 DRP added parameter for user to be able to filter output by warehouse. Default to 'All' can coma separated. has to be multiselect list or All    
	,@userId uniqueidentifier = ''   
	,@lcLabelQty as int = null   --05/01/17 DRP:  added    
AS    
BEGIN    

	--12/07/15 DRP:  ADDED    
	-- SET NOCOUNT ON added to prevent extra result sets from interfering with SELECT statements.    
	SET NOCOUNT ON;    
	--02/20/15 YS changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key    
	-- 10/11/19 VL changed part_no from char(25) to char(35)    
	DECLARE @lcPartStart CHAR(35)='',@lcRevisionStart CHAR(8)='',    
			@lcPartEnd CHAR(35)='',@lcRevisionEnd CHAR(8)=''    
    
	 --12/07/15 DRP changed part range paramaters from lcpart to lcuniq_key, remove single lcuniq_key    
	 -- find starting part number    
	 IF  @lcUniq_keyStart IS NULL OR @lcUniq_keyStart =''     
	  SELECT @lcPartStart=' ', @lcRevisionStart=' '    
	 ELSE    
	 SELECT @lcPartStart = ISNULL(I.Custpartno,' '),     
		 @lcRevisionStart = ISNULL(I.Custrev,' ')      
	 FROM INVENTOR I WHERE Uniq_key=@lcUniq_keyStart    
      
	-- find ending part number    
	IF  @lcUniq_keyEnd IS NULL OR @lcUniq_keyEnd =''     
		-- 10/11/19 VL changed part_no from char(25) to char(35)    
		SELECT @lcPartEnd = REPLICATE('Z',35), @lcRevisionEnd=REPLICATE('Z',8)    
	ELSE    
		SELECT @lcPartEnd =ISNULL(I.custpartno,' '),      
		@lcRevisionEnd = ISNULL(I.Custrev,' ')     
		FROM Inventor I WHERE Uniq_key=@lcUniq_keyEnd    
    
	/*WAREHOUSE LIST*/    
	--09/13/2013 DRP:  added code to handle Warehouse List    
	DECLARE @Whse TABLE(Uniqwh CHAR(10))    
	IF @lcUniqWh IS NOT NULL AND @lcUniqWh <> '' AND @lcUniqWh <> 'All'    
		INSERT INTO @Whse   
		SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcUniqWh,',')    
	ELSE    
	IF @lcUniqWh = 'All'    
	BEGIN    
		INSERT INTO @Whse SELECT uniqwh FROM WAREHOUS    
	END    
    
	--select * from @Whse    
	--09/13/2013 DRP:  added code to handle Location List    
	DECLARE @Loc TABLE(Loc CHAR(17))    
	IF @lcLoc IS NOT NULL AND @lcLoc <> ''    
		INSERT INTO @Loc   
		SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcLoc,',')    
	/*RECORD SELECTION SECTION*/    
	BEGIN    
		--GET LIST OF CUSTOMES FOR @USERID WITH ACCESS       
		DECLARE  @tCustomer as tCustomer    
		DECLARE @Customer TABLE (custno char(10))    
		INSERT INTO @tCustomer (Custno,CustName) EXEC aspmnxSP_GetCustomers4User @userId ;    
  
		IF @lcCustNo IS NOT NULL AND @lcCustNo <>'' AND @lcCustNo<>'All'    
			INSERT INTO @Customer   
			SELECT * FROM dbo.[fn_simpleVarcharlistToTable](@lcCustNo,',')    
			WHERE CAST (id AS CHAR(10)) IN (SELECT CustNo FROM @tCustomer)    
		ELSE    
		BEGIN    
			IF  @lcCustNo='All'     
			BEGIN    
				INSERT INTO @Customer SELECT CustNo FROM @tCustomer    
			END -- IF  @lcCustNo='All'     
		END   

   -- IF @lcCustNo is not null and @lcCustNo <>'' and @lcCustNo<>'All'    
  
   --03/01/18 YS lotcode size change to 25    
	SELECT i.INT_UNIQ, part_no,revision, part_class, part_type, DESCRIPt, i.CUSTNO, CUSTNAME     
	      ,warehouse,[location],mfgr.UNIQMFGRHD,PARTMFGR,MFGR_PT_NO,mfgr.W_KEY,mstr.MATLTYPE    
	      ,i.[STATUS],ISNULL(CAST(invtlot.lotcode AS CHAR (25)),CAST(mfgr.W_KEY AS CHAR (15))) AS Reference    
	      ,CAST (1 AS NUMERIC(3,0)) AS LabelQty,i.ABC,CUSTPARTNO,CUSTREV    
	      ,CASE WHEN @lcLabelQty IS NULL THEN 1 ELSE @lcLabelQty END AS LabelQty     
            
	FROM INVENTOR i 
	-- 05/21/2020 Satyawan H: Removed INVTMFHD table from JOIN and added InvtMPNLink and MfgrMaster in JOIN modfied selected fields
	JOIN INVTMFGR mfgr ON i.UNIQ_KEY = mfgr.UNIQ_KEY
    JOIN InvtMPNLink mpn ON mpn.uniq_key = i.UNIQ_KEY AND mfgr.UNIQMFGRHD = mpn.uniqmfgrhd 
	JOIN MfgrMaster mstr ON mstr.MfgrMasterId = mpn.MfgrMasterId   
	INNER JOIN WAREHOUS ON mfgr.UNIQWH = warehous.UNIQWH    
	LEFT OUTER JOIN INVTLOT ON mfgr.W_KEY = invtlot.W_KEY    
	LEFT OUTER JOIN CUSTOMER ON i.CUSTNO = customer.CUSTNO    
	LEFT OUTER JOIN SUPINFO ON mfgr.uniqsupno = supinfo.UNIQSUPNO    
           
   WHERE mpn.IS_DELETED = 0    
   AND mfgr.IS_DELETED = 0    
   --AND PART_SOURC = 'CONSG'    
   AND (custpartno+custrev BETWEEN @lcPartStart + @lcrevisionstart and @lcPartEnd+@lcRevisionEnd)    
   AND (@lcUniqWh = '' OR EXISTS (SELECT 1 FROM @Whse wh WHERE WH.UNIQWH=WAREHOUS.UNIQWH))    
   AND mfgr.[location] = CASE WHEN @lcLoc = '*' OR @lcLoc = '' THEN mfgr.[LOCATION] ELSE @lcLoc END    
   AND (@lcCustNo='All' OR EXISTS (SELECT 1 FROM @Customer t INNER JOIN customer c ON t.custno=c.custno WHERE c.custno=i.custno))    
   ORDER BY CUSTPARTNO,CUSTREV    
  END     
END