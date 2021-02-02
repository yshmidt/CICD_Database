CREATE TABLE [dbo].[iTransferipkey] (
    [ixferIpKeyUnique] CHAR (10)       CONSTRAINT [DF_iTransferipkey_ixferIpKeyUnique] DEFAULT ('') NOT NULL,
    [invtxfer_n]       CHAR (10)       CONSTRAINT [DF_iTransferipkey_invtxfer_n] DEFAULT ('') NOT NULL,
    [qtyTransfer]      NUMERIC (12, 2) CONSTRAINT [DF_iTransferipkey_qtyTransfer] DEFAULT ((0)) NOT NULL,
    [fromIpkeyunique]  CHAR (10)       CONSTRAINT [DF_iTransferipkey_fromIpkeyunique] DEFAULT ('') NOT NULL,
    [toIpkeyunique]    CHAR (10)       CONSTRAINT [DF_iTransferipkey_toIpkeyunique] DEFAULT ('') NOT NULL,
    CONSTRAINT [PK_ixferIpKeyUnique] PRIMARY KEY CLUSTERED ([ixferIpKeyUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [fromipkey]
    ON [dbo].[iTransferipkey]([fromIpkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [invtxfer_n]
    ON [dbo].[iTransferipkey]([invtxfer_n] ASC);


GO
CREATE NONCLUSTERED INDEX [toipkey]
    ON [dbo].[iTransferipkey]([toIpkeyunique] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 08/08/2014
-- Description:	Inventory Transfer with IPkey Insert Trigger
-- Modified : 08/20//14 YS add where to "insert" code, for ipkey "from" and "to" has to be different
-- Modified : 02/08/2017 Satish B : isAllocated column is not present in IPKEY table as per new database structure
-- Modified : 02/08/2017 Satish B : Check condition if fromIpKeyUniqe and toIpKeyUniq are equal for Manual Reject Entry
-- Modified : 02/08/2017 Satish B : Update the pkgBalance of IPKEYUNIQ 
-- Modified : 04/24/2017 Satish B : Check weather the FROMWKEY  has MRB warehouse or not
-- Modified : 04/24/2017 Satish B : If FROMWKEY has MRB warehouse then update the pkgBalance of thet IPKEYUNIQ which has MRB warehouse
-- Modified : 05/22/2017 Satish B : Check INVTMFGR.UNIQWH is of MRB warehouse (Cheak 'equal to' instade of not 'equal to')
-- Modified : 11/22/2017 Shrikant B :Modify the Code for the Put Entry on the IpKey table for the ToIpkeyUnique if not exists in ipkey
-- Modified : 02/18/2020 Sachin B :Modify the Code for the Put Entry on the IpKey table for the TOWKEY if not exists in ipkey to avoid future issue of not getting data of sfbl warehouse ifmtc alreaady breaks in another sfbl warehouse
-- =============================================
CREATE TRIGGER [dbo].[iTransferIpKey_Insert]
   ON [dbo].[iTransferipkey]
   AFTER INSERT
AS 
BEGIN
	-- if fromipkey and toipkey is the same, find ipkey record and update w_key, no changes to qty
	-- if toipkey is different create new ipkey record
	--!!! talk to Vicky, if over-issued first issue and then transfer to keep correct pkgBalance 
	-- 'to' the same as 'from' ipkey
	--02/08/2017 Satish B : Check condition if fromIpKeyUniqe and toIpKeyUniq are equal for Manual Reject Entry
	DECLARE @wKey char(10)
	IF EXISTS(SELECT fromIpkeyunique,toIpkeyunique FROM Inserted WHERE fromIpkeyunique=toIpkeyunique) 
		BEGIN
			UPDATE IpKey Set W_KEY = t.toWkey ,pkgBalance=i.qtyTransfer
						FROM Invttrns t 
						INNER JOIN Inserted I ON t.INVTXFER_N =i.invtxfer_n 
						where i.fromIpkeyunique=i.toIpkeyunique
						AND i.fromIpkeyunique=Ipkey.IPKEYUNIQUE
			--'to' is different than 'from' -- insert new ipkey
		 END
	 ELSE
		BEGIN
			--02/14/2017 Satish B : Update the pkgBalance of IPKEYUNIQ 
			UPDATE IpKey SET pkgBalance=pkgBalance-i.qtyTransfer
										FROM Invttrns t 
										INNER JOIN Inserted I ON t.INVTXFER_N =i.invtxfer_n 
										WHERE  i.fromIpkeyunique=Ipkey.IPKEYUNIQUE

			--04/24/2017 Satish B : Check weather the FROMWKEY has MRB warehouse or not
			SELECT @wKey= INVTMFGR.W_KEY FROM INVTMFGR INVTMFGR
			INNER JOIN  INVTTRNS T ON T.FROMWKEY=INVTMFGR.W_KEY
			INNER JOIN  Inserted I ON I.invtxfer_n=T.INVTXFER_N
			--05/22/2017 Satish B : Check INVTMFGR.UNIQWH is of MRB warehouse (Cheak 'equal to' instade of not 'equal to')
			WHERE INVTMFGR.UNIQWH =(SELECT UNIQWH FROM WAREHOUS WHERE WAREHOUSE='MRB')

			--04/24/2017 Satish B : If FROMWKEY has MRB warehouse then update the pkgBalance of that IPKEYUNIQ which has MRB warehouse
			IF @wKey<>''
				BEGIN
					UPDATE IpKey SET pkgBalance=pkgBalance+i.qtyTransfer
									FROM Invttrns t 
									INNER JOIN Inserted I ON t.INVTXFER_N =i.invtxfer_n 
									WHERE  i.toIpkeyunique=Ipkey.IPKEYUNIQUE
				END
			ELSE
				 BEGIN
				     -- Modified : 11/22/2017 Shrikant B :Modify the Code for the Put Entry on the IpKey table for the ToIpkeyUnique if not exists in ipkey
					 -- Modified : 02/18/2020 Sachin B :Modify the Code for the Put Entry on the IpKey table for the TOWKEY if not exists in ipkey to avoid future issue of not getting data of sfbl warehouse ifmtc alreaady breaks in another sfbl warehouse
					 IF NOT EXISTS (SELECT * FROM IPKEY ip 
					                         INNER JOIN inserted i ON i.toIpkeyunique = ip.IPKEYUNIQUE 				 
					                         INNER JOIN INVTTRNS T ON I.invtxfer_n=t.INVTXFER_N  AND T.TOWKEY =ip.W_KEY 
								   )
						 BEGIN
						  --08/20//14 YS add where to "insert" code,  for ipkey from and to has to be different
					INSERT INTO [dbo].[IPKEY]
						   ([IPKEYUNIQUE]
						   ,[UNIQ_KEY]
						   ,[UNIQMFGRHD]
						   ,[LOTCODE]
						   ,[REFERENCE]
						   ,[EXPDATE]
						   ,[PONUM]
						   ,[RecordId]
						   ,[TRANSTYPE]
						   ,[originalPkgQty]
						   ,[pkgBalance]
						   ,[fk_userid]
						   ,[recordCreated]
						   ,[W_KEY]
						   --02/08/2017 Satish B : isAllocated column is not present in IPKEY table as per new database structure
						   --,[isAllocated]
						   ,[originalIpkeyUnique])
					 SELECT I.toIpkeyunique,
							T.UNIQ_KEY,
							t.UNIQMFGRHD,
							T.LOTCODE, 
							T.REFERENCE,
							T.EXPDATE, 
							T.PONUM,
							T.InvtXfer_n,       
									'T' AS TRANSTYPE,
									I.qtyTransfer AS originalPkgQty,
									I.qtyTransfer AS pkgBalance,
							T.fk_userid,
							T.[DATE] [recordCreated],
									T.TOWKEY AS W_key,
							--02/08/2017 Satish B : isAllocated column is not present in IPKEY table as per new database structure
							--0 as isAllocated,
									I.fromIpkeyunique AS originalIpkeyUnique 
									FROM Inserted I 
									INNER JOIN INVTTRNS T ON I.invtxfer_n=t.INVTXFER_N 
									WHERE i.fromIpkeyunique<>i.toIpkeyunique
						 END
					 ELSE
						 BEGIN
						  UPDATE IpKey SET pkgBalance=pkgBalance+i.qtyTransfer
						  FROM Inserted I WHERE i.toIpkeyunique=Ipkey.IPKEYUNIQUE
						 END				 
                 END
	   END
END