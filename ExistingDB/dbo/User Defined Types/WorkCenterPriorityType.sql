CREATE TYPE [dbo].[WorkCenterPriorityType] AS TABLE (
    [uniqKey]    VARCHAR (10) NOT NULL,
    [priority]   DECIMAL (18) NOT NULL,
    [woNo]       VARCHAR (10) NOT NULL,
    [categoryId] VARCHAR (4)  NOT NULL);

