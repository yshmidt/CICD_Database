
-- =============================================  
-- Author: Shivshankar Patil   
-- Create date: 01/11/18
-- Description: For Sorting and filtering the data
-- Shivshankarp 01/22/2018  Not required the sort expression while get count
-- Shivshankarp 25/01/2019  While filtering Applied where condition
-- =============================================  
CREATE FUNCTION fn_GetDataBySortAndFilters
(
@sqlQuery NVARCHAR(MAX)  =null,
@filter NVARCHAR(MAX) = null ,
@sortExpression NVARCHAR(MAX) = null,
@qrderBY NVARCHAR(200)='' ,
@uniqField NVARCHAR (100)='' ,
@startRecord INT =1
,@endRecord INT =150)
RETURNS NVARCHAR(MAX)

AS
Begin
     --DECLARE @qryResult Query;
	 DECLARE @qryMain NVARCHAR(MAX)

	 IF(@uniqField ='' )  
	    BEGIN
			 IF @filter <> '' AND @sortExpression <> ''
						BEGIN
							SET @qryMain='SELECT * FROM('+@sqlQuery+')a  WHERE ' + @filter + ' ORDER BY '+ @sortExpression+'
										   OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
										   FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
						END

					ELSE IF @filter = '' AND @sortExpression <> ''
						BEGIN
							SET @qryMain='SELECT * FROM('+@sqlQuery+')a  ORDER BY '+ @sortExpression+' 
										   OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
										   FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
						END
					ELSE IF @filter <> '' AND @sortExpression = ''
						BEGIN
							 SET @qryMain='SELECT * FROM('+@sqlQuery+')a WHERE ' +@filter+ 'ORDER BY '+ @qrderBY +'
					 					   OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
										   FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
						END
					ELSE
						BEGIN
					   SET @qryMain='SELECT * FROM('+@SQLQuery+')a  ORDER BY '+ @qrderBY +'
									OFFSET ('+CONVERT(VARCHAR(10),@startRecord -1)+') ROWS  
									FETCH NEXT ('+CONVERT(VARCHAR(10),@endRecord)+') ROWS ONLY'
						END

			END

		ELSE 
		    BEGIN   
			       IF @filter <> '' AND @sortExpression <> ''
						BEGIN
						    -- Shivshankarp 01/22/2018  Not required the sort expression while get count
							-- Shivshankarp 25/01/2019  While filtering Applied where condition
							SET @qryMain='SELECT COUNT('+ @uniqField +') FROM('+@sqlQuery+')a  WHERE ' + @filter + ''-- ORDER BY '+ @sortExpression+'' 							
						END

					ELSE IF @filter = '' AND @sortExpression <> ''
						BEGIN
						    -- Shivshankarp 01/22/2018  Not required the sort expression while get count
							SET @qryMain='SELECT COUNT('+ @uniqField +')  FROM('+@sqlQuery+')a'--  ORDER BY '+ @sortExpression+'' 							
						END
					ELSE IF @filter <> '' AND @sortExpression = ''
						BEGIN
							 SET @qryMain='SELECT COUNT('+ @uniqField +')  FROM('+@sqlQuery+')a WHERE ' +@filter+ ''
						END
					ELSE
						BEGIN
					   SET @qryMain='SELECT COUNT('+@uniqField+')  FROM('+@SQLQuery+')a'
						END
			 END

		 RETURN	 @qryMain   

end;