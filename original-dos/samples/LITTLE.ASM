;**********************************
;** My first full assembler demo **
;***       386 users only !     ***
;**********************************

.MODEL Large
DOSSEG
.386
.STACK 200h

.DATA
sincos label word
	INCLUDE TRIGTAB.INC
xdata label word
	INCLUDE XDATA.INC
logo label byte 
	INCLUDE LOGO.INC
pro dw 2000 dup(0)
rot dw 8000 dup(0)
rotxy dw  0
rotyz dw  0
rotxz dw  0
incrxy dw 4
incrxz dw 2
tmpx   dw  0

z0     dw 300

.CODE
INCLUDE VGABASIC.INC

start :
        mov     bx,ss
        add     bx,200h/10h     ;get past the end of the file
        mov     [VSCR],bx  ;store the buffer segment
			   ;just a shit ! i coudn't find how the hell the mem
			   ;is allocated with 48h/21h
	call SetVga
	call SetPal

EscW  :	 
	call Cls
	call RotatePoints
	call Three2TwoD          ;into VSCR,of course!
	call DrawPoints
	call PutLogo
	call Flip

	mov dx,seg rotxy
	mov ds,dx
	
	mov ax,ds:[rotxy]
	add ax,ds:[incrxy]
	mov ds:[rotxy],ax	
	
	cmp ax,350
	jbe ver2
	mov ax,-4
	mov ds:[incrxy],ax
	jmp okincr
ver2    :
	cmp ax,5
	jae okincr
	mov ax,4
	mov ds:[incrxy],ax
okincr  :
	mov ax,ds:[rotxz]
	add ax,ds:[incrxz]
	mov ds:[rotxz],ax

	cmp ax,350
	jbe ver2p
	mov ax,-4
	mov ds:[incrxz],ax
	jmp okincr1
ver2p    :
	cmp ax,5
	jae okincr1
	mov ax,4
	mov ds:[incrxz],ax
okincr1  :
		
	in al,60h
	dec al                   ;is it soup yet !?           
	jne EscW
Exit  :
	call SetText

	mov ax,4c00h
	int 21h

RotatePoints proc

	xor si,si
	xor di,di
	mov dx,seg xdata
	mov ds,dx

rotloop :
        ;Y-AXIS ROTATION
        mov si,ds:[rotxz]
	shl si,1                   ;???????????????

	mov ax,ds:sincos[si]       ;ax=x
	mov dx,ds:xdata[di]
	imul dx                    ;ax=x*cos(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	mov cx,dx                ;in cx se tine rezultatul partial
	mov ax,ds:sincos[si+2]        ;ax=y
	mov dx,ds:xdata[di+4]
	imul dx	 ;ax=y*sin(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	add cx,dx               ;cx=x*cos+y*sin
        mov ds:rot[di],cx        ;store the rotated x in tmpx

	mov ax,ds:sincos[si]        ;ax=y
	mov dx,ds:xdata[di+4]
	imul dx     ;ax=y*cos(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	mov cx,dx                ;in cx se tine rezultatul partial
	mov ax,ds:sincos[si+2]        ;ax=x
	mov dx,ds:xdata[di]
	imul dx  	 ;ax=x*sin(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	sub cx,dx

        mov rot[di+4],cx        ;store the rotated y in xdata
        mov cx,ds:xdata[di+2]
        mov ds:rot[di+2],cx


        ;Z-Axis Rotation
        mov si,ds:[rotxy]
	shl si,1                   ;???????????????

	mov ax,ds:sincos[si]       ;ax=x
	mov dx,ds:rot[di]
	imul dx                    ;ax=x*cos(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	mov cx,dx                ;in cx se tine rezultatul partial

	mov ax,ds:sincos[si+2]        ;ax=y
	mov dx,ds:rot[di+2]
	imul dx	                 ;ax=y*sin(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	add cx,dx               ;cx=x*cos+y*sin
        mov ds:[tmpx],cx        ;store the rotated x in tmpx

	mov ax,ds:sincos[si]        ;ax=y
	mov dx,ds:rot[di+2]
	imul dx     ;ax=y*cos(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	mov cx,dx                ;in cx se tine rezultatul partial
	mov ax,ds:sincos[si+2]        ;ax=x
	mov dx,ds:rot[di]
	imul dx  	 ;ax=x*sin(t)
        sal ax,1
        rcl dx,1
        sal ax,1
        rcl dx,1
	sub cx,dx

        mov ds:rot[di+2],cx        ;store the rotated y in xdata
	mov cx,ds:[tmpx]
	mov ds:rot[di],cx

        add di,8
        cmp di,8000
        jb  rotloop
	ret
RotatePoints endp

Three2TwoD      PROC

        xor si,si
        xor di,di
        mov dx,seg xdata
        mov ds,dx
        mov dx,seg pro
        mov fs,dx

t2dloop :
	mov  bx,ds:rot[si+4]
	add bx,[z0]
	or bx,bx
	jnz nxt
	inc bx
nxt :
	mov     ax,ds:rot[si+2]           ;get y-value
	imul word ptr [z0]
	idiv    bx
	mov     fs:pro[di+2],ax

	mov     ax,ds:rot[si]             ;get x-value
	imul word ptr [z0]
	idiv    bx
	mov     fs:pro[di],ax

        add si,8
        add di,4
        cmp si,8000
        jb t2dloop

	ret

Three2TwoD      ENDP

DrawPoints proc
	xor si,si
	xor di,di
        mov dx,seg pro
	mov ds,dx

drawloop:

	mov bx,ds:pro[si]
	add bx,160
	mov cx,ds:pro[si+2]
	add cx,100
	mov al,byte ptr ds:xdata[di+6]

	push di
	call PUTPIXEL
	pop di

 	add si,4
	add di,8
	cmp di,8000
	jb drawloop

	ret
DrawPoints endp

PutLogo proc
	mov es,[VSCR]	
	mov di,52800
	mov dx,seg logo
	mov ds,dx
	mov si,offset logo
	mov cx,2720	
	rep movsd
	ret
PutLogo endp
	
end start

