program KNOP;

Uses
  SDLglGDWGraph in '../sdlglgdwgraph.pas';

var
    Time,deltaTime:word;

procedure FillScreen;
var i,j:integer;
    B:Pixel;
    S:Symbol;
    begin
         i:=1;
         while i<25 do begin
               j:=1;
               while j<40 do begin
                     B.x:=j;B.y:=i;
                     S.Code:=Random(2)*4;
                     S.Attr:=14;
                     Put16x16(B,S,0);
                     inc(j,2)
               end;
               inc(i,2)
         end{}
    end {FillScreen};

begin
 if LoadSymData('KNOP.CHR')<>0 then
 begin
       writeln(#7,'File read error!');
       halt (255)
 end;
 
 InitGraph;
 FillScreen;
 
 gdwSwapBuf;
 
 Time:=WhatTime;
 repeat until InKey<>0;
 
 // pause defends on user interaction
 deltaTime := WhatTime - Time;

 while true do begin
	 FillScreen;
	 
	 gdwSwapBuf;
	 
	 Time:=WhatTime + deltaTime;
	 
	 while WhatTime<Time do if InKey<>0 then halt
	 
 end{while}
 
end.

