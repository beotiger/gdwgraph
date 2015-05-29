Unit UPiton;
{ движение питона и обрубков хвостов фрррр...}
interface
Uses SDLGLgdwGraph,PDefs;

type Piton = object
     Head,Tail,Game:Pixel;
     Dir:word;
     Condition:State;
     VID:Symbol;
     Len,extLen:integer;
     Speed,xSpeed:word;
     Timer:word;
     Score,Stamina,MaxLength:word;
     Lives:byte;
     YMove:boolean;
     procedure Move;
     procedure Init(H:Pixel;D:word;V:byte;L:integer;Spd:word);
     procedure Control;
     private
     procedure Bear;
     procedure CutTail;
     procedure Check;
     procedure RunCutting;
end {object};
var  Boa:array[1..MaxPiton] of Piton;

type PPiTail = ^PiTail;
    Pitail = object
     Beg,Fin:Pixel;
     Speed,xSpeed:word;
     Prev,Next:PPitail;
     Done:boolean;
     constructor Init;
     destructor Remove;
     procedure Move;
     end;
const  LastTail:PPiTail=NIL;
type    PBeing = ^Being;
        Being = object
        LOC,Game:Pixel;
        VID:Symbol;
        Kind:word;
        NPic:word;
        Dir,Speed,xSpeed,Timer:word;
        Stamina:word;               { Stamina используется AI... }
        Prev,Next:PBeing;{ указатели на предыдущий и послудующий обхекты в списке }
        constructor Create(Pos:Pixel;K:word);
        destructor ReMove;
        procedure Move;

        private
        procedure MoveFly;
        procedure MoveRab;
        procedure MoveFrog;
        procedure MoveMan;
        procedure MoveSeed;
        procedure MoveBlock;
        procedure MoveKey;

        end {object};
const   LastBeing:PBeing = NIL;
procedure SummonBeing(Kind:word;N:word);        { породить объекты питона }
procedure SummonThing(VID:Symbol;N:word);       { породить вещи в карте }
procedure ClearObjects;
procedure CreateBeing(LOC:Pixel;Kind:word);


implementation

function FindPythonHead(LOC:Pixel):integer;forward;
procedure CreatePitail(St,En:Pixel;Spd:word);forward;
procedure FindBeing(C:Pixel;var Be:PBeing);forward;
     { найти объект по координатам в C}
procedure MoreBeings(Spot:Pixel;Kind:word;Numb:word);forward;

{ удалим объект, но не из памяти и списка, а просто ... }
procedure DelThisOne(Spot:Pixel;B:PBeing);forward;
 { B нужна, чтобы объект не удалил сам себя }
procedure IfIsTail(LOC:Pixel;var T:PPiTail);forward;
procedure FindPiTail(LOC:Pixel;var T:PPiTail);forward;



procedure Piton.Control;
begin
     if Condition=EMPTY then exit;
     if (Len=0)  then begin
        Len:=3;Condition:=DEADONE;Timer:=DeadTime
     end;
     case Condition of
     DEADONE:if Timer>0 then dec(Timer) else begin
                if Lives=0 then Condition:=EMPTY else
                begin dec(Lives);Condition:=BORN end end;
     FROZEN:if Timer>0 then dec(Timer) else begin Condition:=GOOD;
               Timer:=HungryTime end;
     GOOD:begin
               Move;
               if Timer=0 then begin Timer:=HungryTime;dec(extLen) end
               else dec(Timer)
               end;
     GOD:begin
         if Timer=0 then begin Condition:=GOOD;Timer:=HungryTime end
            else dec(Timer);
            Move
         end;
     BORN:Bear
     end{case}
end;
procedure Piton.Init(H:Pixel;D:word;V:byte;L:integer;Spd:word);        { предварительная инициализация питона }
begin
     Head:=H;VID.Attr:=V;Dir:=D;Len:=L;Speed:=Spd;Condition:=BORN
end;

procedure Piton.Bear;        { появление питона в уровне }
begin
     if MAP[Head.y,Head.x].Code>255 then exit; { здесь что-движущееся }
     if MAP[Head.y,Head.x].Code<8 then exit;   { это тело питона или его голова }
     Tail:=Head;extLen:=Len-1;Len:=1;
     Condition:=GOD;Timer:=InitTime;
     BackDir(Dir);Stamina:=0;
     xSpeed:=Speed;
     MAP[Head.y,Head.x].Code:=4+Dir;
     MAP[Head.y,Head.x].Attr:=VID.Attr
end;

procedure Piton.Move;           { питон ползет }
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     xSpeed:=Speed;
     MAP[Head.y,Head.x].Code:=Dir;NextCoor(Head,Dir);
     Check;
     if (not(YCrushed)) then
     	 YCrushed := not(YMove);
     if not(YMove) then PrevCoor(Head,Dir);
     MAP[Head.y,Head.x].Code:=4+Dir;
     MAP[Head.y,Head.x].Attr:=VID.Attr;
     if GameType=BOAS then begin
        if YCrushed then inc(Score);      { счетчик столкновений }
        exit
     end;
      if YMove then begin
        if ExtLen=0 then CutTail
        else if ExtLen>0 then begin dec(extLen);inc(Len) end
     end;
     if (not(YMove)) and (Condition<>GOD) then dec(extLen);
     if extLen<0 then begin CutTail;if YMove then CutTail;inc(extLen);dec(Len) end;
     if MaxLength<Len then MaxLength:=Len
end {Piton.Move};

procedure Piton.CutTail;
var C:word;
begin
     C:=MAP[Tail.y,Tail.x].Code;
     MAP[Tail.y,Tail.x].Code:=Blank;
     NextCoor(Tail,C)
end;

procedure Piton.Check;
var       The:word;Be:PBeing;
const     BonScore:array[1..9]of word = (10,5,7,20,0,1,2,3,4);
          BonLen:array[1..9]of integer = (3,1,2,5,0,1,1,2,2);
begin
     YMove:=true;
     The:=MAP[Head.y,Head.x].Code;
     if The=Blank then exit;      { пусто - выходим ... }
     if The<4 then begin RunCutting;exit end;       { режем чей-то хвост }
     if The<8 then begin YMove:=false;exit end;
     case The of
     8:YMove:=false;
     9:exit;
     10:begin
             Condition:=Frozen;Timer:=FreezeTime;
             MoreBeings(Head,2,Random(9))
     end;
     11:inc(extLen,3);
     12:inc(Lives);
     13:begin Condition:=GOD;Timer:=GodTime end;
     14:begin Condition:=Frozen;Timer:=FreezeTime end;
     15:dec(extLen);
     16:dec(extLen,2);
     17:dec(extLen,5)
     else            { наткнулись на движущийся объект? }
     begin
          FindBeing(Head,Be);
          if Be=NIL then exit;  { Ве не должен быть равен нулю }
          case Be^.Kind of
          0:exit;
          13,14:begin
                     KeyPicked:=true;
                     Score:=Score+50
          end;
          12,11:begin YMove:=false;exit end;    { блоки движущиеся }
          10:begin Condition:=Frozen;Timer:=FreezeTime end
          else { Kind = 1..9 }
          begin
               Score:=Score+BonScore[Be^.Kind];
               extLen:=extLen+BonLen[Be^.Kind];
               YAte:=true;
               if Condition<>GOD then Timer:=HungryTime     { питон насытился }
          end
          end {case Be^.Kind};
          New(Be);
          DelThisOne(Head,Be);
          Dispose(Be)
     end {case else}
     end {case The}
end{Piton.Check};

procedure Piton.RunCutting;
var Spot,St:Pixel;
    T:PPiTail;
    Spd,TailLen:word;
    N:integer;
begin
    { if (GameType=CLASSIC) or (GameType=BOAS) then begin}
        YMove:=false;exit;{ end;}
     Spot:=Head;
     IfIsTail(Spot,T);
     if T<>NIL then begin
        with T^ do
             if (Beg.y=Fin.y) and (Beg.x=Fin.x) then Dispose(T,Remove)
             else PrevCoor(Fin,MAP[Fin.y,Fin.x].Code);
        exit
     end;
     FindPiTail(Spot,T);
     if T<>NIL then begin
        with T^ do
             if (Spot.x=Beg.x) and (Spot.y=Beg.y)
                then NextCoor(Beg,MAP[Beg.y,Beg.x].Code)
             else begin
                  St:=Spot;NextCoor(St,MAP[St.y,St.x].Code);
                  Spd:=Speed;
                  CreatePiTail(St,Fin,Spd);
                  PrevCoor(Spot,MAP[Spot.y,Spot.x].Code);
                  Fin:=Spot
             end {else};
        exit
     end;
     { значит, это тело питона }
     N:=FindPythonHead(Spot);
     if N=0 then exit; { N вообще-то не должен бы быть равен нулю, но... }
     if Boa[N].Condition=GOD then begin YMove:=false;exit end;
     if (Spot.x=Boa[N].Tail.x) and (Spot.y=Boa[N].Tail.y) then begin
        dec(Boa[N].Len);NextCoor(Boa[N].Tail,MAP[Spot.y,Spot.x].Code);
        inc(Score);exit
     end;
     TailLen:=1;St:=Boa[N].Tail;
     while (St.x<>Spot.x) and (St.y<>Spot.y) do begin
           inc(TailLen);NextCoor(St,MAP[St.y,St.x].Code) end;
     Boa[N].Len:=Boa[N].Len-TailLen;
     PrevCoor(St,MAP[St.y,St.x].Code);
     CreatePiTail(Boa[N].Tail,St,Boa[N].Speed);
     NextCoor(Spot,MAP[Spot.y,Spot.x].Code);
     Boa[N].Tail:=Spot;
     Score:=Score+TailLen
end {Piton.RunCutting};

constructor PiTail.Init;begin end;
destructor PiTail.Remove;     { удаление хвоста из списка }
begin
     if Next=NIL then LastTail:=Prev else Next^.Prev:=Prev;
     if Prev<>NIL then Prev^.Next:=Next
end;
procedure PiTail.Move;
var Sym:Symbol;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     xSpeed:=Speed;
     Sym:=MAP[Beg.y,Beg.x];
     MAP[Beg.y,Beg.x].Code:=Blank;
     if (Beg.y=Fin.y) and (Beg.x=Fin.x) then Done:=true
     else NextCoor(Beg,Sym.Code)
end;
procedure CreatePitail(St,En:Pixel;Spd:word);
var T:PPiTail;
begin
     New(T);if LastTail = NIL then
     begin
          LastTail:=T;T^.Prev:=NIL;T^.Next:=NIL
     end else
     begin
          LastTail^.Next:=T;
          T^.Next:=NIL;
          T^.Prev:=LastTail;
          LastTail:=T
     end;
     T^.Beg:=St;T^.Fin:=En;T^.Speed:=Spd;T^.xSpeed:=Spd;
     T^.Done:=false
end;
procedure IfIsTail(LOC:Pixel;var T:PPiTail);
begin
     T:=LastTail;
     while T<>NIL do
           if (T^.Fin.x=LOC.x) and (T^.Fin.y=LOC.y) then exit
           else T:=T^.Prev
end;
procedure FindPiTail(LOC:Pixel;var T:PPiTail);
begin
     while MAP[LOC.y,LOC.x].Code<4 do begin
           T:=LastTail;
           while T<>NIL do
                 if (T^.Beg.y=LOC.y) and (T^.Beg.x=LOC.x) then exit
                 else T:=T^.Prev;
           PrevCoor(LOC,MAP[LOC.y,LOC.x].Code)
     end
end;
Function FindPythonHead(LOC:Pixel):integer;
var i:integer;
begin
     while MAP[LOC.y,LOC.x].Code<4 do NextCoor(LOC,MAP[LOC.y,LOC.x].Code);
     for i:=1 to MaxPiton do
         if (Boa[i].Condition<>EMPTY) and (LOC.x=Boa[i].Head.x) and
         (LOC.y=Boa[i].Head.y) then begin FindPythonHead:=i;exit end;
     FindPythonHead:=0
end;
procedure CreateBeing(LOC:Pixel;Kind:word);
var       B:PBeing;
begin
     if MaxAvail<sizeof(Being) then exit;
     New(B,Create(LOC,Kind));
     case Kind of
     1:inc(Flies);
     2:inc(Rabs);
     3:inc(Frogs);
     4:inc(Men)
     end{case}
end;

{ удалим объект, но не из памяти и списка, а просто ... }
procedure DelThisOne(Spot:Pixel;B:PBeing); { B нужна, чтобы объект не удалил сам себя }
var PB:PBeing;
begin
     PB:=LastBeing;
     while PB<>NIL do
           if (PB^.Prev<>B) and (PB^.LOC.x=Spot.x) and (PB^.LOC.y=Spot.y) then
           begin
                case PB^.Kind of
                1:begin
                       if QntFly>0 then dec(QntFly);
                       dec(Flies)
                  end;
                2:begin
                       if QntRab>0 then dec(QntRab);
                       dec(Rabs)
                  end;
                3:begin
                       if QntFrog>0 then dec(QntFrog);
                       dec(Frogs)
                  end;
                4:begin
                       if QntMan>0 then dec(QntMan);
                       dec(Men)
                  end
                end;
                PB^.Kind:=0;
                exit
           end
           else PB:=PB^.Prev
end;
procedure MoreBeings(Spot:Pixel;Kind:word;Numb:word);
{ порождаем Numb объектов Kind вокруг Spot }
var i,Time:integer;NewSpot:Pixel;
begin
     for Time:=1 to 10 do
         for i:=0 to 7 do begin
             if Numb=0 then exit;       { все...}
             if Random(10)<7 then begin
                NewSpot:=Spot;
                NewCoor(NewSpot,i);
                if CorCoor(NewSpot) then begin CreateBeing(NewSpot,Kind);
                   dec(Numb) end{if}
             end {if}
         end{for}
end;



constructor Being.Create(Pos:Pixel;K:word);
const Speeds:array [1..14] of word =
       (3,7,4,2,18*5,18*4,18*3,18*2,18*1,18*8,4,4,10,11);
      VIDS:array[1..14]of Symbol = (
      (Code:Fly1;Attr:18),(Code:Rab1;Attr:20),(Code:Frog1;Attr:22),
      (Code:Man1;Attr:24),(Code:Seed1;Attr:26),(Code:273;Attr:26),
      (Code:274;Attr:26),(Code:275;Attr:26),(Code:276;Attr:26),
      (Code:277;Attr:28),(Code:Block1;Attr:30),(Code:Block2;Attr:30),
      (Code:Key1;Attr:32),(Code:Key2;Attr:32));
begin
    Prev:=LastBeing;
    Next:=NIL;
    if LastBeing<>NIL then LastBeing^.Next:=@Self; {  след. элемент в списке }
    LastBeing:=@Self; { добавим в список }
    LOC:=Pos;
    VID.Code:=VIDS[K].Code;
    VID.Attr:=VIDS[K].Attr+Random(2);
    Kind:=K;
    Speed:=Speeds[K]+Random(5);
    xSpeed:=Speed;
    Timer:=0;Stamina:=0;Dir:=Random(4);
    if K=11 then Dir:=2 else if K=12 then Dir:=1;
    MAP[LOC.y,LOC.x]:=VID                   { нарисуем на карте объект }
end;

destructor Being.ReMove;     { удаляет объект из списка }
begin
     if Next = NIL then LastBeing:=Prev else Next^.Prev:=Prev;
     if Prev<> NIL then Prev^.Next:=Next
end;
procedure Being.Move;
begin
     case Kind of
     1:MoveFly;
     2:MoveRab;
     3:MoveFrog;
     4:MoveMan;
     5..10:MoveSeed;
     11,12:MoveBlock;
     13,14:MoveKey
     end
end;
procedure Being.MoveBlock;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     xSpeed:=Speed;
     MAP[LOC.y,LOC.x].Code:=Blank;
     NextCoor(LOC,Dir);
     if not(CorCoor(LOC)) then begin PrevCoor(LOC,Dir);BackDir(Dir) end;
     MAP[LOC.y,LOC.x]:=VID
end;
procedure Being.MoveKey;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     xSpeed:=Speed;
     case Kind of
     13:begin inc(Kind);MAP[LOC.y,LOC.x].Code:=Key2;MAP[LOC.y,LOC.x].Attr:=32 end;
     14:begin dec(Kind);MAP[LOC.y,LOC.x].Code:=Key1;MAP[LOC.y,LOC.x].Attr:=33 end;
     end
end;
procedure Being.MoveSeed;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     xSpeed:=Speed+Random(18*3);
     inc(Kind);
     if Kind>10 then begin { зерно умирает }
                     Kind:=0;MAP[LOC.y,LOC.x].Code:=Blank; exit end;
     inc(MAP[LOC.y,LOC.x].Code);
     if Kind = 10 then begin
        MAP[LOC.y,LOC.x].Attr:=28+Random(2);
        MoreBeings(LOC,5,Random(8)+1)        { выбросим семена }
     end
end;


procedure FindNearestTail(var Spot:Pixel);  { ищет ближайший к мухе хвост }
var TSpot:Pixel;D,Dist,N:integer;
begin
     Dist:=10000;TSpot:=Spot;
     for N:=1 to MaxPiton do
         if (Boa[N].Condition<>EMPTY) then begin
            D:=Distance(Boa[N].Tail,TSpot);
            if D<Dist then begin
               Dist:=D;Spot:=Boa[N].Tail
            end
         end
end;
function WhichPitonTail(LOC:Pixel):word;        { чей же хвот? }
var N:integer;
begin
     for N:=1 to MaxPiton do
         if (Boa[N].Condition<>EMPTY) and
         (Boa[N].Tail.x=LOC.x) and (Boa[N].Tail.y=LOC.y) then begin
             WhichPitonTail:=N;exit end;
     WhichPitonTail:=0
end;

procedure Being.MoveFly;        { движение мухи }
var       NewSpot:Pixel;
          N:word;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end else xSpeed:=Speed;
     NPic:=(NPic+1) and 3;
     NewSpot:=LOC;
     FindNearestTail(NewSpot);
     with NewSpot do
          if (x<LOC.x) and (y<LOC.y) then Dir:=3 else
          if (x>LOC.x) and (y<LOC.y) then Dir:=0 else
          if (x>LOC.x) and (y>LOC.y) then Dir:=1 else
          if (x<LOC.x) and (y>LOC.y) then Dir:=2;
     if Random(100)>80 then Dir:=Random(4);
     MAP[LOC.y,LOC.x]:=SPACE;NextEnhCoor(LOC,Dir);
     if MAP[LOC.y,LOC.x].Code<4 then begin { наткнулись на хвост }
        N:=WhichPitonTail(LOC);
        if (N>0) and (Boa[N].Condition<>GOD) then begin
           dec(Boa[N].Len);NextCoor(Boa[N].Tail,MAP[LOC.y,LOC.x].Code)
        end else PrevEnhCoor(LOC,Dir) { это не кончик хвоста }
     end else if not(CorCoor(LOC)) then PrevEnhCoor(LOC,Dir);
     MAP[Loc.y,LOC.x].Code:=Fly1+NPic;
     MAP[LOC.y,LOC.x].Attr:=VID.Attr
end {MoveFly};



procedure Being.MoveRab;

procedure FindNearestSeed(var Spot:Pixel);
var       D,Dist:integer;Plot:Pixel;B:PBeing;
begin
     Dist:=3000;Plot:=Spot;
     B:=LastBeing;
     while B<>NIL do begin
           if (B^.Kind>4) and (B^.Kind<10) then begin
              D:=Distance(Plot,B^.LOC);
              if D<Dist then begin
                 Dist:=D;Spot:=B^.LOC
              end
           end;
           B:=B^.Prev
     end
end;

procedure Moving;       { движем кролика }
var C:word;
begin
          if xSpeed>0 then begin dec(xSpeed);exit end;
          xSpeed:=Speed;
          NPic:=(NPic+1) and 3;
          MAP[LOC.y,LOC.x].Code:=Blank;
          NextCoor(LOC,Dir);
          C:=MAP[LOC.y,LOc.x].Code;
          if (C>271) and (C<277) then DelThisOne(LOC,Prev)   { съели семя }
          else if C<>Blank then begin PrevCoor(LOC,Dir);
                                      Dir:=(Dir+sgn(Random(10)-5)) and 3
          end;
          MAP[LOC.y,LOC.x].Code:=Rab1+NPic;
          MAP[LOC.y,LOC.x].Attr:=VID.Attr;
          if Stamina<16 then inc(Stamina)
end {Moving};
procedure Stopping;
var S:Pixel;i:integer;C:word;
begin
     S:=LOC;i:=3; { смотрим вперед }
     while i>0 do begin
           NextCoor(S,Dir);C:=MAP[LOC.y,LOC.x].Code;
           if C<8 then begin { кролик увидел питона }
              Stamina:=0;BackDir(Dir);exit
           end;
           dec(i)
     end {while};
     if Random(100)>20 then exit;
     S:=LOC;
     FindNearestSeed(S);
     with LOC do
          if Random(10)<6 then begin
             if x<S.x then Dir:=1 else Dir:=3 end
          else begin
              if y<S.y then Dir:=2 else Dir:=0 end;
     Stamina:=10
end {Stopping};
begin
     if Stamina>15 then Stopping else
     begin
          if Random(100)>85 then Dir:=(Dir+SGN(Random(10)-5)) and 3;
          Moving
     end
end {Being.MoveRab};

procedure Being.MoveFrog;       { перемещаем лягушку }
procedure TryToHop;
begin
     NPic:=(NPic+1) and 3;
     xSpeed:=Speed;
     if Random(100)<75 then exit;
     Dir:=Random(4);
     MAP[LOC.y,LOC.x].Code:=Blank;
     NextCoor(LOC,Dir);NextCoor(LOC,Dir);
     if not(CorCoor(LOC)) then begin PrevCoor(LOC,Dir);PrevCoor(LOC,Dir) end;
     MAP[LOC.y,LOC.x].Code:=Frog1+NPic;
     MAP[LOC.y,LOC.x].Attr:=VID.Attr
end;
procedure HopForFly;    { лягушка ловит муху, если она рядом }
var Spot:Pixel;C:word;D:word;
begin
     for D:=0 to 3 do begin
         Spot:=LOC;
         NextCoor(Spot,D);NextCoor(Spot,D);
         C:=MAP[Spot.y,Spot.x].Code;
         if (C>255) and (C<260) then begin
            MAP[Loc.y,LOC.x].Code:=Blank;
            LOC:=Spot;MAP[LOC.y,LOC.x].Code:=VID.Code;
            MAP[LOC.y,LOC.x].Attr:=VID.Attr;
            xSpeed:=Speed;DelThisOne(LOC,Prev);exit
         end
     end
end;
begin
     HopForFly;
     if xSpeed>0 then dec(xSpeed) else TryToHop
end;


procedure Being.MoveMan;        { перемещение человечка }
procedure SelectDir;
begin
     if Stamina=0 then Dir:=Random(4) else
     with Game do
          if Random(100)<50 then begin
             if x<LOC.x then Dir:=3 else Dir:=1 end
             else begin if y<LOC.y then Dir:=0 else Dir:=2 end
end{SelectDir};

procedure Moving;
var C:word;
begin
     if xSpeed>0 then begin dec(xSpeed);exit end;
     SelectDir;       { выберем направление }
     xSpeed:=Speed;NPic:=(NPic+1) and 3;
     MAP[LOC.y,LOC.x].Code:=Blank;
     NextCoor(LOC,Dir);C:=MAP[LOC.y,LOC.x].Code;
     if (c>=Rab1) and (C<Rab1+4) then DelThisOne(LOC,Prev)
     else if C<>Blank then PrevCoor(LOC,Dir);
     MAP[LOC.y,LOC.x].Code:=Man1+NPic;
     MAP[LOC.y,LOC.x].Attr:=VID.Attr
end;
procedure FindNearestRabbit(var Spot:Pixel);    { ищем кролика ближнего }
var Dist,D:integer;Plot:Pixel;B:PBeing;
begin
     Dist:=30000;Plot:=Spot;
     B:=LastBeing;
     while B<>NIL do begin
           if B^.Kind=2 then begin
              D:=Distance(Plot,B^.LOC);
              if D<Dist then begin
                 Dist:=D;Spot:=B^.LOC
              end
           end;
           B:=B^.Prev
     end
end;
begin
     case Stamina of
     0:if Random(100)>75 then begin
            Game:=LOC;FindNearestRabbit(Game);Stamina:=12
       end;
     12:if (Random(100)<15) or ((LOC.x=Game.x) and (LOC.y=Game.y))
           then Stamina:=0
     end{case};
     Moving
end {Being.MoveMan};

procedure SummonBeing(Kind:word;N:word);        { породить объекты питона }
var A:Pixel;T:Longword;
begin
     T:=WhatTime+2*TimeZoom;
     while N>0 do begin
           if WhatTime>=T then exit; { защита от вечного цикла }
           A.x:=Random(32)+1;
           A.y:=Random(25)+1;
           if CorCoor(A) then
           begin
                dec(N);
                CreateBeing(A,Kind)
           end
     end
end;
procedure SummonThing(VID:Symbol;N:word);       { породить вещи в карте }
var A:Pixel;T:Longword;
begin
     T:=WhatTime+2*TimeZoom;
     while N>0 do begin
           if WhatTime>=T then exit;     { защита от зацикливания }
           A.x:=Random(32)+1;
           A.y:=Random(25)+1;
           if CorCoor(A) then
           begin
                dec(N);MAP[A.y,A.x]:=VID
           end
     end
end;
procedure FindBeing(C:Pixel;var Be:PBeing);
begin
     Be:=LastBeing;
     while Be<>NIL do
           if (C.x=Be^.LOC.x) and (C.y=Be^.LOC.y) then exit
           else Be:=Be^.Prev
end;
procedure ClearObjects; { очищает все объекты игры в начале каждого уровня }
var Pt,DPt:PPiTail;
    B,DB:PBeing;
    i:word;
begin
     for i:=3 to MaxPiton do Boa[i].Condition:=EMPTY;
     Pt:=LastTail;
     while Pt<>NIL do begin
           DPt:=Pt;Pt:=Pt^.Prev;Dispose(DPt)
     end;
     LastTail:=NIL;
     B:=LastBeing;
     while B<>NIL do begin
           DB:=B;B:=B^.Prev;Dispose(DB)
     end;
     LastBeing:=NIL;
     { число всех жителей обнулим }
     Flies:=0;
     Rabs:=0;
     Frogs:=0;
     Men:=0
end;

end.
