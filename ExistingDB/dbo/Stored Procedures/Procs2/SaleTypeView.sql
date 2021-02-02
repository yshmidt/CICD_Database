CREATE PROC [dbo].[SaleTypeView] AS 
SELECT SaleTypeID, Gl_nbr, Cog_gl_nbr
	FROM SaleType
	ORDER BY SaleTypeId
