CREATE TYPE [dbo].[tDepts] AS TABLE (
    [dept_id]   CHAR (4)    DEFAULT ('') NOT NULL,
    [dept_name] CHAR (25)   DEFAULT ('') NOT NULL,
    [number]    NUMERIC (4) DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([dept_id] ASC));

