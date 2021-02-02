CREATE TABLE [dbo].[iRecSerial] (
    [iRecSeriUnique]   CHAR (10) CONSTRAINT [DF_ReceiveSerial_iRecSeriUnique] DEFAULT ('') NOT NULL,
    [invtrec_no]       CHAR (10) CONSTRAINT [DF_ReceiveSerial_invtrec_no] DEFAULT ('') NOT NULL,
    [serialno]         CHAR (30) CONSTRAINT [DF_ReceiveSerial_serialno] DEFAULT ('') NOT NULL,
    [serialuniq]       CHAR (10) CONSTRAINT [DF_ReceiveSerial_serialuniq] DEFAULT ('') NOT NULL,
    [ipkeyunique]      CHAR (10) CONSTRAINT [DF_ReceiveSerial_ipkeyunique] DEFAULT ('') NOT NULL,
    [IsGeneralReceive] BIT       CONSTRAINT [DF__iRecSeria__IsGen__0D29C0D5] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ReceiveSerial] PRIMARY KEY CLUSTERED ([iRecSeriUnique] ASC)
);


GO
CREATE NONCLUSTERED INDEX [invtrec_no]
    ON [dbo].[iRecSerial]([invtrec_no] ASC);


GO
CREATE NONCLUSTERED INDEX [ipkey]
    ON [dbo].[iRecSerial]([ipkeyunique] ASC);


GO
CREATE NONCLUSTERED INDEX [serialno]
    ON [dbo].[iRecSerial]([serialno] ASC);


GO
CREATE NONCLUSTERED INDEX [serialuniq]
    ON [dbo].[iRecSerial]([serialuniq] ASC);


GO
-- =============================================
-- Author:		Yelena Shmist
-- Create date: 08/04/2014
-- Description:	inserrt trigger for iRecSerial (for new ip key insert separate serial number from invt_rec table)
-- when record is incerted into iRecSerial table 
--- 1. check if ipkey is traceable for the part and insert new ipkey or update quantities of the ipkey
--  2. insert new record into invtser table check for duplicate
-- 08/05/14 YS more modifications
-- 08/12/14 YS we allow multiple desktop user link to the same aspnet_users record. Will pick the first on the list, 
--eventully saveinit will be changed to save aspnet_Users.Userid
--08/20/14 YS verify number of serial numbers against received qty and if no match abort the transaction or if parts are not serialized
--08/21/14 YS cannot verify if insert command is separate for each serial number
-- 06/26/16 YS modify code according to the new structure
-- 06/30/2016 Sachin B change the code for Id_key=i.id_value to Id_key=i.ID_KEY
--Sachin B 07/13/2106 update the ipkeyunique column also
--03/02/18 YS changed lotcode size to 25
-- Nilesh S 3/12/2018 Check existing serial number for buy part
-- Nilesh S 3/12/2018 Check existing serial number for make part
-- Nilesh Sa 3/13/2018 Modified to filter serial number from general receiving
-- Nilesh Sa 3/13/2018 This condition will validated only if from general receiving
-- Nilesh Sa 3/14/2018 Not to validate if SN is ship to any packing list
-- Nilesh Sa 3/14/2018 As per discussion with Yelena Modified the condition only with PACKLISTNO or DEPTKEY
-- Rajendra K  9/1/2019 Added Condition for SN
-- =============================================
CREATE TRIGGER [dbo].[IRecSerial_Insert] ON [dbo].[iRecSerial] 
	AFTER INSERT
AS

BEGIN

	SET NOCOUNT ON;
	--08/20/14 YS added qtyrec from invt_rec table to verify number of serial numbers, added serialyes
	--03/02/18 YS changed lotcode size to 25
	DECLARE @tinserted table ([SERIALUNIQ] char(10)
           ,[SERIALNO] char(30)
           ,[UNIQ_KEY] char(10)
           ,[UNIQMFGRHD] char(10)
           ,[UNIQ_LOT] char(10)
           ,[ID_KEY] char(10)
           ,[ID_VALUE] char(10)
           ,[SAVEDTTM] smalldatetime
           ,[SAVEINIT] char(8)
           ,[LOTCODE] nvarchar(25)
           ,[EXPDATE] smalldatetime
           ,[REFERENCE] char(12)
           ,[PONUM] char(15)
           ,[ISRESERVED] bit
           ,[ACTVKEY] char(10)
           ,[OLDWONO] char(10)
           ,[WONO] char(10)
           ,[RESERVEDFLAG] char(10)
           ,[RESERVEDNO] char(10)
           ,[ipkeyunique] char(10)
		   ,[UseIpkey] bit 
		   ,[fk_userId] uniqueidentifier
		   ,[invtrec_no] char(10)
		   ,[QtyRec] numeric(12,2) 
		   ,[SerialYes] bit
		   ,[IsGeneralReceive] BIT)
--08/20/14 YS added qtyrec from invt_rec table to verify number of serial numbers
	INSERT INTO @tinserted (
			[SERIALUNIQ]
           ,[SERIALNO]
           ,[UNIQ_KEY]
           ,[UNIQMFGRHD]
           ,[UNIQ_LOT]
           ,[ID_KEY]
           ,[ID_VALUE]
           ,[SAVEDTTM]
           ,[SAVEINIT]
           ,[LOTCODE]
           ,[EXPDATE]
           ,[REFERENCE]
           ,[PONUM]
           ,[ISRESERVED]
           ,[ACTVKEY]
           ,[OLDWONO]
           ,[WONO]
           ,[RESERVEDFLAG]
           ,[RESERVEDNO]
           ,[ipkeyunique]
		   ,UseIpkey
		   ,fk_userId
		   ,invtrec_no
		   ,QtyRec
		   ,SerialYes
		   ,IsGeneralReceive -- Nilesh Sa 3/13/2018 Modified to filter serial number from general receiving
		   )
	 SELECT I.SERIALUNIQ
           ,I.SERIALNO           
		   ,R.UNIQ_KEY
           ,R.UNIQMFGRHD
           ,R.UNIQ_LOT
           ,'W_KEY' as ID_KEY
           ,R.W_key
           ,getdate()
		   ,r.SAVEINIT
           ,R.LOTCODE
           ,R.EXPDATE
           ,R.REFERENCE
           ,' ' as ponum
           ,0 as ISRESERVED
           ,' ' as ACTVKEY
           ,' ' as OLDWONO
		   ,' ' as WONO
           ,' ' as RESERVEDFLAG
           ,' ' as RESERVEDNO 
           ,I.ipkeyunique 
		   ,p.useipkey
		   ,R.fk_userid
		   ,i.invtrec_no
		   ,r.QTYREC
		   ,p.SERIALYES
		   ,I.IsGeneralReceive -- Nilesh Sa 3/13/2018 Modified to filter serial number from general receiving
		   FROM Inserted I inner join Invt_rec R on I.invtrec_no=R.INVTREC_NO 
		   INNER JOIN Inventor P on R.UNIQ_KEY=P.UNIQ_KEY
		   -- 06/28/16 YS no need to get userid, invt_rec already has one. We are about to rmeove it anyway
		   ---- 08/12/14 YS we allow multiple desktop user link to the same aspnet_users record. Will pick the first on the list, 
		   ----eventully saveinit will be changed to save aspnet_Users.Userid
		   --outer apply 
		   --(select top 1 users.firstname,users.userid,fk_aspnetUsers from users where R.fk_userid=users.fk_aspnetUsers order by users.UNIQ_USER) U
		  
	--08/20/14 YS  verify if serial number is entered for parts that are not serialized
	IF EXISTS (SELECT 1 FROM @tinserted Where SerialYes=0)
	BEGIN
		RAISERROR('Cannot insert serial number for a none-serialized part.',1,1);
		IF @@TRANCOUNT<>0
			ROLLBACK TRANSACTION
		RETURN
	END	 -- EXISTS (SELECT COUNT(*),QtyRec,Invtrec_no	 
	-- verify if number of serial numbers are the same as qtyrec
--08/21/14 YS cannot verify if insert command is separate for each serial number
	--IF EXISTS (SELECT COUNT(*),QtyRec,Invtrec_no
	--	from @tinserted
	--	group by qtyrec,invtrec_no
	--	having count(*)<>QtyRec)
	--BEGIN
	--	RAISERROR('Number of serial numbers is not matching to total quantities received.',1,1);
	--	IF @@TRANCOUNT<>0
	--		ROLLBACK TRANSACTION
	--	RETURN
	--END	 -- EXISTS (SELECT COUNT(*),QtyRec,Invtrec_no
	
	BEGIN TRANSACTION
	BEGIN TRY
		-- if ip key used count serial numbers per each ipkey (ipkeyunique for each serial has to be populated in iRecSerial), 
		--08/20/19 YS insert record into iRecIpkey
		-- the trigger for iRecIpkey should generate Ipkey
		INSERT INTO  [dbo].[iRecIpKey]
			([iRecIpKeyUnique]
			,[invtrec_no]
			,[qtyPerPackage]
			,[qtyReceived]
			,[ipkeyunique]) 
		SELECT dbo.fn_GenerateUniqueNumber() as [iRecIpKeyUnique],
				I.INVTREC_NO,
				COUNT(I.Serialno) as [qtyPerPackage],
				COUNT(I.Serialno) as [qtyReceived],
				I.ipkeyunique
		FROM @tinserted I 
		WHERE I.UseIpkey=1
		GROUP BY I.INVTREC_NO,I.ipkeyunique
	
	END TRY	
	BEGIN CATCH
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			RETURN
	END CATCH

	-- Nilesh S 3/12/2018 Check existing serial number for buy part
	SELECT InvtSer.serialuniq,InvtSer.serialno,InvtSer.id_key,InvtSer.Id_value
			FROM InvtSer INNER JOIN @tInserted I on Invtser.SERIALNO=I.serialno and I.UNIQ_KEY=invtser.UNIQ_KEY 
			AND invtser.ID_KEY <> 'packlistno' -- Nilesh Sa 3/14/2018 Not to validate if SN is ship to any packing list
			-- Nilesh Sa 3/13/2018 This condition will validated only if from general receiving
			AND IsGeneralReceive = 1

	IF (@@ROWCOUNT<>0)
		BEGIN
				RAISERROR('Some of the Serial Numbers you are trying to receive is already in the system. Please check your inventory.',1,1);
				ROLLBACK TRANSACTION
				RETURN;
		END

   -- Nilesh S 3/12/2018 Check existing serial number for make part
	SELECT InvtSer.serialuniq,InvtSer.serialno,InvtSer.id_key,InvtSer.Id_value
			FROM InvtSer INNER JOIN INVENTOR  on INVENTOR.UNIQ_KEY=invtser.UNIQ_KEY AND INVENTOR.PART_SOURC='make' 
			AND ID_KEY <> 'packlistno' -- Nilesh Sa 3/14/2018 Not to validate if SN is ship to any packing list
			-- Nilesh Sa 3/13/2018 This condition will validated only if from general receiving
			Inner join @tInserted t on InvtSer.SERIALNO = t.SERIALNO AND IsGeneralReceive = 1 
			and t.UNIQ_KEY =  InvtSer.UNIQ_KEY  -- Rajendra K  9/1/2019 Added Condition for SN

	IF (@@ROWCOUNT<>0)
		BEGIN
				RAISERROR('Some of the Serial Numbers you are trying to receive is already in the system. Please check your inventory.',1,1);
				ROLLBACK TRANSACTION
				RETURN;
		END


	-- now insert into invtser
	BEGIN TRY
		-- check for duplicate serial numbers for the same mpn
		SELECT InvtSer.serialuniq,InvtSer.serialno,InvtSer.id_key,InvtSer.Id_value
			FROM InvtSer INNER JOIN @tInserted I on Invtser.SERIALNO=I.serialno
			where (InvtSer.Id_key = 'W_KEY' OR InvtSer.Id_key = 'WONO') 
			and I.uniqmfgrhd=invtser.UNIQMFGRHD
		IF (@@ROWCOUNT<>0)
		BEGIN
			---!!! need a way to comunicate to user, why the trigger failed
			-- cannot receive
			RAISERROR('Some of the Serial Numbers you are trying to receive is already in the system. Please check your inventory.',1,1);
			ROLLBACK TRANSACTION
			RETURN;
		END	---(@@ROWCOUNT<>0)			
		ELSE ---(@@ROWCOUNT<>0)
		BEGIN
			-- check if exists but was shipped and now returned back
			-- 06/30/2016 Sachin B change the code for Id_key=i.id_value to Id_key=i.ID_KEY,
			UPDATE InvtSer SET Id_key=i.ID_KEY, 
				Id_value=i.id_value,
				UniqMfgrhd = i.UniqMfgrhd,
				LotCode = i.LotCode,
				Uniq_Lot = i.uniq_Lot,
				ExpDate = i.ExpDate,
				Reference = i.REFERENCE,
				Ponum = i.ponum,
				ActvKey = i.ACTVKEY,
				--Sachin B 07/13/2106 update the ipkeyunique column also
				ipkeyunique = i.ipkeyunique
				FROM @tinserted I WHERE I.Serialno=InvtSer.SERIALNO and I.UNIQMFGRHD =i.UNIQMFGRHD and 
				--invtser.Id_key<>'WONO' and invtser.id_key<>'W_KEY'
				(invtser.Id_key = 'PACKLISTNO' OR invtser.id_key = 'DEPTKEY') 
				-- Nilesh Sa 3/14/2018 As per discussion with Yelena Modified the condition only with PACKLISTNO or DEPTKEY
							
			--now, insert the new one
		
			INSERT INTO [dbo].[INVTSER]
			   ([SERIALUNIQ]
			,[SERIALNO]
			,[UNIQ_KEY]
			,[UNIQMFGRHD]
			,[UNIQ_LOT]
			,[ID_KEY]
			,[ID_VALUE]
			,[SAVEDTTM]
			,[SAVEINIT]
			,[LOTCODE]
			,[EXPDATE]
			,[REFERENCE]
			,[PONUM]
			,[ISRESERVED]
			,[ACTVKEY]
			,[OLDWONO]
			,[WONO]
			,[RESERVEDFLAG]
			,[RESERVEDNO]
			,[ipkeyunique])
			SELECT I.SERIALUNIQ
           ,I.SERIALNO           
		   ,I.UNIQ_KEY
           ,I.UNIQMFGRHD
           ,I.UNIQ_LOT
           ,I.ID_KEY
           ,I.ID_VALUE
           ,I.SAVEDTTM
           ,I.SAVEINIT
           ,I.LOTCODE
           ,I.EXPDATE
           ,I.REFERENCE
           ,I.ponum
           ,I.ISRESERVED
           ,I.ACTVKEY
           ,I.OLDWONO
		   ,I.WONO
           ,I.RESERVEDFLAG
           ,I.RESERVEDNO 
           ,I.ipkeyunique FROM @tInserted I where NOT EXISTS (SELECT 1 from invtSer where invtser.UNIQMFGRHD = i.UNIQMFGRHD and invtser.serialno=i.serialno)
	END	 -- ---(@@ROWCOUNT<>0)  
	
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT <>0
			ROLLBACK TRAN ;
			RETURN
	END CATCH
	IF @@TRANCOUNT <>0
	COMMIT TRANSACTION
END -- end of the trigger code	