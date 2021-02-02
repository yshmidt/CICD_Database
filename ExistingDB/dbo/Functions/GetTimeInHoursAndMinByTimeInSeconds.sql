-- =============================================
-- Author:	Sachin B
-- Create date: 06/13/2016
-- Description:	This function is used for get time in hours and mins by the time in seconds
-- GetTimeInHoursAndMinByTimeInSeconds 500
-- =============================================
CREATE Function [dbo].[GetTimeInHoursAndMinByTimeInSeconds] (@_TimeInSeconds int)
        Returns nvarchar(254)
        BEGIN
				if(@_TimeInSeconds is null)
				BEGIN
					 return ''
				END
				ELSE
					BEGIN
						return	RIGHT('0' + CAST(@_TimeInSeconds / 3600 AS VARCHAR),2) + ':' +
								RIGHT('0' + CAST((@_TimeInSeconds / 60) % 60 AS VARCHAR),2) 
					END	
				Return ''	
        END 