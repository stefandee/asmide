codes segment byte
.386
assume cs:codes

org 100h

start :
	mov cx,4000
	rep stosd
	rep stosw
	rep stosb
	rep movsd
	rep movsw		
	rep movsb
	mov ax,4c00h
	int 21h
codes ends
	end start	
