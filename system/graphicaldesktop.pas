unit GraphicalDesktop;

interface

uses LinuxTerminal;

procedure RunDesktopLoop;
procedure PutPixel(X, Y: Integer; Color: Cardinal);

implementation

const
  SCREEN_WIDTH  = 1024;
  SCREEN_HEIGHT = 768;
  VESA_FRAMEBUFFER = $E0000000; 

  COLOR_BACKGROUND = $00050A05;
  COLOR_TERMINAL   = $00002200;
  COLOR_TEXT_GREEN = $0000FF00;
  COLOR_BORDER     = $00005500;
  COLOR_BAR        = $00001100;

type
  TWindow = record
    X, Y, Width, Height: Integer;
    Title: PChar;
  end;

var
  TermWindow: TWindow;

procedure PutPixel(X, Y: Integer; Color: Cardinal); inline;
var PixelPtr: PCardinal;
begin
  if (X >= 0) and (X < SCREEN_WIDTH) and (Y >= 0) and (Y < SCREEN_HEIGHT) then
  begin
    PixelPtr := PCardinal(VESA_FRAMEBUFFER + (Y * SCREEN_WIDTH + X) * 4);
    PixelPtr^ := Color;
  end;
end;

procedure DrawRectangle(X, Y, W, H: Integer; Color: Cardinal);
var PX, PY: Integer;
begin
  for PY := Y to Y + H do
    for PX := X to X + W do PutPixel(PX, PY, Color);
end;

procedure DrawDesktop;
var i: Integer;
begin
  DrawRectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_BACKGROUND);
  
  { Linie skanujące CRT }
  for i := 0 to (SCREEN_HEIGHT div 4) do
    for unsafe_x := 0 to SCREEN_WIDTH-1 do PutPixel(unsafe_x, i*4, $00000500);

  { Pasek zadań }
  DrawRectangle(0, SCREEN_HEIGHT - 40, SCREEN_WIDTH, 40, COLOR_BAR);

  { Okno terminala }
  DrawRectangle(TermWindow.X, TermWindow.Y, TermWindow.Width, TermWindow.Height, COLOR_TERMINAL);
  DrawRectangle(TermWindow.X, TermWindow.Y, TermWindow.Width, 20, COLOR_BORDER);
  
  { Wywołanie renderowania zawartości tekstowej terminala }
  RenderTerminalInsideGUI(TermWindow.X + 10, TermWindow.Y + 30);
end;

procedure RunDesktopLoop;
begin
  TermWindow.X := 100; TermWindow.Y := 100;
  TermWindow.Width := 640; TermWindow.Height := 400;

  while True do
  begin
    DrawDesktop;
    asm hlt end; { Odpoczynek procesora do następnego przerwania zegara }
  end;
end;

end.