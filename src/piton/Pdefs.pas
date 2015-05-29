Unit PDefs;     { переменные и начальные функции Питона - старт 11 апреля
                  2001 года от рождества Христова }

interface
Uses SDLglGdwGraph{, Types}, sdl;

{\\\\\\\\\\\\ ИМЕНА РАБОЧИХ ФАЙЛОВ ////////////////}
const         TableFileName = 'SCORES.PTN';
              SymFileName   = 'PITON.CHR';
              PalFileName   = 'PITON.PAL';
              IntroFileName = 'INTRO.PTN';
              MapsFileName  = 'MAPS.PTN';


const         MaxX = 40;
              MaxY = 25;
              MapX = 32;
              MapY = 25;
              StartX = 0;
              StartY = 0;

              MaxLevel = 25; {макс.уровень в питоне универсале }
              MaxPiton = 8;  { число питонов }

              { коды в таблице символов }
              Fly1   = 256;     { муха }
              Rab1   = 260;     {кролик}
              Frog1  = 264;     {лягушка}
              Man1   = 268;     { человек }
              Seed1  = 272;     { семена 1 }
              Seed6  = 277;     { увядший цветок }
              Block1 = 278;     { блоки }
              Block2 = 279;
              Key1   = 280;     {ключи}
              Key2   = 281;
              Blank  = 32;      { пробел - пусто на карте }
{\\\\\\\\\ Описание некоторых символов ///////////////////////////}
           BRICK:Symbol       =(Code:8;Attr:8);
           SPACE:Symbol       =(Code:32;Attr:38);
           SPIKE:Symbol       =(Code:15;Attr:15);
           SPIKE2:Symbol      =(Code:16;Attr:16);
           HSLASH:Symbol      =(Code:18;Attr:46);
           VSLASH:Symbol      =(Code:19;Attr:46);
           LUC:Symbol         =(Code:24;Attr:46);
           RUC:Symbol         =(Code:25;Attr:46);
           LDC:Symbol         =(Code:26;Attr:46);
           RDC:Symbol         =(Code:27;Attr:46);


type      Gmtp = (DEMO, CLASSIC, UNIV, BOAS);   { типы игры }
          State = (EMPTY,GOOD,GOD,FROZEN,DEADONE,BORN); { состояния питона }
          Screen = array [1..MaxY,1..MaxX] of Symbol;

          UniLevel = record                { структура уровня в файле }
                   FileMap:array[1..MapY, 1..MapX] of Symbol; { уровень }
                   Fl,R,Fr,M:word         { число жителей в уровне }
                   end;

const
     GameType:Gmtp = DEMO;      { стартуем в демо }
     Cycles:word   = 0;         { циклы игры      }
     TimeEndOfGame:word = 0;    { отчет для конца игры }
     Ukaz:word = 2;
     DCycles:word = 0;          { полные циклы игры }
     FromLevel:word = 1;        { с какого уровня начинать }
     YesKey:boolean = FALSE;            { ключ на уровне ли     }
     KeyPicked:boolean = FALSE;         { ключ взял ли  }
     YCrushed:boolean = FALSE;          { врубился ли   }
     NumOfPl:byte = 1;                  { число игроков }
     NumLev:word  = 0;                  { текущий уровень }
     Ctrl1Pl:byte = 1;                  { управление 1-го игрока }
     Ctrl2Pl:byte = 2;                  { управление 2-го игрока }
     YESCED:boolean = FALSE;            { флаг нажатия ESC       }
     YENTERED:boolean = FALSE;          { флаг нажатия ENTER     }
     YesF5:boolean    = FALSE;          { флаг нажатия F5        }
     ExtMode:boolean  = FALSE;          { флаг расширенного режима }
     YPaused:boolean = FALSE;           { флаг ПАУЗЫ }
     YMenu:boolean = FALSE;             { выводить меню? }
     YTable:boolean = FALSE;            { показывать таблицу рекордов? }
     YLevel:boolean = TRUE;             { уровень грузим в начале }
     YATE:boolean = FALSE;              { cъел ли что-либо питончик }

    { массивы клавиш управления для 1-го и 2-го игроков }
    Pl1Keys:array [0..3] of word = (SDLK_UP,SDLK_RIGHT,SDLK_DOWN,SDLK_LEFT);
    Pl2Keys:array [0..3] of word = (SDLK_w,SDLK_d,SDLK_s,SDLK_a);

    {  таймеры в 1/18 секундах - 1 цикл игры длится 1/18 секунды }
    DeadTime   = 15;
    HungryTime = 18*10;
    GodTime    = 18*10;
    FreezeTime = 18*2;
    InitTime   = 18*3;
    {-----скорость также в тиках игры---- }
    NormSpeed  = 3;
    FastSpeed  = 1;
    LowSpeed   = 5;

	MaxAvail = 32600;	// от фонаря взял

var
   EKRAN, MAP:Screen;
   QntFly,QntRab,QntFrog,QntMan:word;   { количество живности на уровне }
   Pl1Stat, Pl2Stat:integer;            { статус нажатия для игроков    }
   GloTimer:Longword;                       { таймер отсчета 1/18 сек.      }

   Flies,Rabs,Frogs,Men:integer;        { число присутствующих на уровне жителей }


procedure ReFreshScreen;                { проца вывода карты на экран }
procedure NextCoor(var Coor:Pixel;Dir:word); { смена координат в направлении Dir }
procedure PrevCoor(var Coor:pixel;Dir:word); { координаты обратно }
procedure BackDir(var Dir:word);             { направление обратно }

function ThisIsTheEdgeOfMap(LOC:Pixel):boolean; { TRUE - если вышли за границы карты }
function IsInMap(LOC:Pixel):boolean;            { TRUE - если в карте }
function CorCoor(Spot:Pixel):boolean; {TRUE - если не за грагицей и карта пуста в этом месте }
function SGN(Value:integer):integer;  { SGN - она и в Васике SGN }
procedure NextEnhCoor(var Plot:Pixel;Dir:word); { диагональные перемещения }
procedure PrevEnhCoor(var Plot:Pixel;Dir:word);
procedure NewCoor(var Spot:Pixel;Dir:word);        { все направления }
procedure Wait(Tics:Longword);                     { ждет 1/18 c ???}
procedure WaitWithKey(Tics:Longword);              { то же, только с опросом клавы }
function Distance(A,B:Pixel):integer;   { найдем дистанцию между A и B }
procedure ClearMap;                     { очистка игровой карты }
procedure PrintScreen;                  { вывод всей MAP на экран }
procedure ClearEKRANandMAP;				{ экран и карта должны различаться }
										{для корректной работы PrintScreen }

{////////////////// Р Е А Л И З А Ц И Я \\\\\\\\\\\\\\\\\\\\\\\\}
implementation

procedure ReFreshScreen;                { проца вывода карты на экран }
var       Pix:Pixel;
			x,y: integer;
begin
     WaitSync;
//     with Pix do
     for y:=1 to MaxY do
     for x:=1 to MaxX do
            if (EKRAN[y,x].Code<>MAP[StartY+y,StartX+x].Code)
         or
            (EKRAN[y,x].Attr<>MAP[StartY+y,StartX+x].Attr)
         then begin
              EKRAN[y,x].Code:=MAP[StartY+y,StartX+x].Code;
              EKRAN[y,x].Attr:=MAP[StartY+y,StartX+x].Attr;
			  Pix.Y := y;
			  Pix.X := x;
              PutPalSymbol(Pix,EKRAN[y,x],0)
          end
end {ReFreshScreen};
procedure NextCoor(var Coor:Pixel;Dir:word);
begin
     with Coor do begin
          case Dir of
          0:dec(y);     { NORTH }
          1:inc(x);     { EAST }
          2:inc(y);     { SOUTH }
          3:dec(x)      { WEST }
          end;
          if x<1 then x:=MAPX else
          if x>MAPX then x:=1;
          if y<1 then y:=MAPY else
          if y>MAPY then y:=1
     end
end;
procedure PrevCoor(var Coor:Pixel;Dir:word);
begin
     with Coor do begin
          case Dir of
          2:dec(y);     { NORTH }
          3:inc(x);     { EAST }
          0:inc(y);     { SOUTH }
          1:dec(x)      { WEST }
          end;
          if x<1 then x:=MAPX else
          if x>MAPX then x:=1;
          if y<1 then y:=MAPY else
          if y>MAPY then y:=1
     end

end;
procedure BackDir(var Dir:word);
begin
     Dir:=(Dir+2)and 3
end;
function ThisIsTheEdgeOfMap(LOC:Pixel):boolean;
begin
 ThisIsTheEdgeOfMap:= (LOC.y<1) or (LOC.y>MapY)
                      or (LOC.x<1) or (LOC.x>MapX)
end;
function CorCoor(Spot:Pixel):boolean;
begin
  CorCoor:= (MAP[Spot.y,Spot.x].Code=BLANK)
end;
function SGN(Value:integer):integer;
begin
     if Value<0 then SGN:=-1 else if Value>0 then SGN:=+1 else SGN:=0
end;
procedure NextEnhCoor(var Plot:Pixel;Dir:word);
begin
     case Dir of
          0:begin inc(Plot.x);dec(Plot.y) end;
          1:begin inc(Plot.x);inc(Plot.y) end;
          2:begin dec(Plot.x);inc(Plot.y) end;
          3:begin dec(Plot.x);dec(Plot.y) end
     end;
     if Plot.x<1 then Plot.X:=MAPX else
     if Plot.x>MAPX then Plot.X:=1;
     if Plot.y<1 then Plot.y:=MAPY else
     if Plot.y>MAPY then Plot.y:=1

end;
procedure PrevEnhCoor(var Plot:Pixel;Dir:word);
begin
     case Dir of
          2:begin inc(Plot.x);dec(Plot.y) end;
          3:begin inc(Plot.x);inc(Plot.y) end;
          0:begin dec(Plot.x);inc(Plot.y) end;
          1:begin dec(Plot.x);dec(Plot.y) end
     end;
     if Plot.x<1 then Plot.X:=MAPX else
     if Plot.x>MAPX then Plot.X:=1;
     if Plot.y<1 then Plot.y:=MAPY else
     if Plot.y>MAPY then Plot.y:=1

end;
procedure NewCoor(var Spot:Pixel;Dir:word);
{ Dir может быть от 0 до 7 - считается от севера по часовой стрелке }
const       deltaCoor:array[0..7] of Pixel = (
            (x:0;y:-1),(x:1;y:-1),(x:1;y:0),(x:1;y:1),
            (x:0;y:1),(x:-1;y:+1),(x:-1;y:0),(x:-1;y:-1));
begin
     Spot.x:=Spot.x+deltaCoor[Dir].x;
     Spot.y:=Spot.y+deltaCoor[Dir].y;
     if Spot.x<1 then Spot.x:=MapX else if Spot.x>MapX then Spot.x:=1;
     if Spot.y<1 then Spot.y:=MapY else if Spot.y>MapY then Spot.y:=1
end;

procedure Wait(Tics:Longword);
var Time:Longword;
begin
	Time:=WhatTime+Tics*TimeZoom;
	while WhatTime<Time do
end;

procedure WaitWithKey(Tics:Longword);
var Time:Longword;
begin
	Time:=WhatTime+Tics*TimeZoom;
   Inkey;// сбросим клавишу
	while (InKey=0) and (WhatTime<Time) do ;{ пустой оператор }
end;

function Distance(A,B:Pixel):integer;
var      dx,dy:integer;
         sq:real;
begin
     dx:=(A.x-B.x)*(A.x-B.x);
     dy:=(A.y-B.y)*(A.y-B.y);
     sq:=(dx+dy);
     Distance:=Round(sqrt(sq)+0.5)
end;

function IsInMap(LOC:Pixel):boolean;
begin
     with LOC do IsInMap:=(x>=1)and(x<=MapX)and(y>=1)and(y<=MapY)
end;

procedure ClearMap;var x,y:integer;
begin
     for y:=1 to MapY do for x:=1 to MapX do MAP[y,x]:=SPACE
end;

procedure PrintScreen;
var
	A:Pixel;
	x,y:integer;
begin
     WaitSync;
     for y:=1 to MaxY do
         for x:=1 to MaxX do begin
         	 A.Y := y; A.X := x;
           if EKRAN[y,x].Code<>MAP[y,x].Code then
           // выводим только измененный символ! - old way. 
					 // now мы выводим всю карту целиком
           //begin
							EKRAN[y,x]:=MAP[y,x];
					PutPalSymbol(A,EKRAN[y,x],0);
           // end;
         end;
     // gdwSwapBuf;
end{PrintScreen};

procedure ClearEKRANandMAP;
{ экран и карта должны различаться для корректной работы PrintScreen }
var
	x,y:integer;
begin
     for y:=1 to MaxY do
         for x:=1 to MaxX do begin
					EKRAN[y,x].Code:=511;
					MAP[y,x].Code:=32;
     end;
end{ClearEKRANandMAP};


end.
