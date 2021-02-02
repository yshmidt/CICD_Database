CREATE TABLE [dbo].[issueSerial] (
    [iIssueSerUnique] CHAR (10) CONSTRAINT [DF_issueSerial_iIssueSerUnique] DEFAULT ('') NOT NULL,
    [invtisu_no]      CHAR (10) CONSTRAINT [DF_issueSerial_invtisu_no] DEFAULT ('') NOT NULL,
    [serialno]        CHAR (30) CONSTRAINT [DF_issueSerial_serialno] DEFAULT ('') NOT NULL,
    [serialuniq]      CHAR (10) CONSTRAINT [DF_issueSerial_serialuniq] DEFAULT ('') NOT NULL,
    [ipkeyunique]     CHAR (10) CONSTRAINT [DF_issueSerial_ipkeyunique] DEFAULT ('') NOT NULL,
    [kaseqnum]        CHAR (10) CONSTRAINT [DF_issueSerial_kaseqnum] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_issueSerial] PRIMARY KEY CLUSTERED ([iIssueSerUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtisu_no]
    ON [dbo].[issueSerial]([invtisu_no] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkeyunique]
    ON [dbo].[issueSerial]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [serialno]
    ON [dbo].[issueSerial]([serialno] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[issueSerial]([serialuniq] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_issueSerialKit]
    ON [dbo].[issueSerial]([kaseqnum] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/08/2014
-- Description:	Inventory Issue Serialize parts with or w/o IPkey
-- Modified :	08/14/14 YS added validation
--				08/20/14 VL only add comments because think Kit cases should fall in cModid NOT in ('R','W') and T.Wono<>' '
--				09/23/14 Yogesh missing COMMIT
-- 03/17/2016 YS revised for the new structure
-- 06/30/16 YS added code for ipkey. This trigger needs a lot testing. And more work for the issue SF components parts 
-- 07/05/16 YS modified cas when updating invtser. Move NOT IN ('R','W') to the end of the case, otherwise cmodif='S' and 'F' will fall under  NOT IN ('R','W') and populate InvtSer with incorrect information
-- 3/22/18 : Satish B :When issue from Packing List then avoid upating UniqMfgrhd as empty
-- 03/18/20 VL: change the code that update invtser for RMA receiver
-- 03/19/20 VL: changed to SPACE(10) in updating invtser.id_value and update in next SQL
-- 08/10/20 VL added to exclude the Rework WO KIT record created from RMA receiver, in RMA receiver, the two records (one received back (negative issue qty) 
-- and one issued to Rework WO (positive qty) created at the same time, so this SQL statement will return error because the serial number is not in W_KEY yet
-- 08/11/20 VL found I didn't have criteria to link Invtser and Inserted
-- =============================================
CREATE TRIGGER [dbo].[IssueSerial_Insert]
   ON [dbo].[issueSerial]
   AFTER INSERT
AS 
BEGIN
	
	-- 03/17/16 YS added error trap
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	-- find serial numbers and assign new location and new ip key if different
	---!!! we might include validation if serial number exists and current w_key and ipkey matching the one in the transaction
	-- for now will creat for the cycle count and inventory issue, PL cases
	-- add other case later when kitting is done. 
	BEGIN TRY		
		BEGIN TRANSACTION				   
			-- first check if serial number exists
			select * from inserted where serialuniq not IN (SELECT serialuniq from invtSer)
			IF (@@ROWCOUNT<>0)
			BEGIN
				RAISERROR('Cannot find Serial Number to issue. This operation will be cancelled.', -- Message text.
					16, -- Severity.
					1 -- State.
				);
			END  -- IF (@@ROWCOUNT<>0)
			-- check if exists in the correct location

			SELECT inserted.* from INSERTED INNER JOIN Invt_isu on Invt_isu.INVTISU_NO=inserted.invtisu_no
			where Invt_isu.QTYISU>0 
			-- 08/10/20 VL added to exclude the Rework WO KIT record created from RMA receiver, in RMA receiver, the two records (one received back (negative issue qty) 
			-- and one issued to Rework WO (positive qty) created at the same time, so this SQL statement will return error because the serial number is not in W_KEY yet
			AND NOT EXISTS(SELECT 1 FROM Kamain INNER JOIN Woentry ON Kamain.Wono = Woentry.Wono INNER JOIN Somain ON Woentry.Sono = Somain.Sono	
				WHERE Kamain.Wono = Invt_isu.Wono AND Kamain.BOMPARENT = Kamain.Uniq_key AND LINESHORT = 1 
				AND Woentry.JobType = 'REWORK' AND Somain.IS_RMA = 1)
			-- 08/10/20 VL End}

			AND Inserted.serialuniq NOT IN (select SerialUniq from InvtSer where id_key='W_KEY' and id_value=Invt_isu.W_KEY)
			IF (@@ROWCOUNT<>0)
			BEGIN
				
				RAISERROR('Cannot find Serial Number in the given location. This operation will be cancelled.', -- Message text.
					16, -- Severity.
					1 -- State.
				);
			END  

			-- IF (@@ROWCOUNT<>0)
			/* cModid:
				'Y' - cycle count 
				'I' - inventory handling issue
				'R' - RMA Receiver
				'W' - Serial Number assign to Work order. issue record is created by assigning new serial number to rework work order and placing another one instead into inventory
				'S' - Shop Floor
				'K' - Kit issue
				'U' - Kit update
				'C' - Close Kit
				'P' - PO receiving
				'F' - Packing list
				'E' - Edit Line shortage
				'O' - ECO module (ECO partially completed WO update)
			*/
			-- 08/20/14 VL didn't add more case for kit because Kit cases should fall in cModid NOT in ('R','W') and T.Wono<>' ' case
			-- modify InvtSer
			--- !! will have to revisit for each case of issue.
			
			-- 07/05/16 YS modified cas when updating invtser. Move NOT IN ('R','W') to the end of the case, otherwise cmodif='S' and 'F' will fall under  NOT IN ('R','W') and populate InvtSer with incorrect information
			UPDATE InvtSer SET Id_Key = CASE WHEN T.QtyIsu>0 
					THEN				--- CASE T.QtyIsu>0 
						CASE WHEN T.cModId IN ('Y','I') THEN 'INVTISU_NO'
							WHEN T.CMODID in ('R','W') and T.Wono<>' ' THEN 'DEPTKEY' 
							WHEN t.CMODID = 'S' and T.Deptkey<>' '   THEN 'DEPTKEY'     -- Shop Floor tracking transfer 'FGI-WIP'
							WHEN t.cModid='F' THEN 'PACKLISTNO'							-- packing list
							WHEN T.CMODID NOT in ('R','W') and T.Wono<>' ' THEN 'WONO'
							
						END  --- CASE T.cModId
					ELSE		----CASE T.QtyIsu>0 
					'W_KEY'
					END	,		----CASE T.QtyIsu>0 
					Id_Value = CASE WHEN T.QtyIsu>0 
					THEN 
						CASE WHEN T.cModId IN ('Y','I') THEN T.InvtIsu_no
							-- 03/18/20 VL comment out the Quotdept code, will update later, found has consider uniquerout
							-- 03/19/20 VL changed to SPACE(10) and update in next SQL
							--WHEN T.CMODID in ('R','W') and T.Wono<>' ' THEN ISNULL(Q.UniqNumber,space(10))
							 WHEN T.CMODID in ('R','W') and T.Wono<>' ' THEN SPACE(10)
							 WHEN t.CMODID = 'S' and T.Deptkey<>' '   THEN T.DEPTKEY     -- Shop Floor tracking transfer 'FGI-WIP'
							 WHEN t.cModid='F' THEN SUBSTRING(T.IssuedTo,11,10)			-- packing list
							 WHEN T.CMODID NOT in ('R','W') and T.Wono<>' ' THEN T.Wono
						END  --- CASE T.cModId
					ELSE		----CASE T.QtyIsu>0 
						T.W_KEY
					END	,		----CASE T.QtyIsu>0 
					ActvKey = CASE WHEN t.QTYISU>0  
					THEN
						CASE WHEN  t.CMODID = 'S' and T.Deptkey<>' ' THEN T.ACTVKEY ELSE ' ' END
						ELSE -- CASE WHEN t.QTYISU>0 
						' '
						END,	 -- CASE WHEN t.QTYISU>0 	 
					IsReserved = 0,
					ReservedFlag = ' ',
					ReservedNo = ' ' ,
					LotCode = CASE WHEN T.QtyIsu>0
					THEN 
						CASE WHEN  t.CMODID = 'S' and T.Deptkey<>' ' THEN ' ' 
						WHEN t.cModid = 'R' THEN t.LotCode
						ELSE InvtSer.LotCode END
					ELSE -- CASE WHEN T.QtyIsu>0
						T.LotCode
					END -- CASE WHEN T.QtyIsu>0
					,Expdate = CASE WHEN T.QtyIsu>0
					THEN 
						CASE WHEN  t.CMODID = 'S' and T.Deptkey<>' ' THEN NULL 
						WHEN t.cModid = 'R' THEN t.ExpDate
						ELSE InvtSer.ExpDate END
					ELSE -- CASE WHEN T.QtyIsu>0
						T.ExpDate
					END -- CASE WHEN T.QtyIsu>0
					,Reference =CASE WHEN T.QtyIsu>0
					THEN 
						CASE WHEN  t.CMODID = 'S' and T.Deptkey<>' ' THEN ' ' 
						WHEN t.cModid = 'R' THEN t.Reference
						ELSE InvtSer.Reference END
					ELSE -- CASE WHEN T.QtyIsu>0
						T.Reference
					END -- CASE WHEN T.QtyIsu>0
					,UniqMfgrhd =CASE WHEN T.QtyIsu>0
					THEN 
					--- 3/22/18 : Satish B :When issue from Packing List then avoid upating UniqMfgrhd as empty
						--CASE WHEN  t.CMODID = 'F' THEN ' ' ELSE InvtSer.Uniqmfgrhd END
						InvtSer.Uniqmfgrhd
					ELSE -- CASE WHEN T.QtyIsu>0
						T.UniqMfgrhd
					END -- CASE WHEN T.QtyIsu>0
					,Uniq_lot =CASE WHEN T.QtyIsu>0
					THEN 
						CASE WHEN  t.CMODID = 'F' THEN ' ' 
						--- 06/30/16 YS empty Uniq_lot when moving back from FGI to WIP (SF module)
						WHEN  t.CMODID = 'S' and T.Deptkey<>' ' THEN ' ' 
						WHEN t.cModid = 'R' THEN ' '  --- ? uniq_lot
						ELSE InvtSer.Uniq_lot END
					ELSE -- CASE WHEN T.QtyIsu>0
						isnull(L.Uniq_Lot,space(10))   --- check for the uniqlot
					END -- CASE WHEN T.QtyIsu>0 
					,PoNum = CASE WHEN t.QtyIsu>0 THEN InvtSer.Ponum ELSE t.Ponum END,
					Wono = CASE WHEN t.QtyIsu>0 
					THEN
						CASE WHEN t.Wono <> ' ' and T.cModId IN ('R','W') THEN t.Wono ELSE InvtSer.Wono END
					ELSE --- CASE WHEN t.QtyIsu<0 
						CASE WHEN t.cModid = 'R' THEN ISNULL(C.Wono,space(10)) ELSE invtser.wono END
					END	 -- --- CASE WHEN t.QtyIsu<0 
			FROM Inserted I INNER JOIN Invt_isu T on I.invtisu_no =T.INVTISU_NO
			-- 03/18/20 VL comment out the Quotdept code, will update later, found has consider uniquerout
			--LEFT OUTER JOIN Quotdept Q ON Q.Uniq_key=T.Uniq_key and Q.Dept_id='STAG'
			OUTER APPLY (SELECT cmdetail.WOno FROM CmDetail 
					WHERE CmDetail.PACKLISTNO=SUBSTRING(T.IssuedTo,10,10) 
					and CmDetail.UNIQUELN=t.UniqueLn ) C
			OUTER APPLY (select Uniq_lot FROM Invtlot 
					WHERE InvtLot.Lotcode=T.Lotcode 
					and isnull(Invtlot.ExpDate,1)=ISNULL(T.ExpDate,1) 
					and InvtLot.Reference=T.Reference
					and InvtLot.Ponum=T.Ponum) L
			WHERE InvtSer.Serialuniq=I.SerialUniq			

			--  03/18/20 VL update Id_value from Quotdept if cModid in ('R','W')
			-- 08/11/20 VL found I didn't have criteria to link Invtser and Inserted
			UPDATE Invtser	
				SET Id_Value = Q.UNIQNUMBER
				FROM Inserted I 
				INNER JOIN Invt_isu T ON I.invtisu_no = T.INVTISU_NO
				INNER JOIN QUOTDEPT Q ON Q.UNIQ_KEY = T.UNIQ_KEY
				INNER JOIN Woentry W On Q.uniqueRout = W.uniquerout AND W.Uniq_key = Q.Uniq_key AND W.Wono = T.Wono
				WHERE Q.DEPT_ID = 'STAG'
				AND Invtser.Serialuniq = I.Serialuniq
				AND T.CMODID in ('R','W') and T.Wono<>' ' 

			-- 06/30/16 YS if useIpkey need to insert a record into iIssueipkey
			  INSERT INTO  [dbo].[issueIpKey]
				([issueIpKeyUnique]
				,[invtisu_no]
				,[qtyIssued]
				,[ipkeyunique]
				,[kaseqnum]
				 ) 
				SELECT dbo.fn_GenerateUniqueNumber() as [issueIpKeyUnique],
						I.invtisu_no,
						case when S.qtyIsu>=0
						THEN COUNT(I.Serialno) 
						ELSE
						-COUNT(I.Serialno) END as [qtyIssued],
						I.ipkeyunique,i.kaseqnum
				FROM Inserted I 
				INNER JOIN Invt_isu S on I.invtisu_no=S.INVTISU_NO
				INNER join inventor m on s.uniq_key=m.uniq_key
				WHERE M.UseIpkey=1
				GROUP BY I.invtisu_no,I.ipkeyunique,S.qtyIsu,i.kaseqnum	

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
	--09/23/14 Yogesh missing COMMIT
	IF @@TRANCOUNT <>0
		COMMIT TRANSACTION
END