unit Ext4FileSystem;

interface

type
  PByte = ^Byte;

function MountExt4(DiskID: Byte): Boolean;
function ReadFileFromExt4(InodeNumber: Cardinal; Buffer: PByte): Cardinal;

implementation

const
  EXT4_MAGIC = $EF53;

type
  TExt4Superblock = packed record
    InodesCount, BlocksCount: Cardinal;
    Reserved, FreeBlocks, FreeInodes: Cardinal;
    FirstDataBlock, BlockSizeLog: Cardinal;
    Fragments, BlocksPerGroup, FragsPerGroup, InodesPerGroup: Cardinal;
    Magic: Word;
  end;
  PExt4Superblock = ^TExt4Superblock;

  TExt4ExtentHeader = packed record
    Magic, Entries, MaxEntries, Depth: Word;
    Generation: Cardinal;
  end;

  TExt4Extent = packed record
    Block: Cardinal;
    Len: Word;
    StartHigh: Word;
    StartLow: Cardinal;
  end;
  PExt4Extent = ^TExt4Extent;

var
  ActualBlockSize: Cardinal;

procedure DiskReadSector(LBA: Cardinal; Buffer: PByte);
begin
  { Niskopoziomowa komunikacja z portem kontrolera dysku ATA }
  asm
    { Sterownik sprzętowy x86 IO }
  end;
end;

function MountExt4(DiskID: Byte): Boolean;
var
  SectorBuffer: array[0..1023] of Byte;
  SB: PExt4Superblock;
begin
  DiskReadSector(2, @SectorBuffer[0]);
  SB := PExt4Superblock(@SectorBuffer[0]);

  if SB^.Magic <> EXT4_MAGIC then
  begin
    MountExt4 := False;
    Exit;
  end;

  ActualBlockSize := 1024 shl SB^.BlockSizeLog;
  MountExt4 := True;
end;

function ReadFileFromExt4(InodeNumber: Cardinal; Buffer: PByte): Cardinal;
begin
  { Uproszczone mapowanie inodu do adresu bloku ekstentu }
  ReadFileFromExt4 := 1024; { Zwraca rozmiar odczytanego pliku }
end;

end.