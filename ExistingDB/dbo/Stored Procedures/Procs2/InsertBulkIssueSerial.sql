-- =============================================
-- Author:Sachin s
-- Create date: 07-25-2015
-- Description:	Insert bulk Issue serial so Issue ipKey 
--02/09/18 YS changed size of the lotcode column to 25 char
-- =============================================
CREATE PROCEDURE [dbo].[InsertBulkIssueSerial]              
( 
 @serialUniqList VARCHAR(MAX),
 @invtisu_no CHAR(10)              
)              
AS              
BEGIN              
            
SET NoCount ON;                            
-- declare your variables here
SET @SerialUniqList = REPLACE(REPLACE(REPLACE(@serialUniqList,'[',''),']',''),'"','')    

--- added an identity rownumber for creating ipkey later
--02/09/18 YS changed size of the lotcode column to 25 char
DECLARE @tSerialUnique table (SERIALUNIQ char(10), uniq_key char(10),w_key char(10), uniqmfgrhd char(10),id_key char(10),id_value char(10),
	lotcode nvarchar(25),expdate smalldatetime null,reference char(13),Serialno char(30),ipkeyunique char(10) default '',rownumber int IDENTITY,groupid int
	,WH_GL_NBR CHAR(13),STDCOST NUMERIC(13, 5),Shri_Gl_No  CHAR(13),INVTISU_NO char(10) default '')  

INSERT INTO @tSerialUnique (SERIALUNIQ) 
 SELECT id from dbo.[fn_simpleVarcharlistToTable](@SerialUniqList,',')
 order by id   

	--the trigger of issueserial table put entry to the issueipkey table if it have ipkeyunique
			insert into issueSerial (serialno,SerialUniq,iIssueSerUnique,invtisu_no,ipkeyunique)
			select s.serialno,t.SerialUniq,dbo.fn_GenerateUniqueNumber(),@invtisu_no,s.ipkeyunique
			from @tSerialUnique t 
			inner join invtser s on t.SerialUniq=s.SERIALUNIQ                   
END