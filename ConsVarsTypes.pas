{****************************************************************
  $Id: ConsVarsTypes.pas,v 1.1 2006-03-07 05:35:48 dale Exp $
****************************************************************}
unit ConsVarsTypes;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SynEdit, SynEditTypes, SynEditKeyCmds, SynHighlighterSQL,
  Ora;

type
   // Exception
  EPackageEditorError = class(Exception);

   // ��������� ����������� � ��
  TDBConnectParams = record
    bNetDirect: Boolean;
    sService:   String;
    sServer:    String;
    sPort:      String;
    sSID:       String;
    sUserName:  String;
    sPassword:  String;
  end;

   // ��� ������� ��������� ����
  TCodeObjType = (coNone, coFunction, coPackage, coProcedure);

   //-------------------------------------------------------------------------------------------------------------------
   // ������ ������� ������� �������
   //-------------------------------------------------------------------------------------------------------------------

   // ��� ������ � ������� �������
  TStatusKind  = (skUnknown, skOK, skError);

   // ������ ������� �������
  PStatusEntry = ^TStatusEntry;
  TStatusEntry = record
    SKind: TStatusKind; // ��� ������
    iLine: Integer;     // ����� ������ � ����, � ������� ��������� ������
    iCol:  Integer;     // ����� ������� � ����, � ������� ��������� ������
    sPart: String;      // ����� ����, � ������� ��������� ������ ('FUNCTION', 'PACKAGE BODY', ...)
    sText: String;      // ����� ������
  end;

  TStatusList = class(TList)
  private
     // Prop handlers
    function GetItems(Index: Integer): PStatusEntry;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    function  Add(SKind: TStatusKind; iLine, iCol: Integer; const sPart, sText: String): Integer;
     // Props
    property Items[Index: Integer]: PStatusEntry read GetItems; default;
  end;

   //-------------------------------------------------------------------------------------------------------------------
   // ������ �������� ��� ���������
   //-------------------------------------------------------------------------------------------------------------------

   // ��� �������, �� �������� �������������� ���������
  TNavObjType = (notNone, notProcedure, notFunction);

   // ������ ������ ���� tvNav
  PNavRecord = ^TNavRecord;
  TNavRecord = record
    NavObjType: TNavObjType; // ��� �������
    sName:      String;      // ������������ �������
    sArgs:      String;      // ��������� �������
    iRowMain:   Integer;     // ����� ������ � ����������/�������� � �������� ������ (������������ ������)
    iRowBody:   Integer;     // ����� ������ � ����������/�������� � ���� ������
    iOrd:       Integer;     // ���������� ����� ��� overloaded-�������� (0..n)
  end;

  TNavList = class(TList)
  private
     // ���������� ������ � �������� idx � ������� sName, NavObjType
    function CompareObj(idx: Integer; const sName: String; NavObjType: TNavObjType): Integer;
     // Prop handlers
    function GetItems(Index: Integer): PNavRecord;
  protected
    procedure Notify(Ptr: Pointer; Action: TListNotification); override;
  public
    function  Add(_NavObjType: TNavObjType; const _sName, _sArgs: String; _iRowMain, _iRowBody: Integer): Integer;
     // ������� ����� ��� ������� �������� � ���������� ��� ������ � Index, � ���������� ����� � iOrd
    procedure FindInsIndex(NavObjType: TNavObjType; const sName: String; var Index, iOrd: Integer);
     // ���������� ������ ��������� �������, ��� -1, ���� ��� ������. ���� iOrd=-1, �� ���� ������ ������ � ���������
     //   ����� � ������, � �������� iRowBody=0
    function  IndexOf(NavObjType: TNavObjType; const sName: String; iOrd: Integer): Integer;
     // Props
    property Items[Index: Integer]: PNavRecord read GetItems; default;
  end;

   //-------------------------------------------------------------------------------------------------------------------
   // ��������� �������-������������ ������ ���������
   //-------------------------------------------------------------------------------------------------------------------

  ISourceEditorNavigation = interface(IInterface)
     // ������ ��������� sMainSource � sBodySource ������� ��������� ������ � ���� ������ ��������������
    procedure GetSource(var sMainSource, sBodySource: String);
     // ������ ��������� ���� ��������� ������� ������ NavList
    procedure SetResultList(NavList: TNavList);
  end;

   //-------------------------------------------------------------------------------------------------------------------
   // ����� ������������ ��������� ������
   //-------------------------------------------------------------------------------------------------------------------

  TSourceScanThread = class(TThread)
  private
     // ��������� �������, ���������������� ��������� � ������������� ���������
    FEditorNavIntf: ISourceEditorNavigation;
     // �����, ��������� ������� ����� �������������, ����� ��������� ����������
    FWaitTime: Cardinal;
     // Syntax highlighter ��� �������� ����������
    FSynSQL: TSynSQLSyn;
     // ��������� ������ ����������� ��������
    FNavList: TNavList;
     // ������� ��������� ����������
    FHScanEvent: THandle;
     // ����������� ������: �������� � ���� ������
    FSrcMain: String;
    FSrcBody: String;
     // True, ���� ��������� ���� ��������������
    FSourceChanged: Boolean;
     // ��������� FSrcMain � FSrcBody ��������, ����������� ����� FEditorNavIntf
    procedure GetSource;
     // ������� �������������� ������ FNavList � FEditorNavIntf
    procedure SetResults;
  protected
    procedure Execute; override;
  public
    constructor Create(EditorNavIntf: ISourceEditorNavigation);
    destructor Destroy; override;
     // ���������� �����, ��� ��������� ����������
    procedure SetModified(cWaitTime: Cardinal);
     // ��������� ������� ��� ������ �����������
    procedure Shutdown;
  end;

   //-------------------------------------------------------------------------------------------------------------------
   // ��������� �������-������������ ������� ����������
   //-------------------------------------------------------------------------------------------------------------------

  ICompileSource = interface(IInterface)
     // ������ ���������� Session ��� �������
    function  GetSession: TOraSession;
     // ������ ��������� sMainSource � sBodySource ������� ��������� ������ � ���� ������ ��������������, �
     //   sObjTypeMain � sObjTypeBody - Oracle-�������������� ����� �� �������� 
    procedure GetSource(var sMainSource, sBodySource, sObjTypeMain, sObjTypeBody: String);
     // ������ ��������� ������ �������
    procedure AddResultEntry(SKind: TStatusKind; iLine, iCol: Integer; const sPart, sText: String);
     // ������ ������������� ��������� "���������� ���������"
    procedure Complete(bSuccess: Boolean);
  end;

   //-------------------------------------------------------------------------------------------------------------------
   // ����� �������������� SQL-������
   //-------------------------------------------------------------------------------------------------------------------

  TCompileThread = class(TThread)
  private
     // ��������� �������, ������������ ����������
    FCompileSrcIntf: ICompileSource;
     // ������� ��������� ���������� � ������������� ������ ����������
    FHCompileEvent: THandle;
     // ������������� ������: �������� � ���� ������
    FSrcMain: String;
    FSrcBody: String;
     // ���� ��������: �������� � ���� ������
    FObjTypeMain: String;
    FObjTypeBody: String;
     // ������, ������������ ��� ����������
    FQuery: TOraQuery;
     // True ��� �������� ���������� ����������
    FSuccess: Boolean;
     // ���� ��� ����������� ������ �������
    FErrObjType: String;
    FErrMessage: String;
     // ��������� ������ ����������
    procedure AddResultEntry;
     // ���������� � ���������� ��������
    procedure Complete;
  protected
    procedure Execute; override;
  public
    constructor Create(CompileSrcIntf: ICompileSource);
    destructor Destroy; override;
     // ��������� FSrcMain, FSrcBody, FObjTypeMain, FObjTypeBody ��������, ����������� ����� FCompileSrcIntf � ��������� ����������
    procedure StartCompiling;
     // ��������� ������� ��� ������ �����������
    procedure Shutdown;
  end;

const

  SApp_Name                    = 'PackageEditor';
  SApp_Version                 = '3.01RC2';
  SApp_FullName                = SApp_Name+' '+SApp_Version;

   // ���� � �������
  SRegBaseKey                  = 'Software\DaleTech\PackageEditor';
  SRegToolbarsKey              = SRegBaseKey+'\Toolbars';
  SRegMainWindow               = 'MainWindow';
  SRegPreferences              = 'Preferences';
  SRegLogin                    = SRegPreferences+'\Login';
  SRegEditor                   = SRegPreferences+'\Editor';
  SRegHighlight                = SRegPreferences+'\Highlight';
  SRegKeyBindings              = SRegPreferences+'\KeyBindings';
  SRegOpenMRU                  = 'OpenMRU';
  SRegOpenFiles                = 'OpenFiles';

   // Image indices
  iiOK                         =  0;
  iiError                      =  1;
  iiFunction                   =  2;
  iiPackage                    =  3;
  iiProcedure                  =  4;
  iiWait                       =  5;
  iiUser                       =  6;
  iiUnknown                    =  7;
  //iiPublic                   =  8;
  iiNew                        =  9;
  iiOpen                       = 10;
  iiSave                       = 11;
  iiSaveAs                     = 12;
  iiClose                      = 13;
  iiDrop                       = 14;
  iiCut                        = 15;
  iiCopy                       = 16;
  iiPaste                      = 17;
  iiUndo                       = 18;
  iiRedo                       = 19;
  iiConnect                    = 20;
  iiDisconnect                 = 21;
  iiRetrieveObject             = 22;
  iiExit                       = 23;
  iiFind                       = 24;
  iiReplace                    = 25;
  iiSearchAgain                = 26;
  iiCompile                    = 27;
  iiSettings                   = 28;
  iiInfo                       = 29;
  iiHelp                       = 30;
  iiRefresh                    = 31;
  iiMacroRecStop               = 32;
  iiMacroPause                 = 33;
  iiMacroPlay                  = 34;

  aiiNavObjTypes: Array[TNavObjType] of Integer = (iiWait, iiProcedure, iiFunction);

  aCOT: Array[TCodeObjType] of record
    sName: String[9];
    pcTemplate: PChar;
    ii: Integer;
  end = (
    (sName: 'unknown';   pcTemplate: nil;                                                          ii: -1),
    (sName: 'FUNCTION';  pcTemplate: 'FUNCTION %(...) RETURN ... IS'#13'BEGIN'#13'  ...'#13'END;'; ii: iiFunction),
    (sName: 'PACKAGE';   pcTemplate: 'PACKAGE % IS'#13'  ...'#13'END;';                            ii: iiPackage),
    (sName: 'PROCEDURE'; pcTemplate: 'PROCEDURE %() IS'#13'BEGIN'#13'  ...'#13'END;';              ii: iiProcedure));

  WM_UPDATECAPTION             = WM_USER+10;
  WM_ENABLEACTIONS             = WM_USER+11;
  WM_UPDATETABNAMES            = WM_USER+12;
  WM_UPDATESTATUSLIST          = WM_USER+13;

   // �����
  CNavList_FontScanning        = clGrayText; // ���� ������ ������� 'Scanning source...' � ������ ���������
  CNavList_FontStatic          = clSilver;   // ���� ������ ������������ ������ � ������ ��������� (������ �����)
  CNavList_FontErroneous       = $0000a0;    // ���� ������ ��������� ���������/������� � ������ ��������� (��� ����������)
  CNavList_BackErroneous       = $e5e5ff;    // ���� ���� ��������� ���������/������� � ������ ���������
  CNavList_FontPrivateProc     = $a0c0a0;    // ���� ������ ��������� ��������� � ������ ��������� (������������� � ��������� ������)
  CNavList_FontPrivateFunc     = $c0a0a0;    // ���� ������ ��������� ������� � ������ ��������� (������������� � ��������� ������)
  CNavList_FontPublicProc      = $007000;    // ���� ������ ���������� ��������� � ������ ���������
  CNavList_FontPublicFunc      = $700000;    // ���� ������ ���������� ������� � ������ ���������

  CResultList_FontUnknown      = clGrayText; // ���� ������ ��������� ���������� � ������������� ������� �������
  CResultList_FontOK           = clGreen;    // ���� ������ ��������� ���������� � ���������� ��������� �������
  CResultList_FontError        = $0000a0;    // ���� ������ ��������� ���������� �� ��������� ��������� �������
  CResultList_FontWorking      = $006090;    // ���� ������ ��������� � �������������� �������
  CResultList_BackWorking      = $e0e0e0;    // ���� ���� ���� ����������� ��� �������������� �������

resourcestring
   // Dialog texts
  SDlgTitle_Info               = 'Info';
  SDlgTitle_Error              = 'Error';
  SDlgTitle_Confirm            = 'Confirm';
  SDlgTitle_OpenFile           = 'Open object script';
  SDlgTitle_SaveFileAs         = 'Save object script as';

  SMsg_ConnectingToServer      = 'Connecting to %s...';
  SMsg_MemoryStatus            = 'Memory load: %d%%';
  SMsg_Done                    = 'Done';
  SMsg_SearchStringNotFound    = 'Search string "%s" not found';
  SMsg_ReplaceSummary          = 'Replaced %d occurences of "%s"';
  SMsg_ScanningSource          = 'Scanning source...';
  SMsg_LoadingFile             = 'Loading file: %s...';
  SMsg_StatusUnknown           = 'Status is unknown. Click here to load current object status.';
  SMsg_StatusDroppedOK         = '%s dropped OK';
  SMsg_StatusCannotDrop        = 'Cannot drop object %s: %s';
  SMsg_StatusDoesntExist       = '%s "%s" does not exist';
  SMsg_StatusOK                = '%s is compiled OK';
  SMsg_StatusNoStatusFound     = 'No status records found for %s "%s"';
  SMsg_NoConnection            = 'not connected';
  SMsg_LineColIndicator        = 'Line: %d / Col: %d ';
  SMsgConfirm_DropObject       = 'Do you wish to drop "%s"?';
  SMsgConfirm_ReloadFile       = 'Date/time of file "%s" has changed. Do you wish to reload it?';
  SMsgConfirm_FileNotSaved     = '%s "%s" was modified.'#13'Do you want to save changes?';

  SMsgError_CannotAccessRegKey = 'Error accessing registry key: %s';

  SWebUrl                      = 'http://devtools.narod.ru';
  
  SDefaultFileExt              = 'sql';
  SDefaultFileFilter           = 'SQL script files (*.sql)|*.sql|Text files (*.txt)|*.txt|All files (*.*)|*.*';

var
  DefConParams:      TDBConnectParams;   // ��������� ����������� �� ���������
  ActiveConParams:   TDBConnectParams;   // ������� ��������� �����������
  sEdFontName:       String;             // ��� ������ ���������
  sHistTxSrch:       String;             // ����� ������� ��������� �����
  sHistTxRepl:       String;             // ����� ������� ����� ������
  iEdFontSize:       Integer;            // ������ ������ ���������
  iMaxUndo:          Integer;            // ���������� ������ � ������ ������
  iRightEdge:        Integer;            // ��������� ������ �������, ��������
  iTabWidth:         Integer;            // ������ ��������� �� ���������
  SynEditOpts:       TSynEditorOptions;  // ����� ���������
  bAutoLogin:        Boolean;            // True, ���� ������������ � ������� ��� ������ ����������
  bUpperKwds:        Boolean;            // True, ���� �������� ����� ������������� � ������� ��������
  bAutoSave:         Boolean;            // True, ���� ��������� ����� ������� ������������� ����� �����������
  bShowGutter:       Boolean;            // True, ���� ���������� ����� ������ � ��������� ���� 
  bLineNums:         Boolean;            // True, ���� ���������� ������ ����� �� ������      
  bWantTabs:         Boolean;            // True, ���� ��������� ������� ��������� � ���������
  bRestoreDesktop:   Boolean;            // True, ���� ��������������� ��������� ����������������� ����� ��� �������
  bAutoloadStatus:   Boolean;            // True, ���� ������������� ��������� ������ ��� ����������� ��� ������ ������
  bShowNavHints:     Boolean;            // True, ���� ���������� ��������� ���������/������� �� ����������� ���������� ����������
  SynEditKeyStrokes: TSynEditKeyStrokes; // ��������� ������
   // ������� ��������� ������
  sTxSearch:         String;             // ������ ������
  sTxReplace:        String;             // ������ ������
  TxSrchOptions:     TSynSearchOptions;  // ����� ������
  bRegexSearch:      Boolean;            // True, ���� ������� ����� �� ���������� ����������

   // Exceptions
  procedure PackageEditorError(const sMsg: String); overload;
  procedure PackageEditorError(const sMsg: String; const aParams: Array of const); overload;

   // ��������� ��� ��������� �������, ������������ ��� � clWindow ��� clBtnFace ��������������
  procedure EnableWndCtl(Ctl: TWinControl; bEnable: Boolean);
   // �������-�������������
  function iif(b: Boolean; const sTrue, sFalse: String): String; overload;
  function iif(b: Boolean; iTrue, iFalse: Integer): Integer;     overload;
  function iif(b: Boolean; pTrue, pFalse: Pointer): Pointer;     overload;
   // ���������� �����������/������������ �������� �� �������
  function Min(const aVals: Array of Integer): Integer;
  function Max(const aVals: Array of Integer): Integer;
   // ����������� �������
  procedure Info(const sMessage: String);
  procedure Error(const sMessage: String);
  function  Confirm(const sMessage: String): Boolean;
   // ���������� ��� ������� �� ��� �����
  function ObjTypeByName(const sType: String): TCodeObjType;
   // ������������ ������� ��������� ����� � ������ �������� ������
  function ConvertKwd(const sKwd: String): String;
   // �����������/�������������� ������
  function Encrypt(const s: String): String;
  function Decrypt(const s: String): String;

implementation
uses TypInfo, Forms, OraError;

  procedure PackageEditorError(const sMsg: String);
  begin
    raise EPackageEditorError.Create(sMsg);
  end;

  procedure PackageEditorError(const sMsg: String; const aParams: Array of const); overload;
  begin
    raise EPackageEditorError.CreateFmt(sMsg, aParams);
  end;

  procedure EnableWndCtl(Ctl: TWinControl; bEnable: Boolean);
  var pi: PPropInfo;
  begin
    Ctl.Enabled := bEnable;
    pi := GetPropInfo(Ctl, 'Color', [tkInteger]);
    if pi<>nil then SetOrdProp(Ctl, pi, iif(bEnable, clWindow, clBtnFace));
  end;

  function iif(b: Boolean; const sTrue, sFalse: String): String;
  begin
    if b then Result := sTrue else Result := sFalse;
  end;

  function iif(b: Boolean; iTrue, iFalse: Integer): Integer;
  begin
    if b then Result := iTrue else Result := iFalse;
  end;

  function iif(b: Boolean; pTrue, pFalse: Pointer): Pointer;
  begin
    if b then Result := pTrue else Result := pFalse;
  end;

  function Min(const aVals: Array of Integer): Integer;
  var i: Integer;
  begin
    Result := 2147483647;
    for i := 0 to High(aVals) do
      if aVals[i]<Result then Result := aVals[i];
  end;

  function Max(const aVals: Array of Integer): Integer;
  var i: Integer;
  begin
    Cardinal(Result) := $80000000;
    for i := 0 to High(aVals) do
      if aVals[i]>Result then Result := aVals[i];
  end;

  procedure Info(const sMessage: String);
  begin
    Application.MessageBox(PChar(sMessage), PChar(SDlgTitle_Info), MB_OK or MB_ICONINFORMATION);
  end;

  procedure Error(const sMessage: String);
  begin
    Application.MessageBox(PChar(sMessage), PChar(SDlgTitle_Error), MB_OK or MB_ICONERROR);
  end;

  function Confirm(const sMessage: String): Boolean;
  begin
    Result := Application.MessageBox(PChar(sMessage), PChar(SDlgTitle_Confirm), MB_OKCANCEL or MB_ICONQUESTION)=IDOK;
  end;

  function ObjTypeByName(const sType: String): TCodeObjType;
  begin
    for Result := Succ(coNone) to High(Result) do
      if AnsiCompareText(aCOT[Result].sName, sType)=0 then Exit;
    Result := coNone;
  end;

  function ConvertKwd(const sKwd: String): String;
  begin
    if bUpperKwds then Result := sKwd else Result := AnsiLowerCase(sKwd);
  end;

  function Encrypt(const s: String): String;
  var
    sh: Byte;
    i, l, Key: Integer;
  begin
    Key := Random(MaxInt);
    l := Length(s);
    Result := Format('%.3x%.8x%.3x%.8x%.8x', [Random($FFF), $FE8534CC-Cardinal(Key), Random($FFF), Random(MaxInt), (MaxInt-l) xor Key]);
    sh := 0;
    for i := 1 to l do begin
      Result := Result+Format('%.2x%.4x', [Byte((Key shr sh) and $FF) xor Byte(s[i]), Random($FFFF)]);
      sh := (sh+1) mod 8;
    end;
    for i := 1 to Random(20) do Result := Result+Format('%.7x', [Random($FFFFFFF)]);
  end;

  function Decrypt(const s: String): String;
  var
    sh: Byte;
    i, l, Key: Integer;
  begin
    Key := Integer($FE8534CC-Cardinal(StrToIntDef('$'+Copy(s, 4, 8), 0)));
    l := (MaxInt-StrToIntDef('$'+Copy(s, 23, 8), 0)) xor Key;
    sh := 0;
    Result := '';
    for i := 1 to l do begin
      Result := Result+Char(StrToIntDef('$'+Copy(s, 25+i*6, 2), 0) xor Byte((Key shr sh) and $FF));
      sh := (sh+1) mod 8;
    end;
  end;
  
   //===================================================================================================================
   // TStatusList
   //===================================================================================================================

  function TStatusList.Add(SKind: TStatusKind; iLine, iCol: Integer; const sPart, sText: String): Integer;
  var p: PStatusEntry;
  begin
    New(p);
    Result := inherited Add(p);
    p.SKind := SKind;
    p.iLine := iLine;
    p.iCol  := iCol;
    p.sPart := sPart;
    p.sText := sText;
  end;

  function TStatusList.GetItems(Index: Integer): PStatusEntry;
  begin
    Result := PStatusEntry(Get(Index));
  end;

  procedure TStatusList.Notify(Ptr: Pointer; Action: TListNotification);
  begin
    if Action=lnDeleted then Dispose(PStatusEntry(Ptr));
  end;

   //===================================================================================================================
   // TNavList
   //===================================================================================================================

  function TNavList.Add(_NavObjType: TNavObjType; const _sName, _sArgs: String; _iRowMain, _iRowBody: Integer): Integer;
  var
    p: PNavRecord;
    iNewOrd: Integer;
  begin
     // ���� ����� �������
    FindInsIndex(_NavObjType, _sName, Result, iNewOrd);
     // ������ �������
    New(p);
    Insert(Result, p);
    with p^ do begin
      NavObjType := _NavObjType;
      sName      := _sName;
      sArgs      := _sArgs;
      iRowMain   := _iRowMain;
      iRowBody   := _iRowBody;
      iOrd       := iNewOrd; 
    end;
  end;

  function TNavList.CompareObj(idx: Integer; const sName: String; NavObjType: TNavObjType): Integer;
  var pNavRec: PNavRecord;
  begin
    pNavRec := GetItems(idx);
     // ���������� �����
    Result := AnsiCompareText(pNavRec^.sName, sName);
     // ���� ����� ���������, ���������� ���: ������� ���� ���������, ����� �������
    if Result=0 then Result := ShortInt(pNavRec^.NavObjType)-ShortInt(NavObjType);
  end;

  procedure TNavList.FindInsIndex(NavObjType: TNavObjType; const sName: String; var Index, iOrd: Integer);
  var idxLow, idxHigh, idx: Integer;
  begin
    idxLow  := 0;
    idxHigh := Count-1;
    iOrd := 0;
    while idxLow<=idxHigh do begin
       // ���� ������� � ������� ������� ����� ��������� � �������� ���������
      idx := (idxLow+idxHigh) shr 1;
      case CompareObj(idx, sName, NavObjType) of
         // �������� ������� ������ �������: ������ ����� ������� ����� ��������� ��������
        Low(Integer)..-1: idxLow := idx+1;
         // �������� ������� ������ �������: ������ ������ ������� ����� �������� ���������
        1..High(Integer): idxHigh := idx-1;
         // ����� ���������� - ���������� ��������, ���� �� ����� ��������� ���������� �����
        else {0} begin
          repeat
            iOrd := GetItems(idx)^.iOrd+1;
            Inc(idx);
          until (idx>idxHigh) or (GetItems(idx)^.iOrd=0);
          idxLow := idx;
          Break;
        end;
      end;
    end;
    Index := idxLow;
  end;

  function TNavList.GetItems(Index: Integer): PNavRecord;
  begin
    Result := PNavRecord(Get(Index));
  end;

  function TNavList.IndexOf(NavObjType: TNavObjType; const sName: String; iOrd: Integer): Integer;
  var
    idxLow, idxHigh, idx: Integer;
    p: PNavRecord;
  begin
    Result := -1;
    idxLow  := 0;
    idxHigh := Count-1;
    while idxLow<=idxHigh do begin
      idx := (idxLow+idxHigh) shr 1;
      case CompareObj(idx, sName, NavObjType) of
        Low(Integer)..-1: idxLow := idx+1;
        1..High(Integer): idxHigh := idx-1;
        else {0} begin
           // ���������� ��������, ��� ���������� �����. �������� � �������� � iOrd=0
          Dec(idx, GetItems(idx)^.iOrd);
          repeat
            p := GetItems(idx);
            if ((iOrd<0) and (p.iRowBody=0)) or ((iOrd>=0) and (p.iOrd=iOrd)) then begin
              Result := idx;
              Break;
            end;
            Inc(idx);
          until (idx>idxHigh) or (GetItems(idx)^.iOrd=0);
          Break;
        end;
      end;
    end;
  end;

  procedure TNavList.Notify(Ptr: Pointer; Action: TListNotification);
  begin
    if Action=lnDeleted then Dispose(PNavRecord(Ptr));
  end;

   //===================================================================================================================
   // TSourceScanThread
   //===================================================================================================================

  constructor TSourceScanThread.Create(EditorNavIntf: ISourceEditorNavigation);
  begin
    inherited Create(True);
    FreeOnTerminate := True;
    FEditorNavIntf := EditorNavIntf;
     // ������ Highlighter ��� ��������
    FSynSQL := TSynSQLSyn.Create(nil);
    FSynSQL.SQLDialect := sqlOracle;
     // ������ ��������� ������ �������� ���������
    FNavList := TNavList.Create;
     // ������ ������� ������ ������������
    FHScanEvent := CreateEvent(nil, False, False, nil);
    Assert(FHScanEvent<>0, 'Failed to create Scan Event');
    Resume;
  end;

  destructor TSourceScanThread.Destroy;
  begin
    FSynSQL.Free;
    FNavList.Free;
    CloseHandle(FHScanEvent);
    inherited Destroy;
  end;

  procedure TSourceScanThread.Execute;

     // ��������� �������� ����. ���� bSecond=False - ��� ������ ������, ����� - ������
    procedure ScanSrc(const sSrc: String; bSecond: Boolean);
    const FuncNameTypes: Set of TtkTokenKind = [
      SynHighlighterSQL.tkDatatype, SynHighlighterSQL.tkDefaultPackage, SynHighlighterSQL.tkException,
      SynHighlighterSQL.tkFunction, SynHighlighterSQL.tkIdentifier, SynHighlighterSQL.tkKey, SynHighlighterSQL.tkPLSQL,
      SynHighlighterSQL.tkSQLPlus, SynHighlighterSQL.tkTableName, SynHighlighterSQL.tkUnknown,
      SynHighlighterSQL.tkVariable];
    var
      iLine, iScanPos, idx, iSrcLength: Integer;
      s: String;
      NOType: TNavObjType;

      procedure ScanLineNums(iCurPos: Integer);
      var i: Integer;
      begin
        for i := iScanPos to iCurPos do
          if sSrc[i]=#13 then Inc(iLine);
        iScanPos := iCurPos+1;
      end;

       // �������� ���������� ��������� ���������/������� � ���������� ��
      function GetArgs: String;
      var iBegPos, iEndPos: Integer;
      begin
        iBegPos := FSynSQL.GetTokenPos+Length(FSynSQL.GetToken)+1;
        Result := '';
         // ���� ������ ������������ ������
        while (iBegPos<=iSrcLength) and (Byte(sSrc[iBegPos])<=32) do Inc(iBegPos);
        if (iBegPos<iSrcLength) and (sSrc[iBegPos]='(') then begin
          iEndPos := iBegPos+1;
           // ���� ������ ')' ��� ';'
          while (iEndPos<=iSrcLength) and not (sSrc[iEndPos] in [';', ')']) do Inc(iEndPos);
          if (iEndPos<=iSrcLength) and (sSrc[iEndPos]=')') then Result := Copy(sSrc, iBegPos+1, iEndPos-iBegPos-1);
        end;
      end;

    begin
      iSrcLength := Length(sSrc);
      FSynSQL.SetLine(sSrc, 1);
      iLine := 1;
      iScanPos := 1;
      while not Terminated and not FSourceChanged and not FSynSQL.GetEOL do begin
         // �������� �������� ����� PL/SQL
        if FSynSQL.GetTokenKind=Ord(tkPLSQL) then begin
           // ��������� ��� ��������� �����
          s := Trim(AnsiUpperCase(FSynSQL.GetToken));
          if s='PROCEDURE'     then NOType := notProcedure
          else if s='FUNCTION' then NOType := notFunction
          else                      NOType := notNone;
           // ���� ��� ������ ��� �������������� ������
          if NOType<>notNone then begin
            ScanLineNums(FSynSQL.GetTokenPos);
             // ��������� �� ����� ������ ��� �� ������� ��������������
            FSynSQL.Next; // ���������� 'function' / 'procedure'
            while not FSynSQL.GetEol and not (TtkTokenKind(FSynSQL.GetTokenKind) in FuncNameTypes) do FSynSQL.Next;
            if TtkTokenKind(FSynSQL.GetTokenKind) in FuncNameTypes then begin
               // ��� ���������/�������
              s := FSynSQL.GetToken;
               // ���� �������� ����� - ��������� ������ � ������
              if not bSecond then
                FNavList.Add(NOType, s, GetArgs, iLine, 0)
               // ����� (���� ������) - ���� ������ ������, ����������� ��� ����� ������ � ����, ����� ���������
              else begin
                idx := FNavList.IndexOf(NOType, s, -1);
                if idx>=0 then FNavList[idx].iRowBody := iLine else FNavList.Add(NOType, s, GetArgs, 0, iLine);
              end;
            end;
            Sleep(0);
          end;
        end;
        FSynSQL.Next;
      end;
    end;

  begin
     // ������ ����, ���� ����� ���
    while not Terminated do begin
       // ��� ����� ����������
      WaitForSingleObject(FHScanEvent, INFINITE);
      repeat
        if Terminated then Break;
         // ���������� ������� � ��� �������� �����
        ResetEvent(FHScanEvent);
        Sleep(FWaitTime);
        FNavList.Clear;
         // �������� ���������
        if not Terminated then Synchronize(GetSource);
         // ��������� �������� �����
        if not Terminated then ScanSrc(FSrcMain, False);
         // ��������� ���� ������
        if not Terminated then ScanSrc(FSrcBody, True);
      until not FSourceChanged or Terminated;
       // ������� ��, ���� �������������
      if not Terminated then Synchronize(SetResults);
    end;
  end;

  procedure TSourceScanThread.GetSource;
  begin
    FEditorNavIntf.GetSource(FSrcMain, FSrcBody);
    FSourceChanged := False;
  end;

  procedure TSourceScanThread.SetModified(cWaitTime: Cardinal);
  begin
    FWaitTime := cWaitTime;
    FSourceChanged := True;
    if FHScanEvent<>0 then SetEvent(FHScanEvent);
  end;

  procedure TSourceScanThread.SetResults;
  begin
    FEditorNavIntf.SetResultList(FNavList);
  end;

  procedure TSourceScanThread.Shutdown;
  begin
    Terminate;
    SetEvent(FHScanEvent);
  end;

   //===================================================================================================================
   // TCompileThread 
   //===================================================================================================================

  procedure TCompileThread.AddResultEntry;
  begin
    FCompileSrcIntf.AddResultEntry(skError, 0, 0, FErrObjType, FErrMessage);
  end;

  procedure TCompileThread.Complete;
  begin
    FCompileSrcIntf.Complete(FSuccess);
  end;

  constructor TCompileThread.Create(CompileSrcIntf: ICompileSource);
  begin
    inherited Create(True);
    FreeOnTerminate := True;
    FCompileSrcIntf := CompileSrcIntf;
    FHCompileEvent := CreateEvent(nil, False, False, nil);
    Assert(FHCompileEvent<>0, 'Failed to create Compile Event');
    FQuery := TOraQuery.Create(nil);
    FQuery.Session := FCompileSrcIntf.GetSession;
    Resume;
  end;

  destructor TCompileThread.Destroy;
  begin
    FQuery.Free;
    CloseHandle(FHCompileEvent);
    inherited Destroy;
  end;

  procedure TCompileThread.Execute;

    function ExecText(const sObjType, sSQLText: String): Boolean;
    begin
      Result := False;
      FQuery.SQL.Text := sSQLText;
      try
        FQuery.ExecSQL;
        Result := True;
      except
        on e: EOraError do
          if (e.ErrorCode=0) or (e.ErrorCode=24344 {Success with compilation error}) then
            Result := True
          else begin
            Synchronize(AddResultEntry);
            FErrObjType := sObjType;
            FErrMessage := e.Message;
          end;
      end;
       // Release memory
      FQuery.SQL.Clear;
    end;

  begin
    while not Terminated do begin
      FSuccess := False;
      WaitForSingleObject(FHCompileEvent, INFINITE);
      if Terminated then Break;
      FSuccess := ExecText(FObjTypeMain, FSrcMain);
      if Terminated then Break;
      if FSuccess and (FSrcBody<>'') then FSuccess := ExecText(FObjTypeBody, FSrcBody);
      Synchronize(Complete);
    end;
  end;

  procedure TCompileThread.Shutdown;
  begin
    Terminate;
    SetEvent(FHCompileEvent);
  end;

  procedure TCompileThread.StartCompiling;
  begin
    FCompileSrcIntf.GetSource(FSrcMain, FSrcBody, FObjTypeMain, FObjTypeBody);
    SetEvent(FHCompileEvent);
  end;

end.
