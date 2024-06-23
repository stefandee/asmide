;*************************
;** BASIC VGA FUNCTIONS **
;*************************

VGA dw 0A000h
VSCR dw 0
LeftClip dw 5
RightClip dw 315
TopClip dw 5
BottClip dw 195

WorkPal label byte
        INCLUDE chroma.inc

SetColor MACRO Index,R,G,B
	mov dx,3c8h
	mov al,&Index
	out dx,al
	inc dx
	mov al,&r
	out dx,al
	mov al,&g
	out dx,al
	mov al,&b
	out dx,al
ENDM SetColor

;LoadPal proc
;	mov ax,03d02h
;	mov dx,seg chroma
;	mov ds,dx
;	mov dx,offset chroma
;	int 21h
;	jc error

;	mov bx,ax
;	mov cx,768
;	mov ah,3fh
;	mov dx,seg workpal
;	mov ds,dx
;	mov dx,offset workpal
;	int 21h
;	jc error
;error :
	;ret
;LoadPal endp

PutPixel proc
;input bx,cx=x,y
;al=color
	mov es,[VSCR]
	mov di,bx
	mov bx,cx
	shl bx,8
	shl cx,6
	add bx,cx
	add di,bx
	stosb
	ret
PutPixel endp

SetVga proc
	mov ax,13h
	int 10h
	ret
SetVga endp

SetText proc
	mov ax,3h
	int 10h
	ret
SetText endp

HLine proc
;input  bx,dx=x,y
;input  al=color,cx=lungime
;obs    se folosesc transferuri pe 32 de biti : stosd

	cmp dx,[BottClip]		;verificare  pe y
	ja done
	cmp dx,[TopClip]
	jb done
dothing :
	cld
	shr cx,1
	mov ah,al
	mov es,[VSCR]
	mov di,bx
	mov bx,dx
	shl dx,8
	shl bx,6
	add bx,dx
	add di,bx
	rep stosw
done    :
	ret
HLine endp

SetPal proc
;input none
;function set the workpal

        mov ax,seg workpal
        mov ds,ax
        mov si,offset workpal
        call WaitRetrace

        mov dx,3c8h
        mov al,0
        out dx,al
        inc dx
        mov cx,384
        rep outsb
        call WaitRetrace
        mov dx,3c8h
        mov al,128
        out dx,al
        inc dx
        mov cx,384
        rep outsb

        ret
SetPal endp

WaitRetrace proc
;input none
;function too obvious for those who knows
        mov dx,3DAh
l1:
        in al,dx
        and al,08h
        jnz l1
l2:
        in al,dx
        and al,08h
        jz  l2
        ret
WaitRetrace endp

Flip proc
	mov es,[VGA]
	mov ds,[VSCR]
	xor di,di
	xor si,si
	mov cx,16000
	rep movsd
	ret
FLip endp

Cls proc
	mov es,[VSCR]
	xor eax,eax
	mov cx,16000
	xor di,di
	rep stosd
	ret
Cls endp

