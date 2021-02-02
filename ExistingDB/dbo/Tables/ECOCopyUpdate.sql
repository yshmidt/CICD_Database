CREATE TABLE [dbo].[ECOCopyUpdate] (
    [EcoCopyUniq]  CHAR (10)      CONSTRAINT [DF__ECOCopyUp__EcoCo__45590B5F] DEFAULT ([dbo].[fn_GenerateUniqueNumber]()) NOT NULL,
    [UniqeECNo]    CHAR (10)      NOT NULL,
    [CopyCriteria] NVARCHAR (100) NOT NULL,
    [IsChecked]    BIT            CONSTRAINT [DF__ECOCopyUp__IsChe__464D2F98] DEFAULT ((0)) NOT NULL
);

