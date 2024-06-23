program Assembler_IDE;

{$M 32767,0,111111}
{$X+,S-}

USES
    Dos, Objects, Drivers, Memory, Views, Menus, Dialogs,
    StdDlg, MsgBox, App, Calc, Editors, Crt, NewBack, Options;

CONST
     MaxCompileLines = 50;
CONST
     HeapSize = 16 * (1024 div 16);
CONST
     cmCalculator = 101;
     cmShowClip   = 102;
     cmRun        = 103;
     cmCompile    = 104;
     cmInfo       = 105;
     cmComp       = 106;
     cmLink       = 107;
     cmCAdv       = 108;
     cmLAdv       = 109;
     cmParam      = 110;
     cmDirs       = 111;
     cmUScr       = 112;
	 
	 cmFind        = 82;
	 cmReplace     = 83;
	 cmSearchAgain = 84;
CONST
     hcFile       = 1001;
     hcEdit       = 1002;
     hcSearch     = 1003;
     hcFind       = 1004;
     hcReplace    = 1005;
     hcSAgain     = 1006;
     hcExec       = 1007;
     hcRun        = 1008;
     hcCompile    = 1009;
     hcParam      = 1010;
     hcUScr       = 1011;
TYPE
    PHintStatusLine = ^THintStatusLine;
    THintStatusLine = object(TStatusLine)
                    function Hint(AHelpCtx: Word): String; virtual;
                    procedure Draw;virtual;
                    end;
    PEdWin = ^ TEdWin;
    TEdWin = object(TEditWindow)
           WinTitle : string[3];
           procedure Close;virtual;
           end;

    PInterior = ^TInterior;
    TInterior = object(TScroller)
              constructor Init(var Bounds: TRect; AHScrollBar,AVScrollBar: PScrollBar);
              procedure Draw; virtual;
              end;

    PCompileWin = ^TCompileWin;
     TCompileWin = object(TWindow)
                WinTitle : string[3];
                constructor Init(Bounds: TRect; WTitle: String; WindowNo: Word);
                procedure MakeInterior(Bounds: TRect);
                end;

    PEditorApp = ^TEditorApp;
    TEditorApp = object(TApplication)
      constructor Init;
      procedure InitDesktop;virtual;
      function OpenEditor(FileName: FNameStr; Visible: Boolean): PEdWin;
      procedure HandleEvent(var Event: TEvent); virtual;
      procedure InitMenuBar; virtual;
      procedure InitStatusLine; virtual;
      procedure OutOfMemory; virtual;
      procedure SaveConfig;
      procedure LoadConfig;
    end;
TYPE
    VideoAttr = record
              Mode : byte;
              Columns : byte;
              ActivePage : byte;
              CursorX,CursorY : byte;
              StartLine,EndLine : byte;
              Info                : array[1..25,1..80] of word;
             end;
VAR
   EditorApp         : TEditorApp;
   ClipWindow        : PEdWin;
   P                 : PEdwin;
   EditFile          : integer;
   CompileLinesCount : integer;
   CompileLines      : array[0..MaxCompileLines-1] of String;
   BeforeTV,TV       : VideoAttr;
VAR
   {paths,params}
   LastCompiledFile : String;
   ParamList        : String;
   Path2MyFiles     : DirStr;
   Dirs4Include     : String;
   Path4ObjOutput   : String;
   Path4LstOutPut   : String;
   Path4XrfOutPut   : String;
   Path2ExeLink     : String;
   CompileResult    : boolean;
   DummyName        : NameStr;
   DummyExt         : ExtStr;

procedure GetVideoAttr(var VAttr : VideoAttr);
var
   r  : registers;
begin
 r.ah:=$0f;
 Intr($10,r);
 with VAttr do begin Mode:=r.al;Columns:=r.ah;ActivePage:=r.bh;end;
 r.ah:=$03;
 r.bh:=VAttr.ActivePage;
 Intr($10,r);
 with VAttr do begin CursorX:=r.dh;CursorY:=r.dl;StartLine:=r.ch;EndLine:=r.cl;end;
 if VAttr.Mode in [0,1,2,3,7] then Move(ptr($B800,0)^,Vattr.Info,4000);
end;

procedure SetVideoAttr(VAttr : VideoAttr;DoCopy : boolean);
var
   r  : registers;
begin
 r.ah:=$00;
 if VAttr.Mode in [0,1,2,3,7] then r.al:=VAttr.Mode
                              else r.al:=VAttr.Mode+$80;
 Intr($10,r);
 r.ah:=$05;
 r.al:=VAttr.ActivePage;
 Intr($10,r);
 r.ah:=$02;
 r.bh:=VAttr.ActivePage;
 r.dh:=VAttr.CursorX;
 r.dl:=VAttr.CursorY;
 Intr($10,r);
 r.ah:=$01;
 r.ch:=VAttr.StartLine;
 r.cl:=VAttr.EndLine;
 Intr($10,r);
 if (DoCopy) and (VAttr.Mode in [0,1,2,3,7]) then Move(VAttr.Info,ptr($B800,0)^,4000);
end;

function THintStatusLine.Hint(AHelpCtx: Word): String;
begin
  case AHelpCtx of
    hcFile     : Hint := 'File menu';
    hcNew   : Hint := 'Create a new file in a new edit window';
    hcOpen  : Hint := 'Locate and Open an existing file';
    hcExit  : Hint := 'Terminate the application';
    hcSave  : Hint := 'Save the file in the current window';
    hcSaveAs: Hint := 'Save the current file under a new name,directory or drive';
    hcSaveAll:Hint := 'Save all modified files';
    hcChangeDir:Hint := 'Choose a new default directory';
    hcDosShell : Hint := 'Temporarly exit to OS';
    hcEdit     : Hint := 'Cut-and-paste editing commands';
    hcUndo : Hint := 'Undo the previous editor operation';
    hcCut : Hint := 'Remove the selected text and put it into Clipboard';
    hcCopy : Hint := 'Copy the selected text into the ClipBoard';
    hcPaste : Hint := 'Copy the selected text from ClipBoard to cursor position';
    hcClear : Hint := 'Delete the selected text';
    hcTile     : Hint := 'Arrange windows on desktop by tiling';
    hcCascade  : Hint := 'Arrange windows on desktop by cascading';
    hcCloseAll : Hint := 'Close all windows on desktop';
    hcResize   : Hint := 'Change the size or position of active window';
    hcZoom     : Hint := 'Enlarge or restore the size of active window';
    hcNext     : Hint := 'Make the next window active';
    hcPrev     : Hint := 'Make the previous window active';
    hcClose    : Hint := 'Close the active window';
    hcSearch   : Hint := 'Text search commands';
    hcFind     : Hint := 'Look up for text';
    hcReplace  : Hint := 'Search for text the replace it with new one';
    hcSAgain   : Hint := 'Repeat the last find or replace command';
    hcExec     : Hint := 'Run & Compile commands';
    hcRun      : Hint := 'Run the current program';
    hcCompile  : Hint := 'Compile source file';
    hcParam    : Hint := 'Set command-line parameters to be passed to program';
    hcUScr     : Hint := 'See the results of your program';
    else Hint := '';
  end;
end;

procedure THintStatusLine.Draw;
var
   AuxItems1,AuxItems2 : PStatusItem;
begin
   if HelpCtx=hcnocontext
      then inherited Draw
      else begin
            AuxItems1:=Items;
            new(AuxItems2);
            if HelpCtx=hcDragging
               then with AuxItems2^ do
                         begin
                          Next:=Nil;
                          new(Text);
                          Text^:='~~ Move   ~Shift~+~~ Resize   ~<Ù~ Done   ~Esc~ Cancel';
                         end
               else with AuxItems2^ do
                         begin
                          Next:=Nil;
                          new(Text);
                          Text^:='~F1~ Help';
                         end;
            Items:=AuxItems2;
            inherited Draw;
            Items:=AuxItems1;
            dispose(AuxItems2^.Text);
            dispose(AuxItems2);
           end;
end;

procedure TEditorApp.InitDesktop;
var
  R: TRect;
begin
  GetExtent(R);
  R.Grow(0, -1);
  Desktop := New(PMyDesktop, Init(R));
end;

{ TInterior }
constructor TInterior.Init(var Bounds: TRect; AHScrollBar,
  AVScrollBar: PScrollBar);
begin
  TScroller.Init(Bounds, AHScrollBar, AVScrollBar);
  GrowMode := gfGrowHiX + gfGrowHiY;
  Options := Options or ofFramed;
  SetLimit(128, CompileLinesCount);
end;

procedure TInterior.Draw;
var
  Color: Byte;
  I, Y: Integer;
  B: TDrawBuffer;
begin
  Color := GetColor(1);
  for Y := 0 to Size.Y - 1 do
  begin
    MoveChar(B, ' ', Color, Size.X);
    i := Delta.Y + Y;
    if (I < CompileLinesCount) then
      {track the current option - with red background and yellow foreground}
      if Y=0 then begin
                   MoveChar(B, ' ', 78, Size.X);
                   MoveStr(B, Copy(CompileLines[I], Delta.X + 1,Size.X),78)
                  end
         else MoveStr(B, Copy(CompileLines[I], Delta.X + 1,Size.X), Color);
    WriteLine(0, Y, Size.X, 1, B);
  end;
end;

{ TCompileWin }
constructor TCompileWin.Init(Bounds: TRect; WTitle: String;
  WindowNo: Word);
var
  S: string[3];
begin
  Str(EditFile, S);
  TWindow.Init(Bounds, WTitle{ + ' ' + S}, wnNoNumber);
  Palette:=wpCyanWindow;
  MakeInterior(Bounds);
end;

procedure TCompileWin.MakeInterior(Bounds: TRect);
var
  HScrollBar, VScrollBar: PScrollBar;
  Interior: PInterior;
  R: TRect;
begin
  VScrollBar := StandardScrollBar(sbVertical + sbHandleKeyboard);
  HScrollBar := StandardScrollBar(sbHorizontal + sbHandleKeyboard);
  GetExtent(Bounds);
  Bounds.Grow(-1,-1);
  Interior := New(PInterior, Init(Bounds, HScrollBar, VScrollBar));
  Insert(Interior);
end;

procedure TEdWin.Close;
begin
  inherited Close;
  dec(EditFile);
  sound(2000);
  delay(35);
  nosound;
  if EditFile<=0
     then begin
           EditFile:=0;
           DisableCommands([cmRun,cmCompile]);
          end;
end;

function TEditorApp.OpenEditor(FileName: FNameStr; Visible: Boolean): PEdWin;
var
  R: TRect;
begin
  DeskTop^.GetExtent(R);
  r.a.y:=r.a.y+EditFile;
  P := New(PEdWin,
    Init(R, FileName, wnNoNumber));
  if not Visible then P^.Hide;
  P^.WinTitle:='EDT';
  DeskTop^.Insert(P);
  OpenEditor := PEdWin(Application^.InsertWindow(P));
end;

constructor TEditorApp.Init;
var
  H: Word;
  R: TRect;
begin
  EditFile:=0;
  
  {FPC/the dos cross-compiler doesn't recognize this}
  {MaxHeapSize := HeapSize;}
  
  inherited Init;
  DisableCommands([cmSave, cmSaveAs, cmCut, cmCopy, cmPaste, cmClear,
    cmUndo, cmFind, cmReplace, cmSearchAgain,cmRun,cmCompile]);
  EditorDialog := StdEditorDialog;
  ClipWindow := OpenEditor('', False);
  if ClipWindow <> nil then
  begin
    Clipboard := ClipWindow^.Editor;
    Clipboard^.CanUndo := False;
  end;
  with CBFlags do
       begin
        Tipe:=1;Others:=0;Debug:=0;Float:=0;
        Sense:=0;Order:=0;Code:=0;List:=0;
       end;
  with CSFlags do
       begin
        Tipe:='Tasmx';Others:='';Debug:='';Float:='';
        Sense:='';Order:='';Code:='';List:='';
       end;
  with LBFlags do
       begin
        All:=0;Map:=0;
       end;
  with LSFlags do
       begin
        All:='';Map:='';
       end;
  with CABFlags do
       begin
        Hash:='';Valid:='';Emu:='';Sym:='';
       end;
  with CASFlags do
       begin
        Hash:='';Valid:='';Emu:='';Sym:='';
       end;
  with ALBFlags do
       begin
        Pack:='';
        Newexe:='';
        Platform:=1;
        WhatExec:=1;
       end;
  with ALSFlags do
       begin
        Pack:='';
        Newexe:='';
        Platform:=' /Tde';
       end;
  with DirFlags do
       begin
        IncludeDir := '';
        ObjectDir  := '';
        ListingDir := '';
        XRefDir    := '';
        ExeDir     := '';
        MapDir     := '';
        ObjectFiles:= '';
        LibDir     := '';
        DefDir     := '';
       end;
  Dirs4Include     :='';
  Path4ObjOutput   :=',';
  Path4LstOutPut   :='';
  Path4XrfOutPut   :='';
  LastCompiledFIle :='';
end;

procedure TEditorApp.HandleEvent(var Event: TEvent);

var
   AuxStr : string;
   i      : integer;
   D      : DirStr;
   N      : NameStr;
   E      : ExtStr;

procedure FileOpen;
var
  FileName: FNameStr;
begin
  FileName := '*.ASM';
  if ExecuteDialog(New(PFileDialog, Init('*.ASM', 'Open file',
    '~N~ame', fdOpenButton+fdReplaceButton, 100)), @FileName) <> cmCancel then
    begin
     OpenEditor(FileName, True);
     EnableCommands([cmRun,cmCompile]);
     inc(EditFile);
    end;
end;

procedure FileNew;
begin
  OpenEditor('', True);
  EnableCommands([cmRun,cmCompile]);
  inc(EditFile);
end;

procedure ChangeDir;
begin
  ExecuteDialog(New(PChDirDialog, Init(cdNormal, 0)), nil);
end;

procedure ShowClip;
begin
  ClipWindow^.Select;
  ClipWindow^.Show;
end;

procedure Calculator;
begin
  InsertWindow(New(PCalculator, Init));
end;

procedure Compile;
var
    fname : string;
    dir:string;
    name,cmdline:string;
    i:integer;
    r:registers;
    outtemp:array[1..255] of char;
    temphandle,stdhandle:word;
    Re : Trect;
    Window : PCompileWin;
    ResultF : Text;
    SFromFile : char;
    MaxRead,CountRead : integer;
    SearchResult : PView;

function SearchTitle : PView;
 function AuxSearchTitle(P: PView): Boolean; far;
  begin
    if PCompileWin(P)^.WinTitle='Win'
       then AuxSearchTitle:=True
       else AuxSearchTitle:=False;
  end;

 begin
  SearchTitle := DeskTop^.FirstThat(@AuxSearchTitle);
 end;

begin
 CompileResult:=false;
 if desktop^.current<>nil
    then begin
          p:=PEdWin(Desktop^.Current);
          if p^.WinTitle='EDT'
             then begin
                   dir:=p^.gettitle(0);
                   name:='';
                   i:=length(dir);
                   while (dir[i]<>'\') and (i>0) do
                         begin
                          name:=dir[i]+name;
                          dec(i);
                         end;
                   if name='Untitled' then begin
                                            P^.Editor^.SaveAs;
                                            {get the title of the latest saved window}
                                            dir:=p^.gettitle(0);
                                            name:='';
                                            i:=length(dir);
                                            while (dir[i]<>'\') and (i>0) do
                                                  begin
                                                   name:=dir[i]+name;
                                                   dec(i);
                                                  end;
                                          end
                                      else P^.Editor^.SaveFile;
                   FSplit(dir,D,N,E);
                   name:=D+name;
                  end
             else exit;
         end
   else exit;

 cmdline:='';
 with CSFlags do cmdline := cmdline+' '+Float+' '+Debug+' '+Others+
                            List+' '+Code+' '+Order+' '+Sense;
 with CASFlags do cmdline := cmdline+' '+Hash+' '+Emu+' '+Valid+' '+
                             Sym;

 fname:=Path2MyFiles+'asmedit.ide';
 for i:=1 to length(fname)+1 do outtemp[i]:=#0;
 for i:=1 to length(fname) do outtemp[i]:=fname[i];

 {get file handle}
 r.ah:=$3c;
 r.ds:=seg(outtemp);
 r.dx:=ofs(outtemp);
 r.cx:=0;
 msdos(r);
 temphandle:=r.ax;

 {duplicate std out handle}
 r.ah:=$45;
 r.bx:=$1;
 msdos(r);
 stdhandle:=r.ax;

 {redirect standard output handle}
 r.ah:=$46;
 r.bx:=temphandle;
 r.cx:=1;
 msdos(r);

 {swapvectors;}
 exec(Path2MyFiles+'\tasm.exe',cmdline+' /m2 '+Dirs4Include+' '+name+Path4ObjOutPut+Path4LstOutPut+Path4XrfOutPut);
 {swapvectors;}

 {test this shit}

 {restore original std handle}
 r.ah:=$46;
 r.bx:=stdhandle;
 r.cx:=1;
 msdos(r);

 {must close file}
 r.ah:=$3e;
 r.bx:=temphandle;
 msdos(r);

 case doserror of
 2 : MessageBox('Could not find external compiler TASM.EXE.',
      nil, mfError + mfOkButton);
 3 : MessageBox('Path to TASM.EXE could not be found.',
      nil, mfError + mfOkButton);
 5 : MessageBox('Access denied to external compiler TASM.EXE.',
      nil, mfError + mfOkButton);
 6 : MessageBox('Invalid handler accesssing external compiler TASM.EXE.',
      nil, mfError + mfOkButton);
 8 : MessageBox('Not enough memory to run external compiler TASM.EXE.',
      nil, mfError + mfOkButton);
 10: MessageBox('Invalid environment.',
      nil, mfError + mfOkButton);
 11: MessageBox('Invalid format.',
      nil, mfError + mfOkButton);
 else begin
       LastCompiledFile:=dir;
       {read informations from result file}
       for i:=0 to MaxCompileLines-1 do CompileLines[i]:='';
       Assign(ResultF,Fname);
       Reset(ResultF);
       CompileLines[0]:='Using the external compiler...'+Name;
       CompileLinesCount:=1;
       repeat
        readln(ResultF,CompileLines[CompileLinesCount]);
        inc(CompileLinesCount);
       until (Eof(ResultF)) or (CompileLinesCount>=MaxCompileLines);
       close(ResultF);

       {Inc(EditFile);}
       SearchResult:=SearchTitle;
       if SearchResult=NIL
          then begin
                Re.Assign(0, 0, 80, 7);
                Re.Move(0,16);
                Window := New(PCompileWin, Init(Re, 'Last Compile Result', EditFile));
                Window^.WinTitle:='Win';
                DeskTop^.Insert(Window);
               end
          else begin
                PCompileWin(SearchResult)^.ReDraw;
               end;
      CompileResult:=true;
     end;
 end;
end;


procedure RunPrg;
var
   cmdline     : string;
   r           : registers;
   outtemp     : array[1..255] of char;
   temphandle,
   stdhandle   : word;
   fname       : string;
   i           : integer;
   ResultF     : text;
   SearchResult: PView;
   Re          : TRect;
   Window      : PCompileWin;
   auxstr      : string;

function SearchTitle : PView;
 function AuxSearchTitle(P: PView): Boolean; far;
  begin
    if PCompileWin(P)^.WinTitle='Win'
       then AuxSearchTitle:=True
       else AuxSearchTitle:=False;
  end;

 begin
  SearchTitle := DeskTop^.FirstThat(@AuxSearchTitle);
 end;

begin
 {first compile...}
 Compile;
 if CompileResult
    then begin
          {then do linkage...}
          fname:=Path2MyFiles+'asmedit.ide';
          for i:=1 to length(fname)+1 do outtemp[i]:=#0;
          for i:=1 to length(fname) do outtemp[i]:=fname[i];

          cmdline:='';
          with  LSFlags do cmdline:=cmdline+' '+All+' '+Map;
          with ALSFlags do cmdline:=cmdline+' '+Pack+' '+NewExe+' '+Platform;

          {get file handle - asmedit.ide : open fct $3d}
          r.ah:=$3c;
          r.ds:=seg(outtemp);
          r.dx:=ofs(outtemp);
          r.cx:=0;
          msdos(r);
          temphandle:=r.ax;

          {seek the eof : asmedit.ide
          r.ah:=$42;
          r.cx:=0;
          r.dx:=0;
          r.al:=2;
          r.bx:=temphandle;
          msdos(r);}

          {duplicate std out handle}
          r.ah:=$45;
          r.bx:=$1;
          msdos(r);
          stdhandle:=r.ax;

          {redirect standard output handle}
          r.ah:=$46;
          r.bx:=temphandle;
          r.cx:=1;
          msdos(r);


          Path2ExeLink:='';
          if (Path4ObjOutput=',') or (Path4ObjOutput=' ')
             then begin
                   FSplit(LastCompiledFile,D,N,E);
                   cmdline:=D+N+'.OBJ'+' '+cmdline;
                   Path2ExeLink:=D+N;
                   sound(200);delay(35);nosound;
                  end
             else  begin
                    Path4ObjOutPut[1]:=' ';{erase the ,}
                    FSplit(Path4ObjOutput,D,N,E);
                    if (N='') and (E='')
                       then begin
                             auxstr:=D;
                             FSplit(LastCompiledFile,D,N,E);
                             Path2ExeLink:=auxstr+N;
                             auxstr:=auxstr+N+'.OBJ';
                             cmdline:=auxstr+' '+cmdline;
                            end
                       else begin
                             cmdline:=Path4ObjOutPut+' '+cmdline;
                             FSplit(Path4ObjOutput,D,N,E);
                             Path2ExeLink:=D+N;
                            end;
                  end;

          exec(Path2MyFiles+'\tlink.exe','  '+cmdline+'  ');

          {test this shit}

          {restore original std handle}
          r.ah:=$46;
          r.bx:=stdhandle;
          r.cx:=1;
          msdos(r);

          {must close file}
          r.ah:=$3e;
          r.bx:=temphandle;
          msdos(r);

         {read informations from result file}
         for i:=0 to MaxCompileLines-1 do CompileLines[i]:='';
         Assign(ResultF,Fname);
         Reset(ResultF);
         CompileLines[0]:='Using the external linker for '+cmdline;
         CompileLinesCount:=1;
         repeat
          readln(ResultF,CompileLines[CompileLinesCount]);
          inc(CompileLinesCount);
         until (Eof(ResultF)) or (CompileLinesCount>=MaxCompileLines);
         close(ResultF);

        SearchResult:=SearchTitle;
        if SearchResult=NIL
           then begin
                 Re.Assign(0, 0, 80, 7);
                 Re.Move(0,16);
                 Window := New(PCompileWin, Init(Re, 'Last Compile Result', EditFile));
                 Window^.WinTitle:='Win';
                 DeskTop^.Insert(Window);
                end
           else begin
                 PCompileWin(SearchResult)^.ReDraw;
                end;

         case doserror of
          2 : MessageBox('Could not find external linker TLINK.EXE.',
               nil, mfError + mfOkButton);
          3 : MessageBox('Path to TLINK.EXE could not be found.',
               nil, mfError + mfOkButton);
          5 : MessageBox('Access denied to external linker TLINK.EXE.',
               nil, mfError + mfOkButton);
          6 : MessageBox('Invalid handler accesssing external linker TLINK.EXE.',
               nil, mfError + mfOkButton);
          8 : MessageBox('Not enough memory to run external linker TLINK.EXE.',
               nil, mfError + mfOkButton);
          10: MessageBox('Invalid environment.',
               nil, mfError + mfOkButton);
          11: MessageBox('Invalid format.',
               nil, mfError + mfOkButton);
         else if DosExitCode = 0 then
              begin
               if ALSFlags.Platform[5]='c' then Path2ExeLink:=Path2ExeLink+'.COM';
               if ALSFlags.Platform[5]='e' then Path2ExeLink:=Path2ExeLink+'.EXE';
               if ALSFlags.Platform[5]='d'
                  then begin
                        MessageBox('Cannot run a DLL.',nil, mfError + mfOkButton);
                        exit;
                       end;

               {then exec the program}
               CompileLines[CompileLinesCount]:='Running program : '+Path2ExeLink+'...';
               inc(CompileLinesCount);
               PCompileWin(SearchResult)^.ReDraw;

               GetVideoAttr(TV);
               SetVideoAttr(BeforeTV,TRUE);
               exec(Path2ExeLink,ParamList);
               GetVideoAttr(BeforeTV);
               SetVideoAttr(TV,FALSE);

               CompileLines[CompileLinesCount]:='DosError code : '+char(DosError+48);
               inc(CompileLinesCount);
               if DosError=0
                  then begin
                        CompileLines[CompileLinesCount]:='Exit code : '+char(Hi(DosExitCode)+48)+char(Lo(DosExitCode)+48);
                        inc(CompileLinesCount);
                       end;
               PCompileWin(SearchResult)^.ReDraw;

               {restore the application}
               DeskTop^.ReDraw;
               Application^.ReDraw;
              end;
         end;
      end;
end;

function Parameters : PDialog;
var
  D: PDialog;
  Control: PView;
  R: TRect;
begin
  R.Assign(0, 0, 60, 7);
  D := New(PDialog, Init(R, 'Program Parameters'));
  with D^ do
  begin
    Options := Options or ofCentered;

    R.Assign(15, 2, 55, 3);
    Control := New(PInputLine, Init(R, 80));
    Insert(Control);
    R.Assign(2, 2, 14, 3);
    Insert(New(PLabel, Init(R, '~P~arameter :', Control)));
    R.Assign(55, 2, 58, 3);
    Insert(New(PHistory, Init(R, PInputLine(Control), 10)));

    R.Assign(33, 4, 43, 6);
    Insert(New(PButton, Init(R, 'O~K~', cmOk, bfDefault)));
    Inc(R.A.X, 12); Inc(R.B.X, 12);
    Insert(New(PButton, Init(R, '~C~ancel', cmCancel, bfNormal)));

    SelectNext(False);
  end;
  Parameters := D;
end;

procedure DoInfo;
begin
 MessageBox('    Assembler IDE v1.01 by Karg '+#13+#13+'  (C) Wings Of Sorrow ,1995-1996',
  nil, mfInformation + mfOkButton);
end;

procedure UserScreen;
begin
 HideMouse;
 GetVideoAttr(TV);
 SetVideoAttr(BeforeTV,TRUE);
 readkey;
 SetVideoAttr(TV,False);
 DeskTop^.ReDraw;
 Application^.ReDraw;
 ShowMouse;
end;

begin
  inherited HandleEvent(Event);
  case Event.What of
    evCommand:
      case Event.Command of
        cmCalculator  : Calculator;
        cmShowClip    : ShowClip;
        cmCompile     : Compile;
        cmOpen        : FileOpen;
        cmNew         : FileNew;
        cmChangeDir   : ChangeDir;
        cmRun         : RunPrg;
        cmParam       : ExecuteDialog(Parameters, @ParamList);
        cmComp:if ExecuteDialog(New(PDragDialog1,Init), @CBFlags) <> cmCancel then
                     begin
                     with CBFlags do
                     begin
                     case Tipe of
                     1: CSFlags.Tipe:='Tasmx';
                     2: CSFlags.Tipe:='Masm';
                     3: begin
                        CSFlags.Tipe:='Tasmx';
                        Tipe:=1;
                        end;
                     end;

                     case Debug of
                     1 : CSFlags.Debug:='/zi';
                     2 : CSFlags.Debug:='/zd';
                     else begin
                          CSFlags.Debug:='/zn';
                          Debug:=4;
                          end;
                     end;
                     case Float of
                     0 : CSFlags.Float:='';
                     2 : CSFlags.Float:='/r';
                     else begin
                          CSFlags.Float:='/e';
                          Float:=1;
                          end;
                     end;

                     case Sense of
                     1 : CSFlags.Sense:='/ml';
                     2 : CSFlags.Sense:='/mx';
                     else begin
                          CSFlags.Sense:='/mu';
                          Sense:=4;
                          end;
                     end;

                     case Others of
                     1 : CSFlags.Others:='/c';
                     2 : CSFlags.Others:='/n';
                     4 : CSFlags.Others:='/p';
                     8 : CSFlags.Others:='/q';
                     0 : CSFlags.Others:='';
                     end;

                     case Order of
                     1 : CSFlags.Order:='/a';
                     2 : CSFlags.Order:='/s';
                     else begin
                          CSFlags.Order:='';
                          Order:=0;
                          end;
                     end;

                     case Code of
                     1 : CSFlags.Code:='/os';
                     2 : CSFlags.Code:='/o';
                     4 : CSFlags.Code:='/op';
                     8 : CSFlags.Code:='/oi';
                     else begin
                          CSFlags.Code:='/os';
                          Code:=1;
                          end;
                     end;

                     case List of
                     1 : CSFlags.List:='/l';
                     2 : CSFlags.List:='/la';
                     else begin
                          CSFlags.List:='';
                          List:=0;
                          end;
                     end;

                     end;
                     end;
        cmLink : if ExecuteDialog(New(PDragDialog2,Init), @LBFlags)<>cmCancel
                    then begin
                          AuxStr:='';
                          if LBFlags.All and 1=1 then AuxStr:=AuxStr+'/i ';
                          if LBFlags.All and 2=2 then AuxStr:=AuxStr+'/n ';
                          if LBFlags.All and 4=4 then AuxStr:=AuxStr+'/c ';
                          if LBFlags.All and 8=8 then AuxStr:=AuxStr+'/o ';
                          if LBFlags.All and 16=16 then AuxStr:=AuxStr+'/ye ';
                          if LBFlags.All and 32=32 then AuxStr:=AuxStr+'/yx ';
                          if LBFlags.All and 64=64 then AuxStr:=AuxStr+'/e ';
                          if LBFlags.All and 128=128 then AuxStr:=AuxStr+'/C ';
                          if LBFlags.All and 256=256 then AuxStr:=AuxStr+'/l ';
                          if LBFlags.All and 512=512 then AuxStr:=AuxStr+'/d ';
                          if LBFlags.All and 1024=1024 then AuxStr:=AuxStr+'/3 ';
                          if LBFlags.All and 1024=1024 then AuxStr:=AuxStr+'/v ';
                          LSFlags.All:=AuxStr;

                          AuxStr:='';
                          if LBFlags.Map and 1=1 then AuxStr:=AuxStr+'/m ';
                          if LBFlags.Map and 2=2 then AuxStr:=AuxStr+'/s ';
                          if LBFlags.Map=0 then AuxStr:='/x ';
                          LSFlags.Map:=AuxStr;

                         end;
        cmCAdv : if Application^.ExecuteDialog(New(PDragDialog3,Init), @CABFlags)<>cmCancel
                    then begin
                          with CASFlags do
                               begin
                                hash:='';
                                valid:='';
                                emu:='';
                                sym:='';
                               end;
                          if CABFlags.Hash<>'' then CASFlags.Hash:='/kh'+CABFlags.Hash+' ';
                          if CABFlags.Valid<>'' then CASFlags.Valid:='/mv'+CABFlags.Valid+' ';
                          if CABFlags.Emu<>'' then CASFlags.Emu:='/u'+CABFlags.Emu+' ';
                          if CABFlags.Sym<>'' then CASFlags.Sym:='/d'+CABFlags.Sym+' ';
                         end;
        cmLAdv : if Application^.ExecuteDialog(New(PDragDialog4,Init), @ALBFlags)<>cmCancel
                    then begin
                          with ALSFlags do
                               begin
                                Pack:='';
                                NewExe:='';
                                Platform:='';
                               end;
                          if ALBFlags.Pack<>'' then ALSFlags.Pack:='/P'+ALBFlags.Pack+' ';
                          if ALBFlags.NewExe<>'' then ALSFlags.NewExe:='/A'+ALBFlags.NewExe+' ';
                          case ALBFlags.Platform of
                          0 : ALSFlags.Platform:=' /Tw';
                          1 : ALSFlags.Platform:=' /Td';
                          end;
                          case ALBFlags.WhatExec of
                          0 : ALSFlags.Platform:=ALSFlags.Platform+'c';
                          1 : ALSFlags.Platform:=ALSFlags.Platform+'e';
                          2 : ALSFlags.Platform:=ALSFlags.Platform+'d';
                          end;
                         end;
        cmDirs : if Application^.ExecuteDialog(New(PDragDialog5,Init), @DirFlags)<>cmCancel
                    then begin
                          Dirs4Include:='';
                          if DirFlags.IncludeDir<>''
                             then begin
                                   AuxStr:='';
                                   for i:=1 to length(DirFlags.IncludeDir)+1 do
                                       begin
                                        if (DirFlags.IncludeDir[i]=' ') or
                                           (DirFlags.IncludeDir[i]=';') or
                                           (DirFlags.IncludeDir[i]=',') or
                                           (i>length(DirFlags.IncludeDir))
                                           then begin
                                                 if AuxStr[length(AuxStr)]<>'\' then AuxStr:=AuxStr+'\';
                                                 Dirs4Include:=Dirs4Include+'/i'+AuxStr+' ';
                                                 AuxStr:='';
                                                end
                                           else AuxStr:=AuxStr+DirFlags.IncludeDir[i];
                                       end;
                                  end;
                          If DirFlags.ObjectDir='' then Path4ObjOutPut:=','
                             else begin
                                   FSplit(DirFlags.ObjectDir,D,N,E);
                                   if N='' then Path4ObjOutPut:=','+D
                                      else Path4ObjOutPut:=','+D+N+E;
                                  end;
                          If DirFlags.ListingDir='' then Path4LstOutPut:=''
                             else begin
                                   FSplit(DirFlags.ListingDir,D,N,E);
                                   if N='' then Path4LstOutPut:=','+D
                                      else Path4LstOutPut:=','+D+N+E;
                                  end;
                          If DirFlags.XrefDir='' then Path4XrfOutPut:=''
                             else begin
                                   FSplit(DirFlags.XrefDir,D,N,E);
                                   if N='' then Path4XrfOutPut:=','+D
                                      else Path4XrfOutPut:=','+D+N+E;
                                   if Path4LstOutPut='' then Path4XrfOutPut:=','+Path4XrfOutPut;
                                  end;
                         end;

{    Directories = record
                IncludeDir,  ok
                ObjectDir,   ok
                ListingDir,  ok
                XRefDir,     ok
                ExeDir,
                MapDir,
                ObjectFiles,
                LibDir,
                DefDir : string[80];
                end;
}

        cmInfo : DoInfo;
        cmUScr : UserScreen;

      else
        Exit;
      end;
  else
    Exit;
  end;

  ClearEvent(Event);
end;

procedure TEditorApp.InitMenuBar;
var
  R: TRect;
begin
  GetExtent(R);
  R.B.Y := R.A.Y + 1;
  MenuBar := New(PMenuBar, Init(R, NewMenu(
    NewSubMenu('~F~ile', hcFile, NewMenu(
      StdFileMenuItems(
      nil)),
    NewSubMenu('~E~dit', hcEdit, NewMenu(
      StdEditMenuItems(
      nil)),
    NewSubMenu('~S~earch', hcSearch, NewMenu(
      NewItem('~F~ind...', '', kbNoKey, cmFind, hcFind,
      NewItem('~R~eplace...', '', kbNoKey, cmReplace, hcReplace,
      NewItem('~S~earch again', '', kbNoKey, cmSearchAgain, hcSAgain,
      nil)))),
    NewSubmenu('Exe~c~utor',hcExec,NewMenu(
      NewItem('~R~un CTRL-F9','',kbCtrlF9,cmRun,hcRun,
      NewItem('~C~ompile  F9','',KbF9,cmCompile,HcCompile,NewLine(
      NewItem('~P~arameters...','',kbNoKey,cmParam,hcParam,
      nil))))),
    NewSubmenu('~O~ptions',hcNoContext,NewMenu(
      NewItem('~C~ompiler Directives','',kbNoKey,cmComp,hcNoContext,
      NewItem('~L~inker Directives','',kbNoKey,cmLink,hcNoContext,
      NewItem('~A~dvanced Compiler','',kbNoKey,cmCAdv,hcNoContext,
      NewItem('Ad~v~anced Linker','',kbNoKey,cmLAdv,hcNoContext,NewLine(
      NewItem('~D~irectories...','',kbNoKey,cmDirs,hcNoContext,
      nil))))))),
    NewSubMenu('~W~indows', hcNoContext, NewMenu(
      StdWindowMenuItems(NewLine(
      NewItem('~U~ser screen Alt+F5', '', kbAltF5, cmUScr, hcUScr,
      nil)))),
    NewSubMenu('~H~elp', hcNoContext, NewMenu(
       NewItem('~A~bout', '',kbnokey,cmInfo,hcNoContext,
       nil)),
    nil))))))))));
end;

procedure TEditorApp.InitStatusLine;
var
  R: TRect;
begin
  GetExtent(R);
  R.A.Y := R.B.Y - 1;
  StatusLine:=
  New(PHintStatusLine, Init(R,
    NewStatusDef(0, $FFFF,
      NewStatusKey('~F2~ Save', kbF2, cmSave,
      NewStatusKey('~F3~ Open', kbF3, cmOpen,
      NewStatusKey('~Alt-F3~ Close', kbAltF3, cmClose,
      NewStatusKey('~F5~ Zoom', kbF5, cmZoom,
      NewStatusKey('~F6~ Next', kbF6, cmNext,
      NewStatusKey('', kbCtrlF5, cmResize,
      NewStatusKey('~F7~ Calculator', kbF7, cmCalculator,
      NewStatusKey('~F10~ Menu', kbF10, cmMenu,
      nil)))))))),
    nil)));
end;

procedure TEditorApp.OutOfMemory;
begin
  MessageBox('Not enough memory for this operation.',
    nil, mfError + mfOkButton);
end;

procedure TEditorApp.SaveConfig;
begin
end;
procedure TEditorApp.LoadConfig;
begin
end;

begin
  writeln('Assembler IDE Version 1.01 by KARG . (C) 1995-1996 Wings Of Sorrow');
  GetVideoAttr(BeforeTV);
  FSplit(FExpand('ASM.EXE'),Path2MyFiles,DummyName,DummyExt);
  EditorApp.Init;
  EditorApp.Run;
  EditorApp.Done;
end.
