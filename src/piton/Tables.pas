Unit Tables;    {  Таблица рекордов и меню }
interface
         Uses PDefs,UPiton,SDLglgdwGraph, sdl{,Graphics,Dialogs};

const 
		MaxParticipiant = 10;
type     Part = record
              Name:shortstring;
              Scores:word;
              MaxLen:word;
         end;
         TriumphTable = object
                      Participiant:array[1..MaxParticipiant] of Part;
                      TempMap:Screen;
                      Forma:array[1..14,1..28]of Symbol;
                      procedure LoadTable(var Err:byte);
                      procedure StoreTable(var Err:byte);
                      procedure ShowTable;
                      procedure HideTable;
                      procedure InsertName(Sc,Ln:word);
                      procedure InitForma;
                      procedure FillFormRec(Num:word);
                      procedure Forma2Map(LeftUp:Pixel);
                      procedure MoveTable2Center(From:Pixel);
                      procedure NullTable;
                      procedure PutStr2Forma(A:Pixel;S:string;P:byte);
         end;
var      ScoreTable:TriumphTable;

type     Menu = object
         TempMap:Screen;
         Forma:array[1..20,1..23] of Symbol;
         procedure InitForma;
         procedure PutStr2Forma(A:Pixel;S:string;P:byte);
         procedure ControlMenu;
         procedure ShowMenu;
         procedure HideMenu;
         procedure Menu2Map(Where:Pixel);
         end;
var      MenuTable:Menu;

procedure NewGame;
procedure ExitGame;

implementation

{Uses Windows;}

procedure InputString(LOC:Pixel;var S:shortstring;Tile:byte;StrLen:byte);
var NLOC:Pixel;Sym:Symbol;
    Index,Key:word;Time:word;
    L:integer;
const Star:Symbol=(Code:20;Attr:38);
begin
		Time:=0;
		Sym.Attr:=Tile;NLOC.y:=LOC.y;Index:=1;
		while true do begin
           PutPalString(LOC,S,Tile,0);
       		L := Length(S);
           if L<StrLen then begin     { сотрем последний символ }
              NLOC.x:=LOC.x+L;
              PutPalSymbol(NLOC,SPACE,0)
           end;
           NLOC.x:=LOC.x+Index-1;
           if Index>L then Sym.Code:=Blank else Sym.Code:=ord(S[Index]);
           if Time mod 12<7 then PutPalSymbol(NLOC,Sym,0)
           else PutPalSymbol(NLOC,Star,0);               { мигаем курсором }
           Key:=Inkey;
           if Key<>0 then begin
	           PutPalSymbol(NLOC,Sym,0);
	           case Key of
	      	     SDLK_LEFT:if Index>1 then dec(Index);
	         	  SDLK_RIGHT:if (Index<=L) and (Index<StrLen) then inc(Index);
		           SDLK_BACKSPACE:if Index>1 then
	              	begin Delete(S,Index-1,1);dec(Index) end;
	   	        	SDLK_DELETE:if Index<=L then Delete(S,Index,1);
		           SDLK_ESCAPE,SDLK_RETURN:if L>0 then exit;
                 else
                 	begin
	               	if Index>L then S:=S+char(Key) else S[Index]:=char(Key);
			            if Index<StrLen then inc(Index)
	   			   end
	           end { case }
           end { if Key<>0 };
           gdwSwapBuf;
           Wait(1);inc(Time)
		end{while}
end;

procedure ExitGame;     { \\\\\\\ Выход из Игры //////// }
var E:byte;
begin
     ScoreTable.StoreTable(E);
     CloseGraph;
//     if E>0 then ShowMessage('Could not create Table of Scores...');
//     ShowMessage('Thank you for playing with me. Your Pyttie!');
     Halt
end;
procedure NewGame;      { \\\\\\\\ Старт Новой Игры!!!//////}
var Z:Pixel;var Sym:Symbol;
begin
     YMenu:=false;YTable:=false;YLevel:=true;
     YPaused:=false;
     NumLev:=FromLevel-1; { начальный уровень }
     if(GameType=BOAS) or (GameType=CLASSIC) then
     begin	// default values which don't care
     	NumLev:=1;
        QntFly:=0;
        QntRab:=0;
        QntFrog:=0;
        QntMan:=0;
        Z.x:=39;Z.y:=11;
         Sym.Code:=32;
         Sym.Attr:=35;
	     PutBigPalSymbol(Z,Sym,0,1,2);
         inc(Z.x);
//         Sym.Code:=ord('1');
		 PutBigPalSymbol(Z,Sym,0,1,2)
     end;

     Cycles:=0;
     with Boa[1] do begin
          Condition:=BORN;Lives:=3;Score:=0;MaxLength:=0;Len:=3
     end;
     with Boa[2] do begin
          Condition:=BORN;Lives:=3;Score:=0;MaxLength:=0;Len:=3
     end;
     if (NumOfPl=1) and (GameType<>BOAS) then Boa[2].Condition:=EMPTY
end{NewGame};


const TCode = $A5;
      TWCode = $3A6C;
      TMCode = $89F1;

procedure TriumphTable.LoadTable(var Err:byte);
var
	i,j:byte;
   F:file of Part;
begin
     Assign(F,TableFileName);
     Reset(F);
     Err:=IOResult;
     if Err>0 then exit;
     for i:=1 to MaxParticipiant do begin
         Read(F,Participiant[i]);
     end;
     Err:=IOResult;Close(F);
     if Err>0 then exit;
     { декодируем текст из таблицы рекордов }
     for i:=1 to MaxParticipiant do begin
         for j:=1 to 12 do
             Participiant[i].Name[j]:=chr(ord(Participiant[i].Name[j]) xor TCode);
         Participiant[i].Scores:=Participiant[i].Scores xor TWCode;
         Participiant[i].MaxLen:=Participiant[i].MaxLen xor TMCode
     end
end{LoadTable};
procedure TriumphTable.StoreTable(var Err:byte);
var i,j:integer;F:file of Part;
begin
     for i:=1 to MaxParticipiant do begin
         for j:=1 to 12 do
             Participiant[i].Name[j]:=chr(ord(Participiant[i].Name[j]) xor TCode);
         Participiant[i].Scores:=Participiant[i].Scores xor TWCode;
         Participiant[i].MaxLen:=Participiant[i].MaxLen xor TMCode
     end;
     Assign(F,TableFileName);ReWrite(F);Err:=IOResult;
     if Err>0 then exit;
     for i:=1 to MaxParticipiant do
         Write(F,Participiant[i]);
     Err:=IOResult;Close(F)
end {StoreTable};

procedure TriumphTable.PutStr2Forma(A:Pixel;S:string;P:byte);
var i:integer;ss:string;bb:byte;
begin
     for i:=0 to Length(S)-1 do begin
         ss:=S[i+1];
         bb:=ord(ss[1]);
         if bb > 127 then bb:= oem866_table[bb];
//  			CharToOEMBuff(@ss[1], @ss[1], Length(ss));
         Forma[A.y,A.x+i].Code:=word(bb);//ord(SS[1]);
         Forma[A.y,A.x+i].Attr:=P
     end
end;
procedure TriumphTable.InitForma;
var       Pix:Pixel;Sym:Symbol;S:string[2];
				x,y:integer;
const     Tochka:Symbol = (Code:ord('.');Attr:37);
          TStr:string[16]='Таблица рекордов';
begin
     for y:=1 to 14 do for x:=1 to 28 do begin
     		Pix.x := x;
         Pix.Y := y;
         Forma[Pix.y,Pix.x]:=SPACE;
     end;
     Forma[1,1]:=LUC;Forma[1,28]:=RUC;
     Forma[14,1]:=LDC;Forma[14,28]:=RDC;
     for x:=2 to 27 do begin
     		Pix.X := x;
         Forma[1,Pix.x]:=HSLASH;
         Forma[14,Pix.x]:=HSLASH
     end;
     for y:=2 to 13 do begin
     		Pix.y := y;
         Forma[Pix.y,1]:=VSLASH;
         Forma[Pix.y,28]:=VSLASH
     end;
     Pix.x:=7;Pix.y:=1;PutStr2Forma(Pix,TStr,36);
     Pix.x:=2;
     for y:=3 to MaxParticipiant+2 do begin
     		Pix.Y := y;
         Str((Pix.y-2):2,S);
         PutStr2Forma(Pix,S,37);
         Forma[Pix.y,Pix.x+2]:=Tochka
     end;
     for y:=1 to MaxParticipiant do
     begin
      Pix.Y := y;
     	FillFormRec(Pix.y)
     end;
end {InitForma};
procedure TriumphTable.FillFormRec(Num:word);
var S:string[5];Pix:Pixel;
begin
     Pix.y:=Num+2;Pix.x:=5;
     PutStr2Forma(Pix,Participiant[Num].Name,38);
     Str(Participiant[Num].Scores:5,S);Pix.x:=18;
     if Participiant[Num].Scores>0 then PutStr2Forma(Pix,S,39);
     Forma[Pix.y,23].Code:=ord('0');
     Forma[Pix.y,23].Attr:=39;
     Str(Participiant[Num].MaxLen:3,S);
     Pix.x:=25;PutStr2Forma(Pix,S,40)
end;
procedure TriumphTable.Forma2Map(LeftUp:Pixel);
var A:Pixel;
	x,y:integer;
begin
     For y:=LeftUp.y to LeftUp.y+13 do
         for x:=LeftUp.x to LeftUp.x+27 do
         begin
         	A.x := x; A.Y :=y;
             if IsInMap(A) then
                MAP[A.y,A.x]:=Forma[A.y-LeftUp.y+1,A.x-LeftUp.x+1]
         end;
end;
procedure TriumphTable.ShowTable;
const D:Pixel=(x:3;y:5);
begin
     TempMap:=MAP;Forma2Map(D)
end;
procedure TriumphTable.HideTable;
begin
     MAP:=TempMap
end;

procedure TriumphTable.MoveTable2Center(From:Pixel);
const D:Pixel=(x:3;y:5);
begin
     TempMap := MAP;
		 
     while (D.x<>From.x) or (D.y<>From.y) do
     begin
          Forma2Map(From);
					PrintScreen;
					gdwSwapBuf;
					Wait(1);
					
          MAP:=TempMap;

          if D.x<From.x then dec(From.x);
          if D.x>From.x then inc(From.x);
          if D.y<From.y then dec(From.y);
          if D.y>From.y then inc(From.y)
     end {while}
end;

procedure TriumphTable.NullTable;
var i:byte;
begin
     for i:=1 to MaxParticipiant do begin
         Participiant[i].Name:='            ';
         Participiant[i].Scores:=0;
         Participiant[i].MaxLen:=0
     end
end;


procedure TriumphTable.InsertName(Sc,Ln:word); { вставить инфо об игроке в таблицу /
                                     ввести имя, если очков достаточно }
var Num,i:integer;A:Pixel;

function WhereNum:integer;
var N:integer;
begin
     for N:=1 to MaxParticipiant do
         if Sc>Participiant[N].Scores then begin WhereNum:=N;exit end
         else if Sc=Participiant[N].Scores then
              if Ln>Participiant[N].MaxLen then
                 begin WhereNum:=N;exit end;
     WhereNum:=0;
end;

procedure ShiftTableDown(N:integer);
var i:integer;
begin
     if N<MaxParticipiant then for i:=MaxParticipiant downto N+1 do
     begin
          Participiant[i].Name:=Participiant[i-1].Name;
          Participiant[i].Scores:=Participiant[i-1].Scores;
          Participiant[i].MaxLen:=Participiant[i-1].MaxLen
     end;
     Participiant[N].Name:='            ';
     Participiant[N].Scores:=Sc;Participiant[N].MaxLen:=Ln
end;
begin
     Num:=WhereNum;
     if Num>0 then begin
        ShiftTableDown(Num);
        for i:=1 to MaxParticipiant do FillFormRec(i);
        ShowTable;ReFreshScreen;
        A.x:=7;A.y:=6+Num;
//        Participiant[Num].Name := '';
        InputString(A,Participiant[Num].Name,38,12);
        FillFormRec(Num);                           { запомним введенное имя }
        HideTable
     end{if}
end;

procedure Menu.PutStr2Forma(A:Pixel;S:string;P:byte);
var i:integer;ss:string;bb:byte;
begin
     for i:=0 to Length(S)-1 do begin
     		ss:=S[i+1];
	        bb:=ord(ss[1]);
    	    if bb > 127 then bb:= oem866_table[bb];
//  			CharToOEMBuff(@ss[1], @ss[1], Length(ss));
         Forma[A.y,A.x+i].Code:=word(bb);//ord(ss[1]);
         Forma[A.y,A.x+i].Attr:=P
     end
end;
procedure Menu.InitForma;
var i,j:integer;
const MenuStr:array[1..13] of string[19]=('>Меню<','Игроков:1','Старт игры:',
                           'Питон классический','Питон универсальный',
                           'Удавы Судьбы','Управление:','Игрок 1:клава 1',
                           'Игрок 2:клава 2','Таблица рекордов','Возврат в',
                           'Выход','gDw');
      MenuPos:array[1..13] of Pixel = ((x:9;y:1),(x:3;y:3),(x:3;y:5),(x:4;y:6),
                           (x:4;y:7),(x:4;y:8),(x:3;y:10),(x:4;y:11),
                           (x:4;y:12),(x:3;y:14),(x:3;y:16),(x:3;y:18)
                           ,(x:20;y:20));
      MenuPal:array[1..13] of byte = (41,42,44,43,43,43,44,36,36,45,46,47,48);
begin
     for i:=1 to 20 do for j:=1 to 23 do Forma[i,j]:=SPACE;
     Forma[1,1]:=LUC;Forma[1,23]:=RUC;
     Forma[20,1]:=LDC;Forma[20,23]:=RDC;
     for i:=2 to 22 do begin
         Forma[1,i]:=HSLASH;
         Forma[20,i]:=HSLASH
     end;
     for i:=2 to 19 do begin
         Forma[i,1]:=VSLASH;
         Forma[i,23]:=VSLASH
     end;
     for i:=1 to 13 do
         PutStr2Forma(MenuPos[i],MenuStr[i],MenuPal[i])
end {InitForma};
procedure Menu.Menu2Map(Where:Pixel);
var A:Pixel;x,y:integer;
begin
     for y:=Where.y to Where.y+19 do
         for x:=Where.x to Where.x+22 do
         begin
         	A.X := x;
            A.Y := y;
            if IsInMAP(A) then MAP[A.y,A.x]:=Forma[A.y-Where.y+1,A.x-Where.x+1]
         end
end;
procedure Menu.ShowMenu;
const D:Pixel=(x:7;y:4);
begin
     TempMap:=MAP;
     Menu2Map(D)
end;
procedure Menu.HideMenu;
begin
     MAP:=TempMap
end;
procedure Menu.ControlMenu;
const
      PosYUkaz:array[1..9] of integer = (3,6,7,8,11,12,14,16,18);
      A:Pixel=(x:13;y:16);
      MenuTime:word=0;
var   S:string[4];C:Symbol;
begin
     Forma[3,11].Code:=$30+NumOfPl;
     Forma[11,18].Code:=$30+Ctrl1Pl;
     Forma[12,18].Code:=$30+Ctrl2Pl;
     if GameType=DEMO then S:='ДЕМО' else S:='ИГРУ';
     PutStr2Forma(A,S,42);
     if (MenuTime mod 10)<7 then C.Code:=20 else C.Code:=Blank;
     C.Attr:=49;
     Forma[PosYUkaz[Ukaz],2]:=SPACE;
     if YENTERed then
     case Ukaz of
     1:if NumOfPl=1 then inc(NumOfPl) else dec(NumOfPl);
     2,3,4:begin
                GameType:=GMTP(Ukaz-1);
                NewGame
           end;
     5:if Ctrl1Pl=1 then inc(Ctrl1Pl) else dec(Ctrl1Pl);
     6:if Ctrl2Pl=1 then inc(Ctrl2Pl) else dec(Ctrl2Pl);
     7:begin YTable:=true;YMenu:=false end;
     8:begin YMenu:=false;YPaused:=false end;
     9:ExitGame                              { выход из питона }
     end{case};
     case Pl1Stat of 0,3:dec(Ukaz);1,2:inc(Ukaz) end;
     case Pl2Stat of 0,3:dec(Ukaz);1,2:inc(Ukaz) end;
     if Ukaz<1 then Ukaz:=9 else if Ukaz>9 then Ukaz:=1;
     inc(MenuTime);
     Forma[PosYUkaz[Ukaz],2]:=C
end{ControlMenu};

end.
