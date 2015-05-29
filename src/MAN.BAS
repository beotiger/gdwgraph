DECLARE SUB PutMessage ()
DECLARE SUB CountSpeed ()
DECLARE SUB Game ()
DECLARE SUB LoadTable ()
DECLARE SUB BossAI (B%)
DECLARE SUB DirectaMan (N%)
DECLARE FUNCTION FreeNumber% ()
DECLARE FUNCTION WhichNumber% (x%, y%, N%)
DECLARE SUB ManAI (N%)
DECLARE SUB WeaponFly (N%)
DECLARE FUNCTION WhichBoss% (x%, y%)
DECLARE SUB KeyBoard ()
DECLARE SUB AI ()
DECLARE SUB Move ()
DECLARE SUB ResetBoss (B%)
DECLARE SUB EdenCapWell ()
DECLARE SUB WriteBoard ()
DECLARE SUB GameOver ()
DECLARE SUB PutBoss (x%, y%, CODE%, ATTR%)
DECLARE SUB PutOrSymbol (x%, y%, CODE%, ATTR%)
DECLARE SUB SetBoss (x%, y%, CODE%, ATTR%)
DECLARE FUNCTION ReadKey% ()
DECLARE SUB MoveObject (N%)
DECLARE SUB MoveBoss (B%)
DECLARE SUB PutBigSymbol (x%, y%, CODE%, ATTR%, Wid%, Height%)
DECLARE SUB PutSymbol (x%, y%, CODE%, ATTR%)
DECLARE SUB PutAllSymbol (x%, y%, CODE%, ATTR%)
DECLARE FUNCTION ExistFile% (FileName$)
DECLARE SUB RestoreScreen (xl%, yu%, xr%, yd%)
DECLARE SUB Ramka (xl%, yu%, xr%, yd%)
DECLARE SUB SaveScreen (xUp%, yUp%, xDwn%, yDwn%)
DECLARE SUB RepeatSymbol (x%, y%, CODE%, ATTR%, number%)
DEFINT A-Z

DECLARE SUB GetReady ()
DECLARE SUB OpenScreen ()
DECLARE SUB MainMenu ()
DECLARE SUB FirstInit ()
DECLARE SUB OpenLevel ()
DECLARE SUB ReadLevel ()
DECLARE SUB OutPutLevel (N$)
DEFINT A-Z
OPTION BASE 1
'CLEAR , &H7000
CONST BLACK = 0, BLUE = 1, GREEN = 2, CYAN = 3, RED = 4
CONST MAGENTA = 5, BROWN = 6, WHITE = 7
CONST GREY = 8, lightblue = 9, LIGHTGREEN = 10, lightcyan = 11, LIGHTRED = 12
CONST LIGHTMAGENTA = 13, YELLOW = 14, LIGHTWHITE = 15


CONST SKULL = 128, WEAPON = 129, TEN = 130, APPLE = 131, CROSS = 132
CONST TREE = 133, HEART = 134, BRICK = 135
CONST STAIR = 136, TREASURE = 166, MAN = 144, MANR = 146
CONST MANL = 149, MANUD = 141
CONST UpLine = 171, EMPTY = 178, STAR = 179

CONST LTOOTHED = 215, SKELETON = 235, GIANT = 223, coBOSS = 215
CONST MaxThing = 50

TYPE SYMBOL
 CODE AS INTEGER
 ATTR AS INTEGER
END TYPE

COMMON SHARED FIRE, SCROLL, UP, LEFT, RIGHT, DOWN, ESC, SPACE
COMMON SHARED Level, NextLevel, PlayerDeath, P1, P2, Cycles
COMMON SHARED KeyP1, KeyP2, SECOND
DIM SHARED WP1(3), WP2(3), MU(4), MF(2)

TYPE Object
 x AS INTEGER
 y AS INTEGER
 xOld AS INTEGER
 yOld AS INTEGER
 VID AS SYMBOL
 pVID AS SYMBOL
 HP AS INTEGER
 GUN AS INTEGER
 SPD AS INTEGER
 STEPS AS INTEGER
 FLSTEPS AS INTEGER
 the AS INTEGER
 CODE AS INTEGER
 dirx AS INTEGER
 diry AS INTEGER
 charge AS INTEGER
 behave AS INTEGER
 stamina AS INTEGER
END TYPE

DIM SHARED thing(1 TO MaxThing) AS Object
DIM SHARED MAP(1 TO 20, 1 TO 40) AS SYMBOL
TYPE OBOSS
 x AS INTEGER
 y AS INTEGER
 xOld AS INTEGER
 yOld AS INTEGER
 HP AS INTEGER
 VID AS SYMBOL
 pVID1 AS SYMBOL
 pVID2 AS SYMBOL
 pVID3 AS SYMBOL
 pVID4 AS SYMBOL
 dirx AS INTEGER
 diry AS INTEGER
 CODE AS INTEGER
 charge AS INTEGER
 behave AS INTEGER
END TYPE
DIM SHARED tBOSS(1 TO 5) AS OBOSS, EYE(20)
COMMON SHARED NOTHING  AS SYMBOL
REDIM SHARED EKR(1 TO 1) AS SYMBOL


NOTHING.CODE = EMPTY: NOTHING.ATTR = 7
ESC = 1
MU(1) = 141: MU(2) = 143: MU(3) = 144: MU(4) = 145
MF(1) = 143: MF(2) = 145
UP = 72: DOWN = 80: LEFT = 75: RIGHT = 77
FIRE = 57: SPACE = 57: SCROLL = 28


CALL PutMessage
CALL CountSpeed
SCREEN 13
CALL LoadTable
CALL Game

SUB AI
 FOR i = 1 TO MaxThing
  IF thing(i).CODE = 1 THEN
   CALL ManAI(i)
   CALL DirectaMan(i)
  ELSEIF thing(i).CODE = 2 THEN
   CALL WeaponFly(i)
  END IF
 NEXT
 FOR i = 1 TO 5
  IF tBOSS(i).CODE > 0 THEN CALL BossAI(i)
 NEXT
END SUB

SUB BossAI (B)
 NextLevel = 10
 SELECT CASE tBOSS(B).CODE
 CASE 1: 'LTOOTHED
  IF tBOSS(B).HP <= 0 THEN
   CALL ResetBoss(B)
   IF tBOSS(B).x > 1 THEN x = tBOSS(B).x - 1 ELSE x = 1
   IF x + 3 > 40 THEN x = 37
   tBOSS(B).CODE = 0
   IF MAP(tBOSS(B).y + 1, x).CODE = EMPTY THEN CALL PutSymbol(x, tBOSS(B).y + 1, SKULL, 7)
   FOR i = x + 1 TO x + 3
    IF MAP(tBOSS(B).y + 1, i).CODE = EMPTY AND RND(1) < .67 THEN
     CALL PutSymbol(i, tBOSS(B).y + 1, HEART, 37)
     MAP(tBOSS(B).y + 1, i).CODE = HEART
    END IF
   NEXT
   EXIT SUB
  END IF 'HPPPPP
  IF (Cycles AND 1) = 0 THEN EXIT SUB
  SELECT CASE tBOSS(B).behave
  CASE 1:
   IF tBOSS(B).x = 1 THEN tBOSS(B).behave = 2: EXIT SUB
   IF MAP(tBOSS(B).y, tBOSS(B).x - 1).CODE = BRICK OR MAP(tBOSS(B).y + 1, tBOSS(B).x - 1).CODE = BRICK OR MAP(tBOSS(B).y + 2, tBOSS(B).x - 1).CODE = EMPTY THEN
    tBOSS(B).behave = 2: EXIT SUB
   END IF
   tBOSS(B).x = tBOSS(B).x - 1
   tBOSS(B).VID.CODE = LTOOTHED + 4
  CASE 2:
   IF tBOSS(B).x = 39 THEN tBOSS(B).behave = 1: EXIT SUB
   IF MAP(tBOSS(B).y, tBOSS(B).x + 2).CODE = BRICK OR MAP(tBOSS(B).y + 1, tBOSS(B).x + 2).CODE = BRICK OR MAP(tBOSS(B).y + 2, tBOSS(B).x + 2).CODE = EMPTY THEN
    tBOSS(B).behave = 1: EXIT SUB
   END IF
   tBOSS(B).x = tBOSS(B).x + 1
   tBOSS(B).VID.CODE = LTOOTHED
   END SELECT
  CASE ELSE: 'other BOSS
  END SELECT
END SUB

SUB CloseWindow (lx, uy, rx, dy)
 CALL RestoreScreen(lx, uy, rx, dy)
END SUB

SUB CountSpeed
 B! = TIMER + 1: C! = 0
 WHILE C! < B!: C! = TIMER: WEND
 B! = TIMER + 1
 WHILE C! < B!: C! = TIMER: SECOND = SECOND + 1: WEND
 PRINT SECOND
END SUB

SUB CreateWindow (lx, uy, rx, dy)
 CALL SaveScreen(lx, uy, rx, dy)
 CALL Ramka(lx, uy, rx, dy)
END SUB

SUB DirectaMan (N)
 IF thing(N).VID.ATTR <> 15 AND (Cycles AND 1) = 0 THEN EXIT SUB

 SELECT CASE thing(N).behave
  CASE 0: thing(N).VID.CODE = 144
  CASE 1: thing(N).VID.CODE = (Cycles MOD 3) + 149
   IF thing(N).x = 1 THEN EXIT SUB
   IF MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN thing(N).x = thing(N).x - 1
  CASE 2: thing(N).VID.CODE = (Cycles MOD 3) + 146
   IF thing(N).x = 40 THEN EXIT SUB
   IF MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN thing(N).x = thing(N).x + 1
  CASE 3: thing(N).VID.CODE = MU((Cycles AND 3) + 1)
   IF thing(N).y = 1 THEN EXIT SUB
   IF MAP(thing(N).y - 1, thing(N).x).CODE <> BRICK AND thing(N).pVID.CODE = STAIR THEN thing(N).y = thing(N).y - 1
  CASE 4: thing(N).VID.CODE = MU((Cycles AND 3) + 1)
   IF thing(N).y = 20 THEN EXIT SUB
   IF MAP(thing(N).y + 1, thing(N).x).CODE <> BRICK THEN thing(N).y = thing(N).y + 1
  CASE 5:
    thing(N).VID.CODE = 140: DIR = -1: GOSUB FillWeapon
  CASE 6:
    thing(N).VID.CODE = 142: DIR = 1: GOSUB FillWeapon
  CASE 7:
   thing(N).FLSTEPS = thing(N).FLSTEPS + 1
   IF thing(N).FLSTEPS < 6 THEN
    thing(N).VID.CODE = MF((Cycles AND 1) + 1)
   ELSE
    thing(N).VID.CODE = 164
   END IF
   thing(N).y = thing(N).y + 1
  CASE 8:
   IF thing(N).VID.ATTR <> 15 AND thing(N).VID.ATTR <> 14 THEN
    thing(N).VID.CODE = SKULL
   ELSE
    thing(N).VID.CODE = 157
   END IF
  END SELECT
 EXIT SUB
FillWeapon:
 NW = FreeNumber
 IF NW = 0 THEN RETURN
 thing(NW).GUN = thing(N).GUN
 thing(NW).x = thing(N).x + DIR
 thing(NW).y = thing(N).y
 thing(NW).xOld = thing(N).x + DIR
 thing(NW).yOld = thing(N).y
 thing(NW).dirx = DIR
 thing(NW).CODE = 2
 SELECT CASE thing(NW).GUN
 CASE 1:
  thing(NW).HP = 1: thing(NW).SPD = 5
  IF DIR < 0 THEN thing(NW).VID.CODE = 137 ELSE thing(NW).VID.CODE = 153
 CASE 2:
  thing(NW).HP = 2: thing(NW).SPD = 3
  IF DIR < 0 THEN thing(NW).VID.CODE = 152 ELSE thing(NW).VID.CODE = 156
 CASE 3:
  thing(NW).HP = 5: thing(NW).SPD = 2
  IF DIR < 0 THEN thing(NW).VID.CODE = 138 ELSE thing(NW).VID.CODE = 154
 CASE 4:
  thing(NW).HP = 3: thing(NW).SPD = 3
  IF DIR < 0 THEN thing(NW).VID.CODE = 139 ELSE thing(NW).VID.CODE = 155
 END SELECT
 thing(NW).VID.ATTR = 7
 thing(NW).pVID = MAP(thing(NW).y, thing(NW).x)
 thing(N).charge = 3
 RETURN
END SUB

SUB EdenCapWell
 FOR i = 1 TO 3
  IF WP1(i) > 99 THEN WP1(i) = 99
 NEXT
 Cycles = Cycles + 1
 PlayerDeath = PlayerDeath - 1: NextLevel = NextLevel - 1
 FOR i = 1 TO SECOND * 8: NEXT
END SUB

FUNCTION ExistFile (FileName$)
 DEF SEG = &H8000
 Byte = &HC2
 FOR i = 0 TO LEN(FileName$) - 1
  POKE Byte + i, ASC(MID$(FileName$, i + 1, 1))
 NEXT
 POKE Byte + i, 0
 CALL absolute(&H8B)
 ExistFile = PEEK(&HC1)
 DEF SEG
END FUNCTION

SUB FirstInit
 IF Level = 0 THEN Level = 1
 FOR i = 2 TO 3: WP1(i) = 0: WP2(i) = 0: NEXT
 WP1(1) = 6: WP2(1) = 6
END SUB

FUNCTION FreeNumber
 FOR i = 1 TO MaxThing
  IF thing(i).CODE = 0 THEN FreeNumber = i: EXIT FUNCTION
 NEXT
 FreeNumber = 0
END FUNCTION

SUB Game
 DO
  CALL OpenScreen
  CALL MainMenu
  CALL FirstInit
 DO
  CALL OpenLevel
  CALL ReadLevel
  CALL GetReady
 DO
  CALL KeyBoard
  CALL AI
  CALL Move
  CALL EdenCapWell
  CALL WriteBoard
 LOOP UNTIL NextLevel = 0 OR PlayerDeath = 0
 IF NextLevel = 0 THEN
   Level = Level + 1: LOCATE 23, 18: COLOR 15: PRINT USING "##"; Level;
 END IF
 LOOP WHILE NextLevel = 0
 CALL GameOver
LOOP
END SUB

SUB GameOver
 CALL Ramka(15, 9, 25, 11)
 LOCATE 10, 16: COLOR 15: PRINT "GAME OVER"
 DO: A = ReadKey: LOOP WHILE A = 0
END SUB

SUB GetReady
  j = 10
 DO
  IF P1 > 0 THEN CALL PutSymbol(thing(P1).x, thing(P1).y, EMPTY, 7)
  IF P2 > 0 THEN CALL PutSymbol(thing(P2).x, thing(P2).y, EMPTY, 7)
  FOR i = 1 TO SECOND * 3: NEXT
  IF P1 > 0 THEN CALL PutSymbol(thing(P1).x, thing(P1).y, MAN, 15)
  IF P2 > 0 THEN CALL PutSymbol(thing(P2).x, thing(P2).y, MAN, 14)
  FOR i = 1 TO SECOND * 5: NEXT
  j = j - 1
 LOOP UNTIL j = 0
END SUB

SUB KeyBoard
 KeyP1 = ReadKey
END SUB

DEFSNG A-Z
SUB LoadTable
 DEF SEG = &H7000
 BLOAD "SIM.DAT", 0
 DEF SEG = &H8000
 BLOAD "man.lib", 0
 DEF SEG
END SUB

DEFINT A-Z
SUB MainMenu
 CALL PutBigSymbol(4, 10, SKULL, 15, 4, 4)
 DO
  CALL PutBigSymbol(28, 8, i + 146, 54, 4, 7)
  FOR j = 1 TO SECOND * 5: NEXT
  i = i + 1: IF i > 2 THEN i = 0
  A = ReadKey
  IF A = ESC THEN
   SCREEN 0, 0: WIDTH 80: COLOR 15, 0
   LOCATE 24, 1: END
  END IF
 LOOP WHILE A <> SPACE
END SUB

SUB ManAI (N)
 IF thing(N).behave = 8 THEN EXIT SUB
 IF thing(N).HP <= 0 THEN thing(N).behave = 8: EXIT SUB
 IF thing(N).charge > 0 THEN thing(N).charge = thing(N).charge - 1
 IF thing(N).VID.ATTR = 15 OR thing(N).VID.ATTR = 14 THEN GOSUB PickIt
 IF thing(N).y < 20 THEN
    IF thing(N).pVID.CODE <> STAIR AND MAP(thing(N).y + 1, thing(N).x).CODE = EMPTY THEN
     IF thing(N).VID.ATTR = 15 THEN PlayerDeath = RND(1) * 50 + 8 ELSE NextLevel = 12
     thing(N).behave = 7: EXIT SUB
 END IF
 END IF
 IF thing(N).behave = 7 THEN
  IF thing(N).FLSTEPS < 6 THEN thing(N).behave = 0 ELSE thing(N).behave = 8
  thing(N).FLSTEPS = 0: EXIT SUB
 END IF
 IF thing(N).VID.ATTR = 15 OR thing(N).VID.ATTR = 14 THEN GOTO YouMan
 NextLevel = 12
 IF thing(N).pVID.CODE = SKULL THEN
  L = WhichNumber(thing(N).x, thing(N).y, N)
  IF RND(1) > .65 AND L > 0 THEN 'take SKULL
   thing(L).CODE = 0
   thing(N).pVID = thing(L).pVID
  END IF
 END IF
' IF thing(N).pVID.CODE >= coBOSS THEN thing(N).behave = 8: EXIT SUB
 IF (Cycles AND 1) = 0 THEN EXIT SUB
 SELECT CASE thing(N).behave
 CASE 0:
  thing(N).stamina = 128
  IF thing(N).x = 1 THEN thing(N).behave = 2: EXIT SUB
  IF thing(N).x = 40 THEN thing(N).behave = 1: EXIT SUB
  IF thing(N).y = 20 THEN
       IF thing(N).pVID.CODE = STAIR THEN thing(N).behave = 3: EXIT SUB
       IF MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN thing(N).behave = 1: EXIT SUB
       IF MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN thing(N).behave = 2: EXIT SUB
       EXIT SUB
  END IF
  IF thing(N).x > thing(P1).x AND MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN
   thing(N).behave = 1: EXIT SUB
  END IF
  IF thing(N).x < thing(P1).x AND MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN
   thing(N).behave = 2: EXIT SUB
  END IF
  IF thing(N).y < thing(P1).y AND MAP(thing(N).y + 1, thing(N).x).CODE <> BRICK THEN
   thing(N).behave = 4: EXIT SUB
  END IF
  IF thing(N).x > 1 AND MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN
   thing(N).behave = 1: EXIT SUB
  END IF
  IF thing(N).x < 40 AND MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN
   thing(N).behave = 1: EXIT SUB
  END IF
  IF thing(N).y < 20 AND MAP(thing(N).y + 1, thing(N).x).CODE = STAIR THEN
   thing(N).behave = 4: EXIT SUB
  END IF
  EXIT SUB
  CASE 1:
   IF EYE(thing(N).y) = 2 THEN
    thing(N).stamina = 0
    thing(N).behave = 2
   END IF
   GOSUB iStairs
   IF Stairs > 0 THEN
    IF thing(N).stamina <= 32 THEN
     thing(N).stamina = 128
     IF (Stairs AND 1) > 0 THEN thing(N).behave = 4 ELSE thing(N).behave = 3
     EXIT SUB
    ELSE
     IF (Stairs AND 1) > 0 AND thing(N).y < thing(P1).y THEN
      thing(N).stamina = 128: thing(N).behave = 4: EXIT SUB
     ELSEIF thing(N).y > thing(P1).y THEN
      thing(N).stamina = 128: thing(N).behave = 3: EXIT SUB
     END IF
    END IF
   END IF
   IF thing(N).x = 1 THEN
    thing(N).stamina = thing(N).stamina / 2
    thing(N).behave = 2: EXIT SUB
   END IF
   IF MAP(thing(N).y, thing(N).x - 1).CODE = BRICK THEN
    thing(N).stamina = thing(N).stamina / 2
    thing(N).behave = 2: EXIT SUB
   END IF
   IF thing(N).y = thing(P1).y THEN
    IF thing(N).x > thing(P1).x AND thing(N).charge = 0 AND RND(1) < .4 THEN
     thing(N).behave = 5
    END IF
   END IF
   EXIT SUB
  CASE 2:
   IF EYE(thing(N).y) = 1 THEN
    thing(N).stamina = 0
    thing(N).behave = 1
   END IF
   GOSUB iStairs
   IF Stairs > 0 THEN
    IF thing(N).stamina <= 32 THEN
     thing(N).stamina = 128
     IF (Stairs AND 1) > 0 THEN thing(N).behave = 4 ELSE thing(N).behave = 3
     EXIT SUB
    ELSE
     IF (Stairs AND 1) > 0 AND thing(N).y < thing(P1).y THEN
      thing(N).stamina = 128: thing(N).behave = 4: EXIT SUB
     ELSEIF thing(N).y > thing(P1).y THEN
      thing(N).stamina = 128: thing(N).behave = 3: EXIT SUB
     END IF
    END IF
   END IF
   IF thing(N).x = 40 THEN
    thing(N).stamina = thing(N).stamina / 2
    thing(N).behave = 1: EXIT SUB
   END IF
   IF MAP(thing(N).y, thing(N).x + 1).CODE = BRICK THEN
    thing(N).stamina = thing(N).stamina / 2
    thing(N).behave = 1: EXIT SUB
   END IF

   IF thing(N).y = thing(P1).y THEN
    IF thing(N).x < thing(P1).x AND thing(N).charge = 0 AND RND(1) < .4 THEN
     thing(N).behave = 6
    END IF
   END IF
   EXIT SUB
   CASE 3: 'Moving UP!!
    IF thing(N).y = thing(P1).y THEN GOSUB ToPlayer
    IF thing(N).y = 1 THEN
     GOSUB ToPlayer
     thing(N).stamina = thing(N).stamina / 2
     thing(N).behave = 4
     EXIT SUB
    END IF
    IF thing(N).pVID.CODE <> STAIR OR MAP(thing(N).y - 1, thing(N).x).CODE = BRICK THEN
     GOSUB ToPlayer
     thing(N).stamina = thing(N).stamina / 2
     thing(N).behave = 4
     EXIT SUB
    END IF
    IF thing(N).stamina = 32 THEN GOSUB ToPlayer
   CASE 4: 'Moving DOWN!!
    IF thing(N).y = thing(P1).y THEN GOSUB ToPlayer
    IF thing(N).y = 20 THEN
     GOSUB ToPlayer
     thing(N).stamina = thing(N).stamina / 2
     thing(N).behave = 3
     EXIT SUB
    END IF
    IF MAP(thing(N).y + 1, thing(N).x).CODE = BRICK THEN
     GOSUB ToPlayer
     thing(N).stamina = thing(N).stamina / 2
     thing(N).behave = 3
     EXIT SUB
    END IF
    IF thing(N).stamina = 32 THEN GOSUB ToPlayer
   CASE 5: thing(N).behave = 1
   CASE 6: thing(N).behave = 2
   END SELECT
   EXIT SUB
iStairs:
 Stairs = 0
 IF thing(N).y < 20 THEN
  IF MAP(thing(N).y + 1, thing(N).x).CODE <> BRICK THEN Stairs = 1
 END IF
 IF thing(N).pVID.CODE = STAIR THEN Stairs = (Stairs OR 2)
 RETURN
ToPlayer:
 IF thing(N).x = 1 THEN
  IF MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN
    thing(N).behave = 2: thing(N).stamina = 128: EXIT SUB
  ELSE
    RETURN
  END IF
 END IF
 IF thing(N).x = 40 THEN
  IF MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN
    thing(N).behave = 1: thing(N).stamina = 128: EXIT SUB
  ELSE
    RETURN
  END IF
 END IF

 IF thing(N).y = 20 THEN
  IF thing(N).x > thing(P1).x AND MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK THEN
     thing(N).behave = 1: thing(N).stamina = 128: EXIT SUB
  END IF
  IF MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN
   thing(N).behave = 2: thing(N).stamina = 128: EXIT SUB
  END IF
  RETURN
 END IF
 IF thing(N).x > thing(P1).x AND MAP(thing(N).y, thing(N).x - 1).CODE <> BRICK AND MAP(thing(N).y + 1, thing(N).x - 1).CODE <> EMPTY THEN
   thing(N).behave = 1: thing(N).stamina = 128: EXIT SUB
 END IF
 IF MAP(thing(N).y + 1, thing(N).x + 1).CODE <> EMPTY AND MAP(thing(N).y, thing(N).x + 1).CODE <> BRICK THEN
  thing(N).behave = 2: thing(N).stamina = 128: EXIT SUB
 END IF
 RETURN
PickIt:
 IF MAP(thing(N).y, thing(N).x).ATTR <> 15 THEN
  thing(N).behave = 8: thing(N).HP = 0: EXIT SUB
 END IF
 IF thing(N).pVID.CODE <> EMPTY THEN
 SELECT CASE thing(N).pVID.CODE
 CASE SKULL:
  SELECT CASE thing(N).pVID.ATTR
  CASE RED: WP1(1) = WP1(1) + 3
  CASE CYAN: WP1(2) = WP1(2) + 2
  CASE MAGENTA: WP1(3) = WP1(3) + 1
  CASE ELSE:
  END SELECT
  L = WhichNumber(thing(N).x, thing(N).y, N)
  thing(L).CODE = 0: thing(N).pVID = thing(L).pVID
 CASE TREASURE:
  SELECT CASE RND(1)
  CASE IS < .2: WP1(3) = WP1(3) + 3
  CASE IS < .4: WP1(2) = WP1(2) + 5
  CASE IS < .75: WP1(1) = WP1(1) + 6
  CASE IS < .9: IF thing(N).HP < 6 THEN thing(N).HP = thing(N).HP + 1
  CASE ELSE:
  END SELECT
  thing(N).pVID = NOTHING
 CASE APPLE:
  IF thing(N).HP < 5 THEN thing(N).HP = 5: thing(N).pVID = NOTHING
 CASE WEAPON:
  SELECT CASE thing(N).pVID.ATTR
  CASE RED: WP1(1) = WP1(1) + 9
  CASE CYAN: WP1(2) = WP1(2) + 7
  CASE MAGENTA: WP1(3) = WP1(3) + 5
  CASE ELSE:
  END SELECT
  thing(N).pVID = NOTHING
 CASE HEART:
    IF thing(N).HP < 8 THEN thing(N).HP = thing(N).HP + 1: thing(N).pVID = NOTHING
 CASE ELSE:
 END SELECT
 END IF
 RETURN
YouMan:
 PlayerDeath = RND(1) * 50 + 7
 SELECT CASE KeyP1
 CASE FIRE:
  IF thing(N).charge > 0 THEN EXIT SUB
  IF thing(N).behave = 1 AND thing(N).x > 1 THEN
   IF (MAP(thing(N).y, thing(N).x - 1).CODE = EMPTY OR MAP(thing(N).y, thing(N).x - 1).CODE = STAIR) AND WP1(thing(N).GUN) > 0 THEN
    WP1(thing(N).GUN) = WP1(thing(N).GUN) - 1
    EYE(thing(N).y) = 1
    thing(N).charge = 3
    thing(N).behave = 5: EXIT SUB
   END IF
  ELSEIF thing(N).behave = 2 AND thing(N).x < 40 THEN
   IF (MAP(thing(N).y, thing(N).x + 1).CODE = EMPTY OR MAP(thing(N).y, thing(N).x + 1).CODE = STAIR) AND WP1(thing(N).GUN) > 0 THEN
    WP1(thing(N).GUN) = WP1(thing(N).GUN) - 1
    EYE(thing(N).y) = 2
    thing(N).charge = 3
    thing(N).behave = 6: EXIT SUB
   END IF
  END IF
 CASE SCROLL:
  GOSUB ResetW
  IF thing(N).GUN = 3 THEN thing(N).GUN = 1 ELSE thing(N).GUN = thing(N).GUN + 1
  GOSUB SetW
 CASE UP:
      IF thing(N).pVID.CODE <> STAIR THEN thing(N).behave = 0 ELSE thing(N).behave = 3
 CASE LEFT: thing(N).behave = 1
 CASE RIGHT: thing(N).behave = 2
 CASE DOWN:
     IF thing(N).y = 20 THEN thing(N).behave = 0: EXIT SUB
     IF MAP(thing(N).y + 1, thing(N).x).CODE = BRICK THEN thing(N).behave = 0 ELSE thing(N).behave = 4
 CASE ESC: PlayerDeath = 1
 CASE SPACE: NextLevel = 1
 CASE ELSE:
 END SELECT
 IF thing(N).behave = 5 THEN thing(N).behave = 1
 IF thing(N).behave = 6 THEN thing(N).behave = 2
 EXIT SUB
ResetW:
 SELECT CASE thing(N).GUN
 CASE 1: CALL PutBigSymbol(1, 23, 153, RED, 2, 1)
 CASE 2: CALL PutBigSymbol(4, 23, 156, CYAN, 2, 1)
 CASE 3: CALL PutBigSymbol(7, 23, 154, MAGENTA, 2, 1)
 END SELECT: RETURN
SetW:
 SELECT CASE thing(N).GUN
 CASE 1: CALL PutBigSymbol(1, 23, 153, RED + 128, 2, 1)
 CASE 2: CALL PutBigSymbol(4, 23, 156, CYAN + 128, 2, 1)
 CASE 3: CALL PutBigSymbol(7, 23, 154, MAGENTA + 128, 2, 1)
 END SELECT: RETURN
END SUB

SUB Move
 FOR i = 1 TO MaxThing
  IF thing(i).CODE = 1 OR thing(i).CODE = 2 THEN CALL MoveObject(i)
 NEXT
 FOR i = 1 TO 5
  IF tBOSS(i).CODE > 0 THEN CALL MoveBoss(i)
 NEXT
END SUB

SUB MoveBoss (B)
 CALL ResetBoss(B)
 CALL PutBoss(tBOSS(B).x, tBOSS(B).y, tBOSS(B).VID.CODE, tBOSS(B).VID.ATTR)
 IF (MAP(tBOSS(B).y, tBOSS(B).x).CODE >= 140 AND MAP(tBOSS(B).y, tBOSS(B).x).CODE < 152) OR MAP(tBOSS(B).y, tBOSS(B).x).CODE = SKULL THEN
  N = WhichNumber(tBOSS(B).x, tBOSS(B).y, 0)
  tBOSS(B).pVID1 = thing(N).pVID
 ELSE
  tBOSS(B).pVID1 = MAP(tBOSS(B).y, tBOSS(B).x)
 END IF
 IF (MAP(tBOSS(B).y, tBOSS(B).x + 1).CODE >= 140 AND MAP(tBOSS(B).y, tBOSS(B).x + 1).CODE < 152) OR MAP(tBOSS(B).y, tBOSS(B).x + 1).CODE = SKULL THEN
  N = WhichNumber(tBOSS(B).x + 1, tBOSS(B).y, 0)
  tBOSS(B).pVID2 = thing(N).pVID
 ELSE
  tBOSS(B).pVID2 = MAP(tBOSS(B).y, tBOSS(B).x + 1)
 END IF
 IF (MAP(tBOSS(B).y + 1, tBOSS(B).x).CODE >= 140 AND MAP(tBOSS(B).y + 1, tBOSS(B).x).CODE < 152) OR MAP(tBOSS(B).y + 1, tBOSS(B).x).CODE = SKULL THEN
  N = WhichNumber(tBOSS(B).x, tBOSS(B).y + 1, 0)
  IF N <> 0 THEN tBOSS(B).pVID3 = thing(N).pVID
 ELSE
  tBOSS(B).pVID3 = MAP(tBOSS(B).y + 1, tBOSS(B).x)
 END IF
 IF (MAP(tBOSS(B).y + 1, tBOSS(B).x + 1).CODE >= 140 AND MAP(tBOSS(B).y + 1, tBOSS(B).x + 1).CODE < 152) OR MAP(tBOSS(B).y + 1, tBOSS(B).x + 1).CODE = SKULL THEN
  N = WhichNumber(tBOSS(B).x + 1, tBOSS(B).y + 1, 0)
  IF N <> 0 THEN tBOSS(B).pVID4 = thing(N).pVID
 ELSE
  tBOSS(B).pVID4 = MAP(tBOSS(B).y + 1, tBOSS(B).x + 1)
 END IF

 CALL SetBoss(tBOSS(B).x, tBOSS(B).y, tBOSS(B).VID.CODE, tBOSS(B).VID.ATTR)
 tBOSS(B).xOld = tBOSS(B).x: tBOSS(B).yOld = tBOSS(B).y
END SUB

SUB MoveObject (N)
 MAP(thing(N).yOld, thing(N).xOld) = thing(N).pVID
 CALL PutSymbol(thing(N).xOld, thing(N).yOld, thing(N).pVID.CODE, thing(N).pVID.ATTR)
 CALL PutOrSymbol(thing(N).x, thing(N).y, thing(N).VID.CODE, thing(N).VID.ATTR)

 IF MAP(thing(N).y, thing(N).x).CODE < 137 THEN
   thing(N).pVID = MAP(thing(N).y, thing(N).x)
 ELSEIF MAP(thing(N).y, thing(N).x).CODE = EMPTY OR MAP(thing(N).y, thing(N).x).CODE = TREASURE THEN
   thing(N).pVID = MAP(thing(N).y, thing(N).x)
 ELSEIF MAP(thing(N).y, thing(N).x).CODE > 202 AND MAP(thing(N).y, thing(N).x).CODE < 215 THEN
   thing(N).pVID = MAP(thing(N).y, thing(N).x)
 ELSEIF MAP(thing(N).y, thing(N).x).CODE < coBOSS THEN
  L = WhichNumber(thing(N).x, thing(N).y, N)
  IF L > 0 THEN thing(N).pVID = thing(L).pVID ELSE thing(N).pVID = MAP(thing(N).y, thing(N).x)
 END IF
 MAP(thing(N).y, thing(N).x) = thing(N).VID
 thing(N).xOld = thing(N).x: thing(N).yOld = thing(N).y
END SUB

SUB OpenLevel
 CALL OutPutLevel("level" + RIGHT$(STR$(Level), LEN(STR$(Level)) - 1))
END SUB

SUB OpenScreen
 CLS : CALL RepeatSymbol(1, 21, UpLine, 7, 40)
 LOCATE 22, 15: COLOR 12: PRINT "Level"; : LOCATE 23, 18: COLOR 15
 PRINT USING "##"; Level
 CALL PutBigSymbol(1, 23, 153, RED + 128, 2, 1)
 CALL PutBigSymbol(4, 23, 156, CYAN, 2, 1)
 CALL PutBigSymbol(7, 23, 154, MAGENTA, 2, 1)
 CALL OutPutLevel("Man.TIT")
END SUB

SUB OutPutLevel (N$)
 OPEN N$ FOR INPUT AS #1
 FOR i = 1 TO 20: FOR j = 1 TO 40
  INPUT #1, MAP(i, j).CODE: INPUT #1, MAP(i, j).ATTR
 NEXT j, i
 CLOSE #1
 FOR i = 1 TO 20: FOR j = 1 TO 40
  CALL PutAllSymbol(j, i, MAP(i, j).CODE, MAP(i, j).ATTR)
 NEXT j, i
END SUB

DEFSNG A-Z
SUB PutAllSymbol (x%, y%, CODE%, ATTR%)
 DEFINT A-Z
 IF CODE < 128 THEN LOCATE y, x: COLOR ATTR: PRINT CHR$(CODE); : EXIT SUB
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, CODE
 IF ATTR% > 128 THEN ATTR% = ATTR% - 128: POKE &H89, 3 ELSE POKE &H89, 0
 POKE &H8A, ATTR
 CALL absolute(0)
 DEF SEG
END SUB

SUB PutBigSymbol (x, y, CODE, ATTR, Wid, Height)
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, CODE
 IF ATTR% > 128 THEN ATTR% = ATTR% - 128: POKE &H89, 3 ELSE POKE &H89, 0
 POKE &HDB, Wid: POKE &HDD, Height
 POKE &H8A, ATTR
 CALL absolute(&HDF)
 DEF SEG
END SUB

DEFSNG A-Z
SUB PutBoss (x%, y%, CODE%, ATTR%)
 CALL PutOrSymbol(x%, y%, CODE%, ATTR%)
 CALL PutOrSymbol(x% + 1, y%, CODE% + 1, ATTR%)
 CALL PutOrSymbol(x%, y% + 1, CODE% + 2, ATTR%)
 CALL PutOrSymbol(x% + 1, y% + 1, CODE% + 3, ATTR%)
END SUB

DEFINT A-Z
SUB PutInvSymbol (x, y, CODE, ATTR)
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, CODE
 POKE &H89, 3: POKE &H8A, ATTR
 CALL absolute(0)
 DEF SEG
END SUB

SUB PutMessage
 PRINT : PRINT "ATTENTION! This is the SHAREWARE version."
 PRINT "All rights for distribuition this game throu BBS have been given to KYRANDIA corp."
 PRINT "To order commersion release or to register this game call Kyrandia BBS"
 PRINT "(C)opyright Volgograd-98 by Grendel Dragon Wizard."
 PRINT : PRINT "ВНИМАНИЕ! Это пробная версия."
 PRINT "Все права на распространение этой игры через ББС переданы Кирандия корп."
 PRINT "Чтобы зарегестрировать данную программу, обращайтесь к Кирандия ББС."
 PRINT " Волгоград-98 by Grendel Dragon Wizard"


END SUB

SUB PutOrSymbol (x, y, CODE, ATTR)
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, CODE
 POKE &H89, 1: POKE &H8A, ATTR
 CALL absolute(0)
 DEF SEG
END SUB

DEFSNG A-Z
SUB PutString (x%, y%, S1$, ATTR%)
 FOR i% = 1 TO LEN(S1$)
  CALL PutSymbol(x%, y%, ASC(MID$(S1$, i%, 1)), ATTR%)
  x% = x% + 1
 NEXT
END SUB

DEFINT A-Z
SUB PutSymbol (x, y, CODE, ATTR)
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, CODE
 POKE &H89, 0: POKE &H8A, ATTR
 CALL absolute(0)
 DEF SEG
END SUB

SUB Ramka (xl, yu, xr, yd)
 CALL PutSymbol(xl, yu, 172, WHITE)
 CALL RepeatSymbol(xl + 1, yu, 177, 7, xr - xl - 1)
 CALL PutSymbol(xr, yu, 173, 7)
 FOR i = yu + 1 TO yd - 1
  CALL PutSymbol(xl, i, 176, 7): CALL RepeatSymbol(xl + 1, i, 178, 7, xr - xl - 1)
  CALL PutSymbol(xr, i, 176, 7)
 NEXT
 CALL PutSymbol(xl, yd, 174, 7): CALL RepeatSymbol(xl + 1, yd, 177, 7, xr - xl - 1)
 CALL PutSymbol(xr, yd, 175, 7)
END SUB

FUNCTION ReadKey
 DEF SEG = &H8000
 CALL absolute(&HAB)
 ReadKey = PEEK(&HC0)
 DEF SEG
END FUNCTION

SUB ReadLevel
 FOR i = 1 TO MaxThing: thing(i).CODE = 0: NEXT
 FOR i = 1 TO 5: tBOSS(i).CODE = 0: NEXT
 P1 = 0: P2 = 0
 FOR i = 1 TO 20: EYE(i) = 0: NEXT
 N = 0: B = 0
 FOR i = 1 TO 20
  FOR j = 1 TO 40
   IF MAP(i, j).CODE = MAN THEN
    N = N + 1: GOSUB InitMan
   ELSEIF MAP(i, j).CODE >= coBOSS THEN
    B = B + 1: GOSUB InitBoss
   END IF
  NEXT j, i
 EXIT SUB
InitMan:
 thing(N).x = j: thing(N).y = i: thing(N).xOld = j: thing(N).yOld = i
 thing(N).VID = MAP(i, j)
 thing(N).pVID = NOTHING
 thing(N).behave = 0: thing(N).FLSTEPS = 0: thing(N).STEPS = 0
 thing(N).the = 0: thing(N).charge = 0: thing(N).CODE = 1
 SELECT CASE MAP(i, j).ATTR
 CASE RED: thing(N).HP = 1: thing(N).GUN = 1
 CASE CYAN: thing(N).HP = 2: thing(N).GUN = 2
 CASE MAGENTA: thing(N).HP = 3: thing(N).GUN = 3
 CASE BROWN: thing(N).HP = 3: thing(N).GUN = 4
 CASE BLUE: thing(N).HP = 5: thing(N).GUN = 5
 CASE LIGHTWHITE: thing(N).HP = 5: P1 = N
     IF thing(N).GUN = 0 THEN thing(N).GUN = 1
 CASE YELLOW: thing(N).HP = 5: P2 = N
  IF thing(N).GUN = 0 THEN thing(N).GUN = 1
 END SELECT
 RETURN
InitBoss:
 SELECT CASE MAP(i, j).CODE
 CASE LTOOTHED:
  GOSUB SetBI
  tBOSS(B).CODE = 1: tBOSS(B).HP = 15: tBOSS(B).dirx = 1
  tBOSS(B).behave = 2
 CASE GIANT:
  GOSUB SetBI
  tBOSS(B).CODE = 2: tBOSS(B).HP = 20: tBOSS(B).dirx = 0
  tBOSS(B).behave = 0
 CASE SKELETON:
  tBOSS(B).CODE = 3: tBOSS(B).HP = 25: tBOSS(B).dirx = 0
  tBOSS(B).behave = 0
 CASE ELSE: B = B - 1
 END SELECT
 RETURN
SetBI:
 tBOSS(B).x = j: tBOSS(B).y = i
 tBOSS(B).xOld = j: tBOSS(B).yOld = i
 tBOSS(B).VID = MAP(i, j)
 tBOSS(B).pVID1 = NOTHING
 tBOSS(B).pVID2 = NOTHING
 tBOSS(B).pVID3 = NOTHING
 tBOSS(B).pVID4 = NOTHING
 tBOSS(B).charge = 0: tBOSS(B).diry = 0
 RETURN
END SUB

DEFSNG A-Z
SUB RepeatSymbol (x%, y%, CODE%, ATTR%, number%)
 DEFINT A-Z
 FOR i = 0 TO number - 1
  CALL PutSymbol(x + i, y, CODE, ATTR)
 NEXT
END SUB

SUB ResetBoss (B)
 MAP(tBOSS(B).yOld, tBOSS(B).xOld) = tBOSS(B).pVID1
 MAP(tBOSS(B).yOld, tBOSS(B).xOld + 1) = tBOSS(B).pVID2
 MAP(tBOSS(B).yOld + 1, tBOSS(B).xOld) = tBOSS(B).pVID3
 MAP(tBOSS(B).yOld + 1, tBOSS(B).xOld + 1) = tBOSS(B).pVID4
 CALL PutSymbol(tBOSS(B).xOld, tBOSS(B).yOld, tBOSS(B).pVID1.CODE, tBOSS(B).pVID1.ATTR)
 CALL PutSymbol(tBOSS(B).xOld + 1, tBOSS(B).yOld, tBOSS(B).pVID2.CODE, tBOSS(B).pVID2.ATTR)
 CALL PutSymbol(tBOSS(B).xOld, tBOSS(B).yOld + 1, tBOSS(B).pVID3.CODE, tBOSS(B).pVID3.ATTR)
 CALL PutSymbol(tBOSS(B).xOld + 1, tBOSS(B).yOld + 1, tBOSS(B).pVID4.CODE, tBOSS(B).pVID4.ATTR)
END SUB

SUB RestoreScreen (xl, yu, xr, yd)
 t = 1
 FOR i = yu TO yd
  FOR j = xl TO xr
    CALL PutSymbol(j, i, EKR(t).CODE, EKR(t).ATTR): t = t + 1
 NEXT j, i
REDIM EKR(1 TO 1)  AS SYMBOL
END SUB

SUB SaveScreen (xUp, yUp, xDwn, yDwn)
 REDIM EKR((xDwn - xUp + 1) * (yDwn - yUp + 1)) AS SYMBOL
 t = 1
 FOR i = yUp TO yDwn
  FOR j = xUp TO xDwn
   EKR(t) = MAP(i, j)
  t = t + 1
 NEXT j, i
END SUB

SUB SetBoss (x, y, CODE, ATTR)
 MAP(y, x).CODE = CODE
 MAP(y, x).ATTR = ATTR
 MAP(y, x + 1).CODE = CODE + 1
 MAP(y, x + 1).ATTR = ATTR
 MAP(y + 1, x).CODE = CODE + 2
 MAP(y + 1, x).ATTR = ATTR
 MAP(y + 1, x + 1).CODE = CODE + 3
 MAP(y + 1, x + 1).ATTR = ATTR
END SUB

SUB WeaponFly (N)
  Moves = thing(N).SPD
  DO WHILE Moves > 0
   IF thing(N).x = 40 OR thing(N).x = 1 THEN GOSUB StopIt: EXIT DO
   thing(N).x = thing(N).x + thing(N).dirx
   IF MAP(thing(N).y, thing(N).x).CODE <> EMPTY THEN
    SELECT CASE MAP(thing(N).y, thing(N).x).CODE
    CASE BRICK: GOSUB StopIt: EXIT DO
    CASE TREE:
     GOSUB StopIt
     IF thing(N).GUN = 3 THEN
      MAP(thing(N).y, thing(N).x) = NOTHING
      CALL PutSymbol(thing(N).x, thing(N).y, NOTHING.CODE, NOTHING.ATTR)
     END IF
     EXIT DO
    CASE CROSS:
     GOSUB StopIt
     MAP(thing(N).y, thing(N).x) = NOTHING
     CALL PutSymbol(thing(N).x, thing(N).y, NOTHING.CODE, NOTHING.ATTR)
     EXIT DO
    CASE 140 TO 151:
     GOSUB StopIt
     M = WhichNumber(thing(N).x, thing(N).y, N)
     IF M > 0 THEN thing(M).HP = thing(M).HP - thing(N).HP
     EXIT DO
    CASE 215 TO 255:
     GOSUB StopIt
     M = WhichBoss(thing(N).x, thing(N).y)
     IF M > 0 THEN tBOSS(M).HP = tBOSS(M).HP - thing(N).HP
     EXIT DO
    CASE ELSE:
    END SELECT
    END IF
    Moves = Moves - 1
   LOOP
   EXIT SUB
StopIt:
 MAP(thing(N).yOld, thing(N).xOld) = thing(N).pVID
 CALL PutSymbol(thing(N).xOld, thing(N).yOld, thing(N).pVID.CODE, thing(N).pVID.ATTR)
 thing(N).CODE = 0
 EYE(thing(N).y) = 0
 RETURN
END SUB

FUNCTION WhichBoss (x, y)
 FOR i = 1 TO 5
  IF tBOSS(i).CODE > 0 THEN
   IF tBOSS(i).x = x AND tBOSS(i).y = y THEN WhichBoss = i: EXIT FUNCTION
   IF tBOSS(i).x + 1 = x AND tBOSS(i).y = y THEN WhichBoss = i: EXIT FUNCTION
   IF tBOSS(i).x = x AND tBOSS(i).y + 1 = y THEN WhichBoss = i: EXIT FUNCTION
   IF tBOSS(i).x + 1 = x AND tBOSS(i).y + 1 = y THEN WhichBoss = i: EXIT FUNCTION
  END IF
 NEXT i
END FUNCTION

FUNCTION WhichNumber (x, y, N)
 FOR i = 1 TO MaxThing
  IF thing(i).xOld = x AND thing(i).yOld = y AND i <> N THEN WhichNumber = i: EXIT FUNCTION
 NEXT
END FUNCTION

SUB WriteBoard
 LOCATE 24, 1: COLOR 7
 PRINT USING "##"; WP1(1); : PRINT " ";
 PRINT USING "##"; WP1(2); : PRINT " ";
 PRINT USING "##"; WP1(3);
 IF thing(P1).HP <= 0 THEN
  CALL PutBigSymbol(1, 22, EMPTY, 0, 8, 1)
 ELSE
  FOR i = 1 TO thing(P1).HP
   CALL PutSymbol(i, 22, HEART, MAGENTA)
  NEXT
  WHILE i < 9
   CALL PutSymbol(i, 22, EMPTY, 7): i = i + 1
  WEND
 END IF
END SUB

