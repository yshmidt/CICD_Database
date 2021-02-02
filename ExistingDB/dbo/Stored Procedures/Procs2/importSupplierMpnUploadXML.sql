-- =============================================
-- Author: Anuj Kumar
-- Create date: 5/8/2015
-- Description: imports the XML file to SQL table
-- 05.14.15 YS remove all count(*) from the validation
-- 05/15/15 YS more modifications, changes to importSupplierMpnLinkerror structure added importid
-- 05/17/15 YS added new table to save the exceptions that were not loaded and the reason
-- 05/19/15 YS cannot insert null for the primary keys importid and rowid
-- 03/28/16 YS removed invtmfhd table
-- =============================================
CREATE PROCEDURE [dbo].[importSupplierMpnUploadXML]
-- Add the parameters for the stored procedure here
--05/14/15 YS added default
@importId uniqueidentifier = NULL,
@userId uniqueidentifier = NULL
,@x xml 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	/* If import ID is not provided, create a new is */
	IF (@importId IS NULL) SET @importId = NEWID()

	/* Declare variables and temperory tables */
	--05/14/15 YS not used
	---DECLARE @lRollback bit=0,@partmfgrErrs varchar(MAX),@mfgrptnoErrs varchar(MAX),@supnameErrs varchar(MAX),@suplpartnoErrs varchar(MAX),@pfdsuplErrs varchar(MAX)
	DECLARE @errNumber int,@errSeverity int,@errProc VARCHAR(MAX),@errLine int,@errMsg VARCHAR(MAX)
	--05/17/15 YS remove for now
	--DECLARE @ErrTable TABLE (ErrNumber int,ErrSeverity int,ErrProc varchar(MAX),ErrLine int,ErrMsg varchar(MAX))
	-- 05/15/15 YS move begin transaction down
	BEGIN TRY  -- outside begin try
   -- BEGIN TRANSACTION -- wrap transaction
	
		/* Declare import table variables */
		-- 05/14/15 YS added uniqueidentifier, pfdsupl has to have 5 to allow for 'false'

		DECLARE @importResultSet TABLE (rowId uniqueidentifier default newid(), Partmfgr varchar(MAX),Mfgr_pt_no varchar(MAX),SupName varchar(MAX),SUPLPARTNO varchar(MAX),
			PFDSUPL char(5))
		-- 05/17/15 YS added new table variable to save all exceptions
		DECLARE @importSupplierMpnLinkException  Table 
		(importid uniqueidentifier ,rowId uniqueidentifier, Partmfgr varchar(MAX),Mfgr_pt_no varchar(MAX),
		SupName varchar(MAX),SUPLPARTNO varchar(MAX),exceptionMsg varchar(90),lastLoad bit default 1)
		/* Parse Supplier part number records and insert into table variable */
		-- YS use importSupplierResultSet for testing to bypass loading from xml
		--INSERT INTO @importResultSet(Partmfgr,Mfgr_pt_no,SupName,SUPLPARTNO,PFDSUPL)
		--select * from importSupplierResultSet
		INSERT INTO @importResultSet(Partmfgr,Mfgr_pt_no,SupName,SUPLPARTNO,PFDSUPL)
			SELECT 
					x.importSupplierMpn.query('PARTMFGR/text()').value('.','VARCHAR(MAX)') Partmfgr,
					x.importSupplierMpn.query('MFGR_PT_NO/text()').value('.','VARCHAR(MAX)') Mfgr_pt_no,
					x.importSupplierMpn.query('SUPNAME/text()').value('.','VARCHAR(MAX)') SupName,
					x.importSupplierMpn.query('SUPLPARTNO/text()').value('.','VARCHAR(MAX)') SUPLPARTNO,
					x.importSupplierMpn.query('PFDSUPL/text()').value('.','VARCHAR(5)') PFDSUPL
				FROM @x.nodes('/Root/Row') AS X(importSupplierMpn)
				OPTION (OPTIMIZE FOR(@x = NULL))
				---05/14/15 YS update pfdsupl, chnage later to use bit type
				UPDATE @importResultSet SET PFDSUPL=CASE WHEN PFDSUPL<>' ' AND RTRIM(PFDSUPL) IN ('Yes','Y','1','T','True') THEN '1' ELSE '0' END

				-- 05/14/15 YS check for duplicates in the upload 
				;WITH importDupl
				as
				(
				select rowId,Partmfgr,Mfgr_pt_no,SupName,SUPLPARTNO,PFDSUPL,
					ROW_NUMBER() OVER (Partition by partmfgr,mfgr_pt_no,supname,suplpartno order by PFDSUPL desc) n
					FROM @importResultSet)
				-- 05/17/15 YS change code to save problem records and report to the user
				INSERT INTO @importSupplierMpnLinkException (
					importid 
					,rowId 
					, Partmfgr 
					,Mfgr_pt_no 
					,SupName 
					,SUPLPARTNO 
					,exceptionMsg 
					)
					SELECT @importId,
						rowId,
						Partmfgr,
						Mfgr_pt_no,
						SupName,
						SUPLPARTNO,
						'Upload file has duplicate records, will load only once' from importDupl where importDupl.n>1
				DELETE R FROM @importResultSet R
				WHERE exists (select 1 from @importSupplierMpnLinkException E where r.rowId=e.rowId and e.lastLoad=1)

				update @importSupplierMpnLinkException set lastLoad=0
				 
				--05/15/15 YS check for the different suplpartno for the same MPN and PFDSUPL=1 , need to pick one and update the othesr as 0
				;WITH importDuplPFDSUPL
				as
				(
				select rowId,Partmfgr,Mfgr_pt_no,SupName,SUPLPARTNO,PFDSUPL,
					ROW_NUMBER() OVER (Partition by partmfgr,mfgr_pt_no order by Supname,SuplPartno) n
					FROM @importResultSet where PFDSUPL=1)
				UPDATE I set PFDSUPL=0
				FROM @importResultSet I
				WHERE exists (select 1 from importDuplPFDSUPL where I.rowId=importDuplPFDSUPL.rowId and importDuplPFDSUPL.n>1)
				--select * from @importResultSet
				--validation if incorrect file upload
				---05/15/15 YS remove this begin try
				--BEGIN TRY
				declare @msg varchar(MAX)='';
				--05/14/15 YS changed validation
				--if((select COUNT(*) from @importResultSet)<=0 or (SELECT TOP 1 PARTMFGR FROM @importResultSet)='')
				IF NOT EXISTS (SELECT 1 from @importResultSet WHERE partmfgr<>' ' and supname<>' ' and SUPLPARTNO<>' ')
				BEGIN -- begin inner if block
					--05/14/15 YS changed message
					SET @msg='No information to load, please verify data exists in the upload file.' 

					BEGIN TRY --begin try block
						RAISERROR(@msg,16,1)
					END TRY --end try block

					BEGIN CATCH --begin catch block
						SELECT @errNumber = ERROR_NUMBER();
						SELECT @errSeverity=ERROR_SEVERITY();
						SELECT @errProc=ERROR_PROCEDURE();
						SELECT @errLine=ERROR_LINE();
						SELECT @errMsg=ERROR_MESSAGE();

						--05/15/15 YS added begin/commit transaction to a procedure
						--05/15/15 YS added import id column to the error table
						--EXEC importSupplierMpnErrorAdd @errNumber, @errSeverity,@errProc,@errLine,@errMsg,@importId  --procedure to insert into error table
						--05/17/15 YS insert into importSupplierMpnLinkException instead
						--05/19/15 YS cannot insert null for the primary keys importid and rowid
						INSERT INTO importSupplierMpnLinkException  
						(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
							VALUES (@importId,newid(),'','','','',@errMsg)				
						SELECT * FROM importSupplierMpnLinkException where importId=@importId
						RETURN -1
					END CATCH --end catch block
				END -- IF NOT EXISTS (SELECT 1 from @importResult  WHERE partmfgr<>' ' and supname<>' ' and SUPLPARTNO<>' ')
				
                   
					--validation 1)Find any PartMfgr that are not entered into Manex
				

				IF EXISTS (select 1 FROM @importResultSet R
						LEFT OUTER JOIN Support ON RTRIM(R.PartMfgr)=LEFT(Text2,8) and Support.FIELDNAME='PARTMFGR'
						WHERE Support.Text2 IS NULL)

				BEGIN --Begin outside if block

					SET @msg='Part Manufacturer code does not exist in Manex system Setup database.' 
					--Delete the incoorect record
					-- 05/17/15 YS change code to save problem records and report to the user
					INSERT INTO @importSupplierMpnLinkException (
					importid 
					,rowId 
					, Partmfgr 
					,Mfgr_pt_no 
					,SupName 
					,SUPLPARTNO 
					,exceptionMsg 
					)
					SELECT @importId,
						rowId,
						Partmfgr,
						Mfgr_pt_no,
						SupName,
						SUPLPARTNO,
						@msg
						from @importResultSet R where 
						NOT EXISTS (SELECT 1 FROM Support WHERE Fieldname = 'PARTMFGR' and LEFT(Text2,8) =RTRIM(R.PartMfgr))
				
				
				DELETE R FROM @importResultSet R
				WHERE exists (select 1 from @importSupplierMpnLinkException E where r.rowId=e.rowId and e.lastLoad=1)
				update @importSupplierMpnLinkException set lastLoad=0

					--05/14/15 YS changed validation
					IF NOT EXISTS (select 1 from @importResultSet)
					BEGIN -- begin inner if block
					    BEGIN TRY --begin try block
							RAISERROR(@msg,16,1)
						END TRY --end try block

						BEGIN CATCH --begin catch block
							

							--05/17/15 YS insert into exception table and return back to user
							INSERT INTO importSupplierMpnLinkException  
							(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
							select importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg
							from @importSupplierMpnLinkException
							
							select * from importSupplierMpnLinkException
							RETURN -1
							--END -- end inner if
						END CATCH --end catch block
					END --NOT EXISTS (select 1 from @importResultSet)
				END	----IF NOT EXISTS (SELECT 1 FROM Support INNER JOIN @importResultSet R ON LEFT(Text2,8) =RTRIM(R.PartMfgr)...

			

				--validation 2)The combination partmfgr and mfgr_pt_no has to exists in Invtmfhd table.
						
				-- 03/28/16 YS removed invtmfhd table

				IF EXISTS (SELECT 1  FROM @importResultSet R OUTER APPLY
					(select uniq_key,partmfgr,mfgr_pt_no from MfgrMaster inner join invtmpnlink on mfgrmaster.mfgrmasterid=invtmpnlink.mfgrmasterid 
								where R.partmfgr=MfgrMaster.partMfgr and R.Mfgr_pt_no=MfgrMaster.mfgr_pt_no) M  
					 where m.UNIQ_KEY is null)
				BEGIN --Begin outer if block
					
					---05/14/15 Wrong message
					---SET @msg='Supplier is already connected to the given MPN.'
					SET @msg='Cannot find Manufacturer Code and Manufacturer Part Number in Invtmfhd table to link' 
						-- 05/17/15 YS change code to save problem records and report to the user
					INSERT INTO @importSupplierMpnLinkException (
					importid 
					,rowId 
					, Partmfgr 
					,Mfgr_pt_no 
					,SupName 
					,SUPLPARTNO 
					,exceptionMsg 
					)
					SELECT @importId,
						rowId,
						Partmfgr,
						Mfgr_pt_no,
						SupName,
						SUPLPARTNO,
						@msg
						from @importResultSet R where 
							-- 03/28/16 YS removed invtmfhd table
						NOT EXISTS (SELECT 1  FROM Invtmpnlink INNER JOIN MfgrMaster on Invtmpnlink.mfgrmasterid=mfgrmaster.mfgrmasterid WHERE
						MfgrMaster.partMfgr=R.partmfgr and MfgrMaster.mfgr_pt_no=R.Mfgr_pt_no )
				
				
				DELETE R FROM @importResultSet R
				WHERE exists (select 1 from @importSupplierMpnLinkException E where r.rowId=e.rowId and e.lastLoad=1)
				update @importSupplierMpnLinkException set lastLoad=0	
					
					--Delete the incorrect record
				
					IF NOT EXISTS (SELECT 1 from @importResultSet)	
					BEGIN --Begin inner if block
						BEGIN TRY --Begin inner try block
							RAISERROR(@msg,16,1)
						END TRY --End inner try block
						BEGIN CATCH --Begin inner catch block
							
						
							----05/15/15 YS added import id column to the error table
							
									
							--SELECT * FROM importsuppliermpnlinkerror where importid=@importId
							--05/17/15 YS insert into exception table and return back to user
							INSERT INTO importSupplierMpnLinkException  
							(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
							select importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg
							from @importSupplierMpnLinkException
							
							select * from importSupplierMpnLinkException where importid=@importId
							RETURN -1
									--END
						END CATCH --End catch
					END --IF NOT EXISTS (SELECT 1 from @importResultSet)	
								
				END --IF NOT EXISTS (SELECT 1  FROM Invtmfhd M inner join @importResultSet R ON ...
			

					--validation 3)Supname has to exists in Supinfo Table. {UniqSUpno} value will be used in the final Insert/Update.
--05/15/15 YS remove begin try
				
					---05/14/15 YS remove count
					
			
				if EXISTS (SELECT 1  from  @importResultSet R LEFT OUTER JOIN Supinfo S ON R.SupName=S.SUPNAME WHERE S.UNIQSUPNO is null)
				BEGIN --begin outer if block
					SET @msg='The supplier does not exist in Manex system Setup database.'
						---05/14/15 Wrong message
					---SET @msg='Supplier is already connected to the given MPN.'
					-- 05/17/15 YS change code to save problem records and report to the user
					INSERT INTO @importSupplierMpnLinkException (
					importid 
					,rowId 
					, Partmfgr 
					,Mfgr_pt_no 
					,SupName 
					,SUPLPARTNO 
					,exceptionMsg 
					)
					SELECT @importId,
						rowId,
						Partmfgr,
						Mfgr_pt_no,
						SupName,
						SUPLPARTNO,
						@msg
						from @importResultSet R where 
						NOT EXISTS (SELECT 1  from Supinfo S WHERE S.SUPNAME=R.SupName)
						
				
				
					DELETE R FROM @importResultSet R
					WHERE exists (select 1 from @importSupplierMpnLinkException E where r.rowId=e.rowId and e.lastLoad=1)
					update @importSupplierMpnLinkException set lastLoad=0
					
					--Delete incorrect record
					--DELETE R FROM @importResultSet  R where NOT EXISTS (SELECT 1   from Supinfo S where S.SUPNAME=R.SupName)
					--05/14/15 YS remove count(*)
					--if((SELECT COUNT(*) FROM @importResultSet)<= 0) --check if record exists
					if NOT EXISTS (SELECT 1 from @importResultSet)
					BEGIN --begin inner if block
									
						BEGIN TRY --begin try block
							RAISERROR(@msg,16,1)
						END TRY --end try block
									
						BEGIN CATCH --Begin catch block

							--SELECT @errNumber = ERROR_NUMBER();
							--SELECT @errSeverity=ERROR_SEVERITY();
							--SELECT @errProc=ERROR_PROCEDURE();
							--SELECT @errLine=ERROR_LINE();
							--SELECT @errMsg=ERROR_MESSAGE();
							----05/15/15 YS added import id column to the error table
							--EXEC importSupplierMpnErrorAdd @errNumber, @errSeverity,@errProc,@errLine,@errMsg,@importId --insert into error log table
							---- 05/14/15 YS no need to count again
							----if((SELECT COUNT(*) FROM @importResultSet)=0) --check if record exists to continue
							----BEGIN
							----COMMIT --if no record exists commit
							--SELECT * FROM importsuppliermpnlinkerror where importid=@importId
								--05/17/15 YS insert into exception table and return back to user
							INSERT INTO importSupplierMpnLinkException  
							(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
							select importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg
							from @importSupplierMpnLinkException
							
							select * from importSupplierMpnLinkException where importid=@importId
							RETURN -1
									--END
						END CATCH --end catch
					END --if NOT EXISTS (SELECT 1 from @importResultSet)
				END --if NOT EXISTS (SELECT 1  from Supinfo S inner join @importResultSet R ON S.SUPNAME=R.SupName)
				--END TRY --end try block
			--		BEGIN CATCH	--Begin catch block

			--	INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)
			--	SELECT
			--		ERROR_NUMBER() AS ErrorNumber
			--		,ERROR_SEVERITY() AS ErrorSeverity
			--		,ERROR_PROCEDURE() AS ErrorProcedure
			--		,ERROR_LINE() AS ErrorLine
			--		,ERROR_MESSAGE() AS ErrorMessage;
			--		-- 05/14/15 YS extra variable
			--	--SET @supnameErrs = @msg
				
			--END CATCH --End catch block

					--validation 4)Check if Partmfgr, Mfgr_pt_no and SuplPartNo is already exists for any parts in the database.
				--05/15/15 ys removed begin try
				--BEGIN TRY--Begin try block

					-- 05/14/15 YS the internal SELECT COUNT(*) will return result as 0 and the external when check for exists will return 1
					-- and the validation will fail - always
			--- 03/28/16 YS removed invtmfhd table
				IF EXISTS (SELECT 1 from invtmfsp ms inner join invtmpnlink l on ms.UNIQMFGRHD=l.UNIQMFGRHD
							inner join Mfgrmaster M on l.MfgrMasterId=m.MfgrMasterId
							INNER JOIN Supinfo S On ms.uniqsupno=s.UNIQSUPNO 
							INNER JOIN @importResultSet  R ON 
							M.MFGR_PT_NO=R.Mfgr_pt_no and 
							M.PARTMFGR=R.Partmfgr and 
							s.SUPNAME=R.SupName and 
							ms.SUPLPARTNO=R.SUPLPARTNO
							WHERE ms.IS_DELETED=0)

				BEGIN
					
					SET @msg='Supplier is already connected to the given MPN '
					--05/14/15 YS remove count()
					--05/17/15 YS added exception table to return result to a user
						--- 03/28/16 YS removed invtmfhd table
					INSERT INTO @importSupplierMpnLinkException (
					importid 
					,rowId 
					, Partmfgr 
					,Mfgr_pt_no 
					,SupName 
					,SUPLPARTNO 
					,exceptionMsg 
					)
					SELECT @importId,
						rowId,
						Partmfgr,
						Mfgr_pt_no,
						SupName,
						SUPLPARTNO,
						@msg
						from @importResultSet R where 
							--- 03/28/16 YS removed invtmfhd table
						EXISTS (SELECT 1 from invtmfsp ms inner join invtmpnlink L  on ms.UNIQMFGRHD=L.UNIQMFGRHD 
							inner join Mfgrmaster M on l.mfgrmasterid=m.mfgrmasterid
							INNER JOIN SUPINFO S On ms.uniqsupno=S.UNIQSUPNO where 
							M.mfgr_pt_no=R.Mfgr_pt_no and 
							M.partmfgr=R.Partmfgr and 
							S.SUPNAME=R.SupName and 
							ms.SUPLPARTNO=R.SUPLPARTNO and
							ms.is_deleted=0)
						
				
				
					DELETE R FROM @importResultSet R
					WHERE exists (select 1 from @importSupplierMpnLinkException E where r.rowId=e.rowId and e.lastLoad=1)
					update @importSupplierMpnLinkException set lastLoad=0

				
							
					-- 05/14/15 YS remove count()
					--if((SELECT COUNT(*) FROM @importResultSet)<= 0)
					IF NOT EXISTS (select 1 from @importResultSet)	
					BEGIN --Begin If Block
									
						BEGIN TRY --Begin Try Block
							RAISERROR(@msg,16,1)
						END TRY --End Try Block

						BEGIN CATCH --Begin Catch Block
							--05/17/15 YS remove error log and replace with exception table and return back to user
							--SELECT @errNumber = ERROR_NUMBER();
							--SELECT @errSeverity=ERROR_SEVERITY();
							--SELECT @errProc=ERROR_PROCEDURE();
							--SELECT @errLine=ERROR_LINE();
							--SELECT @errMsg=ERROR_MESSAGE();

							--05/15/15 YS added import id column to the error table
							--05/17/15 YS remove error log and replace with exception table and return back to user
							--EXEC importSupplierMpnErrorAdd @errNumber, @errSeverity,@errProc,@errLine,@errMsg,@importId
							--05/14/15 YS no need to count() again
							---if((SELECT COUNT(*) FROM @importResultSet)=0)
							--BEGIN
					--		COMMIT
							--SELECT * FROM importsuppliermpnlinkerror where importid=@importId
							--05/17/15 YS insert into exception table and return back to user
							INSERT INTO importSupplierMpnLinkException  
							(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
							select importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg
							from @importSupplierMpnLinkException
							
							select * from importSupplierMpnLinkException where importid=@importId
							RETURN -1
							--END
						END CATCH --End Catch Block
					END -- IF NOT EXISTS (select 1 from @importResultSet)
				END -- EXISTS (SELECT 1 from invtmfsp ms inner join invtmfhd M on ms.UNIQMFGRHD=m.UNIQMFGRHD...
			

				
		

     		--validation 5)If user sends preferred flag as true update pfdsupl to false for the existing parts
			--05/15/15 YS remove begin try
			--05/14/15 YS change update
			--05/15/15 YS start begin transaction
			INSERT INTO importSupplierMpnLinkException  
			(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
			select importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg
			from @importSupplierMpnLinkException

			BEGIN TRANSACTION		
				Update INVTMFSP set PFDSUPL=0 
					where EXISTS 
					--03/28/16 YS removed invtmfhd table
					(SELECT 1 FROM Invtmpnlink L inner join MfgrMaster M on l.mfgrmasterid=m.mfgrmasterid 
					INNER JOIN @importResultSet R on R.Partmfgr=M.PARTMFGR and R.Mfgr_pt_no=M.MFGR_PT_NO 
						---05/14/15 YS update pfdsupl at the top of the procedure
					where  R.PFDSUPL='1' and INVTMFSP.UNIQMFGRHD=L.UNIQMFGRHD)
				
				

				 --update invtmfsp table if record already exists and marked as deleted
				-- 05/14/15 move this code before the insert
				-- 05/15/15 change to make sure when is_deleted become 0 update pfdsupl 
				;WITH updateIsDeleted
				AS
				(
				--03/28/16 YS removed invtmfhd table
				select l.uniqmfgrhd,l.uniq_key,U.*,ise.uniqmfsp from @importResultSet U
						inner join mfgrmaster m on m.partmfgr=u.partmfgr and m.mfgr_pt_no=u.mfgr_pt_no
					inner join invtmpnlink L On l.MfgrMasterId=m.MfgrMasterId
					inner join supinfo s on u.supname=s.supname
				cross apply
				(select UNIQMFSP,uniqsupno,is_deleted,pfdsupl from  invtmfsp ms 
					where ms.IS_DELETED=1 and ms.uniqsupno=s.uniqsupno and ms.SUPLPARTNO=u.suplpartno and ms.UNIQMFGRHD=l.UNIQMFGRHD) ISE 
				)
				Update Invtmfsp set is_deleted=0 ,pfdsupl=updateIsDeleted.pfdsupl
					FROM updateIsDeleted where updateIsDeleted.UNIQMFSP=InvtMfsp.UNIQMFSP
				-- 05/14/15 YS remove potential duplicates
				--03/28/16 YS removed invtmfhd table
				DELETE R FROM @importResultSet  R 
					Where EXISTS (SELECT 1 from invtmfsp ms inner join invtmpnlink L on ms.UNIQMFGRHD=l.UNIQMFGRHD 
					inner join Mfgrmaster M on l.MfgrMasterId=m.MfgrMasterId
					INNER JOIN SUPINFO S On ms.uniqsupno=S.UNIQSUPNO where 
					M.mfgr_pt_no=R.Mfgr_pt_no and 
					M.partmfgr=R.Partmfgr and 
					S.SUPNAME=R.SupName and 
					ms.SUPLPARTNO=R.SUPLPARTNO)
							
							
							
						
						
						--03/28/16 YS removed invtmfhd table
						INSERT INTO [dbo].[INVTMFSP]
				           ([UNIQMFGRHD]
				           ,[UNIQMFSP]
						   ,[uniqsupno]
						   ,[SUPLPARTNO]
						   ,[UNIQ_KEY]
						   ,[PFDSUPL]
						   ,[IS_DELETED])
							SELECT l.Uniqmfgrhd           
						   ,dbo.fn_GenerateUniqueNumber() as UNIQMFSP
                           ,S.UNIQSUPNO
                           ,R.SUPLPARTNO
                           ,l.UNIQ_KEY 
                           ,case 
						   when R.PFDSUPL='1' then 1 else 0 End as PFDSUPL
                           ,0 as IS_DELETED
						   --03/28/16 YS removed invtmfhd table
						FROM @importResultSet  R INNER JOIN MfgrMaster M on R.PartMfgr=M.Partmfgr
                             and R.Mfgr_pt_no=M.Mfgr_pt_no
							 inner join Invtmpnlink L on m.mfgrmasterid=l.mfgrmasterid
                             INNER JOIN Inventor I ON I.Uniq_key=l.Uniq_key
                             INNER JOIN SUPINFO S ON S.SUPNAME=R.Supname
                             where I.Part_sourc<>'PHANT' and I.Part_sourc<>'CONSG'
							 
							 --05/14/15 YS remove rowcount check use transaction count
					

							-- BEGIN --Begin if block
						IF @@TRANCOUNT>0
						BEGIN
							 COMMIT
							 --05/17/15 YS return any exceptions to a user
							 select * from importSupplierMpnLinkException where importid=@importId
							 RETURN 

						 END --End If block

					-- 05/14/15 cannot have multiple commit with only one begin transaction
					--COMMIT--Commit changes to database
				select * from importSupplierMpnLinkException where importid=@importId
	END TRY--End Try Block

	BEGIN CATCH --outside Begin Catch Block
		--05/14/15 YS un-used variable
		--SET @lRollback=1
		--05/15/15 YS remove the next insert
		--INSERT INTO @ErrTable (ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg)--Insert into error table if errors occurs while reading xml
		--05/15/15 YS assign to error varibales
		--SELECT
			SELECT @errNumber = ERROR_NUMBER();
			SELECT @errSeverity=ERROR_SEVERITY();
			SELECT @errProc=ERROR_PROCEDURE();
			SELECT @errLine=ERROR_LINE();
			SELECT @errMsg=ERROR_MESSAGE();
			--ERROR_NUMBER() AS ErrorNumber
			--,ERROR_SEVERITY() AS ErrorSeverity
			----,ERROR_STATE() AS ErrorState
			--,ERROR_PROCEDURE() AS ErrorProcedure
			--,ERROR_LINE() AS ErrorLine
			--,ERROR_MESSAGE() AS ErrorMessage;
			
			-- 05/14/15 YS have to check if the transaction count >0
			if @@TRANCOUNT>0
				ROLLBACK --RollBack transaction if error occurs
			--05/17/15 YS insert into importSupplierMpnLinkException instead
			--05/19/15 YS cannot insert null for the primary keys importid and rowid
			INSERT INTO importSupplierMpnLinkException  
			(importid ,rowId , Partmfgr ,Mfgr_pt_no,SupName ,SUPLPARTNO ,  exceptionMsg )
			VALUES (@importId,newid(),'','','','',@errMsg)
		--BEGIN TRY --Begin Try Block
				--05/15/15 YS added import id column to the error table
				--05/17/15 YS remove error log use importSupplierMpnLinkException
				--EXEC importSupplierMpnErrorAdd @errNumber, @errSeverity,@errProc,@errLine,@errMsg,@importId
			--SELECT DISTINCT ErrNumber,ErrSeverity,ErrProc,ErrLine,ErrMsg FROM @ErrTable
		--END TRY --End Try Block

		--BEGIN CATCH -- Begin catch block

		--	SELECT
		--	ERROR_NUMBER() AS ErrorNumber
		--	,ERROR_SEVERITY() AS ErrorSeverity
		--	--,ERROR_STATE() AS ErrorState
		--	,ERROR_PROCEDURE() AS ErrorProcedure
		--	,ERROR_LINE() AS ErrorLine
		--	,ERROR_MESSAGE() AS ErrorMessage;

		--END CATCH --End Catch block
		--SELECT	*	FROM @ErrTable
		SELECT * from importSupplierMpnLinkerror where importid=@importId
		SELECT 'Problems uploading file' AS uploadError
		RETURN -1
	END CATCH	--End Final catch block
	
END 