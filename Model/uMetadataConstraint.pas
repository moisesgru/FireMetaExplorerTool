unit uMetadataConstraint;

interface

uses
  MVCFramework.ActiveRecord, System.SysUtils, System.JSON, FireDAC.Comp.Client, FireDAC.Stan.Param;

type
  TMetadataConstraint = class
  public
    function GetConstraintsJSON(const table_name: string): TJSONArray;
  end;

implementation

function TMetadataConstraint.GetConstraintsJSON(const table_name: string): TJSONArray;
var
  FDQuery: TFDQuery;
  ConstraintsArray: TJSONArray;
  ConstraintObject: TJSONObject;
begin
  ConstraintsArray := TJSONArray.Create;
  FDQuery := TFDQuery.Create(nil);
  try
    FDQuery.Connection := ActiveRecordConnectionsRegistry.GetCurrent;
    FDQuery.SQL.Text :=
    'SELECT ' +
    '    RC.RDB$CONSTRAINT_NAME AS CONSTRAINT_NAME, ' +
    '    TRIM(RC.RDB$CONSTRAINT_TYPE) AS CONSTRAINT_TYPE, ' +
    '    CASE ' +
    '        WHEN RC.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'' THEN ' +
    '            (SELECT TRIM(REF_TABLE.RDB$RELATION_NAME) ' +
    '             FROM RDB$RELATION_CONSTRAINTS REF_TABLE ' +
    '             JOIN RDB$REF_CONSTRAINTS REF ON REF_TABLE.RDB$CONSTRAINT_NAME = REF.RDB$CONST_NAME_UQ ' +
    '             WHERE REF.RDB$CONSTRAINT_NAME = RC.RDB$CONSTRAINT_NAME) ' +
    '        ELSE NULL ' +
    '    END AS REFERENCED_TABLE, ' +
    '    CASE ' +
    '        WHEN RC.RDB$CONSTRAINT_TYPE = ''FOREIGN KEY'' THEN ' +
    '            (SELECT LIST(TRIM(SEG.RDB$FIELD_NAME), '', '') ' +
    '             FROM RDB$INDEX_SEGMENTS SEG ' +
    '             JOIN RDB$INDICES IDX ON SEG.RDB$INDEX_NAME = IDX.RDB$INDEX_NAME ' +
    '             WHERE IDX.RDB$INDEX_NAME = ( ' +
    '                 SELECT REF_TABLE.RDB$INDEX_NAME ' +
    '                 FROM RDB$RELATION_CONSTRAINTS REF_TABLE ' +
    '                 JOIN RDB$REF_CONSTRAINTS REF ON REF_TABLE.RDB$CONSTRAINT_NAME = REF.RDB$CONST_NAME_UQ ' +
    '                 WHERE REF.RDB$CONSTRAINT_NAME = RC.RDB$CONSTRAINT_NAME ' +
    '             )) ' +
    '        ELSE NULL ' +
    '    END AS REFERENCED_COLUMN, ' +
    '    (SELECT LIST(TRIM(SEG.RDB$FIELD_NAME), '', '') ' +
    '     FROM RDB$INDEX_SEGMENTS SEG ' +
    '     WHERE SEG.RDB$INDEX_NAME = RC.RDB$INDEX_NAME ' +
    '    ) AS LOCAL_COLUMNS ' +
    'FROM RDB$RELATION_CONSTRAINTS RC ' +
    'LEFT JOIN RDB$REF_CONSTRAINTS RF ON RC.RDB$CONSTRAINT_NAME = RF.RDB$CONSTRAINT_NAME ' +
    'LEFT JOIN RDB$INDICES IDX ON RC.RDB$INDEX_NAME = IDX.RDB$INDEX_NAME ' +
    'WHERE TRIM(RC.RDB$RELATION_NAME) = :TABLENAME ' +
    '  AND RC.RDB$CONSTRAINT_TYPE IN (''PRIMARY KEY'', ''FOREIGN KEY'', ''CHECK'') ' +
    'ORDER BY RC.RDB$CONSTRAINT_TYPE, RC.RDB$CONSTRAINT_NAME;';
    FDQuery.Params.ParamByName('TABLENAME').AsString := UpperCase(table_name);
    FDQuery.Open;

    while not FDQuery.Eof do
    begin
      ConstraintObject := TJSONObject.Create;
      ConstraintObject.AddPair('constraint_name', Trim(FDQuery.FieldByName('constraint_name').AsString));
      ConstraintObject.AddPair('constraint_type', FDQuery.FieldByName('constraint_type').AsString);
      ConstraintObject.AddPair('referenced_table', Trim(FDQuery.FieldByName('referenced_table').AsString));
      ConstraintObject.AddPair('referenced_column', Trim(FDQuery.FieldByName('referenced_column').AsString));
      ConstraintObject.AddPair('local_columns', Trim(FDQuery.FieldByName('local_columns').AsString));
      ConstraintsArray.AddElement(ConstraintObject);
      FDQuery.Next;
    end;
  finally
    FDQuery.Free;
  end;
  Result := ConstraintsArray;
end;

end.

