CREATE TABLE [dbo].[DEPT_LGT] (
    [WONO]            CHAR (10)        CONSTRAINT [DF__DEPT_LGT__WONO__4F87BD05] DEFAULT ('') NOT NULL,
    [DEPT_ID]         CHAR (4)         CONSTRAINT [DF__DEPT_LGT__DEPT_I__507BE13E] DEFAULT ('') NOT NULL,
    [NUMBER]          NUMERIC (4)      CONSTRAINT [DF__DEPT_LGT__NUMBER__51700577] DEFAULT ((0)) NOT NULL,
    [TIME_USED]       NUMERIC (6)      CONSTRAINT [DF__DEPT_LGT__TIME_U__544C7222] DEFAULT ((0)) NOT NULL,
    [originalDateIn]  DATETIME         NULL,
    [DATE_IN]         DATETIME         NULL,
    [originalDateOut] DATETIME         CONSTRAINT [DF_DEPT_LGT_originalDateOut] DEFAULT (getdate()) NULL,
    [DATE_OUT]        DATETIME         CONSTRAINT [DF_DEPT_LGT_date_out] DEFAULT (getdate()) NULL,
    [inUserId]        UNIQUEIDENTIFIER CONSTRAINT [DF_DEPT_LGT_inUserId] DEFAULT ('00000000-0000-0000-0000-000000000000') NOT NULL,
    [LOG_INIT]        CHAR (8)         CONSTRAINT [DF__DEPT_LGT__LOG_IN__5540965B] DEFAULT ('') NOT NULL,
    [outUserId]       UNIQUEIDENTIFIER CONSTRAINT [DF_DEPT_LGT_outUserId] DEFAULT ('00000000-0000-0000-0000-000000000000') NOT NULL,
    [LOGOUT_INI]      CHAR (8)         CONSTRAINT [DF__DEPT_LGT__LOGOUT__5634BA94] DEFAULT ('') NOT NULL,
    [TMLOGTPUK]       VARCHAR (10)     CONSTRAINT [DF__DEPT_LGT__TMLOG___5728DECD] DEFAULT ('') NOT NULL,
    [OVERTIME]        NUMERIC (6)      CONSTRAINT [DF__DEPT_LGT__OVERTI__581D0306] DEFAULT ((0)) NOT NULL,
    [IS_HOLIDAY]      BIT              CONSTRAINT [DF__DEPT_LGT__IS_HOL__5911273F] DEFAULT ((0)) NOT NULL,
    [UNIQLOGIN]       CHAR (10)        CONSTRAINT [DF__DEPT_LGT__UNIQLO__5A054B78] DEFAULT ('') NOT NULL,
    [uDeleted]        BIT              CONSTRAINT [DF_DEPT_LGT_deleted] DEFAULT ((0)) NOT NULL,
    [comment]         VARCHAR (MAX)    CONSTRAINT [DF_DEPT_LGT_comment] DEFAULT ('') NOT NULL,
    [LastUpdatedBy]   UNIQUEIDENTIFIER CONSTRAINT [DF__DEPT_LGT__LastUp__11EE75F2] DEFAULT ('00000000-0000-0000-0000-000000000000') NULL,
    [LastUpdatedDate] DATETIME         CONSTRAINT [DF__DEPT_LGT__LastUp__12E29A2B] DEFAULT (getdate()) NULL,
    [ModTimeUsed]     DECIMAL (6)      CONSTRAINT [DF__DEPT_LGT__ModTim__21BAC967] DEFAULT ((0)) NULL,
    CONSTRAINT [DEPT_LGT_PK] PRIMARY KEY CLUSTERED ([UNIQLOGIN] ASC)
);


GO
CREATE NONCLUSTERED INDEX [LOG_INIT]
    ON [dbo].[DEPT_LGT]([LOG_INIT] ASC);


GO
CREATE NONCLUSTERED INDEX [WODEPTTMNO]
    ON [dbo].[DEPT_LGT]([LOG_INIT] ASC, [WONO] ASC, [DEPT_ID] ASC, [NUMBER] ASC, [TMLOGTPUK] ASC);


GO
CREATE NONCLUSTERED INDEX [WONO]
    ON [dbo].[DEPT_LGT]([LOG_INIT] ASC, [WONO] ASC, [DEPT_ID] ASC, [NUMBER] ASC);


GO
-- =============================================
-- Author:		Nitesh B	
-- Create date: 05/28/2018
-- Description:	Dept_lgt insert/Update/Delete trigger
-- Modification 
   -- 
-- =============================================
CREATE TRIGGER  [dbo].[Dept_lgt_Insert_Update_Delete]
   ON  [dbo].[DEPT_LGT] 
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorSeverity INT;
    DECLARE @ErrorState INT;

	BEGIN TRY
		BEGIN TRANSACTION
		IF NOT EXISTS (select 1 from  DEPT_LGT DL inner join Inserted I on  DL.UNIQLOGIN = I.UNIQLOGIN)
			BEGIN
				RAISERROR ('Cannot Locate any Records in DEPT_LGT Table to Insert record into DeptLgtHistory table.', -- Message text.
				   16, -- Severity.
					1 -- State.
				);

			END

	INSERT INTO [dbo].[DeptLgtHistory]
           ([DeptLgtHistoryUniq]
           ,[UniqLogin]
           ,[TMLOGTPUK]
           ,[LogTypeTime]
           ,[DateIn]
           ,[DateOut]
           ,[TotalTime]
           ,[IsDeleted]
           ,[ModifiedBy]
           ,[ModifiedDate])
     
	       (SELECT 
		        dbo.fn_GenerateUniqueNumber()
			   ,UniqLogin
			   ,TMLOGTPUK
			   ,Time_Used
			   ,Date_In
			   ,Date_Out
			   ,Time_Used
			   ,uDeleted
			   ,LastUpdatedBy
			   ,LastUpdatedDate 
		   FROM Inserted) 

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

