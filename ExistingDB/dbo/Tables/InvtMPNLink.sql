CREATE TABLE [dbo].[InvtMPNLink] (
    [uniq_key]           CHAR (10) CONSTRAINT [DF_InvtMPNLink_uniq_key] DEFAULT ('') NOT NULL,
    [uniqmfgrhd]         CHAR (10) CONSTRAINT [DF_InvtMPNLink_uniqmfgrhd] DEFAULT ('') NOT NULL,
    [is_deleted]         BIT       CONSTRAINT [DF_InvtMPNLink_is_deleted] DEFAULT ((0)) NOT NULL,
    [MfgrMasterId]       BIGINT    CONSTRAINT [DF_InvtMPNLink_MfgrMasterKey] DEFAULT ('') NOT NULL,
    [orderpref]          INT       CONSTRAINT [DF_InvtMPNLink_orderpref] DEFAULT ((99)) NOT NULL,
    [IsSynchronizedFlag] BIT       DEFAULT ((0)) NULL,
    CONSTRAINT [uniqmfgrhd] PRIMARY KEY CLUSTERED ([uniqmfgrhd] ASC)
);


GO
CREATE NONCLUSTERED INDEX [MfgrMaster]
    ON [dbo].[InvtMPNLink]([MfgrMasterId] ASC);


GO
CREATE NONCLUSTERED INDEX [uniq_key]
    ON [dbo].[InvtMPNLink]([uniq_key] ASC);


GO
CREATE NONCLUSTERED INDEX [InvtMPNLink_is_deleted]
    ON [dbo].[InvtMPNLink]([is_deleted] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 03/26/2015
-- Description:	Update trigger
-- Modified : 
-- =============================================
CREATE TRIGGER [dbo].[InvtMpnLink_Update] 
   ON  [dbo].[InvtMPNLink] 
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	DECLARE @generateMessage varchar(max)=' '
	---if is_deleted changed from 0 to 1 validate
	If EXISTS (select 1 FROM Inserted I inner join Deleted D ON I.UniqMfgrHd=D.UniqMfgrhd where I.is_deleted=1 and D.is_deleted=0)
	BEGIN
		-- check qty_oh
		if EXISTS(select 1 from Invtmfgr Q inner join Inserted I on Q.uniqmfgrhd=I.Uniqmfgrhd 
							INNER JOIN Deleted D on Q.Uniqmfgrhd=D.Uniqmfgrhd
							where I.is_deleted=1 and D.is_deleted=0
							and Q.Qty_oh<>0)
		BEGIN 
			select @generateMessage=
				STUFF((SELECT ', Partmfgr: '+RTRIM(M.PartMfgr)+' MPN: '+RTRIM(M.Mfgr_pt_no)+' '+
				'Warehouse/Location: '+RTRIM(W.Warehouse)+'/'+CASE WHEN Q.location<>'' THEN RTRIM(Q.Location) ELSE '' END +' '+
				'Part No/Rev: '+RTRIM(i1.Part_no)+CASE WHEN I1.Revision<>'' THEN '/'+RTRIM(I1.revision) else '' END
				from Invtmfgr Q inner join Inserted I on Q.uniqmfgrhd=I.Uniqmfgrhd 
							INNER JOIN Deleted D on Q.Uniqmfgrhd=D.Uniqmfgrhd
							INNER JOIN MfgrMaster M ON I.mfgrMasterid=M.MfgrMasterId
							INNER JOIN Warehous W ON W.Uniqwh=Q.Uniqwh
							inner join Inventor i1 on I1.Uniq_key=q.uniq_key
							where I.is_deleted=1 and D.is_deleted=0
							and Q.Qty_oh<>0
			order by i1.part_no,I1.revision,m.partmfgr,m.mfgr_pt_no
			FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), 1, 2,'')  
			SET @generateMessage = 'You have quantities on hand for the AML(s) you are trying to remove. System cannot delete requested AML. Additional Information: '+@generateMessage
				RAISERROR(@generateMessage,1,1)
				ROLLBACK TRANSACTION   
		RETURN 
		END -- check qty_oh
		--check for cycle count flag
		if EXISTS(select 1 from Invtmfgr Q inner join Inserted I on Q.uniqmfgrhd=I.Uniqmfgrhd 
							INNER JOIN Deleted D on Q.Uniqmfgrhd=D.Uniqmfgrhd
							where I.is_deleted=1 and D.is_deleted=0
							and Q.COUNTFLAG<>' ')
		BEGIN 
			select @generateMessage=
				STUFF((SELECT ', Partmfgr: '+RTRIM(M.PartMfgr)+' MPN: '+RTRIM(M.Mfgr_pt_no)+' '+
				'Warehouse/Location: '+RTRIM(W.Warehouse)+'/'+CASE WHEN Q.location<>'' THEN RTRIM(Q.Location) ELSE '' END +' '+
				'Part No/Rev: '+RTRIM(i1.Part_no)+CASE WHEN I1.Revision<>'' THEN '/'+RTRIM(I1.revision) else '' END
				from Invtmfgr Q inner join Inserted I on Q.uniqmfgrhd=I.Uniqmfgrhd 
							INNER JOIN Deleted D on Q.Uniqmfgrhd=D.Uniqmfgrhd
							INNER JOIN MfgrMaster M ON I.mfgrMasterid=M.MfgrMasterId
							INNER JOIN Warehous W ON W.Uniqwh=Q.Uniqwh
							inner join Inventor i1 on I1.Uniq_key=q.uniq_key
							where I.is_deleted=1 and D.is_deleted=0
							and Q.COUNTFLAG<>' '
			order by i1.part_no,I1.revision,m.partmfgr,m.mfgr_pt_no
			FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), 1, 2,'')  
			SET @generateMessage = 'The AML(s), you are trying to remove, are in the process of a physical inventory or cycle count. System cannot delete requested AML. Additional Information: '+@generateMessage
				RAISERROR(@generateMessage,1,1)
				ROLLBACK TRANSACTION   
		RETURN 
		END -- check for cyclecount flag

		-- check for open pos
		if EXISTS(select 1 from poitems poi inner join Inserted I on i.uniqmfgrhd=poI.Uniqmfgrhd 
							INNER JOIN Deleted D on poi.Uniqmfgrhd=D.Uniqmfgrhd
							INNER JOIN Pomain PO ON PO.ponum=poi.ponum
							where I.is_deleted=1 and D.is_deleted=0
							AND  Poi.lcancel = 0 and Poi.Ord_qty>poi.Acpt_qty and Po.postatus <> 'CANCEL'
							AND  Po.postatus <>  'CLOSED')
		BEGIN
			select @generateMessage=
				STUFF((SELECT ', Partmfgr: '+RTRIM(M.PartMfgr)+' MPN: '+RTRIM(M.Mfgr_pt_no)+' '+
				'PO #: '+RTRIM(PO.Ponum)+' Item #: '+poi.Itemno
				From poitems poi inner join Inserted I on I.uniqmfgrhd=poI.Uniqmfgrhd 
							INNER JOIN Deleted D on poi.Uniqmfgrhd=D.Uniqmfgrhd
							INNER JOIN Mfgrmaster M on m.mfgrmasterid=I.mfgrmasterid
							INNER JOIN Pomain PO ON PO.ponum=poi.ponum
							where I.is_deleted=1 and D.is_deleted=0
							AND  Poi.lcancel = 0 and Poi.Ord_qty>poi.acpt_qty and Po.postatus <> 'CANCEL'
							AND  Po.postatus <>  'CLOSED'
						order by m.partmfgr,m.mfgr_pt_no,poi.ponum,poI.itemno
			FOR XML PATH (''), TYPE).value('.','VARCHAR(max)'), 1, 2,'')  
			SET @generateMessage = 'The AML(s), you are trying to remove, are on one or more open purchase orders. System cannot delete requested AML. Additional Information: '+@generateMessage
				RAISERROR(@generateMessage,1,1)
				ROLLBACK TRANSACTION   
		RETURN 

		END ----- check for open pos
		-- 10/03/15  Sachins S -update IsSynchronizedFlag to 0,WHEN update the from web service		
	update InvtMPNLink set IsSynchronizedFlag=
						  CASE WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 1) THEN 0
						       WHEN (I.IsSynchronizedFlag = 1 and D.IsSynchronizedFlag = 0) THEN 1
						ELSE 0 END
			FROM inserted I inner join deleted D on i.uniqmfgrhd=d.uniqmfgrhd
			where I.uniqmfgrhd =InvtMPNLink.uniqmfgrhd 
	
	--08/17/17 Vijay G  if mfgrmaster is_deleted flag become 1 update related record Invtmfgr is_deleted with 1
	UPDATE Invtmfgr SET IS_DELETED=1 
		FROM Inserted I INNER JOIN Invtmfgr mfgr on I.uniq_key=mfgr.UNIQ_KEY 
		where I.IS_DELETED =1 and mfgr.IS_DELETED=0 and mfgr.UNIQMFGRHD= i.uniqmfgrhd and mfgr.UNIQ_KEY= i.uniq_key
		

	-- 10/03/15  Sachins S -delete the record from SynchronizationMultiLocationLog while upadte the records  
	--if one location already synchronized and other location not getting synchronized
		IF EXISTS (SELECT 1 FROM inserted where IsSynchronizedFlag=0)
			BEGIN
			    DELETE FROM SynchronizationMultiLocationLog 
				WHERE EXISTS (SELECT 1 FROM Inserted where IsSynchronizedFlag=0 and Inserted.uniqmfgrhd=SynchronizationMultiLocationLog.Uniquenum);
			END 

			
	END -- If EXISTS (select 1 FROM Inserted I inner join Deleted D ON I.UniqMfgrHd=D.UniqMfgrhd where I.is_deleted=1 and D.is_deleted=0

	IF @@TRANCOUNT<>0
		COMMIT
END