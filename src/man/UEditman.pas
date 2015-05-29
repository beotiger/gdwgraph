Unit UEditMan;
{	Переделанная с QuickBasic'а программа! 						}
{ на Дельфи-7, используя библиотеку gdwGraph для режима VGA-13, }
{ адаптированного под обычное окно Windows						}
interface

procedure Main;

{	ВНИМАНИЕ! Программа выходит без предупреждения,				}
{ 	если при старте не может прочитать файл MAN.CHR 			}

implementation

uses SDLglGdwGraph, SysUtils, sdl;

procedure GetSymbol (var Code:word; var ATTR:byte); forward;
procedure SelectAttr (var A:byte); forward;
procedure CreateSymbol; forward;
procedure Editor; forward;

procedure RestoreScreen (xl:integer; yu:integer; xr:integer; yd:integer);forward;	// восстановить экран
procedure SaveScreen (xUp:integer; yUp:integer; xDwn:integer; yDwn:integer);forward;

procedure Ramka (xl:integer; yu:integer; xr:integer; yd:integer);forward;
procedure RepeatSymbol (x:integer; y:integer; Code:word; ATTR:byte; number:integer);forward;

procedure PutBoss (x:integer; y:integer; Code:word; ATTR:byte);forward;
procedure SetBoss (x:integer; y:integer; Code:word; ATTR:byte);forward;

procedure CreateWindow (lx:integer; uy:integer; rx:integer; dy:integer); forward;
procedure CloseWindow (lx:integer; uy:integer; rx:integer; dy:integer);  forward;


{ ЦВЕТА }
const BLACK = 0; BLUE = 1; GREEN = 2; CYAN = 3; RED = 4; MAGENTA = 5; BROWN = 6; WHITE = 7;
		GREY = 8; LIGHTBLUE = 9; LIGHTGREEN = 10; LIGHTCYAN = 11; LIGHTRED = 12;
         LIGHTMAGENTA = 13; YELLOW = 14; LIGHTWHITE = 15;

{ СИМВОЛЫ }
const SKULL = 128; WEAPON = 129; TEN = 130; APPLE = 131; CROSS = 132;
		TREE = 133; HEART = 134; BRICK = 135; STAIR = 136; TREASURE = 166; MAN = 144; MANR = 146;
		MANL = 149; MANUD = 141; UPLINE = 171; EMPTY = 178; STAR = 42; GRAVE = 157;
        BUTT1 = 183; BUTT2 = 182;	// бабочка из HERO (nice Apple2 game)


const	STOCKATTR:array[1..10] of word = (4,3,5,6,1,15,14,0,0,0);
		UNITSTOCK:array[1..{7}10] of Symbol = (
             (Code:EMPTY;Attr: WHITE),(Code:BRICK;Attr:12),(Code:STAIR;Attr:13),(Code:APPLE;Attr:7),
			 (Code:HEART;Attr:5),(Code:CROSS;Attr:8),(Code:TREE;Attr:10),
			 (Code:TREASURE;Attr:65),(Code:BUTT1;Attr:47),(Code:164;Attr:WHITE)
			 );
		BOSSSTOCK:array[1..3] of Symbol = (
             (Code:215;Attr:24),(Code:223;Attr:43),(Code:240;Attr:70));
		CARDSSTOCK:array[1..3] of Symbol = (
             (Code:203;Attr:77),(Code:207;Attr:91),(Code:211;Attr:29));
		ARROW:array[1..4] of word = (167,170,168,169);
		NOTHING:Symbol = (Code: EMPTY; Attr:7);

const
	MapY = 20; MapX = 40;	// размер карты уровня по вертикали и горизонтали
	MaxLevel = 10;	// максимальное кол-во уровней

var
    MAP: array [1..MapY,1..MapX] of Symbol;
	tSymbol:Symbol;
	EKR: array of Symbol; { динамически массив? КРУТО! }
	loct: Pixel;	// для locate - курсор
	colt: byte;		// для scolor - цвет символов

//    Key:word;	// global var for Keyboard presses codes, ha-ha
    Level: word;	// global var for current editing LEVEL

function pow(a,x:integer):integer;
// A simple power function a ^ x??
var
	t,i:integer;
begin
	if x = 0 then pow := 1
	else begin
		t:=a;
		for i:=1 to x-1 do
			t:=t*a;
		pow:=t;
	end;
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
	loct.X := loct.X + Length(S);
end;

function WaitWithKey(Tics:Longword; var smod:word):word;	// ждем Tics тиков или нажатия клавиши
var Time:Longword;Key:word;
begin
	Time:=WhatTime+Tics*TimeZoom;
    Key:=Inkey;// сбросим клавишу

    while (Key = 0) and (WhatTime<Time) do Key := EInkey(smod);{ пустой оператор }
	WaitWithKey := Key;
end;


const SymFileName = 'MAN.CHR';	// таблица символов игры MAN????  --  исправить

procedure Main;
begin                   {///////////////MAIN\\\\\\\\\\\\\}
	colt := 15;	// init color
	
	if LoadSymData(SymFileName)<>0 then
	begin
		writeln('Can not find file ' + SymFileName);
		halt(255);
	end;
	
	InitGraph('MAN | Level and symbol editor');	// инициализируем графику
//	LoadTable;// тоже что LoadSymData???
	Editor;
	CloseGraph;
	halt;
end;                    {//////////////MAIN\\\\\\\\\\\\\\\}


procedure CloseWindow (lx, uy, rx, dy:integer);
begin
	RestoreScreen(lx, uy, rx, dy)
end;

// ....................................... //
// создание большого символа (16*16 точек)
// ....................................... //
procedure CreateSymbol;
var
	yCur, xCur, gClr:integer;
    cSym:word;	// код символа
    mPen,mDouble:boolean;
	IM,SIM:array[1..16,1..16] of word;
    i:integer;
	xPos, yPos: integer;
    ADRESS:word;
    s:string;

	procedure OpenIt;
    begin
	 Ramka(2, 1, 19, 18);Ramka(20, 16, 23, 19);
	 LOCATE( 19, 3);
	 SCOLOR( MAGENTA);
	 MYPRINT('x=');
	 LOCATE(20, 3);
	 MYPRINT('y=');
	end; // OpenIt

	// печать служебной информации?
	procedure PrintLittleOnes;
	var S:string;
	begin
	// напечатаем сами символы (4 штуки) 8*8 точек
	 PutSymbol(21, 17, cSym, LIGHTMAGENTA,0);
	 PutSymbol(22, 17, cSym + 1, LIGHTMAGENTA,0);
	 PutSymbol(21, 18, cSym + 2, LIGHTMAGENTA,0);
	 PutSymbol(22, 18, cSym + 3, LIGHTMAGENTA,0);

	 // голубым цветом напечатаем коды текущих символов
	 SCOLOR (BLUE);
	 LOCATE (16, 24);
	 s := Format('%3d',[cSym]);
	 MYPRINT(s);
	 LOCATE (17, 24);
	 s := Format('%3d',[cSym+1]);
	 MYPRINT(s);
	 LOCATE (18, 24);
	 s := Format('%3d',[cSym+2]);
	 MYPRINT(s);
	 LOCATE (19, 24);
	 s := Format('%3d',[cSym+3]);
	 MYPRINT(s);
	end;

	function CountSTARS(i,j:integer):integer;	// подсчитаем звездочки ^_^
	var A:integer;
	begin
	 A := 0;
	 IF IM[i, j] = STAR THEN A := A + 1;
	 IF IM[i, j + 1] = STAR THEN A := A + 1;
	 IF IM[i + 1, j] = STAR THEN A := A + 1;
	 IF IM[i + 1, j + 1] = STAR THEN A := A + 1;
	 CountStars := A
	end;

	procedure SIM2IM;	// копируем массив SIM в массив IM
	var i,j:integer;
	begin
	 FOR i := 1 TO 16 do FOR j := 1 TO 16 do
	  IM[i, j] := SIM[i, j];
	end;

	procedure SIM8IM;	// копируем часть массива (8*8 точек)
	var i,j:integer;
	begin
	 FOR i := yPos TO yPos + 7 do FOR j := xPos TO xPos + 7 do
	  IM[i, j] := SIM[i, j];
	end;

	procedure SetorDelBit;	{ установим или сотрем звездочку }
	begin
	 IF IM[yCur, xCur] = EMPTY THEN IM[yCur, xCur] := STAR ELSE IM[yCur, xCur] := EMPTY;
	 PutSymbol(2 + xCur,1 + yCur,IM[yCur, xCur], LIGHTGREEN,0);	// выведем этот символ на экран
	 IF mDouble THEN begin // есть перо-дубляр
	  IF IM[yCur, 17 - xCur] = EMPTY THEN IM[yCur, 17 - xCur] := STAR ELSE IM[yCur, 17 - xCur] := EMPTY;
	  PutSymbol(2 + 17 - xCur, 1 + yCur, IM[yCur, xCur], LIGHTGREEN,0);	// выведем и этот символ на экран
	 END // if mDouble
	end; // SetorDelBit

	procedure SetBit; { установим звездочку }
	begin
		IM[yCur, xCur] := STAR;
		PutSymbol(2 + xCur,1 + yCur, IM[yCur, xCur], LIGHTGREEN,0);	// выведем этот символ на экран
		IF mDouble THEN begin
		IM[yCur, 17 - xCur] := STAR;
		PutSymbol(2 + 17 - xCur, 1 + yCur, IM[yCur, xCur], LIGHTGREEN,0);	// выведем и этот символ на экран
		END;
	end;

	procedure LocSym;
	begin
		 IF xCur < 9 THEN xPos := 1 ELSE xPos := 9;
		 IF yCur < 9 THEN yPos := 1 ELSE yPos := 9;
	end;

	function iSAVE:byte;
	{  сохраняет таблицу символов на диске }
	var F:file;
	begin
	{$I-}
		  Assign(F,SymFileName);
		  ReWrite(F,1);
		  IF IOResult <> 0 THEN begin
			 iSAVE:=2;exit
		  end {if};
		  BlockWrite(F,SymData,SymDataSize);
		  Close(F);
	{$I+}
		  iSAVE:=IOResult
	end;

	procedure iPRINT;
	var i,j:integer;
	begin
	 FOR i := 1 TO 16 do FOR j := 1 TO 16 do
		PutSymbol(2 + j, 1 + i, IM[i, j], LIGHTGREEN, 0);
	end;

	procedure BYNtoSTR(BYN:integer);
	// преобразуем байт BYN в строку EMPTY,STAR в зависимости от битов (0-EMPTY, 1- STAR)
	var N,t:integer;
	begin
	 t := xPos;
	 FOR N := 7 DOWNTO 0 do begin
	  IF BYN - pow(2,N) < 0 THEN IM[yPos, t] := EMPTY
	  ELSE begin
			IM[yPos, t] := STAR;
			BYN := BYN - pow(2,N);
	  end;// else
	  t := t + 1
	 end;
	end;

	procedure PreobHEX;	// преобразуем байт в 8 точек в xPos,yPos позиции поля
	var j:integer;
	begin
	 FOR j := 1 TO 8 do begin
	  BYNtoSTR(SymData[ADRESS]);
	  ADRESS := ADRESS + 1;
	  yPos := yPos + 1;
	 end;// for j
	end; // PreobHEX

	procedure iGET;			// получить символ
	begin
	 // PrintLittleOnes;
	 ADRESS := cSym * 8;	// адрес символа в таблице SymData
	// DEF SEG = &H7000
	 xPos := 1; yPos := 1; PreobHEX;
	 xPos := 9; yPos := 1; PreobHEX;
	 xPos := 1; yPos := 9; PreobHEX;
	 xPos := 9; yPos := 9; PreobHEX;
	// DEF SEG :
	 // iPRINT;
	end;

	function STRtoBYN:byte;
	// обратное BYNtoSTR преобразование
	var
		N:integer;
		BYN:byte;
	begin
	 BYN := 0;
	 FOR N := 8 DOWNTO 1 do
	  IF IM[yPos, xPos + N - 1] <> EMPTY THEN BYN := BYN + 1 * pow(2,(9 - N - 1));
	 STRtoBYN := BYN;
	end;

	procedure PreobDec;
    var i:integer;
	begin

	 FOR i := 1 TO 8 do begin
	  SymData[ADRESS] :=StrtoBYN;
	  ADRESS := ADRESS + 1;
	  yPos := yPos + 1;
	 end;
	end;// PreobDex

	procedure iPUT;
	begin
	 ADRESS := cSym * 8;	// начальное смещение символа в таблице Symdata
	 xPos := 1; yPos := 1; PreobDec;
	 xPos := 9; yPos := 1; PreobDec;
	 xPos := 1; yPos := 9; PreobDec;
	 xPos := 9; yPos := 9; PreobDec;
	 // PrintLittleOnes;
	end;


	function KeyDisp(Key,smod:word):boolean;	// returns true if need to exit
    var i,j,x,y:integer;
    	nothing:byte;	// пустая переменная для получения кода символа
	begin
	 KeyDisp := false;	// no quit
	 CASE Key of
		SDLK_SPACE: SetorDelBit;	// dot
		SDLK_ESCAPE: KeyDisp := true; // quit flag
		SDLK_TAB:
			IF (xCur < 9) AND (yCur < 9) THEN xCur := xCur + 8
			ELSE IF yCur < 9 THEN begin yCur := yCur + 8; xCur := xCur - 8 end
			ELSE IF xCur < 9 THEN xCur := xCur + 8
			ELSE begin xCur := xCur - 8; yCur := yCur - 8 end;

        SDLK_F1: if smod and KMOD_CTRL <> 0 then
		begin
		   FOR i := 1 TO 16 do
			FOR j := 1 TO 16 do
				IF IM[i, j] = STAR THEN IM[i, j] := EMPTY ELSE IM[i, j] := STAR;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR i := yPos TO yPos + 7 do FOR j := xPos TO xPos + 7 do
			IF IM[i, j] = STAR THEN IM[i, j] := EMPTY ELSE IM[i, j] := STAR;
		   // iPRINT;
		end;
		SDLK_F2: if smod AND KMOD_CTRL <> 0 then
		begin
		   FOR i := 1 TO 16 do
			FOR j := 1 TO 16 do
				SIM[j, i] := IM[i, j];
		   SIM2IM;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR i := 1 TO 8 do FOR j := 1 TO 8 do
				SIM[i, j] := IM[yPos + i - 1, xPos + j - 1];
		   FOR i := 1 TO 8 do FOR j := 1 TO 8 do
				SIM[j + 8, i + 8] := SIM[i, j];
		   FOR i := 1 TO 8 do FOR j := 1 TO 8 do
				IM[yPos + i - 1, xPos + j - 1] := SIM[i + 8, j + 8];
		   // iPRINT;
		end
        else mDouble := NOT (mDouble);
		SDLK_F3: if smod and KMOD_CTRL <> 0 then
		begin
			FOR i := 1 TO 16 do
				FOR j := 1 TO 16 do
					SIM[i, 17 - j] := IM[i, j];
			SIM2IM;
			// iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   IF xPos = 1 THEN
			FOR i := yPos TO yPos + 7 do
			 FOR j := xPos TO xPos + 7 do
			  SIM[i, 9 - j] := IM[i, j]
		   ELSE
			FOR i := yPos TO yPos + 7 do
			 FOR j := xPos TO xPos + 7 do
			  SIM[i, 17 - j + 8] := IM[i, j];
		   SIM8IM;
		   // iPRINT;
		end
        else iPUT;	// put big symbol into charset
		SDLK_F4: if smod and KMOD_CTRL <> 0 then
		begin
		   FOR i := 2 TO 16 do
			FOR j := 1 TO 16 do
				IM[i - 1, j] := IM[i, j];
		   FOR j := 1 TO 16 do IM[16, j] := EMPTY;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR i := yPos + 1 TO yPos + 7 do
			FOR j := xPos TO xPos + 7 do
			 IM[i - 1, j] := IM[i, j];
		   FOR j := xPos TO xPos + 7 do IM[yPos + 7, j] := EMPTY;
		   // iPRINT;
		end
        else iGET;	// reget it from charset
		SDLK_F5: if smod and KMOD_CTRL <> 0 then
		begin
		   FOR i := 15 DOWNTO 1 do
			FOR j := 1 TO 16 do
				IM[i + 1, j] := IM[i, j];
		   FOR j := 1 TO 16 do IM[1, j] := EMPTY;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR i := yPos + 6 DOWNTO yPos do
			FOR j := xPos TO xPos + 7 do
			 IM[i + 1, j] := IM[i, j];
		   FOR j := xPos TO xPos + 7 do IM[yPos, j] := EMPTY;
		   // iPRINT;
		end
        else
        mPen := NOT (mPen);
		SDLK_F6: if smod and KMOD_CTRL <> 0 then
		begin
		   FOR j := 15 DOWNTO 1 do
			FOR i := 1 TO 16 do
				IM[i, j + 1] := IM[i, j];
		   FOR i := 1 TO 16 do IM[i, 1] := EMPTY;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR j := xPos + 6 DOWNTO xPos do
			FOR i := yPos TO yPos + 7 do
			 IM[i, j + 1] := IM[i, j];
		   FOR i := yPos TO yPos + 7 do IM[i, xPos] := EMPTY;
		   // iPRINT;
		end
		else
		begin
			GetSymbol(cSym, nothing);	// быстрый выбор символа
			OpenIt;
			IF cSym > 252 THEN cSym := 252;
			iGET;
		end;

		SDLK_F7: if smod and KMOD_CTRL <> 0 then
		begin
		   FOR j := 2 TO 16 do
			FOR i := 1 TO 16 do
				IM[i, j - 1] := IM[i, j];
		   FOR i := 1 TO 16 do IM[i, 16] := EMPTY;
		   // iPRINT;
		end
        else if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   FOR j := xPos + 1 TO xPos + 7 do
			FOR i := yPos TO yPos + 7 do
			 IM[i, j - 1] := IM[i, j];
		   FOR i := yPos TO yPos + 7 do IM[i, xPos + 7] := EMPTY;
		   // iPRINT;
		end
        else
        begin LoadSymData(SymFileName);iGET end;

		SDLK_F8: if smod and KMOD_SHIFT <> 0 then
        begin
	        IF gClr = 15 THEN gClr := 0 ELSE gClr := 15;
        end
        else
        if smod and KMOD_CTRL <> 0 then
		begin
		   x := 1; y := 1;
			i:=1;
			while i <= 16 do begin
				j:=1;
				while j <= 16 do begin

					IF CountSTARS(i,j) > 1 THEN SIM[y, x] := STAR ELSE SIM[y, x] := EMPTY;
					x := x + 1;
					j:=j+2;
				end;	// while j
				x := 1; y := y + 1;
				i:=i+2;
			end; //while i
		   FOR i := 1 TO 16 do FOR j := 1 TO 16 do IM[i, j] := EMPTY;
		   LocSym;
		   FOR i := 1 TO 8 do FOR j := 1 TO 8 do
				IM[yPos + i - 1, xPos + j - 1] := SIM[i, j];
		   // iPRINT;
		end // case Ctrl_F8
		else
        if smod and KMOD_ALT <> 0 then
		begin
		   LocSym;
		   x := 1; y := 1;
		   FOR i := yPos TO yPos + 7 do begin
			   FOR j := xPos TO xPos + 7 do begin
				SIM[y, x] := IM[i, j];
				SIM[y, x + 1] := IM[i, j];
				SIM[y + 1, x] := IM[i, j];
				SIM[y + 1, x + 1] := IM[i, j];
				x := x + 2
			   end; // for j
			   x := 1; y := y + 2
		   end; // for i
		   SIM2IM;
		   // iPRINT;
		end
		else iSAVE;	// save charset to file
		
		SDLK_F9: if smod and KMOD_SHIFT <> 0 then
        begin
			FOR i := 1 TO 16 do
				FOR j := 1 TO 16 do
					IM[i, j] := EMPTY;
			// iPRINT;
		end
        else
		begin
			LocSym;
			 FOR i := yPos TO yPos + 7 do
			  FOR j := xPos TO xPos + 7 do
			   IM[i, j] := EMPTY;
			// iPRINT;
		end;

		SDLK_F10:
		begin
			iSAVE;
			KeyDisp:=true;
		end;

	  // Page Up/Down
		SDLK_PAGEUP: IF cSym - 4 > 127 THEN begin cSym := cSym - 4; iGET; end;
		SDLK_PAGEDOWN: IF cSym + 4 < 253 THEN begin cSym := cSym + 4; iGET; end;

		// MOVE PEN
		SDLK_LEFT:
		begin
			IF mPen THEN SetBit;
			IF xCur > 1 THEN xCur := xCur - 1;
		end;
		SDLK_RIGHT:
		begin
			IF mPen THEN SetBit;
			IF xCur < 16 THEN xCur := xCur + 1;
		end;
		SDLK_UP:
		begin
		   IF mPen THEN SetBit;
		   IF yCur > 1 THEN yCur := yCur - 1;
		end;
		SDLK_DOWN:
		begin
		   IF mPen THEN SetBit;
		   IF yCur < 16 THEN yCur := yCur + 1;
		end;
	  END; //case
	END;	// function KeyDisp



var
	LOC,LOC2:Pixel;
	mPaus, Key,smod:word;
	whatSym: boolean = true;
	
begin	// CreateSym
//	IF xCur = 0 THEN begin

// do some initialization
	xCur := 1; yCur := 1;	// курсор
	cSym := 128;			// редактируемый символ (1-ый из 4-х)
	gClr := 15; 			// его цвет
	mPen := false;	// перо поднято, дубляра нету
  mDouble := false;	//

	iGET;

 REPEAT
	FOR i := 1 TO 20 do RepeatSymbol(1, i, 178, 7, 40);
	OpenIt;	// рамка + инфо
	PrintLittleOnes;

	LOCATE(2, 22);SCOLOR(13);MYPRINT('F2 DOUBLE F5 PEN');
	LOCATE(3, 22);MYPRINT('F3 PUT    F6 PICK');
	LOCATE(4, 22);MYPRINT('F4 GET    F7 READ');
	LOCATE(5, 22);MYPRINT('F8 SAVE   F9 CLEAR');
	LOCATE(6, 22);MYPRINT('F  SAVE&QUIT');
	PutSymbol(23,6,TEN,13,0);

	SCOLOR(7);LOCATE(7, 22);MYPRINT('PgUP,PgDWN LIST');
	SCOLOR(11);LOCATE(8, 22);MYPRINT('Alt,Ctrl+  F4 UP');
	LOCATE (9, 22); MYPRINT ('F1 INVERSE F5 DOWN');
	LOCATE (10, 22); MYPRINT ('F2 ROTATE  F6 RGHT');
	LOCATE (11, 22); MYPRINT ('F3 REVERSE F7 LEFT');
	LOCATE (12, 22); MYPRINT ('F8 SIZE');
	SCOLOR(7); LOCATE(13, 22); MYPRINT ('Tab tabulate');
	LOCATE(14, 22); MYPRINT ('SPACE set/del pix'); {'or del pixel}
	LOCATE(15, 22); MYPRINT ('ESC quit');
	SCOLOR(13); LOCATE(16, 30); MYPRINT ('Shift');
	LOCATE( 17, 30); MYPRINT ('F8 GRID');
	LOCATE(18, 30); MYPRINT ('F9 CLEAR');

//	iGET;
	iPrint;

	// выводим курсор
  if whatSym then 
	begin 
		PutSymbol(2 + xCur,1 + yCur, word('X'), WHITE, 0);
		// в двойном режиме выведем и этот символ на экран
		if mDouble then PutSymbol(2 + 17 - xCur, 1 + yCur, word('X'), WHITE, 0);
		mPaus := 7; 
	end
  else
	begin
		PutSymbol(2 + xCur, 1 + yCur, IM[yCur, xCur], LIGHTGREEN, 0);
		if mDouble then PutSymbol(2 + 17 - xCur, 1 + yCur, IM[yCur, 17 - xCur], LIGHTGREEN, 0);		
		mPaus := 12;
	end;

  whatSym := not whatSym;

  LOCATE (19, 5);Scolor(LIGHTCYAN);
  s:=Format('%2d',[xCur]);MYPRINT(s);
  LOCATE(20, 5);   s:=Format('%2d',[yCur]);MYPRINT(s);
  LOC.X:=80;LOC.Y:=0;LOC2.X:=80;LOC2.Y:=144;
  PutLine(LOC,LOC2, gClr);
  LOC.X:=8;LOC.Y:=72;LOC2.X:=152;LOC2.Y:=72;
  PutLine(LOC,LOC2, gClr);

	gdwSwapBuf;

  Key := WaitWithKey(mPaus, smod);	{ пауза до нажатия клавишы? }

//  PutSymbol(2 + xCur, 1 + yCur, IM[yCur, xCur], LIGHTGREEN,0);

//	gdwSwapBuf;


//  IF Key = 0 THEN Key:=WaitWithKey(5,smod);

  IF Key<>0 then
	if(KeyDisp(Key,smod)) then break	// обработаем нажатую клавишу

 UNTIL FALSE
end; {CreateSymbol}
{end of CreateSymbol}


/////////////////////////////////////////////////////////////////
// END OF CreateSymbol
/////////////////////////////////////////////////////////////////


procedure CreateWindow (lx, uy, rx, dy:integer);
begin
 SaveScreen(lx, uy, rx, dy);
 Ramka(lx, uy, rx, dy);
END;

  /////////////////////////////////////////////////////
 //             САМ ЕГО ВЕЛИЧЕСТВО РЕДАКТОР!        //
/////////////////////////////////////////////////////
procedure Editor;
CONST sCurs = 88;

var CurX, CurY: integer;	// курсор
	sUnit:word;	// код
	aUnit:byte;	// атрибут
	sDir:byte;	// направление пера
	item:word;	// выбранный предмет?
	Exitflag: boolean;	// флаг выхода
	Key,smod:word;		// код нажатия

	Code:word;	// ??? где он инициализируется?

	procedure iNEW;	// новый
	var i,j:integer;
	begin
		 CurX := 1;
		 CurY := 1;
		 FOR i := 1 TO MapY do
         	FOR j := 1 TO MapX do begin
			  MAP[i, j].Code := 178;
			  MAP[i, j].ATTR := 7;
		 end;

		 sUNIT := 178;
		 aUNIT := WHITE;
		 sDIR := 1;
		 item := 1
	end;

	procedure OpenLevel;
	var i,j:integer;
	begin
	 FOR i := 1 TO MapY do
		FOR j := 1 TO MapX do
			PutSymbol(j, i, MAP[i, j].Code, MAP[i, j].ATTR,0);
	end;

	procedure LoadLevel; // загрузка уровня с диска
	var
		F:TextFile;
		s:string;
		i,j: integer;

	begin
	{$I-}
		// уровень называется типа LEVEL1.MAN, LEVEL2.MAN .. LEVEL10.MAN и т.д.
		Assign(F, 'LEVEL' + IntToStr(Level) + '.MAN');
		Reset(F);
		if IOResult = 0 then
        begin
	{$I+}
		   FOR i := 1 TO MapY do
			FOR j := 1 TO MapX do begin
				Readln(F,s);	// читаем код символа
				MAP[i, j].Code := StrToIntDef(trim(s),0);		// преобразуем и помещаем в карту
				Readln(F,s);	// читаем его атрибут
				MAP[i, j].ATTR := StrToIntDef(trim(s),0);		// преобразуем и помещаем в карту
	       end;//for j
	  		Close(F);
    	end;
	  OpenLevel;	// покажем загруженный уровень
	end; // LoadLevel

	procedure PutStatusLine;
	var s:string;
	begin
		LOCATE( 23, 1); SCOLOR (15);
		s:=Format('%2d',[CurY]);
		MYPRINT(s);
		s:=Format('%2d',[CurX]);
		MYPRINT (' ' + s);
		PutSymbol(8, 23, sUNIT, aUNIT,0);
		PutSymbol(12, 23, ARROW[sDIR], 15,0);
		LOCATE (23, 17); MYPRINT(Format('%2d',[Level]));
	end; //

	procedure KeyDriver;	// обработка нажатия клавиши в основном редакторе уровней
	var i:integer;
		procedure ShiftCursor;	// двигаем курсор в зависимости от нарпавления sDIR (1..4)
		begin
		 CASE sDIR of
		  1:
			  IF CurX < MapX THEN CurX := CurX + 1
			  ELSE IF CurY < MapY THEN begin CurX := 1; CurY := CurY + 1; end;
		  2:
			   IF CurY < MapY THEN CurY := CurY + 1
			   ELSE IF CurX < MapX THEN begin CurY := 1; CurX := CurX + 1 end;
		  3:
		   IF CurX > 1 THEN CurX := CurX - 1
		   ELSE IF CurY > 1 THEN begin CurX := MapX; CurY := CurY - 1 end;
		  4:
		   IF CurY > 1 THEN CurY := CurY - 1
		   ELSE IF CurX > 1 THEN begin CurY := MapY; CurX := CurX - 1 end;
		  END; // case
		end; // shiftcursor

		procedure Set1Unit;
		begin
		 MAP[CurY, CurX].Code := sUNIT;
		 MAP[CurY, CurX].ATTR := aUNIT;
		 PutSymbol(CurX, CurY, sUNIT, aUNIT,0);
		 ShiftCursor;
		end;

		procedure SaveLevel;	// сохранение текущего уровня на диск
		var
			F:TextFile;
			i,j: integer;
		begin
		// уровень называется типа LEVEL1.MAN, LEVEL2.MAN .. LEVEL10.MAN
			Assign(F, 'LEVEL' + IntToStr(Level) + '.MAN');
			Rewrite(F);

			for i := 1 to MapY do
				for j := 1 to MapX do begin
					Writeln(F,IntToStr(MAP[i, j].Code));		// пишем в файл код символа
					Writeln(F,IntToStr(MAP[i, j].ATTR));		// и его атрибут (цвет?)
				end;
		 Close(F);
		end; // SaveLevel
////////////////////////////////////////////////////////////////////////////////
		const myitem:integer=1;	// for choosing items
		procedure ChooseNewItem{(items:word)};
		// выберем предмет из UNITSTOCK
		var i,uy,ux,dy,dx,items:integer;
		begin
			items := High(UNITSTOCK);
			if myitem < 1 then myitem := 1;
			if myitem > items then myitem:=items;
			 uy := CurY - 1;
			 IF uy < 1 THEN uy := 1;
			 IF uy + 2 > MapY THEN uy := 18;
			 ux := CurX - items div 2;
			 IF ux < 1 THEN ux := 1;
			 IF ux + items + 1 > MapX THEN ux := MapX - items - 1;
			 dy := uy + 2;
			 dx := ux + items + 1;
			 
			 while true do begin
				 CreateWindow(ux, uy, dx, dy);
				 FOR i := 1 TO items do
					PutSymbol(ux + i, uy + 1, UNITSTOCK[i].Code, UNITSTOCK[i].Attr,0);
			 
			  PutSymbol(ux + myitem, uy + 1, UNITSTOCK[myitem].Code, UNITSTOCK[myitem].Attr,3);	// put INVERSE
				
				Inkey;
				Key := 0;
				gdwSwapBuf;
				while Key = 0 do Key:=Inkey;	// ждём нажатия клавиши

				PutSymbol(ux + myitem, uy + 1, UNITSTOCK[myitem].Code, UNITSTOCK[myitem].Attr,0);

				IF Key = SDLK_RETURN THEN begin		// выбрали предмет
					sUNIT := UNITSTOCK[myitem].Code;
					aUNIT := UNITSTOCK[myitem].Attr;
					CloseWindow(ux, uy, dx, dy);
					exit;	//ChooseNewItem
				end;
				IF Key = SDLK_ESCAPE THEN begin CloseWindow(ux, uy, dx, dy); exit; end;	// выход без выбора предмета
				IF (Key = SDLK_LEFT) AND (myitem > 1) THEN myitem := myitem - 1;		// перемещение курсора
				IF (Key = SDLK_RIGHT) AND (myitem < items) THEN myitem := myitem + 1;
			 end // while true
		end;// ChooseNewItem
////////////////////////////////////////////////////////////////////////////////////
		procedure ChooseItem(items:word);
		// выберем оружие или человека (ЦВЕТ)
		var i,uy,ux,dy,dx:integer;
		begin
			if item < 1 then item := 1;
			if item > items then item:=items;
			 uy := CurY - 1;
			 IF uy < 1 THEN uy := 1;
			 IF uy + 2 > MapY THEN uy := 18;
			 ux := CurX - items div 2;
			 IF ux < 1 THEN ux := 1;
			 IF ux + items + 1 > MapX THEN ux := MapX - items - 1;
			 dy := uy + 2;
			 dx := ux + items + 1;


			 while true do begin
				 CreateWindow(ux, uy, dx, dy);

				 FOR i := 1 TO items do
					PutSymbol(ux + i, uy + 1, Code, STOCKATTR[i],0);
			 
				  PutSymbol(ux + item, uy + 1, Code, STOCKATTR[item],3);	// put INVERSE

				  Inkey;
          Key := 0;
					gdwSwapBuf;

				  while Key = 0 do Key:=Inkey;	// ждём нажатия клавиши

				  PutSymbol(ux + item, uy + 1, Code, STOCKATTR[item],0);

				  IF Key = SDLK_RETURN THEN begin		// выбрали предмет
						sUNIT := Code;
						aUNIT := STOCKATTR[item];
						CloseWindow(ux, uy, dx, dy);
						exit;	//ChooseItem
				  end;
				 IF Key = SDLK_ESCAPE THEN begin CloseWindow(ux, uy, dx, dy); exit; end;	// выход без выбора предмета

				 IF (Key = SDLK_LEFT) AND (item > 1) THEN item := item - 1;		// перемещение курсора
				 IF (Key = SDLK_RIGHT) AND (item < items) THEN item := item + 1;
			 end // while true
		end;// ChooseItem

	begin	// KeyDriver
    	if smod and KMOD_CTRL <> 0 then
   		case Key of
		   SDLK_F1..SDLK_F3:	// поместим одного из 3-х боссов?	PutBoss-на экран, SetBoss - в карту уровня
			   IF (CurX < MapX) AND (CurY < MapY) THEN begin
					PutBoss(CurX, CurY, BOSSSTOCK[Key - SDLK_F1 + 1].Code, BOSSSTOCK[Key - SDLK_F1 + 1].ATTR);
					SetBoss(CurX, CurY, BOSSSTOCK[Key - SDLK_F1 + 1].Code, BOSSSTOCK[Key - SDLK_F1 + 1].ATTR);
                    if CurX < (MapX-1) then CurX:=CurX + 2;
			   END;
        end { case }
        else if smod and KMOD_ALT <> 0 then
        case Key of
		   SDLK_F1..SDLK_F3:
			   IF (CurX < MapX) AND (CurY < MapY) THEN begin
				PutBoss(CurX, CurY, CARDSSTOCK[Key - SDLK_F1 + 1].Code, CARDSSTOCK[Key - SDLK_F1 + 1].ATTR);
				SetBoss(CurX, CurY, CARDSSTOCK[Key - SDLK_F1 + 1].Code, CARDSSTOCK[Key - SDLK_F1 + 1].ATTR);
                if CurX < (MapX-1) then CurX:=CurX + 2;
			   END;
        end { case }
        else if smod and KMOD_SHIFT <> 0 then
        case Key of
		   SDLK_F1..SDLK_F7:	// выберем стандартный символ!
		   begin
			   sUNIT := UNITSTOCK[Key - SDLK_F1 + 2].Code;
			   aUNIT := UNITSTOCK[Key - SDLK_F1 + 2].ATTR;
		   end;

		   SDLK_F8: begin Code := MAN; ChooseItem(7); end;	// выбрать человечка?
		   SDLK_F9: begin Code := WEAPON; ChooseItem(3); end; // выбрать оружие?
		   SDLK_F10: {begin sUNIT := EMPTY; aUNIT := 7; end;} // empty symbol
				ChooseNewItem;
        end { case }
	else // no modifiers are set
	  CASE Key of
		   SDLK_RETURN: Set1Unit; // вставим Unit
		   SDLK_SPACE: FOR i := 1 TO 5 do Set1Unit;	// вставим сразу 5 юнитов
		   SDLK_TAB: FOR i := 1 TO 5 do ShiftCursor;	// сдвинем курсор
		   SDLK_ESCAPE: ExitFlag := true;	// установим флаг выхода

		   // перемещение курсора
		   SDLK_LEFT: IF CurX > 1 THEN CurX := CurX - 1;
		   SDLK_UP: IF CurY > 1 THEN CurY := CurY - 1;
		   SDLK_RIGHT: IF CurX < MapX THEN CurX := CurX + 1;
		   SDLK_DOWN: IF CurY < MapY THEN CurY := CurY + 1;

		   SDLK_F2: SaveLevel;			// сохраним тек.уровень
		   SDLK_F3: LoadLevel;		// перезагрузим тек.уровень

		   SDLK_F4: GetSymbol(sUNIT, aUNIT);	// получим символ
		   SDLK_F5: begin sDIR := sDIR + 1; IF sDIR > 4 THEN sDIR := 1; end;	// повернем перо

		   SDLK_F6: begin CreateSymbol;OpenLevel; end; 	// вход в редактор больших символов! (встроеный!!!)

		   SDLK_F7: SelectAttr(aUNIT);	// выберем атрибут
		   SDLK_F9: begin iNEW; OpenLevel; end;  //??? создать новый уровень на месте текущего

		   SDLK_F10: begin SaveLevel; ExitFlag := true; end;	// сохраним уровень и выйдем?

		   SDLK_PAGEUP: begin IF Level > 1 THEN dec(Level) else Level:=MaxLevel; iNEW; LoadLevel; end; // на уровень назад
		   SDLK_PAGEDOWN: begin IF Level < MAxLevel THEN inc(Level) else Level:=1; iNEW; LoadLevel; end;	// на уровень вперед

       SDLK_F12: gdwFullScr;	//  ----  ВНИМАНИЕ, ТЕСТОВАЯ ШТУКА, НЕ РАБОТАЕТ ПОКА!
	  END; // CASE Key
	  PutStatusLine		// обновим строку статуса
	end; // procedure KeyDriver

	procedure OpenScreen;
	var LOC:Pixel;
	begin
		RepeatSymbol(1, 21, UPLINE, 7, 40);
		LOC.X := 2;LOC.Y:= 22;
		PutString(LOC, 'y x UNIT DIR LEVEL', CYAN, 0);
		LOC.X := 1;LOC.Y:= 25;
		PutString(LOC, '2SAVE 3LOAD 5DIR 6CREATE 9NEW  SAVE&QUIT', MAGENTA, 0);
    PutSymbol(31,25,TEN,MAGENTA,0);  // TEN = 10!
	end;

var cspd : integer;	// скорость курсора

begin	// EDITOR
	cspd := 0;
 Level := 1;		// начинаем с первого уровня
 ExitFlag := false;	// флаг выходв в 0
 iNEW;				// init some values
// OpenScreen;		// открываем экран
 LoadLevel;			// загружаем текущий уровень
//  PutStatusLine;

 while ExitFlag = false do begin
	OpenLevel;	// выводим уровень из ЬФЗ
	OpenScreen;		// показываем инфо
	PutStatusLine;	// статусная строка

	tSymbol := MAP[CurY, CurX];

	if(cspd < 5) then
		PutSymbol(CurX, CurY, sCurs, 15,0)					// выводим курсор
	else
//	Key := WaitWithKey(1);	{ пауза до нажатия клавишы? }
		PutSymbol(CurX, CurY, tSymbol.Code, tSymbol.ATTR,0);	// стираем его
	gdwSwapBuf;
	Key := WaitWithKey(1, smod);	{ пауза до нажатия клавишы? }
	IF Key <> 0 THEN begin
		PutSymbol(CurX, CurY, tSymbol.Code, tSymbol.ATTR,0);	// стираем курсор
    	KeyDriver;	// обслужим нажатую клавишу
    end;
	inc(cspd);
	cspd := cspd AND $07;	// так круто! число 0..15
 end;//while ExitFlag

end; // EDITOR????!!!!!!!!!!  yyeeeeeeeeeeeeeeeeaaaaaaaah

///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
//////		END OF EDITOR 																			 //////
///////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////

// ******************************************************************* //
// Дополнительный процедуры создания большого символа и палитры?			 //
// ******************************************************************* //

procedure GetSymbol (var Code:word; var ATTR:byte);		// GetSymbol???
var
	i,j,A,NSym:word;
	s:string;

	Key:word;

	// Вывод символа 8*8 точек в зависимости от его кода в i
	procedure PutIt(i: word; Clr: byte);
	// i - код символа, Clr - attribute
	// Clr - operation, 0 -norm, 3- inv
	begin
		PutSymbol(((i - 128) mod 8) + 8, (i - 128) div 8 + 2, i, 15, Clr);
	end;
	
var Adress1,Adress2:integer;

begin
 NSym := 0;
 
 // i - выбранный код символа
 IF Code > 127 THEN i := Code ELSE i := 128;

 while true do begin
	 CreateWindow(7, 1, 16, 18); 
	 FOR j := 128 TO 255 do PutIt(j, 0);
 
  PutIt(i, 3);
	
  LOCATE (18, 13);
  s:=Format('%3d',[i]);
  MYPRINT(s);
	Key:=0;
  gdwSwapBuf;
  while Key = 0 do Key:=Inkey;			// wait keypress

  IF i <> NSym THEN PutIt(i, 0);
	
//  IF LEN(A$) = 2 THEN
   CASE Key of
		SDLK_LEFT: IF i > 128 THEN i := i - 1;
    SDLK_RIGHT: IF i < 255 THEN i := i + 1;
    SDLK_UP: IF i - 8 > 127 THEN i := i - 8;
    SDLK_DOWN: IF i + 8 < 256 THEN i := i + 8;
    SDLK_INSERT:
		  IF NSym = 0 THEN
		   NSym := i			// запомним текущий символ
		  ELSE begin
				Adress1 := NSym * 8;
				Adress2 := i * 8;

				FOR j := 0 TO 7 do begin			// SWAP symbols
					A := SymData[Adress1 + j];
					SymData[Adress1 + j] := SymData[Adress2 + j];
					SymData[Adress2 + j] := A;
				end; // for j
				
				PutIt(NSym, 0);
				NSym := 0;
		  END;// ELSE

    SDLK_DELETE:		// delete or copy symbol
			IF NSym = 0 THEN begin
			 Adress1 := i * 8;
			 FOR j := 0 TO 7 do
				SymData[Adress1 + j]:=0;
				IF i < 255 THEN begin PutIt(i, 0); i := i + 1 end
			end ELSE begin
				Adress1 := NSym * 8;
				Adress2 := i * 8;
				FOR j := 0 TO 7 do
					SymData[Adress2 + j] := SymData[Adress1 + j];
				PutIt(NSym, 0);
				NSym := 0;
			END;	// else

		SDLK_ESCAPE: begin CloseWindow(7, 1, 16, 18);EXIT; end;// procedure
		SDLK_RETURN: begin Code := i; CloseWindow(7, 1, 16, 18); exit; end;
   END ;//case
 end	// while true
end;	// GetSymbol
  ////////////////////////////////////////////////////////
 ////////			END PROCEDURE		/////////////////
////////////////////////////////////////////////////////

procedure PutBoss (x, y:integer; Code:word; ATTR:byte);
begin
	PutSymbol(x, y, Code, ATTR,0);
	PutSymbol(x + 1, y, Code + 1, ATTR,0);
	PutSymbol(x, y + 1, Code + 2, ATTR,0);
	PutSymbol(x + 1, y + 1, Code + 3, ATTR,0);
END;	{ PutBoss }

procedure SetBoss (x, y:integer; Code:word; ATTR:byte);
begin
 MAP[y, x].Code := Code;
 MAP[y, x].ATTR := ATTR;
 MAP[y, x + 1].Code := Code + 1;
 MAP[y, x + 1].ATTR := ATTR;
 MAP[y + 1, x].Code := Code + 2;
 MAP[y + 1, x].ATTR := ATTR;
 MAP[y + 1, x + 1].Code := Code + 3;
 MAP[y + 1, x + 1].ATTR := ATTR;
END;	{ SetBoss }


procedure Ramka (xl, yu, xr, yd:integer);
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

// /////////////////////// //
// Выбор атрибута? ЦВЕТА  //
// ///////////////////// //
procedure SelectAttr(var A:byte);	
var
	i,j: byte;
	s:String;
	Key:word;

	procedure PutIt1(i, Code: byte);
//	var i1:word;
	begin
//	   i1 := i;		//  ???????? WHY?
	   PutSymbol((i - 128) mod 8 + 8, (i - 128) div 8 + 2, Code, i - 128, 3);
	end;

begin	//SelectAttr

// первичная позиция курсора
	IF A < 128 THEN j := 128 + A ELSE j := 128;
	 
 while true do begin
	// рамка/поле
  CreateWindow(7, 1, 16, 18);
	// чистим область
	FOR i := 128 TO 255 do PutIt1(i, EMPTY);
 
	// выводим курсор
  PutIt1(j, STAR);
	
	s:=Format('%3d', [j-128]);
	LOCATE (18, 13);
	SCOLOR (15);
  MYPRINT(s);
	
  Key:=0;
  gdwSwapBuf;
	
  while Key = 0 do Key := Inkey	;		// WAIT KEYPRESS
		
	// очищаем курсор
	PutIt1(j, EMPTY);

  CASE Key of
   SDLK_LEFT: IF j > 128 THEN j := j - 1 else j := 255;
   SDLK_RIGHT: IF j < 255 THEN j := j + 1 else j := 128;
   SDLK_DOWN: IF j + 8 < 256 THEN j := j + 8;
   SDLK_UP: IF j - 8 > 127 THEN j := j - 8;
   SDLK_ESCAPE: begin CloseWindow(7, 1, 16, 18); EXIT end;		// cancel
   SDLK_RETURN: begin A := j - 128; CloseWindow(7, 1, 16, 18); EXIT end;	// choose attr and quit
  END; // case

  end // while true
END;	// procedure


end.
