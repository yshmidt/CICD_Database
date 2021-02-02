CREATE TABLE [dbo].[WOENTRY] (
    [WONO]             CHAR (10)        CONSTRAINT [DF__WOENTRY__WONO__4B03CA61] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]         CHAR (10)        CONSTRAINT [DF__WOENTRY__UNIQ_KE__4BF7EE9A] DEFAULT ('') NOT NULL,
    [OPENCLOS]         CHAR (10)        CONSTRAINT [DF__WOENTRY__OPENCLO__4CEC12D3] DEFAULT ('') NOT NULL,
    [ORDERDATE]        SMALLDATETIME    NULL,
    [DUE_DATE]         SMALLDATETIME    NULL,
    [AUDPLACE]         CHAR (9)         CONSTRAINT [DF__WOENTRY__AUDPLAC__4DE0370C] DEFAULT ('') NOT NULL,
    [BLDQTY]           NUMERIC (7)      CONSTRAINT [DF__WOENTRY__BLDQTY__4ED45B45] DEFAULT ((0)) NOT NULL,
    [COMPLETE]         NUMERIC (7)      CONSTRAINT [DF__WOENTRY__COMPLET__4FC87F7E] DEFAULT ((0)) NOT NULL,
    [BALANCE]          NUMERIC (7)      CONSTRAINT [DF__WOENTRY__BALANCE__50BCA3B7] DEFAULT ((0)) NOT NULL,
    [WONOTE]           TEXT             CONSTRAINT [DF__WOENTRY__WONOTE__51B0C7F0] DEFAULT ('') NOT NULL,
    [IS_CLOSED]        BIT              CONSTRAINT [DF__WOENTRY__IS_CLOS__52A4EC29] DEFAULT ((0)) NOT NULL,
    [DATECHG]          SMALLDATETIME    NULL,
    [PLANTNO]          CHAR (12)        CONSTRAINT [DF__WOENTRY__PLANTNO__53991062] DEFAULT ('') NOT NULL,
    [AUDBY]            CHAR (3)         CONSTRAINT [DF__WOENTRY__AUDBY__548D349B] DEFAULT ('') NOT NULL,
    [AUDDATE]          SMALLDATETIME    NULL,
    [MATL_CK]          CHAR (3)         CONSTRAINT [DF__WOENTRY__MATL_CK__558158D4] DEFAULT ('') NOT NULL,
    [ENGR_CK]          CHAR (3)         CONSTRAINT [DF__WOENTRY__ENGR_CK__56757D0D] DEFAULT ('') NOT NULL,
    [QLTY_CK]          CHAR (3)         CONSTRAINT [DF__WOENTRY__QLTY_CK__5769A146] DEFAULT ('') NOT NULL,
    [SALE_CK]          CHAR (3)         CONSTRAINT [DF__WOENTRY__SALE_CK__585DC57F] DEFAULT ('') NOT NULL,
    [KIT_NOTE]         TEXT             CONSTRAINT [DF__WOENTRY__KIT_NOT__5951E9B8] DEFAULT ('') NOT NULL,
    [MRP_DONE]         BIT              CONSTRAINT [DF__WOENTRY__MRP_DON__5A460DF1] DEFAULT ((0)) NOT NULL,
    [ORD_TYPE]         CHAR (8)         CONSTRAINT [DF__WOENTRY__ORD_TYP__5B3A322A] DEFAULT ('') NOT NULL,
    [MAT_REQ_DT]       SMALLDATETIME    NULL,
    [MAT_REQ_Q]        NUMERIC (8)      CONSTRAINT [DF__WOENTRY__MAT_REQ__5C2E5663] DEFAULT ((0)) NOT NULL,
    [MAT_REQ_D]        CHAR (2)         CONSTRAINT [DF__WOENTRY__MAT_REQ__5D227A9C] DEFAULT ('') NOT NULL,
    [PROD_TIME]        NUMERIC (3)      CONSTRAINT [DF__WOENTRY__PROD_TI__5E169ED5] DEFAULT ((0)) NOT NULL,
    [TTSETPTIME]       NUMERIC (7)      CONSTRAINT [DF__WOENTRY__TTSETPT__5F0AC30E] DEFAULT ((0)) NOT NULL,
    [ISSUED]           BIT              CONSTRAINT [DF__WOENTRY__ISSUED__5FFEE747] DEFAULT ((0)) NOT NULL,
    [ENG_APPR]         BIT              CONSTRAINT [DF__WOENTRY__ENG_APP__60F30B80] DEFAULT ((0)) NOT NULL,
    [ENG_APPD]         SMALLDATETIME    NULL,
    [ENG_APPT]         CHAR (8)         CONSTRAINT [DF__WOENTRY__ENG_APP__61E72FB9] DEFAULT ('') NOT NULL,
    [ENG_APPI]         CHAR (3)         CONSTRAINT [DF__WOENTRY__ENG_APP__62DB53F2] DEFAULT ('') NOT NULL,
    [SHFLNOTE]         TEXT             CONSTRAINT [DF__WOENTRY__SHFLNOT__63CF782B] DEFAULT ('') NOT NULL,
    [ORIG_DUEDT]       SMALLDATETIME    NULL,
    [BUILDABLE]        NUMERIC (7)      CONSTRAINT [DF__WOENTRY__BUILDAB__64C39C64] DEFAULT ((0)) NOT NULL,
    [SCHED_FB]         NUMERIC (1)      CONSTRAINT [DF__WOENTRY__SCHED_F__65B7C09D] DEFAULT ((0)) NOT NULL,
    [IS_ALLOC]         BIT              CONSTRAINT [DF__WOENTRY__IS_ALLO__66ABE4D6] DEFAULT ((0)) NOT NULL,
    [KITSTATUS]        CHAR (10)        CONSTRAINT [DF__WOENTRY__KITSTAT__67A0090F] DEFAULT ('') NOT NULL,
    [KITCLOSEDT]       SMALLDATETIME    NULL,
    [START_DATE]       SMALLDATETIME    NULL,
    [CUSTNO]           CHAR (10)        CONSTRAINT [DF__WOENTRY__CUSTNO__68942D48] DEFAULT ('') NOT NULL,
    [SONO]             CHAR (10)        CONSTRAINT [DF__WOENTRY__SONO__69885181] DEFAULT ('') NOT NULL,
    [KIT]              BIT              CONSTRAINT [DF__WOENTRY__KIT__6A7C75BA] DEFAULT ((0)) NOT NULL,
    [SHTGNOTE]         TEXT             CONSTRAINT [DF__WOENTRY__SHTGNOT__6B7099F3] DEFAULT ('') NOT NULL,
    [RELEDATE]         SMALLDATETIME    NULL,
    [SERIALYES]        BIT              CONSTRAINT [DF__WOENTRY__SERIALY__6C64BE2C] DEFAULT ((0)) NOT NULL,
    [UNIQUELN]         CHAR (10)        CONSTRAINT [DF__WOENTRY__UNIQUEL__6D58E265] DEFAULT ('') NOT NULL,
    [GLDIVNO]          CHAR (2)         CONSTRAINT [DF__WOENTRY__GLDIVNO__6E4D069E] DEFAULT ('') NOT NULL,
    [CMPRICELNK]       CHAR (10)        CONSTRAINT [DF__WOENTRY__CMPRICE__6F412AD7] DEFAULT ('') NOT NULL,
    [EACHQTY]          NUMERIC (9, 2)   CONSTRAINT [DF__WOENTRY__EACHQTY__70354F10] DEFAULT ((0)) NOT NULL,
    [FSTDUEDT]         SMALLDATETIME    NULL,
    [DELIFREQ]         CHAR (2)         CONSTRAINT [DF__WOENTRY__DELIFRE__71297349] DEFAULT ('') NOT NULL,
    [PRJUNIQUE]        CHAR (10)        CONSTRAINT [DF__WOENTRY__PRJUNIQ__721D9782] DEFAULT ('') NOT NULL,
    [ARCSTAT]          CHAR (10)        CONSTRAINT [DF__WOENTRY__ARCSTAT__7311BBBB] DEFAULT ('') NOT NULL,
    [SQCSTATUS]        CHAR (10)        CONSTRAINT [DF__WOENTRY__SQCSTAT__7405DFF4] DEFAULT ('') NOT NULL,
    [KITLSTCHDT]       SMALLDATETIME    NULL,
    [KITLSTCHINIT]     CHAR (8)         CONSTRAINT [DF__WOENTRY__KITLSTC__74FA042D] DEFAULT ('') NULL,
    [MRPONHOLD]        BIT              CONSTRAINT [DF__WOENTRY__MRPONHO__75EE2866] DEFAULT ((0)) NOT NULL,
    [COMPLETEDT]       SMALLDATETIME    NULL,
    [KITSTARTINIT]     CHAR (8)         CONSTRAINT [DF__WOENTRY__KITSTAR__76E24C9F] DEFAULT ('') NULL,
    [KITCLOSEINIT]     CHAR (8)         CONSTRAINT [DF__WOENTRY__KITCLOS__77D670D8] DEFAULT ('') NULL,
    [KITCOMPLETE]      BIT              CONSTRAINT [DF__WOENTRY__KITCOMP__78CA9511] DEFAULT ((0)) NOT NULL,
    [KITCOMPLDT]       SMALLDATETIME    NULL,
    [KITCOMPLINIT]     CHAR (8)         CONSTRAINT [DF__WOENTRY__KITCOMP__79BEB94A] DEFAULT ('') NULL,
    [LFCSTITEM]        BIT              CONSTRAINT [DF__WOENTRY__LFCSTIT__7AB2DD83] DEFAULT ((0)) NOT NULL,
    [LIS_RWK]          BIT              CONSTRAINT [DF__WOENTRY__LIS_RWK__7BA701BC] DEFAULT ((0)) NOT NULL,
    [inLastMrp]        BIT              CONSTRAINT [DF_WOENTRY_inLastMrp] DEFAULT ((0)) NOT NULL,
    [JobType]          CHAR (10)        NULL,
    [uniquerout]       CHAR (10)        CONSTRAINT [DF__WOENTRY__uniquer__4FE0BB73] DEFAULT ('') NOT NULL,
    [ClosedBy]         UNIQUEIDENTIFIER CONSTRAINT [DF_woentry_ClosedBy] DEFAULT (NULL) NULL,
    [ReleasedBy]       UNIQUEIDENTIFIER NULL,
    [RoutingChk]       BIT              CONSTRAINT [DF__WOENTRY__Routing__0EF20DB6] DEFAULT ((0)) NOT NULL,
    [WrkInstChk]       BIT              CONSTRAINT [DF__WOENTRY__WrkInst__0FE631EF] DEFAULT ((0)) NOT NULL,
    [BOMChk]           BIT              CONSTRAINT [DF__WOENTRY__BOMChk__10DA5628] DEFAULT ((0)) NOT NULL,
    [ECOChk]           BIT              CONSTRAINT [DF__WOENTRY__ECOChk__11CE7A61] DEFAULT ((0)) NOT NULL,
    [EquipmentChk]     BIT              CONSTRAINT [DF__WOENTRY__Equipme__12C29E9A] DEFAULT ((0)) NOT NULL,
    [ToolsChk]         BIT              CONSTRAINT [DF__WOENTRY__ToolsCh__13B6C2D3] DEFAULT ((0)) NOT NULL,
    [RoutingChkDate]   DATETIME         NULL,
    [RoutingChkBy]     NVARCHAR (256)   NULL,
    [WrkInstChkDate]   DATETIME         NULL,
    [WrkInstChkBy]     NVARCHAR (256)   NULL,
    [BOMChkDate]       DATETIME         NULL,
    [BOMChkBy]         NVARCHAR (256)   NULL,
    [ECOChkDate]       DATETIME         NULL,
    [ECOChkBy]         NVARCHAR (256)   NULL,
    [EquipmentChkDate] DATETIME         NULL,
    [EquipmentChkBy]   NVARCHAR (256)   NULL,
    [ToolsChkDate]     DATETIME         NULL,
    [ToolsChkBy]       NVARCHAR (256)   NULL,
    [CreatedByUserId]  UNIQUEIDENTIFIER NULL,
    [KitUniqwh]        CHAR (10)        CONSTRAINT [DF_WOENTRY_KitUniqwh] DEFAULT ('') NOT NULL,
    [KitCloseUserId]   UNIQUEIDENTIFIER CONSTRAINT [DF__WOENTRY__KitClos__41694A41] DEFAULT (NULL) NULL,
    [KitReOpenUserId]  UNIQUEIDENTIFIER CONSTRAINT [DF__WOENTRY__KitReOp__425D6E7A] DEFAULT (NULL) NULL,
    CONSTRAINT [WOENTRY_PK] PRIMARY KEY CLUSTERED ([WONO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [<Name of Missing Index, sysname,>]
    ON [dbo].[WOENTRY]([OPENCLOS] ASC)
    INCLUDE([WONO], [UNIQ_KEY]);


GO
CREATE NONCLUSTERED INDEX [CUSTNO]
    ON [dbo].[WOENTRY]([CUSTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [OPENCLOS]
    ON [dbo].[WOENTRY]([OPENCLOS] ASC);


GO
CREATE NONCLUSTERED INDEX [ORDERDATE]
    ON [dbo].[WOENTRY]([ORDERDATE] ASC);


GO
CREATE NONCLUSTERED INDEX [PARTNOREV]
    ON [dbo].[WOENTRY]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [PLANTNO]
    ON [dbo].[WOENTRY]([PLANTNO] ASC);


GO
CREATE NONCLUSTERED INDEX [PRJUNIQUE]
    ON [dbo].[WOENTRY]([PRJUNIQUE] ASC);


GO
CREATE NONCLUSTERED INDEX [SONO]
    ON [dbo].[WOENTRY]([SONO] ASC);


GO
CREATE NONCLUSTERED INDEX [SONOUKUL]
    ON [dbo].[WOENTRY]([SONO] ASC, [UNIQ_KEY] ASC, [UNIQUELN] ASC);


GO
-- =======================================================================================================================================  
-- Author:  <Vicky Lu>  
-- Create date: <02/25/2010>  
-- Description: <Update associated tables when Woentry is inserted a new record>  
-- 10/15/15 VL Added 'RWRK' and 'RWQC' to quotdept and dept_qty even user never goes to routing (those 2 WCs are added there)  
-- 09/12/2017 Sachin B Add temporary condition and uniqueRout ='' becuase cureently it used all the rout of template also  
-- 09/27/2017 Shripati U :-Changed the name from uniqueRout to Uniquerout  
-- 01/19/2018 Shripati U :- Uniquerout should be mandatory while creating the Work Order   
-- 01/19/2018 Shripati U :- Insert WoCheckList table while creating work order  
-- 01/29/2018 Shripati U :- Insert into WOTools and WOEquipments table while creating work order   
-- 02/06/2018 Shripati U : Increased the 'Chklst_tit' (column) length of @ZWrkCkLst table also Increased @lcChklst_tit variable size  
-- 03/08/2018 Sachin B : Add IsAssemblyAdded flag value true in WoCheckList,WOTools and WOEquipments table  
-- 03/28/18   YS Have to be able to run with the new Uniquerout column empty.   
---Work order created from Sales order for example. Current sales order module in the desktop   
--- Modified the code that saves dept_qty records and when no records in the quotdept table find default template   
-- create default templat if none is available  
-- need testing and need aspnet userid for the person who created work order  
-- 03/29/18 Sachin B Remove the Unused Parameters and table from Declaration  
-- 03/29/18 Sachin B Remove the Commented Code from the Trigger  
-- 03/29/18 Sachin B Add parameter @UserId and put this value in UserId in RoutingTemplate table  
-- 03/29/18 Sachin B Add try catch block for exception handaling  
-- 04/03/18 Sachin B Add parameter @OrderCreationDate and put this value in updatedate column in routingtemplate  
-- 04/04/18 Sachin B Set SERIALSTRT Column of Quotdept table where DEPT_ID ='STAG'  
-- 04/11/2019 Sachin B Insert the Assembly Added tools to Work Order  
-- 04/04/19 Sachin B Insert ToolId in the WOTools Table  
-- 05/27/19 Sachin B Insert IsOptional in the DEPT_QTY table  
-- 08/27/2019 Satyawan H Update the uniqroute column of woentry table if Quotdept records for uniq_key found  
-- 08/28/19 Satyawan H removed select line for adding cursor  
-- 08/28/19 Satyawan H Added cursor to the inserted records for bulk WO record insert.  
-- 08/11/2020 Sachin B Put the Newly Added Column data in WO Tools Table
-- =======================================================================================================================================  
CREATE TRIGGER [dbo].[Woentry_Insert] ON  [dbo].[WOENTRY]   
AFTER INSERT  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
    -- Insert statements for trigger here  
 --03/28/18 YS added jobtype to be able to find default routing based on the job type  
 -- 03/29/18 Sachin B Remove the Unused Parameters and table from Declaration  
 DECLARE @lcUniq_Key CHAR(10), @lcWono CHAR(10), @lnBldQty NUMERIC(7,0),@lcNewUniqNbr CHAR(10), @lcTestNo CHAR(10),  
   @lcShopfl_chk CHAR(25), @lcDept_activ CHAR(4), @lcUniqnumber2 CHAR(10), @lnNumber2 NUMERIC(4,0), @lcChklst_tit CHAR(100), @Uniqnbra2 CHAR(10),  
   @llSerialYes bit, @lcChkUniqNumber CHAR(10),@Uniquerout CHAR(10),-- 09/27/2017 Shripati U Changed the name from uniqueRout to Uniquerout  
   -- 03/29/18 Sachin B Add parameter @UserId and put this value in UserId in RoutingTemplate table  
   @Jobtype CHAR(10),@lnCount3 INT, @lnCount4 INT, @lnTotalNo3 INT, @lnTotalNo4 INT, @templateId INT,@UserId UNIQUEIDENTIFIER,  
   -- 04/03/18 Sachin B Add parameter @OrderCreationDate and put this value in updatedate column in routingtemplate  
   @OrderCreationDate DATETIME, @IsOptional BIT;   
        
 --03/28/18 YS added uniquerout column to @ZQuotDept   
 -- 03/29/18 Sachin B Remove the Unused Parameters and table from Declaration  
 -- 05/27/19 Sachin B Insert IsOptional in the DEPT_QTY table  
 DECLARE @ZQuotDept TABLE (nRecno INT IDENTITY, Dept_id CHAR(4), Number NUMERIC(4,0), UniqNumber CHAR(10), SerialStrt BIT,uniqueRout CHAR(10), IsOptional BIT);   
 DECLARE @ZAssyChk TABLE (nRecno INT IDENTITY, Uniq_key CHAR(10), Shopfl_chk CHAR(25));   
 DECLARE @ZWrkCkLst TABLE (nRecno INT IDENTITY, Dept_activ CHAR(4), Uniqnumber CHAR(10), Number NUMERIC(4,0), Chklst_tit CHAR(100), Uniqnbra CHAR(10));   
  
 -- 03/29/18 Sachin B Add try catch block for exception handaling  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
  
BEGIN TRY    
BEGIN TRANSACTION   
  
   
 --03/28/18 YS added jobtype to be able to find default routing based on the job type  
 -- 08/28/19 Satyawan H removed select line for adding cursor  
 --SELECT @lcUniq_Key = Uniq_key, @lcWono = Wono, @lnBldQty = BldQty, @llSerialYes = SerialYes, @Uniquerout = Uniquerout,@Jobtype=JobType,  
 --@UserId= CreatedByUserId,@OrderCreationDate =ORDERDATE FROM INSERTED;  
  
 -- 08/28/19 Satyawan H Added cursor to the inserted records for bulk WO record insert.  
 DECLARE wo_cursor CURSOR FAST_FORWARD   
 FOR SELECT Uniq_key, Wono, BldQty, SerialYes, Uniquerout, JobType, CreatedByUserId, ORDERDATE   
 FROM INSERTED ORDER BY WONO  
  
 OPEN wo_cursor    
 FETCH NEXT FROM wo_cursor      
 INTO @lcUniq_Key,@lcWono,@lnBldQty,@llSerialYes,@Uniquerout,@Jobtype,@UserId,@OrderCreationDate  
  
 WHILE @@FETCH_STATUS = 0      
 BEGIN      
  
  
 -- 03/28/18 YS Have to be able to run with the new Uniquerout column empty. Work order created from Sales order for example. Current sales order module in the desktop and it is not aware of the Uniquerout  
 /* YS find match by @uniquerout or if @uniquerout is empty find default routing.   
  need to know if job is rework or not to get the correct default  
  If job type is rework, but fefault rework routing is not exists (backward compatibility) use regular default    
 */  
 -- 05/27/19 Sachin B Insert IsOptional in the DEPT_QTY table  
 Set @Uniquerout = TRIM(@Uniquerout)  
  
 IF @Uniquerout<>''  
 BEGIN  
     INSERT @ZQuotDept  
  SELECT Dept_id, Number, UniqNumber, SerialStrt,uniqueRout,IsOptional  
  FROM QuotDept   
  -- 09/12/2017 Sachin B Add temporary condition and uniqueRout ='' becuase cureently it used all the rout of template also  
  -- 09/27/2017 Shripati U Changed the name from uniqueRout to Uniquerout  
  WHERE Uniq_key = @lcUniq_Key and uniqueRout =@Uniquerout  
  ORDER BY number;  
 END  
   
 IF @Uniquerout='' and @jobtype NOT LIKE '%rework%'  
 BEGIN  
     INSERT @ZQuotDept  
  SELECT Dept_id, Number, UniqNumber, SerialStrt,q.uniqueRout,q.IsOptional  
  FROM QuotDept Q   
  INNER JOIN routingProductSetup s ON q.uniqueRout=s.uniquerout and q.UNIQ_KEY=s.Uniq_key  
  INNER JOIN RoutingTemplate t ON  s.TemplateID=t.TemplateID  
  WHERE q.UNIQ_KEY=@lcUniq_Key AND t.TemplateType='Regular' AND s.isDefault=1 ORDER BY number;  
    END  
  
 IF @Uniquerout='' and @jobtype  LIKE '%rework%'  
 BEGIN   
     INSERT @ZQuotDept          
  SELECT Dept_id, Number, UniqNumber,SerialStrt,q.uniqueRout,q.IsOptional  
  FROM QuotDept Q   
  INNER JOIN routingProductSetup s ON q.uniqueRout=s.uniquerout AND q.UNIQ_KEY=s.Uniq_key  
  INNER JOIN RoutingTemplate t ON  s.TemplateID=t.TemplateID  
  WHERE q.UNIQ_KEY=@lcUniq_Key AND t.TemplateType='Rework' AND s.isDefault=1  
    END  
  
 /* -----------------------------------------------*/  
 /* Update Quotdept, Quotdpdt, Dept_Qty, Actv_qty  */  
 /* -----------------------------------------------*/  
  
 /* Get all Quotdept records for this uniq_key */  
  
 IF EXISTS(SELECT 1 FROM @ZQuotDept)  
  /* Find records in QuotDept*/  
  BEGIN  
   --03/28/18 YS old code no need for do while, keep it simple     
   -- 05/27/19 Sachin B Insert IsOptional in the DEPT_QTY table  
   INSERT INTO DEPT_QTY (Wono, Dept_id, Number, Curr_qty, Deptkey, SerialStrt, UniqueRec, IsOptional)  
   SELECT @lcwono AS wono,Dept_id,Number,   
   CASE WHEN Number = 1 THEN @lnBldqty ELSE 0 END as Curr_qty, UniqNumber, SerialStrt, dbo.fn_GenerateUniqueNumber() AS UniqueRec,IsOptional  
   FROM @ZQuotDept   
  
   INSERT INTO Actv_qty (Wono, Activ_id, Numbera, Deptkey, ActvKey, UniqueRecid)   
   SELECT @lcWono AS wono,Activ_id, Numbera, UniqNumber, UniqNbra, dbo.fn_GenerateUniqueNumber() AS UniqueRecid  
   FROM Quotdpdt   
   INNER JOIN dept_qty on quotdpdt.UniqNumber = dept_qty.Deptkey AND Dept_qty.wono=@lcwono   
   WHERE Quotdpdt.Uniq_Key=@lcUniq_Key    
  
   -- 08/27/2019 Satyawan H Update the uniqroute column of woentry table if Quotdept records for uniq_key found  
   IF EXISTS(SELECT 1 uniqueRout FROM @ZQuotDept)  
   BEGIN  
    SET @Uniquerout = (SELECT TOP 1 uniqueRout FROM @ZQuotDept);  
    UPDATE WOENTRY SET uniquerout =@Uniquerout WHERE WONO =@lcWono  
   END   
  END  
 ELSE   --- no records found in quotdept  
 BEGIN  
  
  --- 03/28/18 instead find a default from new template table  
  -- 03/29/18 Sachin B Remove the Commented Code from the Trigger  
  DECLARE @tuniquerout TABLE (uniquerout CHAR(10))  
  
  --check if Regular template exists      
  IF @Jobtype NOT LIKE '%rework%'  
    BEGIN  
     IF NOT EXISTS (SELECT 1 FROM RoutingTemplate T WHERE t.TemplateType='Regular' AND t.IsDefault=1)  
    BEGIN  
     --- add template with 5 hardcoded WC  
     ---!!! need userid  
     -- 03/29/18 Sachin B Add parameter @UserId and put this value in UserId in RoutingTemplate table  
     -- 04/03/18 Sachin B Add parameter @OrderCreationDate and put this value in updatedate column in routingtemplate  
     INSERT INTO RoutingTemplate (TemplateName,TemplateType,IsDefault,UserId,UpdateDate)  
     VALUES ('MNX Template','Regular',1,@UserId,@OrderCreationDate)  
   
     INSERT INTO RoutingTemplateDetail (TemplateId,DeptId,SequenceNo)  
     SELECT TemplateID,'STAG', 1 FROM RoutingTemplate WHERE TemplateType='Regular' and IsDefault=1  
     UNION  
     SELECT TemplateID,'FGI', 2 FROM RoutingTemplate WHERE TemplateType='Regular' and IsDefault=1  
     UNION  
     SELECT TemplateID,'RWRK', 3 FROM RoutingTemplate WHERE TemplateType='Regular' and IsDefault=1  
     UNION   
     SELECT TemplateID, 'RWQC', 4 FROM RoutingTemplate WHERE TemplateType='Regular' and IsDefault=1  
     UNION  
     SELECT TemplateID, 'SCRP', 5 FROM RoutingTemplate WHERE TemplateType='Regular' and IsDefault=1     
  
     INSERT INTO routingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID)  
     OUTPUT inserted.uniquerout INTO @tuniquerout  
     SELECT @lcUniq_Key AS uniq_key,dbo.fn_GenerateUniqueNumber() AS uniquerout,1 AS isdefault,templateid   
     FROM RoutingTemplate T WHERE t.TemplateType='Regular' AND t.IsDefault=1  
        
     INSERT INTO Quotdept  (UNIQ_KEY,dept_id,Number,uniqueRout,UniqNumber)  
     SELECT t.Uniq_key,d.DeptId,D.SequenceNo,t.uniquerout,dbo.fn_GenerateUniqueNumber() AS UniqNumber  
     FROM routingProductSetup T   
     INNER JOIN RoutingTemplateDetail D ON t.TemplateID=d.TemplateId  
     INNER JOIN @tuniquerout K ON t.uniquerout=k.uniquerout  
  
     -- 04/04/18 Sachin B  Set SERIALSTRT Column of Quotdept table where DEPT_ID ='STAG'  
     UPDATE qo  
     SET qo.SERIALSTRT = @llSerialYes  
     FROM Quotdept qo  
     JOIN @tuniquerout gm ON qo.uniqueRout= gm.uniqueRout   
     WHERE qo.DEPT_ID ='STAG'  
  
    END -- IF NOT EXISTS (select 1 from RoutingTemplate T where t.TemplateType='Regular' and t.IsDefault=1)  
    ELSE  
       BEGIN  
     --- find regular template and create product template     
     INSERT INTO routingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID)  
     OUTPUT inserted.uniquerout INTO @tuniquerout  
     SELECT @lcUniq_Key AS uniq_key,dbo.fn_GenerateUniqueNumber() AS uniquerout,1 AS isdefault,templateid   
     FROM RoutingTemplate T WHERE t.TemplateType='Regular' and t.IsDefault=1  
        
     INSERT INTO Quotdept  (UNIQ_KEY,dept_id,Number,uniqueRout,UniqNumber)  
     SELECT t.Uniq_key,d.DeptId,D.SequenceNo,t.uniquerout,dbo.fn_GenerateUniqueNumber() AS UniqNumber  
     FROM routingProductSetup T   
     INNER JOIN RoutingTemplateDetail D ON t.TemplateID=d.TemplateId  
     INNER JOIN @tuniquerout K ON t.uniquerout=k.uniquerout  
  
     -- 04/04/18 Sachin B  Set SERIALSTRT Column of Quotdept table where DEPT_ID ='STAG'  
     UPDATE qo  
     SET qo.SERIALSTRT = @llSerialYes  
     FROM Quotdept qo  
     JOIN @tuniquerout gm ON qo.uniqueRout= gm.uniqueRout   
     WHERE qo.DEPT_ID ='STAG'  
    END   
     END --- if @Jobtype not like '%rework%'    
  
  IF @Jobtype LIKE '%rework%'       
    BEGIN  
   IF NOT EXISTS (SELECT 1 FROM RoutingTemplate T WHERE t.TemplateType='Rework' AND t.IsDefault=1)  
    BEGIN  
     --- add template with 5 hardcoded WC  
     ---!!! need userid  
     -- 03/29/18 Sachin B Add parameter @UserId and put this value in UserId in RoutingTemplate table  
     -- 04/03/18 Sachin B Add parameter @OrderCreationDate and put this value in updatedate column in routingtemplate  
     INSERT INTO RoutingTemplate (TemplateName,TemplateType,IsDefault,UserId,UpdateDate)  
     VALUES ('MNX Rework Template','Rework',1,@UserId,@OrderCreationDate)  
   
     INSERT INTO RoutingTemplateDetail (TemplateId,DeptId,SequenceNo)  
     SELECT TemplateID,'STAG', 1 FROM RoutingTemplate WHERE TemplateType='Rework' and IsDefault=1  
     UNION  
     SELECT TemplateID,'FGI', 2 FROM RoutingTemplate WHERE TemplateType='Rework' and IsDefault=1  
     UNION  
     SELECT TemplateID,'RWRK', 3 FROM RoutingTemplate WHERE TemplateType='Rework' and IsDefault=1  
     UNION   
     SELECT TemplateID, 'RWQC', 4 FROM RoutingTemplate WHERE TemplateType='Rework' and IsDefault=1  
     UNION  
     SELECT TemplateID, 'SCRP', 5 FROM RoutingTemplate WHERE TemplateType='Rework' and IsDefault=1     
  
     INSERT INTO routingProductSetup (Uniq_key,uniquerout,isDefault,TemplateID)  
     OUTPUT inserted.uniquerout INTO @tuniquerout  
     SELECT @lcUniq_Key AS uniq_key,dbo.fn_GenerateUniqueNumber() AS uniquerout,1 AS isdefault,templateid   
     FROM RoutingTemplate T WHERE t.TemplateType='Rework' AND t.IsDefault=1  
        
     INSERT INTO Quotdept  (UNIQ_KEY,dept_id,Number,uniqueRout,UniqNumber)  
     SELECT t.Uniq_key,d.DeptId,D.SequenceNo,t.uniquerout,dbo.fn_GenerateUniqueNumber() AS UniqNumber  
     FROM routingProductSetup T   
     INNER JOIN RoutingTemplateDetail D ON t.TemplateID=d.TemplateId  
     INNER JOIN @tuniquerout K ON t.uniquerout=k.uniquerout  
  
     -- 04/04/18 Sachin B  Set SERIALSTRT Column of Quotdept table where DEPT_ID ='STAG'  
     UPDATE qo  
     SET qo.SERIALSTRT = @llSerialYes  
     FROM Quotdept qo  
     JOIN @tuniquerout gm ON qo.uniqueRout= gm.uniqueRout   
     WHERE qo.DEPT_ID ='STAG'  
  
     END -- IF NOT EXISTS (select 1 from RoutingTemplate T where t.TemplateType='Rework' and t.IsDefault=1)  
     ELSE  
    BEGIN  
     INSERT INTO routingProductSetup (Uniq_key,isDefault,TemplateID,uniquerout)  
     OUTPUT inserted.uniquerout INTO @tuniquerout  
     SELECT @lcUniq_Key AS uniq_key,1 AS isdefault,templateid ,dbo.fn_GenerateUniqueNumber()  
     FROM RoutingTemplate T WHERE t.TemplateType='Rework' AND t.IsDefault=1  
               
     INSERT INTO Quotdept (UNIQ_KEY,dept_id,Number,uniqueRout,UniqNumber)  
     SELECT t.Uniq_key,d.DeptId,D.SequenceNo,t.uniquerout,dbo.fn_GenerateUniqueNumber() AS UniqNumber  
     FROM routingProductSetup T   
     INNER JOIN RoutingTemplateDetail D ON t.TemplateID=d.TemplateId  
     INNER JOIN @tuniquerout K ON t.uniquerout=k.uniquerout  
  
     -- 04/04/18 Sachin B  Set SERIALSTRT Column of Quotdept table where DEPT_ID ='STAG'  
     UPDATE qo  
     SET qo.SERIALSTRT = @llSerialYes  
     FROM Quotdept qo  
     JOIN @tuniquerout gm ON qo.uniqueRout= gm.uniqueRout   
     WHERE qo.DEPT_ID ='STAG'  
    END   
   END --- if @Jobtype like '%rework%'   
    
   --- 03/28/18 YS now insert into dept_qty  
   -- 05/27/19 Sachin B Insert IsOptional in the DEPT_QTY table  
   INSERT INTO DEPT_QTY (Wono, Dept_id, Number, Curr_qty, Deptkey, SerialStrt, UniqueRec, IsOptional)  
   SELECT @lcwono AS wono,Dept_id,Number,CASE WHEN Number = 1 THEN @lnBldqty ELSE 0 END AS Curr_qty, UniqNumber, SerialStrt, dbo.fn_GenerateUniqueNumber() AS UniqueRec,IsOptional   
   FROM QuotDept WHERE UNIQ_KEY=@lcUniq_Key AND EXISTS (SELECT 1 FROM  @tuniquerout t WHERE t.uniquerout=QUOTDEPT.uniqueRout)  
  
   --Update the uniqroute column of woentry table  
   IF EXISTS(SELECT 1 uniqueRout FROM @tuniquerout)  
   BEGIN  
   SET @Uniquerout = (SELECT TOP 1 uniqueRout FROM @tuniquerout);  
   UPDATE WOENTRY SET uniquerout =@Uniquerout WHERE WONO =@lcWono  
   END         
 END --- no records found in quotdept  
  
 -- 09/12/11 VL added to update Dept_qty.SerialStrt if the WO is serialized to prevent incorrect update in   
 -- other places (like SN import utility)  
 IF @llSerialYes = 1  
 BEGIN  
     -- 09/12/2017 Sachin B Add temporary condition and uniqueRout ='' becuase cureently it used all the rout of template also  
  -- 01/19/2018 Shripati U :- Uniquerout should be mandatory while creating the Work Order   
  SELECT @lcChkUniqNumber = UniqNumber FROM QuotDept WHERE Uniq_key = @lcUniq_Key AND SerialStrt = 1 and uniqueRout =@Uniquerout  
  IF @@ROWCOUNT = 0 -- No serial number starting WC was found for this serialized part, will choose STAG as starting WC  
   UPDATE Dept_qty SET SerialStrt = 1 WHERE Wono = @lcWono AND Dept_id = 'STAG'    
 END  
   
 /* -------------------------------------------------*/  
 /* Update Assychk         */  
 /* -------------------------------------------------*/  
 INSERT @ZAssyChk  
  SELECT Uniq_key, Shopfl_chk  
   FROM AssyChk  
   WHERE Uniq_key = @lcUniq_Key;  
 SET @lnTotalNo3 = @@ROWCOUNT  
 IF (@lnTotalNo3 > 0)  
  BEGIN   
   SET @lnCount3=0;  
   WHILE @lnTotalNo3>@lnCount3  
   BEGIN   
    SET @lnCount3=@lnCount3+1;  
    SELECT @lcShopfl_chk = Shopfl_chk  
     FROM @ZAssyChk WHERE nRecno = @lnCount3;  
    IF (@@ROWCOUNT<>0)  
     BEGIN  
     WHILE (1=1)  
     BEGIN  
      EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT  
      SELECT @lcTestNo = JbShpChkUk FROM JbShpChk WHERE JbShpChkUk = @lcNewUniqNbr  
      IF (@@ROWCOUNT<>0)  
       CONTINUE  
      ELSE  
       BREAK  
     END   
     INSERT INTO JbShpChk (Wono, Shopfl_chk, JbShpchkUk)   
      VALUES (@lcWono, @lcShopfl_chk,@lcNewUniqNbr)  
     END  
   END  
  END  
  
 /* -------------------------------------------------*/  
 /* Update JShpChkL         */  
 /* -------------------------------------------------*/  
 INSERT @ZWrkCkLst  
  SELECT Dept_activ, Uniqnumber, Number, Chklst_tit, Uniqnbra  
   FROM WrkCkLst  
   WHERE Uniq_key = @lcUniq_Key;  
 SET @lnTotalNo4 = @@ROWCOUNT  
 IF (@lnTotalNo4 > 0)  
  BEGIN   
   SET @lnCount4=0;  
   WHILE @lnTotalNo4>@lnCount4  
   BEGIN   
    SET @lnCount4=@lnCount4+1;  
    SELECT @lcDept_activ = Dept_activ,  
      @lcUniqnumber2 = Uniqnumber,  
      @lnNumber2 = Number,  
      @lcChklst_tit = Chklst_tit,  
      @Uniqnbra2 = Uniqnbra  
     FROM @ZWrkCkLst WHERE nRecno = @lnCount4;  
  
    IF (@@ROWCOUNT<>0)  
     BEGIN  
     WHILE (1=1)  
     BEGIN  
      EXEC sp_GenerateUniqueValue @lcNewUniqNbr OUTPUT  
      SELECT @lcTestNo = JshpchkUk FROM JShpChkL WHERE JshpchkUk = @lcNewUniqNbr  
      IF (@@ROWCOUNT<>0)  
       CONTINUE  
      ELSE  
       BREAK  
     END   
     INSERT INTO JShpChkL (Wono, Dept_activ, Number, ChkLst_tit, Deptkey, Uniqnbra, JshpChkUk)  
      VALUES (@lcWono, @lcDept_activ, @lnNumber2, @lcChklst_tit, @lcUniqnumber2, @Uniqnbra2, @lcNewUniqNbr)  
     END  
   END  
  END  
    -- 03/08/2018 Sachin B : Add IsAssemblyAdded flag value true in WoCheckList,WOTools and WOEquipments table  
    /* -------------------------------------------------*/  
 /* Insert into WoCheckList table */      
 /* 01/19/2018 Shripati U :- Insert into WoCheckList table while creating work order */  
 /* -------------------------------------------------*/  
    SELECT @templateId = TemplateId  FROM routingProductSetup WHERE Uniq_key =@lcUniq_Key AND uniquerout =@Uniquerout  
  
 INSERT INTO WoCheckList(Dept_ID,Wono,Description,UniqueNumber,TemplateId,WOCheckPriority,IsAssemblyAdded)   
 SELECT Dept_activ,@lcWono,Chklst_tit,UNIQNUMBER,@templateId,wccheckpriority,1  
  FROM WRKCKLST WHERE Uniq_key =@lcUniq_Key AND TemplateId =@templateId   
  
 /* -------------------------------------------------*/  
 /* Insert into WOTOOLS table */      
 /*  01/29/2018 Shripati U :- Insert into WOTOOLS and WOEquipments table while creating work order */   
 /* -------------------------------------------------*/  
 -- 04/04/19 Sachin B Insert ToolId in the WOTools Table  
 -- 08/11/2020 Sachin B Put the Newly Added Column data in WO Tools Table
	INSERT INTO WOTools
	(Dept_Id,WONO,[Description],UniqueNumber,TemplateId, WOToolPriority,ToolsAndFixtureId,IsAssemblyAdded,ToolId,Location,ToolSerialNumber,ToolCustomerID,DateofPurchase,ExpirationDate)  
		SELECT t.DEPT_ID,@lcWono,tf.[Description],UNIQNUMBER,TemplateId,tf.ToolsFixturePriority,tf.ToolsAndFixtureId,1,NULL,t.Location,t.ToolSerialNumber,t.ToolCustomerID,t.DateofPurchase,t.ExpirationDate
		FROM TOOLING t 
		INNER JOIN ToolsAndFixtures tf ON t.ToolsAndFixtureId =tf.ToolsAndFixtureId
		WHERE t.UNIQ_KEY=@lcUniq_Key AND t.TemplateId =@templateId 
    -- 04/11/2019 Sachin B Insert the Assembly Added tools to Work Order
	UNION
		SELECT t.DEPT_ID,@lcWono,t.[Description],UNIQNUMBER,TemplateId,0,t.ToolsAndFixtureId,1,t.TOOLID,t.Location,t.ToolSerialNumber,t.ToolCustomerID,t.DateofPurchase,t.ExpirationDate 
		FROM TOOLING t 
		WHERE ToolsAndFixtureId IS NULL AND t.UNIQ_KEY=@lcUniq_Key AND t.TemplateId =@templateId
  
    /* -------------------------------------------------*/  
 /* Insert into WoCheckList table */      
 /*  01/29/2018 Shripati U :- Insert into WOTools and WOEquipments table while creating work order */   
 /* -------------------------------------------------*/  
 INSERT INTO WOEquipments(Dept_Id,WONO,Description,UniqueNumber,TemplateId,WOEquipmentPriority,WcEquipmentId,IsAssemblyAdded)  
 SELECT t.DEPT_ID,@lcWono,wc.Equipment, UNIQNUMBER, TemplateId,wc.EquipmentPriority, wc.WcEquipmentId,1  
    FROM Equipment t INNER JOIN WcEquipment wc ON t.WcEquipmentId =wc.WcEquipmentId   
    WHERE t.UNIQ_KEY=@lcUniq_Key AND t.TemplateId =@templateId   
  
 -- Clean all the tables  
 DELETE FROM @ZAssyChk  
 DELETE FROM @ZWrkCkLst  
 DELETE FROM @ZQuotDept  
 DELETE FROM @tuniquerout  
   
 FETCH NEXT FROM wo_cursor      
 INTO @lcUniq_Key,@lcWono,@lnBldQty,@llSerialYes,@Uniquerout,@Jobtype,@UserId,@OrderCreationDate  
     
 END    
 CLOSE wo_cursor;      
 DEALLOCATE wo_cursor;   
END TRY  
BEGIN CATCH  
 IF @@TRANCOUNT <>0  
  ROLLBACK TRAN ;  
  SELECT @ErrorMessage = ERROR_MESSAGE(),  
  @ErrorSeverity = ERROR_SEVERITY(),  
  @ErrorState = ERROR_STATE();  
  RAISERROR (@ErrorMessage, -- Message text.  
            @ErrorSeverity, -- Severity.  
            @ErrorState -- State.  
            );  
  RETURN  
END CATCH  
 -- 03/29/18 Sachin B Add try catch block for exception handaling  
 IF @@TRANCOUNT <>0  
  COMMIT TRANSACTION  
END