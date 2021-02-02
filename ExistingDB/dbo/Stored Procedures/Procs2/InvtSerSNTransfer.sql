-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
--Modified:
-- 07/31/13 YS see comments for TO/FROm SCRP              
-- 08/01/13 YS Will not change DueoutDt during regular transfer Will be changed during schedule/re-schedule process              
-- 08/02/13 YS added check for the production schedule module install status and if install re-calculate the priority              
-- 09/20/13 Santosh Lokhande Converted datatype for @UserId from varchar(8) to uniqueidentifier as we are sending UserId from the application (not initials)              
-- 09/20/13 Santosh Lokhande Added variable to hold user initials.              
-- 06/06/14 Santosh Lokhande : Changed procedure to send activity Id's if transfer is by activity otherwise send department Id's.              
-- 06/10/14 Santosh Lokhande : From Activity was blank when scanned serial number is not in Activity. But associated serial number transferred is in some    --Activity.              
-- 06/27/14 Santosh Lokhande : Updated procedure to transfer bunch of serial number. Previously it was transferring single serial number.    
-- 07/08/14 YS modifications    
-- 07/29/14 YS chnage code to list all the columns when inserting into invt_rec, otherwise when columns are added or removed from the table    
--  this code will brake.    
-- 08/18/14 YS same as above for invt_isu   
-- 08/28/14 Santosh Lokhande: Added IsLotDetail bit to check the record is LotDetail or not. If LotDetail=0 then Make Uniq_Lot, LotCode, ExpDate and Reference empty.
-- 09/09/14 YS - problem when transfering from FGI and SCRP back to WIP, the complete  qty in woentry has to be decreased 
-- 09/09/14 YS - when trnasferring from FGI to SCRP the complete quantity have to stay the same 
-- 09/09/14 YS - when trnasferring from SCRP to FGI the complete quantity have to stay the same 
-- 09/11/14 Added missing code for moving to SCRP , balance quantities decreased
-- 05/16/16 Anuj Set LotCode, ExpDate and Reference to be empty when LotDetail=0
-- 06/18-06/30 YS and Sachin B made changes. removed code to update one serail at a time. modified code for the new structure changes.
-- 07/13/16 Sachin b Set ExpDate to null when LotDetail=0
-- 07/14/2016 Sachin B Added the Code for put entry in to according to group of W_key,lotcode,refrence and expdate
-- 08/05/16 Sachin B While testing i found that when RAISERROR takes place then at the same time it not go to the catch block but execute next statement so we need update Severity from 1 to 16
-- 08/11/16 Sachin B this will lock the satored procedure for given time in miliseconds when transaction commit or rollback or after the time defined it remove that lock from this sp  
-- 08/16/16 Sachin B Check Serial no is available to his department and warehouse
-- 01/12/17 VL added functional currency code
-- 09/02/2017 Sachin B put entry in configuration variance table
-- 09/15/2017 Sachin B Add parmeter @TransferId pass from Code that is used in print move ticket report
-- 11/03/2017 Sachin B Insert @TransferId into INVT_REC Table of XFER_UNIQ Column
-- 12/07/2017 Sachin B Update ClosedBy column with @UserId Bldqty -(Complete+@SerialNoCount) = 0
-- 02/09/18 YS changed size of the lotcode column to 25 char
-- 01/18/2019 Sachin B Put the  Entry on the QtyPerPackage Column of Invt_rec
-- 05/23/2019 Sachin B  - Save User Id Insted of initials in the By Column
-- 12/18/2019 Sachin B - Modify the Message Suggested by Nate if item is transfered to Other WC
-- 04/27/2020 Sachin B - Implement functionality for the Using existing MTC While Transfer to FGI
-- =============================================
CREATE PROCEDURE [dbo].[InvtSerSNTransfer]              
(              
 @SerialUniqList VARCHAR(MAX),              
 @Wono VARCHAR(10),               
 @FR_DeptKey VARCHAR(10),              
 @TO_DeptKey VARCHAR(10),              
 @FR_ActvKey VARCHAR(10),              
 @TO_ActvKey VARCHAR(10),              
 @UserId uniqueidentifier,    
 --02/09/18 YS changed size of the lotcode column to 25 char           
 @LOTCODE nvarchar(25),              
 @EXPDATE smalldatetime = NULL,                
 @REFERENCE char(12),              
 @W_Key char(10),              
 @UNIQMFGRHD char(10),
 @ordmult INT,
 -- 09/15/2017 Sachin B Add parmeter @TransferId pass from Code that is used in print move ticket report
 @TransferId char(10),  
 -- 04/27/2020 Sachin B - Implement functionality for the Using existing MTC While Transfer to FGI
 @existingMTC NVARCHAR(10)  =''        
)              
AS              
BEGIN              
       
SET NoCount ON;                            
BEGIN TRY                  
BEGIN TRANSACTION --transferTransaction          
           
 /* start fresh here */

-- parse serialuniqList and create table variable
-- declare your variables here
declare @SerialNoCount int =0,
		@uniq_key char(10),
		@Msg NVARCHAR(MAX) ,
		--@invtisu_no char(10),		
		@isIpKey bit,
		@TO_Dept_Id char(4),
		@TO_Dept_Number int,
		@FR_Dept_id char(4),
		@FR_Dept_Number int,
		@Initials varchar(8),
		@IsSNINWC bit,
		@IsLotDetail bit =0,   -- if part has to have lot code
		@FGIEXPDAYS int,	   -- default how many days from today the lot code will expire
		@Autodt bit,			   -- defualt today's date as lot code reference value		
		@Invtrec_no char(10),
		@ErrorMessage NVARCHAR(4000), -- declare variable to catch an error
		@ErrorSeverity INT,
		@ErrorState INT,
		@rc int = 0 -- return code

--08/11/16 Sachin B this will lock the satored procedure for given time in miliseconds when transaction commit or rollback or after the time defined it remove that lock from this sp  
Exec @rc = sp_getapplock @Resource='SerialNoTransfer' -- the resource to be locked
         , @LockMode='Exclusive'  -- Type of lock
         , @LockOwner='Transaction' -- Transaction or Session
         , @LockTimeout = 30000 -- timeout in milliseconds, 30 seconds

SET @SerialUniqList = REPLACE(REPLACE(REPLACE(@SerialUniqList,'[',''),']',''),'"','')            

-- added an identity rownumber for creating ipkey later  , groupid to group into packages by @ordmult 
-- 01/12/17 VL added StdCostPR     
--02/09/18 YS changed size of the lotcode column to 25 char
DECLARE @tSerialUnique table (SERIALUNIQ char(10), uniq_key char(10),w_key char(10), uniqmfgrhd char(10),id_key char(10),id_value char(10),
	lotcode nvarchar(25),expdate smalldatetime null,reference char(12),Serialno char(30),ipkeyunique char(10) default '',rownumber int IDENTITY,groupid int
	,WH_GL_NBR CHAR(13),STDCOST NUMERIC(13, 5),Shri_Gl_No  CHAR(13),INVTISU_NO char(10) default '', STDCOSTPR NUMERIC(13,5))    
INSERT INTO @tSerialUnique (SERIALUNIQ)  SELECT id from dbo.[fn_simpleVarcharlistToTable](@SerialUniqList,',') order by id   
update @tSerialUnique  set 
uniq_key = s.Uniq_key,
uniqmfgrhd  = s.uniqmfgrhd,
id_key =s.id_key,
id_value = s.id_value,
lotcode = s.lotcode,
expdate = s.expdate,
reference = s.reference ,
w_key = CASE WHEN s.id_key='W_KEY' then s.id_value else ' ' END,
serialno= s.SERIALNO,
WH_GL_NBR = (SELECT WH_GL_NBR FROM Warehous WHERE WareHouse = 'WIP'),              
-- 01/12/17 VL added StdCostPR  
STDCOST =   i.[STDCOST],
Shri_Gl_No =(SELECT TOP 1 Shri_Gl_No from InvSetup),
StdCostPR = i.StdCostPR
from InvtSer s 
inner join @tSerialUnique t on s.SERIALUNIQ=t.SERIALUNIQ
inner join INVENTOR i on i.UNIQ_KEY =s.UNIQ_KEY
-- capture count
SET @SerialNoCount=@@ROWCOUNT
SET @Initials = (SELECT Initials FROM aspnet_Profile where UserId = @UserId)   
select @isIpkey=i.useIpkey, 
@isLotDetail = ISNULL(lotDetail,0),
@FGIEXPDAYS = isnull(FGIEXPDAYS,0),
@uniq_key=i.UNIQ_KEY
FROM Inventor I inner join Woentry w on i.uniq_key=w.uniq_key 
left outer join parttype p on i.part_class=p.part_class and i.part_type=p.part_type 
where w.wono=@wono  

-- now validate
-- find "To" Dept ID and number
SELECT @TO_Dept_Number = number,@TO_Dept_Id = Dept_Id              
 FROM DEPT_QTY               
 WHERE wono = @wono and deptkey = @TO_DeptKey    

 -- find "From" Dept ID and number
SELECT @FR_Dept_Number = number,@FR_Dept_Id = dept_id              
 FROM DEPT_QTY               
 WHERE wono = @wono and deptkey = @FR_DeptKey   

-- 08/16/16 Sachin B Check Serial no is available to his department and warehouse
Declare @SerialNoPresentCount int
IF(@FR_Dept_Id = 'FGI')
	BEGIN
		SET @SerialNoPresentCount = (select count(distinct ser.SERIALUNIQ) from INVTSER ser 
		INNER JOIN @tSerialUnique seruniq  on ser.ID_VALUE = seruniq.id_value 
		where ser.SERIALUNIQ in (select SERIALUNIQ from @tSerialUnique) 
		and ser.ID_KEY = 'W_KEY')  
		IF(@SerialNoCount <> @SerialNoPresentCount) 
			BEGIN
			    RAISERROR('Some of Serial no you selected is already transfer by other user now they are not present to this center so''. This operation will be cancelled. Please try again.',16,1)             
			END
	END
ELSE
   BEGIN
   Set @SerialNoPresentCount = (select count(*) from INVTSER where SERIALUNIQ in (select SERIALUNIQ from @tSerialUnique) and ID_VALUE = @FR_DeptKey and ID_KEY = 'DEPTKEY')  
		IF(@SerialNoCount <> @SerialNoPresentCount) 
		BEGIN
		    -- 12/18/2019 Sachin B - Modify the Message Suggested by Nate if item is transfered to Other WC
			--RAISERROR('Some of Serial no you selected is already transfer by other user now they are not present to this center so''. This operation will be cancelled. Please try again.',16,1)  
			RAISERROR('Some or all of the qty in the currently selected WC has already been transfered by a different user. Please refresh screen and verify current WC qty again.',16,1)            
		END
   END

           
              
-- This code is old, have to use MnxSettingsManagement check if transfer by WC. suggested name for the  setting   TrByWCorActv , char(1) default 'W'
SELECT @IsSNINWC= CASE WHEN isnull(XXWCORACTV,'W')='W' THEN 1 ELSE 0 END FROM  ShopFSet       
              
   -- 06/30/16 YS when RAISERROR takes place no need to rollback and retun, Catch statement should do the job. Need to test!!! 
   -- 08/05/16 Sachin B While testing i found that when RAISERROR takes place then at the same time it not go to the catch block but execute next statement so we need update Severity from 1 to 16
 -- check for "To" "FGI" and empty uniqmfgrhd or empty w_key
 IF @TO_Dept_Id='FGI' and len(isnull(@UNIQMFGRHD,''))=0              
 BEGIN              
	  RAISERROR('You must provide @UNIQMFGRHD if you are transfering the serial number to ''FGI''. This operation will be cancelled. Please try again.',16,1)                           
 END  --  @TO_Dept_Id='FGI' and len(isnull(@UNIQMFGRHD,''))=0                   
              
 IF @TO_Dept_Id='FGI' and  len(isnull(@W_Key,''))=0              
 BEGIN              
	  RAISERROR('You must provide @W_Key if you are transfering the serial number to ''FGI''. This operation will be cancelled. Please try again.',16,1)                           
 END   --- @TO_Dept_Id='FGI' and  len(isnull(@W_Key,''))=0             
              
 If (@FR_Dept_Id = 'FGI') AND EXISTS (select 1  from @tSerialUnique where W_key =' ')
 BEGIN              
	RAISERROR('Some of the selected serial numbers are not located in stock. Cannot move from FGI This operation will be cancelled. Please try again.',16,1)              
 END ---  @FR_Dept_Id = 'FGI' AND EXISTS (select 1  from @tSerialUnique where W_key =' ')
 
-- check if any of the serial numbers are already in their destination   
          
 IF (@TO_DeptKey != @FR_DeptKey) AND exists(select 1 from @tSerialUnique                           
	WHERE (id_value=@TO_DeptKey and id_key='deptkey') or (id_key = 'W_KEY' and @TO_Dept_id='FGI'))        
 BEGIN                
  RAISERROR('Some of the Serial Numbers you are trying to receive is already in the system. Please check your inventory.',16,1);                             
 END --- (@TO_DeptKey != @FR_DeptKey)...               


 --- Update 'From' qty
 -- do not allow negative qty
 if exists (select 1 from dept_qty where wono=@wono and dept_qty.DEPTKEY = @fr_deptKey and dept_qty.curr_qty-@SerialNoCount<0)
 BEGIN
	RAISERROR('Not enough quantities in the ''From'' Work Center. Transaction will be cancelled.',16,1);                
 END -- exists (select 1 from dept_qty where wono=@wono and dept_qty.DEPTKEY = ...
 UPDATE Dept_qty               
 SET Curr_qty = curr_qty - @SerialNoCount ,
 Xfer_qty = Xfer_qty + @SerialNoCount 
 WHERE deptkey = @FR_DeptKey AND wono = @wono              
                       
 
 IF @IsSNINWC=0 --sn is in activity         
 BEGIN              
	  UPDATE actv_qty              
		SET Curr_qty = case              
		when  Curr_qty = 0 then 0              
	   else Curr_qty - @SerialNoCount              
	   end,              
		Xfer_qty = Xfer_qty + @SerialNoCount             
	  WHERE wono = @wono              
		and deptkey = @FR_DeptKey              
		and actvkey = @FR_ActvKey               
 END   ---  @IsSNINWC=0            
              
 -- end for FROM WC --              
              
 -- start for to WC --              
 UPDATE Dept_qty  -- increase qty in to WC              
 SET Curr_qty = Curr_qty + @SerialNoCount               
 WHERE  deptkey = @TO_DeptKey and wono = @wono               
                              
 -- If To Actvity key is available during transfer then upate the actv_qty table.              
 If @TO_ActvKey <> ''              
 BEGIN              
	  UPDATE actv_qty    
		SET Curr_qty = Curr_qty + @SerialNoCount              
	  WHERE wono = @wono              
		and deptkey = @TO_DeptKey              
		and actvkey = @TO_ActvKey               
 END   --  @TO_ActvKey <> ''      
 -- end for to WC --              
              
           
 --- now deal with stock
 IF @FR_Dept_Id = 'FGI' OR @TO_Dept_Id = 'FGI'              
 BEGIN              
	   IF @IsLotDetail=0  
	   BEGIN  
		---
			Update @tSerialUnique Set LOTCODE=' ',EXPDATE=null,REFERENCE=' '
			-- 05/16/16 Anuj Set LotCode, ExpDate and Reference to be empty when LotDetail=0
			SET @LOTCODE=''
			-- 07/13/16 Sachin b Set ExpDate to null when LotDetail=0
			SET @EXPDATE=null
			SET @REFERENCE=''
	   END -- if IF @IsLotDetail=0 
	   ELSE -- if lot code is required, check if provided
	   begin
		  if @lotcode=' '  and @TO_Dept_Id = 'FGI'
		  BEGIN
			  -- default
			  SELECT @lotcode=@wono,@EXPDATE= dateadd(day,@FGIEXPDAYS,GETDATE()),@REFERENCE = case when @Autodt=1 THEN  convert(char(11), getdate(), 113) else '' end
			  update  @tSerialUnique Set LOTCODE=@lotcode,EXPDATE=@EXPDATE,REFERENCE=@REFERENCE
		  END -- @lotcode=' '  and @TO_Dept_Id = 'FGI'
		  if @lotcode=' '  and @Fr_Dept_Id = 'FGI'
		  BEGIN
				RAISERROR('Lot Code information is missing.',16,1);                
		  END -- @lotcode=' '  and @Fr_Dept_Id = 'FGI'
	   end --- else if IF @IsLotDetail=0 
	
	----- I am still working from here down 
	  IF @FR_Dept_Id = 'FGI' -- inser into invt_isu              
	  BEGIN  

	       -- 07/14/2016 Sachin B Added the Code for put entry in to according to group of W_key,lotcode,refrence and expdate
		   -- and corresponding to that invtisu_no we have to put entry in the table issueSerial and update the warehouse and lotdetails
		   --02/09/18 YS changed size of the lotcode column to 25 char
		   Declare @GroupInvtIsNo table(
		    LOTCODE nvarchar(25), 
			EXPDATE smalldatetime,                
			REFERENCE char(12),              
			W_Key char(10),
			IssueCount int,
			grpnumber int     
		   )

		   insert into @GroupInvtIsNo (W_Key,LOTCODE,REFERENCE,EXPDATE,IssueCount,grpnumber)
		   SELECT distinct
			w_key,lotcode,reference,expdate,
			COUNT(w_key) as IssueCount ,ROW_NUMBER() over (order by w_key) as grpnumber 
			FROM @tSerialUnique t group by w_key,lotcode,reference,expdate

			-- ;with GroupInvtIsNo
			--as
			--(
			--SELECT distinct
			--w_key,lotcode,reference,expdate,
			--COUNT(w_key) as IssueCount ,ROW_NUMBER() over (order by w_key) as grpnumber 
			--FROM @tSerialUnique t group by w_key,lotcode,reference,expdate
			--)

			IF @IsLotDetail=0 
				BEGIN
					update t set 
					groupid=grpnumber from @GroupInvtIsNo gs
					inner join @tSerialUnique t on 
					t.w_key=gs.w_key 
					--and t.lotcode=gs.lotcode 
					--and t.reference=gs.reference and t.expdate=gs.expdate 
				END
			ELSE
				BEGIN
					update t set 
					groupid=grpnumber from @GroupInvtIsNo gs
					inner join @tSerialUnique t on 
					t.w_key=gs.w_key and t.lotcode=gs.lotcode 
					and t.reference=gs.reference and t.expdate=gs.expdate 
				END
			
			-- generate ipkeyunique per each group
			DECLARE @genInvtIsuNO TABLE 
			(
				groupid VARCHAR(10) NOT NULL UNIQUE, 
				INVTISU_NO char(10) not null unique
			);

			INSERT INTO @genInvtIsuNO (groupid,INVTISU_NO)
			SELECT groupid, dbo.fn_generateuniquenumber() 
				FROM @tSerialUnique
			GROUP 
			BY groupid;

			MERGE INTO @tSerialUnique t
			USING @genInvtIsuNO AS source
				ON source.groupid = t.groupid
			WHEN MATCHED THEN
			UPDATE
			SET t.INVTISU_NO = source.INVTISU_NO;

			Declare @WH_GL_NBR char(13) =(SELECT WH_GL_NBR FROM Warehous W WHERE WareHouse = 'WIP')	                
			--Set @Invtisu_no = dbo.fn_GenerateUniqueNumber()
			-- 01/12/17 VL modified invt_isu insert trigger to update functional currency fields:StdCostPR, PRFcused_uniq, FuncFcused_uniq
   		   INSERT INTO [dbo].[INVT_ISU]    
				   ([W_KEY]    
				   ,[UNIQ_KEY]    
				   ,[ISSUEDTO]    
				   ,[QTYISU]    
				   --,[DATE]		--- defualt to taday's date , default constraint for the column
				 --  ,[U_OF_MEAS]    - updated by insert trigger
				   ,[GL_NBR]    
				   ,[INVTISU_NO]    
				   --,[GL_NBR_INV]    -- updated by insert trigger
				   ,[WONO]    
				   ,[IS_REL_GL]    
				   --,[STDCOST]    -- update by insert trigger
				   ,[LOTCODE]    
				   ,[EXPDATE]    
				   ,[REFERENCE]    
				   ,[SAVEINIT]    
				   ,[DEPTKEY]    
				   ,[ACTVKEY]    
				   ,[UNIQMFGRHD]    
				   ,[CMODID]    
				   ,[LSKIPUNALLOCCODE]    
				  )    
			  SELECT  w_key,@uniq_key,'FGI-WIP:'+@wono,COUNT(w_key),@WH_GL_NBR,
				 INVTISU_NO,@WONO,0,lotcode ,expdate,              
				reference,@Initials,@TO_DeptKey,isnull(@TO_ActvKey,''),@UNIQMFGRHD,                
				'S',0              
				from  @tSerialUnique t group by w_key,lotcode,reference,expdate,INVTISU_NO               
		 
			--Sachin B Is useipkey is true then we have to put entry on the issueipkey and issueSerial tables
			IF @isIpkey=1
			BEGIN
			     Update t set t.ipkeyunique = ser.ipkeyunique
				 from @tSerialUnique t 
				 Inner join INVTSER ser on t.SERIALUNIQ = ser.serialuniq								
			END

			--the trigger of issueserial table put entry to the issueipkey table if it have ipkeyunique
			insert into issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique)
			select t.serialno,t.SerialUniq,dbo.fn_GenerateUniqueNumber(),invtisu_no,s.ipkeyunique --- need to figure out ipkey  
			from @tSerialUnique t 
			inner join invtser s on t.SerialUniq=s.SERIALUNIQ            
                 
			UPDATE Woentry              
				SET Complete = Complete-@SerialNoCount ,              
				Balance = Bldqty -   (Complete-@SerialNoCount) ,              
				OpenClos = case              
				when  Bldqty -  (Complete-@SerialNoCount) = 0 then 'Closed'              
				else OpenClos              
				end,              
				Completedt = case              
				when  Bldqty -  (Complete-@SerialNoCount) = 0 then getdate()  
				else Completedt              
				end              
			WHERE Wono = @Wono  
			
			-- 09/02/2017 Sachin B put entry in configuration variance table
			--Logic for put Entry in configuration variance
			SELECT INVTISU_NO,COUNT(w_key) as qty,ROW_NUMBER() OVER(ORDER BY A.INVTISU_NO DESC) AS ROW INTO #Configuraion 
			FROM  @tSerialUnique as a GROUP BY w_key,lotcode,reference,expdate,INVTISU_NO   
			
			--Find the highest number to start with
			DECLARE @COUNTER INT = (SELECT MAX(ROW) FROM #Configuraion);
			DECLARE @ROW INT;  
			
			DECLARE @invtisuNo CHAR(10)
			DECLARE @QtytoInsert NUMERIC(12,2)

			WHILE (@COUNTER != 0)
			BEGIN
				SELECT TOP 1 @ROW = ROW,@invtisuNo = INVTISU_NO,@QtytoInsert =qty FROM #Configuraion WHERE ROW = @COUNTER
				ORDER BY ROW DESC

				--Put entry into configuration variance
				BEGIN              
				  EXEC ConfgVarSNTransferAdd @Wono,@QtytoInsert,@FR_Dept_Id,@TO_Dept_Id,@invtisuNo,''              
				END 
				SET @COUNTER = @ROW -1
			END
			--DROP TABLE #ControlTable			                     
	  END  --- IF @FR_Dept_Id = 'FGI'
  
  
            
	  IF @TO_Dept_Id = 'FGI'  -- insert record into [INVT_REC]              
	  BEGIN                   
                
			--07/29/14 YS chnage code to list all the columns. When columns are added or removed from the table    
			-- this code will brake.
		   SET @Invtrec_no = dbo.fn_GenerateUniqueNumber() 
		    -- 01/12/17 VL modified invt_isu insert trigger to update functional currency fields:StdCostPR, PRFcused_uniq, FuncFcused_uniq
		   INSERT INTO [dbo].[INVT_REC]    
				   ([W_KEY]    
				   ,[UNIQ_KEY]    
				   --,[DATE]    --- defualt to taday's date , default constraint for the column
				   ,[QTYREC]    
				   ,[COMMREC]    
				   ,[GL_NBR]    
				   ,[IS_REL_GL]    
				   --,[STDCOST]   -- insert trigger update this column 
				   ,[INVTREC_NO]    
				   --,[U_OF_MEAS]   -- insert trigger will update this column 
				   ,[LOTCODE]    
				   ,[EXPDATE]    
				   ,[REFERENCE]    
				   ,[SAVEINIT]    
				   ,[UNIQ_LOT]    
				   --,[serialno]    --- remove from the table
				   --,[serialuniq]     --- remove from the table
				   ,[UNIQMFGRHD]    
				   ,[fk_userid]
				   -- 11/03/2017 Sachin B Insert @TransferId into INVT_REC Table of XFER_UNIQ Column
				   ,XFER_UNIQ
				   -- 01/18/2019 Sachin B Put the  Entry on the QtyPerPackage Column of Invt_rec
				   ,qtyPerPackage
				   )             
		   SELECT Distinct  @W_KEY,t.UNIQ_KEY,@SerialNoCount as [QTYREC],        
			 'WIP-FGI:' + @Wono as [COMMREC],w.WH_GL_NBR as [GL_NBR]             
			 ,0 as [IS_REL_GL],@Invtrec_no,@LOTCODE,@EXPDATE              
			 ,@REFERENCE,@Initials,isnull(L.UNIQ_LOT,space(10)) as Uniq_lot,@UNIQMFGRHD, 
			  -- 01/18/2019 Sachin B Put the  Entry on the QtyPerPackage Column of Invt_rec       
			  @UserId as  [fk_userid],@TransferId,@ordmult            
		   FROM @tSerialUnique t LEFT OUTER JOIN
		   InvtLot L ON @w_key=l.w_key and t.lotcode=l.LOTCODE 
			and ((t.expdate is null and l.expdate is null) or  (t.expdate=l.EXPDATE)) 
			and t.reference=l.reference 
		   CROSS JOIN Warehous W WHERE 
		   w.WareHouse = 'WIP'  
    
		-- 09/02/2017 Sachin B put entry in configuration variance table
		--Put entry into configuration variance
		BEGIN              
			EXEC ConfgVarSNTransferAdd @Wono,@SerialNoCount,@FR_Dept_Id,@TO_Dept_Id,'',@Invtrec_no              
		END 

		--- create ipkey
		IF @isIpkey=1
		BEGIN	
		    -- 04/27/2020 Sachin B - Implement functionality for the Using existing MTC While Transfer to FGI		
			IF @existingMTC =''
			BEGIN
				-- divide into groups according with @ordmult
				;WITH GroupIpkey
				AS
				(
					--06/23/16 Sachin B put entry to the group number column as ordmult provided 
					SELECT t.*,
					(CASE WHEN @ordmult=0 then 1 ELSE @ordmult END -1 + ROW_NUMBER() OVER(ORDER BY t.serialno))/CASE WHEN @ordmult=0 THEN 1 ELSE @ordmult END grpnumber
					FROM @tSerialUnique t
					--select t.*,NTILE(((@SerialNoCount)/(case when @ordmult=0 then 1 else @ordmult end)))  OVER (order by serialno) as grpnumber 
					--from @tSerialUnique t
				)
				UPDATE T SET groupid=grpnumber FROM GroupIpkey 
				INNER JOIN @tSerialUnique t ON t.serialno=GroupIpkey.serialno

				-- generate ipkeyunique per each group
				DECLARE @genIpKey TABLE 
				(
					groupid VARCHAR(10) NOT NULL UNIQUE, 
					ipkeyuniq CHAR(10) not null UNIQUE
				);

				INSERT INTO @genIpKey (groupid,ipkeyuniq)
				SELECT groupid, dbo.fn_generateuniquenumber() 
				FROM @tSerialUnique
				GROUP BY groupid;

				-- now populate @tSerialUnique.ipkeyunique
				MERGE INTO @tSerialUnique t
				USING @genIpKey AS source
					ON source.groupid = t.groupid
				WHEN MATCHED THEN
				UPDATE
				SET ipkeyunique = source.ipkeyuniq;
			END
			ELSE
			BEGIN
				UPDATE @tSerialUnique SET ipkeyunique = @existingMTC
			END
		END --- if @isIpkey=1

		--- the insert trigger for the iRecSerial will update invtser and if ipkeyunique is not empty will insert a record into ipkey table
		INSERT INTO iRecSerial (iRecSeriUnique,invtrec_no,serialno,serialuniq,ipkeyunique) 
		SELECT dbo.fn_GenerateUniqueNumber(),@Invtrec_no,[SERIALNO], [SERIALUNIQ],[IPKEYUNIQUE] 
		FROM  @tSerialUnique t  
	                	                                 
		UPDATE Woentry              
			SET Complete =  Complete+@SerialNoCount ,              
				Balance = Bldqty - (Complete+@SerialNoCount),              
				OpenClos = case              
				when  Bldqty - (Complete+@SerialNoCount) = 0 then 'Closed'              
				else OpenClos   
				end,              
				Completedt = case              
				when  Bldqty - (Complete+@SerialNoCount) = 0 then getdate()              
				else Completedt              
				end          
				WHERE Wono = @Wono              
	  END  --- IF @TO_Dept_Id = 'FGI'             
 END   ----  IF @FR_Dept_Id = 'FGI' OR @TO_Dept_Id = 'FGI' 

  IF @TO_Dept_Id <> 'FGI'            
 BEGIN               
   IF @IsSNINWC=1 --sn is in work center              
   BEGIN                 
		UPDATE InvtSer                
			SET Id_Value = @TO_DeptKey , id_key = 'DEPTKEY' --- ?              
			WHERE exists (select 1 from @tSerialUnique t where t.serialuniq=Invtser.serialuniq)             
   END              
   ELSE --sn is in activity              
   BEGIN              
		-- If current activity is last activity                   
		UPDATE InvtSer                
			SET Id_Value = @TO_DeptKey,              
				Actvkey = @TO_ActvKey,              
				id_key='DEPTKEY'              
		WHERE exists (select 1 from @tSerialUnique t where t.serialuniq=Invtser.serialuniq)                        
   END   --- IF @IsSNINWC=1           
 END  --- @TO_Dept_Id <> 'FGI' 

--When quantity move to and from by scrp
--When Quantity move from the scrp we need to update woentry 
-- 06/30/16 YS have to use @SerialNoCount to reduce the qty
 IF @FR_Dept_Id = 'SCRP'               
  BEGIN              
	UPDATE Woentry              
    SET Complete =  Complete-@SerialNoCount ,              
	Balance = Bldqty -  (Complete-@SerialNoCount) ,             
	OpenClos = case when  Bldqty -  (Complete-@SerialNoCount) = 0 then 'Closed' else OpenClos END,              
    Completedt = case when  Bldqty -  (Complete-@SerialNoCount)= 0 then getdate() else Completedt END              
    WHERE Wono = @Wono              
 END -- IF @FR_Dept_Id = 'SCRP'             
 -- 06/30/16 YS have to use @SerialNoCount to encrease the qty              
 IF (@TO_Dept_Id = 'SCRP') or (@FR_Dept_Id = 'SCRP') -- Insert record into [SCRAPREL]              
 BEGIN                
	   IF (@TO_Dept_Id ='SCRP')
		   BEGIN
			   UPDATE Woentry              
				   SET Complete = Complete+@SerialNoCount ,              
					Balance = Bldqty -   (Complete+@SerialNoCount) ,              
					OpenClos = case when  Bldqty -  (Complete+@SerialNoCount) = 0 then 'Closed' else OpenClos end, 
					-- 12/07/2017 Sachin B Update ClosedBy column with @UserId Bldqty -(Complete+@SerialNoCount) = 0 
					ClosedBy = case when  Bldqty -  (Complete+@SerialNoCount) = 0 then @UserId else ClosedBy end,              
					Completedt = case  when  Bldqty -  (Complete+@SerialNoCount) = 0 then getdate() else Completedt end              
				   WHERE Wono = @Wono 
		   END --- if (@TO_dept_id='SCRP')
   
	   --Insert in to scrap detail table according to and from SCRP 
	  -- 06/30/1 YS use  @SerialNoCount  for qtyTransf        
	   -- 01/12/17 VL modified Scraprel insert trigger to update functional currency fields: PRFcused_uniq, FuncFcused_uniq, but add stdcostPR here 
	   INSERT INTO ScrapRel (Wono,Uniq_key,QtyTransf,Initials, Trans_no, Shri_gl_no, Wip_gl_nbr,StdCost, [DateTime],StdCostPR)                
	   SELECT @Wono,info.UNIQ_KEY ,case  when  @FR_Dept_Id = 'SCRP' then - @SerialNoCount  else @SerialNoCount  end,              
		@Initials,                 
		dbo.fn_GenerateUniqueNumber(),              
		info.Shri_Gl_No,               
		dbo.fn_GetWIPGl(),               
		info.STDCOST, GETDATE(),
		info.STDCOSTPR               
	   FROM @tSerialUnique info                
                   
	  If dbo.GetGlPostRules4PostType('SCRAP')=1               
	  BEGIN                 
		  EXEC dbo.SpScrapReleasePost @Initials                
	  END                
 END  --- if (@TO_dept_id='SCRP' or @FR_Dept_Id = 'SCRP')        

 --Code for the put entry in the transfer table
 DECLARE @XFERC_QTY numeric(7,0)              
              
  BEGIN              
  If @FR_ActvKey = '' or @FR_DeptKey<>@TO_DeptKey              
  SELECT @XFERC_QTY = Xfer_qty              
  FROM Dept_qty              
  WHERE Deptkey= @FR_DeptKey              
 AND wono = @Wono                
  ELSE              
  SELECT @XFERC_QTY = Xfer_qty              
  FROM  Actv_qty              
  WHERE Deptkey = @FR_DeptKey              
  AND wono = @Wono              
  AND actvkey = @FR_ActvKey              
  END                  
              
 DECLARE @From_Id char(4)              
 DECLARE @To_Id char(4)              
              
 IF @FR_ActvKey<>''              
	 BEGIN            
	  SELECT @From_Id = (SELECT ACTIV_ID FROM ACTV_QTY WHERE ACTVKEY=@FR_ActvKey and WONO=@Wono)              
	 END              
 ELSE              
	 BEGIN              
	  SELECT @From_Id = @FR_Dept_Id              
	 END              
              
 IF @TO_ActvKey<>''              
	 BEGIN              
	  SELECT @To_Id = (SELECT ACTIV_ID FROM ACTV_QTY WHERE ACTVKEY=@TO_ActvKey and WONO=@Wono)              
	 END              
 ELSE              
	 BEGIN              
	  SELECT @To_Id = @TO_Dept_Id              
	 END              
 -- 09/15/2017 Sachin B Add parmeter @TransferId pass from Code that is used in print move ticket report
 -- insert record into TRANSFER w
	  INSERT INTO .[dbo].[TRANSFER] 
	  ([Date],
	  FR_DEPT_ID,
	  TO_DEPT_ID,
	  QTY,
	  XFERC_QTY,
	  HRS,
	  [MIN],
	  [BY],
	  WONO,
	  FTNOTE,
	  CREDIT_QTY,
	  FR_NUMBER,
	  TO_NUMBER,
	  FR_DEPTKEY,
	  TO_DEPTKEY,
	  FR_ACTVKEY,
	  TO_ACTVKEY,
	  XFER_UNIQ
	  )values(GETDATE()              
		 ,@From_Id               
		 ,@To_Id               
		 ,@SerialNoCount              
		 ,@XFERC_QTY              
		 ,0               
		 ,0  
     -- 05/23/2019 Sachin B  - Save User Id Insted of initials in the By Column            
     ,@UserId                   
		 ,@Wono              
		 ,''              
		 ,0              
		 ,@FR_Dept_Number               
		 ,@TO_Dept_Number               
		 ,@FR_DeptKey               
		 ,@TO_DeptKey                    
		 ,isnull(@FR_ActvKey ,'')              
		 ,isnull(@TO_ActvKey,'')              
		 ,@TransferId )                       
  
 --Put entry to the TRANSFERSNX table for each serialuniquekey.              
 Insert into TRANSFERSNX (FK_XFR_UNIQ,FK_SERIALUNIQ,SFXFRSNUNIQ) SELECT @TransferId,serialuniq, dbo.fn_GenerateUniqueNumber()  from  @tSerialUnique  

 -- 09/02/2017 Sachin B put entry in configuration variance table
 --Put entry in the congiguration variance table
 IF (@FR_Dept_Id = 'SCRP' and @TO_Dept_Id <> 'FGI') or (@TO_Dept_Id = 'SCRP' and @FR_Dept_Id <> 'FGI')           
  BEGIN           
	EXEC ConfgVarSNTransferAdd @Wono,@SerialNoCount,@FR_Dept_Id,@TO_Dept_Id,'',''              
  END
          
COMMIT TRANSACTION              
              
END TRY      
-- 06/20/16 YS change how catch is working need to make sure it is working as expected        
BEGIN CATCH                          
	IF @@TRANCOUNT > 0 
		ROLLBACK TRANSACTION;      
	    SELECT @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage, -- Message text.
               @ErrorSeverity, -- Severity.
               @ErrorState -- State.
               );
                    
END CATCH                       
END