CREATE TABLE [dbo].[GLFISCALYRS] (
    [FY_UNIQ]        CHAR (10)     CONSTRAINT [DF__GLFISCALY__FY_UN__6A5BAED2] DEFAULT ('') NOT NULL,
    [FISCALYR]       CHAR (4)      CONSTRAINT [DF__GLFISCALY__FISCA__6B4FD30B] DEFAULT ('') NOT NULL,
    [lCLOSED]        BIT           CONSTRAINT [DF__GLFISCALY__CLOSE__6D381B7D] DEFAULT ((0)) NOT NULL,
    [lCURRENT]       BIT           CONSTRAINT [DF__GLFISCALY__CURRE__6E2C3FB6] DEFAULT ((0)) NOT NULL,
    [FYNOTE]         VARCHAR (254) CONSTRAINT [DF__GLFISCALY__FYNOT__6F2063EF] DEFAULT ('') NOT NULL,
    [dBeginDate]     SMALLDATETIME NULL,
    [dEndDate]       SMALLDATETIME NULL,
    [sequenceNumber] INT           CONSTRAINT [DF_GLFISCALYRS_sequenceNumber] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [GLFISCALYRS_PK] PRIMARY KEY CLUSTERED ([FY_UNIQ] ASC)
);


GO
CREATE NONCLUSTERED INDEX [FiscalYr]
    ON [dbo].[GLFISCALYRS]([dBeginDate] ASC, [FISCALYR] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_GLFISCALYRS]
    ON [dbo].[GLFISCALYRS]([sequenceNumber] ASC);


GO
-- =============================================
-- Author:		<Yelena Shmidt>
-- Create date: <10/22/2009>
-- Description:	<Create audit trail for the changes in the GlFiscalYrs table>
-- 06/22/15 YS update sequncenumber column if record was removed or inserted
-- =============================================
CREATE TRIGGER [dbo].[GlFiscalYrs_Update_Insert_Delete] 
   ON  [dbo].[GLFISCALYRS] 
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	IF (SELECT COUNT(*) FROM inserted) > 0 
    BEGIN 
        IF (SELECT COUNT(*) FROM deleted) > 0 
        BEGIN 
            -- update! 
			IF UPDATE(FYNote)			
				BEGIN
				INSERT AuditFiscalYrs (Fk_fy_uniq,UserId,changetype,changetext) SELECT Inserted.fy_uniq,SUSER_SNAME(),'U',
				'List of Changes: '+CASE WHEN Deleted.FiscalYr<> Inserted.FiscalYr THEN 'FY: Before '+Deleted.FiscalYr+' After '+Inserted.Fiscalyr ELSE '' END+ 
				CASE WHEN Deleted.dbeginDate<>Inserted.dbeginDate THEN ' Beginning Date: Before '+ 	CONVERT(CHAR(20),Deleted.dbeginDate,120) +' After '+CONVERT(CHAR(20),Inserted.dbeginDate,120) ELSE '' END +
				CASE WHEN Deleted.dEndDate<>Inserted.dEndDate THEN ' Ending Date: Before '+ 	CONVERT(CHAR(20),Deleted.dEndDate,120)+' After '+CONVERT(CHAR(20),Inserted.dEndDate,120) ELSE '' END +
				',  Fiscal Year Note changed '  
				FROM INSERTED,Deleted where Inserted.fy_uniq=Deleted.fy_uniq;
				END
			ELSE
				BEGIN
				INSERT AuditFiscalYrs (Fk_fy_uniq,UserId,changetype,changetext) SELECT Inserted.fy_uniq,SUSER_SNAME(),'U',
				'List of Changes: '+CASE WHEN Deleted.FiscalYr<> Inserted.FiscalYr THEN 'FY: Before '+Deleted.FiscalYr+' After '+Inserted.Fiscalyr ELSE '' END+  
				CASE WHEN Deleted.dbeginDate<>Inserted.dbeginDate THEN ' Beginning Date: Before '+ 	CONVERT(CHAR(20),Deleted.dbeginDate,120) +' After '+CONVERT(CHAR(20),Inserted.dbeginDate,120) ELSE '' END +
				CASE WHEN Deleted.dEndDate<>Inserted.dEndDate THEN ' Ending Date: Before '+ 	CONVERT(CHAR(20),Deleted.dEndDate,120)+' After '+CONVERT(CHAR(20),Inserted.dEndDate,120) ELSE '' END
				FROM INSERTED,Deleted where Inserted.fy_uniq=Deleted.fy_uniq 			;
			END
			
        END 
        ELSE -- IF (SELECT COUNT(*) FROM deleted) > 0 
        BEGIN 
            -- insert! 
			-- 06/22/15 YS update sequncenumber column if record was removed or inserted
            INSERT AuditFiscalYrs (Fk_fy_uniq,UserId,changetype,changetext) SELECT fy_uniq,SUSER_SNAME(),'I','Inserted Fiscal year '+Inserted.FiscalYr FROM INSERTED 
			update GLFISCALYRS set sequenceNumber = nr.sequenceNumber from (select fy_uniq,fiscalYr,ROW_NUMBER() over (order by dbegindate) as sequenceNumber from  GLFISCALYRS) nr where nr.FY_UNIQ=GLFISCALYRS.FY_UNIQ
		END -- IF (SELECT COUNT(*) FROM deleted) > 0 
    END -- (SELECT COUNT(*) FROM inserted) > 0 
    ELSE -- (SELECT COUNT(*) FROM inserted) > 0 
    BEGIN 
        -- delete! 
		-- 06/22/15 YS update sequncenumber column if record was removed or inserted
        INSERT AuditFiscalYrs (Fk_fy_uniq,UserId,changetype,changetext) SELECT fy_uniq,SUSER_SNAME(),'D','Deleted Fiscal year '+Deleted.FiscalYr FROM DELETED 
    update GLFISCALYRS set sequenceNumber = nr.sequenceNumber from (select fy_uniq,fiscalYr,ROW_NUMBER() over (order by dbegindate) as sequenceNumber from  GLFISCALYRS) nr where nr.FY_UNIQ=GLFISCALYRS.FY_UNIQ
	END -- (SELECT COUNT(*) FROM inserted) > 0 	
END -- trigger