

CREATE proc [dbo].[OpenProjectsView]    
AS SELECT  Pjctmain.prjnumber,PrjUnique FROM pjctmain 
 WHERE PrjStatus<>'Cancelled' AND PrjStatus<>'Closed' ORDER By PrjNumber




