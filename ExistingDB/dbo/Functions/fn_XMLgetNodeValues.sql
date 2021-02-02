CREATE FUNCTION [dbo].[fn_XMLgetNodeValues] (@xml xml)
   RETURNS @tbl TABLE ([order] int IDENTITY(1, 1) PRIMARY KEY CLUSTERED,[type] varchar(40) NOT NULL,name varchar(64)NOT NULL,value varchar(MAX) NOT NULL) AS
BEGIN
   IF (@xml is null)
	    RETURN
   ELSE	    
		--Get a table of the table values including a row for each 'root' to indicate the start of a new row
		DECLARE		@nodeValueTbl TABLE (NodeID int,NodeLevel int,ParentNodeName varchar(64),ElementName varchar(max),nodeValue varchar(MAX),nodePath varchar(10))
		DECLARE     @Nodes TABLE(NodeID INT IDENTITY(1, 1) PRIMARY KEY CLUSTERED,ParentNodeName NVARCHAR(64),NodeName NVARCHAR(64),nodeValue varchar(MAX))
		
		
		
		INSERT      @Nodes(ParentNodeName,NodeName,nodeValue)
		SELECT      e.value('local-name(..)[1]', 'VARCHAR(MAX)') AS ParentNodeName, e.value('local-name(.)[1]', 'VARCHAR(MAX)') AS NodeName,e.value('(.)[1]', 'VARCHAR(MAX)') AS nodeValue
			FROM    @xml.nodes('//*[local-name(.) > ""]') AS n(e)
		;WITH Yak(NodeLevel, ParentNodeName, ElementName, NodeID,nodeValue,nodePath)
		AS (
					SELECT      0,ParentNodeName,NodeName,NodeID,nodeValue,ROW_NUMBER() OVER(ORDER BY ParentNodeName)
						FROM       @Nodes
						WHERE      ParentNodeName = ''
					UNION ALL
					SELECT     y.NodeLevel + 1,n.ParentNodeName,n.NodeName,n.NodeID,n.nodeValue,ROW_NUMBER() OVER(ORDER BY n.ParentNodeName)
						FROM       @Nodes AS n
						INNER JOIN Yak AS y ON y.ElementName = n.ParentNodeName
		)
		INSERT INTO @nodeValueTbl
		SELECT distinct NodeID,NodeLevel,ParentNodeName,ElementName,nodevalue,nodePath FROM YAK ORDER BY NodeID
		
		--insert the node values
		INSERT INTO @tbl
		SELECT 'colValue',CASE WHEN NodeLevel = 0 THEN 'rowNum' ELSE ElementName END,CASE WHEN NodeLevel = 0 THEN nodePath ELSE nodeValue END 
			FROM @nodeValueTbl 
			ORDER BY NodeID
   RETURN
END
