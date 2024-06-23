.model tiny
.386

.data
 failed db 'This processor does not support cpuid.$'
 undef db 'Unable to give a serious result.$'
 ok db 'Your cpu is an '
 id1 dd ?
 id2 dd ?
 id3 dd ?
 endchar db '.$'  

.code 
	assume cs:@code, ds:@data
	mov dx,@data
	mov ds,dx

	PUSHFD
	POP EAX
	OR  EAX,0000000100000000000000000000b
	PUSH EAX
	POPFD
	AND  EAX,0000000100000000000000000000b
	JZ CPUIDFAILED

	xor eax,eax
	;this is cpuid
	db 0fh,0a2h
	nop
	nop
	nop
	nop

	cmp eax,1
	je cpuidinfo
	
	lea dx,undef
	mov ah,9
	int 21h
	jmp theend

cpuidinfo:
        mov ds:[id1],ebx
	mov ds:[id2],edx
	mov ds:[id3],ecx
	mov ah,9
	lea dx,ok
	mov ah,9
	int 21h
	jmp theend

CPUIDFAILED:
	lea DX,failed
	MOV AH,9
	INT 21H	

theend:
	MOV AH,4CH
   	INT 21H
END
