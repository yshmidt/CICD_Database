﻿CREATE TABLE [dbo].[CYCLESER] (
    [UNIQCCNO]     CHAR (10) CONSTRAINT [DF__CYCLESER__UNIQCC__79B300FB] DEFAULT ('') NOT NULL,
    [UNIQCCSERIAL] CHAR (10) CONSTRAINT [DF__CYCLESER__UNIQCC__7AA72534] DEFAULT ('') NOT NULL,
    [SERIALNO]     CHAR (30) CONSTRAINT [DF__CYCLESER__SERIAL__7B9B496D] DEFAULT ('') NOT NULL,
    [UNIQMFGRHD]   CHAR (10) CONSTRAINT [DF__CYCLESER__UNIQMF__7C8F6DA6] DEFAULT ('') NOT NULL,
    CONSTRAINT [CYCLESER_PK] PRIMARY KEY CLUSTERED ([UNIQCCSERIAL] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SERIALNO]
    ON [dbo].[CYCLESER]([SERIALNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQCCNO]
    ON [dbo].[CYCLESER]([UNIQCCNO] ASC);


GO
CREATE NONCLUSTERED INDEX [UNIQMFGRHD]
    ON [dbo].[CYCLESER]([UNIQMFGRHD] ASC);

