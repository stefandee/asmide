data segment byte
	msg db 'Transmission over a serial line',0
	mlen equ $-msg
data ends	
code segment byte
	assume cs:code,es:data

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

	mov al,00001011b ;seteaza parametrii transm - 
	mov dx,3fbh
	out dx,al
	
	mov ax,data
	mov ds,ax
	xor si,si
loop1:

	mov dx,3fdh
waitc:	in al,dx
	and al,32
	jz waitc

	lodsb
	cmp al,0
	je theend
		
	mov dx,3f8h
	out dx,al
	jmp loop1
theend :
	mov ax,04c00h
	int 21h
code ends
end start