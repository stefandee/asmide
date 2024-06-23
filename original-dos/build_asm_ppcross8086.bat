if not exist ./obj mkdir obj

ppcross8086 -Mtp -CX -XX -XP -WmHuge -Wtexe -FU./obj ASM.PAS
@if %ERRORLEVEL% GEQ 1 EXIT /B %ERRORLEVEL%

@rem run this from MS-DOS, compatible/emulation/virtualization (DosBox, FreeDos, etc)