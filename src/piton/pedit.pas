Unit PEdit;        { редактор для составления уровней к питону }

interface

procedure Main;

implementation

Uses SDLglGDWGraph in '../SDLglGDWGraph.pas', PDefs, SysUtils, sdl;

const
      AUP       = 502;                  { курсор стрелка вверх }
      HelpFileName = 'PEDITHLP.PTN';
      Cur:Pixel=(x:20;y:12);
      MySym:Symbol=(Code:8;Attr:8);  { выбранный символ      }
      MyStep:integer=1;              { шаг курсора при вводе }
      MyDir:integer=2;               { направление           }
      Time:word=0;                   { счетчик 1/18 cek      }
      Key:word=0;                    { код нажатия           }
      smod:word = 0;	{ modificator }
      Astra:Symbol=(Code:AUP+2;Attr:38); { курсор вид          }

var
	MapBuf:Screen;   { временное хранение карты }
	loct : Pixel;	// для locate


procedure Locate(X,Y:byte);
begin
	loct.X := X;
	loct.Y := Y;
end;

procedure Mywrite(S:string);
begin	// выводим строку белым цветом
	PutString(loct, S, 15, 0);
	loct.X := loct.X + Length(S);
end;

function ReadLN(x, y: integer; tit: String; var Str: string; MaxLen: integer): boolean;
{ ввод строки специально для PEditor }
{ ввод осуществляем в коорд. x, y }
{ tit - выводимая подсказка }
{ MaxLen задаёт максимальную длину строки }

{ Возврат true при Accept, false - при Cancel }

	var Index, Key:integer;
			N:integer;
			Time:Longword;
			MyLoct:Pixel;
		
	const InsMode:boolean = FALSE;
      CharSym:array[boolean]of char = ('*','^');
			
	procedure AddChar(c:char);
	begin 	// добавляем символ с в строку зависимость от режима
		if Index > Length(Str) then Str:=Str+c
		else
		begin
			if not(InsMode) then Str[InDex] := c
			else if Length(Str)<MaxLen then Insert(c, Str, InDex)
		end;
		if InDex<MaxLen then inc(InDex);
	end;

begin	{ ReadLN }
		Result := false;
		
		Locate(x, y);
		Mywrite(tit);

		InDex:=1;
		MyLoct := loct;
		
		while TRUE do begin
			Locate(x, y);
			Mywrite(tit);
		
			locate(MyLoct.X,MyLoct.Y);
			MyWrite(Str + ' ');
			N := MaxLen-Length(Str);
			
			while N>0 do begin Mywrite(' ');dec(N) end ;
			
			Locate(MyLoct.X - 1 + InDex, MyLoct.Y);
			Mywrite(CharSym[InsMode]); { cursor }
			Time := WhatTime + 4 * TimeZoom;
			Key := 0;
			gdwSwapBuf;
			
			while (Key = 0) and (WhatTime<Time) do Key:=Inkey;
			
			Locate(x, y);
			Mywrite(tit);
		
			locate(MyLoct.X,MyLoct.Y);
			MyWrite(Str + ' ');
			
			Locate(MyLoct.X - 1 + InDex, MyLoct.Y);
			
			if InDex>Length(Str) then Mywrite(' ') else Mywrite(Str[InDex]);
			Time:=WhatTime+6*TimeZoom;
			gdwSwapBuf;
			
			while (Key=0) and (WhatTime<Time) do Key:=Inkey;
			
			if Key<>0 then
			case Key of
				SDLK_SPACE..SDLK_z:
					begin
						AddChar(char(Key));
					end;

//				SCAN_MINUS: AddChar('-');
//				SCAN_DOT: AddChar('.');
//				SCAN_EQUA: AddChar('=');
//       	SDLK_SPACE: AddChar(' ');

				SDLK_LEFT:if InDex>1 then dec(Index);
				SDLK_RIGHT: if (InDex<=Length(Str)) and (InDex<MaxLen) then inc(InDex);
				SDLK_BACKSPACE:if InDex>1 then begin Delete(Str,InDex-1,1);dec(InDex) end;
				SDLK_DELETE:if InDex<=Length(Str) then Delete(Str,InDex,1);
				SDLK_ESCAPE: exit; // false
				SDLK_RETURN: if Length(Str)>0 then 
					begin
						locate(MyLoct.X,MyLoct.Y);
						MyWrite(Str + ' ');
						gdwSwapBuf;
						Result := true;
						exit;
					end;
				SDLK_INSERT: InsMode := not(InsMode);
			end {case Key}
			
		end {while TRUE} ;
		loct.X := MyLoct.X + Length(Str);
end {ReadLN};


function ChooseSym(Sym:word): word;
var i, j:word;Key:word;
	s:string;

	procedure PrintSym(i: word; Oper:byte);
	var P:Pixel;S:Symbol;
	begin
		 S.Code:=i;S.Attr:=38;
		 P.x:=i mod 32 + 1;
		 P.y:=i div 32 + 4;
		 PutPalSymbol(P,S,Oper)
	end;

	procedure Lines;
	const UP1:Pixel=(x:0;y:20); DN1:Pixel=(x:0;y:156);
		  UP2:Pixel=(x:256;y:20); DN2:Pixel=(x:256;y:156);
	begin
		 Bar(UP1,DN2,0);    { очищаем площадь }
		 PutLine(UP1,UP2,14);
		 PutLine(DN1,DN2,14)
	end;

begin
     i:=Sym;Key:=0;
     while (Key<>SDLK_ESCAPE) and (Key<>SDLK_RETURN) do begin
      Lines;
			for j:=0 to 511 do PrintSym(j, 0);

      Locate(30,20);
			s:=Format('%3d',[i]);
			Mywrite(s);
			PrintSym(i, 3);
			gdwSwapBuf;

			repeat Key:=InKey until Key<>0;
			PrintSym(i, 0);
			case Key of
				SDLK_ESCAPE:ChooseSym:=Sym;
				SDLK_RETURN:ChooseSym:=i;
				SDLK_UP:i:=word(i-32)mod 512;
				SDLK_DOWN:i:=word(i+32) mod 512;
				SDLK_RIGHT:i:=word(i+1) mod 512;
				SDLK_LEFT:i:=word(i-1) mod 512
			end
     end
end;

function ChoosePal(Pal:byte):byte;      { выбор тайла палитры (Ctrl-F5) }
var i,j: byte;
		T,key: word;
		s: string;

	procedure Init;
	const A:Pixel=(x:48;y:16); B:Pixel=(x:192;y:160);
	begin
		 Bar(A,B,0);                { очистка }
		 inc(A.x,4);inc(A.y,4);
		 dec(B.x,4);dec(B.y,4);
		 Rect(A,B,15);              { рамка }
		 dec(A.x,4);dec(A.y,4);
		 inc(B.x,4);inc(B.y,4)
	end;
	
	procedure PutCur(i: byte; Oper:byte);
	var P:Pixel;S:Symbol;
	const QUAD = 511;
	begin
		 S.Code:=QUAD;S.Attr:=i;
		 P.x:=i mod 16 + 8;
		 P.y:=i div 16 + 4;
		 PutPalSymbol(P,S,Oper)
	end;
	
begin
     i:=Pal;Key:=0;T:=0;

     while (Key<>SDLK_ESCAPE) and (Key<>SDLK_RETURN) do begin
				Init;
				for j:=0 to 255 do PutCur(j, 0);

				if T mod 16 < 6 then PutCur(i, 3) else PutCur(i, 0);
				
				Key:=InKey;
				Locate(21,20);
				s:=Format('%3d',[i]);
				Mywrite(s);

				if Key<>0 then begin
					PutCur(i, 0);  { сотрем курсор }
					case Key of
						SDLK_ESCAPE:ChoosePal:=Pal;
						SDLK_RETURN:ChoosePal:=i;
						SDLK_UP:i:=i-16;
						SDLK_DOWN:i:=i+16;
						SDLK_LEFT:dec(i);
						SDLK_RIGHT:inc(i)
					end{case}
				end;
				
				gdwSwapBuf;
				
				Wait(1);
				inc(T)
     end{while}
		 
end{ChoosePal};

procedure MyTable;      { таблица внутренних символов питона }
var i, j:byte;
		Key,T:word;
		s:string;
	
		const	NumberOfThings  = 27;
					Things:array[0..NumberOfThings-1] of Symbol = (
             (Code:8;Attr:8),(Code:9;Attr:9),(Code:10;Attr:10),
             (Code:11;Attr:11),(Code:12;Attr:12),(Code:13;Attr:13),
             (Code:14;Attr:14),(Code:15;Attr:15),(Code:16;Attr:16),
             (Code:17;Attr:17),(Code:256;Attr:18),(Code:260;Attr:20),
             (Code:264;Attr:22),(Code:268;Attr:24),(Code:272;Attr:26),
             (Code:273;Attr:26),(Code:274;Attr:26),(Code:275;Attr:26),
             (Code:276;Attr:28),(Code:Seed6;Attr:28),(Code:Block1;Attr:30),
             (Code:Block2;Attr:31),(Code:Key1;Attr:32),(Code:Key2;Attr:33),
             (Code:21;Attr:38),(Code:22;Attr:38),(Code:23;Attr:38)
             );
					NumOfThing:byte=0;
					
	procedure Init;
	const A:Pixel=(x:48;y:16); B:Pixel=(x:192;y:160);
	begin
			 Bar(A,B,0);                { очистка }
			 inc(A.x,4);inc(A.y,4);
			 dec(B.x,4);dec(B.y,4);
			 Rect(A,B,15);              { рамка }
			 dec(A.x,4);dec(A.y,4);
			 inc(B.x,4);inc(B.y,4)
	end;
	
	procedure PutCur(i, Oper: byte);
	var P:Pixel;S:Symbol;
	begin
			 S:=Things[i];
			 P.x:=i mod 16 + 8;
			 P.y:=i div 16 + 4;
			 PutPalSymbol(P,S,Oper)
	end;
	
begin
     i:= NumOfThing;
		 Key:= 0;
		 T:= 0;
		 
     while (Key<>SDLK_ESCAPE) and (Key<>SDLK_RETURN) do
		 begin
				Init;
				for j:=0 to NumberOfThings - 1 do PutCur(j, 0);

				if T mod 16 < 6 then PutCur(i, 3) else PutCur(i, 0);
				
				Key:=InKey;
				Locate(21,20);
				s:=Format('%3d', [i]);
				Mywrite(s);

				if Key<>0 then
				begin
					PutCur(i, 0);  { сотрем курсор }
					case Key of
						SDLK_RETURN: MySym := Things[i];
						SDLK_UP: i := i-16;
						SDLK_DOWN: i := i+16;
						SDLK_LEFT: dec(i);
						SDLK_RIGHT: inc(i)
					end{case}
				end;

				i:=i mod NumberOfThings;
				
				gdwSwapBuf;
				
				Wait(1);
				inc(T)
     end{while};

     if Key<>SDLK_ESCAPE then NumOfThing:=i
end{MyTable};

procedure ShowLevelInfo;
var
	S2:string;
    A:Pixel;
//    Sym:Symbol;

  procedure PutStr2MAP(A:Pixel;Info:string;Pal:byte);
  var i:integer;L:byte;
  begin
	L:=Length(Info);
     for i:=1 to L do begin
         MAP[A.y,A.x+i-1].Code:=ord(Info[i]);
         MAP[A.y,A.x+i-1].Attr:=Pal
     end{for}
  end;

begin
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
// выведем номер тек.уровня
     Str(NumLev:2,S2);
     A.x:=39;A.y:=11;
     PutStr2MAP(A,S2,35);

{     Sym.Code:=ord(S2[1]);
     Sym.Attr:=35;
     PutBigPalSymbol(A,Sym,0,1,2);

     inc(A.x);
     Sym.Code:=ord(S2[2]);
     PutBigPalSymbol(A,Sym,0,1,2); }
end;

procedure SaveMap(Level:word);
var F:file of UniLevel;L:UniLevel;
    x,y:integer;
begin
     with L do begin
          Fl:=QntFly;R:=QntRab;Fr:=QntFrog;M:=QntMan;
          for y:=1 to MapY do
              for x:=1 to MapX do
                  FileMap[y,x]:=MAP[y,x]
     end{with};
{$I-}
     Assign(F,MapsFileName);
     ReSet(F);
     if IOResult<>0 then
     		ReWrite(F);
     Seek(F,(Level-1));
     Write(F,L);
     if IOResult<>0 then {BEEP};	// do nothing YET??
     Close(F)
{$I+}
end{SaveMap};

function LoadIntroFile(S:string):boolean;
var F:file of Screen;
begin
{$I-}
     Assign(F,S);ReSet(F);
     if IOResult<>0 then LoadIntroFile:=false
     else begin
          Read(F,MAP);
          LoadIntroFile:=IOResult=0;
          Close(F)
     end;
{$I+}
	
end;

procedure ReadMap(Level:word);
var F:file of UniLevel;L:UniLevel;
    x,y:integer;
begin
		if not(LoadIntroFile(IntroFileName)) then ClearMap;// грузим intro
{$I-}
         Assign(F,MapsFileName);ReSet(F);
         if IOResult<>0 then begin {BEEP} exit end;
         Seek(F,Level-1);
         Read(F,L);
         if IOResult<>0 then ClearMap
         else
         with L do begin
              QntFly:=Fl;QntFrog:=Fr;QntRab:=R;QntMan:=M;
              for y:=1 to MapY do
                  for x:=1 to MapX do
                      MAP[y,x]:=FileMap[y,x]
         end{with};
         Close(F);
				 // PrintScreen;
         ShowLevelInfo	// покажем информацию об уровне
{$I+}
end{ReadMap};


function SaveIntroFile(S:string):boolean;
var F:file of Screen;
begin
{$I-}
     Assign(F,S);ReWrite(F);
     if IOResult<>0 then SaveIntroFile:=false
     else begin
          Write(F,MAP);
          SaveIntroFile:=IOResult=0;
          Close(F)
     end
{$I+}
end;

procedure GetInfo;
const A:Pixel=(x:56;y:28); B:Pixel=(x:192;y:160);
var s:string;
begin
		Bar(A,B,0);Rect(A,B,13);Locate(11,5);
		Mywrite('*Get Info*');
		Locate(9,8);
		s:=Format('Level=%3d',[NumLev]);
		Mywrite(s);
		Locate(9,10);
		s:=Format('Code=%3d',[MySym.Code]);
		Mywrite(s);
		Locate(9,11);
		s:=Format('Attr=%3d',[MySym.Attr]);
		Mywrite(s);
		Locate(9,12);
		s:=Format('Step=%2d',[MyStep]);
		Mywrite(s);
		Locate(9,14);
		s:=Format('x=%2d | y=%2d',[Cur.x,Cur.y]);

		Mywrite(s);
		Locate(19,20);Mywrite('by gDw');

		// вывод кол-ва жителей уровня
		s:=Format('Rab:%3d',[QntRab]);
		Locate(9,16);Mywrite(s);
		s:=Format('Frg:%3d',[QntFrog]);
		Locate(9,17);Mywrite(s);
		s:=Format('Fly:%3d',[QntFly]);
		Locate(9,18);Mywrite(s);
		s:=Format('Man:%3d',[QntMan]);
		Locate(9,19);Mywrite(s);
		 
		gdwSwapBuf;
		WaitWithKey(180)
end;

procedure InPutNumberofBeings;
	const A:Pixel=(x:56;y:28); B:Pixel=(x:192;y:160);
	var s:string;
begin
		// small hack for back-buffer
    Bar(A,B,0);Rect(A,B,13);Locate(9,5);Mywrite('Input numbers:');
		gdwSwapBuf;
		Bar(A,B,0);Rect(A,B,13);Locate(9,5);Mywrite('Input numbers:');
		gdwSwapBuf;

		s:=IntToStr(QntRab);
		if ReadLn(9, 8, 'Rab:', s, 2)
		then QntRab := StrToIntDef(s,0)
		else exit;
		
		s:=IntToStr(QntFrog);
		if ReadLn(9, 9, 'Frg:', s, 2)
		then QntFrog := StrToIntDef(s,0)
		else exit;

		s:=IntToStr(QntFly);
		if ReadLn(9, 10, 'Fly:', s, 2)
		then QntFly := StrToIntDef(s,0)
		else exit;
		
		s:=IntToStr(QntMan);
		if ReadLn(9, 11, 'Men:', s, 2)
		then QntMan := StrToIntDef(s,0);

//		ShowLevelInfo	// обновим инфо об уровне
end;

procedure NextPos(var Spot:Pixel;Dir:word);
{ Dir может быть от 0 до 7 - считается от севера по часовой стрелке }
const       deltaCoor:array[0..7] of Pixel = (
            (x:0;y:-1),(x:1;y:-1),(x:1;y:0),(x:1;y:1),
            (x:0;y:1),(x:-1;y:+1),(x:-1;y:0),(x:-1;y:-1));
begin
	 PutPalSymbol(Spot,MAP[Spot.y,Spot.x],0);
	 Spot.x:=Spot.x+deltaCoor[Dir].x;
     Spot.y:=Spot.y+deltaCoor[Dir].y;
     if Spot.x<1 then Spot.x:=MaxX else if Spot.x>MaxX then Spot.x:=1;
     if Spot.y<1 then Spot.y:=MaxY else if Spot.y>MaxY then Spot.y:=1
end;

procedure SummonThing(VID:Symbol;N:word);       { породить вещи в карте }
var A:Pixel;T:Longword;
begin
     T:=WhatTime+2*TimeZoom;
     while N>0 do begin
           if WhatTime>=T then exit;
           A.x:=Random(32)+1;
           A.y:=Random(25)+1;
           if CorCoor(A) then
           begin
                dec(N);MAP[A.y,A.x]:=VID
           end
     end
end;

procedure FillMap(Sym:Symbol);  { заполнение карты заданным символом }
var i,j:integer;
begin
     for i:=1 to MapY do
         for j:=1 to MapX do
             MAP[i,j]:=Sym
end{FillMap};


// быстрый переход на уровень
function GotoLevel:integer;
const A:Pixel=(x:56;y:28); B:Pixel=(x:192;y:44);
var s:string;
begin

		// small hack for back-buffer
		Bar(A,B,0);Rect(A,B,13);
		gdwSwapBuf;		 
		Bar(A,B,0);Rect(A,B,13);
		gdwSwapBuf;		 
		
		s:=IntToStr(NumLev);
		if ReadLn(9, 5, 'Go to level:', s, 2)
		then GotoLevel := StrToIntDef(s,0)
		else GotoLevel := NumLev;
end;

function YesNo(s:string):boolean;
// true - yes, false - noooooo
const A:Pixel=(x:56;y:28); B:Pixel=(x:212;y:60);
	LOCY:Pixel=(x:11;y:7);LOCN:Pixel=(x:15;y:7);

var Key:word;
	Choose:boolean;
begin
	Choose:=true;
	
	while true do begin
		Bar(A,B,0);
		Rect(A,B,13);
		Locate(9,5);
		Mywrite('Save '+s+'?');

		Locate(11,7);MyWrite('Yes  No  ');
		if Choose then
			PutString(LOCY,'Yes ', 3, 3)
		else
			PutString(LOCN,' No  ', 3, 3);

		gdwSwapBuf;

		Key:=Inkey;
		while Key=0 do Key:=Inkey;

		case Key of
			SDLK_LEFT,SDLK_RIGHT,SDLK_UP,SDLK_DOWN: Choose:= not Choose;
			SDLK_ESCAPE: begin Choose:=false; break end;
			SDLK_RETURN: break;
		end;//case
		//     gdwSwapBuf;
		Wait(1);
	end;//while true
		 
  YesNo:=Choose
end;

procedure KeyBoard;     { обслуживание клавиатуры }
var i,L:integer;
begin
  if smod and KMOD_ALT <> 0 then  MyStep := Key - SDLK_F1 + 1  // смена шага пера

  else
  case Key of
     SDLK_ESCAPE:begin CloseGraph; halt end;	// Выход

     SDLK_UP:begin NextPos(Cur,0);exit;end;		// перемещение курсора
     SDLK_PAGEUP:begin NextPos(Cur,1);exit;end;
     SDLK_RIGHT:begin NextPos(Cur,2);exit;end;
     SDLK_PAGEDOWN:begin NextPos(Cur,3);exit;end;
     SDLK_DOWN:begin NextPos(Cur,4);exit;end;
     SDLK_END:begin NextPos(Cur,5);exit;end;
     SDLK_LEFT:begin NextPos(Cur,6);exit;end;
     SDLK_HOME:begin NextPos(Cur,7);exit;end;
		 
// переход на уровни
     SDLK_INSERT:
     begin
	     if NumLev>1 then dec(NumLev) else NumLev:=MaxLevel;
			 ReadMap(NumLev);
			 PrintScreen;
			 gdwSwapBuf;
     end;

     SDLK_DELETE:
		 begin
				inc(NumLev);
				if NumLev > MaxLevel then NumLev:=1;
				ReadMap(NumLev);
				PrintScreen;
				gdwSwapBuf;
     end;
// ввод нескольких одинаковых символов
     SDLK_RETURN:
     		begin
           for i:=1 to MyStep do
               begin
                MAP[Cur.y,Cur.x].Code:=MySym.Code;
                MAP[Cur.y,Cur.x].Attr:=MySym.Attr;
                NextPos(Cur,MyDir);
               end;
            exit
           end;
     // заменить клаву таб другой? But why?!  :)
     SDLK_TAB:for i:=1 to 4 do begin
             MAP[Cur.y,Cur.x].Code:=MySym.Code;
             MAP[Cur.y,Cur.x].Attr:=MySym.Attr;
             NextPos(Cur,2)
             end;

     SDLK_F1: if smod and KMOD_SHIFT <> 0 then begin if YesNo(HelpFileName) then SaveIntroFile(HelpFileName) end
        else if smod and KMOD_CTRL <> 0 then MapBuf:=Map
		else 
		begin
			LoadIntroFile(HelpFileName);
			PrintScreen;
			gdwSwapBuf;
		end;

     SDLK_F2: if smod and KMOD_SHIFT <> 0 then begin if YesNo(IntroFileName) then SaveIntroFile(IntroFileName) end
     	else if smod and KMOD_CTRL <> 0 then Map:=MapBuf
		else if YesNo('Level ' + IntToStr(NumLev)) then SaveMap(NumLev);
     SDLK_F3:if smod and KMOD_SHIFT <> 0 then LoadIntroFile(IntroFileName) else
     if smod and KMOD_CTRL <> 0 then SummonThing(MySym,MyStep)
     else ReadMap(NumLev);
     SDLK_F4:if smod and KMOD_CTRL <> 0 then MySym.Code:=ChooseSym(MySym.Code) else MyTable;
     SDLK_F5:if smod and KMOD_CTRL <> 0 then MySym.Attr:=ChoosePal(MySym.Attr)
     else begin MyDir:=(MyDir+1) and 7;Astra.Code:=AUP+MyDir end;

     SDLK_F7: if smod and KMOD_SHIFT <> 0 then
        begin
           for i:=1 to MyStep do
               begin
         //       MAP[Cur.y,Cur.x].Code:=MySym.Code;
                MAP[Cur.y,Cur.x].Attr:=MySym.Attr;
                NextPos(Cur,MyDir);
               end;
            exit
         end;

     SDLK_F8:if smod and KMOD_SHIFT <> 0 then FillMap(MySym) else ClearMap;
     SDLK_F9:if smod and KMOD_SHIFT <> 0 then
     begin
     	L := GotoLevel;
      if L>0 then
			begin
				if L > MaxLevel then L := MaxLevel;
				NumLev := L;
				ReadMap(NumLev);
			end;
     end
     else InPutNumberOfBeings;

     SDLK_F10:if smod and KMOD_SHIFT <> 0 then MySym:=MAP[Cur.y,Cur.x]
	     else GetInfo;
     else begin if Key < 256 then begin
                MAP[Cur.y,Cur.x].Code:=ord(Key);
                MAP[Cur.y,Cur.x].Attr:=MySym.Attr;
                NextPos(Cur,MyDir);
                exit
          end end
  end;//case
	
end;

procedure Error(S:string);
begin
     halt(255);
end;

procedure Main;
begin                   {///////////////MAIN\\\\\\\\\\\\\}
     if LoadSymData(SymFileName)<>0 then Error(SymFileName);
     if LoadPalData(PalFileName)<>0 then ;
     if NumPal<50 then Error(PalFileName);
		 
//     if not(LoadIntroFile(IntroFileName)) then ClearMap;

     NumLev:=1;
     ReadMap(NumLev);
     MapBuf:=Map;                         { инициализируем MapBuf }
     NumLev:=1;
		 InitGraph('Piton-99 | Level and screen editor');

     Randomize;

     while true do begin
				PrintScreen;
				ShowLevelInfo;
//				gdwSwapBuf;
				
			 if Time mod 12<6 then
				PutPalSymbol(Cur,MySym,0)
			 else
				PutPalSymbol(Cur,Astra,0);

       gdwSwapBuf;

			 Key:=EInKey(smod);
			 if Key<>0 then KeyBoard;
			 
			 Wait(1);
			 inc(Time)
     end
end;                    {//////////////MAIN\\\\\\\\\\\\\\\}

end.
