CREATE TABLE [dbo].[INVT_ISU] (
    [W_KEY]            CHAR (10)        CONSTRAINT [DF__INVT_ISU__W_KEY__56FEC19B] DEFAULT ('') NOT NULL,
    [UNIQ_KEY]         CHAR (10)        CONSTRAINT [DF__INVT_ISU__UNIQ_K__57F2E5D4] DEFAULT ('') NOT NULL,
    [ISSUEDTO]         CHAR (20)        CONSTRAINT [DF__INVT_ISU__ISSUED__59DB2E46] DEFAULT ('') NOT NULL,
    [QTYISU]           NUMERIC (12, 2)  CONSTRAINT [DF__INVT_ISU__QTYISU__5ACF527F] DEFAULT ((0)) NOT NULL,
    [DATE]             SMALLDATETIME    CONSTRAINT [DF_INVT_ISU_DATE] DEFAULT (getdate()) NULL,
    [U_OF_MEAS]        CHAR (4)         CONSTRAINT [DF__INVT_ISU__U_OF_M__5BC376B8] DEFAULT ('') NOT NULL,
    [GL_NBR]           CHAR (13)        CONSTRAINT [DF__INVT_ISU__GL_NBR__5CB79AF1] DEFAULT ('') NOT NULL,
    [INVTISU_NO]       CHAR (10)        CONSTRAINT [DF__INVT_ISU__INVTIS__5DABBF2A] DEFAULT ([dbo].[fn_generateuniquenumber]()) NOT NULL,
    [GL_NBR_INV]       CHAR (13)        CONSTRAINT [DF__INVT_ISU__GL_NBR__5E9FE363] DEFAULT ('') NOT NULL,
    [WONO]             CHAR (10)        CONSTRAINT [DF__INVT_ISU__WONO__5F94079C] DEFAULT ('') NOT NULL,
    [IS_REL_GL]        BIT              CONSTRAINT [DF__INVT_ISU__IS_REL__60882BD5] DEFAULT ((0)) NOT NULL,
    [STDCOST]          NUMERIC (13, 5)  CONSTRAINT [DF__INVT_ISU__STDCOS__617C500E] DEFAULT ((0)) NOT NULL,
    [LOTCODE]          NVARCHAR (25)    CONSTRAINT [DF__INVT_ISU__LOTCOD__62707447] DEFAULT ('') NOT NULL,
    [EXPDATE]          SMALLDATETIME    NULL,
    [REFERENCE]        CHAR (12)        CONSTRAINT [DF__INVT_ISU__REFERE__63649880] DEFAULT ('') NOT NULL,
    [SAVEINIT]         CHAR (8)         CONSTRAINT [DF__INVT_ISU__SAVEIN__6458BCB9] DEFAULT ('') NOT NULL,
    [PONUM]            CHAR (15)        CONSTRAINT [DF__INVT_ISU__PONUM__6641052B] DEFAULT ('') NOT NULL,
    [TRANSREF]         CHAR (30)        CONSTRAINT [DF__INVT_ISU__TRANSR__691D71D6] DEFAULT ('') NOT NULL,
    [UNIQUELN]         CHAR (10)        CONSTRAINT [DF__INVT_ISU__UNIQUE__6A11960F] DEFAULT ('') NOT NULL,
    [INSTORERETURN]    BIT              CONSTRAINT [DF__INVT_ISU__INSTOR__6B05BA48] DEFAULT ((0)) NOT NULL,
    [DEPTKEY]          CHAR (10)        CONSTRAINT [DF__INVT_ISU__DEPTKE__6BF9DE81] DEFAULT ('') NOT NULL,
    [ACTVKEY]          CHAR (10)        CONSTRAINT [DF__INVT_ISU__ACTVKE__6CEE02BA] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]       CHAR (10)        CONSTRAINT [DF__INVT_ISU__UNIQMF__6DE226F3] DEFAULT ('') NOT NULL,
    [CMODID]           CHAR (1)         CONSTRAINT [DF__INVT_ISU__CMODID__6ED64B2C] DEFAULT ('') NOT NULL,
    [LSKIPUNALLOCCODE] BIT              CONSTRAINT [DF__INVT_ISU__LSKIPU__6FCA6F65] DEFAULT ((0)) NOT NULL,
    [fk_userid]        UNIQUEIDENTIFIER NULL,
    [sourceDev]        CHAR (1)         CONSTRAINT [DF_INVT_ISU_sourceDev] DEFAULT ('D') NOT NULL,
    [kaseqnum]         CHAR (10)        CONSTRAINT [DF_INVT_ISU_kaseqnum] DEFAULT ('') NOT NULL,
    [STDCOSTPR]        NUMERIC (13, 5)  CONSTRAINT [DF__INVT_ISU__STDCOS__21D9F9A1] DEFAULT ((0)) NOT NULL,
    [FUNCFCUSED_UNIQ]  CHAR (10)        CONSTRAINT [DF__INVT_ISU__FUNCFC__22CE1DDA] DEFAULT ('') NOT NULL,
    [PRFCUSED_UNIQ]    CHAR (10)        CONSTRAINT [DF__INVT_ISU__PRFCUS__23C24213] DEFAULT ('') NOT NULL,
    CONSTRAINT [INVT_ISU_PK] PRIMARY KEY CLUSTERED ([INVTISU_NO] ASC)
);


GO
CREATE NONCLUSTERED INDEX [INVOICENO]
    ON [dbo].[INVT_ISU]([ISSUEDTO] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_INVT_ISU_kit]
    ON [dbo].[INVT_ISU]([kaseqnum] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL]
    ON [dbo].[INVT_ISU]([IS_REL_GL] ASC);


GO
CREATE NONCLUSTERED INDEX [IS_REL_GL_NBR]
    ON [dbo].[INVT_ISU]([IS_REL_GL] ASC, [GL_NBR] ASC)
    INCLUDE([W_KEY], [UNIQ_KEY], [ISSUEDTO], [QTYISU], [DATE], [INVTISU_NO], [STDCOST]);


GO
CREATE NONCLUSTERED INDEX [ISSUEDTO]
    ON [dbo].[INVT_ISU]([ISSUEDTO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQ_KEY]
    ON [dbo].[INVT_ISU]([UNIQ_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[INVT_ISU]([UNIQMFGRHD] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQUELN_INCLUDE]
    ON [dbo].[INVT_ISU]([UNIQUELN] ASC)
    INCLUDE([ISSUEDTO], [QTYISU], [INVTISU_NO], [GL_NBR_INV], [STDCOST]);


GO
CREATE NONCLUSTERED INDEX [W_KEY]
    ON [dbo].[INVT_ISU]([W_KEY] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[INVT_ISU]([WONO] ASC);


GO
-- =============================================  
-- Author:  Yelena Shmidt  
-- Create date: 07/19/2010  
-- Description: <Insert trigger for Invt_isu . Start from the top to make sure nothing is missing.>  
-- work my way through converting from 9.6.1  
-- 06/28/11 VL Consider Expdate = NULL, if it's used in SELECT WHERE statement, NULL value won't be found,  
--    Also Fix serial number part and added uniquerec and wono into Kadetail  
-- 03/15/12 VL Fix @lnTotalCount to get right value, also add case for cModid = 'Y' -- cycle count  
-- 04/06/12 VL Added @lcTestSerialUniq to take the value returned from SQL, found a situation that cycle count issue around 5000 records  
--    and it hang.  Found if let the variable took the return value from a SQL solve the issue, also fixed in invtmfgr_update trigger  
-- 04/10/12 VL Fixed an issue that END is put in incorrect place, so if no invt_res records created for wono, it also skips that invt_res for project part  
-- 05/04/12 VL Changed the place of an END, so if part source is not BUY or MAKE, it still go through the updating Invt_res table part  
-- 11/28/12 VL Only insert/update invtlot record if parttype.lotdetail = 1, now inventory module allow user to change lot code tracking to non lot code tracking or vice versa  
-- 11/30/12 VL Found the huge records got Manex hang problem again in KIT, SQLManex got hung if more than 3000 SN invt_isu records are saved, tried to assign the SELECT value into a variable again  
-- 04/15/13 VL Added code to allow SO/PK issue to use PJ allocation if the PJ is assigned in SO  
-- 09/26/13 VL Found the code for updating Kalocate is incorrect, should be if in close kit, no change in pick_qty, otherwise, descease, the code is opposite way  
-- 09/30/13 VL  Found when close kit, there are two kamain with same part number, one with overissued and one is not, or both, sometimes the kalocate might retrn any records because it doesn't have overissue qty or already decresed, just skip the checkingof kalocate  
-- 10/02/13 VL  Found when copy 09/26/13 code , missed a place, fixed again  
-- 02/07/14 YS if reference and ponum was empty when inserting into invt_isu even if the lot code is entered we are loosing the information for the lot code, becuase the insert will remove anything that empty  
 --- and assigning @reference from inserted will produce null. changed to check for null values and replace with empty  
-- 02/12/14 VL  Use @zKamain.Wono, not @lcWono when inserting Kadetail  
-- 06/18/14 VL  Found there is no code about SkipUnallocCode, in some situation, don't need to update invt_res table  
-- 08/13/14 YS  Changes for the IPKEY  
-- 08/15/14 YS  update [DATE] and populate [SAVEINIT] if from ipkey (sourceDev='I') untill we remove saveinit  
-- 08/21/14 VL Realized the changes made on 06/18/14 was incorrect, should only have @lcModId <> 'U'  
-- 10/09/14 YS  replace Invtmfhd table with 2 new tables  
-- 12/04/14 YS update stdcost from inventory  
-- 04/14/15 YS Location length is changed to varchar(256)  
-- 03/14/16 YS Changes to the trigger. We changed when the data is removed from inventory, kiiting will only allocate and SF will issue when assembly is moved from a WC  
-- de-allocate has to be done prior to inserting into the issue  
-- need add back code for rma shipping  
-- 05/23/16 YS added code to populate gl_nbr_inv at the end  
--06/27/16 YS added U_OF_MEAS update  
--- 06/30/16 YS when issue against the kit exclude [ISSUEDTO] like 'FGI-WIP:%'  
--- 07/16/16 Sachin b chnage the code update the Invtmfgr when multiple entry on the Invt_Isu Table  
--- 09/08/16 Sachin b chnage the code update the Kamain when multiple entry on the Invt_Isu Table  
-- 11/04/16 VL Added Presentation currency fields   
-- 01/12/17 VL  added to update PRFcused_uniq and FuncFcused_uniq   
-- 07/31/17   Sachin B  Add group by clause for update the invt_lot table and get sum(i.qtyisu) as qtyisu  
-- 12/28/2018 Sachin B Fix the Invt_Isu Table IS_REL_GL column value 0 Issue  
-- 02/04/2020 Sachin B Fix the Issue to insert data in the PO store Table
-- =============================================  
CREATE TRIGGER [dbo].[INVT_ISUE_INSERT]  
   ON  [dbo].[INVT_ISU]   
   AFTER INSERT  
AS   
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
 -- 03/14/16 YS added error trap  
 DECLARE @ErrorMessage NVARCHAR(4000);  
    DECLARE @ErrorSeverity INT;  
    DECLARE @ErrorState INT;  
 BEGIN TRY  
 BEGIN TRANSACTION  
  -- 03/14/16 YS validate w_key  
  IF NOT EXISTS  
   (SELECT 1 from Invtmfgr inner join Inserted I on i.W_KEY=invtmfgr.w_key)   
  
  BEGIN   
    RAISERROR ('Cannot find a record(s) in the INVTMFGR table to issue from. This operation will be cancelled.', -- Message text.  
       16, -- Severity.  
     1 -- State.  
    );  
  END --NOT EXISTS (SELECT 1 from Invtmfgr...  
      
  --08/13/14 YS find out if lot code is required.   
  -- 08/13/14 YS remove lot detail information if required but not provided create an error and if not required but provide create an error  
  -- 03/14/16 YS changed to use all the records inserted, instead of one by one  
  -- lot code validation  
  if exists (select 1 from inserted Iss inner join Inventor I on iss.UNIQ_KEY=i.uniq_key   
     inner join parttype p on i.part_class=p.PART_CLASS and i.part_type=p.PART_TYPE WHERE   
     (p.LOTDETAIL=1 and (iss.lotcode is null or iss.lotcode=' '))   
      OR (p.LOTDETAIL=0 and  iss.lotcode<>' ' and iss.lotcode is not null))  
  BEGIN  
    
  
   RAISERROR('Problem with Lot Code information. This operation will be cancelled.', -- Message text.  
     16, -- Severity.  
     1 -- State.  
    );  
     
  END -- lot code validation  
    
  -- 08/13/14 YS}  
  --- 03/14/16 YS un-allocate should take place prior (we may need procedure that will receive ipkey and serial numbers and un-allocate and then insert issue or   
  --.net application will do that first  
  -- make sure that if qty deallocated the records in the invtmfgr is not deleted. Which is strange because we should have qty_oh if we have allocated qty  
  update invtmfgr set is_deleted=0 where exists (select 1 from Inserted I where I.w_key=invtmfgr.w_key and i.QTYISU<0)  
  UPDATE InvtMPNLink SET Is_deleted=0 where exists (select 1 from Inserted I where I.uniqmfgrhd=InvtMPNLink.uniqmfgrhd and i.QTYISU<0)  
  --- if Invtlot table has to be updated  
  -- check if if isseud qty are positive and not enough qty_oh-reserved (reserverd should be updated)  
  if exists (select 1 from Inserted I inner join Invtlot L on I.w_key=L.w_key and I.lotcode=l.lotCode and   
    I.reference=l.reference and i.ponum=l.ponum and   
    ISNULL(I.EXPDATE,1) = ISNULL(L.ExpDate,1)  
    and I.qtyIsu>0 and (l.lotQty-lotResQty)<I.qtyIsu)  
  BEGIN  
   RAISERROR('Not enough qty to issue from a spacific Lot Code. This operation will be cancelled.', -- Message text.  
     16, -- Severity.  
     1 -- State.  
    );  
  END   
  -- update invtlot using merge  
  -- 07/31/17 Sachin B  Add group by clause for update the invt_lot table and get sum(i.qtyisu) as qtyisu  
  MERGE InvtLot T  
  USING (SELECT i.W_key,i.lotcode,i.reference, i.ponum,i.expdate, sum(i.qtyisu) as qtyisu from inserted I where  
   lotcode<>' ' group by i.W_key,i.lotcode,i.reference, i.ponum,i.expdate ) as S  
   ON (s.w_key=T.w_key AND S.lotcode=T.lotcode and s.reference=t.reference and s.ponum=t.ponum and ISNULL(t.EXPDATE,1) = ISNULL(s.ExpDate,1))  
  WHEN MATCHED  THEN     
  UPDATE SET T.lotQty=t.lotqty-s.qtyIsu  
  WHEN NOT MATCHED BY TARGET THEN   
  INSERT (w_key,LotCode,Expdate,reference,ponum,lotqty,uniq_lot)   
  VALUES (s.w_key,s.LotCode,s.Expdate,s.reference,s.ponum,abs(s.qtyisu),dbo.fn_GenerateUniqueNumber());  
  -- remove lot code with 0 qty      
  DELETE FROM InvtLot WHERE LotQty=0.00 and LotResQty=0.00 ;  
    
  --07/16/16 Sachin b chnage the code update the Invtmfgr when multiple entry on the Invt_Isu Table  
  
      UPDATE c  
     SET c.Qty_Oh= c.Qty_oh-r.qtyIsu  
     FROM Invtmfgr c  
     JOIN (SELECT sum(qtyIsu) qtyIsu, w_key FROM inserted I GROUP BY w_key) r  
     ON c.w_key = r.w_key  
  
  -- check if location needs to be removed  
  update Invtmfgr set is_deleted=1 where qty_oh=0 and exists (select 1 from inserted i where i.w_key=invtmfgr.w_key)  
  and dbo.fRemoveLocation(Invtmfgr.UniqWh,Invtmfgr.UniqMfgrHd)=1  
  -- double check qty oh  
  IF exists (select 1 from invtmfgr inner join Inserted I on i.w_key=invtmfgr.w_key where QTY_OH<0 )  
  BEGIN   
   RAISERROR('No quantity available to issue. This operation will be cancelled.', -- Message text.  
     16, -- Severity.  
     1 -- State.  
    );  
  END -- double check qty oh   
       
  -- all the records issued to the kit will have kaseqnum or at least wono  
  --- first update the records with kaseqnum not empty in the issue table  
  --- 09/08/16 Sachin b chnage the code update the Kamain when multiple entry on the Invt_Isu Table  
        Update k set k.Act_qty = k.Act_qty+ i.qtyIsu,k.ShortQty = k.ShortQty-i.qtyIsu  
  from KAMAIN k  
  JOIN (SELECT sum(qtyIsu) qtyIsu,kaseqnum FROM inserted I GROUP BY KASEQNUM) i  
  ON k.KASEQNUM = i.KASEQNUM  
    
  -- update all others that have only wono   
  --- 06/30/16 YS and not created by the SF, exclude [ISSUEDTO] like 'FGI-WIP:%'  
    
   ;with  
  getReady2Apply  
  as  
  (select k.*,I.qtyisu,isnull(d.number,d1.number) as number,  
   sum(k.shortQty) over (partition by k.wono,k.uniq_key order by isnull(D.Number,d1.number) range unbounded preceding) as shortRunning,  
   sum(shortQty) over (partition by k.wono,k.uniq_key) as total4Part,  
   ROW_NUMBER() OVER (Partition by k.wono,k.uniq_key order by isnull(d.number,d1.number)) as n  
  from Kamain k Inner join Inserted I on (i.kaseqnum=' ' and k.wono=i.wono and k.uniq_key=i.uniq_key)  
  left outer join dept_qty d on k.wono=d.wono and k.dept_id=d.dept_id  
    inner join depts d1 on k.dept_id=d1.dept_id  
     --- 06/30/16 YS and not created by the SF, exclude [ISSUEDTO] like 'FGI-WIP:%'  
    WHERE I.IssuedTo NOT LIKE 'FGI-WIP:%'  
  ),  
  ApplyIssue  
  as  
  (  
  select a.*,  LAG(a.shortqty,1,0) OVER (partition by a.uniq_key order by n ) as lastRowShortgae,  
   a.qtyisu-lag(shortRunning,1,0) OVER (partition by a.uniq_key order by n ) as deltaapply,  
   case when  a.qtyisu-lag(shortRunning,1,0) OVER (partition by a.uniq_key order by n )>a.shortqty then a.shortQty  
   when a.qtyisu-lag(shortRunning,1,0) OVER (partition by a.uniq_key order by n )<0 then a.qtyisu  
   when a.qtyisu-lag(shortRunning,1,0) OVER (partition by a.uniq_key order by n )<a.shortqty then   
   a.qtyisu-lag(shortRunning,1,0) OVER (partition by a.uniq_key order by n )  
   else 0 end as applied  
   from getReady2Apply a  
  )  
  UPDATE Kamain SET Act_qty=kamain.Act_qty+A.applied, kamain.SHORTQTY=kamain.Shortqty-a.applied from ApplyIssue a where a.kaseqnum=Kamain.Kaseqnum   
    
    
    
  -- 03/14/16 YS use aspnet_profile for the user's initials. will remove saveinit  
  -- 05/23/16 YS added gl_nbr_inv  
  --06/27/16 YS added U_OF_MEAS update  
  -- 11/04/16 VL Added Presentation currency fields   
  UPDATE INVT_ISU SET  
   Invt_isu.STDCOST = Inventor.STDCOST,  
   Invt_isu.STDCOSTPR = Inventor.STDCOSTPR,    
   -- 12/28/2018 Sachin B Fix the Invt_Isu Table IS_REL_GL column value 0 Issue  
   Invt_isu.IS_REL_GL=CASE WHEN (I.QtyIsu*Inventor.StdCost)=0.00 THEN 1 ELSE INVT_ISU.IS_REL_GL END,  
   Invt_isu.Gl_nbr_inv = dbo.fn_GETINVGLNBR(Invt_isu.w_key,'I',Invt_isu.INSTORERETURN),  
   [Date]=GETDATE(),  
   [U_OF_MEAS]=I.U_OF_MEAS,  
   -- 01/12/17 VL added to update PRFcused_uniq and FuncFcused_uniq   
   PRFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetPresentationCurrency() END,  
   FuncFcused_uniq = CASE WHEN dbo.fn_IsFCInstalled() = 0 THEN SPACE(10) ELSE dbo.fn_GetFunctionalCurrency() END  
   --SAVEINIT = CASE WHEN I.Saveinit=' ' and I.fk_userid is not null THEN ISNULL(U.Userid,space(8)) ELSE I.SaveInit END  
   FROM inserted I   
   inner join Inventor on I.UNIQ_KEY=Inventor.UNIQ_KEY  
   -- outer apply   
   --   (select top 1 users.firstname,users.userid,fk_aspnetUsers from users where I.fk_userid=users.fk_aspnetUsers order by users.UNIQ_USER) U  
   where I.INVTISU_NO =Invt_isu.INVTISU_NO   

   -- 02/04/2020 Sachin B Fix the Issue to insert data in the PO store Table
   -- Inset data in the POSTORE if the instore =1 in the invtmfgr table
   IF EXISTS(SELECT 1 FROM  Inserted I INNER JOIn invtmfgr mf ON i.w_key =mf.w_key AND mf.instore =1)
   BEGIN
		INSERT INTO POSTORE (UniqRecord,Date_isu,Uniq_key,UniqSupno,Qty_isu,Partmfgr,Mfgr_pt_no,LotCode,ExpDate,Reference,UsedBy,UniqMfgrHd,SerialNo,SerialUniq,UniqWh,Location) 
		SELECT dbo.fn_GenerateUniqueNumber(),CAST(GETDATE() as smalldatetime),I.Uniq_key,mf.UniqSupNo,
		CASE WHEN isuSer.Serialno IS NOT NULL THEN 1 ELSE I.qtyisu END,
		mast.PartMfgr,mast.Mfgr_pt_no,
		I.lotcode, I.expdate, I.REFERENCE, I.IssuedTo, I.UniqMfgrhd,
		ISNULL(isuSer.Serialno,''), ISNULL(isuSer.SerialUniq,''),mf.Uniqwh,mf.[Location] 
		FROM Inserted I 
		INNER JOIN invtmfgr mf ON i.w_key =mf.w_key AND mf.instore =1
		INNER JOIN InvtMPNLink mpn ON mf.uniqmfgrhd =mpn.uniqmfgrhd
		INNER JOIN MfgrMaster mast ON mast.MfgrMasterId =mpn.MfgrMasterId
		LEFT JOIN issueserial isuSer ON i.invtisu_no =isuSer.invtisu_no
   END
   
 END TRY  
 BEGIN CATCH  
  IF @@TRANCOUNT>0  
  ROLLBACK  
  SELECT @ErrorMessage = ERROR_MESSAGE(),  
   @ErrorSeverity = ERROR_SEVERITY(),  
   @ErrorState = ERROR_STATE();  
   RAISERROR (@ErrorMessage, -- Message text.  
               @ErrorSeverity, -- Severity.  
               @ErrorState -- State.  
               );  
 END CATCH  
 IF @@TRANCOUNT>0  
 COMMIT    
END