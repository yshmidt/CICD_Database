﻿CREATE PROCEDURE [dbo].[MicsSysStaticInfoView]
AS SELECT [XXCUNOSYS]
      ,[XXSUPNOSYS]
      ,[XXWONOSYS]
      ,[XXINVNOSYS]
      ,[XXPSNOSYS]
      ,[XXPONOSYS]
      ,[XXCMNOSYS]
      ,[XXDMNOSYS]
      ,[XXSLQNSYS]
      ,[XXPAK_PRT]
      ,[XXINV_PRT]
      ,[XXRCVRSYS]
      ,[XXCARNOSYS]
      ,[XXSONOSYS]
      ,[XXPTNOSYS]
      ,[XXCPTNOSYS]
      ,[XXDMRNOSYS]
	  ,[XXECONO]
	  ,[XXDMRPLNO]
	  ,[XXPROJNO]
      ,[PKSTD_FOOT]
      ,[INSTD_FOOT]
      ,[AKSTD_FOOT]
      ,[CRSTD_FOOT]
      ,[DMSTD_FOOT]
      ,[POSTD_FOOT]
	  ,[QTSTD_FOOT]
	  ,[RMA_FOOT]      
	  ,[INV_GL_NO]
      ,[WIP_GL_NO]
      ,[FIG_GL_NO]
      ,[BUFFERDAYS]
      ,[DELIVDAYS]
      ,[PRIORDAY1]
      ,[PRIORDAY2]
      ,[FIELD149]
      ,LINARC 
      ,TARCDTTM 
      ,cArcBy
      ,MANEXVERNO
      ,CurrentWebReleaseDate
      ,PriorWebReleaseDate
      ,[UNIQUEREC]
 FROM [dbo].[MICSSYS]
 
