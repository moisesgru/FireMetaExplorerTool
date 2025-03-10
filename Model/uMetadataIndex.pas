unit uMetadataIndex;

interface

uses
  MVCFramework.ActiveRecord, System.SysUtils, System.JSON, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TMetadataIndex = class
  public
    function GetIndexesJSON(const table_name: string): TJSONArray;
  end;

implementation

function TMetadataIndex.GetIndexesJSON(const table_name: string): TJSONArray;
var
  FDQuery: TFDQuery;
  IndexesArray: TJSONArray;
  IndexObject: TJSONObject;
begin
  IndexesArray := TJSONArray.Create;
  FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := ActiveRecordConnectionsRegistry.GetCurrent;
    FDQuery.SQL.Text :=
      'SELECT ' +
      '  RDB$INDICES.RDB$INDEX_NAME AS index_name, ' +
      '  LIST(Trim(RDB$INDEX_SEGMENTS.RDB$FIELD_NAME), '', '') AS columns, ' +
      '  CASE WHEN RDB$INDICES.RDB$UNIQUE_FLAG = 1 THEN 1 ELSE 0 END AS is_unique ' +
      'FROM RDB$INDEX_SEGMENTS ' +
      'JOIN RDB$INDICES ON RDB$INDEX_SEGMENTS.RDB$INDEX_NAME = RDB$INDICES.RDB$INDEX_NAME ' +
      'WHERE RDB$INDICES.RDB$RELATION_NAME = :TableName ' +
      'GROUP BY RDB$INDICES.RDB$INDEX_NAME, RDB$INDICES.RDB$UNIQUE_FLAG';
    FDQuery.Params.ParamByName('TableName').AsString := UpperCase(table_name);
    FDQuery.Open;

    while not FDQuery.Eof do
    begin
      IndexObject := TJSONObject.Create;
      IndexObject.AddPair('index_name', Trim(FDQuery.FieldByName('index_name').AsString));
      IndexObject.AddPair('columns', Trim(FDQuery.FieldByName('columns').AsString));
      IndexObject.AddPair('is_unique', TJSONBool.Create(FDQuery.FieldByName('is_unique').AsInteger = 1));
      IndexesArray.AddElement(IndexObject);
      FDQuery.Next;
    end;
  finally
    FDQuery.Free;
  end;
  Result := IndexesArray;
end;

end.

