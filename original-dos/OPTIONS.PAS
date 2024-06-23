UNIT
    Options;

INTERFACE

USES
    Dos, Objects, Drivers, Views, Menus, Dialogs,
    StdDlg, MsgBox, App;

TYPE
    TCBFlags = record
               Sense,
               Order,
               Debug,
               Float,
               Code,
               List,
               Others,
               Tipe:word
              end;
    TCSFlags = record
               Sense,
               Order,
               Debug,
               Float,
               Code,
               List,
               Others,
               Tipe:string[10];
              end;

    TLBFlags = record
             All,
             Map : word;
             end;
    TLSFlags = record
             All,
             Map : string[10];
             end;
    TCASFLags = record
              Hash,
              Valid,
              Emu : string[80];
              Sym : string[80];
              end;
    TCABFLags = record
              Hash,
              Valid,
              Emu : string[80];
              Sym : string[80];
              end;
    TALBFlags = record
              Pack,
              NewExe   : string[80];
              Platform,
              WhatExec : Word;
              end;
    TALSFlags = record
              Pack,
              NewExe,
              Platform : string[10];
              end;
    TDirFlags = record
                IncludeDir,
                ObjectDir,
                ListingDir,
                XRefDir,
                ExeDir,
                MapDir,
                ObjectFiles,
                LibDir,
                DefDir : string[80];
                end;

    PDragDialog1 = ^TDragDialog1;
    TDragDialog1 = object(TDialog)
      {compiler options}
      constructor Init;
    end;

    PDragDialog2 = ^TDragDialog2;
    TDragDialog2 = object(TDialog)
      {linker options}
      constructor Init;
    end;

    PDragDialog3 = ^TDragDialog3;
    TDragDialog3 = object(TDialog)
      {advanced compiler options}
      constructor Init;
    end;

    PDragDialog4 = ^TDragDialog4;
    TDragDialog4 = object(TDialog)
      {advanced linker options}
      constructor Init;
    end;

    PDragDialog5 = ^TDragDialog5;
    TDragDialog5 = object(TDialog)
      {directories options}
      constructor Init;
    end;

VAR
   DragDialog1       : PDragDialog1;
   DragDialog2       : PDragDialog2;
   CBFlags           : TCBFlags;
   CSFlags           : TCSFlags;
   LBFlags           : TLBFlags;
   LSFlags           : TLSFlags;
   CASFlags          : TCASFlags;
   CABFlags          : TCABFlags;
   ALBFlags          : TALBFlags;
   ALSFlags          : TALSFlags;
   DirFlags          : TDirFlags;

IMPLEMENTATION

constructor TDragDialog1.Init;
var
  R: TRect;
  ToIns:PCheckBoxes;
begin

  R.Assign(-35,-10, 35, 10);
  inherited Init(R, 'Compiler options');
  Options := Options or ofCentered;

  R.Assign(2, 3, 20, 6);
  ToIns := New(PCheckBoxes, Init(R,
    NewSItem('All',
    NewSItem('Globals',
    NewSItem('None',
    nil)))));
  Insert(ToIns);
  R.Assign(2, 2, 20, 3);
  Insert(New(PLabel, Init(R, 'Case ~S~ensitivity', ToIns)));

  R.Assign(22,3,46,5);
  ToIns := New(PCheckBoxes, Init(R,
   NewSItem('Alphabetic',
   NewSItem('Source-code segment',nil))));
  Insert(ToIns);
  R.Assign(22,2,32,3);
  Insert(New(PLabel,Init(R,'~O~rdering',ToIns)));

  R.Assign(48,3,68,6);
  ToIns := New(PCheckBoxes, Init(R,
   NewSItem('Full',
   NewSItem('Line Numbers',
   NewSItem('None',nil)))));
  Insert(ToIns);
  R.Assign(48,2,64,3);
  Insert(New(PLabel, Init(R, '~D~ebug Info', ToIns)));

  R.Assign(2,8,23,10);
  ToIns := New(PCheckBoxes, Init(R,
   NewSItem('Emulated',
   NewSItem('Real',nil))));
  Insert(ToIns);
  R.Assign(2,7,23,8);
  Insert(New(PLabel, Init(R,'~N~umeric processing',ToIns)));

  R.Assign(26,8,68,10);
  ToIns := New(PCheckBoxes, Init(R,
   NewSItem('Standard',
   NewSItem('Win/Overlay',
   NewSItem('Phar Lap',
   NewSItem('I B M',
   nil))))));
  Insert(ToIns);
  R.Assign(26,7,39,8);
  Insert(New(PLabel, Init(R,'Object ~C~ode',ToIns)));

  R.Assign(2,12,18,14);
  ToIns := New(PCheckBoxes, Init(R,
   NewSItem('Normal',
   NewSItem('Expanded',
   nil))));
  Insert(ToIns);
  R.Assign(2,11,18,12);
  Insert(New(PLabel, Init(R,'~L~isting',ToIns)));

  R.Assign(20, 12, 47, 16);
  ToIns := New(PCheckBoxes, Init(R,
    NewSItem('Cross References',
    NewSItem('Symbol Tables',
    NewSItem('Check DPMI override',
    NewSItem('Supress Obj unused'
    ,nil))))));
  Insert(ToIns);
  R.Assign(20, 11, 47, 12);
  Insert(New(PLabel, Init(R, 'O~t~hers', ToIns)));
  R.Assign(49, 12, 68, 14);
  ToIns := New(PCheckBoxes, Init(R,
    NewSItem('Tasm Type',
    NewSItem('Masm Type',nil))));
  Insert(ToIns);
  R.Assign(49, 11, 68, 12);
  Insert(New(PLabel, Init(R, 'Code ~g~eneration', ToIns)));


  R.Assign(23, 17, 33, 19);
  Insert(New(PButton, Init(R, 'O~k~', cmOK, bfDefault)));
  R.Assign(37, 17, 47, 19);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);
end;

constructor TDragDialog2.Init;
var
  R: TRect;
  ToIns:PCheckBoxes;
begin

  R.Assign(-35,-10, 35, 8);
  inherited Init(R, 'Linker options');
  Options := Options or ofCentered;

  R.Assign(2, 3, 68, 9);
  ToIns := New(PCheckBoxes, Init(R,
    NewSItem('Initialize all segments',
    NewSItem('No default libraries   ',
    NewSItem('Case significant symbols',
    NewSItem('Overlay switch',
    NewSItem('Expanded mem swapping',
    NewSItem('Extended mem swapping',
    NewSItem('No extended dictionary',
    NewSItem('Case sensitive',
    NewSItem('Source line numbers',
    NewSItem('Warn if duplicate symbols',
    NewSItem('Enable 32-bit process',
    NewSItem('Full debug info',
    nil))))))))))))));
  Insert(ToIns);
  R.Assign(2, 2, 20, 3);
  Insert(New(PLabel, Init(R, 'Code ~g~eneration', ToIns)));

  R.Assign(20, 11, 50, 13);
  ToIns := New(PCheckBoxes, Init(R,
    NewSItem('Map file with publics',
    NewSItem('Map file with segments',
    nil))));
  Insert(ToIns);
  R.Assign(20, 10, 50, 11);
  Insert(New(PLabel, Init(R, '~M~ap file', ToIns)));

  R.Assign(23, 15, 33, 17);
  Insert(New(PButton, Init(R, 'O~k~', cmOK, bfDefault)));
  R.Assign(37, 15, 47, 17);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);

end;

constructor TDragDialog3.Init;
var
  R      : TRect;
  ToIns2 : PInputLine;
begin

  R.Assign(-25,-7, 25, 8);
  inherited Init(R, 'Adv.Compiler options');
  Options := Options or ofCentered;

  R.Assign(33, 2, 39, 3);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(5, 2, 33, 3);
  Insert(New(PLabel, Init(R, '~H~ash table capacity ', TOIns2)));
  R.Assign(40, 2, 43, 3);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 11)));

  R.Assign(33, 4, 39, 5);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(5, 4, 33, 5);
  Insert(New(PLabel, Init(R, '~V~alid length for symbols', TOIns2)));
  R.Assign(40, 4, 43, 5);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 12)));

  R.Assign(31, 6, 39, 7);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(5, 6, 33, 7);
  Insert(New(PLabel, Init(R, '~E~mulation version', TOIns2)));
  R.Assign(40, 6, 43, 7);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 13)));

  R.Assign(6, 9, 39, 10);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(5, 8 , 33, 9);
  Insert(New(PLabel, Init(R, '~S~ymbols define', ToIns2)));
  R.Assign(40, 9, 43, 10);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 14)));

  R.Assign(13, 12, 23, 14);
  Insert(New(PButton, Init(R, 'O~k~', cmOK, bfDefault)));
  R.Assign(27, 12, 37, 14);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);

end;

constructor TDragDialog4.Init;
var
  R      : TRect;
  ToIns1 : PRadioButtons;
  ToIns2 : PInputLine;
begin

  R.Assign(-25,-7, 25, 8);
  inherited Init(R, 'Adv.Linker options');
  Options := Options or ofCentered;

  R.Assign(33, 2, 41, 3);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 2, 33, 3);
  Insert(New(PLabel, Init(R, '~P~ack code segments ', TOIns2)));
  R.Assign(42, 2, 45, 3);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 15)));

  R.Assign(33, 4, 41, 5);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 4, 33, 5);
  Insert(New(PLabel, Init(R, '~S~et NEWEXE segment allignment ', TOIns2)));
  R.Assign(42, 4, 45, 5);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 15)));

  R.Assign(2, 7, 23, 9);
  ToIns1 := New(PRadioButtons, Init(R,
    NewSItem('Windows',
    NewSItem('Dos',
    nil))));
  Insert(ToIns1);
  R.Assign(2, 6, 23, 7);
  Insert(New(PLabel, Init(R, 'Pl~a~tform', ToIns1)));

  R.Assign(27, 7, 48, 9);
  ToIns1 := New(PRadioButtons, Init(R,
    NewSItem('COM',
    NewSItem('EXE',
    NewSItem('DLL',
    nil)))));
  Insert(ToIns1);
  R.Assign(27, 6, 48, 7);
  Insert(New(PLabel, Init(R, 'Exe~c~utable', ToIns1)));

  R.Assign(13, 12, 23, 14);
  Insert(New(PButton, Init(R, 'O~k~', cmOK, bfDefault)));
  R.Assign(27, 12, 37, 14);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);

end;

constructor TDragDialog5.Init;
var
  R      : TRect;
  ToIns2 : PInputLine;
begin

  R.Assign(-35,-11, 35, 12);
  inherited Init(R, 'Directories');
  Options := Options or ofCentered;

  R.Assign(25, 2, 65, 3);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 2, 25, 3);
  Insert(New(PLabel, Init(R, '~I~nclude directories ', TOIns2)));
  R.Assign(65, 2, 68, 3);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 4, 65, 5);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 4, 25, 5);
  Insert(New(PLabel, Init(R, '~O~bject Output', TOIns2)));
  R.Assign(65, 4, 68, 5);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 6, 65, 7);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 6, 25, 7);
  Insert(New(PLabel, Init(R, '~L~isting Output', TOIns2)));
  R.Assign(65, 6, 68, 7);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 8, 65, 9);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 8, 25, 9);
  Insert(New(PLabel, Init(R, 'X~r~ef Output', TOIns2)));
  R.Assign(65, 8, 68, 9);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 10, 65, 11);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 10, 25, 11);
  Insert(New(PLabel, Init(R, 'E~x~e Output', TOIns2)));
  R.Assign(65, 10, 68, 11);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 12, 65, 13);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 12, 25, 13);
  Insert(New(PLabel, Init(R, '~M~ap Output', TOIns2)));
  R.Assign(65, 12, 68, 13);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 14, 65, 15);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 14, 25, 15);
  Insert(New(PLabel, Init(R, 'O~b~ject files to link', TOIns2)));
  R.Assign(65, 14, 68, 15);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 16, 65, 17);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 16, 25, 17);
  Insert(New(PLabel, Init(R, 'L~i~brary Directories', TOIns2)));
  R.Assign(65, 16, 68, 17);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(25, 18, 65, 19);
  ToIns2 := New(PInputLine, Init(R, 80));
  Insert(ToIns2);
  R.Assign(2, 18, 25, 19);
  Insert(New(PLabel, Init(R, 'De~f~inition Directories', TOIns2)));
  R.Assign(65, 18, 68, 19);
  Insert(New(PHistory, Init(R, PInputLine(ToIns2), 16)));

  R.Assign(23, 20, 33, 22);
  Insert(New(PButton, Init(R, 'O~k~', cmOK, bfDefault)));
  R.Assign(37, 20, 47, 22);
  Insert(New(PButton, Init(R, 'Cancel', cmCancel, bfNormal)));
  SelectNext(False);

end;

BEGIN
END.