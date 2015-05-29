Unit UDEMOTEST;

// Note: this unit counts on gdwSwapBuffers
// with flip screen, but later this behavior had been changed
// by vendors and program does not work correctly nowadays

interface
uses SDLglGdwGraph;
{
  тестируем модуль  gdwgraph
  проверяем все ее функци, скорость, возможности
	написана gDw 15 июня 2000 рХ
   under Delphi on 16 Aug 2011
}

const	SymDataFileName:string	= 'SYMDATA.CHR';
type	DIRECTION = (NONE,NORTH,EAST,SOUTH,WEST);
	DOT = object
		Coor:Pixel;
		Visible:boolean;
		DIR:DIRECTION;
		Color:byte;
		procedure Create;	{ создание точки }
		procedure Serve;	{ использование оной }
		procedure Delete;	{ и удаление последней с экрана }
	end;

procedure Main();

implementation

uses SysUtils,sdl, gl;

const
	myBlack = 0;
	myMaroon = 12;
	myGreen = 2;
	myNavy = 9;			// ???
	myPurple = 5;
	myTeal =  11;
	myGray =  8;
	mySilver = 7;
	myRed =  4;
	myLime =  10;
	myBLue =  1;
	myFuchsia = 13;
	myAqua =  3;
	myWhite =  15;

	procedure DOT.Create;	{ создает точку в случайном месте экрана }
	begin
		Coor.x:=random(320);
		Coor.y:=random(200);
		Visible:=true;
		DIR:=Direction(random(5));
		Color:=random(256);

		PutPixel(Coor,Color);	{ выводим точку }
	end;
	procedure DOT.Serve;
	begin
		DelPixel(Coor);
		case DIR of
			NONE: ;
			NORTH:
                        	begin
					dec(Coor.y);
					if Coor.y<0 then Coor.y:=199
				end;
			EAST:	begin
					inc(Coor.x);
					if Coor.x>319 then Coor.x:=0
				end;
			SOUTH:	begin
					inc(Coor.y);
					if Coor.y>199 then Coor.y:=0
				end;
			WEST:	begin
					dec(Coor.x);
					if Coor.x<0 then Coor.x:=319
				end;
		end {case};
		PutPixel(Coor,Color)
	end {DOT.Serve};
	procedure DOT.Delete;
	begin
		DelPixel(Coor)
	end;

const MaxX = 319; MaxY = 199;
      NormSpeedOn = 5;NormSpeedOff = 2;
      SlowSpeedOn = 6;SlowSpeedOff = 4;
var CurStep:shortint;
type
	ExtendedPixel = object
	LOC:Pixel;	{локацция}
	Color:byte;	{цвет точки}
	opColor1:byte;	{ цвет под точкой }
	step:shortint;	{ шаг перемещения }
	Visible:boolean;	{ видима ли?}
	Timer,Speed:array[boolean] of integer;
		{ задержки  для  мигания точек }
	procedure Init(CurCoor:Pixel;C:byte);		{ начльня инициалзация точки }
	procedure Switch;	{ переключение видимости точки }
	procedure SlowDown;	{ замедление  мерцания точки }
	procedure Move(Dir:DIRECTION;D:boolean);	{ перемещение точки }
	procedure Serve;	{ oбслуживание точки }
	end	{object};
{ опишем метоdы объекта }
procedure ExtendedPixel.Init(CurCoor:Pixel;C:byte);
begin
	LOC.x:=CurCoor.x;LOC.y:=CurCoor.y;
	Color:=C;
	step:=CurStep;Visible:=false;
	Speed[false]:=NormSpeedOff;
	Speed[true]:=NormSpeedOn;
	Switch
end;
procedure ExtendedPixel.Switch;
begin
	if Visible then
		PutPixel(LOC,opColor1)
	else begin
		opColor1:=SDLglGDWGraph.GetPixel(LOC);
		PutPixel(LOC,Color)
	end;
	Visible:=not(Visible);
	Timer[Visible]:=Speed[Visible]
end;
procedure ExtendedPixel.SlowDown;
begin
	Speed[false]:=SlowSpeedOff;
	Speed[true]:=SlowSpeedOn
end;
procedure ExtendedPixel.Move(Dir:DIRECTION;D:boolean);
{ если D = true, то линию проводим }
procedure MoveDown;
var OldLOC,HeLOC:Pixel;
begin
	OldLOC.x:=LOC.x;OldLOC.y:=LOC.y;
	case Dir  of
		NORTH:begin
			LOC.y:=LOC.y-step;
			if LOC.y<0 then begin
                                HeLOC.x:=LOC.x;HeLOC.y:=0;
				PutLine(OldLOC,HeLOC,Color);
				OldLOC.y:=MaxY;
				LOC.y:=MaxY+1+LOC.y
			end
		      end;
		EAST:begin
			LOC.x:=LOC.x+step;
			if LOC.x>MaxX then begin
                                HeLOC.x:=MaxX;HeLOC.y:=LOC.y;
				PutLine(OldLOC,HeLOC,Color);
				OldLoc.x:=0;LOC.x:=LOC.x-MaxX-1
			end
		      end;
		SOUTH:begin
			LOC.y:=LOC.y+step;
			if LOC.y>MaxY then begin
                                HeLOC.x:=LOC.x;HeLOC.y:=MaxY;
				PutLine(OLdLOC,HeLOC,Color);
				OldLOC.y:=0;LOC.y:=LOC.y-MaxY-1
			end end;
		WEST:begin
			LOC.x:=LOC.x-step;
			if LOC.x<0 then begin
                                HeLOC.x:=0;HeLOc.y:=LOC.y;
				PutLine(OldLOC,HeLOC,Color);
				OldLOC.x:=MaxX;LOC.x:=MaxX+1+LOC.x
			end end
	end {case};
	PutLine(OldLOC,LOC,Color);
	if not(Visible) then Switch
end{MoveDown};
{ еремещене точки при пднятом пере }
procedure MoveUp;
begin
	if Visible then Switch;
	case Dir of
	NORTH:begin
		LOC.y:=LOC.y-step;
		if LOC.y<0 then LOC.y:=MaxY+1+LOC.y
		end;
	EAST:begin
		LOC.x:=LOC.x+step;
		if LOC.x>MaxX then LOC.x:=LOC.x-MaxX-1
		end;
	SOUTH:begin
		LOC.y:=LOC.y+step;
		if LOC.y>MaxY then LOC.y:=LOC.y-MaxY-1
		end;
	WEST:begin
		LOC.x:=LOC.x-step;
		if LOC.x<0 then LOC.x:=MaxX+1+LOC.x
		end
	end {case};
	Switch
end {MovUp};
begin{--Move}
	if D then MoveDown else MoveUp
end {Move};
procedure ExtendedPixel.Serve;
begin
	if Timer[Visible] = 0 then Switch
	else dec(Timer[Visible])
end;

procedure ErrorReadingSymbolData;
begin
	writeln('Could not load SYMDATA.CHR file. Exitting.');
	halt(255)	{ выход в дось с ERRORLEVEL = 255 }
end;

function sgn(Argument:integer):shortint;
{ кто учил в школе Бэйсик, тот знает  о чем поет нам эта функция }
begin
	if Argument>0 then 		sgn:=1
	else
		if Argument<0 then  	sgn:=-1
		else
					sgn:=0
end {sgn};

procedure WaitKey;	{ очищает буфер и ждет нажаия клавиши }
begin
	gdwSwapBuf;
	while  Inkey <> 0 do;	{ сбраываембуфер, если накоплся }
	repeat until Inkey<>0	{ ждем нажатия		}
end;

procedure Pause(MSec:word);	{ пауза в MSec/1000 секунд }
begin
	gdwSwapBuf;
   SDL_Delay(MSec div 100);
end {Pause};

var A,B:Pixel;C:byte;
const	Sym:Symbol = (Code:ord('*');Attr:101);

{ теперь здесь представлено 5 тестовых процур }
{ из блока Bench                              }
procedure BePixel;
begin
	PutPixel(A,C);
	inc(A.x);if A.x>319 then begin
		A.x:=0;inc(A.y);
		if A.y>199 then A.y:=0
		end
end;
procedure BeSymbol;
begin
	PutSymbol(A,Sym,0);
	inc(A.x);if A.x>40 then begin
		A.x:=1;inc(A.y);if A.y>25 then A.y:=1
		end
end;
procedure BeSquare;
begin
	B.x:=A.x+50;B.y:=A.y+50;
	Bar(A,B,C);
	A.x:=A.x+5;
	if A.x>269 then begin
		A.x:=0;inc(A.y,3);
		if A.y>149 then A.y:=0
	end {if}
end;
procedure BeCircle;
begin
	Circle(A,30,C);
	inc(A.x,3);
	if A.x>289 then begin
		A.x:=31;inc(A.y,2);
		if A.y>169 then A.y:=31
	end {if}
end;
procedure BeBigSymbol;
begin
	PutBigSymbol(A,Sym,0,3,5);
	inc(A.x,3);
	if A.x>38 then begin
		A.x:=1;inc(A.y,5);
		if  A.y>21 then A.y:=1
	end {if}
end;
/////////////////////////////////////////////////////////////////////////////
procedure Demon;
{ первая из основных  3-х процедур демонстрации, редактора, бенчмарки }

procedure ShowColors;		{ показваем цвета  VGA-13 }
	const 	Sym:Symbol = (Code:32;Attr:0);

	var i,j:integer;Dis:Pixel;
	begin
		ClearDevice;
                Dis.x:=7;Dis.y:=2;
		PutString(Dis,'Тест цветов VGA-13',3,0);
		for i:=6 to 13 do
			for j:=3 to 34 do begin
            Dis.x:=j;
            Dis.y:=i;
				PutSymbol(Dis,Sym,3);
            if(Sym.Attr<255) then inc(Sym.Attr)
            else Sym.Attr:=0;
			end;
		WaitKey
	end {ShowColors};
procedure ShowTable;		{ показываем таблицу символов }
	var Code:word;
	const Color:byte = 15;
	var Sym:Symbol;Position:Pixel;
	begin
		ClearDevice;
                Position.x:=5;Position.y:=2;
		PutString(Position,'Тест таблицы символов',2,0);
		for Code:=0 to 511 do begin
			Sym.Code:=Code;
			Sym.Attr:=Color;
			Position.x:=(Code mod 32)+3;
			Position.y:=(Code div 32)+6;
			PutSymbol(Position,Sym,0)
		end {for};
		WaitKey
	end { ShowTable };

procedure Pixelling;
{ данная процедура использует некоторые начальные объектно ориентированные возможности ТР6.0 }
const	MaxDot = 300;		{ число обслужваемых  точек }
var 	Dots:array[1..MaxDot] of DOT;
	i:integer;
begin		{ Pixelling }
	ClearDevice;
	for i:=1 to MaxDot do Dots[i].Create;	{ создаем нужное кол-во точек  }
	repeat
{ перемещаем точки, пока нет нажатиЯ клавиши }
		WaitSync;
		for i:=1 to MaxDot do Dots[i].Serve;
		Pause(100)
	until Inkey<>0;
	for i:=1 to MaxDot do Dots[i].Delete;	{ удалим точки }
	Pause(2000);
	while Inkey = 0 do begin
					Dots[1].Create;		{ покрываем экран тысячью точек - эффект  "снег" }
					inc(i);
					if (i mod 500) = 0 then gdwSwapBuf;
	end; { while }
end {Pixelling};

procedure LinenCircles;		{ kруги и линии }
var	Dot,Dot2:Pixel;
	Color:byte;
        Radius:integer;
    var Key:word;
{ я всегда мечтал написать  на паскале процедуру длиной в строку }
 procedure LitCir; var R:integer; begin Color:=random(100)+50;for R:=10 downto 1 do Circle(Dot,R,Color)end;
   procedure Linen;
   var Radius:integer;
	begin
		PutPixel(Dot,random(250)+1);
		for Radius:=1 to 6 do begin
          Dot2.x:=(random(10)+3)*sgn(random(100)-50)+Dot.x;
		    Dot2.y:=(random(10)+2)*sgn(random(100)-50)+Dot.y;
			 PutLine(Dot,Dot2,Random(250)+1)
      end
	end;
begin
	ClearDevice;
{ покрываем экран сеткой-линиями сначала слева направо, затем - сверху вниз }
	Dot.x:=0;Dot.y:=0;Color:=10;
	Dot2.y:=199;
	while Dot.x<320 do begin
		Dot2.x:=Dot.x;
		PutLine(Dot,Dot2,Color);
		inc(Dot.x,4);inc(Color,2)
	end;
	Dot.x:=0;Dot2.x:=319;
	Color:=40;
	while Dot.y<200 do begin
		Dot2.y:=Dot.y;
		PutLine(Dot,Dot2,Color);
		inc(Dot.y,3);inc(Color);
	end {while};
{ теперь выводим 100 кругов из центра экрана с увеличивающмися радиусами }
	Dot.x:=160;Dot.y:=100;
	WaitKey;
    Key:=0;
	while Key=0 do begin
		Color:=random(250+1);
		for Radius:=1 to 100 do begin
			Circle(Dot,Radius,Color);
			inc(Color);
            Key:=Inkey;
            if Key<>0 then break;
			Pause(200)
		end;
		Pause(2000)
	end;
{ но и  это еще не все?!.. }
	ClearDevice;
	repeat
		Dot.x:=random(280)+15;
		Dot.y:=random(160)+20;
		if random(100)>75 then LitCir else Linen;
		Pause(6500)
	until Inkey<>0
{ вот теперь вроде бы и все... а жаль... -- gDw (AVP.)}

end	{LinenCircles};

procedure BarsNRects;		{ бары и четырехугольники }
var	A,B:Pixel;
	C:byte;
begin
	ClearDevice;
	while Inkey = 0 do begin
		A.x:=random(280);A.y:=random(170);
		B.x:=A.x+random(38);B.y:=A.y+random(25);
		C:=random(256);
		if random(100)<50 then
			Rect(A,B,C)
		else	Bar(A,B,C);
		Pause(6100)
	end;
{ то 'while', то 'repeat'... Это господин Паскаль, господа...	}
	repeat
	A.x:=0;A.y:=1;
   B.x:=319;B.y:=199;

		C:=random(250)+1;
		while A.y<>B.y do begin
			Rect(A,B,C);
			dec(C);inc(A.x);inc(A.y);
			dec(B.x);dec(B.y);
         Pause(2250);
         if InKey<>0 then exit
		end
   until FALSE
end		{BarsNRects};
procedure HornOfOpulence;
{  эта процедура взята мной из архаической, но интересной книги Дэвида Э. Грайса }
{  "Графические средства персонального компьютера", изданной на английском языке }
{  в 1985, а на русском - в 1989 }
{	Я переписал ее (процедуру :) ) с Бэйсика на г-н Паскаль, и вот что получилось.. }
var i:integer;Color:byte;Pos:Pixel;
begin
	ClearDevice;
	while Inkey = 0 do begin
		Color:=random(250)+1;
		for i:=1 to 125 do begin
                        Pos.x:=160+trunc(100.0*cos(i/20));
			Pos.y:=90+trunc(70.000*sin(i/20));

			Circle(	Pos,45-i div 3, Color);
			inc(Color)
		end {for};
		Pause(5500)
	end {while}
end  {HornOfOpulence};

procedure BigMovingString;	{ бльшая движущаяся cтрока }
var 	PosStr:integer;
const
	Str:string =
'Вы просмотрели DemoTest библиотеки <gdwgraph.pas>. Для выхода ' +
'в меню нажмите любую клавишу. Искренне Ваш - gDw-2000, лето! ';
Str2:string = '                  ';
var StrLength:integer;	{длина строки}
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
var i:integer;Sym:Symbol;
         s:string;
         sb:integer;
begin
	StrLength := Length(Str);
	if PosStr>StrLength then PosStr:=1;
{ однвременно на экране видно лишь 16 символов строки }
	for i:=16 downto 1  do
		if PosStr-i+1>0 then
      begin
  			s:=Str[PosStr-i+1];
            sb := ord(s[1]);
			if (sb > 127) and (sb < 256) then
				sb:=oem866_table[sb]; // CharToOEM
//			CharToOEMBuff(@s[1], @s[1], Length(s));
         Sym.Code:=word(sb);
//   		Sym.Code:=word(Str[PosStr-i+1]);
			 Sym.Attr:=15;
			PutBigSymbol(Coor[i], Sym,0
			  , SizeX[i],SizeY[i]);
      end;
	inc(PosStr);
	Pause(7500)
end {MoveIt};
begin   {--BigMovingString}
	ClearDevice;
   Str:=concat(Str,Str2);
	PosStr:=1;
	repeat until Inkey = 0;		{ сбросим строб клавиатуры }
	while Inkey = 0 do MoveIt	{ выводим строку пока не будет нажатия }
end;	{BigMovingString}

procedure BeHappyNow;		{ last, but not least, as they say.. }
const 	Str:string='Be happy NOW!';
var	Height,Width:integer;
	Coor:Pixel;Sym:Symbol;
	i:byte;
	j:byte;		{длина строки}
begin
	j:=Length(Str);
{ oпределим размеры  строки }
	Width:=40 div j;
	if Width<1 then exit;	{ строка не помещается на экране }
	if Width>=24  then Height:=24
			else Height:=Width+1;
{ определим координаты строки для вывода }
	Coor.y:=13 - (Height shr 1);
{ теперь выводим  строку в цикле }
	ClearDevice;
	while Inkey = 0 do begin
                Coor.x:=0;
		for i:=1 to j do begin
        		Sym.Code:=word(Str[i]);
			Sym.Attr:=random(255)+1;
			inc(Coor.x,Width);
			PutBigSymbol(Coor,Sym,0,Width,Height)
		end {for};
		Pause(20500)
	end {while}
end {BeHappyNow};

{ теперь начинается тело основоной процедуры Demon, которая просто вызывает }
{ все предописанные проедуры }
begin	{--Demon}
	ShowColors;	{ показываем цвета }
	ShowTable;	{ показываем таблицу символов }
	Pixelling;	{ точки }
	LinenCircles;	{ круги и линии }
	BarsNRects;	{ бары и четырехугольники }
	HornOfOpulence;	{ рог изобилия, а почему, не знаю }
	BigMovingString;
	BeHappyNow
end	{--Demon};


procedure Bench;		{ вторая из 3-х sub }
const	Etalon_386:array  [1..5] of longint = (54528,8228,508,119,501);
var	ThisMachine:array [1..5] of longint;
	Result:longint;
        Time:Longword;
	RunTest:procedure;
	i,j:integer;
        Maxim:array [1..3] of longint;

{ эти 5 проц перенеси в основной блок DEMOTEST }
	
procedure SetTime(var Timer:Longword);
begin
	Timer:=WhatTime+1080;
end;

function Average:longint;	{ опредеяет среднее значние массива Maxim }
var i:integer;Aver:longint;
begin
	Aver:=0;
	for i:=1 to 3 do Aver:=Aver+Maxim[i];
	Average:=Aver div 3
end;
const	BeProc:array [1..5] of procedure =
		(@BePixel,@BeSymbol,@BeSquare,@BeCircle,@BeBigSymbol);
	BegX:array [1..5] of integer = (0,1,0,31,1);Color:byte=15;

procedure OutResults;	{ выдача результатов на термнал }

const WhereY:array [1..5]  of byte = (5,7,9,11,13);


var
	i:integer;
   First,Second:longint;
	CR:Pixel;
   s:String;
begin
   ClearDevice;
   CR.x:=2;Cr.y:=2;
	PutString(CR,'Названия ',6,3);
   inc(CR.y);
	PutString(CR,'    теста',6,3);
   CR.x:=13;dec(CR.y);
	PutString(CR,' Данная ',13,3);
   inc(CR.y);
	PutString(CR,'скорость',13,3);
   CR.x:=22;dec(CR.y);
	PutString(CR,'Эталонная',11,3);
   inc(CR.y);
	PutString(CR,' скорость',11,3);
   CR.x:=33;dec(CR.y);
	PutString(CR,'Данная/',9,3);
   inc(CR.y);
	PutString(CR,' эталон',9,3);

{ выводим названия тестов }
   CR.x:=2;CR.y:=5;
	PutString(CR,'ТОЧКИ',15,0);
   inc(CR.y,2);
	PutString(CR,'СИМВОЛЫ',15,0);
   inc(CR.y,2);
	PutString(CR,'КВАДРАТЫ',15,0);
   inc(CR.y,2);
	PutString(CR,'КРУГИ',15,0);
   inc(CR.y,2);
	PutString(CR,'БОЛЬШИЕ',15,0);
   inc(CR.y);
	PutString(CR,'СИМВОЛЫ',15,0);

{  выводим соответсвующие  числа }
	for i:=1 to 5 do begin
		CR.X:=13;
      CR.Y:=WhereY[i];
		s:=Format('%8d  %8d  %5.1f',[ThisMachine[i],Etalon_386[i],ThisMachine[i]/Etalon_386[i]]);
      PutString(CR,s,15,0);
	end {for};
        CR.x:=9;CR.y:=16;
	PutString(CR,'Числа под скоростью указывают',14,0);
        CR.x:=3;inc(CR.y);
	PutString(CR,'количество объектов, выведенных за 1с.',14,0);
        inc(CR.y,2);
	PutString(CR,'Эталонная система - ',13,0);
        CR.x:=23;
	PutString(CR,'386DX-40(AMD)',13,3);
        CR.x:=3;CR.y:=21;
	PutString(CR,'Общий коэффициент вашей системы по',101,0);
        inc(CR.y);
	PutString(CR,'отношению к эталонной равен',101,0);
	CR.X:=31;CR.Y:=22;
	First:=0;			{ начинаем вычислять общий кооэффициент }
	for i:=1 to 5 do First:=First+ThisMachine[i];
	Second:=0;
	for i:=1 to 5 do Second:=Second+Etalon_386[i];
	First:=First div 5;Second:=Second div  5;
   s:=Format('%7.1f',[First/Second]);
   PutString(CR,s,15,0);
	WaitKey
end {OutResults};

begin 		{ Bench }
	for j:=1 to 5 do begin  // 5 tests
	     	RunTest:=BeProc[j];	{ нужный тест }
		for i:=1 to 3 do begin
			A.x:=BegX[j];A.y:=BegX[j];
			C:=random(256);
			Result:=0;ClearDevice;
			SetTime(Time);  // on 1 second??
			while Time>WhatTime do begin
				if Inkey = SDLK_ESCAPE
                	then exit;	// for Application.ProcessMessages either it may hang
				RunTest;
				inc(Result);
				inc(C);
				inc(Sym.Attr)
			end;
        gdwSwapBuf;
			Maxim[i]:=Result
		end { for i };
		ThisMachine[j]:=Average; {среднее значение }
	end { for j };
	OutResults
end			{Bench};

///////////////////////////////////////////////////////////////////
{ osталась последняя проедура из 3-х главных - IntEd,
									или InteractiveEditor }
procedure IntEd;

var	Mode : (single,double2);
	FExit,PenDown:boolean;
	Key:word;
	A,B:ExtendedPixel;
procedure IIInitialization;	{ начальная инициалзация }
const Z:Pixel = (x:160;y:100);
begin
	ClearDevice;
	CurStep:=4;Mode:=single;
	PenDown:=false;
	A.Init(Z,15)
end;
procedure Dispatcher;
begin
        Key:=InKey;
	while Key = 0 do begin
		case Mode of
		single:		A.Serve;
		double2:	begin A.Serve;B.Serve end;
		end;
		Pause(2000);
                Key:=InKey
	end {while}
end;

function ChooseColor(CurColor:byte):byte;
const	Str:string = 'Выберите цвет';
        Sym:Symbol = (Code:32;Attr:0);
		A:Pixel	= (x:28;y:20);
        B:Pixel	= (x:292;y:100);
var	BMP:gdwImage;
    CR:Pixel;CD:Symbol;
	Key:word;
    C:byte;
procedure PrintC;	{ печать курсора }
begin
        CR.x:=(C mod 32) + 5;CR.y:=(C div 32) + 5;
        CD.Code:=ord('*');CD.Attr:=C;
		PutSymbol( CR, CD, 3)
end;

procedure DelC;		{ удаление курсора }
begin
	CR.x:=(C mod 32) +5;CR.y:=(C div 32) + 5;
	Sym.Attr:=C;
	PutSymbol( CR,Sym,3)
end;

procedure PreExit;		{ восстановление экрана }
begin
	PutImage(A,BMP);	{ восстановим область экрана }
    BMP.Body:=NIL;
end;

begin	{ ChooseColor }
	GetImage(A,B,BMP);	// память будет выделена автоматом
	Rect(A,B,15);			{ обрамление }
    CR.x:=14;CR.y:=4;
	PutString(CR,Str,13,0);
	for C:=0 to 255 do DelC;
	C:=CurColor;
	repeat
		PrintC;
        gdwSwapBuf;
		repeat Key:=Inkey until Key <> 0;
		WaitSync;
		DelC;
		case Key of
		SDLK_UP:C:=C-32;
		SDLK_DOWN:C:=C+32;
		SDLK_LEFT:dec(C);
		SDLK_RIGHT:inc(C);
		SDLK_ESCAPE:begin
			PreExit;
			ChooseColor:=CurColor;
			exit;
			end;
	end
	until Key = SDLK_RETURN;
	PreExit;
    ChooseColor:=C
end;

procedure Analyser;
procedure AnalSingle;
var Z:Pixel;
begin
	case Key of
		2..11:A.step:=Key-1;
		SDLK_ESCAPE:FExit:=true;
		SDLK_F9:A.Color:=ChooseColor(A.Color);
		SDLK_F10:IIInitialization;
		SDLK_SPACE:PenDown:=not(PenDown);
		SDLK_UP:A.Move(NORTH,PenDown);
		SDLK_DOWN:A.Move(SOUTH,PenDown);
		SDLK_LEFT:A.Move(WEST,PenDown);
		SDLK_RIGHT:A.Move(EAST,PenDown);
		SDLK_F2:begin
            Z.x:=(A.LOC.x+A.step) mod 320;
			Z.y:=(A.LOC.y+A.step) mod 200;
			B.Init(Z,A.Color);
			A.Slowdown;
			Mode:=double2
		   end;
		end {case}
end {AnalSigle};
procedure AnalDouble;	{ анализатор режима 2-ной точки }
procedure GoToSingle;
begin
	A.Init(B.LOC,B.Color);
	Mode:=single
end;
procedure Ret2Single;
begin
	if B.Visible then B.Switch;
	A.Init(A.LOC,A.Color);
	Mode:=single
end;
function Distance(A,B:Pixel):integer;
{ опреdеляет расстояние между A и B точками }
var dx,dy:integer;
begin
	dx:=A.x-B.x;dy:=A.y-B.y;
	Distance:=trunc(sqrt(dx*dx+dy*dy))+1
end;
begin
	case Key of
		2..11:B.step:=Key-1;
		SDLK_UP:B.Move(NORTH,false);
		SDLK_DOWN:B.Move(SOUTH,false);
		SDLK_LEFT:B.Move(WEST,false);
		SDLK_RIGHT:B.Move(EAST,false);
		SDLK_ESCAPE:Ret2Single;
		SDLK_F2:begin
			PutLine(A.LOC,B.LOC,B.Color);GoToSingle;
		end;
		SDLK_F3:begin
			Rect(A.LOC,B.LOC,B.Color);GoToSingle;
			end;
		SDLK_F4:begin
			Bar(A.LOC,B.LOC,B.Color);GoToSingle
			end;
		SDLK_F5:begin
			Circle(A.LOC,Distance(A.LOC,B.LOC),B.Color);
			B.opColor1:=B.Color;Ret2Single
		 	end;
		SDLK_F9:B.Color:=ChooseColor(B.Color);
		SDLK_F10:GoToSingle;
	end {case}
end {AnalDouble};

begin	{--Analyser}
	case Mode of
		single:AnalSingle;
		double2:AnalDouble;
	end
end;
begin	{ -- IntEd }
	IIInitialization;
	FExit:=false;	{ выход закрыт }
	repeat
		Dispatcher;
		Analyser
	until FExit
end;

procedure Mandelbrotte;
// Выводим фрактал Мандельбротта, простейший, без наворотов, всего несколько цветов
// цвета с TColor к VGA13 - ещё раз?
  const
    aColors: array[0..14] of byte = (myBlack, myMaroon, myGreen, myNavy,
      myPurple, myTeal, myGray, mySilver, myRed, myLime, myBLue, myFuchsia,
      myAqua, myWhite, myBlack);
  var
   iI, iJ, iNewColor : Integer;
   rU, rV, rX, rY, rZ: Real;
   PX:Pixel;
  const
	ClientWidth = 320;	// Ширина экрана в точках
	ClientHeight = 200;	// Высота экрана в точках
	
begin
	ClearDevice;
glBegin(GL_POINTS);
	for iI := 0 to ClientWidth - 2 do
		for iJ := 0 to ClientHeight - 2 do begin
			rX := -0.8 + 3 * iI / ClientWidth;
			rY := -1.4 + 2.8 * iJ / ClientHeight;
			iNewColor := 0;
			rU := 0;
			rV := 0;
			repeat
				rZ := Sqr(rU) - Sqr(rV) - rX;
				rV := 2 * rU * rV - rY;
				rU := rZ;
				Inc(iNewColor);
			until (Sqr(rU) + Sqr(rV) > 9) or (iNewColor = 14);
			// рисуем точку
			PX.x := iI + 1;
			PX.y := iJ + 1;
			PutPalPixel(PX, aColors[iNewColor]);
//			PutPixel(PX, aColors[iNewColor]);
//			Canvas.Pixels[iI + 1, iJ + 1] := aColors[iNewColor];
		end;
glEnd;
	WaitKey	// ждём нажатия
end;

procedure Fern;

//const
 //	iterations = 50000;  //Кол-во итераций
//const Greens:array[0..4] of TColor = ($FF00,$C000,$A000,$8000,$7000);
 const

	ClientWidth = 320;	// Ширина экрана в точках
	ClientHeight = 200;	// Высота экрана в точках

var
	t, x, y: real;
    p: real;//CЛУЧАЙНАЯ ВЕЛИЧИНА
//	k: longint;
	mid_x, mid_y, radius: integer;
	PX:Pixel;
    ti : Longword;

begin
	ClearDevice;
  ti := 0;
	mid_x := ClientWidth div 2;
	mid_y := ClientHeight - 10 ;
	radius := trunc(0.1 * mid_y);
	randomize;
	x := 1.0;
	y := 0.0;
//	for k := 1 to iterations do
	while Inkey = 0 do	// до нажатия клавишы действуем!
	begin
		p := random;
		t := x;
		if p <= 0.85 then  //Построение верхней части листа
        begin
			x := 0.84 * x -0.045  * y;
			y := 0.045  * t + 0.86   * y + 1.6;
		end
		else
		if p <= 0.92 then  //Построение левого  листа
		begin
			x := 0.25   * x - 0.26 * y;
			y := 0.23 * t + 0.25   * y + 1.6;

		end                //Построение правого листа
		else if p <= 0.99 then
		begin
			x := -0.135   * x + 0.28 * y;
			y := 0.26 * t + 0.245 * y + 0.44;
		end
		else
		begin              //Построение стебля
			x := 0.0;
			y := 0.16 * y  ;
		end;
		PX.x := mid_x+round(radius*x);
		PX.y := mid_y-round(radius*y)+12;	//why 35?
		PutPixel(PX, myGreen);
    inc(ti);
		
    if (ti mod 500) = 0 then
			gdwSwapBuf;

	end
end;


procedure Main();
var	Key:word;	{ скан-код нажатой в меню клавиши }
    Z,X:Pixel;
begin	{ -- M A I N -- }
{	начало модуля DEMOTEST }
	if (LoadSymData(SymDataFileName)=2) then ErrorReadingSymbolData;
	InitGraph('Demotest for gdwGraph');
	while true do begin

		ClearDevice;
                Z.x:=3;Z.y:=1;
		PutString(Z,'МЕНЮ:',15,3);
                Z.x:=1;Z.y:=3;
		PutString(Z,'F1.Демонстрация',100,0);
                inc(Z.y);
		PutString(Z,'F2.Бенчмарка...',101,0);
                inc(Z.y);
		PutString(Z,'F3.Интередактор',102,0);
                inc(Z.y,2);

		PutString(Z,'F4.Ещё тест?',myGreen,0);
                inc(Z.y,2);

		PutString(Z,'F5. Фрактал Мандельбротта',myAqua,0);
                inc(Z.y,1);
		PutString(Z,'F6. Фрактал - папоротник',myAqua,0);
                inc(Z.y,5);

		PutString(Z,'ESC.Выход в BIOS',myRed,0);
    gdwSwapBuf;
                repeat
                	Key:=InKey
                until Key<>0;
		case Key of
		    SDLK_F1:Demon;
		    SDLK_F2:Bench;
		    SDLK_F3:IntEd;
	        SDLK_F4:
				begin
					Z.X := 320 div 2;
					Z.Y := 200 div 2;
//					X.X := 319;
//					X.Y := 199;
					Circle(Z,50,15);
		gdwSwapBuf;
					repeat
						Key:=InKey
					until Key<>0;
				end;
			SDLK_F5: Mandelbrotte;	// фрактал Мандельбротта
			SDLK_F6: Fern;			// папоротник зелёный!
			SDLK_ESCAPE:begin  CloseGraph;halt end;
		end {case}
	end {while}
end;	{ -- M A I N -- }

{--	Продукция gDw - это торговая и рекламная марки Grendel Dragon Wizard.
-- Российская Федерация
-- г.Волгоград, ул.Твардовского 9-16,  г-ну Плешакову А.В.
--	20 июня 2000 года от р.Хр.																  }
end.
