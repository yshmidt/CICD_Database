CREATE TABLE [dbo].[WcOperator] (
    [WcOperatorId] INT           IDENTITY (1, 1) NOT NULL,
    [DeptId]       CHAR (4)      NOT NULL,
    [OperatorName] NVARCHAR (50) NOT NULL,
    CONSTRAINT [PK_WcOperator] PRIMARY KEY CLUSTERED ([WcOperatorId] ASC),
    CONSTRAINT [FK_WcOperator_WcOperator] FOREIGN KEY ([DeptId]) REFERENCES [dbo].[DEPTS] ([DEPT_ID])
);

