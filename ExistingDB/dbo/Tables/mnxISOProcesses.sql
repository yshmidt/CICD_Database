CREATE TABLE [dbo].[mnxISOProcesses] (
    [isoNode]      [sys].[hierarchyid] NOT NULL,
    [ProcessName]  NVARCHAR (100)      DEFAULT ('') NOT NULL,
    [ReleventLink] NVARCHAR (200)      DEFAULT ('') NOT NULL,
    PRIMARY KEY CLUSTERED ([isoNode] ASC)
);


GO
-- =============================================
-- Author:		Yelena Shmidt
-- Create date: 07/15/19
-- Description:	delete trigger to remove all child nodes whem removing a record 
-- =============================================
CREATE TRIGGER mnxISOProcesses_delete 
   ON  [dbo].mnxISOProcesses
   AFTER DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

     DELETE FROM mnxISOProcesses 
	 WHERE isoNode IN
		(
        SELECT DISTINCT h.isoNode
        FROM deleted d
        INNER JOIN mnxISOProcesses h
        ON h.isoNode.IsDescendantOf(d.isoNode) = 1
      EXCEPT
        SELECT isoNode
        FROM deleted
		)
END