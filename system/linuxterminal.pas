unit LinuxTerminal;

interface

procedure InitTerminalWindow;
procedure RenderTerminalInsideGUI(StartX, StartY: Integer);
procedure HandleKeyboardInput(Key: Char);

implementation

uses Ext4FileSystem;

const
  ROWS = 24; COLS = 80;

var
  ScreenBuffer: array[0..ROWS-1, 0..COLS-1] of Char;
  CX, CY: Integer;
  CmdBuffer: string[80];

procedure TermWriteStr(S: string);
var i: Integer;
begin
  for i := 1 to length(S) do
  begin
    if S[i] = #10 then
    begin
      CX := 0; inc(CY);
      Exit;
    end;
    ScreenBuffer[CY, CX] := S[i];
    inc(CX);
  end;
end;

procedure ExecuteCommand(Cmd: string);
begin
  TermWriteStr(#10);
  if Cmd = 'uname -a' then
    TermWriteStr('Linux pascal-kernel 6.1.0-RT-x86_64'#10)
  else if Cmd = 'ls' then
    TermWriteStr('bin/  boot/  dev/  etc/  home/  root/'#10)
  else
    TermWriteStr('bash: command not found'#10);
  
  TermWriteStr('root@pascal-os:/# ');
end;

procedure HandleKeyboardInput(Key: Char);
begin
  if Key = #13 then
  begin
    ExecuteCommand(CmdBuffer);
    CmdBuffer := '';
  end
  else
  begin
    CmdBuffer := CmdBuffer + Key;
    ScreenBuffer[CY, CX] := Key;
    inc(CX);
  end;
end;

procedure RenderTerminalInsideGUI(StartX, StartY: Integer);
var r, c: Integer;
begin
  for r := 0 to ROWS - 1 do
    for c := 0 to COLS - 1 do
    begin
      { Logika rysowania znaku ScreenBuffer[r,c] piksel po pikselu 
        na pozycji (StartX + c*8, StartY + r*16) }
    end;
end;

procedure InitTerminalWindow;
begin
  FillChar(ScreenBuffer, SizeOf(ScreenBuffer), ' ');
  CX := 0; CY := 0; CmdBuffer := '';
  TermWriteStr('Welcome to Pascal Linux Subsytem'#10);
  TermWriteStr('root@pascal-os:/# ');
end;

end.