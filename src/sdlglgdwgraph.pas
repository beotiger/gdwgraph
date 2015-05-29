{$A1}

// NOTE: glDisable( GL_TEXTURE_2D );

{ /////////////////////////////////////////////
	SDL VERSION!!!

    переделана под glOrtho окна!

ПЕРЕПИСАНА ДЛЯ ДВОЙНОГО БУФЕРА SDL OPENGL

ДЛЯ ПОЯВЛЕНИЯ РИСУНКА НА ЭКРАНЕ СЛЕДУЕТ ВЫЗЫВАТЬ
ФУНКЦИЮ gdwSwapBuf								

 /////////////////////////////////////////////   }

{ библиотека для режима BIOS 13h (VGA 320*200*8) -  256 цветов  }
{  написана под Turbo Pascal 6.0 на 386DX-40	}
{ исправлена и дополнена в марте 2001 года от Р.Х. }

{ ПЕРЕДЕЛАНА ПОД Дельфи7 - 15-18 августа 2011 года}
{используя метод Canvas формы}

{ адаптирована к OpenGL 25,26 августа 2011 года, авторы те же (я) }
{ переделана под SDL OpenGL 9 сентября 2011 года }

Unit SDLglGDWGraph;

interface

{Uses Types, Graphics, Windows,SysUtils,
		opengl; // это OPENGL VERSION of GDWGraph!!!!
}
Uses
//	Windows, {for CharToOEMBuf -- see cp1251_cp866.inc}
	gl,
//	glu,
	SysUtils,
	sdl;
 // SDL_opengl;
	

const
		MaxCode = 511;
		SymDataSize = (MaxCode+1) * 8;
		MaxPal = 255;		{ максимальный доступный номер палитры }
		SizePal = (MaxPal+1)*64;

		scrClientWidth:integer 	= 640;
		scrClientHeight:integer = 400;	// реальный размер канвы 640*400 instead of 320*200

		TimeZoom = 50;	// исп.для регулирования скорости задержки от WhatTime
		
{$I RECOLOR.INC  -- подключим карту преобразований VGA13 цветов в TColor }
{$I cp1251_cp866.inc -- ansi2oem866 table just for letters А..Я, а..я, Ёё! }

var
		PalData: array[0..SizePal] of byte;
		SymData: array[0..SymDataSize] of byte;
		NumPal: word;
		
		inFullScreen : boolean;

		surface : PSDL_Surface;

type
		Pixel = record
			X,Y:integer   { координаты точки на дисплее VGA }
		end;

		Symbol = record
			Code:word;	{ код символа }
			Attr:byte;	{ его цвет }
		end;

		{
			*****************
			* ОБЩИЕ ФУНКЦИИ *
			*****************
		}
				 
		{ включение графики}
		function InitGraph(WindowCaption:string=''):boolean;	// returns true on success

		{ fullscreen on/off }
		procedure gdwFullScr({fs:boolean});

		// swap frame buffers
		procedure gdwSwapBuf;

		procedure CloseGraph;		{вкл.текста}
		procedure ClearDevice;   {oчистка экрана}
		procedure WaitSync;	// DUMMY		{ ожидание обратного хода луча }

		// функции загрузки данных
		function LoadSymData(FileName:string):byte;{загружает таблицу символов}
		function LoadPalData(FileName:string):byte;{загружает файд с палитрой}

		// функции работы с точками
		procedure PutPixel(Point:Pixel; Color:byte); {выводит точку}
		procedure DelPixel(Point:Pixel);             {стирает точку}
		function GetPixel(Point:Pixel):byte;         {получить цвет точки}

		// линии, прямоугольники и круги
		procedure PutLine(PointSt, PointEn:Pixel; Color:byte);{ линия }
		procedure Rect(LeftTop, RightBot:Pixel; Color:byte); { прямоугольник }
		procedure Bar(LeftTop, RightBot:Pixel; Color:byte); { закрашенный прямоугольник = бар }
		procedure Circle(Center:Pixel; Radius:integer; Color:byte); { kруг }

		// функции по работе с символами
		procedure PutSymPixel(Point:Pixel;R,G,B:GLFloat);
		procedure PutPalPixel(Point:Pixel;Color:byte);

		procedure PutSymbol(LOC:Pixel;ID:Symbol; Oper:byte);overload; { символ VGA13 (8*8 точек) }
		procedure PutSymbol(X,Y:integer;Code:word;Attr,Oper:byte);overload; { тоже с простыми типами }

		procedure PutBigSymbol(LOC:Pixel; ID:Symbol; Oper:byte;
															deltaX,deltaY:integer);overload; { увеличенный символ }
															
		procedure PutPalSymbol(LOC:Pixel;ID:Symbol;Oper:byte); { символ с палитрой 256 цветов!? }
		procedure PutBigPalSymbol(LOC:Pixel; ID:Symbol; Oper:byte;
										 deltaX,deltaY:integer); { увеличенный символ }

		// вывод строк символов
		procedure PutString(LOC:Pixel;Str:string;Color:byte;Oper:byte); { вывод строки символов }
		procedure PutPalString(LOC:Pixel;Str:string;Color:byte;Oper:byte); { вывод строки символов через палитру }

		// вывод связанной группы символов
		procedure Put16x16(LOC:Pixel;ID:Symbol;Oper:byte); { вывод символа 16*16 как четыре 8*8 : 1-2 3-4    }
		procedure Put24x24(LOC:Pixel;ID:Symbol;Oper:byte);
		procedure PutPal16x16(LOC:Pixel;ID:Symbol;Oper:byte);
		procedure PutPal24x24(LOC:Pixel;ID:Symbol;Oper:byte);

		// функции по работе с образами
		type gdwImage =
		record
			Height,Width:GLUint;
			Body:array of GLUbyte; //dynamic array
		end;
		
		procedure GetImage(LeftTop,RightBot:Pixel;var BitMap:gdwImage);	//забрать образ с экрана
		procedure PutImage(LOC:Pixel;BitMap:gdwImage);              //вывести образ на экран
		
		// функции обработки клавиатуры
		function Inkey:word;	{ центральная функция обслуживания сообщений - must be runned }
		function EInkey(var modif:word):word;// + modifyer
			
		// функция времени
		function WhatTime:Longword;

/////////////////////////////////////////////////////////////////////////////////////
implementation

function EInkey(var modif:word):word;// + modifyer
var	event : TSDL_Event;
{ вoзвращаeт код нажатой клавиши ( если нажатие было ) }
begin
	Result := 0;
	modif := 0;
   while( SDL_PollEvent( @event ) = 1 ) do
    begin
      case event.type_ of
//        SDL_QUITEV : ;{Done := true;}
        SDL_KEYDOWN :  begin
          // handle key presses
          Result := event.key.keysym.sym;	{ TO DO - подумать о модификаторах }
		  modif := event.key.keysym.modifier;
        end;
        SDL_ACTIVEEVENT:	// when we lose/restore focus
        	// gdwSwapBuf;
      end;
    end;
end;

function Inkey:word;// + modifyer
var	event : TSDL_Event;
{ вoзвращаeт код нажатой клавиши ( если нажатие было ) }
begin
	Result := 0;
   while( SDL_PollEvent( @event ) = 1 ) do
    begin
      case event.type_ of
//        SDL_QUITEV : ;{Done := true;}
        SDL_KEYDOWN :
          // handle key presses
          Result := event.key.keysym.sym;
       SDL_ACTIVEEVENT, SDL_VIDEOEXPOSE:
	   // when we lose/restore focus
        	// gdwSwapBuf;
      end;
    end;
end;

function WhatTime:Longword;	// получаем так называемый Tick count's - таймер BIOS'a?
begin
	WhatTime := SDL_GetTicks;
end;

function LoadSymData(FileName:string):byte;
var F:file;
         begin
{$I-}
              Assign(F,FileName);
              Reset(F,1);
              if IOResult<>0 then begin LoadSymData:=2;exit end;
              BlockRead(F,SymData,SymDataSize);
              LoadSymData:=IOResult;
              Close(F)
{$I+}
         end;

function LoadPalData(FileName:string):byte;
{ загружает палитру из файла FileName }
{ уст. NumPal=номеру последнего загруженного тайла палитры }
var	
	IO:byte;
	Buffer:array[1..64] of byte;
	F:file;

begin
{$I-}
	NumPal:=0;
	Assign(F,FileName);
	ReSet(F,1);
	IO:=IOResult;
	if IO<>0 then begin	LoadPalData:=IO;exit end;
	repeat
   	BlockRead(F,Buffer,64);
		IO:=IOResult;
		if IO<>0 then begin
			Close(F);
			LoadPalData:=IO;
      	exit
		end;
		for IO:=1 to 64 do
			PalData[NumPal*64+IO-1]:=Buffer[IO];
		if NumPal = MaxPal then begin
			Close(F);
			LoadPalData:=0;
			exit
		end;
		inc(NumPal)
	until FALSE
{$I+}
end {LoadPalData};


  ////////////////////////////////////////////
 ////////////    SDL OPENGL       ///////////
////////////////////////////////////////////
function InitGraph(WindowCaption: string = ''): boolean;
// returns true on success

const
	MyCapt:PChar = ' { SDL OpenGL Version }';

var
	videoflags : Uint32;
	videoInfo : PSDL_VideoInfo;
  PCapt:PChar;
	bpp: integer = 0;
	
//    Size: Cardinal;
begin
	Result := false;
	if SDL_Init( SDL_INIT_VIDEO ) < 0 then exit;
	videoInfo := SDL_GetVideoInfo;
	if videoInfo = nil then begin SDL_Quit; exit; end;

	bpp := videoInfo.vfmt.BitsPerPixel;
	
	// Enable OpenGL in SDL and store the palette in hardware
	videoFlags := SDL_OPENGL;// or SDL_HWPALETTE;
	// This checks to see if surfaces can be stored in memory
{	if videoInfo^.hw_available <> 0 then
		videoFlags := videoFlags or SDL_HWSURFACE
	else
}
	// ALways use Software surfaces
   // 	videoFlags := videoFlags or SDL_SWSURFACE;
	// This checks if hardware blits can be done * /
	// if videoInfo^.blit_hw <> 0 then
	//	videoFlags := videoFlags or SDL_HWACCEL;
	
	// start in FULLSCREEN mode?
	//	videoflags := videoFlags or SDL_FULLSCREEN;

	// Set the OpenGL Attributes
	SDL_GL_SetAttribute( SDL_GL_RED_SIZE, 5 );
	SDL_GL_SetAttribute( SDL_GL_GREEN_SIZE, 6 );
	SDL_GL_SetAttribute( SDL_GL_BLUE_SIZE, 5 );
	SDL_GL_SetAttribute( SDL_GL_DEPTH_SIZE, 16 );
	SDL_GL_SetAttribute( SDL_GL_DOUBLEBUFFER, 1 );

	surface :=
		SDL_SetVideoMode( scrClientWidth, scrClientHeight, bpp { 16 BPP? }, videoflags );
	if surface = nil then begin SDL_Quit; exit; end;

	// glViewPort(0, 0, scrClientWidth, scrClientHeight); // область вывода
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho( 0, scrClientWidth, scrClientHeight, 0, -1, 1 );

	//Initialize modelview matrix
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();	//-- НЕ НУЖНА?

	//Initialize clear color
	glClearColor(0.0,0.0,0.0,1.0);	// black, not transparent

	// так как размер канвы 640*400 вместо 320*200 ориг.
	glPointSize(2);                   // размер точек 2*2
	glLineWidth(2);	// тольщина линии	2*2
	glPixelStorei(GL_UNPACK_ALIGNMENT, 3);
	glPixelTransferi(GL_INDEX_OFFSET, 1);

	// Set the title bar in environments that support it
	PCapt := StrAlloc(Length(WindowCaption) + StrLen(MyCapt) + 2);
  StrPCopy(PCapt, WindowCaption);	
	StrCat(PCapt, MyCapt);
	SDL_WM_SetCaption(PCapt, PCapt);
	StrDispose(PCapt);
	
  SDL_ShowCursor(SDL_DISABLE); 		// hide cursor? why?
	SDL_EnableKeyRepeat(SDL_DEFAULT_REPEAT_DELAY, SDL_DEFAULT_REPEAT_INTERVAL);
	
	ClearDevice;

	Result := true;
end;

procedure gdwFullScr({fs:boolean});
begin
	if SDL_WM_ToggleFullScreen(surface) >= 0 then
	begin
		inFullScreen := not(inFullScreen);
		gdwSwapBuf;
	end;
end;  { gdwFullScr }

procedure gdwSwapBuf;
begin
//	glFinish;
	SDL_GL_SwapBuffers;	// OpenGL function which swap back buffer to front
//      glBlitFramebuffer(0, 0, 639, 479, 0, 0, 639, 479, GL_COLOR_BUFFER_BIT, GL_LINEAR);
// 	SDL_Flip(surface);
end;

procedure CloseGraph;
begin
	SDL_Quit;
end;

procedure WaitSync;	{ ждем обратного хода луча }
begin
// TO DO??? ha-ha
end;

procedure ClearDevice;	// простейшая очитска экрана 320*200 точек
begin
	glClearColor(0.0,0.0,0.0,1.0);	// black, not transparent
	glClear (GL_COLOR_BUFFER_BIT);      // очистка буфера цвета'
end;    {ClearDevice}

     // так как экран увеличим на 2, всё тоже умножаем на два
procedure PutPixel(Point:Pixel; Color:byte{x,y: integer; c:TColor});
var tc:Uint32;
begin
	tc := VGAColors[Color];	// remap color!
	Point.X := Point.X * 2;
	Point.Y := Point.Y * 2;
	glColor3ub ((tc and $FF),
				((tc and $FF00) shr 8),
				((tc and $FF0000) shr 16));          // цвет точки
	glBegin (GL_POINTS);                // открываем командную скобку
		glVertex2f (Point.X, Point.Y);
	glEnd;
end; { PutPixel }

procedure DelPixel(Point:Pixel);
begin
	Point.X := Point.X * 2;
	Point.Y := Point.Y * 2;
	glColor3f (0.0,0.0,0.0);
	glBegin (GL_POINTS);                // открываем командную скобку
		glVertex2f (Point.X, Point.Y);
	glEnd;
end; { DelPixel }

function GetPixel(Point:Pixel):byte;	// TO DO for SDL GL, or simply sdl?
var i:integer;
	tc: GLUint;
	BitMap: array[0..0,0..0,0..2] of GLUbyte;
begin
	Point.X:=Point.X * 2;
	Point.Y:=Point.Y * 2;
//	tc := scr.Canvas.Pixels[Point.X,Point.Y];
	glReadPixels(Point.X,Point.Y,1,1,GL_RGB,GL_UNSIGNED_BYTE,@BitMap);
    // RGB -> TColor
    tc := (BitMap[0,0,2] shl 16) or (BitMap[0,0,1] shl 8) or (BitMap[0,0,0]);
	for i := 0 to 255 do
		if VGAColors[i] = tc then
		begin
			GetPixel:=i;
			exit;
		end;
	GetPixel:=0;
end;


procedure PutLine(PointSt, PointEn:Pixel; Color:byte);
var tc:Uint32;
begin
	tc := VGAColors[Color];	// remap color!
	
	PointSt.X := PointSt.X * 2;
	PointSt.Y := PointSt.Y * 2;
	PointEn.X := PointEn.X * 2;
	PointEn.Y := PointEn.Y * 2;
	glColor3ub ((tc and $FF),
				((tc and $FF00) shr 8),
				((tc and $FF0000) shr 16));          // цвет точки
	glBegin (GL_LINES);                // открываем командную скобку
		glVertex2f (PointSt.X, PointSt.Y);
		glVertex2f (PointEn.X, PointEn.Y);
	glEnd;
end; { PutLine }

procedure Circle(Center:Pixel; Radius:integer; Color:byte);
var
     R,G,B:GLFloat;	// для цвета, который вычислим один раз
      tc:Uint32;
      sc,koef,step:single;
      x,y:integer;
begin
   tc := VGAColors[Color];	// remap color!

   Radius := Radius * 2;
   Center.X := Center.X * 2;
   Center.Y := Center.Y * 2;

   R :=  (tc and $FF) / 255;
   G := ((tc and $FF00) shr 8) / 255;
   B := ((tc and $FF0000) shr 16) / 255;

	glColor3f(R,G,B);
	glBegin(GL_POINTS);
	
	koef := 1;//scrClientWidth / scrClientHeight;	// коэф.растяжение осей
	sc := 0.0;
    step := 1 / Radius;
    while sc <= 6.283185307179586476925286766559 do
    begin
		x := round(Radius*sin(sc) / koef) + Center.X;
        y := round(Radius*cos(sc)) - Center.Y + scrClientHeight;
        // преобразуем координаты из экранных в OpenGL
//   		R := 2 * x / scrClientWidth - 1;
//		G := 2 * (scrClientHeight - y) / scrClientHeight - 1;
		glVertex2f(x,y);
        sc := sc + step
    end;
	glEnd;
end;// Circle }

procedure Rect(LeftTop, RightBot:Pixel; Color:byte);
var tc:Uint32;
begin
	tc := VGAColors[Color];	// remap color!
	
	LeftTop.X := LeftTop.X * 2;
	LeftTop.Y := LeftTop.Y * 2;
	RightBot.X := RightBot.X * 2 + 1;
	RightBot.Y := RightBot.Y * 2 + 1;
	glColor3f ((tc and $FF) / 255,
				((tc and $FF00) shr 8) / 255,
				((tc and $FF0000) shr 16) / 255);          // цвет точки
	glPolygonMode(GL_FRONT_AND_BACK,GL_LINE);	// тип - линии
	glRectf(LeftTop.X, LeftTop.Y, RightBot.X, RightBot.Y);
end; { Rect }

procedure Bar(LeftTop, RightBot:Pixel; Color:byte);
var tc:Uint32;
begin
	tc := VGAColors[Color];	// remap color!
	LeftTop.X := LeftTop.X * 2;
	LeftTop.Y := LeftTop.Y * 2;
	RightBot.X := RightBot.X * 2 + 1;
	RightBot.Y := RightBot.Y * 2 + 1;

	glColor3f ((tc and $FF) / 255,
				((tc and $FF00) shr 8) / 255,
				((tc and $FF0000) shr 16) / 255);          // цвет точки
	glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);	// тип - заливка
	glRectf(LeftTop.X, LeftTop.Y, RightBot.X, RightBot.Y);
end; { Bar }

////////////////////////////////////////////////////////////////
procedure PutString(LOC:Pixel;Str:string;Color:byte;Oper:byte);
{ вывод строки символов }
var
	i:integer;			{ счетчик      }
	Posit:Pixel;
	Sym:Symbol;
	sb:byte;
begin
		for i:=1 to Length(Str) do begin
			Posit.x:=LOC.x+i-1;
			Posit.y:=LOC.y;
			sb:=ord(Str[i]);
			if (sb > 127) {and (sb < 256)} then
				sb:=oem866_table[sb]; // CharToOEM
			Sym.Code:=word(sb); // convert byte to word? no..
			Sym.Attr:=Color;
			PutSymbol(Posit,   { позиция }
				  Sym,		{ символ }
				  Oper	    ) { операция }
		end
end;
procedure PutPalString(LOC:Pixel;Str:string;Color:byte;Oper:byte);
var
		i:integer;			{ счетчик      }
		Posit:Pixel;
		Sym:Symbol;
		sb:byte;
begin
		for i:=1 to Length(Str) do begin
			 Posit.x:=LOC.x+i-1;
			 Posit.y:=LOC.y;
			sb:=ord(Str[i]);
			if (sb > 127) {and (sb < 256)} then
				sb:=oem866_table[sb]; // CharToOEM			
			Sym.Code:=word(sb);
			Sym.Attr:=Color;
			PutPalSymbol(Posit,   { позиция }
						Sym,		{ символ }
						Oper) { операция }
   	end // for i
end;

	// специально для PutSymbol -
    // вывод точки в координты, GL-скобки
    // задаются в самой процедуре PutSymbol
    // цвет надо задавать, так как DelPixel его сбивает
 	procedure PutSymPixel(Point:Pixel;R,G,B:GLFloat);
	begin
		Point.X := Point.X * 2;
		Point.Y := Point.Y * 2;
   		glColor3f(R,G,B);
		glVertex2f(Point.X, Point.Y);
	end; { PutSymPixel }
	
	// а это - для PalSymbola
 	procedure PutPalPixel(Point:Pixel;Color:byte);
	var R,G,B:GLUByte;	// для цвета, который вычислим один раз
	    tc:Uint32;
	begin	{ вывод символа VGA на дисплей }
	   tc := VGAColors[Color];	// remap color!
	   R :=  (tc and $FF);
	   G := ((tc and $FF00) shr 8);
	   B := ((tc and $FF0000) shr 16);
		Point.X := Point.X * 2;
		Point.Y := Point.Y * 2;
   		glColor3ub(R,G,B);
		glVertex2f(Point.X, Point.Y);
	end; { PutSymPixel }

procedure PutSymbol(LOC:Pixel;ID:Symbol; Oper:byte); { символ VGA13 (8*8 точек) }
var i,j,startData:integer;
		t,bit:byte;
      st: Pixel;
      R,G,B:GLFloat;	// для цвета, который вычислим один раз
      tc:Uint32;
begin	{ вывод символа VGA на дисплей }
   tc := VGAColors[ID.Attr];	// remap color!
   R :=  (tc and $FF) / 255;
   G := ((tc and $FF00) shr 8) / 255;
   B := ((tc and $FF0000) shr 16) / 255;

   dec(LOC.X);   // координаты окна для символов начинаются с 1?
   dec(LOC.Y);
   LOC.X := LOC.X * 8;	// координаты для символов 40*25
   LOC.Y := LOC.Y * 8;
   startData := ID.Code * 8;
   st.X := LOC.X;
   st.Y := LOC.Y;

   glBegin (GL_POINTS);                // открываем командную скобку
	for i:=0 to 7 do begin
   	bit := $80;
		t:= SymData[startData + i];	// берём код описания символа
      for j:=0 to 7 do begin
			if (t AND bit) <> 0 then
         	begin	// есть точка?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1: PutSymPixel(st,R,G,B);
                 3:   PutSymPixel(st,0.0,0.0,0.0);// instead of DelPixel
                 end;
            end
         else
	        	begin	// нет точки?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0: PutSymPixel(st,0.0,0.0,0.0);  // DelPixel
                 3: PutSymPixel(st,R,G,B);
                 end;
            end;
         bit := bit shr 1;
         inc(st.X);
      end; // for j
      st.X := LOC.X;
		inc(st.Y);
   end;	// for i
   glEnd;
end		{ PutSymbol };

// PutSymbol without record types
procedure PutSymbol(X,Y:integer;Code:word;Attr,Oper:byte);
var
	mLOC:Pixel;
	mID:Symbol;
begin
	mLOC.X := X;
	mLOC.Y := Y;
	mID.Code := Code;
	mID.Attr := Attr;
	PutSymbol(mLOC,mID,Oper)
end;


procedure PutBigSymbol(LOC:Pixel; ID:Symbol; Oper:byte; deltaX,deltaY:integer);
{ почти то же саmое, что и предыдущая подпрограмма }
{ только символ выводится увеличенным в deltaX (по горизонтали)   }
{ и deltaY ( по вертикали ) раз. (Фактически его размер удет равен }
{  	(deltaX*8, deltaY*8) точек).	}
var i,j,startData:integer;
		t,bit:byte;
      st: Pixel;
      ix,iy,tmpX,tmpY : integer;
      R,G,B:GLFloat;	// для цвета, который вычислим один раз
      tc:Uint32;
begin	{ вывод символа VGA на дисплей }
   tc := VGAColors[ID.Attr];	// remap color!
   R :=  (tc and $FF) / 255;
   G := ((tc and $FF00) shr 8) / 255;
   B := ((tc and $FF0000) shr 16) / 255;

   dec(LOC.X);   // координаты окна для символов начинаются с 1?
   dec(LOC.Y);
   LOC.X := LOC.X * 8;	// координаты для символов 40*25
   LOC.Y := LOC.Y * 8;

	startData := ID.Code * 8;
	st.X := LOC.X;
	st.Y := LOC.Y;
glBegin (GL_POINTS);                // открываем командную скобку
	for i:=0 to 7 do begin
   	bit := $80;
		t:= SymData[startData + i];	// берём код описания символа
      for j:=0 to 7 do begin
		if (t AND bit) <> 0 then
         	begin	// есть точка?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1:
                 begin
                 	tmpY := st.Y;
                 	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                PutSymPixel(st,R,G,B);
                        inc(st.X,1);
                     end;
                     st.X := tmpX;
                     inc(st.Y,1);	// на 2 точки передвинем неееееееееет
                  end;
                  st.Y := tmpY;
                  st.X := st.X + deltaX;
                 end;
                 3:
                 begin
                 	tmpY := st.Y;
                	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                 	PutSymPixel(st,0.0,0.0,0.0);  // DelPixel
                        inc(st.X,1);
                     end;
                     st.X := tmpX;
                     inc(st.Y,1);
                 	end;
                 st.Y := tmpY;
                 st.X := st.X + deltaX;
            	  end;
            	end; // case
         end // if
         else
	        	begin	// нет точки?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1:
                 begin
                 tmpY := st.Y;
                	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                 	if Oper=0 then PutSymPixel(st,0.0,0.0,0.0);
                        inc(st.X,1);
                     end;
                     st.X := tmpX;
                     inc(st.Y,1);
                 	end;
                 st.Y := tmpY;
                 st.X := st.X + deltaX;
                 end;
                 3:
                 begin
               	tmpY := st.Y;
                 	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                 	PutSymPixel(st,R,G,B);
                        inc(st.X,1);
                     end;
                     st.X := tmpX;
                     inc(st.Y,1);
                 end;
                 st.Y := tmpY;
                 st.X := st.X + deltaX;
                 end;
                 end; //case
            end; // else
         bit := bit shr 1;
//         inc(st.X,1);
      end; // for j
      st.X := LOC.X;
	  st.Y := st.Y + deltaY;	// прыгаем на deltaY - 2 так как экран дубль
   end;	// for i
   glEnd;
end	{ PutBigSymbol };

procedure PutPalSymbol(LOC:Pixel;ID:Symbol;Oper:byte);
{ выводим символ согласно палитре }
var
		i,j,startData,startPal:integer;
		t,bit:byte;
      st: Pixel;
begin
   dec(LOC.X);   // координаты окна для символов начинаются с 1?
   dec(LOC.Y);
   LOC.X := LOC.X * 8;	// координаты для символов 40*25
   LOC.Y := LOC.Y * 8;

   startData := ID.Code * 8;
   startPal := ID.Attr * 64;	// paldata offset
   st.X := LOC.X;
   st.Y := LOC.Y;
glBegin (GL_POINTS);                // открываем командную скобку
	for i:=0 to 7 do begin
   	bit := $80;
		t:= SymData[startData + i];	// берём код описания символа
      for j:=0 to 7 do begin
			if (t AND bit) <> 0 then
         	begin	// есть точка?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1:PutPalPixel(st,PalData[startPal]);
                 3: PutSymPixel(st,0.0,0.0,0.0);
                 end;
            end
         else
	        	begin	// нет точки?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0: PutSymPixel(st,0.0,0.0,0.0);     // DelPixel
                 3: PutPalPixel(st,PalData[startPal]);
                 end;
            end;
         bit := bit shr 1;
         inc(st.X);
         inc(startPal);
      end; // for j
      st.X := LOC.X;
	  inc(st.Y);
   end;	// for i
   glEnd;
end {PutPalSymbol};

procedure PutBigPalSymbol(LOC:Pixel; ID:Symbol; Oper:byte; deltaX,deltaY:integer);{assembler;}
{ почти то же саmое, что и предыдущая подпрограмма }
{ только символ выводится увеличенным в deltaX (по горизонтали)   }
{ и deltaY ( по вертикали ) раз. (Фактически его размер удет равен }
{  	(deltaX*8, deltaY*8) точек).	}
var i,j,startData,startPal:integer;
		t,bit:byte;
      st: Pixel;
      ix,iy,tmpX,tmpY : integer;
      Col: byte;
begin
	dec(LOC.X);   // координаты окна для символов начинаются с 1?
   dec(LOC.Y);
   LOC.X := LOC.X * 8;	// координаты для символов 40*25
   LOC.Y := LOC.Y * 8;

	startData := ID.Code * 8;
   startPal := ID.Attr * 64;	// paldata offset
   st.X := LOC.X;
   st.Y := LOC.Y;

glBegin (GL_POINTS);                // открываем командную скобку
	for i:=0 to 7 do begin
   	bit := $80;
		t:= SymData[startData + i];	// берём код описания символа
      for j:=0 to 7 do begin
			if (t AND bit) <> 0 then
         	begin	// есть точка?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1:
                 begin
                 	tmpY := st.Y;
                 	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		              		Col := PalData[startPal];
		              		PutPalPixel(st,Col);
                        inc(st.X);
                     end;
                     st.X := tmpX;
                     inc(st.Y);
                 end;
                 st.Y := tmpY;
                 st.X := st.X + deltaX;
                 end;
                 3:
                 begin
                 	tmpY := st.Y;
                	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                 	PutSymPixel(st,0.0,0.0,0.0); // DelPixel
                        inc(st.X);
                     end;
                     st.X := tmpX;
                     inc(st.Y);
                 	end;
                 st.Y := tmpY;
                 st.X := st.X + deltaX;
            	 end;
            	end; // case
         end // if
         else
	        	begin	// нет точки?
                 case Oper of       { операция 0=PUT,1=OR,3=INV }
                 0,1:
                 begin
                  tmpY := st.Y;
                	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
		                 	if Oper = 0 then PutSymPixel(st,0.0,0.0,0.0); // DelPixel
                        inc(st.X);
                     end;
                     st.X := tmpX;
                     inc(st.Y);
                 	end;
                  st.Y := tmpY;
                  st.X := st.X + deltaX;
                 end;
                 3:
                 begin
               	tmpY := st.Y;
                 	for iy:= 1 to deltaY do begin
                  	tmpX := st.X;
                  	for ix:=1 to deltaX do begin
                     	Col := PalData[startPal];
	                 		PutPalPixel(st,Col);
                        inc(st.X);
                     end;
                     st.X := tmpX;
                     inc(st.Y);
                  end;
                  st.Y := tmpY;
                  st.X := st.X + deltaX;
                 end;
                 end; //case
            end; // else
         bit := bit shr 1;
//         inc(st.X);
         inc(startPal);
      end; // for j
      st.X := LOC.X;
		inc(st.Y, deltaY);	// прыгаем на deltaY
   end;	// for i
end	{ PutBigPalSymbol };

procedure Put16x16(LOC:Pixel;ID:Symbol;Oper:byte);
{ выводит символ 16*16 точек как четыре 8*8 в следующей диспозиции: }
{	1 - 2		}
{	3 - 4		}
{ на входе - код первого символа 8*8 в таблице символов }
     var Posit:Pixel;Sym:Symbol;
begin
	PutSymbol(LOC,ID,Oper);	{ не все так просто ... }
        Posit.x:=LOC.x+1;Posit.y:=LOC.y;Sym.Code:=ID.Code+1;
        Sym.Attr:=ID.Attr;
	PutSymbol(Posit,Sym,Oper);
        dec(Posit.x);inc(Posit.y);inc(Sym.Code);
	PutSymbol(Posit,Sym,Oper);
        inc(Sym.Code);inc(Posit.x);
	PutSymbol(Posit,Sym,Oper)
end	{ Put16x16 };

procedure PutPal16x16(LOC:Pixel;ID:Symbol;Oper:byte);
{ выводит символ 16*16 точек как четыре 8*8 в следующей диспозиции: }
{ ( с использованием палитры }
{	1 - 2		}
{	3 - 4		}
{ на входе - код первого символа 8*8 в таблице символов }
{ a ID.Attr - номер 1-го тайла палитры (из 4)           }
     var Posit:Pixel;Sym:Symbol;
begin
	PutPalSymbol(LOC,ID,Oper);	{ не все так просто ... }
        Posit.x:=LOC.x+1;Posit.y:=LOC.y;Sym.Code:=ID.Code+1;
        Sym.Attr:=ID.Attr+1;
	PutPalSymbol(Posit,Sym,Oper);
        dec(Posit.x);inc(Posit.y);inc(Sym.Code);inc(Sym.Attr);
	PutPalSymbol(Posit,Sym,Oper);
        inc(Sym.Code);inc(Posit.x);inc(Sym.Attr);
	PutPalSymbol(Posit,Sym,Oper)
end	{ PutPal16x16 };


procedure Put24x24(LOC:Pixel;ID:Symbol;Oper:byte);
        { Вывод символа 24*24 точки как 9 квадпатиков по 8*8 точек каждый}

begin
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);dec(LOC.x,2);inc(LOC.y);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);dec(LOC.x,2);inc(LOC.y);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);
        PutSymbol(LOC,ID,Oper);
end {Put24x24};


procedure PutPal24x24(LOC:Pixel;ID:Symbol;Oper:byte);
        { Вывод символа 24*24 точки как 9 квадпатиков по 8*8 точек каждый}
        { с использованием палитры                                       }
begin
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);dec(LOC.x,2);inc(LOC.y);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);dec(LOC.x,2);inc(LOC.y);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper);
        inc(ID.Code);inc(LOC.x);inc(ID.Attr);
        PutPalSymbol(LOC,ID,Oper)
end {Put24x24};

{	 далее идут 2 subs по работе с образами }
{ это:    GetImage и PutImage	}
procedure GetImage(LeftTop,RightBot:Pixel;var BitMap:gdwImage);	// TO DO!
begin
   BitMap.Width := (abs(RightBot.x-LeftTop.x)+1)*2;
   BitMap.Height := (abs(RightBot.y-LeftTop.y)+1)*2;
   setLength(BitMap.Body,BitMap.Height*BitMap.Width*3*sizeof(GLUbyte));

   LeftTop.X := LeftTop.X * 2;
   LeftTop.Y := LeftTop.Y * 2;
   RightBot.X := RightBot.X * 2 + 1;
   RightBot.Y := RightBot.Y * 2 + 1;
//   glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//   glReadPixels(LeftTop.X,RightBot.Y,BitMap.Width,BitMap.Height,
//   					GL_RGB,GL_UNSIGNED_BYTE,BitMap.Body);
end;

procedure PutImage(LOC:Pixel;BitMap:gdwImage);	// выводит образ в позиию LOC
begin
	glRasterPos2i(LOC.X,LOC.Y + BitMap.Height - 1);
//	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
//	glDrawPixels(BitMap.Width,BitMap.Height,
//    				GL_RGB,GL_UNSIGNED_BYTE,BitMap.Body);
	gdwSwapBuf;
end;		 { PutImage }


end.
