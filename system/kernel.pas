program PascalOSKernel;

uses 
  Ext4FileSystem, 
  GraphicalDesktop, 
  LinuxTerminal;

procedure KernelMain; cdecl; export;
begin
  { 1. Niskopoziomowy montaż dysku systemowego }
  if not MountExt4(0) then
  begin
    { Błąd krytyczny jądra (Kernel Panic) - brak możliwości odczytu dysku }
    asm hlt end;
  end;

  { 2. Inicjalizacja podsystemu terminala i pamięci ekranu }
  InitTerminalWindow;

  { 3. Uruchomienie serwera graficznego GUI i wejście w pętlę operacyjną }
  RunDesktopLoop;
end;

begin
  { Sekcja pusta - jądro jest wywoływane przez KernelMain, nie przez standardowy start }
end.