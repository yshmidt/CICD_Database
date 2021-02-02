-- =============================================
-- Author:		David Sharp
-- Create date: 5/16/2012
-- Description:	converts the results of a select statement to an html table for email
-- =============================================
CREATE PROCEDURE [dbo].[MnxFuncSelectToHtml] 
(
	-- Add the parameters for the function here
	@select varchar(MAX)='',
	@footer varchar(MAX)='',
	@Data xml = NULL,
	@htmlTable varchar(MAX) OUTPUT
)
--RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @thead varchar(MAX),@tbody varchar(MAX),@colNames varchar(MAX)
	
	-- Convert the select statement to html 
	-- ALL nodes MUST have ALL values and IN ORDER
	DECLARE		@DataRow XML
	IF @select<>'' AND @Data IS NULL
	BEGIN
		DECLARE		@modSelect nvarchar(MAX)=CAST('SELECT @dr = (' + @select + ' FOR XML PATH(''root''))' AS varchar(MAX))
		EXEC SP_EXECUTESQL @modSelect,N'@dr xml OUTPUT',@Data OUTPUT
	END
	
	--Get a comma separate list of column names, add one for row number
	SELECT @colNames = 'Row,'+[dbo].[fn_XMLgetcolNames](@Data,1)
	SET @thead = '<table><tr style="{hbc}{hc}{cj}{fl}"><th style="{plr}">'+ REPLACE(@colNames,',','</th><th style="{plr}">') + '</th></tr>'
	
	--Get the values for each node and row number
	DECLARE @nodeValue TABLE(nodeName varchar(50),nodeValue varchar(MAX))
	INSERT INTO @nodeValue
	SELECT name,value FROM [dbo].[fn_XMLgetNodeValues](@Data)
	
	--Convet the table of node values to an XML string prepared for cleaning the final html string
	DECLARE @tblString varchar(MAX)
	SET @tblString = CAST((SELECT CASE WHEN nodeName='rowNum' THEN '{rs}'+CAST(CAST(nodeValue AS int)%2 AS varchar(50))+'{ph}'+nodeValue ELSE '{ph}' + nodeValue  END FROM @nodeValue FOR XML PATH(''))AS varchar(MAX))
	--Prepare to alter row colors (even and odd)
	SET @tblString = REPLACE(@tblString,'{rs}1','</td></tr><tr style="background-color:{rbc1}">')
	SET @tblString = REPLACE(@tblString,'{rs}0','</td></tr><tr style="background-color:{rbc2}">')
	
	--Prep to trim leading extra characters for start of each table row
	SET @tblString='{00}'+@tblString+'</td></tr>'
	SET @tbody = REPLACE(@tblString,'<tr style="background-color:{rbc1}">{ph}','<tr style="background-color:{rbc1}">{00}{ph}')
	SET @tbody = REPLACE(@tbody,'<tr style="background-color:{rbc2}">{ph}','<tr style="background-color:{rbc2}">{00}{ph}')
	
	--Replace place holders with specific codes for each row and justification 
	SET @tbody = REPLACE(@tbody,'{ph}{rj}','{de}{ds}{rj}{pl}{le}')
	SET @tbody = REPLACE(@tbody,'{ph}{cj}','{de}{ds}{cj}{plr}{le}')
	SET @tbody = REPLACE(@tbody,'{ph}{lj}','{de}{ds}{lj}{pr}{le}')
	SET @tbody = REPLACE(@tbody,'{ph}','{de}{ds}{pr}{le}')
	SET @tbody = REPLACE(@tbody,'<d>{de}','')
	SET @tbody = REPLACE(@tbody,'</d>','{de}</tr>')	
	
	--Trim leading Characters
	SET @tbody = REPLACE(@tbody,'{00}</td></tr>','')
	SET @tbody = REPLACE(@tbody,'{00}{de}','')	
	--Combile the table
	SET @htmlTable = @thead + @tbody + COALESCE(@footer,'') + '</table>'
	
	--Final format the html table
	 --NOTE: This leave the header background-color (hbc} and font color {hc}, and the alternating rows background-color {rbc1} and {rbc2} so they can be customized 
	SET @htmlTable = REPLACE(@htmlTable,'{ds}','<td style="')
	SET @htmlTable = REPLACE(@htmlTable,'{ae}','</a>')
	SET @htmlTable = REPLACE(@htmlTable,'{de}','</td>')
	SET @htmlTable = REPLACE(@htmlTable,'{rj}','text-align:right;')
	SET @htmlTable = REPLACE(@htmlTable,'{cj}','text-align:center;')
	SET @htmlTable = REPLACE(@htmlTable,'{lj}','text-align:left;')
	SET @htmlTable = REPLACE(@htmlTable,'{pr}','padding-right:20px;')
	SET @htmlTable = REPLACE(@htmlTable,'{pl}','padding-left:20px;')
	SET @htmlTable = REPLACE(@htmlTable,'{plr}','padding:0 20px;')
	SET @htmlTable = REPLACE(@htmlTable,'{fb}','font-weight:bold;')
	SET @htmlTable = REPLACE(@htmlTable,'{fl}','font-size:larger;')
	
	--SELECT @htmlTable

END
