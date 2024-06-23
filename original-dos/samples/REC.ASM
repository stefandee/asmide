code segment byte
	assume cs:code

start:
	mov al,80h    ;seteaza baud-rate
	mov dx,3fbh
	out dx,al
	mov dx,3f8h
	mov al,12
	out dx,al
	inc dx
	xor al,al
	out dx,al

	mov al,00001011b ;seteaza parametrii rec - 
	mov dx,3fbh
	out dx,al
	
loop1:	mov dx,3fdh
waitc:	in al,dx
	and al,1
	jz waitc

	mov dx,3f8h
	in al,dx
	mov dl,al
	mov ah,2
	int 21h
	
	in al,60h
	dec al
	jnz loop1
theend :
	mov ax,04c00h
	int 21h
code ends
end start