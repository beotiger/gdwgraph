DECLARE SUB SelectAttr (A%)
DECLARE SUB GetSymbol (Code%, ATTR%)
DECLARE SUB CountSpeed ()
DECLARE SUB CreateSymbol ()
DECLARE FUNCTION ExistFile% (FileName$)
DECLARE SUB Editor ()
DECLARE SUB LoadTable ()
DECLARE SUB RestoreScreen (xl%, yu%, xr%, yd%)
DECLARE SUB Ramka (xl%, yu%, xr%, yd%)
DECLARE SUB SaveScreen (xUp%, yUp%, xDwn%, yDwn%)
DECLARE SUB GetSymbol1 (Code%, ATTR%)
DECLARE SUB SetBoss (x%, y%, Code%, ATTR%)
DECLARE SUB CreateWindow (lx%, uy%, rx%, dy%)
DECLARE SUB CloseWindow (lx%, uy%, rx%, dy%)
DECLARE SUB PutBoss (x%, y%, Code%, ATTR%)
DECLARE SUB PutString (x%, y%, s$, ATTR%)
DECLARE SUB RepeatSymbol (x%, y%, Code%, ATTR%, number%)
DECLARE SUB PutSymbol (x%, y%, Code%, ATTR%)
DEFINT A-Z
OPTION BASE 1
CLEAR , &H7000
CONST BLACK = 0, BLUE = 1, GREEN = 2, CYAN = 3, RED = 4, MAGENTA = 5, BROWN = 6, WHITE = 7
CONST GREY = 8, lightblue = 9, LIGHTGREEN = 10, lightcyan = 11, LIGHTRED = 12, LIGHTMAGENTA = 13, YELLOW = 14, LIGHTWHITE = 15
CONST ESC = 27, Enter = 13, SPACE = 32, KTAB = 9, UP = 72, DOWN = 80, RIGHT = 77, LEFT = 75
CONST HOME = 71, PGUP = 73, KEND = 79, PGDWN = 81, INS = 82, DEL = 83
CONST F1 = 59, F2 = 60, F3 = 61, F4 = 62, F5 = 63, F6 = 64, F7 = 65, F8 = 66, F9 = 67, F10 = 68
CONST SHIFTF1 = 84, SHIFTF0 = 83, SHIFTF10 = 93, SHIFTF9 = 92, SHIFTF8 = 91, SHIFTF7 = 90
CONST AltF1 = 104, ALTF0 = 103, ALTF10 = 113, AltF3 = 106
CONST CtrlF1 = 94, CTRLF0 = 93, CTRLF10 = 103, CtrlF3 = 96
CONST CtrlF2 = 95, CtrlF4 = 97, CtrlF5 = 98, CtrlF6 = 99, CtrlF7 = 100, CtrlF8 = 101, CtrlF9 = 102
CONST AltF2 = 105, AltF4 = 107, AltF5 = 108, AltF6 = 109, AltF7 = 110, AltF8 = 111, AltF9 = 112


CONST SKULL = 128, WEAPON = 129, TEN = 130, APPLE = 131, CROSS = 132
CONST TREE = 133, HEART = 134, BRICK = 135
CONST STAIR = 136, TREASURE = 166, MAN = 144, MANR = 146
CONST MANL = 149, MANUD = 141
CONST UPLINE = 171, EMPTY = 178, STAR = 179



TYPE SYMBOL
 Code AS INTEGER
 ATTR AS INTEGER
END TYPE

DIM SHARED UNITSTOCK(1 TO 7) AS SYMBOL, BOSSSTOCK(1 TO 10) AS SYMBOL, CARDSSTOCK(1 TO 10) AS SYMBOL
DIM SHARED STOCKATTR(1 TO 10), ARROW(1 TO 4), SECOND AS SINGLE
DIM SHARED MAP(20, 40) AS SYMBOL, tSymbol AS SYMBOL
REDIM SHARED EKR(1 TO 1) AS SYMBOL

RESTORE DATABLOCK1
FOR i = 1 TO 7: READ STOCKATTR(i): NEXT
FOR i = 1 TO 7: READ UNITSTOCK(i).Code: READ UNITSTOCK(i).ATTR: NEXT
FOR i = 1 TO 3: READ BOSSSTOCK(i).Code: READ BOSSSTOCK(i).ATTR: NEXT
FOR i = 1 TO 3: READ CARDSSTOCK(i).Code: READ CARDSSTOCK(i).ATTR: NEXT
ARROW(1) = 167: ARROW(2) = 170: ARROW(3) = 168: ARROW(4) = 169

'****************** DATA BLOCKS ********************
DATABLOCK1:
DATA 4,3,5,6,1,15,14
DATA 135,12,136,13,131,7,134,5,132,8,133,10,166,3
DATA 215,24,223,43,235,7
DATA 203,77,207,91,211,29

SCREEN 13, 0: WIDTH 40
CALL CountSpeed
CALL LoadTable
CALL Editor

SUB CloseWindow (lx, uy, rx, dy)
 CALL RestoreScreen(lx, uy, rx, dy)
END SUB

SUB CountSpeed
 SECOND = 0
 B! = TIMER + 1: C! = 0
 WHILE C! < B!: C! = TIMER: WEND
 B! = TIMER + 1
 WHILE C! < B!: C! = TIMER: SECOND = SECOND + 1: WEND
 'PRINT SECOND
END SUB

SUB CreateSymbol
 STATIC cSym, yCur, xCur, mPen, mDouble, mSize, gClr
 DIM IM$(16, 16), SIM$(16, 16)
 IF xCur = 0 THEN
   xCur = 1: yCur = 1: cSym = 128: gClr = 15
 END IF
 FOR i = 1 TO 20: CALL RepeatSymbol(1, i, 178, 7, 40): NEXT
 GOSUB OpenIt
 LOCATE 2, 22: COLOR 13: PRINT "F2 DOUBLE F5 PEN"
 LOCATE 3, 22: PRINT "F3 PUT    F6 PICK"
 LOCATE 4, 22: PRINT "F4 GET    F7 READ"
 LOCATE 5, 22: PRINT "F8 SAVE   F9 CLEAR"
 LOCATE 6, 22: PRINT "F  SAVE&QUIT": CALL PutSymbol(23, 6, TEN, 13)
 COLOR 7: LOCATE 7, 22: PRINT "PgUP,PgDWN LIST"
 COLOR 11: LOCATE 8, 22: PRINT "Alt,Ctrl+  F4 UP"
 LOCATE 9, 22: PRINT "F1 INVERSE F5 DOWN"
 LOCATE 10, 22: PRINT "F2 ROTATE  F6 RGHT"
 LOCATE 11, 22: PRINT "F3 REVERSE F7 LEFT"
 LOCATE 12, 22: PRINT "F8 SIZE"
 COLOR 7: LOCATE 13, 22: PRINT "Tab tabulate"
 LOCATE 14, 22: PRINT "SPACE set/del pix" 'or del pixel"
 LOCATE 15, 22: PRINT "ESC quit"
 COLOR 13: LOCATE 16, 30: PRINT "Shift"
 LOCATE 17, 30: PRINT "F8 GRID": LOCATE 18, 30: PRINT "F9 CLEAR"
 GOSUB iGET
 DO
  CALL PutSymbol(2 + xCur, 1 + yCur, ASC("X"), WHITE)
  LOCATE 19, 5':color LIGHTCYAN
  PRINT USING "##"; xCur
  LOCATE 20, 5: PRINT USING "##"; yCur
  LINE (80, 0)-(80, 144), gClr: LINE (8, 72)-(152, 72), gClr
  GOSUB LKPause1
  CALL PutSymbol(2 + xCur, 1 + yCur, ASC(IM$(yCur, xCur)), LIGHTGREEN)
  IF A$ = "" THEN GOSUB LKPause1
  IF A$ <> "" THEN GOSUB KeyDisp
 LOOP
LKPause1:
 FOR i = 1 TO INT(SECOND / 4)
  A$ = INKEY$: IF A$ <> "" THEN EXIT FOR
 NEXT: RETURN

KeyDisp:
 IF LEN(A$) = 1 THEN
 SELECT CASE ASC(A$)
 CASE SPACE: GOSUB SetorDelBit
 CASE ESC: EXIT SUB
 CASE KTAB:
  IF xCur < 9 AND yCur < 9 THEN
   xCur = xCur + 8
  ELSEIF yCur < 9 THEN
   yCur = yCur + 8: xCur = xCur - 8
  ELSEIF xCur < 9 THEN
   xCur = xCur + 8
  ELSE
   xCur = xCur - 8: yCur = yCur - 8
  END IF
 CASE ELSE:
 END SELECT
 ELSE
  SELECT CASE ASC(RIGHT$(A$, 1))
  CASE F2: mDouble = NOT (mDouble)
  CASE F3: GOSUB iPUT
  CASE F4: GOSUB iGET
  CASE F5: mPen = NOT (mPen)
  CASE F6: CALL GetSymbol(cSym, nothing): GOSUB OpenIt
        IF cSym > 252 THEN cSym = 252
        GOSUB iGET
  CASE F8: GOSUB iSAVE
  CASE F9:
     GOSUB LocSym
     FOR i = yPos TO yPos + 7
      FOR j = xPos TO xPos + 7
       IM$(i, j) = CHR$(EMPTY)
     NEXT j, i
     GOSUB iPRINT
  CASE SHIFTF9:
    FOR i = 1 TO 16: FOR j = 1 TO 16
      IM$(i, j) = CHR$(EMPTY)
    NEXT j, i: GOSUB iPRINT
  CASE SHIFTF8: IF gClr = 15 THEN gClr = 0 ELSE gClr = 15
  CASE F10: GOSUB iSAVE: EXIT SUB
  CASE F7: CALL LoadTable
  CASE PGUP:
     IF cSym - 4 > 127 THEN cSym = cSym - 4: GOSUB iGET
  CASE PGDWN:
     IF cSym + 4 < 253 THEN cSym = cSym + 4: GOSUB iGET
  CASE LEFT:
    IF mPen THEN GOSUB SetBit
    IF xCur > 1 THEN xCur = xCur - 1
  CASE RIGHT:
    IF mPen THEN GOSUB SetBit
    IF xCur < 16 THEN xCur = xCur + 1
  CASE UP:
   IF mPen THEN GOSUB SetBit
   IF yCur > 1 THEN yCur = yCur - 1
  CASE DOWN:
   IF mPen THEN GOSUB SetBit
   IF yCur < 16 THEN yCur = yCur + 1
  CASE CtrlF1:
   FOR i = 1 TO 16: FOR j = 1 TO 16
    IF IM$(i, j) = CHR$(STAR) THEN IM$(i, j) = CHR$(EMPTY) ELSE IM$(i, j) = CHR$(STAR)
   NEXT j, i: GOSUB iPRINT
  CASE CtrlF2:
   FOR i = 1 TO 16: FOR j = 1 TO 16
    SIM$(j, i) = IM$(i, j): NEXT j, i
   GOSUB SIM2IM: GOSUB iPRINT
  CASE CtrlF3:
    FOR i = 1 TO 16: FOR j = 1 TO 16
     SIM$(i, 17 - j) = IM$(i, j)
    NEXT j, i: GOSUB SIM2IM: GOSUB iPRINT
  CASE CtrlF4:
   FOR i = 2 TO 16: FOR j = 1 TO 16
    IM$(i - 1, j) = IM$(i, j)
   NEXT j, i
   FOR j = 1 TO 16: IM$(16, j) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE CtrlF5:
   FOR i = 15 TO 1 STEP -1: FOR j = 1 TO 16
    IM$(i + 1, j) = IM$(i, j)
   NEXT j, i
   FOR j = 1 TO 16: IM$(1, j) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE CtrlF6:
   FOR j = 15 TO 1 STEP -1: FOR i = 1 TO 16
    IM$(i, j + 1) = IM$(i, j)
   NEXT i, j
   FOR i = 1 TO 16: IM$(i, 1) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE CtrlF7:
   FOR j = 2 TO 16: FOR i = 1 TO 16
    IM$(i, j - 1) = IM$(i, j)
   NEXT i, j
   FOR i = 1 TO 16: IM$(i, 16) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE CtrlF8:
   x = 1: y = 1
    FOR i = 1 TO 16 STEP 2: FOR j = 1 TO 16 STEP 2
     GOSUB CountSTARS
     IF A > 1 THEN SIM$(y, x) = CHR$(STAR) ELSE SIM$(y, x) = CHR$(EMPTY)
     x = x + 1
    NEXT j
    x = 1: y = y + 1
   NEXT i
   FOR i = 1 TO 16: FOR j = 1 TO 16: IM$(i, j) = CHR$(EMPTY): NEXT j, i
   GOSUB LocSym
   FOR i = 1 TO 8: FOR j = 1 TO 8
    IM$(yPos + i - 1, xPos + j - 1) = SIM$(i, j)
   NEXT j, i: GOSUB iPRINT
  CASE AltF8:
   GOSUB LocSym
   x = 1: y = 1
   FOR i = yPos TO yPos + 7: FOR j = xPos TO xPos + 7
    SIM$(y, x) = IM$(i, j)
    SIM$(y, x + 1) = IM$(i, j)
    SIM$(y + 1, x) = IM$(i, j)
    SIM$(y + 1, x + 1) = IM$(i, j)
    x = x + 2
   NEXT j
   x = 1: y = y + 2
   NEXT i
   GOSUB SIM2IM: GOSUB iPRINT
  CASE AltF1:
   GOSUB LocSym
   FOR i = yPos TO yPos + 7: FOR j = xPos TO xPos + 7
    IF IM$(i, j) = CHR$(STAR) THEN IM$(i, j) = CHR$(EMPTY) ELSE IM$(i, j) = CHR$(STAR)
   NEXT j, i: GOSUB iPRINT
  CASE AltF2:
   GOSUB LocSym
   FOR i = 1 TO 8: FOR j = 1 TO 8
    SIM$(i, j) = IM$(yPos + i - 1, xPos + j - 1)
   NEXT j, i
   FOR i = 1 TO 8: FOR j = 1 TO 8
    SIM$(j + 8, i + 8) = SIM$(i, j)
   NEXT j, i
   FOR i = 1 TO 8: FOR j = 1 TO 8
    IM$(yPos + i - 1, xPos + j - 1) = SIM$(i + 8, j + 8)
   NEXT j, i
   GOSUB iPRINT
  CASE AltF3:
   GOSUB LocSym
   IF xPos = 1 THEN
    FOR i = yPos TO yPos + 7
     FOR j = xPos TO xPos + 7
      SIM$(i, 9 - j) = IM$(i, j)
    NEXT j, i
   ELSE
    FOR i = yPos TO yPos + 7
     FOR j = xPos TO xPos + 7
      SIM$(i, 17 - j + 8) = IM$(i, j)
    NEXT j, i
   END IF
   GOSUB SIM8IM: GOSUB iPRINT
  CASE AltF4:
   GOSUB LocSym
   FOR i = yPos + 1 TO yPos + 7
    FOR j = xPos TO xPos + 7
     IM$(i - 1, j) = IM$(i, j)
    NEXT j, i
   FOR j = xPos TO xPos + 7: IM$(yPos + 7, j) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE AltF5:
   GOSUB LocSym
   FOR i = yPos + 6 TO yPos STEP -1
    FOR j = xPos TO xPos + 7
     IM$(i + 1, j) = IM$(i, j)
    NEXT j, i
   FOR j = xPos TO xPos + 7: IM$(yPos, j) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE AltF6:
   GOSUB LocSym
   FOR j = xPos + 6 TO xPos STEP -1
    FOR i = yPos TO yPos + 7
     IM$(i, j + 1) = IM$(i, j)
   NEXT i, j
   FOR i = yPos TO yPos + 7: IM$(i, xPos) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE AltF7:
   GOSUB LocSym
   FOR j = xPos + 1 TO xPos + 7
    FOR i = yPos TO yPos + 7
     IM$(i, j - 1) = IM$(i, j)
   NEXT i, j
   FOR i = yPos TO yPos + 7: IM$(i, xPos + 7) = CHR$(EMPTY): NEXT
   GOSUB iPRINT
  CASE ELSE:
  END SELECT
  END IF
 RETURN
CountSTARS:
 A = 0
 IF IM$(i, j) = CHR$(STAR) THEN A = A + 1
 IF IM$(i, j + 1) = CHR$(STAR) THEN A = A + 1
 IF IM$(i + 1, j) = CHR$(STAR) THEN A = A + 1
 IF IM$(i + 1, j + 1) = CHR$(STAR) THEN A = A + 1
 RETURN
SIM2IM:
 FOR i = 1 TO 16: FOR j = 1 TO 16
  IM$(i, j) = SIM$(i, j)
 NEXT j, i: RETURN
SIM8IM:
 FOR i = yPos TO yPos + 7: FOR j = xPos TO xPos + 7
  IM$(i, j) = SIM$(i, j)
 NEXT j, i: RETURN
SetorDelBit:
 IF IM$(yCur, xCur) = CHR$(EMPTY) THEN IM$(yCur, xCur) = CHR$(STAR) ELSE IM$(yCur, xCur) = CHR$(EMPTY)
 CALL PutSymbol(2 + xCur, 1 + yCur, ASC(IM$(yCur, xCur)), LIGHTGREEN)
 IF mDouble THEN
  IF IM$(yCur, 17 - xCur) = CHR$(EMPTY) THEN IM$(yCur, 17 - xCur) = CHR$(STAR) ELSE IM$(yCur, 17 - xCur) = CHR$(EMPTY)
  CALL PutSymbol(2 + 17 - xCur, 1 + yCur, ASC(IM$(yCur, xCur)), LIGHTGREEN)
 END IF
 RETURN
SetBit:
 IM$(yCur, xCur) = CHR$(STAR)
 CALL PutSymbol(2 + xCur, 1 + yCur, ASC(IM$(yCur, xCur)), LIGHTGREEN)
 IF mDouble THEN
  IM$(yCur, 17 - xCur) = CHR$(STAR)
  CALL PutSymbol(2 + 17 - xCur, 1 + yCur, ASC(IM$(yCur, xCur)), LIGHTGREEN)
 END IF
 RETURN
LocSym:
     IF xCur < 9 THEN xPos = 1 ELSE xPos = 9
     IF yCur < 9 THEN yPos = 1 ELSE yPos = 9
     RETURN
iSAVE:
 DEF SEG = &H7000
 BSAVE "SIM.DAT", 0, 1024
 DEF SEG : RETURN
iPRINT:
 FOR i = 1 TO 16: FOR j = 1 TO 16
  CALL PutSymbol(2 + j, 1 + i, ASC(IM$(i, j)), LIGHTGREEN)
 NEXT j, i
 RETURN
BYNtoSTR:
 t = xPos
 FOR N = 7 TO 0 STEP -1
  IF BYN - 2 ^ N < 0 THEN IM$(yPos, t) = CHR$(EMPTY) ELSE IM$(yPos, t) = CHR$(STAR): BYN = BYN - 2 ^ N
  t = t + 1
 NEXT N
 RETURN
StrtoBYN:
 BYN = 0
 FOR N = 8 TO 1 STEP -1
  IF IM$(yPos, xPos + N - 1) <> CHR$(EMPTY) THEN BYN = BYN + 1 * 2 ^ (9 - N - 1)
 NEXT N
 RETURN
iGET:
 GOSUB PrintLittleOnes
 ADRESS = (cSym - 128) * 8
 DEF SEG = &H7000
 xPos = 1: yPos = 1: GOSUB PreobHEX
 xPos = 9: yPos = 1: GOSUB PreobHEX
 xPos = 1: yPos = 9: GOSUB PreobHEX
 xPos = 9: yPos = 9: GOSUB PreobHEX
 DEF SEG : GOSUB iPRINT: RETURN
PreobHEX:
 FOR j = 1 TO 8
  BYN = PEEK(ADRESS)
  GOSUB BYNtoSTR
  ADRESS = ADRESS + 1: yPos = yPos + 1
 NEXT: RETURN
iPUT:
 ADRESS = (cSym - 128) * 8: DEF SEG = &H7000
 xPos = 1: yPos = 1: GOSUB PreobDec
 xPos = 9: yPos = 1: GOSUB PreobDec
 xPos = 1: yPos = 9: GOSUB PreobDec
 xPos = 9: yPos = 9: GOSUB PreobDec
 DEF SEG : GOSUB PrintLittleOnes
 RETURN
PreobDec:
 FOR i = 1 TO 8
  GOSUB StrtoBYN
  POKE ADRESS, BYN
  ADRESS = ADRESS + 1: yPos = yPos + 1
 NEXT: RETURN
PrintLittleOnes:
 CALL PutSymbol(21, 17, cSym, LIGHTMAGENTA)
 CALL PutSymbol(22, 17, cSym + 1, LIGHTMAGENTA)
 CALL PutSymbol(21, 18, cSym + 2, LIGHTMAGENTA)
 CALL PutSymbol(22, 18, cSym + 3, LIGHTMAGENTA)
 COLOR BLUE
 LOCATE 16, 24: PRINT USING "###"; cSym
 LOCATE 17, 24: PRINT USING "###"; cSym + 1
 LOCATE 18, 24: PRINT USING "###"; cSym + 2
 LOCATE 19, 24: PRINT USING "###"; cSym + 3
 RETURN
OpenIt:
 CALL Ramka(2, 1, 19, 18): CALL Ramka(20, 16, 23, 19): LOCATE 19, 3
 COLOR MAGENTA: PRINT "x="; : LOCATE 20, 3: PRINT "y=";
 RETURN
END SUB

SUB CreateWindow (lx, uy, rx, dy)
 CALL SaveScreen(lx, uy, rx, dy)
 CALL Ramka(lx, uy, rx, dy)
END SUB

SUB Editor
 CONST sCurs = 88
 Level = 1:  ExitFlag = 0: GOSUB iNEW: GOSUB OpenScreen
 GOSUB LoadLevel
 DO
  GOSUB PutStatusLine
  tSymbol = MAP(CurY, CurX): CALL PutSymbol(CurX, CurY, sCurs, 15)
  GOSUB LKPause
  CALL PutSymbol(CurX, CurY, tSymbol.Code, tSymbol.ATTR)
  IF A$ = "" THEN GOSUB LKPause
  IF A$ <> "" THEN GOSUB KeyDriver

 LOOP WHILE ExitFlag = 0
 EXIT SUB
iNEW:
 CurX = 1: CurY = 1
 FOR i = 1 TO 20: FOR j = 1 TO 40
  MAP(i, j).Code = 178: MAP(i, j).ATTR = 7
 NEXT j, i
 sUNIT = 178: aUNIT = WHITE: sDIR = 1: item = 1
 RETURN
LKPause:
 FOR i = 1 TO INT(SECOND / 4)
  A$ = INKEY$: IF A$ <> "" THEN EXIT FOR
 NEXT: RETURN
KeyDriver:
 IF LEN(A$) = 1 THEN
  SELECT CASE ASC(A$)
  CASE Enter: GOSUB Set1Unit
  CASE 32:
   FOR i = 1 TO 5: GOSUB Set1Unit: NEXT
  CASE KTAB:
   FOR i = 1 TO 5: GOSUB ShiftCursor: NEXT
  CASE ESC: ExitFlag = 1
  CASE ELSE:
  END SELECT
 ELSE
  A = ASC(RIGHT$(A$, 1))
  SELECT CASE A
  CASE F2: GOSUB SaveLevel
  CASE F3: GOSUB LoadLevel
  CASE LEFT: IF CurX > 1 THEN CurX = CurX - 1
  CASE UP: IF CurY > 1 THEN CurY = CurY - 1
  CASE RIGHT: IF CurX < 40 THEN CurX = CurX + 1
  CASE DOWN: IF CurY < 20 THEN CurY = CurY + 1
  CASE F4: CALL GetSymbol(sUNIT, aUNIT)
  CASE F5: sDIR = sDIR + 1: IF sDIR > 4 THEN sDIR = 1
  CASE F6: CALL CreateSymbol: GOSUB OpenLevel
  CASE F10: GOSUB SaveLevel: ExitFlag = 1
  CASE F7: CALL SelectAttr(aUNIT)
  CASE F9:
     GOSUB iNEW: GOSUB OpenLevel
  CASE PGUP:
   IF Level > 1 THEN
    Level = Level - 1: GOSUB iNEW: GOSUB LoadLevel
   END IF
  CASE PGDWN:
   IF Level < 1030 THEN
    Level = Level + 1: GOSUB iNEW: GOSUB LoadLevel
   END IF
  CASE SHIFTF1 TO SHIFTF7:
   sUNIT = UNITSTOCK(A - SHIFTF0).Code
   aUNIT = UNITSTOCK(A - SHIFTF0).ATTR
  CASE SHIFTF10:
   sUNIT = 178: aUNIT = 7
  CASE SHIFTF8:
    Code = MAN: items = 7: GOSUB ChooseItem
  CASE SHIFTF9:
    Code = WEAPON: items = 5: IF item > 5 THEN item = 5
    GOSUB ChooseItem
  CASE CtrlF1 TO CtrlF3:
   IF CurX < 40 AND CurY < 20 THEN
    CALL PutBoss(CurX, CurY, BOSSSTOCK(A - CTRLF0).Code, BOSSSTOCK(A - CTRLF0).ATTR)
    CALL SetBoss(CurX, CurY, BOSSSTOCK(A - CTRLF0).Code, BOSSSTOCK(A - CTRLF0).ATTR)
   END IF
  CASE AltF1 TO AltF3:
   IF CurX < 40 AND CurY < 20 THEN
    CALL PutBoss(CurX, CurY, CARDSSTOCK(A - ALTF0).Code, CARDSSTOCK(A - ALTF0).ATTR)
    CALL SetBoss(CurX, CurY, CARDSSTOCK(A - ALTF0).Code, CARDSSTOCK(A - ALTF0).ATTR)
   END IF
  CASE ELSE:
  END SELECT
 END IF
 RETURN
Set1Unit:
 MAP(CurY, CurX).Code = sUNIT: MAP(CurY, CurX).ATTR = aUNIT
 CALL PutSymbol(CurX, CurY, sUNIT, aUNIT)
ShiftCursor:
 SELECT CASE sDIR
 CASE 1:
  IF CurX < 40 THEN
   CurX = CurX + 1
  ELSEIF CurY < 20 THEN
   CurX = 1: CurY = CurY + 1
  END IF
  CASE 2:
   IF CurY < 20 THEN
    CurY = CurY + 1
   ELSEIF CurX < 40 THEN
    CurY = 1: CurX = CurX + 1
   END IF
  CASE 3:
   IF CurX > 1 THEN
    CurX = CurX - 1
   ELSEIF CurY > 1 THEN
    CurX = 40: CurY = CurY - 1
   END IF
  CASE 4:
   IF CurY > 1 THEN
    CurY = CurY - 1
   ELSEIF CurX > 1 THEN
    CurY = 20: CurX = CurX - 1
   END IF
  END SELECT
  RETURN
SaveLevel:
 OPEN "LEVEL" + RIGHT$(STR$(Level), LEN(STR$(Level)) - 1) FOR OUTPUT AS #1
 FOR i = 1 TO 20: FOR j = 1 TO 40
  PRINT #1, MAP(i, j).Code
  PRINT #1, MAP(i, j).ATTR
 NEXT j, i
 CLOSE #1: RETURN
LoadLevel:
  IF ExistFile("LEVEL" + RIGHT$(STR$(Level), LEN(STR$(Level)) - 1)) THEN
  OPEN "LEVEL" + RIGHT$(STR$(Level), LEN(STR$(Level)) - 1) FOR INPUT AS #1
   FOR i = 1 TO 20: FOR j = 1 TO 40
    INPUT #1, MAP(i, j).Code
    INPUT #1, MAP(i, j).ATTR
   NEXT j, i
  CLOSE #1
 END IF: GOSUB OpenLevel
 RETURN
ChooseItem:
 uy = CurY - 1: IF uy < 1 THEN uy = 1
 IF uy + 2 > 20 THEN uy = 18
 ux = CurX - INT(items / 2)
 IF ux < 1 THEN ux = 1
 IF ux + items + 1 > 40 THEN ux = 40 - items - 1
 dy = uy + 2: dx = ux + items + 1
 CALL CreateWindow(ux, uy, dx, dy)
 FOR i = 1 TO items
  CALL PutSymbol(ux + i, uy + 1, Code, STOCKATTR(i))
 NEXT
 DO
  CALL PutSymbol(ux + item, uy + 1, Code, STOCKATTR(item) + 128)
  DO: A$ = INKEY$: LOOP WHILE A$ = ""
  CALL PutSymbol(ux + item, uy + 1, Code, STOCKATTR(item))
  IF LEN(A$) = 1 THEN
   IF ASC(A$) = Enter THEN
    sUNIT = Code: aUNIT = STOCKATTR(item)
    CALL CloseWindow(ux, uy, dx, dy)
    RETURN
   END IF
   IF ASC(A$) = ESC THEN CALL CloseWindow(ux, uy, dx, dy): RETURN
  ELSE
   IF ASC(RIGHT$(A$, 1)) = LEFT AND item > 1 THEN item = item - 1
   IF ASC(RIGHT$(A$, 1)) = RIGHT AND item < items THEN item = item + 1
  END IF
 LOOP
PutStatusLine:
 LOCATE 23, 1: COLOR 15
 PRINT USING "##"; CurY; : PRINT " "; USING "##"; CurX
 CALL PutSymbol(8, 23, sUNIT, aUNIT)
 CALL PutSymbol(13, 23, ARROW(sDIR), 15)
 LOCATE 23, 17: PRINT Level
 RETURN
OpenScreen:
 CALL RepeatSymbol(1, 21, UPLINE, 7, 40)
 CALL PutString(2, 22, "y x UNIT DIR LEVEL", CYAN)
 CALL PutString(1, 25, "2SAVE 3LOAD 5DIR 6CREATE 9NEW " + CHR$(TEN) + "SAVE&QUIT", MAGENTA)
 RETURN
OpenLevel:
 FOR i = 1 TO 20: FOR j = 1 TO 40
  CALL PutSymbol(j, i, MAP(i, j).Code, MAP(i, j).ATTR)
 NEXT j, i
 RETURN
END SUB

FUNCTION ExistFile (FileName$)
 DEF SEG = &H8000
 Byte = &HC2
 FOR i = 0 TO LEN(FileName$) - 1
  POKE Byte + i, ASC(MID$(FileName$, i + 1, 1))
 NEXT
 POKE Byte + i, 0
 CALL ABSOLUTE(&H8B)
 ExistFile = PEEK(&HC1)
 DEF SEG
END FUNCTION

SUB GetSymbol (Code, ATTR)
 CALL CreateWindow(7, 1, 16, 18)
 Clr = 15
 FOR i = 128 TO 255: GOSUB PutIt: NEXT
 IF Code > 127 THEN i = Code ELSE i = 128
 DO
  Clr = 15 + 128: GOSUB PutIt: Clr = 15: LOCATE 18, 13: PRINT USING "###"; i
  DO: A$ = INKEY$: LOOP WHILE A$ = ""
  IF i <> NSym THEN GOSUB PutIt
  IF LEN(A$) = 2 THEN
   SELECT CASE ASC(RIGHT$(A$, 1))
   CASE LEFT: IF i > 128 THEN i = i - 1
   CASE RIGHT: IF i < 255 THEN i = i + 1
   CASE UP: IF i - 8 > 127 THEN i = i - 8
   CASE DOWN: IF i + 8 < 256 THEN i = i + 8
   CASE INS:
      IF NSym = 0 THEN
       NSym = i
      ELSE
       Adress1 = (NSym - 128) * 8: Adress2 = (i - 128) * 8
       DEF SEG = &H7000
       FOR j = 0 TO 7
        A = PEEK(Adress1 + j): POKE Adress1 + j, PEEK(Adress2 + j)
        POKE Adress2 + j, A: NEXT: DEF SEG
        j = i: i = NSym: GOSUB PutIt: i = j: NSym = 0
      END IF
   CASE DEL:
    IF NSym = 0 THEN
     Adress1 = (i - 128) * 8: DEF SEG = &H7000
     FOR j = 0 TO 7
      POKE Adress1 + j, 0: NEXT
      DEF SEG : IF i < 255 THEN GOSUB PutIt: i = i + 1
    ELSE
      Adress1 = (NSym - 128) * 8: Adress2 = (i - 128) * 8
      DEF SEG = &H7000
      FOR j = 0 TO 7
       POKE Adress2 + j, PEEK(Adress1 + j)
      NEXT
      DEF SEG
      j = i: i = NSym: GOSUB PutIt: i = j: NSym = 0
    END IF
    CASE ELSE:
   END SELECT
  ELSE
   SELECT CASE ASC(A$)
   CASE ESC:
    CALL CloseWindow(7, 1, 16, 18): EXIT SUB
   CASE Enter:
    Code = i: CALL CloseWindow(7, 1, 16, 18)
    EXIT SUB
   CASE ELSE:
   END SELECT
  END IF
 LOOP
PutIt:
 CALL PutSymbol((i - 128) MOD 8 + 8, INT((i - 128) / 8) + 2, i, Clr)
 RETURN
END SUB

DEFSNG A-Z
SUB LoadTable
 DEF SEG = &H7000
 BLOAD "SIM.DAT", 0
 DEF SEG = &H8000
 BLOAD "man.lib", 0
 DEF SEG
END SUB

SUB PutBoss (x%, y%, Code%, ATTR%)
 CALL PutSymbol(x%, y%, Code%, ATTR%)
 CALL PutSymbol(x% + 1, y%, Code% + 1, ATTR%)
 CALL PutSymbol(x%, y% + 1, Code% + 2, ATTR%)
 CALL PutSymbol(x% + 1, y% + 1, Code% + 3, ATTR%)
END SUB

SUB PutString (x%, y%, S1$, ATTR%)
 FOR i% = 1 TO LEN(S1$)
  CALL PutSymbol(x%, y%, ASC(MID$(S1$, i%, 1)), ATTR%)
  x% = x% + 1
 NEXT
END SUB

SUB PutSymbol (x%, y%, Code%, ATTR%)
 DEFINT A-Z
 IF Code < 128 THEN LOCATE y, x: COLOR ATTR: PRINT CHR$(Code); : EXIT SUB
 DEF SEG = &H8000
 POKE &H86, x: POKE &H87, y: POKE &H88, Code
 IF ATTR% > 128 THEN ATTR% = ATTR% - 128: POKE &H89, 3 ELSE POKE &H89, 0
 POKE &H8A, ATTR
 CALL ABSOLUTE(0)
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

DEFSNG A-Z
SUB RepeatSymbol (x%, y%, Code%, ATTR%, number%)
 DEFINT A-Z
 FOR i = 0 TO number - 1
  CALL PutSymbol(x + i, y, Code, ATTR)
 NEXT
END SUB

SUB RestoreScreen (xl, yu, xr, yd)
 t = 1
 FOR i = yu TO yd
  FOR j = xl TO xr
    CALL PutSymbol(j, i, EKR(t).Code, EKR(t).ATTR): t = t + 1
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

SUB SelectAttr (A)
 CALL CreateWindow(7, 1, 16, 18)
 Code = EMPTY
 FOR i = 128 TO 255
  GOSUB PutIt1
 NEXT
 IF A < 128 THEN i = 128 + A ELSE i = 128
 DO
  Code = STAR: GOSUB PutIt1
  LOCATE 18, 13: COLOR 15: PRINT USING "###"; i - 128
  DO: A$ = INKEY$: LOOP WHILE A$ = ""
  Code = EMPTY: GOSUB PutIt1
  IF LEN(A$) = 2 THEN
  SELECT CASE ASC(RIGHT$(A$, 1))
  CASE LEFT: IF i > 128 THEN i = i - 1
  CASE RIGHT: IF i < 255 THEN i = i + 1
  CASE DOWN: IF i + 8 < 256 THEN i = i + 8
  CASE UP: IF i - 8 > 127 THEN i = i - 8
  CASE ELSE:
  END SELECT
  ELSE
   SELECT CASE ASC(A$)
   CASE ESC: CALL CloseWindow(7, 1, 16, 18)
           EXIT SUB
   CASE Enter: A = i - 128: CALL CloseWindow(7, 1, 16, 18): EXIT SUB
   CASE ELSE:
   END SELECT
  END IF
  LOOP
PutIt1:
   i1 = i
   CALL PutSymbol((i - 128) MOD 8 + 8, INT((i - 128) / 8) + 2, Code, i1)
   RETURN
END SUB

SUB SetBoss (x, y, Code, ATTR)
 MAP(y, x).Code = Code
 MAP(y, x).ATTR = ATTR
 MAP(y, x + 1).Code = Code + 1
 MAP(y, x + 1).ATTR = ATTR
 MAP(y + 1, x).Code = Code + 2
 MAP(y + 1, x).ATTR = ATTR
 MAP(y + 1, x + 1).Code = Code + 3
 MAP(y + 1, x + 1).ATTR = ATTR
END SUB

