
CREATE Function [dbo].[NewWhNo] ()
    Returns char(3)
    BEGIN
		-- 08/30/17 VL comment out the old code, we changed for Progeny that they ran out of all numeric whno, so we copied the code from VFP version to add char as whno
		--DECLARE  @pcNextNumber char(3)
		--SELECT @pcNextNumber = dbo.padl(convert(int,MAX(WhNo))+1,3,DEFAULT) from Warehous			
		--RETURN @pcNextNumber
		DECLARE @lcMaxWhno char(3), @lnRecords int, @lcLeft char(1), @IsDone bit, @lnNumber int, @lnRemainder int, @lcGetNumber char(3), @lcChkUniqWh char(10)
		DECLARE @pcNextNumber char(3)

		SELECT @lcMaxWhno = MAX(WhNo) FROM Warehous

		BEGIN
		IF ISNUMERIC(@lcMaxWhno) = 1	-- Max Whno is all numerice, juse original code to get next Whno
			BEGIN
				SELECT @pcNextNumber = dbo.padl(convert(int,MAX(WhNo))+1,3,DEFAULT) from Warehous	
			END
		ELSE -- The max Whno has character
			BEGIN
				SELECT @lnRecords = ISNULL(COUNT(*),0) FROM WAREHOUS WHERE ISNUMERIC(@lcMaxWhno) = 0 AND ASCII(Whno) = ASCII(@lcMaxWhno)
				BEGIN
				IF @lnRecords >=1295 -- time to change the first character
					BEGIN
						SELECT @lcLeft = CHAR(ASCII(@lcMaxWhno)+1)
						IF ASCII(@lcLeft)<65 OR ASCII(@lcLeft)>90 -- not 0-9,a-z
							BEGIN
								-- can not use RAISERROR here, so just reutrn an error
								RETURN	CAST('Problem generating next WHNO. Cannot add new warehouse.' AS INT)
							END
						ELSE
							BEGIN
								SELECT @lnRecords = 0
							END
					END
				ELSE
					BEGIN
						SELECT @lcLeft = LEFT(@lcMaxWhno,1)
					END
				END
				-- Now will use @lcLeft to get new number
				SELECT @IsDone = 0
				WHILE (1=1)
				BEGIN
					--SELECT @lnNumber = CAST(@lnRecords/36 AS INT)
					SELECT @lnNumber = @lnRecords/36
					SELECT @lnRemainder = @lnRecords%36
					SELECT @lcGetNumber = @lcLeft + LTRIM(RTRIM(CASE WHEN @lnNumber>9 THEN CHAR(65-10+@lnNumber) ELSE CAST(@lnNumber AS char) END)) +  LTRIM(RTRIM(CASE WHEN @lnRemainder>9 THEN CHAR(65-10+@lnRemainder) ELSE CAST(@lnRemainder AS char) END))
					SELECT @lcChkUniqWh = UniqWh FROM Warehous WHERE Whno = @lcGetNumber
					BEGIN
					IF @@ROWCOUNT <>0 -- Found the new number already in Warehous table
						IF RIGHT(@lcGetNumber,2) = 'ZZ'
							BEGIN
								-- will change the first character
								SELECT @lcLeft = CHAR(ASCII(@lcLeft)+1)
								SELECT @lnRecords = 0
								IF ASCII(@lcLeft)<65 OR ASCII(@lcLeft)>90 -- not 0-9,a-z
									BEGIN
									-- can not use RAISERROR here, so just reutrn an error
									RETURN	CAST('Problem generating next WHNO. Cannot add new warehouse.' AS INT)
								END
							END
						ELSE
							BEGIN
								SELECT @lnRecords = @lnRecords + 1
								CONTINUE
							END
					ELSE
						SELECT @pcNextNumber = @lcGetNumber
						BREAK
					END

				END
			END
		END
		RETURN @pcNextNumber

	END 