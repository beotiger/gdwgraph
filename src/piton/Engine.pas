Unit Engine;
{ процедуры, входящие в основной вечный цикл игры }

interface

procedure KeyBoard;
procedure Analyser;
procedure ScreenAndTable;
procedure PutInfo;
procedure OpenLevel;
procedure AIPython;
procedure ServePitons;
procedure ServePiTails;
procedure ServeBeings;

implementation

Uses {Windows,}SDLglGDWGraph,PDefs,UPiton,Tables, sdl;

procedure PutBigScreen; { вывод двойного экрана (по нажатию F5) }
const
     MapY:array[-5..31] of byte = (20,21,22,23,24,25,1,2,3,4,5,6,7,8,9,10,
                           11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,1,
                           2,3,4,5,6);
     MapX:array[-7..40] of byte = (25,26,27,28,29,30,31,32,1,2,3,4,5,6,7,
                        8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,
                        25,26,27,28,29,30,31,32,1,2,3,4,5,6,7,8);
     UkazY:array[1..9] of byte = (4,4,4,4,10,10,12,14,16);
     TblX:array[0..79] of byte = (3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,
                       4,4,5,5,
                       6,6,7,7,8,8,9,9,10,10,11,11,12,12,13,13,14,14,
                       15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,
                       15,15,15,
                       14,14,13,13,12,12,11,11,10,10,9,9,8,8,7,7,6,6,
                       5,5,4,4);
var  i,j:integer;
     LeftX,TopY:integer;
     Pix:Pixel;Sym:Symbol;
     x,y: integer;
     s:string;
	 	A:Pixel;

begin
     { определим крайний левый верхний угол для вывода }
     if YMenu then begin
              LeftX:=8;
              TopY:=UkazY[Ukaz];
     end else
     if YTable then begin
               LeftX:=TblX[DCycles mod 80];
               TopY:=5
     end else
     begin
          LeftX:=Boa[1].Head.x-8;
          TopY:=Boa[1].Head.y-6
     end;
     for i:=0 to 11 do
         for j:=0 to 15 do
         begin
              Pix.y:=i*2+1;
              Pix.x:=j*2+1;
              Sym:=MAP[MapY[TopY+i],MapX[LeftX+j]];
              PutBigPalSymbol(Pix,Sym,0,2,2)
         end{for j,i};
         Pix.y:=25;

         for x:=1 to 32 do
         begin
         	Pix.X := x;
         	PutPalSymbol(Pix,SPACE,0);
         end;
         for y:=1 to 25 do
              for x:=33 to 40 do
              begin
              	Pix.X := x;
                Pix.Y := y;
                if Ekran[y,x].Code<>Map[y,x].Code then
                begin
                	EKRAN[y,x]:=MAP[y,x];
	              	PutPalSymbol(Pix,Map[y,x],0);
                end
              end;
{         // выведем номер уровня на экран
 	     Str(NumLev:2,S);
         Pix.x:=39;Pix.y:=11;
         Sym.Code:=ord(S[1]);
         Sym.Attr:=35;
	     PutBigPalSymbol(Pix,Sym,0,1,2);
         inc(Pix.x);
         Sym.Code:=ord(S[2]);
         PutBigPalSymbol(Pix,Sym,0,1,2);
 }
 // отдельно выведем область справа информационную
     for y:=1 to MaxY do
			 for x:=34 to MaxX do begin
				A.Y := y; A.X := x;
				PutPalSymbol(A, EKRAN[y,x], 0);
			 end;

// gdwSwapBuf;
end{PutBigScreen};


procedure ScreenAndTable;
var x,y:integer;
begin
     if YMenu then MenuTable.ControlMenu;
     if YMenu then MenuTable.ShowMenu
	     else if YTable then ScoreTable.ShowTable;
     if (NumOfPl=2) and ExtMode then
     begin	// число игроков 2 не может быть в большом режиме)
	     ExtMode:=false;
   	    for y:=1 to MaxY do
	        for x:=1 to 32 do
	          	EKRAN[y,x].Code:=333;
     end;

     if ExtMode then PutBigScreen {выводим большие символы }
	     	else	PrintScreen; { вывод карты игры на экран }
		
		// покажем уровень
		gdwSwapBuf;
			
     if YMenu then MenuTable.HideMenu else
	     if YTable then ScoreTable.HideTable;
end;

procedure KeyBoard;             { обслуживание клавиатуры }
const KeyBuffer:array[1..12] of word = (0,0,0,0,0,0,0,0,0,0,0,0);
var   KeyPnt:integer;
      Key:word;
      i:integer;
procedure Push(b:word); { это не стек, а ... не знаю что, но классно! }
var  i:integer;
begin
     KeyBuffer[KeyPnt]:=b;
     if KeyPnt<12 then
     		inc(KeyPnt)
     else
	     	for i:=1 to 11 do
         	KeyBuffer[i]:=KeyBuffer[i+1];
end;
procedure Pop(var b:word);
begin
     if KeyPnt>12 then b:=0 else
     begin
          b:=KeyBuffer[KeyPnt];KeyBuffer[KeyPnt]:=0;
          inc(KeyPnt)
     end {else}
end;
begin           { KeyBoard }
     KeyPnt:=1;
     Pl1Stat:=-1;
     Pl2Stat:=-1;  { статусы нажатия клавиш игроками }
     YESCed:=false;YENTERed:=false;
     YesF5:=false;
     Key:=InKey;
     while Key<>0 do begin
      Push(Key);
     	Key:=InKey
     end;
     KeyPnt:=1;
     Pop(Key);   { получим код клавиши }
     while Key<>0 do begin
           if Key=SDLK_ESCAPE then YESCed:=true;
           if Key=SDLK_RETURN then YENTERed:=true;
           if Key=SDLK_F5 then YesF5:=true;
           if Key=SDLK_TAB then YLevel:=true;	// ТАБ - след.уровень
           if Key=SDLK_F10 then ExitGame;		// выход из игры по Ф10
           if Key=SDLK_SPACE then YPaused:=not YPaused;	// toggle PAUSE
           for i:=0 to 3 do begin
               if Key=Pl1Keys[i] then Pl1Stat:=i;
               if Key=Pl2Keys[i] then Pl2Stat:=i
           end{for};
           Pop(Key)     { получим еще один код }
     end {while}
end  {KeyBoard};

procedure ServePitons;          { ///// перемещения питонов \\\\\ }
var i:integer;
begin
     if YPaused then exit;
     for i:=1 to MaxPiton do Boa[i].Control
end;
procedure ServePiTails;         { ///// перемещение обрубков хвостов \\\\\ }
var T,ET:PPiTail;
begin
     if YPaused then exit;
     T:=LastTail;
     while T<>NIL do begin
           T^.Move;
           if T^.Done then begin ET:=T;T:=T^.Prev;Dispose(ET,ReMove) end
           else T:=T^.Prev
     end
end;
procedure ServeBeings;
var B,DB:PBeing;
begin
     if YPaused then exit;
     B:=LastBeing;
     while B<>NIL do begin
           B^.Move;
           if B^.Kind=0 then begin
              DB:=B;B:=B^.Prev;Dispose(DB,ReMove)
           end else B:=B^.Prev
     end{while}
end{ServeBeings};

{ вывод информации о питонах игроков }
procedure PutInfo;
var       i,j:integer;S:string[5];A:Pixel;S2:string[3];
			Sym:Symbol;
const     Head1:Symbol=(Code:4;Attr:0);
          Head2:Symbol=(Code:4;Attr:1);
          CondState:array[State] of string[6] = ('empty ','hunger',' God  ',
                                              'frozen',' dead ',' born ');
procedure PutStr2MAP(A:Pixel;Info:string;Pal:byte);
var i:integer;L:byte;ss:string;bb:byte;
begin
	L:=Length(Info);
     for i:=1 to L do begin
         ss:=Info[i];
         bb:=ord(ss[1]);
         if bb > 127 then bb:= oem866_table[bb];
//  			CharToOEMBuff(@ss[1], @ss[1], Length(ss));
         MAP[A.y,A.x+i-1].Code:=word(bb);//ord(SS[1]);
         MAP[A.y,A.x+i-1].Attr:=Pal
     end{for}
end;
begin
     if YPaused then exit;
     if Cycles mod 2<>0 then exit;  { обслуживаем лишь 3 раза в секунду }

     // выводим головы
     for i:=1 to 7 do begin
         MAP[2,33+i].Code:=Blank;
         MAP[19,33+i].Code:=Blank
     end;
     if Boa[1].Lives>0 then begin
        j:=41-Boa[1].Lives;
        if j<34 then j:=34;
        for i:=40 downto j do MAP[2,i]:=Head1
     end;
     if Boa[2].Lives>0 then begin
        j:=41-Boa[2].Lives;
        if j<34 then j:=34;
        for i:=40 downto j do MAP[19,i]:=Head2
     end;

     Str(Boa[1].Score:5,S);A.x:=35;A.y:=4;
     PutStr2MAP(A,S,39);
     if Boa[1].Score=0 then MAP[4,39].Code:=Blank;
     Str(Boa[1].Len:3,S);A.x:=38;A.y:=6;
     PutStr2MAP(A,S,40);

     Str(Boa[1].Timer:3,S2);A.x:=35;A.y:=7;
     PutStr2MAP(A,S2,41);

     // то же для 2-го игрока
     Str(Boa[2].Score:5,S);A.x:=35;A.y:=21;
     PutStr2MAP(A,S,39);
     if Boa[2].Score=0 then MAP[21,39].Code:=Blank;
     Str(Boa[2].Len:3,S);A.x:=38;A.y:=23;
     PutStr2MAP(A,S,40);
     Str(Boa[2].Timer:3,S2);A.x:=35;A.y:=24;
     PutStr2MAP(A,S2,41);
     A.x:=34;A.y:=8;PutStr2MAP(A,CondState[Boa[1].Condition],35);
     A.x:=34;A.y:=25;PutStr2MAP(A,CondState[Boa[2].Condition],35);
     // выведем число жителей
     Str(QntRab:2,S2);
     A.x:=36;A.y:=12;
     PutStr2MAP(A,S2,45);
     Str(QntFrog:2,S2);
     A.y:=13;
     PutStr2MAP(A,S2,45);
     Str(QntFly:2,S2);
     A.y:=14;
     PutStr2MAP(A,S2,45);
     Str(QntMan:2,S2);
     A.y:=15;
     PutStr2MAP(A,S2,45);
{
	     Str(NumLev:2,S);
         A.x:=39;A.y:=11;
         Sym.Code:=ord(S[1]);
         Sym.Attr:=35;
	     PutBigPalSymbol(A,Sym,0,1,2);
         inc(A.x);
         Sym.Code:=ord(S[2]);
         PutBigPalSymbol(A,Sym,0,1,2);
 }
end  {PutInfo};


procedure OpenLevel;
var Er:byte;
const DemoLevels:array[0..2]of word = (3,5,8);

procedure ReadMap(Level:word;var Err:byte);   {  читает один уровень из файла }
var       L:UniLevel;F:file of UniLevel;
          Z:Pixel;Kind:word;N:integer;
          x,y:integer;
          S:string;
          Sym:symbol;
const Code2Kind:array[Fly1..Key2] of word = (1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4,
                                  5,6,7,8,9,10,11,12,13,14);
begin
     Assign(F,MapsFileName);ReSet(F);
     Er:=IOResult; if Er<>0 then exit;
     Seek(F,Level-1); Read(F,L);Er:=IOResult;
     Close(F);
     if Er>0 then exit;
     with L do begin
          QntFly:=Fl;QntRab:=R;QntFrog:=Fr;QntMan:=M;
          N:=2;
          for y:=1 to MapY do
              for x:=1 to MapX do begin
              		Z.X := x; Z.Y := y;
                  MAP[Z.y,Z.x]:=FileMap[Z.y,Z.x];
                  Kind:=MAP[Z.y,Z.x].Code;
                  case Kind of
                  21:begin
                          MAP[Z.y,Z.x]:=SPACE;
                          if Boa[1].Condition<>EMPTY then
                              Boa[1].Init(Z,Random(4),0,Boa[1].Len,NormSpeed)
                     end;
                  22:begin
                          MAP[Z.y,Z.x]:=SPACE;
                          if Boa[2].Condition<>EMPTY then
                              Boa[2].Init(Z,Random(4),1,Boa[2].Len,NormSpeed)
                     end;
                  23:begin
                          MAP[Z.y,Z.x]:=SPACE;
                          inc(N);if N>MaxPiton then N:=3;
                          Boa[N].Init(Z,Random(4),2+Random(2),2+Random(5),
                          LowSpeed-Random(Cycles div 5000+1));
                          if integer(Boa[N].Speed)<FastSpeed
                             then Boa[N].Speed:=FastSpeed;
                             Boa[N].Lives:=Cycles div 7000
                     end;
                  Fly1..Key2:begin
                         Kind:=Code2Kind[Kind];
                         CreateBeing(Z,Kind);
                         case Kind of
                         1:inc(QntFly);
                         2:inc(QntRab);
                         3:inc(QntFrog);
                         4:inc(QntMan);
                         13,14:YesKey:=true { ключ на уровне }
                         end
                             end
                  end {case Kind}
          end{for}
     end;{with}
// Выведем на экран номер уровня
	     Str(Level:2,S);
         Z.x:=39;Z.y:=11;
         Sym.Code:=ord(S[1]);
         Sym.Attr:=35;
	     PutBigPalSymbol(Z,Sym,0,1,2);
         inc(Z.x);
         Sym.Code:=ord(S[2]);
         PutBigPalSymbol(Z,Sym,0,1,2);
end {ReadMap};
const HC1:Pixel=(x:16;y:13);    { положение голов питонов при старте игры }
      HC2:Pixel=(x:15;y:13);
      HB1:Pixel=(x:32;y:13);
      HB2:Pixel=(x:1;y:13);
begin
     if not(YLevel) then exit;
     ClearMap;
     ClearObjects;
     YLevel:=false;YesKey:=false;KeyPicked:=false;YCrushed:=false;
     TimeEndOfGame:=0;
     case GameType of
     CLASSIC: begin
            Boa[1].Lives:=0;Boa[2].Lives:=0;
            Boa[1].Init(HC1,3,0,Boa[1].Len,NormSpeed);
            if Boa[2].Condition<>EMPTY then
            Boa[2].Init(HC2,1,1,Boa[2].Len,NormSpeed);
            YAte:=true
            end;
     BOAS:  begin
            Boa[1].Init(HB1,1,0,Boa[1].Len,NormSpeed);
            Boa[2].Init(HB2,3,1+Random(3),Boa[2].Len,NormSpeed);
            Boa[1].Lives:=0;Boa[2].Lives:=0;
            SummonThing(BRICK,Random(12)+Cycles div 1080);
            with Boa[1].Head do MAP[y,x]:=SPACE;
            with Boa[2].Head do MAP[y,x]:=SPACE
            end;
     UNIV, DEMO:
           begin
                if GameType=DEMO then NumLev:=DemoLevels[Random(3)]
                else begin
                  inc(NumLev);if NumLev mod 5 = 0 then FromLevel:=NumLev
                end;
                if NumLev>MaxLevel then NumLev:=1;
                ReadMap(NumLev,Er);
                if Er>0 then begin
                   CloseGraph;
//                   writeln('Read map error ',Er,' at NumLev = ',NumLev);
                   halt(255)
                end
           end
     end{case}
end{OpenLevel};

procedure AIPython;
var N:word;
procedure FindNearestGame(var Spot:Pixel);
var       Dist,D:integer;
          Plot:Pixel;B:PBeing;
begin
     Dist:=10000;Plot:=SPot;
     B:=LastBeing;
     while B<>NIL do begin
           if B^.Kind<5 then begin
              D:=Distance(Plot,B^.LOC);
              if D<Dist then begin
                 Dist:=D;Spot:=B^.LOC
              end
           end;
           B:=B^.Prev
     end
end;
procedure AIDir(N:word);
var A,G:Pixel;C:word;
begin
     if Boa[N].xSpeed>0 then exit;      { не трогаем пока его }
     with Boa[N] do
     if GameType<>BOAS then begin
        if Stamina=0 then begin
           Game:=Head;FindNearestGame(Game); {ищем жертву}
           Stamina:=40+Random(50)
        end else begin
            if (Game.x=Head.x) and (Game.y=Head.y) then Stamina:=0
            else begin
                 if Game.x<Head.x then G.x:=3 else G.x:=1;
                 if Game.y<Head.y then G.y:=0 else G.y:=2;
                 A:=Head;NextCoor(A,Dir);C:=MAP[A.y,A.x].Code;
                 if (Random(100)>55) or (C=8) or ((C>14)and(C<18)) then
                 case Dir of
                 0,2:Dir:=G.x;
                 1,3:Dir:=G.y
                 end;
                 dec(Stamina)
            end{else}
        end{else}
     end else
     begin                      { if GameType<>BOAS }
          A:=Head;NextCoor(A,Dir);{LookForward}
          if (Random(100)<25)or (MAP[A.y,A.x].Code<>Blank) then begin
             C:=Dir+SGN(Random(7)-3);
             A:=HEAD;NextCoor(A,C);  { двойная проверка на пробел }
             if MAP[A.y,A.x].Code=Blank then Dir:=C else
             begin
                  if Dir-C<0 then Dir:=(Dir-1)and 3 else Dir:=(Dir+1)and 3
             end
          end{if}
     end{else}
end{AIDir};
begin
     if YPaused then exit;
     if Boa[1].Condition<>EMPTY then begin
        if GameType=DEMO then AIDir(1) else
        with Boa[1] do
             if (Pl1Stat=Dir) and (Speed>FastSpeed) then dec(Speed) else
             if (Pl1Stat=(Dir+2) and 3) and (Speed<LowSpeed) then inc(Speed)
             else if (Pl1Stat<>-1) and (Pl1Stat<>(Dir+2)and 3) then Dir:=Pl1Stat
     end{if};
     if Boa[2].Condition<>EMPTY then begin
        if (GameType=DEMO) or ((GameType=BOAS) and (NumOfPl=1)) then AIDir(2) else
        with Boa[2] do
             if (Pl2Stat=Dir) and (Speed>FastSpeed) then dec(Speed) else
             if (Pl2Stat=(Dir+2) and 3) and (Speed<LowSpeed) then inc(Speed)
             else if (Pl2Stat<>-1) and (Pl2Stat<>(Dir+2) and 3) then Dir:=Pl2Stat
     end{if};
     for N:=3 to MaxPiton do
         if Boa[N].Condition<>EMPTY then AIDir(N)
end{AIPython};

procedure Analyser;     { анализизатор игры - МОЗГ игры }
const TC:array[0..2] of Pixel = ((x:32;y:5),(x:32;y:25),(x:3;y:25));
var x,y:integer;
begin
     if not(YPaused) then inc(Cycles);
     inc(DCycles);
     if YESCed then begin
        if YMenu then begin YMenu:=false;YPaused:=false end
        else begin
             YTable:=false;YMenu:=true;
             if GameType<>DEMO then YPaused:=true
        end
     end;
     if YesF5 then begin
     	ExtMode:=not(ExtMode);
        if not(ExtMode) then // clear field for refreshing
        	    for y:=1 to MaxY do
		         for x:=1 to 32 do
	            	EKRAN[y,x].Code:=333;
     end;
     if TimeEndOfGame=0 then begin
        if (Boa[1].Condition=EMPTY) and (Boa[2].Condition=EMPTY) then
         TimeEndOfGame:=18*3{секунды}
        else
        case GameType of
        CLASSIC:if YAte then begin
                 YAte:=false;
                 if Rabs<5 then SummonBeing(2,Random(2)+1);
                 SummonThing(Brick,Random(3));
                 SummonThing(Spike,Random(3)+1);
                 SummonThing(Spike2,Random(3))
                 end;
        DEMO,UNIV:
                  if YesKey then begin
                     if KeyPicked then YLevel:=true { go to the Next Level }
                  end else begin
                  if (QntFly=0) and (QntRab=0) and (QntFrog=0) and (QntMan=0)
                  then begin
                       YesKey:=true;SummonBeing(13,1+Random(2))
                  end else if YAte then begin
                      YAte:=false;
                      if QntFly>0 then
                         if Flies<3 then SummonBeing(1,1);
                      if QntRab>0 then
                         if Rabs<4 then SummonBeing(2,Random(2)+2);
                      if QntFrog>0 then
                         if Frogs<3 then SummonBeing(3,Random(2)+1);
                      if QntMan>0 then
                         if Men<5 then SummonBeing(4,1);
                      if Random(100)>75 then SummonThing(Spike2,Random(4))
                  end
                  end;
        BOAS:if YCrushed then YLevel:=true
        end{case}
        end {if TimeEndOfGame=0}
        else begin
             dec(TimeEndOfGame);
             if TimeEndOfGame>0 then exit;
			     ExtMode:=false;
	    	    for y:=1 to MaxY do
			        for x:=1 to 32 do
		          	EKRAN[y,x].Code:=333;
             ScoreTable.MoveTable2Center(TC[Random(3)]);
             if (GameType=UNIV) or (GameType=CLASSIC) then
             begin
              with Boa[1] do ScoreTable.InsertName(Score,MaxLength);
              ScoreTable.ShowTable;ReFreshScreen;
          if (NumOfPl=1) and (Boa[1].Score<=ScoreTable.Participiant[10].Scores)
          then WaitWithKey(180) { Pause for showing table of scores }
          else if NumOfPl>1 then begin
              with Boa[2] do ScoreTable.InsertName(Score,MaxLength);
              if Boa[2].Score<=ScoreTable.Participiant[10].Scores then
                 WaitWithKey(180)
          end
          end else WaitWithKey(180);
          ScoreTable.HideTable;
		  PrintScreen;
			gdwSwapBuf;
			
          GameType:=DEMO;
		  NewGame
     end
end{Analyser};


end.
