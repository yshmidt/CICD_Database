
CREATE PROC [dbo].[MrcView] As
SELECT CAST(RTRIM(LTRIM(Text)) AS Char(15)) as Mrc FROM Support WHERE Fieldname = 'MRC' ORDER BY Number
