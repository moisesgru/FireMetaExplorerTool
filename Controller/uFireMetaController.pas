unit uFireMetaController;

{$WARN UNSUPPORTED_CONSTRUCT OFF} // Oculta o warning W1074 para atributos customizados

interface

uses
  System.SysUtils, MVCFramework, MVCFramework.Commons, System.JSON;

type
  [MVCPath('/metadata')]
  TFireMetaController = class(TMVCController)
  public
    [MVCPath('/tables')]
    [MVCHTTPMethod([httpGET])]
    procedure GetTables; // Rota absoluta: /tables

    [MVCPath('/columns/($table_name)')]
    [MVCHTTPMethod([httpGET])]
    procedure GetColumns(const [MVCFromPath] table_name: string); // Rota relativa: /metadata/columns/{table_name}

    [MVCPath('/constraints/($table_name)')]
    [MVCHTTPMethod([httpGET])]
    procedure GetConstraints(const [MVCFromPath] table_name: string); // Rota relativa: /metadata/constraints/{table_name}

    [MVCPath('/indexes/($table_name)')]
    [MVCHTTPMethod([httpGET])]
    procedure GetIndexes(const [MVCFromPath] table_name: string); // Rota relativa: /metadata/indexes/{table_name}

    [MVCPath('/($table_name)')]
    [MVCHTTPMethod([httpGET])]
    procedure GetMetadata(const [MVCFromPath] table_name: string); // Rota relativa: /metadata/{table_name}
  end;


implementation

{$WARN UNSUPPORTED_CONSTRUCT ON} // Reativa os warnings no restante do c�digo

uses
  uMetadataColumn, uMetadataConstraint, uMetadataIndex, uMetadataTables;

procedure TFireMetaController.GetTables;
var
  MetadataTables: TMetadataTables;
begin
  MetadataTables := TMetadataTables.Create;
  try
    Render(MetadataTables.GetTablesJSON, True);
  finally
    FreeAndNil(MetadataTables);
  end;
end;

procedure TFireMetaController.GetColumns(const table_name: string);
var
  MetadataColumn: TMetadataColumn;
begin
  MetadataColumn := TMetadataColumn.Create;
  try
    Render(MetadataColumn.GetColumnsJSON(table_name), True);
  finally
    FreeAndNil(MetadataColumn);
  end;
end;

procedure TFireMetaController.GetConstraints(const table_name: string);
var
  MetadataConstraint: TMetadataConstraint;
begin
  MetadataConstraint := TMetadataConstraint.Create;
  try
    Render(MetadataConstraint.GetConstraintsJSON(table_name), True);
  finally
    FreeAndNil(MetadataConstraint);
  end;
end;

procedure TFireMetaController.GetIndexes(const table_name: string);
var
  MetadataIndex: TMetadataIndex;
begin
  MetadataIndex := TMetadataIndex.Create;
  try
    Render(MetadataIndex.GetIndexesJSON(table_name), True);
  finally
    FreeAndNil(MetadataIndex);
  end;
end;

procedure TFireMetaController.GetMetadata(const table_name: string);
var
  Metadata: TJSONObject;
  MetadataColumn: TMetadataColumn;
  MetadataConstraint: TMetadataConstraint;
  MetadataIndex: TMetadataIndex;
begin
  Metadata := TJSONObject.Create;
  MetadataColumn := TMetadataColumn.Create;
  MetadataConstraint := TMetadataConstraint.Create;
  MetadataIndex := TMetadataIndex.Create;
  try
    Metadata.AddPair('table_name', table_name);
    Metadata.AddPair('columns', MetadataColumn.GetColumnsJSON(table_name));
    Metadata.AddPair('relationships', MetadataConstraint.GetConstraintsJSON(table_name));
    Metadata.AddPair('indexes', MetadataIndex.GetIndexesJSON(table_name));
    Render(Metadata, True);
  finally
    FreeAndNil(MetadataColumn);
    FreeAndNil(MetadataConstraint);
    FreeAndNil(MetadataIndex);
  end;
end;

end.

