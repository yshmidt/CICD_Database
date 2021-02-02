
-- =============================================      
-- Author:  ??      
-- Create date: ??      
-- Description: This procedure is used by bar code SF module in the cloud      
-- Modified: 11/12/14 YS add changes to make sure that rework work order code executes only when we transfer to "FGI"      
-- 11/18/14 YS remove the last IF and always return available location for moving to FGI ( per Santosh request when user in the UI and changes the work center)       
-- Modified: 11/19/2014 Santosh L added a parameter @isSingleMode. And use this parameter whether associated serial numbers are required or not.    
-- 11/19/14 YS adjusted changes by Santosh 
-- 12/10/14 VL The code about getting lot code info from CM tables only need to be ran if it's moving to 'FGI', so added IF to only go through if @my_Deptkey/@my_DeptId is 'FGI'
-- 12/22/14 VL Found the code VL added 12/10/14 is incorrect that @my_DeptId might be FROM or TO work center.  Also uncomment out YS code added on 11/12/14 which were commented out, it looks correct
-- 02/06/15 Santosh L: Added IsKitReleased parameter to check if KIT is released for a WO or not.
-- 05/21/16 Anuj Modified to Get Serial numbers for batch mode
-- 10/26/16 Sachin B pass newly added parameter in SP InvtAvailableFGILocationView @uniq_key ,@wono,0 
-- 03/28/17 YS changed length of the part_no column from 25 to 35
-- 07/20/2017 Sachin B pass newly added parameter keSeqnum in SP InvtAvailableFGILocationView as ''
 --03/01/18 YS lotcode size change to 25
---- =============================================      
CREATE PROCEDURE [dbo].[InvtSerWorkOrderDetailsGet]    
(      
 @SerialNo   VARCHAR(30),      
 @my_Deptkey  VARCHAR(10),      
 @wono    VARCHAR(10),      
 @isSingleMode  bit = 1     
 )      
AS      
  BEGIN      
      DECLARE @my_DeptId VARCHAR(4), @uniq_key VARCHAR(10)      
      DECLARE @snTransferMode char(1) = (SELECT TOP 1 XXWCORACTV FROM ShopFSet)      
         
      ---11/12/14 YS added [ISCMLOTRECORD] used when reworkfirm work order is moved into FGI      
   -- if the record exists within 'CM..' tables assign the lot code information per records in the 'CM.. tables)       
   -- user doesn't have to see the pop up form for the lot code      
   -- 02/06/15 Santosh L: Added IsKitReleased parameter to check if KIT is released for a WO or not.
   --03/01/18 YS lotcode size change to 25
	  DECLARE @tJobInfo TABLE      
        (   
		--- 03/28/17 YS changed length of the part_no column from 25 to 35   
           PART_NO      CHAR(35),      
           REVISION     CHAR(8),      
           DESCRIPT     CHAR(45),      
           PART_TYPE    CHAR(8),      
           PART_CLASS   CHAR(8),      
           STDBLDQTY    NUMERIC(8, 0),--- THESE ARE FIELDS FROM INVENTOR TABLE      
           LOTDETAIL    BIT,      
           FGIEXPDAYS   NUMERIC(4, 0),      
           AUTODT       BIT,      
           --- THESE ARE FIELDS FROM PARTTYPE TABLE                                           
           OPENCLOS     CHAR(10),      
           CMPRICELNK   CHAR(10),      
           UNIQUELN     CHAR(10),      
           BLDQTY       NUMERIC(7, 0), 
		   ISKITRELEASED       BIT,      
           --- THESE ARE FIELDS FROM WOENTRY TABLE                                                
           CUSTNAME     CHAR(35),--- THIS IS FIELD FROM CUSTOMER TABLE      
           [SERIALUNIQ] [CHAR](10) NOT NULL,      
           --- FROM HERE DOWN ALL THE FIELDS ARE FROM INVTSER TABLE      
           [SERIALNO]   [CHAR](30) NOT NULL,      
           [UNIQ_KEY]   [CHAR](10) NOT NULL,      
           [UNIQMFGRHD] [CHAR](10) NOT NULL,      
           [UNIQ_LOT]   [CHAR](10) NOT NULL,      
           [ID_KEY]     [CHAR](10) NOT NULL,      
           [ID_VALUE]   [CHAR](10) NOT NULL,      
           [LOTCODE]    [CHAR](25) NOT NULL,      
           [EXPDATE]    [SMALLDATETIME] NULL,      
           [REFERENCE]  [CHAR](12) NOT NULL,      
           [ACTVKEY]    [CHAR](10) NOT NULL,      
           [WONO]       [CHAR](10),      
           [XXWCORACTV] [CHAR](1),      
     [ISCMLOTRECORD] [bit] DEFAULT (0) NOT NULL      
        )      
      -- 02/06/15 Santosh L: Added IsKitReleased parameter to check if KIT is released for a WO or not.
      INSERT INTO @tJobInfo      
                  (PART_NO,      
                   REVISION,      
                   DESCRIPT,      
PART_TYPE,      
                   PART_CLASS,      
                   STDBLDQTY,      
                   LOTDETAIL,      
                   FGIEXPDAYS,      
                   AUTODT,      
                   OPENCLOS,      
                   CMPRICELNK,      
                   UNIQUELN,      
                   BLDQTY,   
				   IsKitReleased,   
                   CUSTNAME,      
                   [SERIALUNIQ],      
                   [SERIALNO],      
                   [UNIQ_KEY],      
                   [UNIQMFGRHD],      
                   [UNIQ_LOT],      
                   [ID_KEY],      
                   [ID_VALUE],      
                   [LOTCODE],      
                   [EXPDATE],      
                   [REFERENCE],      
                   [ACTVKEY],      
                   [WONO],      
                   [XXWCORACTV])      
 SELECT inventor.part_no,      
             inventor.revision,      
             inventor.descript,      
             inventor.part_type,      
             inventor.part_class,      
           inventor.stdbldqty,      
             Isnull(parttype.lotdetail, Cast(0 AS BIT)),      
             Isnull(parttype.fgiexpdays, Cast(0 AS NUMERIC(4, 0))),      
             Isnull(parttype.autodt, Cast(0 AS BIT)),      
             woentry.openclos,      
             woentry.cmpricelnk,      
             woentry.uniqueln,      
             woentry.bldqty,    
			 woentry.Kit,  
             customer.custname,      
             invtser.[serialuniq],      
             invtser.[serialno],      
             invtser.[uniq_key],      
             invtser.[uniqmfgrhd],      
             invtser.[uniq_lot],      
             invtser.[id_key],      
             invtser.[id_value],      
             invtser.[lotcode],      
             invtser.[expdate],      
             invtser.[reference],      
             invtser.[actvkey],      
             invtser.[wono],      
             @snTransferMode      
      FROM   inventor      
             LEFT OUTER JOIN parttype      
                          ON inventor.part_class = parttype.part_class      
                             AND inventor.part_type = parttype.part_type      
             INNER JOIN invtser      
                     ON inventor.uniq_key = invtser.uniq_key      
             INNER JOIN woentry      
                     ON invtser.wono = woentry.wono      
             INNER JOIN customer      
                     ON woentry.custno = customer.custno      
      WHERE  invtser.wono = @wono      
             AND invtser.serialno = @SerialNo      
       --select * from @tJobInfo     
      -- create table variable to collect actv_qty data for the given work order      
      DECLARE @tActv_qty TABLE      
        (      
           [WONO]            [CHAR](10) NOT NULL,      
           [ACTIV_ID]        [CHAR](4) NOT NULL,      
           [CURR_QTY]        [NUMERIC](7, 0) NOT NULL,      
           [XFER_QTY]        [NUMERIC](7, 0) NOT NULL,      
           [NUMBERA]         [NUMERIC](4, 0) NOT NULL,      
           [DEPTKEY]         [CHAR](10) NOT NULL,      
           [WO_WC_NOTE]      [TEXT] NOT NULL,      
           [ACTVKEY]         [CHAR](10) NOT NULL,      
           [UNIQUERECID]     [CHAR](10) NOT NULL,      
           ISCURRENTACTIVITY BIT DEFAULT 0,      
           ISTOACTIVITY BIT DEFAULT 0,      
           NTOTALACTVINWC    INT      
        )      
      
      INSERT INTO @tActv_qty      
      SELECT A.[wono],      
             [activ_id],      
             [curr_qty],      
             [xfer_qty],      
            [numbera],      
             [deptkey],      
             [wo_wc_note],      
             A.[actvkey],      
             [uniquerecid],      
             Cast(CASE      
                    WHEN J.actvkey IS NULL THEN 0      
                    ELSE 1      
               END AS INT)          AS isCurrentActivity,      
             0,      
             Count(*)      
               OVER (      
                 partition BY deptkey) AS nTotalACtvInWc      
      FROM   actv_qty A      
             LEFT OUTER JOIN @tJobInfo J      
                          ON A.wono = J.wono      
                             AND A.deptkey = J.[id_value]      
                             AND J.id_key = 'DEPTKEY'      
                             AND A.actvkey = J.actvkey      
      WHERE  A.wono = @wono      
      
      -- create table varibale to collect dept_qty for the given work order. Added flag to indicate if the deprtment is From Department      
      DECLARE @tDept_qty TABLE      
        (      
           [DEPT_ID]      [CHAR](4) NOT NULL,      
           [WONO]         [CHAR](10) NOT NULL,      
           [CURR_QTY]     [NUMERIC](7, 0) NOT NULL,      
           [XFER_QTY]     [NUMERIC](7, 0) NOT NULL,      
           [NUMBER]       [NUMERIC](4, 0) NOT NULL,      
           [DEPTKEY]      [CHAR](10) NOT NULL,      
           [WO_WC_NOTE]   [TEXT] NOT NULL,      
           [SERIALSTRT]   [BIT] NOT NULL,      
           [UNIQUEREC]    [CHAR](10) NOT NULL,      
           ISFROMDEPT     BIT NOT NULL,      
           ISMYDEPT       BIT NOT NULL,      
           MYISFROM       BIT NOT NULL,      
           ISTODEPT       BIT DEFAULT 0 NOT NULL,      
           NEXTSTEP       INT DEFAULT 0 NOT NULL,      
           NSEQ           INT,      
           NTOTALACTVINWC INT DEFAULT 0 NOT NULL      
        )      
      
      INSERT INTO @tDept_qty      
                  ([dept_id],      
                   [wono],      
                   [curr_qty],      
                   [xfer_qty],      
                   [number],      
                   [deptkey],      
                   [wo_wc_note],      
                   [serialstrt],      
                   [uniquerec],      
                   isfromdept,      
                   ismydept,      
                   myisfrom,      
                   nseq,      
                   ntotalactvinwc)      
      SELECT [dept_id],      
             D.[wono],      
             [curr_qty],      
             [xfer_qty],      
             D.[number],      
             [deptkey],      
             [wo_wc_note],      
             [serialstrt],      
             [uniquerec],      
             Cast(Isnull(S.isfromdept, 0) AS BIT) AS IsFromDept,      
             CASE      
               WHEN deptkey = @my_Deptkey THEN Cast(1 AS BIT)      
               ELSE Cast(0 AS BIT)      
             END                                  AS IsMyDept,      
             CASE      
               WHEN deptkey = @my_Deptkey      
                    AND S.isfromdept IS NOT NULL THEN Cast(1 AS BIT)      
               ELSE Cast(0 AS BIT)      
             END                                  AS MyIsFrom,      
             Row_number ()      
               OVER(      
                 ORDER BY D.number)               AS nSeq,      
             (SELECT Count(*)      
              FROM   @tActv_qty      
              WHERE  deptkey = D.deptkey)      
      FROM   dept_qty D      
             OUTER apply (SELECT Cast(1 AS BIT) AS IsFromDept,      
                                 D.number      
                          FROM   @tJobInfo J      
                          WHERE  D.wono = J.wono      
                                 AND D.deptkey = CASE      
                                                   WHEN J.id_key = 'DEPTKEY'      
            THEN      
                                                   J.id_value      
                                                   ELSE D.deptkey      
                                                 END      
                   AND D.dept_id = CASE  
                                                   WHEN J.id_key = 'W_KEY' THEN      
                                                   'FGI'      
                                                   ELSE D.dept_id      
                                                 END) S      
      WHERE  D.wono = @wono;      
      
      WITH nextnumber      
           AS (SELECT D.*,      
                      CASE      
                        WHEN D.dept_id = 'FGI'      
                              OR D.dept_id = 'SCRP' THEN Cast(1 AS INT)      
                        ELSE Cast(Isnull(D2.number, 0) AS INT)      
                      END AS NextStep1 -- if last step go back to STAG      
               FROM   @tDept_qty D      
                      LEFT OUTER JOIN @tDept_qty D2      
                                   ON d.nseq = d2.nseq - 1)      
      UPDATE @tDept_qty      
      SET    nextstep = N.nextstep1      
      FROM   nextnumber N      
             INNER JOIN @tDept_qty t      
                     ON N.deptkey = t.deptkey      
---select * from @tDept_qty      
      
   IF EXISTS (SELECT deptkey FROM @tDept_qty WHERE myisfrom = 1) AND (@snTransferMode = 'W')      
      BEGIN  --- we are pushing from my deprtment and transfer by work center      
    UPDATE @tDept_qty      
    SET    istodept = 1      
    WHERE  nseq IN (SELECT nextstep      
        FROM   @tDept_qty      
        WHERE  myisfrom = 1)      
               
      END      
      ELSE IF EXISTS (SELECT deptkey FROM @tDept_qty WHERE  myisfrom = 1) AND (@snTransferMode = 'A')      
      BEGIN  --- we are pushing from my deprtment and transfer by activity      
            
   DECLARE @nexActivityNumber int = (SELECT TOP 1 tActv_qty_to.numbera       
            FROM @tActv_qty tActv_qty_to       
            WHERE tActv_qty_to.deptkey = @my_Deptkey and tActv_qty_to.IsCurrentActivity = 0       
            AND numbera > (SELECT TOP 1 numbera FROm @tActv_qty WHERE IsCurrentActivity = 1) order by numbera)      
                  
   -- check that the current activity is not the last activity in my work center.              
   IF (isnull(@nexActivityNumber,0) > 0 )      
   BEGIN --transfer to next activity is my work center.      
    UPDATE @tDept_qty      
    SET    istodept = 1      
    WHERE  IsMyDept = 1      
          
    UPDATE @tActv_qty       
    SET ISTOACTIVITY =1      
    WHERE deptkey = @my_Deptkey and numbera = ((SELECT NUMBERA FROM @tActv_qty WHERE IsCurrentActivity =1) +1)      
   END      
   ELSE      
   BEGIN --transfer to first activity in next work center.      
    UPDATE @tDept_qty      
    SET    istodept = 1      
    WHERE  nseq IN (SELECT nextstep      
        FROM   @tDept_qty      
        WHERE  myisfrom = 1);      
            
    WITH FirstActivityInNextWC AS (SELECT TOP 1 tActv_qty.* from @tActv_qty tActv_qty inner join @tDept_qty tDept_qty on tActv_qty.deptkey = tDept_qty.deptkey where istodept=1 order by NUMBERA)      
    UPDATE FirstActivityInNextWC       
    SET ISTOACTIVITY =1           
     END      
      END      
      ELSE       
      BEGIN -- we are pulling into my work center      
        UPDATE @tDept_qty      
        SET    istodept = 1      
        WHERE  ismydept = 1;      
              
        if (@snTransferMode = 'A')      
        BEGIN      
   with ToActivityInMyWC AS (SELECT TOP 1 tActv_qty.* FROM @tActv_qty tActv_qty WHERE deptkey=@my_Deptkey order by NUMBERA)      
   UPDATE ToActivityInMyWC       
   SET ISTOACTIVITY =1           
  END      
   END      
         
      SELECT @my_DeptId = dept_id      
      FROM   @tDept_qty      
      WHERE  ismydept = 1      

-- 12/22/14 VL comment out next two lines
-- 12/10/14 VL the following code only need to be ran if it's moving to 'FGI', so added IF to only go through if @my_Deptkey/@my_DeptId is 'FGI'
--IF @my_DeptId = 'FGI'
--BEGIN
   --- 11/12/14 YS This code should be concidered only if we are moving to 'FGI'      
   -- we will always have 'FGI'  dept in the @tDept_id table      
   -- FGI is a hardcode WC and always present      
   --IF (SELECT Count(*)      
  --       FROM   @tDept_qty      
  --       WHERE  dept_id = 'FGI') > 0    
-- 12/22/14 VL un-comment out YS 11/12/14 two lines code which were comment out don't know why, it looks right  
IF EXISTS (select 1 from @tDept_qty where dept_id='FGI' and isToDept=1)      
BEGIN                   
   IF (SELECT OpenClos FROM @tJobInfo) = 'ReworkFirm'         
   BEGIN        
      -- 11/12/14 YS no need to use woentry table here , all the columns already in @tjobInfo      
      Update JobInfo      
      SET JobInfo.lotcode=CmInvlot.LotCode, JobInfo.Expdate=CmInvlot.Expdate, JobInfo.Reference=CmInvlot.Reference        
      FROM CmInvlot, CmAlloc, Cmprices , @tJobInfo JobInfo      
      WHERE Cminvlot.Uniq_Alloc = Cmalloc.Uniq_Alloc         
      AND CmAlloc.Cmemono = Cmprices.Cmemono        
      AND CmAlloc.Packlistno = Cmprices.Packlistno         
      AND CmAlloc.Uniqueln = Cmprices.Uniqueln         
      AND Cmprices.Cmpricelnk = jobinfo.Cmpricelnk         
      AND CmPrices.Uniqueln =  jobinfo.Uniqueln            
      and JobInfo.wono = jobinfo.wono      
      AND jobinfo.wono = @wono        
     --11/12/14 YS no empty date should be assigned, SQL will replace it with '1900...' . Assign null      
      IF @@rowcount = 0        
      BEGIN        
       Update JobInfo      
       SET lotcode= wono ,        
     Expdate = case        
       when  FgiExpDays = 0 then NULL       
       else DATEADD(day,FgiExpDays,GETDATE())        
       end,        
     Reference = case        
        when  AutoDt = 0 then ' '        
        else CONVERT(VARCHAR(10),GETDATE(),111)        
        end   ,      
        --11/12/14 YS make sure [ISCMLOTRECORD]=0      
        [ISCMLOTRECORD]=0          
       FROM  @tJobInfo JobInfo where wono=@wono      
             
      END  --- no records in 'CM ..' tables       
      ELSE  --- 11/12/14 YS added new flag [ISCMLOTRECORD]      
      BEGIN      
     update @tJobInfo SET ISCMLOTRECORD=CASE WHEN LOTDETAIL =1 THEN 1 ELSE 0 END where wono=@wono      
      
      END      
   END        
   ELSE      
   BEGIN        
    --11/12/14 YS no empty date should be assigned, assign NULL instead      
    Update JobInfo      
    SET lotcode= wono ,        
    EXPDATE = case        
       when  FgiExpDays = 0 then NULL     
       else DATEADD(day,FgiExpDays,GETDATE())        
       end,        
    Reference = case        
       when  AutoDt = 0 then ' '        
       else CONVERT(VARCHAR(10),GETDATE(),111)        
       end   ,      
        --11/12/14 YS make sure [ISCMLOTRECORD]=0      
        [ISCMLOTRECORD]=0           
    FROM  @tJobInfo JobInfo      
   END      
END      
--END
-- 12/10/14 VL End}
      
   SELECT *      
      FROM   @tJobInfo;      
   -- Modified: 11/19/2014 Santosh L added a parameter @isSingleMode. And use this parameter whether associated serial numbers are required or not.    
   -- 11/19/14 YS adjusted changes by Santosh. The way it is written if FromDept.Dept_Id='FGI' the result will always return all serial numbers in the FGI location    
   -- 05/21/16 Anuj Modified to Get Serial numbers for batch mode
     with FromDept AS (SELECT * FROM   @tDept_qty WHERE (IsFromDept = 1))      
     SELECT invtser.uniq_key,      
                    invtser.serialuniq,      
                    invtser.serialno,      
                    invtser.id_key,      
  invtser.id_value,      
                    invtser.wono,      
                    invtser.actvkey,      
                    dbo.Fn_getopendefectcountforserialnumber(invtser.serialuniq) AS OpenDefectCount      
      FROM   invtser inner join DEPT_QTY on INVTSER.WONO = DEPT_QTY.WONO
   WHERE invtser.id_key = case when  @my_DeptId = 'FGI' then 'W_KEY'
   when  @my_DeptId <> 'FGI' then 'DEPTKEY'
    else '' end        
   AND DEPT_QTY.DEPTKEY=@my_Deptkey AND DEPT_QTY.WONO = @wono
  -- 11/19/14 YS        
    --  WHERE  (FromDept.Dept_Id='FGI' AND invtser.wono = @wono AND invtser.id_key = 'W_KEY')      
    --OR (FromDept.Dept_Id<>'FGI' AND invtser.wono = @wono AND invtser.id_key = 'DEPTKEY' aND invtser.id_value = FromDept.deptkey)      
    --AND ((@isSingleMode = 1 AND invtser.serialno = @SerialNo) OR (@isSingleMode = 0 OR  invtser.serialno = @SerialNo))    
         
      SELECT *      
      FROM   @tDept_qty      
      ORDER  BY number      
            
      SELECT *      
      FROM   @tActv_qty      
      ORDER  BY deptkey,numbera      
   -- 11/12/14 YS need to run InvtAvailableFGILocationView only if transferring to FGI      
      --IF (SELECT Count(*)      
      --    FROM   @tDept_qty      
      --    WHERE  dept_id = 'FGI') > 0      
  -- 11/18/14 YS remove the last IF and always return available location for moving to FGI ( per Santosh request when user in the UI and changes the work center)       
   --IF EXISTS (select 1 from @tDept_qty where dept_id='FGI' and isToDept=1)       
     -- BEGIN      
   SET @uniq_key=(SELECT uniq_key FROM @tJobInfo)  
            -- 10/26/16 Sachin B pass newly added parameter in SP InvtAvailableFGILocationView @uniq_key ,@wono,0
			-- 07/20/2017 Sachin B pass newly added parameter keSeqnum in SP InvtAvailableFGILocationView as ''     
            EXEC InvtAvailableFGILocationView @uniq_key ,@wono,0,''     
    --  end      
        
           
  END 