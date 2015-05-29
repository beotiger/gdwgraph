Unit UMan;
{	Переделанная с QuickBasic'а игра MAN - бегают человечки		}
{ на Дельфи-7, используя библиотеку gdwGraph для режима VGA-13, }
{ адаптированного под обычное окно Windows						}
interface

procedure Main;

{	ВНИМАНИЕ! Программа выходит без предупреждения,				}
{ 	если при старте не может прочитать файл MAN.CHR 			}

implementation

uses SDLglGDWGraph, SysUtils, sdl;

const GAMESPEED = 25; // скорость игры, потом лучше по тикам подсчитать?

{ Такой список forward процедур - наследие QBasic'a }
procedure PutMessage;forward;

procedure DirectaMan(N:integer);forward;

function FreeNumber:integer;forward;
function WhichNumber(x, y, N:integer):integer;forward;
function WhichBoss (x, y:integer):integer;forward;

//procedure DoKeys(N:integer);forward;
procedure AI;forward;
procedure ManAI(N:integer);forward;
procedure WeaponFly(N:integer);forward;
procedure MoveButt(N:integer);forward;			// ПОЛЁТ БАБОЧКИ

procedure EdenCapWell;forward;
procedure WriteBoard;forward;
procedure WriteInitBoard;forward;
procedure GameOver;forward;

procedure PutBoss(B:integer);forward;
//procedure SetBoss (x, y:integer; CODE:word; ATTR:byte);forward;
procedure BossAI(B:integer);forward;
procedure ResetBoss (B:integer);forward;
procedure BossButt(x,y:integer;Attr:byte);forward;
procedure BOSSMan(x,y:integer;Attr:byte);forward;

procedure RestoreScreen (xl, yu, xr, yd:integer);forward;
procedure Ramka (xl, yu, xr, yd:integer);forward;
procedure SaveScreen (xUp, yUp, xDwn, yDwn:integer);forward;
procedure RepeatSymbol (x, y:integer; CODE:word; ATTR:byte;number:integer);forward;

procedure Game;forward;
procedure GetReady;forward;

procedure MainMenu(var fExit:boolean);forward;
procedure FirstInit;forward;
procedure OpenLevel;forward;
procedure ReadLevel;forward;
procedure OutPutLevel(N:string);forward;
procedure PrintGameMap;forward;

{ ЦВЕТА }
const BLACK = 0; BLUE = 1; GREEN = 2; CYAN = 3; RED = 4; MAGENTA = 5; BROWN = 6; WHITE = 7;
		GREY = 8; LIGHTBLUE = 9; LIGHTGREEN = 10; LIGHTCYAN = 11; LIGHTRED = 12;
         LIGHTMAGENTA = 13; YELLOW = 14; LIGHTWHITE = 15;

{ СИМВОЛЫ }
const SKULL = 128; WEAPON = 129; TEN = 130; APPLE = 131; CROSS = 132;
		TREE = 133; HEART = 134; BRICK = 135; STAIR = 136; TREASURE = 166; MAN = 144; MANR = 146;
		MANL = 149; MANUD = 141; UPLINE = 171; EMPTY = 178; STAR = 42; GRAVE = 157;
        STAND_MAN = 144;	// стоящий человечек
        BUTT1 = 183; BUTT2 = 182;	// бабочка из HERO (nice Apple2 game)
        BUTT_DEF_COLOR = 90; BUTT_SPEED = 5;

{ коды спец.объектов }
const	VID_CAVE = 207; VID_HOUSE = 211;
		CAVE_CLOSED = 201; HOUSE_CLOSED = 202;	// коды для закрытых span-objects


{ коды боссов }
CONST
    EMPTY_BOSS = 252;	// невидимый БОСС
		LTOOTHED = 215; SKELETON = 240; GIANT = 223;
		coBOSS = 215;
		// codes for GIANT
		GIANT_RIGHT = GIANT;
		GIANT_LEFT = 184;

		GIANT_RIGHT_CODES:array[0..2] of word = (GIANT_RIGHT, 196, 236);
		GIANT_LEFT_CODES:array[0..2] of word = (GIANT_LEFT,GIANT_LEFT+4, GIANT_LEFT+8);

		GIANT_DEAD1 = {227}228; GIANT_DEAD2 = {231}232;	// dying giant
		GIANT_DEAD_CODES:array[0..1] of word = (GIANT_DEAD1,GIANT_DEAD2);

		SKELETON_CODES:array[0..2] of word = (SKELETON,SKELETON+4,SKELETON+8);

CONST // more...
		MaxThing = 100;	// максимально кол-во движимых объектов на уровне
		MaxBoss = 10; // also for bosses
		MaxEYE  = 20;	// ?? для убегания человечков от стрел
		MaxHP = 50;	// для человечков HP
		MAX_SPAWN_OBJECTS = 12;	// макс.кол-во рождающихся объектов

		MapY = 20; MapX = 40;	// размер карты уровня по вертикали и горизонтали

		NOTHING: Symbol = (Code:EMPTY; Attr:WHITE);
		WH_SKULL: Symbol = (Code:SKULL; Attr:WHITE);
		SYM_HEART: Symbol = (Code:HEART; Attr:37);
	
	// максимальный номер уровня определяется в начале
	// по кол-ву файлов LEVELx.MAN, где x - целое число

var
  MaxLevel: integer = 0;
	
  INTRO, MAP, EKRAN: array [1..MapY, 1..MapX] of Symbol;// для карты и экрана

	EKR: array of Symbol; { динамически массив? КРУТО! }
	loct: Pixel;	// для locate - курсор
	colt: byte;		// для scolor - цвет символов

	Level, NextLevel, PlayerDeath, Cycles:integer;
  MaxAvThing : integer;	// кол-во подвижныйх объектов на карте
	Weapons: array[1..2,1..3] of integer;
    Pl1HP,Pl2HP: integer;	// hit points for players

	MU:array[1..4] of integer;
	MF:array[1..2] of integer;

    Player1, Player2: integer;	// # in thing of Players
	// для порталов
const	MaxPortals = 10;	PORTAL1 = 205; PORTAL2 = 206;// коды порталов в ьаблице символов (низ)
var
	Portals:integer;	// число порталов в уровне
	Portals1,Portals2:array[1..MaxPortals] of Pixel;	// Pixel is a structure from GDWGraph = x,y:integer

const
	Pl1Keys:array[1..6] of word = (SDLK_SPACE, SDLK_RETURN, SDLK_UP, SDLK_LEFT, SDLK_RIGHT, SDLK_DOWN);
    Pl2Keys:array[1..6] of word = (SDLK_q, SDLK_e, SDLK_w, SDLK_a, SDLK_d, SDLK_s);
    NumOfPlayers : byte = 1; // число игроков
	DblMode : boolean = false;	// Double Mode for F5 key pressing

TYPE
	MANObject=record
		 x : INTEGER;
		 y : INTEGER;
		 xOld : INTEGER;
		 yOld : INTEGER;
		 VID : SYMBOL;
		 pVID : SYMBOL;
		 HP : INTEGER;
		 GUN : INTEGER;
		 SPD : INTEGER;
		 STEPS : INTEGER;
		 FLSTEPS : INTEGER;
		 the : INTEGER;
		 CODE : INTEGER;
		 dirx : INTEGER;
		 diry : INTEGER;
		 charge : INTEGER;
		 behave : INTEGER;
		 stamina : INTEGER;
         keys:word;
         Cycles : INTEGER;
	END;

var thing:array[1..MaxThing] of MANObject;

TYPE
	OBOSS=record
		 x : INTEGER;
		 y : INTEGER;
		 xOld : INTEGER;
		 yOld : INTEGER;
		 HP : INTEGER;
		 VID : SYMBOL;
		 dirx : INTEGER;
		 diry : INTEGER;
		 CODE : INTEGER;
		 charge : INTEGER;
		 behave : INTEGER;
		 pain : INTEGER;
		 SPD : INTEGER;	// speed
		 Stamina: INTEGER;	// ВЫДЕРЖКА!
		 Cycles : INTEGER;	// циклы
		 tag : INTEGER;		// для общих целей
	END;

var
	tBOSS:array[1..MaxBoss] of OBOSS;
	EYE:array[1..MaxEYE] of integer;
	{ таймер отсчета       }
	GloTimer:Longword;

// таблица символов игры MAN
const SymFileName = 'MAN.CHR';

procedure Main;
var i: integer;
		F:file;
		FileName:string;
		
begin					{///////////////MAIN\\\\\\\\\\\\\}
	MU[1] := 141; MU[2] := 143; MU[3] := 144; MU[4] := 145;
	MF[1] := 143; MF[2] := 145;
	
	if LoadSymData(SymFileName)<>0 then begin
		writeln('Could not find ' + SymFileName + ' file. Quitting..');
		halt(255);
	end;

	// ищем уровни LEVEL1.MAN, LEVEL2.MAN и т.д.
{$I-}	
	i := 1;

	while true do
  begin
		FileName := 'LEVEL' + IntToStr(i) + '.MAN';
		Assign(F,FileName);
		Reset(F, 1);
		if IOResult <> 0 then break;
		Close(F);
		
		MaxLevel := i;
		inc(i);
	end;
{$I+}
	if MaxLevel < 1 then begin
		writeln('Could not find levels files. We should have at least "LEVEL1.MAN" to play. Quitting..');
		halt(254);
	end;

	writeln('MAN started. MaxLevel = ' + IntToStr(MaxLevel));

	InitGraph('MAN | How to be a real MAN?');	// инициализируем графику

	PutMessage;
	
	Game;
	CloseGraph;
  halt;
end;                    {//////////////MAIN\\\\\\\\\\\\\\\}

// перегруженный большой символ
procedure PutBigSymbol(x, y:integer; CODE:word; ATTR:byte;Wid, Height:integer; Oper:byte);overload;
var LOC:Pixel;ID:Symbol;
begin
	LOC.x:=x;
	LOC.y:=y;
	ID.Code:=CODE;
	ID.Attr:=ATTR;
	PutBigSymbol(LOC, ID, Oper, Wid, Height)
end;


procedure Locate(Y,X:byte); // установить курсор в позицию Y (row), X (column) для процы MYPRINT
begin	// y = 1..25, x = 1..40
	loct.X := X;
	loct.Y := Y;
end;

procedure SColor(c:byte);	// устновим цвет рисовангия для процы MYPRINT
begin
	colt := c;
end;
	
procedure MYPRINT(S:string);
begin	// выводим строку белым цветом
	PutString(loct,S,colt,0);
//	loct.X := loct.X + Length(S);
	loct.X := 1;						// [CR] CARRIAGE RETURN
	if loct.Y < 25 then inc(loct.Y);	// [LF] LINE FEED
end;

procedure Wait(Tics:Longword);		// задержка в 1/18 секунды с учётом timezoom'a
var Time:Longword;
begin
	Time:=WhatTime+Tics*TimeZoom;
	while WhatTime<Time do
end;

function WaitWithKey(Tics:Longword):word;	// ждем Tics тиков или нажатия клавиши
var Time:Longword;Key:word;
begin
	Time:=WhatTime+Tics*TimeZoom;
    Key:=Inkey;// сбросим клавишу

    while (Key = 0) and (WhatTime<Time) do Key := Inkey;{ пустой оператор }
	WaitWithKey := Key;
end;

function Distance(Ax,Ay,Bx,By:integer):integer;	// высчитываем дистанцию между 2 точками
var      dx,dy:integer;
         sq:single;
begin
     dx:=(Ax-Bx)*(Ax-Bx);
     dy:=(Ay-By)*(Ay-By);
     sq:=(dx+dy);
     Distance:=Round(sqrt(sq)+0.5)
end;
////////////////////////////////////////////////////////////////////////////////
procedure PutMessage;	// выведем устрашающую надпись

const Tics = 280;	// сколько ждать?

var Time: Longword;
		Key: word;

begin
//	ClearDevice;
	Time := WhatTime + Tics * TimeZoom;
  Key := Inkey;	// сбросим клавишу

	while (Key = 0) and (WhatTime < Time) do 
	begin
		Key := Inkey;{ пустой оператор }

		LOCATE(5,1);
		SCOLOR(RED);
		MYPRINT ('ATTENTION!');
			MYPRINT ('');
			SCOLOR(WHITE);
			MYPRINT ('This is the SHAREWARE version.');
		MYPRINT ('All rights for distribution this game ');
			MYPRINT ('through BBS''s been given to KYRANDIA corp.');
			MYPRINT ('');
		MYPRINT ('To order commercial release or to');
			MYPRINT ('register this game call Kyrandia BBS.');
			MYPRINT ('');
			SCOLOR(GREEN);
		MYPRINT ('(C)opyright Volgograd-98,2011');
			MYPRINT ('   by Grendel Dragon Wizard');
		MYPRINT ('');
{
		MYPRINT ('ВНИМАНИЕ! Это пробная версия.');
		MYPRINT ('Все права на распространение этой игры через ББС переданы Кирандия корп.');
		MYPRINT ('Чтобы зарегистрировать данную программу, обращайтесь к Кирандия ББС.');
		MYPRINT (' Волгоград-98 by Grendel Dragon Wizard');
}
		gdwSwapBuf;
	end;

// old approach:    WaitWithKey(280);
END;
///////////////////////////////////////////////////////////////////////////////
procedure CloseWindow (lx, uy, rx, dy:integer);
begin
	RestoreScreen(lx, uy, rx, dy)
end;

procedure CreateWindow (lx, uy, rx, dy:integer);
begin
 SaveScreen(lx, uy, rx, dy);
 Ramka(lx, uy, rx, dy);
END;
///////////////////////////////////////////////////////////////////////////////
procedure Keyboard;
var	i,x,y:integer;
	Key,modif:word;
begin
  Key:=EInkey(modif);
  if Key<>0 then begin
	 for i := 1 TO 6 do begin
		  if (Key = Pl1Keys[i]) AND (Player1 > 0) then begin thing[Player1].keys := i; exit end;
          if (Key = Pl2Keys[i]) AND (Player2 > 0) then begin thing[Player2].keys := i; exit end;
     end;

	 if Key = SDLK_ESCAPE then PlayerDeath := 0;	// конец игры / выход
	 if	(Key = SDLK_TAB) and
     	 (modif and KMOD_SHIFT <> 0) then NextLevel := 0;	// переход на след.уровень? Shift+TAB
     if Key = SDLK_F10 then begin CloseGraph;halt end;	// fast exit
	 if (Key = SDLK_F5) and (NumOfPlayers < 2) then
	 begin
		DblMode := not DblMode;
		if not DblMode then
			for y:=1 to MapY do
				for x:=1 to MapX do
					EKRAN[y,x].Code := 511;	// clear ekran for reputtin map level
	 end; { if Key = F5 }
     if Key = SDLK_F1 then	// PAUSE
     begin
     	Key:=0;
        while Key = 0 do Key:=Inkey;	// some sort of pause
     end;
  end;
end;//Keyboard
//////////////////////////////////////////////////////////////////////////////
procedure MoveSpawn(N:integer);			// ПОЛЁТ ОРУЖИЯ
// CODE == 4 - spawn butterflies, 5 - spawn men?
const MEN_ATTRS:array[0..4] of byte = (RED, CYAN, MAGENTA, BROWN, BLUE);
begin
	if(Cycles MOD thing[N].SPD) <> 0 then exit;

    if thing[N].HP <= 0 then
    begin
     if thing[N].CODE = 4 then
     begin
     	PutSymbol(thing[N].x,thing[N].y,CAVE_CLOSED,thing[N].VID.Attr,0);
        MAP[thing[N].y,thing[N].x].Code := CAVE_CLOSED;
     end
     else // CODE == 5 should be, house closed
     begin
     	PutSymbol(thing[N].x,thing[N].y,HOUSE_CLOSED,thing[N].VID.Attr,0);
        MAP[thing[N].y,thing[N].x].Code := HOUSE_CLOSED;
     end;
     thing[N].CODE:=0;
     exit
    end;// butterfly is DEAD?

    inc(thing[N].Cycles);
    if Random(12) > 2 then exit;	// till next time
    // spawn object?
    if thing[N].CODE = 4 then
    	BossButt(thing[N].x,thing[N].y,BUTT_DEF_COLOR + Random(10)) // цвет случайный?
    else
    	// породить человечка?
        BOSSMan(thing[N].x,thing[N].y,MEN_ATTRS[Random(5)]);
	inc(thing[N].charge);
    if thing[N].charge > MAX_SPAWN_OBJECTS then thing[N].HP := 0;	// auto-closing
end;
//////////////////////////////////////////////////////////////////////////////
procedure AI;
var i:integer;
begin
 FOR i := 1 TO MaxAvThing do	// NOTE: MaxAvThing instead of MaxThing!
  IF thing[i].CODE = 1 THEN begin
    ManAI(i);
    DirectaMan(i);
  end
  ELSE IF thing[i].CODE = 2 THEN  WeaponFly(i)	// двигаем оружие - стрелы, топоры, ножи и т.п.
  ELSE IF thing[i].CODE = 3 THEN  MoveButt(i)	// двигаем бабочку
  ELSE IF (thing[i].CODE = 4) or (thing[i].CODE = 5) THEN  MoveSpawn(i);	// spawn object
// решаем за боссов!
 FOR i := 1 TO MaxBoss do
  IF tBOSS[i].CODE > 0 THEN  BossAI(i);
END;
////////////////////////////////////////////////////////////////////////////////
procedure FillWeapon(x,y,DIR,GUN:integer);	// возникновение оружия!
var NW:integer;
begin
	if MAP[y,x + DIR].Code = BRICK then exit;	// can't shoot through bricks!
 NW := FreeNumber;
 IF NW = 0 THEN exit;
 thing[NW].GUN := GUN;//thing[N].GUN;
 thing[NW].x := x + DIR;//thing[N].x + DIR;
 thing[NW].y := y;//thing[N].y;
 thing[NW].xOld := thing[NW].x;
 thing[NW].yOld := thing[NW].y;
 thing[NW].dirx := DIR;
 thing[NW].CODE := 2;		// internal code of object is WEAPON (1-man,2-weapon,3-butterfly by now)
 case  thing[NW].GUN of
  1: begin                                 // ARROW
	  thing[NW].HP := 1; thing[NW].SPD := 2;	// FAST SPEED
	  IF DIR < 0 THEN thing[NW].VID.CODE := 137 ELSE thing[NW].VID.CODE := 153;
	 end;
  2: begin
	  thing[NW].HP := 2; thing[NW].SPD := 3; // FORKS
	  IF DIR < 0 THEN thing[NW].VID.CODE := 152 ELSE thing[NW].VID.CODE := 156;
	 end;
  3: begin
	  thing[NW].HP := 5; thing[NW].SPD := 4;	// HAMMER
	  IF DIR < 0 THEN thing[NW].VID.CODE := 138 ELSE thing[NW].VID.CODE := 154;
	 end;
  4: begin
	  thing[NW].HP := 3; thing[NW].SPD := 3;	// KNIFE
	  IF DIR < 0 THEN thing[NW].VID.CODE := 139 ELSE thing[NW].VID.CODE := 155;
	 end;
  5: begin
	  thing[NW].HP := 10; thing[NW].SPD := 2;	// FAST Hor.SKULL
	  IF DIR < 0 THEN thing[NW].VID.CODE := 181 ELSE thing[NW].VID.CODE := 180;
	 end;
 END;//case
 thing[NW].VID.ATTR := 7;
//		 thing[NW].pVID := MAP[thing[NW].y, thing[NW].x];
end;  { FillWeapon }
////////////////////////////////////////////////////////////////////////////////
procedure BossButt(x,y:integer;Attr:byte);
var N:integer;
// пробуем создать здесь бабочку (по умолчанию летит вверх)
begin
	if MAP[y,x].Code = BRICK then exit;
	N:=FreeNumber;
    if N = 0 then exit;	// no free numbers left?
		 thing[N].x := x;
		 thing[N].y := y;
		 thing[N].xOld := x;
		 thing[N].yOld := y;
		 thing[N].VID.Code := BUTT1;
		 thing[N].VID.Attr := Attr;
		 thing[N].dirx := 1;	// DX
		 thing[N].diry := -1;   // DY
         if random(10) < 5 then thing[N].dirx := -1;
		 thing[N].Cycles := 0;
         thing[N].SPD := BUTT_SPEED;	// fast
		 thing[N].HP := 1; // HP LOW
		 thing[N].CODE := 3;	// КОД ОБЪЕКТА - БАБОЧКА!
end;
////////////////////////////////////////////////////////////////////////////////
// появляется человечек
procedure BOSSMan(x,y:integer;Attr:byte);
var N:integer;
begin
	N:=FreeNumber;
    if N = 0 then exit;	// no free numbers left?

	CASE Attr of	// оружие человечка зависит от его ЦВЕТА!!
			 RED: begin thing[N].SPD := 8;thing[N].HP := 2; thing[N].GUN := 1; end;// стрелы
			 CYAN: begin thing[N].SPD := 9;thing[N].HP := 4; thing[N].GUN := 2; end;// вилы
			 MAGENTA: begin thing[N].SPD := 10;thing[N].HP := 6; thing[N].GUN := 3; end;//топоры
			 BROWN: begin thing[N].SPD := 9;thing[N].HP := 8; thing[N].GUN := 4; end;// ножики, ха!
			 BLUE: begin thing[N].SPD := 6;thing[N].HP := 10; thing[N].GUN := 5; end;//черепо-кидатель
             ELSE begin thing[N].SPD := 8;thing[N].HP := 2; thing[N].GUN := 1; end; // другой цвет не используем
	 END;//case
     
		 thing[N].x := x;
		 thing[N].y := y;
		 thing[N].xOld := x;
		 thing[N].yOld := y;
		 thing[N].VID.Code := STAND_MAN{144};
         thing[N].VID.Attr := Attr;

		 thing[N].behave := 0;
		 thing[N].FLSTEPS := 0;
		 thing[N].STEPS := 0;
		 thing[N].the := 0;
		 thing[N].charge := 0;
		 thing[N].CODE := 1;
end;
////////////////////////////////////////////////////////////////////////////////
function CanMove(x,y:integer):boolean;	// if Boss can move to x,y - no bricks, or empty below
begin
	IF     (MAP[y + 0,x].CODE = BRICK)
		OR (MAP[y + 1,x].CODE = BRICK)
		OR ((y<MapY-1) AND (MAP[y + 2,x].CODE = EMPTY)) THEN Result:=False
    ELSE Result := True;
end;
////////////////////////////////////////////////////////////////////////////////
procedure BossAI(B:integer);
var i,x,y,TargetM:integer;

	function TryToShoot(GUN:integer = 0):boolean;// пробуем стрелять Гигантом или Скелетоном
    // true - if has had shoot!
    begin
    	Result := false;
        if Random(10) > 2 then exit;	// not ever shooting!
		if GUN = 0 then GUN := Random(4)+1;	// 1..4           
    	if tBOSS[B].dirx = 1 then	// try to shoot left
        begin
			if tBOSS[B].x = 1 then exit;	// edge
            if ((Player1 > 0) and (thing[Player1].HP > 0) and (tBOSS[B].x > thing[Player1].x)
            	and (abs(thing[Player1].y -tBOSS[B].y) < 4))
	                or
               ((Player2 > 0) and (thing[Player2].HP > 0) and (tBOSS[B].x > thing[Player2].x)
   	        	and (abs(thing[Player2].y - tBOSS[B].y) < 4))
            then	begin
						FillWeapon(tBOSS[B].x,tBOSS[B].y + Random(2), -1, GUN);// SHOOOOOOOOOOOOOT!
						Result:=true;
					end;
        end
        else // try to shoot right
        begin
            if tBOSS[B].x = MapX - 1 then exit;	// edge
            if ((Player1 > 0) and (thing[Player1].HP > 0) and ((tBOSS[B].x + 1) < thing[Player1].x)
            	and (abs(thing[Player1].y -tBOSS[B].y) < 4))
	                or
               ((Player2 > 0) and (thing[Player2].HP > 0) and ((tBOSS[B].x + 1) < thing[Player2].x)
   	        	and (abs(thing[Player2].y - tBOSS[B].y) < 4))
            then	begin
						FillWeapon(tBOSS[B].x+1,tBOSS[B].y + Random(2), 1, GUN);// SHOOOOOOOOOOOOOT!
						Result:=true;
					end;
        end;
    end;

    function ChooseTarget:integer;	// выбор игрока для преследования
    var TargetM:integer;
    begin
    	TargetM := 0;
	    if (Player1 > 0) and (Player2 > 0) then
	    begin // живы оба игрока
			if  Distance(thing[Player1].x,thing[Player1].y,tBOSS[B].x,tBOSS[B].y)
	        	 <
		        Distance(thing[Player2].x,thing[Player2].y,tBOSS[B].x,tBOSS[B].y)
	        then TargetM := Player1 else TargetM := Player2; // мишень - ближайший игрок
	        if thing[Player1].HP < 1 then TargetM := Player2;
			if thing[Player2].HP < 1 then TargetM := Player1;
	    end
	    else
	    begin
	    	if Player1 > 0 then TargetM := Player1
		        else if Player2 > 0 then TargetM := Player2;
	    end;
        Result := TargetM;
	end; { ChooseTarget }
begin { BossAI }
 if NextLevel <> 0 then NextLevel := 240;		// not end of LEVEL
 IF (Cycles MOD tBoss[B].SPD) <> 0 THEN EXIT; // СКОРОСТЬ БОССА

 if tBOSS[B].Stamina > 0 then dec(tBOSS[B].Stamina);
 if tBOSS[B].charge > 0 then dec(tBOSS[B].charge);
 inc(tBOSS[B].Cycles);	// циклы босса++

 CASE  tBOSS[B].CODE of
 ///////////////////////////////////////  LTOOTHED
  1: //LTOOTHED;
  begin
  		if (tBOSS[B].Stamina = 0) AND (tBOSS[B].charge = 0) AND (random(12) < 1) then
        	tBOSS[B].charge := random(8)+5;// БОСС исчез!
	  IF tBOSS[B].HP <= 0 THEN begin	// boss is dying
			ResetBoss(B);
		   IF tBOSS[B].x > 1 THEN x := tBOSS[B].x - 1 ELSE x := 1;
		   IF x + 3 > 40 THEN x := 37;
		   tBOSS[B].CODE := 0;
		   IF MAP[tBOSS[B].y + 1, x].CODE = EMPTY THEN MAP[tBOSS[B].y + 1, x]:=WH_SKULL;//white skull
           // PutSymbol(x, tBOSS[B].y + 1, SKULL, 7,0);
		   FOR i := x + 1 TO x + 3 do
				IF (MAP[tBOSS[B].y + 1, i].CODE = EMPTY) AND (random < 0.67) THEN begin
		                MAP[tBOSS[B].y + 1, i] := SYM_HEART;	// сердечки
//					  PutSymbol(i, tBOSS[B].y + 1, HEART, 37,0);
//					 MAP[tBOSS[B].y + 1, i].CODE := HEART;
				END;//if
		   EXIT;
	  END;

	  CASE  tBOSS[B].behave of
	   1:
	   begin
		   IF tBOSS[B].x = 1 THEN begin tBOSS[B].behave := 2; tBOSS[B].Stamina:=random(10)+2; EXIT end;
		   IF not CanMove(tBOSS[B].x-1,tBOSS[B].y){(MAP[tBOSS[B].y, tBOSS[B].x - 1].CODE = BRICK)
				OR (MAP[tBOSS[B].y + 1, tBOSS[B].x - 1].CODE = BRICK)
				OR (MAP[tBOSS[B].y + 2, tBOSS[B].x - 1].CODE = EMPTY)} THEN
                begin
                	tBOSS[B].behave := 2;
                    tBOSS[B].Stamina:=random(10)+2;
                    EXIT
                end;
           IF (tBoss[B].Stamina = 0) AND (random(10) < 1) then
           	begin tBOSS[B].behave := 2;tBOSS[B].Stamina:=random(10)+2; EXIT end;
		   tBOSS[B].x := tBOSS[B].x - 1;
           if(tBOSS[B].charge = 0) then
			   tBOSS[B].VID.CODE := LTOOTHED + 4
           else tBOSS[B].VID.CODE := EMPTY_BOSS;
		end;
	   2:
	   begin
		   IF tBOSS[B].x = 39 THEN begin tBOSS[B].behave := 1;tBOSS[B].Stamina:=random(10)+2; EXIT end;
		   IF not CanMove(tBOSS[B].x+2,tBOSS[B].y){(MAP[tBOSS[B].y, tBOSS[B].x + 2].CODE = BRICK)
				OR (MAP[tBOSS[B].y + 1, tBOSS[B].x + 2].CODE = BRICK)
				OR (MAP[tBOSS[B].y + 2, tBOSS[B].x + 2].CODE = EMPTY)} THEN
                	begin tBOSS[B].behave := 1;tBOSS[B].Stamina:=random(10)+2; EXIT end;
           IF (tBoss[B].Stamina = 0) AND (random(10) < 1) then 	// разворот (неожиданный)
           	 begin tBOSS[B].behave := 1;tBOSS[B].Stamina:=random(10)+2; EXIT end;
		   tBOSS[B].x := tBOSS[B].x + 1;
		   if(tBOSS[B].charge = 0) then
           		tBOSS[B].VID.CODE := LTOOTHED
           else tBOSS[B].VID.CODE := EMPTY_BOSS;
		 end;//case 2
	   END // case behave
   end;// case LTOOTHED
   /////////////////////////////////////////  GIANT
   2:	// GIANT
   	BEGIN
   	  IF (tBOSS[B].HP <= 0) and (tBOSS[B].behave <> 3) THEN
      begin	// boss is dying
      	tBOSS[B].behave:=3;
        tBOSS[B].Stamina := 16;
        exit
      end;
      i := Random(8)+8;      // ПОИГРАТЬСЯ!
      CASE tBOSS[B].behave of
      0: begin
            if tBOSS[B].dirx = 2 then tBOSS[B].VID.Code:=GIANT_RIGHT	// looking right
            	else tBOSS[B].VID.Code:=GIANT_LEFT;	// looking left
      		if tBOSS[B].Stamina > 0 then
      		begin
            	TryToShoot;	// пробуем выстрелить
                exit;
            end;
      	if random(5) < 1 then begin tBOSS[B].Stamina:=i;exit end;//ещё постоит?
   // TryToMove
      	TargetM := ChooseTarget;
// преимущество движения - в направлении таргета
		if tBOSS[B].x = 1 then begin tBOSS[B].behave:=2;tBOSS[B].Stamina:=i; exit end; 	// at the edge of screen
		if tBOSS[B].x = 39 then begin tBOSS[B].behave:=1;tBOSS[B].Stamina:=i; exit end;

        if TargetM = 0 then exit;	// no player to chase
         // dirx of Boss - 2 ->, 1 <-
		if (thing[TargetM].x < tBOSS[B].x) and CanMove(tBOSS[B].x-1,tBOSS[B].y) then
        	begin tBOSS[B].behave:=1;tBOSS[B].Stamina:=i; exit end;	// to the left
        if CanMove(tBOSS[B].x+2,tBOSS[B].y) then
                	begin tBOSS[B].behave:=2;tBOSS[B].Stamina:=i; exit end;	// to the right
       end; // behave == 0
       1: // moving left
       begin
	       tBOSS[B].dirx := 1;
			if (tBOSS[B].Stamina = 0) or (tBOSS[B].x = 1) then
            	begin tBOSS[B].behave:=0;tBOSS[B].Stamina:=i; exit end;
            if TryToShoot then exit;	// выстрелил - всё
            if CanMove(tBOSS[B].x-1,tBOSS[B].y) then tBOSS[B].x := tBOSS[B].x - 1;
            tBOSS[B].VID.Code := GIANT_LEFT_CODES[tBOSS[B].Cycles mod 3];
       end;
       2: // moving right
       begin
       		tBOSS[B].dirx := 2;
			if (tBOSS[B].Stamina = 0) or (tBOSS[B].x = 39) then
            	begin tBOSS[B].behave:=0;tBOSS[B].Stamina:=i; exit end;
            if TryToShoot then exit;	// выстрелил - всё
            if CanMove(tBOSS[B].x+2,tBOSS[B].y) then tBOSS[B].x := tBOSS[B].x + 1;
            tBOSS[B].VID.Code := GIANT_RIGHT_CODES[tBOSS[B].Cycles mod 3];
       end;
       3:	// dying
       begin
       		if tBOSS[B].Stamina <= 0 then	// is DEAD really
            begin
				ResetBoss(B);
            	tBOSS[B].CODE := 0;
            	exit;
            end;
			tBOSS[B].VID.Code := GIANT_DEAD_CODES[tBOSS[B].Stamina and 1];
       end;// case 3
     end // case behave
   END; // CASE GIANT
   /////////////////////////////////////////  SKELETON
   3:	// SKELETON
	BEGIN
   	  IF (tBOSS[B].HP <= 0) and (tBOSS[B].behave <> 8) THEN
      begin	// boss is dying
      	tBOSS[B].behave:=8;
        tBOSS[B].Stamina := 10;
        exit;
      end;
      tBOSS[B].VID.Code := SKELETON_CODES[tBOSS[B].Cycles mod 3]; // меняем вид босса каждый цикл
      i := Random(3)+4;      // ПОИГРАТЬСЯ!
      x:=tBOSS[B].x;
      y:=tBOSS[B].y;
      CASE tBOSS[B].behave of
      0:
      begin
   		if tBOSS[B].Stamina > 0 then
      		begin
            	if (TryToShoot(5)) or (Random(10)>1) then exit;	// пробуем выстрелить
				if (y>1) and (tBOSS[B].tag<5) then // BOSS не может выпустить более 5 бабочек
                begin
                	BossButt(x+Random(2),y-1,BUTT_DEF_COLOR+Random(10));
                    inc(tBOSS[B].tag);
                end;
                exit;
            end;
        tBOSS[B].Stamina:=i;
      	if Random(5) < 1 then begin tBOSS[B].behave:=5;exit end;//прыжок вверх
        if Random(10) < 3 then begin tBOSS[B].behave:=Random(2)+1; exit end;
      	TargetM := ChooseTarget;
// преимущество движения - в направлении таргета
		if tBOSS[B].x = 1 then begin tBOSS[B].behave:=2; exit end; 	// at the edge of screen
		if tBOSS[B].x = 39 then begin tBOSS[B].behave:=1; exit end;
        if TargetM = 0 then exit;	// no player to chase
         // dirx of Boss - 2 ->, 1 <-
		if (thing[TargetM].x < tBOSS[B].x) then	tBOSS[B].behave:=1	// to the left
        	else if thing[TargetM].x > tBOSS[B].x+1 then tBOSS[B].behave:=2
        else tBOSS[B].behave:=Random(2)+1;
      end;	// case 0
      1:
      begin	// ПРЫЖОК ВВЕРХ И ВЛЕВО!
	       tBOSS[B].dirx := 1;
		   if (tBOSS[B].Stamina = 0) or (tBOSS[B].x = 1) or (tBOSS[B].y = 1) then
            	begin tBOSS[B].behave:=3;exit end;	// падаем вниз обратно
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y-1,x-1].Code = BRICK) or (MAP[y-1,x].Code = BRICK)
           	or (MAP[y,x-1].Code = BRICK)
           then tBOSS[B].behave:=3	// вниз падаем
           else begin
           	tBOSS[B].x := x - 1;	// big jump up-left
            tBOSS[B].y := y - 1;
           end;
      end;
      2:
      begin	// ПРЫЖОК ВВЕРХ И ВПРАВО!
	       tBOSS[B].dirx := 2;
		   if (tBOSS[B].Stamina = 0) or (tBOSS[B].x = MapX - 1) or (tBOSS[B].y = 1) then
            	begin tBOSS[B].behave:=4;exit end;	// падаем вниз обратно
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y-1,x+1].Code = BRICK) or (MAP[y-1,x+2].Code = BRICK)
           	or (MAP[y,x+2].Code = BRICK)
           then tBOSS[B].behave:=4	// вниз падаем
           else begin
           	tBOSS[B].x := x + 1;	// big jump up-right
            tBOSS[B].y := y - 1;
           end;
      end;
      3:
      begin	// ПРЫЖОК ВНИЗ И ВЛЕВО!
	       tBOSS[B].dirx := 1;
		   if (tBOSS[B].x = 1) or (tBOSS[B].y = MapY - 1) then
            	begin tBOSS[B].behave:=6;exit end;	// падаем вниз прямо
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y+2,x-1].Code = BRICK) or (MAP[y+1,x-1].Code = BRICK)
           	or (MAP[y+2,x].Code = BRICK)
           then tBOSS[B].behave:=6	// вниз падаем
           else begin
           	tBOSS[B].x := x - 1;	// jump down-left
            tBOSS[B].y := y + 1;
           end;
      end;
      4:
      begin	// ПРЫЖОК ВНИЗ И ВПРАВО!
	       tBOSS[B].dirx := 2;
		   if (tBOSS[B].x = MapX - 1) or (tBOSS[B].y = MapY - 1) then
            	begin tBOSS[B].behave:=6;exit end;	// падаем вниз прямо
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y+2,x+2].Code = BRICK) or (MAP[y+1,x+2].Code = BRICK)
           	or (MAP[y+2,x+1].Code = BRICK)
           then tBOSS[B].behave:=6	// вниз падаем
           else begin
           	tBOSS[B].x := x + 1;	// jump down-left
            tBOSS[B].y := y + 1;
           end;
      end;
      5:
      begin	// ПРЫЖОК ВВЕРХ ПРЯМО!
	       tBOSS[B].dirx := Random(2)+1;
		   if (tBOSS[B].Stamina = 0) or (tBOSS[B].y = 1) then
            	begin tBOSS[B].behave:=6;exit end;
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y-1,x].Code = BRICK) or (MAP[y-1,x+1].Code = BRICK)
	           then tBOSS[B].behave:=6	// вниз падаем
           else
	           tBOSS[B].y := y - 1;
      end;
      6:
      begin	// ПРОСТОЕ ПАДЕНИЕ ВНИЗ!
	       tBOSS[B].dirx := Random(2)+1;
		   if tBOSS[B].y = MapY - 1 then
            	begin tBOSS[B].behave:=0;exit end;	// СТОП
           if TryToShoot(5) then exit;	// выстрелил - всё
           if (MAP[y+2,x].Code = BRICK) or (MAP[y+2,x+1].Code = BRICK)
	           then tBOSS[B].behave:=0	// вниз падаем
           else
	           tBOSS[B].y := y + 1;
      end;
      8:	// босс разрывается на черепки!
      begin
		tBOSS[B].VID.Code := SKELETON_CODES[0];// freeze
      	if tBOSS[B].Stamina > 0 then exit;
        ResetBoss(B);	// BOSS
        tBOSS[B].CODE:=0;
		FillWeapon(x,y,1,5);
		FillWeapon(x,y+1,1,5);
        FillWeapon(x+1,y,-1,5);
        FillWeapon(x+1,y+1,-1,5);
      end; // case 8
	 end; // case behave
    END; // CASE SKELETON
   ELSE //other BOSS;
  END // case
END;
/////////////////////////////////////////////////////////////////////
procedure DirectaMan(N:integer);	// направить человечка
begin	{ DirectaMan }
 if (Cycles MOD thing[N].SPD) <> 0 then exit;	// speed of object
 inc(thing[N].Cycles);	// циклы конкретного существа
 CASE  thing[N].behave of
   0: thing[N].VID.CODE := 144;
   1:begin
	   thing[N].VID.CODE := (thing[N].Cycles MOD 3) + 149;
	   IF thing[N].x = 1 THEN EXIT ;
	   IF MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK THEN thing[N].x := thing[N].x - 1;
	 end;
   2: begin
	   thing[N].VID.CODE := (thing[N].Cycles MOD 3) + 146;
	   IF thing[N].x = 40 THEN EXIT ;
	   IF MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK THEN thing[N].x := thing[N].x + 1;
	  end;
   3: begin
	   thing[N].VID.CODE := MU[(thing[N].Cycles AND 3) + 1];
	   IF thing[N].y = 1 THEN begin thing[N].behave:=0; EXIT end;
	   IF (MAP[thing[N].y - 1, thing[N].x].CODE <> BRICK)
//       	AND ((thing[N].pVID.CODE = STAIR) or (thing[N].pVID.CODE = TREE))
       	AND ((MAP[thing[N].y,thing[N].x].Code = STAIR) or (MAP[thing[N].y,thing[N].x].Code = TREE))
       THEN thing[N].y := thing[N].y - 1
       else thing[N].behave:=0;
	  end;
   4: begin
	   thing[N].VID.CODE := MU[(thing[N].Cycles AND 3) + 1];
	   IF thing[N].y = 20 THEN begin thing[N].behave:=0; EXIT end;
	   IF MAP[thing[N].y + 1, thing[N].x].CODE <> BRICK THEN thing[N].y := thing[N].y + 1
       else thing[N].behave:=0;
	  end;
   5: begin thing[N].VID.CODE := 140; FillWeapon(thing[N].x,thing[N].y,-1,thing[N].GUN);thing[N].charge := 6; end;// до перезарядки
   6: begin thing[N].VID.CODE := 142; FillWeapon(thing[N].x,thing[N].y,1,thing[N].GUN);thing[N].charge := 6; end;
   7: begin
		   thing[N].FLSTEPS := thing[N].FLSTEPS + 1;
		   IF thing[N].FLSTEPS < 6 THEN
			thing[N].VID.CODE := MF[(thing[N].Cycles AND 1) + 1]
		   ELSE
			thing[N].VID.CODE := 164;
		    thing[N].y := thing[N].y + 1;
	 end;
   8: begin
		   IF (thing[N].VID.ATTR <> LIGHTWHITE) AND (thing[N].VID.ATTR <> YELLOW) THEN
				thing[N].VID.CODE := SKULL
		   ELSE
				thing[N].VID.CODE := GRAVE;
           if MAP[thing[N].y,thing[N].x].Code = EMPTY then
           				MAP[thing[N].y,thing[N].x]:=thing[N].VID;
   	  end;
  END// case
END; { DIRECTAMAN }
////////////////////////////////////////////////////////////////////////////////
procedure EdenCapWell; // это из Санта-Барбары?
var i:integer;
begin
	 FOR i := 1 TO 3 do begin
	  IF Weapons[1][i] > 99 THEN Weapons[1][i] := 99;// оружия до 99
	  IF Weapons[2][i] > 99 THEN Weapons[2][i] := 99;// оружия до 99
     end;

	 Cycles := Cycles + 1;	// глобальные циклы игры
	 if PlayerDeath > 0 then dec(PlayerDeath);	// флаг конца игры (смерть игроков)
     if NextLevel > 0 then dec(NextLevel);	// флаг перехода на след.уровень
END;
////////////////////////////////////////////////////////////////////////////////
procedure FirstInit; // первичная инициализация? - перед началом игры
var i:integer;
begin
//	 IF Level <= 0 THEN Level := 1;
// ставим оружие для игроков
	 FOR i := 2 TO 3 do begin Weapons[1][i] := 0; Weapons[2][i] := 0 end;
	 Weapons[1][1] := 6;
     Weapons[2][1] := 6;
// начальное HP
     Pl1HP := 10;
     Pl2HP := 10;
     if NumOfPlayers < 2 then
     begin	// no 2nd player
     	Pl2HP := 0;
        Weapons[2][1] := 0;
     end;

END;

////////////////////////////////////////////////////////////////////////////////
// Выводим весь уровень на экран из массива MAP
procedure PrintAllMap;
var i,j:integer;
begin
	// ClearDevice;

	FOR i := 1 TO MapY do
    	FOR j := 1 TO MapX do begin
			PutSymbol(j, i, MAP[i, j].CODE, MAP[i, j].ATTR,0);
            EKRAN[i,j].Code := 511;
        end;
end;

////////////////////////////////////////////////////////////////////////////////
// ищем первый доступный объект thing (пока только для FillWeapon)
FUNCTION FreeNumber:integer;
var i:integer;
begin
	 FOR i := 1 TO MaxThing do
		IF thing[i].CODE = 0 THEN
        begin
        	if i > MaxAvThing then MaxAvThing := i;
        	FreeNumber := i;
            EXIT
        end;
	 FreeNumber := 0;
END;
////////////////////////////////////////////////////////////////////////////////
procedure EndOfGame;
var	PosStr:integer;
	StrLength:integer;	{длина строки}
const
	Str:string =
		'Congratulations! YOU ARE a REAL MAN! ' +
        'You successfully has finished this extremely dangerous and ' +
        'large game - MAN. Hint: press Shift+TAB to skip the level. But ' +
        'be ready for the next greatest hits from me - ' +
        ' NEWMAN and HEMAN. They will be out in 2154AD, summer. See you then, dude! ' +
        ' Sincerely Yours, Sir Grendel Dragon Wizard.';
	Str2:string = '                     ';

	procedure Pause(MSec:word);	{ пауза в MSec/1000 секунд }
	begin
	   sleep(MSec div 100);
	end {Pause};

procedure MoveIt;	{ непосредственное движение }
const	Coor:array [1..16] of Pixel = (
	(x:40;y:12),(x:39;y:12),(x:38;y:11),(x:37;y:11),(x:36;y:10),(x:34;y:10),
	(x:32;y:10),(x:30;y:10),(x:28;y:10),(x:26;y:9),(x:24;y:8),(x:22;y:7),
	(x:19;y:6),(x:15;y:6),(x:10;y:5),(x:1;y:4)
					);
	SizeX:array[1..16] of integer = (
	1,1,1,1,1,2,2,2,2,2,2,2,3,4,5,9	);
	SizeY:array[1..16] of integer = (
	1,1,2,2,3,3,3,3,3,4,6,8,10,10,12,14	);
var i:integer;
	Sym:Symbol;
    s:string;
begin { MoveIt }
	StrLength := Length(Str);
	if PosStr>StrLength then PosStr:=1;
{ однвременно на экране видно лишь 16 символов строки }
	for i:=16 downto 1  do
		if PosStr-i+1>0 then
      begin
  			s:=Str[PosStr-i+1];
//			CharToOEMBuff(@s[1], @s[1], Length(s));
         Sym.Code:=word(s[1]);
//   		Sym.Code:=word(Str[PosStr-i+1]);
			 Sym.Attr:=BUTT_DEF_COLOR + Random(10);
			PutBigSymbol(Coor[i], Sym,0, SizeX[i], SizeY[i]);
      end;
	inc(PosStr);
  gdwSwapBuf;
	Pause(13000);
end { MoveIt };
begin   { EndOfGame }
//	ClearDevice;
  Str:=Str + Str2;
	PosStr:=1;
	repeat until Inkey = 0;		{ сбросим строб клавиатуры }
	while Inkey = 0 do MoveIt	{ выводим строку пока не будет нажатия }
end; { EndOfGame }
//////////////////////////////////////////////////////////////////////
//  GAAAAAAAAAAAAAAAAAAAAAAAAAAMMMMEEEEEEEEEEEE ////////
//////////////////////////////////////////////////////////////////////
procedure Game;
var
	fExit:boolean;
	i, j : integer;
begin
	Randomize;      // for Random functions
	Level:=1;
    Player1 := 0;
    Player2 := 0;

	// прочитаем данные заставки и сохраним их в массиве INTRO
	// TO-DO: check if MAN.TIT is present
	OutPutLevel('MAN.TIT');	
	FOR i := 1 TO MapY do
    	FOR j := 1 TO MapX do
			begin
				INTRO[i, j].CODE := MAP[i, j].CODE;
				INTRO[i, j].ATTR := MAP[i, j].ATTR;
			end;
	
 while true do begin
   MainMenu(fExit);
	 
   if fExit then exit;//game
   FirstInit;
	 
	// Level:=10;

	 repeat
     DblMode := false;
	   OpenLevel;
	   ReadLevel;
     WriteInitBoard;	// информация
	   GetReady;
		 repeat
       GloTimer:=WhatTime + GAMESPEED;	// засекаем время

//		   KeyP1 := Inkey;	// читаем нажатие клавишы
		   Keyboard;
		   AI;				// рассчёт жителей
//		   Move;			// движение
		   EdenCapWell;		// Санта-Барбара
           PrintGameMap;	// печатаем всю игровую карту
		   WriteBoard;		// полезные надписи
           gdwSwapBuf;	// рисунок - на экран
           	while GloTimer>WhatTime do ;{ пауза, выравнивающая скорость }
		  UNTIL (NextLevel = 0) OR (PlayerDeath = 0);
          IF NextLevel = 0 THEN inc(Level);	// след.уровень
          if Level > MaxLevel then
          begin
          	EndOfGame;	// покажем клип конца игры
            NextLevel := 1;	// конец игры!
          end;
	 until NextLevel <> 0;
	 GameOver;// конец игры
     Level:=1;	// сброс уровня в начало
 end
END;
////////////////////////////////////////////////////////////////////////////////
procedure GameOver;	// КОНЕЦ ИГРЫ - вывод надписи? TO DO
begin
	Ramka(15, 9, 25, 11);
	LOCATE( 10, 16);
    SCOLOR(15);
    MYPRINT('GAME OVER');
    gdwSwapBuf;
	WaitWithKey(180);
END;
////////////////////////////////////////////////////////////////////////////////
procedure GetReady;	 // МИГАНИЕ ЧЕЛОВЕЧКОВ ИГРОКОВ В НАЧАЛЕ УРОВНЯ
var j:integer;
begin
  j := 5;
 repeat
	PrintAllMap;
	WriteInitBoard;
	
  IF Player1 > 0 THEN  PutSymbol(thing[Player1].x, thing[Player1].y, EMPTY, 7,0);
  IF Player2 > 0 THEN  PutSymbol(thing[Player2].x, thing[Player2].y, EMPTY, 7,0);
  gdwSwapBuf;
  Wait(3);	// TimeZoom declared in gdwGraph
	
	PrintAllMap;
	WriteInitBoard;
	
  IF Player1 > 0 THEN  PutSymbol(thing[Player1].x, thing[Player1].y, MAN, 15,0);
  IF Player2 > 0 THEN  PutSymbol(thing[Player2].x, thing[Player2].y, MAN, 14,0);
  gdwSwapBuf;
  Wait(5);	// TimeZoom declared in gdwGraph
  j := j - 1
 UNTIL j = 0
END;
////////////////////////////////////////////////////////////////////////////////

// глобальные переменные для ShowPartLevel
var Part_i: integer = 0;
		Part_js: integer = 0;

procedure ChangePartLevel;
begin
	// читаем уровень в массив MAP
	OutPutLevel('LEVEL' + IntToStr(Random(MaxLevel) + 1) + '.MAN');
	
	Part_js := Random(MapX - 11) + 1;
	Part_i := Random(MapY - 4) + 1;
	
end;

////////////////////////////////////////////////////////////////////////////////
procedure ShowPartLevel;
var i,j,js,x,y:integer;
begin

// если PartLevel ещё не был инициализирован, выйдем сразу
	if Part_i = 0 then exit;
	
// восстановим координаты части уровня
    js := Part_js;
    i := Part_i;
		
    y := 5;
	
    while y < 14 do
    begin
    	x:=1;
        j:=js;
        while x < 24 do
        begin
        	PutBigSymbol(x,y,MAP[i,j].Code,MAP[i,j].Attr,2,2,0);
            inc(x,2);
            inc(j);
        end;
        inc(y,2);
        inc(i);
    end;
end;

////////////////////////////////////////////////////////////////////////////////
// Вывод заставочной части
procedure PrintIntro;
var i,j:integer;
begin
	// ClearDevice;

	FOR i := 1 TO MapY do
    	FOR j := 1 TO MapX do
				PutSymbol(j, i, INTRO[i, j].CODE, INTRO[i, j].ATTR,0);
end;

////////////////////////////////////////////////////////////////////////////////
procedure MainMenu(var fExit:boolean);
var Key:word; i:integer;
begin
	i:=0;
	Key := 0;

	 while Key <> SDLK_SPACE do begin
	 // полоса под уровнем
	 	RepeatSymbol(1, 21, UpLine, 7, 40);
	// карта текущего уровня (заставка)

		PrintIntro;
	// панель информации
		WriteInitBoard;
	 
		PutBigSymbol(4, 10, SKULL, 15, 4, 4, 0); // вывод большого красного черепа
		Locate(19,10); SCOLOR(RED);
		
		MYPRINT(' or ESC to quit');
		Locate(18,28); SCOLOR(GREEN);
		MYPRINT('Players:');

		PutBigSymbol(28, 8, (i mod 3) + 146, 54, 4, 7, 0);
        PutSymbol(36,18,NumOfPlayers + ord('0'),CYAN,3);

		i := i + 1;// IF i > 2 THEN i := 0;

    if i mod 50 = 0 then ChangePartLevel;	// сменим часть уровня (случайно)
	// часть уровня (эффект)
		ShowPartLevel;	// покажет, если есть

    gdwSwapBuf;
	
 // while true	do begin
		// gdwSwapBuf;
		Key:=WaitWithKey(2);
	
		IF Key = SDLK_ESCAPE THEN begin
			fExit:=true;
			exit
		END;

    if Key = SDLK_1 then NumOfPlayers := 1;
		if Key = SDLK_2 then NumOfPlayers := 2;
		
 // end;

	 end;
	 fExit:=false;
END; { MainMenu }

////////////////////////////////////////////////////////////////////////////////
procedure MoveThroughPortal1(var x,y:integer);
var i:integer;
begin
	if Portals < 1 then exit;
	for i:=1 to Portals do
    	if (Portals1[i].X=x) AND (Portals1[i].Y=y) then break;//found
    if i > Portals then exit;
    inc(i);
    if i > Portals then i:=1;
    x:=Portals2[i].X;
    y:=Portals2[i].Y;
end;
procedure MoveThroughPortal2(var x,y:integer);
var i:integer;
begin
	if Portals < 1 then exit;
	for i:=1 to Portals do
    	if (Portals2[i].X=x) AND (Portals2[i].Y=y) then break;//found
    if i > Portals then exit;
    inc(i);
    if i > Portals then i:=1;
    x:=Portals1[i].X;
    y:=Portals1[i].Y;
end;

procedure ManAI(N:integer);	// что делать человечку, а?
var
	Stairs: integer;
    L:integer;
    TargetM: integer;

	procedure iStairs;
	begin
		Stairs := 0;
		IF thing[N].y < 20 THEN
			IF MAP[thing[N].y + 1, thing[N].x].CODE <> BRICK THEN Stairs := 1;
//		IF thing[N].pVID.CODE = STAIR THEN Stairs := (Stairs OR 2);
		IF MAP[thing[N].y,thing[N].x].Code = STAIR THEN Stairs := (Stairs OR 2);

	end;
 
	function ToPlayer:boolean;// returns true for exitting
	begin
		ToPlayer := true;
		 IF thing[N].x = 1 THEN begin
		  IF MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK THEN
			begin thing[N].behave := 2; thing[N].stamina := 128; EXIT end
		  ELSE begin ToPlayer:= false; exit end
		 END;

		 IF thing[N].x = MapX {40} THEN begin
		  IF MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK THEN begin
			thing[N].behave := 1; thing[N].stamina := 128; EXIT end
		  ELSE
			begin ToPlayer:= false; exit end
		 END;

		 IF thing[N].y = 20 THEN begin
			  IF (thing[N].x > thing[TargetM].x)
              		AND (MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK) THEN begin
				 thing[N].behave := 1; thing[N].stamina := 128; EXIT
			  END;
			  IF MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK THEN begin
			   thing[N].behave := 2; thing[N].stamina := 128; EXIT
			  END;
			  ToPlayer:= false; exit
		 end;
		 
		 //////////////
		 IF (thing[N].x > thing[TargetM].x) AND (MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK)
			AND (MAP[thing[N].y + 1, thing[N].x - 1].CODE <> EMPTY) THEN
				begin thing[N].behave := 1; thing[N].stamina := 128; EXIT end;

		 IF (MAP[thing[N].y + 1, thing[N].x + 1].CODE <> EMPTY)
				AND (MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK) THEN
					begin thing[N].behave := 2; thing[N].stamina := 128; EXIT end;
					
		ToPlayer:=false
	end;// ToPlayer

  procedure PickIt;	// поднять вещицу?  FOR PLAYERS ONLY!
  var rnd:real; w,i:integer;bol:boolean;
  begin
  	if Player1 = N then  w:=1 else w:=2;
	IF MAP[thing[N].y,thing[N].x].Code <> EMPTY THEN

	CASE MAP[thing[N].y,thing[N].x].Code of
		 SKULL:
          begin     // ЧЕРЕПОК
			  CASE MAP[thing[N].y,thing[N].x].Attr of
			  RED: Weapons[w][1] := Weapons[w][1] + random(5);
			  CYAN: Weapons[w][2] := Weapons[w][2] + random(4);
			  MAGENTA: Weapons[w][3] := Weapons[w][3] + random(3);
              WHITE: dec(thing[N].HP,3);	// bad skull
			  END;
			  L := WhichNumber(thing[N].x, thing[N].y, N);
			  if L > 0 then
              	thing[L].CODE := 0;
              MAP[thing[N].y,thing[N].x].Code:=EMPTY;// сотрём черепок
		  end;// SKULL
		 TREASURE:         // СОКРОВИЩЕ...
		  begin
		  	rnd := random;	// случ.число от 0 до 1?
			if rnd < 0.2 then Weapons[w][3] := Weapons[w][3] + 2
			else if rnd < 0.4 then Weapons[w][2] := Weapons[w][2] + 3
			else if rnd < 0.75 then Weapons[w][1] := Weapons[w][1] + 5
			else if rnd < 0.9 then IF thing[N].HP < MaxHP THEN inc(thing[N].HP,5);
			MAP[thing[N].y,thing[N].x] := NOTHING;
		  end;
		 APPLE:	begin                  // ЯБЛОЧКО + 5 ЖИЗНЕЙ
         	IF thing[N].HP < MaxHP-5 THEN inc(thing[N].HP,5); MAP[thing[N].y,thing[N].x] := NOTHING;
            	end;
		 WEAPON: begin                 // ОРУЖИЕ
		  CASE MAP[thing[N].y,thing[N].x].Attr of
			  RED: if Weapons[w][1]<99 then Weapons[w][1] := Weapons[w][1] + 10;
			  CYAN: if Weapons[w][2]<99 then Weapons[w][2] := Weapons[w][2] + 8;
			  MAGENTA: if Weapons[w][3]<99 then Weapons[w][3] := Weapons[w][3] + 5;
		  END;//case
		  MAP[thing[N].y,thing[N].x] := NOTHING;
		  end;//WEAPON

		 HEART:
			IF thing[N].HP < MaxHP THEN begin inc(thing[N].HP,3); MAP[thing[N].y,thing[N].x] := NOTHING end
	END;//case
// проверим динамические черпки
	bol:=true;
    for i:=1 to MaxAvThing do
    	if (thing[i].CODE = 1) and (thing[i].behave = 8)
         and (thing[N].x = thing[i].x) and (thing[N].y = thing[i].y)
        then
        begin
			  CASE thing[i].VID.Attr of
				  RED: Weapons[w][1] := Weapons[w][1] + random(5);
				  CYAN: Weapons[w][2] := Weapons[w][2] + random(4);
				  MAGENTA: Weapons[w][3] := Weapons[w][3] + random(3);
//                  YELLOW,LIGHTWHITE: bol:=false;//exit; // can not pick player's skull
                  ELSE bol:=false; // either won't pick a skull
			  END;
              if bol then thing[i].CODE := 0;
              break
        end;
   // test for boss hit
    i := WhichBoss(thing[N].x,thing[N].y);
    if i > 0 then begin
	    dec(thing[N].HP,tBOSS[i].pain);
    end; // behave менять?
  end;//PickIt

  procedure Youman{(N:integer)};		// ДА - ТЫ - МУЖИК.  HEMAN
  var Key:word;w:integer;
  begin
    if PlayerDeath <> 0 then PlayerDeath := 240;	// пока ещё живой
    if Player1 = N then w:=1 else w:=2;
         Key := thing[N].keys;
         thing[N].keys := 0;
		 CASE Key of
		 1{SPACE_BAR}:	// ОГОНЬ! ПЛИ!
		   begin
			  IF thing[N].charge > 0 THEN EXIT;
              IF Weapons[w][thing[N].GUN] <= 0 THEN EXIT;

			  IF (thing[N].behave = 1) AND (thing[N].x > 1) THEN begin
				   IF ((MAP[thing[N].y, thing[N].x - 1].CODE = EMPTY)
                   			OR (MAP[thing[N].y, thing[N].x - 1].CODE = STAIR))
					THEN begin
						Weapons[w][thing[N].GUN] := Weapons[w][thing[N].GUN] - 1;
						EYE[thing[N].y] := 1;//1..20
//						thing[N].charge := 3;
						thing[N].behave := 5;
						EXIT
				   END
              END
			  ELSE IF (thing[N].behave = 2) AND (thing[N].x < 40) THEN
				   IF ((MAP[thing[N].y, thing[N].x + 1].CODE = EMPTY) OR (MAP[thing[N].y, thing[N].x + 1].CODE = STAIR))
                   THEN begin
						Weapons[w][thing[N].GUN] := Weapons[w][thing[N].GUN] - 1;
						EYE[thing[N].y] := 2; // 1..20
//						thing[N].charge := 3;
						thing[N].behave := 6;
						EXIT
				   END;

		   end; // case 1
		 2:{ENTER}// смена оружия, как в DOOM'e
			  IF thing[N].GUN = 3 THEN thing[N].GUN := 1 ELSE thing[N].GUN := thing[N].GUN + 1;
		 3{UP}:
			IF (MAP[thing[N].y,thing[N].x].Code = STAIR) or (MAP[thing[N].y,thing[N].x].Code = TREE)
            	THEN thing[N].behave := 3 ELSE thing[N].behave := 0;
		 4{LEFT}: thing[N].behave := 1;
		 5{RIGHT}: thing[N].behave := 2;
		 6{DOWN}:
				begin
					IF thing[N].y = 20 THEN begin thing[N].behave := 0; EXIT end;
					IF MAP[thing[N].y + 1, thing[N].x].CODE = BRICK THEN thing[N].behave := 0 ELSE thing[N].behave := 4;
				end;
		 END; // case
{ ЛИШНЕЕ? }
//		 IF thing[N].behave = 5 THEN thing[N].behave := 1;
//		 IF thing[N].behave = 6 THEN thing[N].behave := 2;
	end; // Youman

begin { ManAI }// 	Artifial intelligence			MAIN
	if (Cycles MOD thing[N].SPD) <> 0 then exit;	// speed of object
	IF thing[N].HP <= 0 THEN begin thing[N].HP:=0; thing[N].behave := 8; end;
//   	IF thing[N].behave = 8 THEN EXIT;  // DEAD?
	IF thing[N].charge > 0 THEN thing[N].charge := thing[N].charge - 1;
	IF thing[N].the > 0 THEN thing[N].the := thing[N].the - 1;

    if (MAP[thing[N].y,thing[N].x].Code = PORTAL1)
    	AND (thing[N].the = 0) then
    begin
    	thing[N].the := 6;	// ? to play with...
    	MoveThroughPortal1(thing[N].x,thing[N].y);
        exit;
    end;
    if (MAP[thing[N].y,thing[N].x].Code = PORTAL2)
    	AND (thing[N].the = 0) then	// the - чтоб не прыгал постоянно
    begin
       	thing[N].the := 6;	// ? to play with...
    	MoveThroughPortal2(thing[N].x,thing[N].y);
        exit;
    end;

	 IF thing[N].behave = 5 THEN begin thing[N].behave := 1;exit end;
	 IF thing[N].behave = 6 THEN begin thing[N].behave := 2;exit end;

	IF ((thing[N].VID.ATTR = LIGHTWHITE) OR (thing[N].VID.ATTR = YELLOW))
		AND (thing[N].behave <> 8) THEN
			PickIt;     // Player: подберём интересный предмет!

	IF (thing[N].y < 20) and (thing[N].behave <> 8) THEN begin
		IF (MAP[thing[N].y,thing[N].x].Code <> STAIR) AND (MAP[thing[N].y + 1, thing[N].x].CODE = EMPTY) THEN
		begin	// PlayerDeath - флаг смерти игрока, NextLevel - флаг перехода на след.уровень
			IF (thing[N].VID.ATTR = LIGHTWHITE) or (thing[N].VID.ATTR = YELLOW) THEN
            begin if PlayerDeath <>0 then PlayerDeath := 240 end //20 полных циклов
            	ELSE begin if NextLevel<>0 then NextLevel := 240 end;
			thing[N].behave := 7;	// ПАДЕНИЕ
            EXIT
		END//if
	END;// IF;

 IF thing[N].behave = 7 THEN begin
  IF thing[N].FLSTEPS < 6 THEN thing[N].behave := 0
  	 ELSE begin thing[N].behave := 0;thing[N].HP := thing[N].HP - 9; end; // РАЗБИЛСЯ?
  thing[N].FLSTEPS := 0;
  EXIT
 END;

 IF (thing[N].VID.ATTR = LIGHTWHITE) OR (thing[N].VID.ATTR = YELLOW)THEN
 begin
    	if thing[N].behave <> 8 then YouMan;
        // обновим global HP of players
        if Player1 = N then Pl1HP := thing[N].HP else Pl2HP := thing[N].HP;
        exit;  // оно в любом случае выходит?
 end;

IF thing[N].behave = 8 THEN EXIT;  // DEAD?

 if NextLevel <> 0 then NextLevel := 240;   // уровень ещё не закончен

 IF MAP[thing[N].y,thing[N].x].Code = SKULL THEN begin  // ЧЕРЕПОК
	  L := WhichNumber(thing[N].x, thing[N].y, N);
	  IF (random > 0.75) AND (L > 0) THEN begin //превращение человечков?
		   thing[L].CODE := 0;
//		   thing[N].pVID := thing[L].pVID;
	  END;
 END;// IF;
  //////////////////////////////////////////
 //            Real MAN AI!              //
//////////////////////////////////////////
	TargetM := N;	// за кем гоняться, пока - за собой...
    if (Player1 > 0) and (Player2 > 0) then
    begin // живы оба игрока
		if  Distance(thing[Player1].x,thing[Player1].y,thing[N].x,thing[N].y)
        	 <
	        Distance(thing[Player2].x,thing[Player2].y,thing[N].x,thing[N].y)
        then TargetM := Player1 else TargetM := Player2; // мишень - ближайший игрок

        if thing[Player1].HP < 1 then TargetM := Player2;
		if thing[Player2].HP < 1 then TargetM := Player1;
    end
    else
    begin
    	if Player1 > 0 then TargetM := Player1
        else if Player2 > 0 then TargetM := Player2;
    end;

 CASE thing[N].behave of
 0:	begin
	  thing[N].stamina := 128;
	  IF thing[N].x = 1 THEN begin thing[N].behave := 2; EXIT end;
	  IF thing[N].x = 40 THEN begin thing[N].behave := 1; EXIT end;
	  IF thing[N].y = 20 THEN begin
		   IF MAP[thing[N].y,thing[N].x].Code = STAIR THEN begin thing[N].behave := 3; EXIT end;
		   IF MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK THEN begin thing[N].behave := 1; EXIT end;
		   IF MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK THEN begin thing[N].behave := 2; EXIT end;
		   EXIT;
	  END;// IF;
      
//	  if Player1 > 0 then
	  IF (thing[N].x > thing[TargetM].x) AND (MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK) THEN
		thing[N].behave := 1
	  ELSE
	  IF (thing[N].x < thing[TargetM].x) AND (MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK) THEN
	   thing[N].behave := 2
	  ELSE
	  IF (thing[N].y < thing[TargetM].y) AND (MAP[thing[N].y + 1, thing[N].x].CODE <> BRICK) THEN
	   thing[N].behave := 4
	  ELSE
	  IF (thing[N].x > 1) AND (MAP[thing[N].y, thing[N].x - 1].CODE <> BRICK) THEN
	   thing[N].behave := 1
	  ELSE
	  IF (thing[N].x < 40) AND (MAP[thing[N].y, thing[N].x + 1].CODE <> BRICK) THEN
	   thing[N].behave := 1
	  ELSE
	  IF (thing[N].y < 20) AND (MAP[thing[N].y + 1, thing[N].x].CODE = STAIR) THEN
	   thing[N].behave := 4;
	  EXIT;
	end; // case 0 
  1: begin   	// MOVING LEFT
	   IF EYE[thing[N].y] = 2 THEN begin
		thing[N].stamina := 0;
		thing[N].behave := 2;
	   END;
   
   iStairs;
   
   IF Stairs > 0 THEN begin
   
    IF thing[N].stamina <= 32 THEN begin
	
     thing[N].stamina := 128;
     IF (Stairs AND 1) > 0 THEN thing[N].behave := 4 ELSE thing[N].behave := 3;
     EXIT
	end
	
    ELSE
//		if Player1 > 0 then
     IF ((Stairs AND 1) > 0) AND (thing[N].y < thing[TargetM].y) THEN
	 begin	thing[N].stamina := 128; thing[N].behave := 4; EXIT	 END
     ELSE IF thing[N].y > thing[TargetM].y THEN begin thing[N].stamina := 128; thing[N].behave := 3; EXIT END

   END; // IF
   
   IF thing[N].x = 1 THEN begin
    thing[N].stamina := thing[N].stamina div 2;
    thing[N].behave := 2; EXIT
   END;
   
   IF MAP[thing[N].y, thing[N].x - 1].CODE = BRICK THEN begin
    thing[N].stamina := thing[N].stamina div 2;
    thing[N].behave := 2; EXIT
   END;
   
// shooting...
	if (Player1 > 0) and (thing[Player1].HP > 0) then//теперь по мертвым не стреляют...
   IF thing[N].y = thing[Player1].y THEN
    IF (thing[N].x > thing[Player1].x) AND (thing[N].charge = 0) AND (random < 0.4) THEN
     thing[N].behave := 5;

    if (Player2 > 0) and (thing[Player2].HP > 0) then
   IF thing[N].y = thing[Player2].y THEN
    IF (thing[N].x > thing[Player2].x) AND (thing[N].charge = 0) AND (random < 0.4) THEN
     thing[N].behave := 5;
// давай исключим самоубийство падением с высоты
	if (thing[N].y < MapY - 4) then
//  begin
      if (MAP[thing[N].y+1,thing[N].x-1].Code = EMPTY) AND (MAP[thing[N].y+2,thing[N].x-1].Code = EMPTY)
		AND (MAP[thing[N].y+3,thing[N].x-1].Code = EMPTY) AND (MAP[thing[N].y+4,thing[N].x-1].Code = EMPTY)
        AND (MAP[thing[N].y+5,thing[N].x-1].Code = EMPTY)
        	then thing[N].behave := 0;	// stop before chasm

   EXIT
  end; // case 1

  
  2: begin
   IF EYE[thing[N].y] = 1 THEN begin
    thing[N].stamina := 0;
    thing[N].behave := 1;
   END;
   iStairs;
   
   IF Stairs > 0 THEN begin
    IF thing[N].stamina <= 32 THEN begin
     thing[N].stamina := 128;
     IF (Stairs AND 1) > 0 THEN thing[N].behave := 4 ELSE thing[N].behave := 3;
     EXIT
	END
    ELSE
//    	if Player1 > 0 then
     IF ((Stairs AND 1) > 0) AND (thing[N].y < thing[TargetM].y) THEN
     		 begin thing[N].stamina := 128; thing[N].behave := 4; EXIT end
     ELSE IF thing[N].y > thing[TargetM].y THEN begin thing[N].stamina := 128; thing[N].behave := 3; EXIT end;
   END;// IF;
   
   IF thing[N].x = 40 THEN begin
    thing[N].stamina := thing[N].stamina div 2;
    thing[N].behave := 1; EXIT
   END;
   
   IF MAP[thing[N].y, thing[N].x + 1].CODE = BRICK THEN begin
    thing[N].stamina := thing[N].stamina div 2;
    thing[N].behave := 1; EXIT
   END;

// shooting...
	if (Player1 > 0) and (thing[Player1].HP > 0) then
   IF thing[N].y = thing[Player1].y THEN
    IF (thing[N].x < thing[Player1].x) AND (thing[N].charge = 0) AND (random < 0.4) THEN
		thing[N].behave := 6;
    if (Player2 > 0) and (thing[Player2].HP > 0) then
   IF thing[N].y = thing[Player2].y THEN
    IF (thing[N].x < thing[Player2].x) AND (thing[N].charge = 0) AND (random < 0.4) THEN
		thing[N].behave := 6;
// давай исключим самоубийство падением с высоты
	if (thing[N].y < MapY - 4) then
//  begin
      if (MAP[thing[N].y+1,thing[N].x+1].Code = EMPTY) AND (MAP[thing[N].y+2,thing[N].x+1].Code = EMPTY)
		AND (MAP[thing[N].y+3,thing[N].x+1].Code = EMPTY) AND (MAP[thing[N].y+4,thing[N].x+1].Code = EMPTY)
        AND (MAP[thing[N].y+5,thing[N].x+1].Code = EMPTY)
        	then thing[N].behave := 0;	// stop before chasm

   EXIT
  end;		// case 2
  
   3: //Moving UP!!;
   begin
		IF thing[N].y = thing[TargetM].y THEN if ToPlayer then exit;
		IF thing[N].y = 1 THEN begin
		 if(ToPlayer) then exit;
		 thing[N].stamina := thing[N].stamina div 2;
		 thing[N].behave := 4;
		 EXIT
		END;
		
		IF (MAP[thing[N].y,thing[N].x].Code <> STAIR) OR (MAP[thing[N].y - 1, thing[N].x].CODE = BRICK) THEN begin
		 if(ToPlayer) then exit;
		 thing[N].stamina := thing[N].stamina div 2;
		 thing[N].behave := 4;
		 EXIT
		END;
		
		IF thing[N].stamina = 32 THEN if(ToPlayer) then exit;
	end; // case 3
	
   4: //Moving DOWN!!;
   begin
    IF thing[N].y = thing[TargetM].y THEN if(ToPlayer) then exit;
    IF thing[N].y = 20 THEN begin
     if(ToPlayer) then exit;
     thing[N].stamina := thing[N].stamina div 2;
     thing[N].behave := 3;
     EXIT
    END;
	
    IF MAP[thing[N].y + 1, thing[N].x].CODE = BRICK THEN begin
     if(ToPlayer) then exit;
     thing[N].stamina := thing[N].stamina div 2;
     thing[N].behave := 3;
     EXIT
    END;
	
    IF thing[N].stamina = 32 THEN if(ToPlayer) then exit;
	end; // case 4
	
//   5: thing[N].behave := 1;
//   6: thing[N].behave := 2;
   
   END; // CASE
end; // ManAI  SUB   EXIT SUB;
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure PrintGameMap;	// печатаем карту игры
var i,j,x,y,LeftX,TopY,l,t:integer;

	function InRect(var x,y:integer):boolean;
    // проверяет попали ли в карту вывода при большом экране (DblMode==TRUE)
	begin
		Result := false;
		if (x >= LeftX) AND (y >= TopY)
			AND (x <= LeftX + 19) AND (y <= TopY + 9) then
		begin
			Result := true;
			// пересчитаем координаты вывода для экрана
			x := (x - LeftX) * 2 + 1;
			y := (y - TopY ) * 2 + 1;
		end;
	end; { InRect }

	procedure TryToPutBoss(B:integer);// пытаемся вывести хотя бы часть босса
	var x,y:integer;c,a:word;         // при большом экране (DblMode == TRUE)
	begin
		x:=tBOSS[B].x;
		y:=tBOSS[B].y;
		c:=tBOSS[B].VID.Code;
		a:=tBOSS[B].VID.Attr;
		if InRect(x,y) then PutBigSymbol(x,y,c,a,2,2,1);
		x:=tBOSS[B].x+1;
		y:=tBOSS[B].y;
		if InRect(x,y) then PutBigSymbol(x,y,c+1,a,2,2,1);
		x:=tBOSS[B].x;
		y:=tBOSS[B].y+1;
		if InRect(x,y) then PutBigSymbol(x,y,c+2,a,2,2,1);
		x:=tBOSS[B].x+1;
		y:=tBOSS[B].y+1;
		if InRect(x,y) then PutBigSymbol(x,y,c+3,a,2,2,1);
	end; { TryToPutBoss }

begin	{ PrintGameMap }
	if (not DblMode) or (Player1 = 0) then
	begin
		for i:=1 to MaxAvThing do
			if thing[i].CODE > 0 then begin	// стираем движущийся объект
				PutSymbol(thing[i].xOld,thing[i].yOld,EMPTY,WHITE,0);
				EKRAN[thing[i].yOld,thing[i].xOld].Code := EMPTY;
			end;

		for i:=1 to MaxBoss do
			if tBOSS[i].CODE > 0 then ResetBoss(i);	// удалим боссов
			
		// выводим уровень целиком
		PrintAllMap;
		
		{	// Старый код, не работает с двойным буфер OpenGL (хотя раньше работал)
		FOR i := 1 TO MapY do
			FOR j := 1 TO MapX do
				if EKRAN[i,j].Code <> MAP[i,j].Code then begin
					PutSymbol(j, i, MAP[i, j].CODE, MAP[i, j].ATTR,0);
					EKRAN[i,j] := MAP[i,j];
				end;
		}
		
		for i:=1 to MaxAvThing do
			if thing[i].CODE > 0 then
				PutSymbol(thing[i].x,thing[i].y,thing[i].VID.Code,thing[i].VID.Attr,1);
		for i:=1 to MaxBoss do
			if tBOSS[i].CODE > 0 then
				PutBoss(i);// выводим боссов
	end
	
	else	// Put Double Mode (key F5 toggled)
	begin
	// first find Left,Top for MAP output
		LeftX:=thing[Player1].x - 10; // MapX / 4?
		TopY :=thing[Player1].y -  5; // Mapy / 4?
		if LeftX < 1 then LeftX := 1;
		if TopY  < 1 then TopY  := 1;
		if LeftX + 19 > MapX then LeftX := 21; // MapX - 19?
		if TopY  +  9 > MapY then TopY  := 11; // MapY -  9?
		y := 1;
		t := TopY;
		while y < MapY do begin
			x := 1;
			l := LeftX;
			while x < MapX do begin
				PutBigSymbol(x,y,MAP[t,l].Code,MAP[t,l].Attr,2,2,0);
				inc(x,2);
				inc(l);
			end;
			inc(y,2);
			inc(t);
		end;
		for i:=1 to MaxAvThing do
			if thing[i].CODE > 0 then begin
				l:=thing[i].x;
				t:=thing[i].y;
				if InRect(l,t) then PutBigSymbol(l,t,thing[i].VID.Code,thing[i].VID.Attr,2,2,1);
			end;{ if }
		for i:=1 to MaxBoss do
			if tBOSS[i].CODE > 0 then TryToPutBoss(i);
	end; { DoubleMode }

// обновим координаты
	for i:=1 to MaxAvThing do
		if thing[i].CODE > 0 then
		begin
			thing[i].xOld := thing[i].x;
			thing[i].yOld := thing[i].y;
		end;
	for i:=1 to MaxBoss do
		if tBOSS[i].CODE > 0 then begin
			tBOSS[i].xOld := tBOSS[i].x;
			tBOSS[i].yOld := tBOSS[i].y;
		end;
end; { PrintGameMap }

////////////////////////////////////////////////////////////////////////////////
procedure OpenLevel;
begin
	OutPutLevel('LEVEL' + IntToStr(Level) + '.MAN');
end;

////////////////////////////////////////////////////////////////////////////////
// Вывод на экран уровня, прочитанного из файла с именем N
procedure OutPutLevel(N: string);
var
	F:TextFile;
	s:string;
	i,j: integer;
//
begin
// OPEN N$ FOR INPUT AS #1;
	{$I-}
		Assign(F,N);	// либо уровень, либо заставка?
		Reset(F);
		if IOResult <> 0 then exit;	// нет такого уровня?
	{$I+}
	   FOR i := 1 TO MapY do
		FOR j := 1 TO MapX do begin
		Readln(F,s);	// читаем код символа
		MAP[i, j].Code := StrToIntDef(trim(s),0);		// преобразуем и помещаем в карту
		Readln(F,s);	// читаем его атрибут
		MAP[i, j].ATTR := StrToIntDef(trim(s),0);		// преобразуем и помещаем в карту
	   end;//for j
	  Close(F);
END;
////////////////////////////////////////////////////////////////////////////////
procedure Ramka(xl, yu, xr, yd:integer);
var i:integer;
begin
 PutSymbol(xl, yu, 172, WHITE,0);
 RepeatSymbol(xl + 1, yu, 177, 7, xr - xl - 1);
 PutSymbol(xr, yu, 173, 7,0);
 FOR i := yu + 1 TO yd - 1 do begin
  PutSymbol(xl, i, 176, 7,0);
  RepeatSymbol(xl + 1, i, 178, 7, xr - xl - 1);
  PutSymbol(xr, i, 176, 7,0);
 end;//for
 PutSymbol(xl, yd, 174, 7,0);
 RepeatSymbol(xl + 1, yd, 177, 7, xr - xl - 1);
 PutSymbol(xr, yd, 175, 7,0);
END; { Ramka }

// повторим символ NUMBER раз
procedure RepeatSymbol (x, y:integer; Code: word; ATTR: byte; NUMBER:integer);
var i:integer;
begin
 FOR i := 0 TO NUMBER - 1 do
	PutSymbol(x + i, y, Code, ATTR,0);
END;	{ RepeatSymbol }

procedure RestoreScreen (xl, yu, xr, yd:integer);
var i,j,t:integer;	// восстановим экран из EKR массива (динамического)
begin
 t := 1;
 FOR i := yu TO yd do
  FOR j := xl TO xr do begin
		PutSymbol(j, i, EKR[t].Code, EKR[t].ATTR,0);
		t := t + 1;
 end; //fors
	EKR := nil;		// освободим память, занимаемым динамическим массивом
END;

procedure SaveScreen (xUp, yUp, xDwn, yDwn:integer);
var i,j,t:integer;
begin
 SetLength(EKR, (xDwn - xUp + 1) * (yDwn - yUp + 1) * sizeof(Symbol));	// резервируем память
 t := 1;
 FOR i := yUp TO yDwn do
  FOR j := xUp TO xDwn do begin
	EKR[t] := MAP[i, j];
	t := t + 1;
 end;//fors
END;		{SaveScreen}

////////////////////////////////////////////////////////////////////////////////
procedure ReadLevel;	// обработаем уровень, инициализируем геровев
var i,j,N,B: integer;
	procedure InitMan;
	begin
    	if N>MaxThing then exit;	// превысили кол-во доступных объектов
    	 CASE MAP[i, j].ATTR of	// оружие человечка зависит от его ЦВЕТА!!
			 RED: begin thing[N].SPD := 8;thing[N].HP := 2; thing[N].GUN := 1; end;// стрелы
			 CYAN: begin thing[N].SPD := 9;thing[N].HP := 4; thing[N].GUN := 2; end;// вилы
			 MAGENTA: begin thing[N].SPD := 10;thing[N].HP := 6; thing[N].GUN := 3; end;//топоры
			 BROWN: begin thing[N].SPD := 9;thing[N].HP := 8; thing[N].GUN := 4; end;// ножики, ха!
			 BLUE: begin thing[N].SPD := 6;thing[N].HP := 10; thing[N].GUN := 5; end;//черепо-кидатель

			 LIGHTWHITE:	// игрок 1
				begin
	                if (Pl1HP <= 0) then// 1 player is dead?
                    begin
//                    	MAP[i, j].CODE := EMPTY;
                    	dec(N);
                        exit
                    end;
                	Player1 := N;
	                thing[N].SPD := 5;
                	thing[N].HP := Pl1HP;//10;	// сердечек
    	            thing[N].GUN := 1;	// оружие - стрелы
				end;

			 YELLOW:		// игрок 2
				begin
                	if (NumOfPlayers < 2) OR (Pl2HP <= 0) then// 1 player only
                    begin
//                    	MAP[i, j].CODE := EMPTY;
                    	dec(N);
                        exit
                    end;
                	Player2 := N;
	                thing[N].SPD := 5;
					thing[N].HP := Pl2HP;//10;	// сердечек
					thing[N].GUN := 1;
				end;
             ELSE begin dec(N);exit end; // другой цвет не используем
		 END;//case
		 thing[N].x := j;
		 thing[N].y := i;
		 thing[N].xOld := j;
		 thing[N].yOld := i;
		 thing[N].VID := MAP[i, j];
//		 thing[N].pVID := NOTHING;
		 thing[N].behave := 0;
		 thing[N].FLSTEPS := 0;
		 thing[N].STEPS := 0;
		 thing[N].the := 0;
		 thing[N].charge := 0;
		 thing[N].CODE := 1;
         MaxAvThing := N;	// счётчик появившихся объектов
	end;

	procedure InitBoss;	// ИНИЦИАЛИЗИРУЕМ БОССОВ
	begin	// InitBoss
   		 if B>MaxBoss then exit;	//превысили дост.число боссов для уровня

		 tBOSS[B].x := j;
         tBOSS[B].y := i;
		 tBOSS[B].xOld := j;
         tBOSS[B].yOld := i;
		 tBOSS[B].VID := MAP[i, j];
		 tBOSS[B].charge := 0;
         tBOSS[B].diry := 0;
         tBOSS[B].Stamina := 0;
         tBOSS[B].charge := 0;
         tBOSS[B].tag := 0;

		 CASE MAP[i, j].CODE of
			 LTOOTHED:		// ЗУБАН
			 begin
			  tBOSS[B].CODE := 1;
              tBOSS[B].HP := 15;
              tBOSS[B].dirx := 1;
			  tBOSS[B].behave := 2;
              tBOSS[B].pain := 2;	// насколько больно столкновение с ним игроков
              tBOSS[B].SPD := 8;
			 end;
			 GIANT:	// ГИГАНТ
			 begin
			  tBOSS[B].CODE := 2;
              tBOSS[B].HP := 25;
              tBOSS[B].dirx := 2;	// ->
			  tBOSS[B].behave := 0;
              tBOSS[B].pain := 3;	// насколько больно столкновение с ним игроков
              tBOSS[B].SPD := {6}5;
			 end;
			 SKELETON:  // СКЕЛЕТОН
			  begin
			  tBOSS[B].CODE := 3;
              tBOSS[B].HP := 30;
              tBOSS[B].dirx := 0;
			  tBOSS[B].behave := 0;
              tBOSS[B].pain := 4;	// насколько больно столкновение с ним игроков
              tBOSS[B].SPD := {8}7;
			  end;
			 ELSE B := B - 1;	//
		 END // case
	END;// InitBoss

    procedure InitButt;  // бабочка из Hero game for Apple2!
	begin
	   	 if N>MaxThing then exit;	// превысили кол-во доступных объектов
		 thing[N].x := j;
		 thing[N].y := i;
		 thing[N].xOld := j;
		 thing[N].yOld := i;
		 thing[N].VID := MAP[i, j];

//		 thing[N].behave := 0;
		 thing[N].dirx := 1;	// DX
		 thing[N].diry := 1;   // DY
         if random(10) < 5 then thing[N].dirx := -1;
         if random(10) < 5 then thing[N].diry := -1;

		 thing[N].Cycles := 0;

         thing[N].SPD := BUTT_SPEED;	// fast
		 thing[N].HP := 1; // HP LOW

		 thing[N].CODE := 3;	// КОД ОБЪЕКТА - БАБОЧКА!
         MaxAvThing := N;	// счётчик появившихся объектов
	end; { InitButt }
    procedure InitSpawn(x,y,cd:integer);  // точка для SPAWN-объкетов
	begin
	   	 if N>MaxThing then exit;	// превысили кол-во доступных объектов
		 thing[N].x := x;
		 thing[N].y := y;
		 thing[N].xOld := x;
		 thing[N].yOld := y;
		 thing[N].VID := MAP[y, x];
         thing[N].CODE := cd;
         thing[N].Cycles := 0;
         thing[N].charge := 0;
         thing[N].SPD := 120;	// so slow for spawning...?
         thing[N].HP := 50;	// tough rather
    end;

begin	{ ReadLevel }

	 FOR i := 1 TO MaxThing do thing[i].CODE := 0;
	 FOR i := 1 TO MaxBoss do tBOSS[i].CODE := 0;

	 FOR i := 1 TO MaxEYE do EYE[i] := 0;

	 N := 0; B := 0;  
	 MaxAvThing := 0; Portals := 0;
     Player1 := 0; Player2 := 0;
     NextLevel := 240; PlayerDeath := 240;

	 FOR i := 1 TO MapY do
	  FOR j := 1 TO MapX do begin
	   IF MAP[i, j].CODE = MAN THEN begin N := N + 1; InitMan; MAP[i,j]:=NOTHING end
	   ELSE IF MAP[i, j].CODE >= coBOSS THEN
       begin
       	B := B + 1;
        InitBoss;  				// и чистим карту:
		MAP[i,j]:=NOTHING;
        if j<MapX then MAP[i,j+1]:=NOTHING;
        if i<MapY then MAP[i+1,j]:=NOTHING;
        if (j<MapX) and (i<MapY) then MAP[i+1,j+1]:=NOTHING;
      end
// добавим бабочку из HERO!
      ELSE IF MAP[i, j].CODE = BUTT1 THEN begin N := N + 1; InitButt; MAP[i,j]:=NOTHING end
      ELSE IF MAP[i, j].CODE = VID_CAVE THEN begin N := N + 1; InitSpawn(j+1,i+1,4); end	// butterfly spawn
      ELSE IF MAP[i, j].CODE = VID_HOUSE THEN begin N := N + 1; InitSpawn(j,i+1,5); end	// men spawn
	  ELSE IF (MAP[i, j].CODE = PORTAL1) AND (Portals < MaxPortals) THEN
	  begin
		inc(Portals);
		Portals1[Portals].x:=j;
		Portals1[Portals].y:=i;
	  end
	  ELSE IF (MAP[i, j].CODE = PORTAL2) AND (Portals > 0) THEN
	  begin
		Portals2[Portals].x:=j;
		Portals2[Portals].y:=i;
	  end;

      EKRAN[i,j].Code:=255;  // clear it
     end;//for j,i
	PrintGameMap	// наконец распечатаем весь уровень
end;	{ ReadLevel }
////////////////////////////////////////////////////////////////////////////
//procedure PutBoss (x, y:integer; CODE:word; ATTR:byte);		// выводим БОССА (символы 2*2)
procedure PutBoss(B:integer);
begin
 PutSymbol(tBOSS[B].x, tBOSS[B].y, tBOSS[B].VID.Code, tBOSS[B].VID.Attr,1);
 PutSymbol(tBOSS[B].x + 1, tBOSS[B].y, tBOSS[B].VID.Code + 1, tBOSS[B].VID.Attr,1);
 PutSymbol(tBOSS[B].x, tBOSS[B].y + 1, tBOSS[B].VID.Code + 2, tBOSS[B].VID.Attr,1);
 PutSymbol(tBOSS[B].x + 1, tBOSS[B].y + 1, tBOSS[B].VID.Code + 3, tBOSS[B].VID.Attr,1);
end;

procedure ResetBoss(B:integer);		// удаляем босса
begin
	 EKRAN[tBOSS[B].yOld, tBOSS[B].xOld].Code := EMPTY;
	 EKRAN[tBOSS[B].yOld, tBOSS[B].xOld + 1].Code := EMPTY;
	 EKRAN[tBOSS[B].yOld + 1, tBOSS[B].xOld].Code := EMPTY;
	 EKRAN[tBOSS[B].yOld + 1, tBOSS[B].xOld + 1].Code := EMPTY;
	 PutSymbol(tBOSS[B].xOld, tBOSS[B].yOld, EMPTY, WHITE,0);
	 PutSymbol(tBOSS[B].xOld + 1, tBOSS[B].yOld, EMPTY, WHITE,0);
	 PutSymbol(tBOSS[B].xOld, tBOSS[B].yOld + 1, EMPTY, WHITE,0);
	 PutSymbol(tBOSS[B].xOld + 1, tBOSS[B].yOld + 1, EMPTY, WHITE,0);
END;
{
procedure SetBoss(x,y: integer; CODE:word; ATTR:byte);
begin
	 MAP[y, x].CODE := CODE;
	 MAP[y, x].ATTR := ATTR;
	 MAP[y, x + 1].CODE := CODE + 1;
	 MAP[y, x + 1].ATTR := ATTR;
	 MAP[y + 1, x].CODE := CODE + 2;
	 MAP[y + 1, x].ATTR := ATTR;
	 MAP[y + 1, x + 1].CODE := CODE + 3;
	 MAP[y + 1, x + 1].ATTR := ATTR;
END;}
////////////////////////////////////////////////////////////////////////////////
procedure WeaponFly(N:integer);			// ПОЛЁТ ОРУЖИЯ
var //Moves,
	i,M:integer;
	procedure StopIt; // STOP FLYING?
	begin
		 EKRAN[thing[N].yOld, thing[N].xOld] := NOTHING;
		 PutSymbol(thing[N].xOld, thing[N].yOld, {thing[N].pVID.CODE, thing[N].pVID.ATTR}EMPTY,WHITE,0);
		 thing[N].CODE := 0;
		 EYE[thing[N].y] := 0;
	end;

begin { WeaponFly }
	if(Cycles MOD thing[N].SPD) <> 0 then exit;

	IF (thing[N].x = MapX) OR (thing[N].x = 1) THEN begin StopIt; exit end; // конец полёта
 	thing[N].x := thing[N].x + thing[N].dirx;
 	IF MAP[thing[N].y, thing[N].x].CODE <> EMPTY THEN
		CASE MAP[thing[N].y, thing[N].x].CODE of
				BRICK: begin StopIt; exit end;
            	TREE:
				begin
				 StopIt;
				 IF (thing[N].GUN = 3) or (thing[N].GUN = 5)
                 THEN begin // топор и черепок рубят деревья!
				  MAP[thing[N].y, thing[N].x] := NOTHING;
//				  PutSymbol(thing[N].x, thing[N].y, NOTHING.CODE, NOTHING.ATTR,0);
				 END;// IF;
				 exit
				end;
				CROSS:
				begin	// кресты все рубят
				 StopIt;
				 MAP[thing[N].y, thing[N].x] := NOTHING;
//				 PutSymbol(thing[N].x, thing[N].y, NOTHING.CODE, NOTHING.ATTR,0);
				 exit
				end;
 {				140..151:  // попал в человечка
				begin
				 StopIt;
				 M := WhichNumber(thing[N].x, thing[N].y, N);// who is that man?
				 IF M > 0 THEN thing[M].HP := thing[M].HP - thing[N].HP;
				 exit
				end;
				215..255:  // boss hit
				begin
				 StopIt;
				 M := WhichBoss(thing[N].x, thing[N].y);
				 IF M > 0 THEN tBOSS[M].HP := tBOSS[M].HP - thing[N].HP;
				 exit
				end; }
		END;	// case
        // hitting men
        for i:=1 to MaxAvThing do
        	if ((thing[i].CODE = 1) or (thing[i].CODE = 3) or (thing[i].CODE = 4) or (thing[i].CODE = 5))
            	 AND (thing[N].x = thing[i].x) AND (thing[N].y = thing[i].y) then
            begin // hit someone
             StopIt;
			 M := WhichNumber(thing[N].x, thing[N].y, N);// who is that man?
			 IF M > 0 THEN thing[M].HP := thing[M].HP - thing[N].HP;
			 exit
            end;
        M := WhichBoss(thing[N].x,thing[N].y);
        if M > 0 then
        begin
		 StopIt;
		 tBOSS[M].HP := tBOSS[M].HP - thing[N].HP;
		end;
END;	{ WeaponFly }
////////////////////////////////////////////////////////////////////////////////
procedure MoveButt(N:integer);			// ПОЛЁТ ОРУЖИЯ
var
	i,M:integer;
begin
	if(Cycles MOD thing[N].SPD) <> 0 then exit;

    if thing[N].HP <= 0 then
    begin
     thing[N].CODE:=0;
	 PutSymbol(thing[N].xOld,thing[N].yOld,EMPTY,WHITE,0);
     exit
    end;// butterfly is DEAD?

    inc(thing[N].Cycles);

	IF (thing[N].x = MapX) OR (thing[N].x = 1) THEN
    	begin thing[N].dirx := thing[N].dirx * (-1); {exit} end // конец полёта
	ELSE IF (thing[N].y = MapY) OR (thing[N].y = 1) THEN
    	begin thing[N].diry := thing[N].diry * (-1); {exit} end // конец полёта
	ELSE
    IF (MAP[thing[N].y + thing[N].diry, thing[N].x + thing[N].dirx].Code = BRICK) then
	    begin
        	thing[N].diry := thing[N].diry * (-1);
		    IF (MAP[thing[N].y + thing[N].diry, thing[N].x + thing[N].dirx].Code = BRICK) then
            	        	thing[N].dirx := thing[N].dirx * (-1);
            exit
        end; // конец полёта


 	thing[N].x := thing[N].x + thing[N].dirx;
  	thing[N].y := thing[N].y + thing[N].diry;

    if thing[N].x > MapX then thing[N].x := MapX;
	if thing[N].x < 1 then thing[N].x := 1;
    if thing[N].y > MapY then thing[N].y := MapY;
	if thing[N].y < 1 then thing[N].y := 1;

        // hitting men
        for i:=1 to MaxAvThing do
        	if (thing[i].CODE = 1) AND (thing[N].x = thing[i].x)
             AND (thing[N].y = thing[i].y) then
            begin // hit someone
			 M := WhichNumber(thing[N].x, thing[N].y, N);// who is that man?
			 IF M > 0 THEN begin
            	if (thing[M].VID.Attr = LIGHTWHITE) or (thing[M].VID.Attr = YELLOW) then
 	            	thing[M].HP := thing[M].HP - 2;
             end;
			 exit
            end;
       if (thing[N].Cycles MOD 4) < 2 then thing[N].VID.Code := BUTT1
       	else thing[N].VID.Code := BUTT2;

END;	{ MoveButt }
////////////////////////////////////////////////////////////////////////////////
FUNCTION WhichBoss(x, y:integer):integer;		// ищем босса
var i:integer;
begin
 FOR i := 1 TO MaxBoss do 
	  IF tBOSS[i].CODE > 0 THEN
	  BEGIN
	   IF (tBOSS[i].x = x) AND (tBOSS[i].y = y) THEN begin WhichBoss := i; EXIT end;
	   IF (tBOSS[i].x + 1 = x) AND (tBOSS[i].y = y) THEN begin WhichBoss := i; EXIT end;
	   IF (tBOSS[i].x = x) AND (tBOSS[i].y + 1 = y) THEN begin WhichBoss := i; EXIT end;
	   IF (tBOSS[i].x + 1 = x) AND (tBOSS[i].y + 1 = y) THEN begin WhichBoss := i; EXIT end;
	  END;
 WhichBoss:=0
END;
////////////////////////////////////////////////////////////////////////////////
FUNCTION WhichNumber(x, y, N:integer):integer;	// ищем жителя
var i:integer;
begin	// ищес номер жителя с координтатами x,y
	FOR i := 1 TO MaxAvThing do
		IF (thing[i].xOld = x) AND (thing[i].yOld = y) AND (i <> N) THEN
        	begin WhichNumber := i; exit end;
    WhichNumber := 0;
END;
////////////////////////////////////////////////////////////////////////////////
procedure WriteBoard;
var s:string;
// i:integer;
begin
// Выводим больших танцующих человечков!
	if Player1 > 0 then
    	PutBigSymbol(2,22,thing[Player1].VID.CODE,LIGHTWHITE,2,3,0);
	if Player2 > 0 then
    	PutBigSymbol(31,22,thing[Player2].VID.CODE,YELLOW,2,3,0);

// число патронов
	 LOCATE (24, 4); SCOLOR (7);
	 s:=Format('%2d %2d %2d',[Weapons[1][1],Weapons[1][2],Weapons[1][3]]);
	 MYPRINT (s);

	 LOCATE (24, 33); SCOLOR (7);
	 s:=Format('%2d %2d %2d',[Weapons[2][1],Weapons[2][2],Weapons[2][3]]);
	 MYPRINT (s);

// Lives
	LOCATE(22,5);SCOLOR(GREEN);
//    if Player1 > 0 then begin
    	s:=Format('%2d',[{thing[Player1].HP}Pl1HP]);
		MYPRINT(s);
//    end;

	LOCATE(22,34);SCOLOR(GREEN);
//    if Player2 > 0 then begin
		s:=Format('%2d', [{thing[Player2].HP}Pl2HP]);
		MYPRINT(s);
//    end;

// Выводим тип оружия, выбранное игроком - инверсией
    PutBigSymbol(4, 23, 153, RED, 2, 1,0);
	PutBigSymbol(7, 23, 156, CYAN, 2, 1,0);
	PutBigSymbol(10, 23, 154, MAGENTA, 2, 1,0);
	if Player1 > 0 then
	 CASE thing[Player1].GUN of
		 1: PutBigSymbol(4, 23, 153, RED, 2, 1,3);		// INVERSE
		 2: PutBigSymbol(7, 23, 156, CYAN, 2, 1,3);		// INVERSE
		 3: PutBigSymbol(10, 23, 154, MAGENTA, 2, 1,3);	// INVERSE
	 END;

    PutBigSymbol(33, 23, 153, RED, 2, 1,0);
	PutBigSymbol(36, 23, 156, CYAN, 2, 1,0);
	PutBigSymbol(39, 23, 154, MAGENTA, 2, 1,0);
	if Player2 > 0 then
	 CASE thing[Player2].GUN of
		 1: PutBigSymbol(33, 23, 153, RED, 2, 1,3);		// INVERSE
		 2: PutBigSymbol(36, 23, 156, CYAN, 2, 1,3);		// INVERSE
		 3: PutBigSymbol(39, 23, 154, MAGENTA, 2, 1,3);	// INVERSE
	 END;
end; { WriteBoard }
////////////////////////////////////////////////////////////////////////////////
procedure WriteInitBoard;
var s:string;
//	i:integer;
begin
// выводим номер уровня
    LOCATE (22, 15); SCOLOR(RED);
    MYPRINT('Level');
    s := Format('%2d',[Level]);
    PutBigSymbol(18,23,ord(s[1]),WHITE,1,2,0);
	PutBigSymbol(19,23,ord(s[2]),WHITE,1,2,0);

// Выводим больших человечков в стоячей позе
//	PutBigSymbol(1,22,ord(' '),LIGHTWHITE,1,3,0);
   	PutBigSymbol(2,22,144,LIGHTWHITE,2,3,0);
   	PutBigSymbol(31,22,144,YELLOW,2,3,0);

// число патронов
	 LOCATE (24, 4); SCOLOR (7);
	 MYPRINT(Format('%2d %2d %2d',[Weapons[1][1],Weapons[1][2],Weapons[1][3]]));
	 LOCATE (24, 33); SCOLOR (7);
	 MYPRINT(Format('%2d %2d %2d',[Weapons[2][1],Weapons[2][2],Weapons[2][3]]));

// Lives
	PutSymbol(4,22,HEART,MAGENTA,0);
	LOCATE(22,5);SCOLOR(GREEN);
//    if Player1 > 0 then
		MYPRINT(Format('%2d',[{thing[Player1].HP}Pl1HP]));
//    else MYPRINT(' 0');

  	PutSymbol(33,22,HEART,MAGENTA,0);
	LOCATE(22,34);SCOLOR(GREEN);
//    if Player2 > 0 then
		MYPRINT(Format('%2d',[{thing[Player2].HP}Pl2HP]));
//    else MYPRINT(' 0');

// Выводим тип оружия, выбранное игроком - инверсией
    PutBigSymbol(4, 23, 153, RED, 2, 1,0);
	PutBigSymbol(7, 23, 156, CYAN, 2, 1,0);
	PutBigSymbol(10, 23, 154, MAGENTA, 2, 1,0);
	if Player1 > 0 then
	 CASE thing[Player1].GUN of
		 1: PutBigSymbol(4, 23, 153, RED, 2, 1,3);		// INVERSE
		 2: PutBigSymbol(7, 23, 156, CYAN, 2, 1,3);		// INVERSE
		 3: PutBigSymbol(10, 23, 154, MAGENTA, 2, 1,3);	// INVERSE
	 END;

    PutBigSymbol(33, 23, 153, RED, 2, 1,0);
	PutBigSymbol(36, 23, 156, CYAN, 2, 1,0);
	PutBigSymbol(39, 23, 154, MAGENTA, 2, 1,0);
	if Player2 > 0 then
	 CASE thing[Player2].GUN of
		 1: PutBigSymbol(33, 23, 153, RED, 2, 1,3);		// INVERSE
		 2: PutBigSymbol(36, 23, 156, CYAN, 2, 1,3);		// INVERSE
		 3: PutBigSymbol(39, 23, 154, MAGENTA, 2, 1,3);	// INVERSE
	 END;
end; { WriteInitBoard }

end.

