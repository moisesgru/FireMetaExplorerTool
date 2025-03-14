unit uMetadataColumn;

interface

uses
  MVCFramework.ActiveRecord, System.SysUtils, System.JSON, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TMetadataColumn = class
  public
    function GetColumnsJSON(const table_name: string): TJSONArray;
  end;

implementation

function TMetadataColumn.GetColumnsJSON(const table_name: string): TJSONArray;
var
  FDQuery: TFDQuery;
  ColumnsArray: TJSONArray;
  ColumnObject: TJSONObject;
begin
  ColumnsArray := TJSONArray.Create;
  FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := ActiveRecordConnectionsRegistry.GetCurrent;
    FDQuery.SQL.Text :=
      'SELECT ' +
      '  RF.RDB$FIELD_NAME AS name, ' +
      '  F.RDB$FIELD_TYPE AS type, ' +
      '  F.RDB$FIELD_LENGTH AS length, ' +
      '  CASE WHEN RF.RDB$NULL_FLAG IS NULL THEN 1 ELSE 0 END AS nullable ' +
      'FROM RDB$RELATION_FIELDS RF ' +
      'JOIN RDB$FIELDS F ON RF.RDB$FIELD_SOURCE = F.RDB$FIELD_NAME ' +
      'WHERE RF.RDB$RELATION_NAME = :TableName ' +
      'ORDER BY RF.RDB$FIELD_POSITION';
    FDQuery.Params.ParamByName('TableName').AsString := UpperCase(table_name);
    FDQuery.Open;

    while not FDQuery.Eof do
    begin
      ColumnObject := TJSONObject.Create;
      ColumnObject.AddPair('name', Trim(FDQuery.FieldByName('name').AsString));
      ColumnObject.AddPair('type', FDQuery.FieldByName('type').AsString);
      ColumnObject.AddPair('length', TJSONNumber.Create(FDQuery.FieldByName('length').AsInteger));
      ColumnObject.AddPair('nullable', TJSONBool.Create(FDQuery.FieldByName('nullable').AsInteger = 1));
      ColumnsArray.AddElement(ColumnObject);
      FDQuery.Next;
    end;
  finally
    FDQuery.Free;
  end;
  Result := ColumnsArray;
end;

end.

