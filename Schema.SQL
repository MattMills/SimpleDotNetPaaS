CREATE TABLE [dbo].[Servers](
	[ServerID] INT NOT NULL IDENTITY(1,1),
	[ServerName] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Status] INT NULL
)

CREATE TABLE [dbo].[Sites](
	[SiteID] INT NOT NULL IDENTITY(1,1),
	[SiteName] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SiteContent] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ServerCount] INT NULL,
	[AutoScale] BIT NULL
)

CREATE TABLE [dbo].[SitesToServers](
	[SiteID] INT NULL,
	[ServerID] INT NULL,
	[Status] INT NULL
)
