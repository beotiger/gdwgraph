;name BASES NOT GASES, A RASES NOT TO MASES!
.model small
;.code

CODE segment
org 0
assume ds: CODE
assume cs: CODE

Start:
  push ds
  push cs
  pop ds
  mov al, POSX
  mov ah, 0
  dec al
  shl ax, 3
  xchg ax, cx
  mov dl, POSY
  dec dl
  mov dh, 0
  shl dx, 3
  mov ax, 320
  mul dx
  add ax, cx
  xchg ax, di
  mov ax,0a000h
  mov es, ax
  mov al, adCODE
  sub al,128
  mov ah, 0
  shl ax, 3
  xchg ax, si
  mov ax,7000h
  mov ch, 8
  mov bh, adOP
  mov bl, adATTR
  mov ds, ax
  cld
PUTTER:
  lodsb
  mov cl, 8
  push di
PUTZER:
  shl al, 1
  jc @Putz
  
  cmp bh, 0
  jnz @p1
  mov byte ptr es:[di],0
  jmp short @Putz2
 @p1:
  cmp bh, 3
  jnz @putz2
  mov es:[di],bl
  jmp short @putz2
 
 @Putz:
  cmp bh, 3
  jz @p2
  mov es:[di],bl
  jmp @Putz2
 @p2:
  mov byte ptr es:[di],0
  
 @Putz2:
  inc di
  dec cl
  jnz PUTZER
  pop di
  add di, 320
  dec ch
  jnz PUTTER
  pop ds
  retf
;.DATA
 POSX   db ?
 POSY   db ?
 adCODE db ?
 adOP   db ?
 adATTR db ?

EXISTING:
  push ds
  push cs
  pop ds
  mov dx,offset ProgramName
  mov al, 0
  mov ah,3dh
  int 21h
  mov cl, 0
  jc @NO
  mov bx, ax
  mov ax,3e00h
  int 21h
  mov cl, -1
 @NO:
  mov cs:RESULT,cl
  pop ds
  retf

KEYCONTROLLER:
 mov ax,0100h
 int 16h
 mov bh, 0
 jz @NOKEY
 xor ax,ax
 int 16h
 mov bh, ah
@NOKEY:
 mov cs:SCANKEY,bh
 retf
SCANKEY DB ?
RESULT  DB ?

ProgramName DB ?,?,?,?,?,?,?,?,?,?,?,?,?,?,?
 
db 10 dup (?)
Width1 dw 0
Height dw 0

PutBigSymbol proc near
 
  push ds
  push cs
  pop ds
  mov al, POSX
  mov ah, 0
  dec al
  shl ax, 3
  xchg ax, cx
  mov dl, POSY
  dec dl
  mov dh, 0
  shl dx, 3
  mov ax, 320
  mul dx
  add ax, cx
  xchg ax, di
  mov ax,0a000h
  mov es, ax
  mov al, adCODE
  sub al,128
  mov ah, 0
  shl ax, 3
  xchg ax, si
  mov ax,7000h
  mov ch, 8
  mov bh, adOP
  mov bl, adATTR
  mov ds, ax
  cld
iPUTTER:
  push cs:Height
  @P0:
  mov al,ds:[si]
  mov cl, 8
  push di
@p4:
  shl al, 1
  push cs:Width1
@P6:
  pushF

  jc @iPutz
 
  cmp bh, 0
  jnz @ip1
  mov byte ptr es:[di],0
  jmp short @iPutz2
 @ip1:
  cmp bh, 3
  jnz @iputz2
  mov es:[di],bl
  jmp short @iPutz2

 @iPutz:
  cmp bh, 3
  jz @p12
  mov es:[di],bl
  jmp @iPutz2
 @p12:
  mov byte ptr es:[di],0
 

 @iPutz2:
  inc di
  popF
  dec cs:Width1
  jnz @P6
  pop cs:Width1

  dec cl
  jnz @p4
  pop di
  add di, 320
  dec cs:Height
  jnz @P0
  pop cs:Height
  inc si
  dec ch
  jnz iPUTTER
  pop ds
  retf
PutBigSymbol endp

CODE ends

;  .DATA
end Start

