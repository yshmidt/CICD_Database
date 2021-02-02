CREATE TABLE [dbo].[INVTLOT] (
    [W_KEY]     CHAR (10)       CONSTRAINT [DF__INVTLOT__W_KEY__2784B8A3] DEFAULT ('') NOT NULL,
    [LOTCODE]   NVARCHAR (25)   CONSTRAINT [DF__INVTLOT__LOTCODE__2878DCDC] DEFAULT ('') NOT NULL,
    [EXPDATE]   SMALLDATETIME   NULL,
    [LOTQTY]    NUMERIC (12, 2) CONSTRAINT [DF__INVTLOT__LOTQTY__296D0115] DEFAULT ((0)) NOT NULL,
    [REFERENCE] CHAR (12)       CONSTRAINT [DF__INVTLOT__REFEREN__2A61254E] DEFAULT ('') NOT NULL,
    [LOTRESQTY] NUMERIC (12, 2) CONSTRAINT [DF__INVTLOT__LOTRESQ__2B554987] DEFAULT ((0)) NOT NULL,
    [PONUM]     CHAR (15)       CONSTRAINT [DF__INVTLOT__PONUM__2C496DC0] DEFAULT ('') NOT NULL,
    [COUNTFLAG] CHAR (1)        CONSTRAINT [DF__INVTLOT__COUNTFL__2D3D91F9] DEFAULT ('') NOT NULL,
    [UNIQ_LOT]  CHAR (10)       CONSTRAINT [DF__INVTLOT__UNIQ_LO__2E31B632] DEFAULT ('') NOT NULL,
    CONSTRAINT [INVTLOT_PK] PRIMARY KEY NONCLUSTERED ([UNIQ_LOT] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [W_KEYLOT]
    ON [dbo].[INVTLOT]([W_KEY] ASC, [LOTCODE] ASC, [EXPDATE] ASC, [REFERENCE] ASC, [PONUM] ASC);


GO
CREATE NONCLUSTERED INDEX [lotcode]
    ON [dbo].[INVTLOT]([LOTCODE] ASC);


GO
CREATE NONCLUSTERED INDEX [W_key]
    ON [dbo].[INVTLOT]([W_KEY] ASC);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 11/01/2013
-- Description:	update trigger
-- Modified:	04/25/14 VL found can not just use SELECT LotQty.... has to put the result into a variable, otherwise, with a huge value of insert, will cause the system hang
-- =============================================
CREATE TRIGGER [dbo].[InvtLot_Updated]
   ON  [dbo].[INVTLOT]
   AFTER UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
   BEGIN TRANSACTION

   DECLARE @lnLotQty numeric(12,2) 
   --select LOTQTY  from inserted where LOTQTY < 0
   select @lnLotQty = LOTQTY from inserted where LOTQTY < 0
   IF  @@ROWCOUNT<>0
	BEGIN	
		RAISERROR('System was trying to update quatities for lot code with the negative values. 
			Please contact ManEx with detailed information of the action prior to this message.',1,1)
		ROLLBACK TRANSACTION
		RETURN 
	END -- @@ROWCOUNT<>0
	COMMIT
END