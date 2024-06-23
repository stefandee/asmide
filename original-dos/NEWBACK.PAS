unit NewBack;

interface

uses Objects, Drivers, Views, App;

type
  PMyBackground = ^TMyBackground;
  TMyBackground = object(TBackground)
    Text: TTitleStr;
    constructor Init(var Bounds: TRect; AText: TTitleStr);
    procedure Draw; virtual;
  end;

  PMyDesktop = ^TMyDesktop;
  TMyDesktop = object(TDesktop)
    procedure InitBackground; virtual;
  end;



implementation

constructor TMyBackground.Init(var Bounds: TRect; AText: TTitleStr);
begin
  inherited Init(Bounds, ' ');
  Text := AText;
  while Length(Text) < SizeOf(TTitleStr) - 1 do
    Text := Text + AText;
end;

procedure TMyBackground.Draw;
var
  DrawBuffer: TDrawBuffer;
begin
  MoveStr(DrawBuffer, Text, 113{GetColor(1)});
  WriteLine(0, 0, Size.X, Size.Y, DrawBuffer);
end;

procedure TMyDesktop.InitBackground;
var
  R: TRect;
begin
  GetExtent(R);
  Background := New(PMyBackground, Init(R,'±'));
end;

begin
end.
