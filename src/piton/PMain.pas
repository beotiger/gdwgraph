Unit PMain;          { PMAIN.PAS }
interface

procedure Main;

implementation

Uses SDLGLgdwGraph,PDefs,UPiton,Engine,Tables;

function LoadIntroFile(S:string):byte;forward;

procedure IIInitialization;
var a,b:pixel;E:byte;

	procedure Error(S:string);
	begin
	     writeln('File ',S,' read error.');
	     halt(255)
	end;
begin
     if LoadSymData(SymFileName)<>0 then Error(SymFileName);
     if LoadPalData(PalFileName)<>0 then {Error(PalFileName)};
     if NumPal<50 then Error(PalFileName);
   	 ClearEKRANandMAP;
     if LoadIntroFile(IntroFileName)<>0 then Error(IntroFileName);
     ScoreTable.LoadTable(E);
     if E<>0 then ScoreTable.NullTable;
     ScoreTable.InitForma;
     MenuTable.InitForma;

     InitGraph('Piton-99');
     ClearDevice;

     Randomize;
     NewGame;
		 
     MAP[4,40].Code:=ord('0');
     MAP[4,40].Attr:=39;
     MAP[21,40].Code:=ord('0');
     MAP[21,40].Attr:=39;

     PrintScreen;       { печатаем всю MAP }
		 gdwSwapBuf;

     WaitWithKey(180)
end;
function LoadIntroFile(S:string):byte;
var F:file of Screen;Er:byte;
begin
{$I-}
     Assign(F,S);Reset(F);Er:=IOResult;
     if Er=0 then begin Read(F,MAP);Er:=IOResult;Close(F) end;
     LoadIntroFile:=Er
{$I+}
end;
procedure Main;
begin                   { MAIN }
	IIInitialization;
	repeat
				GloTimer:=WhatTime+60;
				KeyBoard;
				OpenLevel;
				PutInfo;
				AIPython;
				ServePitons;
				ServePiTails;
				ServeBeings;
				{ SoundPlayer - звука нет }
				Analyser;
				ScreenAndTable;
				while GloTimer>WhatTime do{ пауза, выравнивающая скорость }
	until false
end;                     { MAIN}
{	////// GDW has finished debugging on 1 of June, 2001	}
{	////// city of Volgograd, VMA, Physics department!		}

end.

