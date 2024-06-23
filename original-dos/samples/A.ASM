data	segment
	new4a proc far
	mov al,0feh
	out 64h,al
	iret
	new4a endp
data	ends

code 	segment
	assume cs:code,ds:data,es:data

	outchar proc
	;
	;IN  : AL-BCD code
	;OUT : NONE
	;
	push ax
	
	mov ah,2	; set cursor (x,y)
	xor bh,bh
	int 10h

	mov cl,4
	pop ax
	push ax
	shr al,cl
	add al,'0'
	mov ah,0ah
	mov cx,1
	int 10h

	inc dl
	mov ah,2
	int 10h

	pop ax
	and al,15
	add al,'0'
	mov ah,0ah
	mov cx,1
	int 10h
	ret 
	outchar endp

start:
	mov al,2	; get current minute
	out 70h,al
	in  al,71h
	add al,1
	daa
	mov ah,al
	mov al,3
	out 70h,al	; set alarm minute crt_min+1 - no hour check
	mov al,ah
	out 71h,al

	mov al,4	; get current hour
	out 70h,al
	in  al,71h
	mov ah,al
	mov al,5
	out 70h,al	; set alarm hour = crt_hour
	mov al,ah
	out 71h,al

	mov ah,25h	; set 4ah hook
	mov al,4ah
	mov dx,data
	mov ds,dx
	mov dx,offset new4a	
	int 21h
	
	mov al,0bh	; enable alarm
	out 70h,al
	in  al,71h
	or  al,32
	mov ah,al
	mov al,0bh
	out 70h,al
	mov al,ah
	out 71h,al

waitalarm:
	mov dl,10
	mov dh,10

	mov al,4	; read curent hour
	out 70h,al
	in  al,71h
	call outchar

	add dl,2
	mov ah,2
	int 10h
	mov al,':'
	mov ah,0ah
	mov cx,1
	int 10h

	mov al,2	; read curent minute
	out 70h,al
	in  al,71h
	inc dl
	call outchar

	add dl,2
	mov ah,2
	int 10h
	mov al,':'
	mov ah,0ah
	mov cx,1
	int 10h

	mov al,0	; read curent second
	out 70h,al
	in  al,71h
	inc dl
	call outchar

	mov dl,10
	mov dh,11

	mov al,5	; read curent hour
	out 70h,al
	in  al,71h
	call outchar

	add dl,2
	mov ah,2
	int 10h
	mov al,':'
	mov ah,0ah
	mov cx,1
	int 10h

	mov al,3	; read curent minute
	out 70h,al
	in  al,71h
	inc dl
	call outchar

	add dl,2
	mov ah,2
	int 10h
	mov al,':'
	mov ah,0ah
	mov cx,1
	int 10h

	mov al,1	; read curent second
	out 70h,al
	in  al,71h
	inc dl
	call outchar

	in al,60h
	dec al
	jz theend	
	jmp waitalarm

theend:
	mov ax,04c00h
	int 21h

ends code
end start
			