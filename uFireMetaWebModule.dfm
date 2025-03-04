object FireMetaWebModule: TFireMetaWebModule
  OnCreate = WebModuleCreate
  OnDestroy = WebModuleDestroy
  Actions = <>
  Height = 230
  Width = 415
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = 'fbclient.dll'
    Embedded = True
    Left = 64
    Top = 24
  end
end
