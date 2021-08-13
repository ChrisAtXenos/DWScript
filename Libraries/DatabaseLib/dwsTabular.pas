{**********************************************************************}
{                                                                      }
{    "The contents of this file are subject to the Mozilla Public      }
{    License Version 1.1 (the "License"); you may not use this         }
{    file except in compliance with the License. You may obtain        }
{    a copy of the License at http://www.mozilla.org/MPL/              }
{                                                                      }
{    Software distributed under the License is distributed on an       }
{    "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, either express       }
{    or implied. See the License for the specific language             }
{    governing rights and limitations under the License.               }
{                                                                      }
{    Copyright Creative IT.                                            }
{    Current maintainer: Eric Grange                                   }
{                                                                      }
{**********************************************************************}
unit dwsTabular;

{$i dws.inc}

interface

uses SysUtils, dwsUtils;

type

   EdwsTabular = class (Exception);

   PdwsTabularNumberStats = ^TdwsTabularNumberStats;
   TdwsTabularNumberStats = record
      public
         Mini, Maxi : Double;
         Average, Sum, SumOfSquares : Double;
         Count : Integer;
   end;

   TdwsTabularColumn = class
      private
         FNumbers : TDoubleDynArray;
         FStrings : TStringDynArray;
         FUnifier : TStringUnifier;

         FCount : Integer;
         FCountEmpty : Integer;
         FCountNonNumeric : Integer;

         FNumberStats : PdwsTabularNumberStats;

      protected
         procedure ClearStats; inline;
         procedure SetCount(n : Integer);

      public
         constructor Create;
         destructor Destroy; override;

         property Numbers : TDoubleDynArray read FNumbers;
         function NumbersDataPtr : PDoubleArray;
         property Strings : TStringDynArray read FStrings;
         function StringsDataPtr : PStringArray;

         procedure Add(const v : String); overload;
         procedure Add(const v : Double); overload;
         procedure Add(const s : String; d : Double); overload;

         property Count : Integer read FCount write SetCount;
         property CountEmpty : Integer read FCountEmpty;
         property CountNonNumeric : Integer read FCountNonNumeric;

         function NumberStats : TdwsTabularNumberStats;

         function CountDistinctStrings : Integer;
         function DistinctStrings : TStringDynArray;
   end;

   TdwsTabularColumns = array of TdwsTabularColumn;

   TdwsTabular = class
      private
         FColumnNames : TStringDynArray;
         FColumnData : TdwsTabularColumns;

      protected

      public
         destructor Destroy; override;

         function AddColumn(const name : String) : TdwsTabularColumn;
         function DropColumn(const name : String) : Boolean;
         function IndexOfColumn(const name : String) : Integer;
         function ColumnByName(const name : String) : TdwsTabularColumn;

         function DoublePtrOfColumn(const name : String) : Pointer;
         function StringPtrOfColumn(const name : String) : Pointer;

         property ColumnNames : TStringDynArray read FColumnNames;
         property ColumnData : TdwsTabularColumns read FColumnData;

         function RowCount : Integer;
   end;

   TdwsTabularStack = class
      private
         FRowIndex : Integer;
         FData : TDoubleDynArray;
         FStackPtr : PDouble;
         FStackSize : Integer;

      protected
         function GetPeek : Double; inline;
         procedure SetPeek(const val : Double); inline;

      public
         constructor Create(stackSize : Integer = 256);

         property RowIndex : Integer read FRowIndex write FRowIndex;
         property StackSize : Integer read FStackSize;
         property Peek : Double read GetPeek write SetPeek;
         function PeekPtr : PDouble; inline;

         procedure Clear;
         procedure Push(const v : Double); inline;
         function Pop : Double; inline;
         function DecStackPtr : PDouble; inline;
   end;

   TdwsTabularOpcodeType = (optypField, optypOp);
   PdwsTabularOpcode = ^TdwsTabularOpcode;
   TdwsTabularOpcode = record
      Method : procedure (stack : TdwsTabularStack; op : PdwsTabularOpcode);
      Operand1, Operand2 : Double;
      DoublePtr : PDoubleArray;
      StringPtr : PStringArray;
      Lookup : TObject;
      Typ : TdwsTabularOpcodeType;
      StackDepth : Integer;
   end;
   TdwsTabularOpcodes = array of TdwsTabularOpcode;

   TdwsNameValueBucket = record
      Name : String;
      Value : Double;
   end;
   TdwsNameValues = class (TSimpleHash<TdwsNameValueBucket>)
      protected
         function SameItem(const item1, item2 : TdwsNameValueBucket) : Boolean; override;
         function GetItemHashCode(const item1 : TdwsNameValueBucket) : Cardinal; override;

         function GetValues(const name : String) : Double;
         procedure SetValues(const name : String; const v : Double);

      public
         class procedure DoLookup(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;

         procedure FromJSON(const j : String);
         function ToJSON : String;

         property Values[const name : String] : Double read GetValues write SetValues;
   end;

   TdwsLinearNameValues = class
      private
         FNames : TStringDynArray;
         FValues : TDoubleDynArray;
         FCount : Integer;
         FUnified : Boolean;

      protected
         procedure Add(const name : String; const value : Double);
         procedure Sort;
         function Compare(a, b : NativeInt) : Integer;
         procedure Swap(a, b : NativeInt);

      public
         constructor Create(nv : TdwsNameValues; unifier : TStringUnifier);

         property Count : Integer read FCount;

         class procedure DoLookup(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoLookupUnified(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
   end;

   TdwsTabularExpression = class
      private
         FTabular : TdwsTabular;
         FOpcodes : TdwsTabularOpcodes;
         FObjectBag : array of TObject;
         FStackDepth : Integer;
         FMaxStackDepth : Integer;

      protected
         function AddOpCode(typ : TdwsTabularOpcodeType) : PdwsTabularOpcode;
         procedure DeleteLastOpCode;

         procedure StackDelta(delta : Integer);

         function LastOpCode : PdwsTabularOpcode;
         function LastOpCodeIsConst : Boolean;
         function PrevOpCode : PdwsTabularOpcode;
         function PrevOpCodeIsMultConst : Boolean;

         class procedure DoPushConst(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoPushNumField(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoPushNumFieldDef(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoMultAddConst(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoAdd(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoAddConst(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoSub(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoMult(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoMultConst(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoMin(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoMax(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoReLu(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoLn(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoExp(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoSqr(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoAbs(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoGTRE(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;
         class procedure DoGTREConst(stack : TdwsTabularStack; op : PdwsTabularOpcode); static;

      public
         constructor Create(aTabular : TdwsTabular);
         destructor Destroy; override;

         property Tabular : TdwsTabular read FTabular;

         procedure Opcode(const code : String);
         procedure Clear;

         procedure PushConst(const c : Double);
         procedure PushNumField(const name : String);
         procedure PushNumFieldDef(const name : String; const default : Double);
         procedure PushLookupField(const name : String; values : TdwsNameValues; const default : Double);

         procedure MultAddConst(const m, a : Double);
         procedure Add;
         procedure Sub;
         procedure Mult;
         procedure Min;
         procedure Max;
         procedure ReLu;
         procedure Ln;
         procedure Exp;
         procedure Sqr;
         procedure Abs;
         procedure GreaterOrEqual;

         property MaxStackDepth : Integer read FMaxStackDepth;
         property StackDepth : Integer read FStackDepth;

         function Evaluate(stack : TdwsTabularStack) : Double;
   end;


// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
implementation
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

uses System.Math, dwsJSON, dwsXXHash, dwsXPlatform;

var
   vDotFormatSettings : TFormatSettings;

// ------------------
// ------------------ TdwsTabularColumn ------------------
// ------------------

// Create
//
constructor TdwsTabularColumn.Create;
begin
   inherited;
   FUnifier := TStringUnifier.Create;
end;

// Destroy
//
destructor TdwsTabularColumn.Destroy;
begin
   ClearStats;
   FUnifier.Free;
   inherited;
end;

// ClearStats
//
procedure TdwsTabularColumn.ClearStats;
begin
   if FNumberStats <> nil then begin
      FreeMem(FNumberStats);
      FNumberStats := nil;
   end;
end;

// SetCount
//
procedure TdwsTabularColumn.SetCount(n : Integer);
var
   buf : Double;
begin
   Assert((n >= 0) and (n <= Count), 'only removing rows is supported');
   if n < Count then begin
      for var k := n-1 to Count-1 do begin
         if FStrings[k] = '' then
            Dec(FCountEmpty)
         else if not TryStrToDouble(FStrings[k], buf) then
            Dec(FCountNonNumeric);
      end;
      SetLength(FStrings, n);
      SetLength(FNumbers, n);
      FCount := n;
   end;
end;

// DataPtr
//
function TdwsTabularColumn.NumbersDataPtr : PDoubleArray;
begin
   Result := @FNumbers[0];
end;

// StringsDataPtr
//
function TdwsTabularColumn.StringsDataPtr : PStringArray;
begin
   Result := @FStrings[0];
end;

// Add
//
procedure TdwsTabularColumn.Add(const v : String);
begin
   ClearStats;
   var n := FCount;
   FCount := n+1;
   SetLength(FNumbers, FCount);
   SetLength(FStrings, FCount);
   if v = '' then begin
      Inc(FCountEmpty);
      FNumbers[n] := 0;
   end else begin
      if not TryStrToDouble(v, FNumbers[n]) then begin
         Inc(FCountNonNumeric);
         FNumbers[n] := 0;
      end;
      FUnifier.UnifyAssign(v, FStrings[n]);
   end;
end;

// Add
//
procedure TdwsTabularColumn.Add(const v : Double);
begin
   var buf : String;
   FastFloatToStr(v, buf, vDotFormatSettings);
   Add(buf, v);
end;

// Add
//
procedure TdwsTabularColumn.Add(const s : String; d : Double);
begin
   ClearStats;
   var n := FCount;
   FCount := n+1;
   SetLength(FNumbers, FCount);
   SetLength(FStrings, FCount);
   FNumbers[n] := d;
   if s = '' then
      Inc(FCountEmpty);
   FUnifier.UnifyAssign(s, FStrings[n]);
end;

// NumberStats
//
function TdwsTabularColumn.NumberStats : TdwsTabularNumberStats;
begin
   if FNumberStats = nil then begin
      FNumberStats := AllocMem(SizeOf(TdwsTabularNumberStats));
      FNumberStats.Count := FCount;
      if FCount > 0 then begin
         var v := FNumbers[0];
         FNumberStats.Mini := v;
         FNumberStats.Maxi := v;
         FNumberStats.Sum := v;
         FNumberStats.SumOfSquares := v*v;
         for var i := 1 to FCount-1 do begin
            v := FNumbers[i];
            if v < FNumberStats.Mini then FNumberStats.Mini := v;
            if v > FNumberStats.Maxi then FNumberStats.Maxi := v;
            FNumberStats.Sum := FNumberStats.Sum + v;
            FNumberStats.SumOfSquares := FNumberStats.SumOfSquares + v*v;
         end;
         FNumberStats.Average := FNumberStats.Sum / FCount;
      end;
   end;
   Result := FNumberStats^;
end;

// CountDistinctStrings
//
function TdwsTabularColumn.CountDistinctStrings : Integer;
begin
   Result := FUnifier.Count;
end;

// DistinctStrings
//
function TdwsTabularColumn.DistinctStrings : TStringDynArray;
begin
   Result := FUnifier.DistinctStrings;
end;

// ------------------
// ------------------ TdwsTabular ------------------
// ------------------

// AddColumn
//
function TdwsTabular.AddColumn(const name : String) : TdwsTabularColumn;
var
   n : Integer;
begin
   Result := TdwsTabularColumn.Create;
   n := Length(FColumnNames);
   SetLength(FColumnNames, n+1);
   SetLength(FColumnData, n+1);
   FColumnNames[n] := name;
   FColumnData[n] := Result;
end;

// DropColumn
//
function TdwsTabular.DropColumn(const name : String) : Boolean;
begin
   var idx := IndexOfColumn(name);
   if idx >= 0 then begin
      var col := FColumnData[idx];
      Delete(FColumnData, idx, 1);
      Delete(FColumnNames, idx, 1);
      col.Free;
      Result := True;
   end else Result := False;
end;

// IndexOfColumn
//
function TdwsTabular.IndexOfColumn(const name : String) : Integer;
begin
   for var i := 0 to High(FColumnNames) do
      if FColumnNames[i] = name then Exit(i);
   Result := -1;
end;

// ColumnByName
//
function TdwsTabular.ColumnByName(const name : String) : TdwsTabularColumn;
begin
   var i := IndexOfColumn(name);
   if i >= 0 then
      Result := FColumnData[i]
   else Result := nil;
end;

// DoublePtrOfColumn
//
function TdwsTabular.DoublePtrOfColumn(const name : String) : Pointer;
begin
   var i := IndexOfColumn(name);
   Assert(i >= 0);
   Result := FColumnData[i].NumbersDataPtr;
end;

// StringPtrOfColumn
//
function TdwsTabular.StringPtrOfColumn(const name : String) : Pointer;
begin
   var i := IndexOfColumn(name);
   Assert(i >= 0);
   Result := FColumnData[i].StringsDataPtr;
end;

// RowCount
//
function TdwsTabular.RowCount : Integer;
begin
   if Length(FColumnData) > 0 then
      Result := FColumnData[0].Count
   else Result := 0;
end;

// Destroy
//
destructor TdwsTabular.Destroy;
begin
   for var i := 0 to High(FColumnData) do
      FColumnData[i].Free;
   inherited;
end;

// ------------------
// ------------------ TdwsTabularStack ------------------
// ------------------

// Create
//
constructor TdwsTabularStack.Create(stackSize : Integer = 256);
begin
   inherited Create;
   SetLength(FData, stackSize);
   FStackSize := stackSize;
   Clear;
end;

// Clear
//
procedure TdwsTabularStack.Clear;
begin
   FStackPtr := @FData[0];
   Dec(FStackPtr);
end;

// Push
//
procedure TdwsTabularStack.Push(const v : Double);
begin
   PDoubleArray(FStackPtr)[1] := v;
   Inc(FStackPtr);
end;

// Pop
//
function TdwsTabularStack.Pop : Double;
begin
   Result := FStackPtr^;
   Dec(FStackPtr);
end;

// DecStackPtr
//
function TdwsTabularStack.DecStackPtr : PDouble;
begin
   Result := FStackPtr;
   Dec(Result);
   FStackPtr := Result;
end;

// GetPeek
//
function TdwsTabularStack.GetPeek : Double;
begin
   Result := FStackPtr^;
end;

// SetPeek
//
procedure TdwsTabularStack.SetPeek(const val : Double);
begin
   FStackPtr^ := val;
end;

// PeekPtr
//
function TdwsTabularStack.PeekPtr : PDouble;
begin
   Result := FStackPtr;
end;

// ------------------
// ------------------ TdwsNameValues ------------------
// ------------------

// SameItem
//
function TdwsNameValues.SameItem(const item1, item2 : TdwsNameValueBucket) : Boolean;
begin
   Result := item1.Name = item2.Name;
end;

// GetItemHashCode
//
function TdwsNameValues.GetItemHashCode(const item1 : TdwsNameValueBucket) : Cardinal;
begin
   Result := SimpleStringHash(item1.Name);
end;

// GetValues
//
function TdwsNameValues.GetValues(const name : String) : Double;
var
   bucket : TdwsNameValueBucket;
begin
   bucket.Name := name;
   if Match(bucket) then
      Result := bucket.Value
   else Result := 0;
end;

// SetValues
//
procedure TdwsNameValues.SetValues(const name : String; const v : Double);
var
   bucket : TdwsNameValueBucket;
begin
   bucket.Name := name;
   bucket.Value := v;
   Replace(bucket);
end;

// DoLookup
//
class procedure TdwsNameValues.DoLookup(stack : TdwsTabularStack; op : PdwsTabularOpcode);
var
   bucket : TdwsNameValueBucket;
begin
   bucket.Name := op.StringPtr[stack.RowIndex];
   if TdwsNameValues(op.Lookup).Match(bucket) then
      stack.Push(bucket.Value)
   else stack.Push(op.Operand1);
end;

// FromJSON
//
procedure TdwsNameValues.FromJSON(const j : String);
begin
   var jv := TdwsJSONValue.ParseString(j);
   try
      if jv.ValueType <> jvtObject then raise EdwsTabular.CreateFmt('JSON object expected but got %s', [ j ]);
      for var i := 0 to jv.ElementCount-1 do begin
         Values[jv.Names[i]] := jv.Elements[i].AsNumber;
      end;
   finally
      jv.Free;
   end;
end;

// ToJSON
//
function TdwsNameValues.ToJSON : String;
begin
   var wr := TdwsJSONWriter.Create;
   try
      wr.BeginObject;
         var bucket : TdwsNameValueBucket;
         for var i := 0 to Capacity-1 do
            if HashBucketValue(i, bucket) then
               wr.WriteName(bucket.Name).WriteNumber(bucket.Value);
      wr.EndObject;
      Result := wr.ToString;
   finally
      wr.Free;
   end;
end;

// ------------------
// ------------------ TdwsLinearNameValues ------------------
// ------------------

// Create
//
constructor TdwsLinearNameValues.Create(nv : TdwsNameValues; unifier : TStringUnifier);
var
   bucket : TdwsNameValueBucket;
   i : Integer;
   buf : String;
begin
   inherited Create;
   FUnified := unifier <> nil;
   for i := 0 to nv.Capacity-1 do
      if nv.HashBucketValue(i, bucket) then
         if FUnified then begin
            unifier.UnifyAssign(bucket.Name, buf);
            Add(buf, bucket.Value)
         end else Add(bucket.Name, bucket.Value);
   if not FUnified then
      Sort;
end;

// DoLookup
//
class procedure TdwsLinearNameValues.DoLookup(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var ps : PString := @(op.StringPtr[stack.RowIndex]);
   if ps^ <> '' then begin
      var top := 0;
      var lnv := TdwsLinearNameValues(op.Lookup);
      var bottom := lnv.FCount - 1;
      while top <= bottom do begin
         var mid := (top + bottom) shr 1;
         var c := CompareStr(lnv.FNames[mid], ps^);
         if c < 0 then
            top := mid + 1
         else begin
            bottom := mid - 1;
            if c = 0 then begin
               stack.Push(lnv.FValues[mid]);
               Exit;
            end;
         end;
      end;
   end;
   stack.Push(op.Operand1);
end;

// DoLookupUnified
//
class procedure TdwsLinearNameValues.DoLookupUnified(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := Pointer(op.StringPtr[stack.RowIndex]);
   if p <> nil then begin
      var lnv := TdwsLinearNameValues(op.Lookup);
      for var i := lnv.FCount-1 downto 0 do begin
         if Pointer(lnv.FNames[i]) = p then begin
            stack.Push(lnv.FValues[i]);
            Exit;
         end;
      end;
   end;
   stack.Push(op.Operand1);
end;

// Add
//
procedure TdwsLinearNameValues.Add(const name : String; const value : Double);
begin
   var n := FCount;
   FCount := n+1;
   SetLength(FNames, FCount);
   SetLength(FValues, FCount);
   FNames[n] := name;
   FValues[n] := value;
end;

// Sort
//
procedure TdwsLinearNameValues.Sort;
begin
   var qs : TQuickSort;
   qs.CompareMethod := Compare;
   qs.SwapMethod := Swap;
end;

// Compare
//
function TdwsLinearNameValues.Compare(a, b : NativeInt) : Integer;
begin
   Result := CompareStr(FNames[a], FNames[b]);
end;

// Swap
//
procedure TdwsLinearNameValues.Swap(a, b : NativeInt);
var
   bufP : Pointer;
   bufV : Double;
begin
   bufP := PPointer(@FNames[a])^;
   PPointer(@FNames[a])^ := PPointer(@FNames[b])^;
   PPointer(@FNames[b])^ := bufP;

   bufV := FValues[a];
   FValues[a] := FValues[b];
   FValues[b] := bufV;
end;

// ------------------
// ------------------ TdwsTabularExpression ------------------
// ------------------

// Create
//
constructor TdwsTabularExpression.Create(aTabular : TdwsTabular);
begin
   inherited Create;
   FTabular := aTabular;
end;

// Destroy
//
destructor TdwsTabularExpression.Destroy;
begin
   Clear;
   inherited;
end;

// Opcode
//
procedure TdwsTabularExpression.Opcode(const code : String);

   procedure RaiseSyntaxError;
   begin
      raise EdwsTabular.CreateFmt('Syntax error for "%s"', [ code ]);
   end;

   procedure ParseNum;
   var
      v : Double;
   begin
      if TryStrToDouble(code, v) then
         PushConst(v)
      else RaiseSyntaxError;
   end;

   procedure ParseField;
   var
      v : Double;
   begin
      var p := Pos('"', code, 2);
      if p <= 0 then RaiseSyntaxError;
      var name := Copy(code, 2, p-2);
      var tail := Copy(code, p+1);
      if tail = '' then begin
         PushNumField(name);
         Exit;
      end;
      if tail[1] <> ' ' then RaiseSyntaxError;
      p := Pos(' ', tail, 2);
      if p <= 0 then begin
         if not TryStrToDouble(Copy(tail, 2), v) then
            RaiseSyntaxError;
         PushNumFieldDef(name, v);
      end else begin
         if not TryStrToDouble(Copy(tail, 2, p-2), v) then
            RaiseSyntaxError;
         var values := TdwsNameValues.Create;
         try
            values.FromJSON(Copy(tail, p+1));
         except
            values.Free;
            raise;
         end;
         PushLookupField(name, values, v);
      end;
   end;

begin
   var n := Length(code);
   case n of
      0 : Exit;
      1 : case code[1] of
            '+' : Add;
            '-' : Sub;
            '*' : Mult;
            '0'..'9' : PushConst(Ord(Code[1])-Ord('0'));
         else
            RaiseSyntaxError;
         end;
      2 : case code[1] of
            'l' :
               if code = 'ln' then Ln
               else RaiseSyntaxError;
            '>' :
               if code = '>=' then GreaterOrEqual
               else RaiseSyntaxError;
            '0'..'9', '-', '.' : ParseNum;
         else
            RaiseSyntaxError;
         end;
      3 : case code[1] of
            'a' :
               if code = 'abs' then Abs
               else RaiseSyntaxError;
            'e' :
               if code = 'exp' then Exp
               else RaiseSyntaxError;
            'm' :
               if code = 'min' then Min
               else if code = 'max' then Max
               else RaiseSyntaxError;
            's' :
               if code = 'sqr' then Sqr
               else RaiseSyntaxError;
            '"' : ParseField;
            '0'..'9', '-', '.' : ParseNum;
         else
            RaiseSyntaxError
         end;
      4 : case code[1] of
            'r' :
               if code = 'relu' then ReLu
               else RaiseSyntaxError;
            '"' : ParseField;
            '0'..'9', '-', '.' : ParseNum;
         else
            RaiseSyntaxError
         end;
   else
      case code[1] of
         '"' : ParseField;
         '0'..'9', '-', '.' : ParseNum;
      else
         RaiseSyntaxError
      end;
   end;
end;

// Clear
//
procedure TdwsTabularExpression.Clear;
begin
   for var i := 0 to High(FObjectBag) do
      FObjectBag[i].Free;
   SetLength(FObjectBag, 0);
   SetLength(FOpcodes, 0);
end;

// AddOpCode
//
function TdwsTabularExpression.AddOpCode(typ : TdwsTabularOpcodeType) : PdwsTabularOpcode;
begin
   var n := Length(FOpcodes);
   SetLength(FOpcodes, n+1);
   Result := @FOpcodes[n];
   Result.StackDepth := StackDepth;
end;

// DeleteLastOpCode
//
procedure TdwsTabularExpression.DeleteLastOpCode;
begin
   var n := Length(FOpcodes);
   Assert(n > 0);
   SetLength(FOpcodes, n-1);
end;

// StackDelta
//
procedure TdwsTabularExpression.StackDelta(delta : Integer);
begin
   FStackDepth := FStackDepth + delta;
   if FStackDepth <= 0 then
      EdwsTabular.Create('Unbalanced opcode');
   if FStackDepth > FMaxStackDepth then
      FMaxStackDepth := FStackDepth;
end;

// LastOpCode
//
function TdwsTabularExpression.LastOpCode : PdwsTabularOpcode;
begin
   var n := High(FOpcodes);
   if n >= 0 then
      Result := @FOpcodes[n]
   else Result := nil;
end;

// LastOpCodeIsConst
//
function TdwsTabularExpression.LastOpCodeIsConst : Boolean;
begin
   var n := High(FOpcodes);
   Result := (n >= 0) and (@FOpcodes[n].Method = @DoPushConst);
end;

// PrevOpCode
//
function TdwsTabularExpression.PrevOpCode : PdwsTabularOpcode;
begin
   var n := High(FOpcodes)-1;
   if n >= 0 then
      Result := @FOpcodes[n]
   else Result := nil;
end;

// PrevOpCodeIsMultConst
//
function TdwsTabularExpression.PrevOpCodeIsMultConst : Boolean;
begin
   var n := High(FOpcodes)-1;
   Result := (n >= 0) and (@FOpcodes[n].Method = @DoMultConst);
end;

// DoPushConst
//
class procedure TdwsTabularExpression.DoPushConst(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Push(op.Operand1);
end;

// DoPushNumField
//
class procedure TdwsTabularExpression.DoPushNumField(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Push(op.DoublePtr[stack.RowIndex]);
end;

// DoPushNumFieldDef
//
class procedure TdwsTabularExpression.DoPushNumFieldDef(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var i := stack.RowIndex;
   if op.StringPtr[i] = '' then
      stack.Push(op.Operand1)
   else stack.Push(op.DoublePtr[i]);
end;

// DoMultConst
//
class procedure TdwsTabularExpression.DoMultAddConst(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := p^ * op.Operand1 + op.Operand2;
end;

// DoAdd
//
class procedure TdwsTabularExpression.DoAdd(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
//   stack.Peek := stack.Pop + stack.Peek;
   var p := stack.DecStackPtr;
   p^ := p^ + PDoubleArray(p)[1];
end;

// DoAddConst
//
class procedure TdwsTabularExpression.DoAddConst(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := stack.Peek + op.Operand1;
end;

// DoSub
//
class procedure TdwsTabularExpression.DoSub(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := stack.Pop - stack.Peek;
end;

// DoMult
//
class procedure TdwsTabularExpression.DoMult(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := stack.Pop * stack.Peek;
end;

// DoMultConst
//
class procedure TdwsTabularExpression.DoMultConst(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := stack.Peek * op.Operand1;
end;

// DoMin
//
class procedure TdwsTabularExpression.DoMin(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := System.Math.Min(stack.Pop, stack.Peek);
end;

// DoMax
//
class procedure TdwsTabularExpression.DoMax(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := System.Math.Max(stack.Pop, stack.Peek);
end;

// DoReLu
//
class procedure TdwsTabularExpression.DoReLu(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := System.Math.Max(0, stack.Pop + stack.Peek);
end;

// DoLn
//
class procedure TdwsTabularExpression.DoLn(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := System.Ln(p^);
end;

// DoExp
//
class procedure TdwsTabularExpression.DoExp(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := System.Exp(p^);
end;

// DoSqr
//
class procedure TdwsTabularExpression.DoSqr(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := System.Sqr(p^);
end;

// DoAbs
//
class procedure TdwsTabularExpression.DoAbs(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := System.Abs(p^);
end;

// DoGTRE
//
class procedure TdwsTabularExpression.DoGTRE(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   stack.Peek := Ord(stack.Pop >= stack.Peek)
end;

// DoGTREConst
//
class procedure TdwsTabularExpression.DoGTREConst(stack : TdwsTabularStack; op : PdwsTabularOpcode);
begin
   var p := stack.PeekPtr;
   p^ := Ord(p^ >= op.Operand1);
end;

// PushConst
//
procedure TdwsTabularExpression.PushConst(const c : Double);
begin
   var op := AddOpCode(optypOp);
   op.Method := @DoPushConst;
   op.Operand1 := c;
   StackDelta(1);
end;

// PushNumField
//
procedure TdwsTabularExpression.PushNumField(const name : String);
begin
   var op := AddOpCode(optypField);
   op.Method := @DoPushNumField;
   op.DoublePtr := Tabular.DoublePtrOfColumn(name);
   StackDelta(1);
end;

// PushNumFieldDef
//
procedure TdwsTabularExpression.PushNumFieldDef(const name : String; const default : Double);
begin
   var op := AddOpCode(optypField);
   op.Method := @DoPushNumFieldDef;
   op.Operand1 := default;
   op.DoublePtr := Tabular.DoublePtrOfColumn(name);
   op.StringPtr := Tabular.StringPtrOfColumn(name);
   StackDelta(1);
end;

// PushLookupField
//
procedure TdwsTabularExpression.PushLookupField(const name : String; values : TdwsNameValues; const default : Double);
begin
   var op := AddOpCode(optypField);

   var column := Tabular.ColumnByName(name);

   var n := Length(FObjectBag);
   SetLength(FObjectBag, n+1);
   if values.Count < 12 then begin
      var lnv := TdwsLinearNameValues.Create(values, column.FUnifier);
      if lnv.FUnified then
         op.Method := @lnv.DoLookupUnified
      else op.Method := @lnv.DoLookup;
      op.Lookup := lnv;
      FObjectBag[n] := lnv;
      FreeAndNil(values);
   end else begin
      op.Method := @values.DoLookup;
      op.Lookup := values;
      FObjectBag[n] := values;
   end;

   op.StringPtr := column.StringsDataPtr;
   op.Operand1 := default;
   StackDelta(1);
end;

// MultAddConst
//
procedure TdwsTabularExpression.MultAddConst(const m, a : Double);
begin
   var op := AddOpCode(optypOp);
   op.Method := @DoMultAddConst;
   op.Operand1 := m;
   op.Operand2 := a;
end;

// Add
//
procedure TdwsTabularExpression.Add;
begin
   if LastOpCodeIsConst then begin
      if PrevOpCodeIsMultConst then begin
         PrevOpCode.Operand2 := LastOpCode.Operand1;
         PrevOpCode.Method := @DoMultAddConst;
         DeleteLastOpCode;
      end else begin
         LastOpCode.Method := @DoAddConst;
      end;
   end else begin
      AddOpCode(optypOp).Method := @DoAdd;
   end;
   StackDelta(-1);
end;

// Sub
//
procedure TdwsTabularExpression.Sub;
begin
   if LastOpCodeIsConst then begin
      var p := LastOpCode;
      p.Operand1 := -p.Operand1;
      p.Method := @DoAddConst;
   end else begin
      AddOpCode(optypOp).Method := @DoSub;
   end;
   StackDelta(-1);
end;

// Mult
//
procedure TdwsTabularExpression.Mult;
begin
   if LastOpCodeIsConst then begin
      LastOpCode.Method := @DoMultConst;
   end else begin
      AddOpCode(optypOp).Method := @DoMult;
   end;
   StackDelta(-1);
end;

// Min
//
procedure TdwsTabularExpression.Min;
begin
   AddOpCode(optypOp).Method := @DoMin;
   StackDelta(-1);
end;

// Max
//
procedure TdwsTabularExpression.Max;
begin
   AddOpCode(optypOp).Method := @DoMax;
   StackDelta(-1);
end;

// ReLu
//
procedure TdwsTabularExpression.ReLu;
begin
   AddOpCode(optypOp).Method := @DoReLu;
   StackDelta(-1);
end;

// Ln
//
procedure TdwsTabularExpression.Ln;
begin
   AddOpCode(optypOp).Method := @DoLn;
end;

// Exp
//
procedure TdwsTabularExpression.Exp;
begin
   AddOpCode(optypOp).Method := @DoExp;
end;

// Sqr
//
procedure TdwsTabularExpression.Sqr;
begin
   AddOpCode(optypOp).Method := @DoSqr;
end;

// Abs
//
procedure TdwsTabularExpression.Abs;
begin
   AddOpCode(optypOp).Method := @DoAbs;
end;

// GreaterOrEqual
//
procedure TdwsTabularExpression.GreaterOrEqual;
begin
   if LastOpCodeIsConst then begin
      LastOpCode.Method := @DoGTREConst;
   end else begin
      AddOpCode(optypOp).Method := @DoGTRE;
   end;
   StackDelta(-1);
end;

// Evaluate
//
function TdwsTabularExpression.Evaluate(stack : TdwsTabularStack) : Double;
begin
   if FStackDepth <> 1 then
      raise EdwsTabular.Create('Unbalanced opcodes');
   if stack.StackSize < MaxStackDepth then
      raise EdwsTabular.Create('Insufficient stack size');
   stack.Clear;
   var n := Length(FOpcodes);
   var p : PdwsTabularOpcode := @FOpcodes[0];
   while n >= 4 do begin
      p.Method(stack, p);
      Inc(p);
      p.Method(stack, p);
      Inc(p);
      p.Method(stack, p);
      Inc(p);
      p.Method(stack, p);
      Inc(p);
      Dec(n, 4);
   end;
   while n > 0 do begin
      p.Method(stack, p);
      Inc(p);
      Dec(n);
   end;
   Result := stack.Peek;
end;

// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------
initialization
// ------------------------------------------------------------------
// ------------------------------------------------------------------
// ------------------------------------------------------------------

   vDotFormatSettings := FormatSettings;
   vDotFormatSettings.DecimalSeparator := '.';

end.
