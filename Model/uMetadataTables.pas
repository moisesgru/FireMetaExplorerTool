unit uMetadataTables;

interface

uses
  MVCFramework, MVCFramework.ActiveRecord, System.SysUtils, System.JSON, FireDAC.Comp.Client;

type
  TMetadataTables = class
  private
    function GetMetadata(const table_name: string): TJSONObject;
  public
    function GetTablesJSON: TJSONArray;
  end;

implementation

uses
  uMetadataColumn, uMetadataConstraint, uMetadataIndex;

function TMetadataTables.GetMetadata(const table_name: string): TJSONObject;
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
  finally
    Result := Metadata;
    FreeAndNil(MetadataColumn);
    FreeAndNil(MetadataConstraint);
    FreeAndNil(MetadataIndex);
  end;
end;

function TMetadataTables.GetTablesJSON: TJSONArray;
var
  FDQuery: TFDQuery;
  TablesArray, MetadataArray: TJSONArray;
  TableObject: TJSONValue; // Alterado para TJSONValue, pois for in retorna TJSONValue
  TableName: string;
  MetadataObject: TJSONObject;
begin
  TablesArray := TJSONArray.Create;
  MetadataArray := TJSONArray.Create; // Novo array para armazenar metadados
  FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := ActiveRecordConnectionsRegistry.GetCurrent;
    FDQuery.SQL.Text :=
      'SELECT TRIM(RDB$RELATION_NAME) AS TABLE_NAME ' +
      'FROM RDB$RELATIONS ' +
      'WHERE RDB$SYSTEM_FLAG = 0 AND RDB$VIEW_BLR IS NULL ' +
      'ORDER BY RDB$RELATION_NAME';
    FDQuery.Open;

    while not FDQuery.Eof do
    begin
      TableName := FDQuery.FieldByName('TABLE_NAME').AsString;

      // Adiciona no array original
      TablesArray.AddElement(TJSONObject.Create.AddPair('table_name', TableName));

      FDQuery.Next;
    end;

    // Loop for-in para percorrer TablesArray
    for TableObject in TablesArray do
    begin
      if TableObject is TJSONObject then
      begin
        // Faz o cast para TJSONObject
        TableName := TJSONObject(TableObject).GetValue<string>('table_name');

        // Obter o metadado e adicionar no array de metadados
        MetadataObject := GetMetadata(TableName);
        MetadataArray.AddElement(MetadataObject);

        // Log no console
        WriteLn(TableName + ': http://localhost:8080/metadata/' + TableName);
        WriteLn('');
      end;
    end;
  finally
    FDQuery.Free;
  end;

  // Retorna o array original com os nomes das tabelas
  Result := MetadataArray;
end;

end.

