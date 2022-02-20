-- ******************** Otus Project DB ********************


CREATE SCHEMA [application];
GO

CREATE SCHEMA [reference];
GO

CREATE SCHEMA [users];
GO

-- ************************************** [users].[Users]
CREATE TABLE [users].[Users]
(
 [id]       int NOT NULL ,
 [username] nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_users] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO
-- ************************************** [reference].[Unit]
CREATE TABLE [reference].[Unit]
(
 [id]         int NOT NULL ,
 [name_short] nvarchar(50) NOT NULL ,
 [name_long]  nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_unit] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO
-- ************************************** [application].[TypeWork]
CREATE TABLE [application].[TypeWork]
(
 [id]    int NOT NULL ,
 [title] nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_type_works] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO
-- ************************************** [reference].[Instruments]
CREATE TABLE [reference].[Instruments]
(
 [id]   int NOT NULL ,
 [name] nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_instruments] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO
-- ************************************** [reference].[Importants]
CREATE TABLE [reference].[Importants]
(
 [id]    int NOT NULL ,
 [name]  nvarchar(50) NOT NULL ,
 [level] int NOT NULL ,


 CONSTRAINT [PK_importants] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO
-- ************************************** [application].[Works]
CREATE TABLE [application].[Works]
(
 [id]           int NOT NULL ,
 [naim]         nvarchar(50) NOT NULL ,
 [create_by]    int NOT NULL ,
 [unit]         int NOT NULL ,
 [type_work_id] int NOT NULL ,
 [quantitie]    float NOT NULL ,
 [create_on]    datetime NOT NULL ,
 [description]  nvarchar(500) NOT NULL ,


 CONSTRAINT [PK_works] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_works_typeworks] FOREIGN KEY ([type_work_id])  REFERENCES [application].[TypeWork]([id]),
 CONSTRAINT [FK_works_unit] FOREIGN KEY ([unit])  REFERENCES [reference].[Unit]([id]),
 CONSTRAINT [FK_works_users] FOREIGN KEY ([create_by])  REFERENCES [users].[Users]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_works_create_by] ON [application].[Works] 
 (
  [create_by] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_works_type_work_id] ON [application].[Works] 
 (
  [type_work_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_works_unit] ON [application].[Works] 
 (
  [unit] ASC
 )

GO
-- ************************************** [users].[UserPlan]
CREATE TABLE [users].[UserPlan]
(
 [id]        int NOT NULL ,
 [title]     nvarchar(500) NOT NULL ,
 [create_by] int NOT NULL ,
 [create_on] datetime NOT NULL ,


 CONSTRAINT [PK_user_plan] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_userplan_users] FOREIGN KEY ([create_by])  REFERENCES [users].[Users]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_userplan_createdby] ON [users].[UserPlan] 
 (
  [create_by] ASC
 )

GO
-- ************************************** [reference].[MaterialUnit]
CREATE TABLE [reference].[MaterialUnit]
(
 [id]          int NOT NULL ,
 [unit]        int NOT NULL ,
 [terget_unit] int NOT NULL ,
 [coefficient] float NOT NULL ,


 CONSTRAINT [PK_material_unit] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_materialunit_target_unit] FOREIGN KEY ([terget_unit])  REFERENCES [reference].[Unit]([id]),
 CONSTRAINT [FK_materialunit_unit] FOREIGN KEY ([unit])  REFERENCES [reference].[Unit]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_materialunit_target_unit] ON [reference].[MaterialUnit] 
 (
  [terget_unit] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_materialunit_unit] ON [reference].[MaterialUnit] 
 (
  [unit] ASC
 )

GO
-- ************************************** [users].[UserBasketWork]
CREATE TABLE [users].[UserBasketWork]
(
 [id]          int NOT NULL ,
 [work_id]     int NOT NULL ,
 [userplan_id] int NOT NULL ,


 CONSTRAINT [PK_user_basket_work] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_userbasket_userplan] FOREIGN KEY ([userplan_id])  REFERENCES [users].[UserPlan]([id]),
 CONSTRAINT [FK_userbasket_works] FOREIGN KEY ([work_id])  REFERENCES [application].[Works]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_userbasketwork_userplan_id] ON [users].[UserBasketWork] 
 (
  [userplan_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_userbasketwork_workid] ON [users].[UserBasketWork] 
 (
  [work_id] ASC
 )

GO
-- ************************************** [application].[Steps]
CREATE TABLE [application].[Steps]
(
 [id]          int NOT NULL ,
 [description] nvarchar(500) NOT NULL ,
 [work_id]     int NOT NULL ,
 [order]       int NOT NULL ,
 [status]      int NOT NULL ,
 [title]       nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_steps] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_steps_works] FOREIGN KEY ([work_id])  REFERENCES [application].[Works]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_steps_workid] ON [application].[Steps] 
 (
  [work_id] ASC
 )

GO
-- ************************************** [reference].[Materials]
CREATE TABLE [reference].[Materials]
(
 [id]            int NOT NULL ,
 [name]          nvarchar(50) NOT NULL ,
 [unit_id]       int NOT NULL ,
 [name_official] nvarchar(50) NOT NULL ,
 [size]          nvarchar(50) NOT NULL ,


 CONSTRAINT [PK_materials] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_materials_materialunit] FOREIGN KEY ([unit_id])  REFERENCES [reference].[MaterialUnit]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_materials_unitid] ON [reference].[Materials] 
 (
  [unit_id] ASC
 )

GO
-- ************************************** [users].[UserSteps]
CREATE TABLE [users].[UserSteps]
(
 [id]                  int NOT NULL ,
 [step_id]             int NOT NULL ,
 [user_basket_work_id] int NOT NULL ,
 [status]              int NOT NULL ,
 [comment]             nvarchar(500) NOT NULL ,
 [order]               int NOT NULL ,


 CONSTRAINT [PK_user_step] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_userstep_steps] FOREIGN KEY ([step_id])  REFERENCES [application].[Steps]([id]),
 CONSTRAINT [FK_userstep_userbasket] FOREIGN KEY ([user_basket_work_id])  REFERENCES [users].[UserBasketWork]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_usersteps_step_id] ON [users].[UserSteps] 
 (
  [step_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_usersteps_userbasketworkid] ON [users].[UserSteps] 
 (
  [user_basket_work_id] ASC
 )

GO
-- ************************************** [application].[StepNotes]
CREATE TABLE [application].[StepNotes]
(
 [id]           int NOT NULL ,
 [note]         int NOT NULL ,
 [step_id]      int NOT NULL ,
 [important_id] int NOT NULL ,
 [order]        int NOT NULL ,


 CONSTRAINT [PK_step_notes] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_importants_stepnotes] FOREIGN KEY ([important_id])  REFERENCES [reference].[Importants]([id]),
 CONSTRAINT [FK_stepnotes_steps] FOREIGN KEY ([step_id])  REFERENCES [application].[Steps]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_stepnotes_importantid] ON [application].[StepNotes] 
 (
  [important_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_stepnotes_stepid] ON [application].[StepNotes] 
 (
  [step_id] ASC
 )

GO
-- ************************************** [application].[StepMaterials]
CREATE TABLE [application].[StepMaterials]
(
 [id]          int NOT NULL ,
 [material_id] int NOT NULL ,
 [unit_id]     int NOT NULL ,
 [step_id]     int NOT NULL ,
 [quantitie]   float NOT NULL ,


 CONSTRAINT [PK_step_materials] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_step_materials_unit] FOREIGN KEY ([unit_id])  REFERENCES [reference].[Unit]([id]),
 CONSTRAINT [FK_stepmaterails_materials] FOREIGN KEY ([material_id])  REFERENCES [reference].[Materials]([id]),
 CONSTRAINT [FK_stepmaterials_steps] FOREIGN KEY ([step_id])  REFERENCES [application].[Steps]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_stepmaterial_material_id] ON [application].[StepMaterials] 
 (
  [material_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_stepmaterial_stepid] ON [application].[StepMaterials] 
 (
  [step_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_stepmaterial_unitid] ON [application].[StepMaterials] 
 (
  [unit_id] ASC
 )

GO
-- ************************************** [application].[StepInstruments]
CREATE TABLE [application].[StepInstruments]
(
 [id]            int NOT NULL ,
 [step_id]       int NOT NULL ,
 [instrument_id] int NOT NULL ,


 CONSTRAINT [PK_step_instruments] PRIMARY KEY CLUSTERED ([id] ASC),
 CONSTRAINT [FK_instruments_stepinstruments] FOREIGN KEY ([instrument_id])  REFERENCES [reference].[Instruments]([id]),
 CONSTRAINT [FK_stepinstruments_steps] FOREIGN KEY ([step_id])  REFERENCES [application].[Steps]([id])
);
GO


CREATE NONCLUSTERED INDEX [IX_stepinstruments_instrument_id] ON [application].[StepInstruments] 
 (
  [instrument_id] ASC
 )

GO

CREATE NONCLUSTERED INDEX [IX_stepinstruments_stepid] ON [application].[StepInstruments] 
 (
  [step_id] ASC
 )

GO
