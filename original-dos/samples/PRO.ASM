.286P

seg_desc struc      ;structura tabelei descriptorilor
        limit dw 0
        bazal dw 0
        bazah db 0
        acces db 0
              dw 0
seg_desc ends              

data segment

       gdt label word
       ds_desc seg_desc<ds_len,0,0,acces_date,>    ;definire tabela descriptori
       cs_desc seg_desc<cs_len,0,0,acces_code,>   
       mem_desc seg_desc<mem_len,0,0bh,acces_date,>

 
ds_len equ $-gdt

mem_len equ 4096 
acces_date  equ 093h 
acces_code  equ 09bh
mesaj db 'Mesaj din modul protejat !$'

data ends

code segment

jmpfar macro dest_off,dest_seg
      db 0eah
      dw offset dest_off
      dw dest_seg
endm     

_lgdt_ macro tabel
	local $1,$2	;incarca adresa de inceput a tabelei descrt.
	db 0fh
$1	label byte
	mov dx,word ptr tabel
$2	label byte
	org offset $1
	db 01h
	org offset $2
	endm	

       assume ds:data, cs:code
start: 

	; setari initiale - adr de jmp dupa intrare in PM
	  mov al,0fh
	  out 70h,al
	  mov al,5
	  out 71h,al

	  xor dx,dx
	  mov es,dx
	  mov di,0467h
	  mov ax,code
	  mov es:[di+2],ax
	  mov ax,offset tratare
	  mov es:[di],ax
       
       mov ax,data
       mov ds,ax	
       ;dezacivare intr
          cli
       ;constructie tabela descriptori           
          mov ax,ds
	  mov bx,ax
	  shr bx,12 	
          shl ax,4
          add ax,offset data
          adc bx,0
          mov ds_desc.bazah,bl
          mov ds_desc.bazal,ax 

          mov ax,cs
	  mov bx,ax
	  shr bx,12 	
          mov cl,4
          shl ax,cl
          add ax,offset start
          adc bx,0
          mov cs_desc.bazah,bl
          mov cs_desc.bazal,ax 
          
          _lgdt_ gdt

;          call activ20

          mov ax,01h	;setez bitul
	  lmsw ax	;trece in mod protejat
          		;incarca reg Status Word cu ax

          jmpfar prot,8		;prima instr. in mod protejat

;incarca  in cs indexul in T.D.
;goleste  coada de instructiuni adusa in procesor anticipat
  
prot:	  mov ax,16		;trece in mod invers video
	  mov ds,ax
	  mov es,ax
     	  mov cx,80*25
	  xor si,si
	  xor di,di

next_car: lodsw
	  xor ah,07fh
	  stosw		
	  loop next_car

          loop $
	  loop $
	  loop $

		
          mov al,0feh		;reset soft
          out 064h,al

stop:	  hlt			;asteapta reset de la keybd controler(8042)
          jmp stop

tratare:
	xor al,al
	out 21h,al
	out 0a1h,al
	sti
	mov ah,9
	mov dx,data
	mov ds,dx
	mov dx,offset mesaj
	int 21h
	mov ax,04c00h
	int 21h

activ20 	proc near
        	mov al,0d1h
        	out 064h,al
        	jmp $+2
        	mov al,0dfh
        	out 060h,al
        	jmp $+2
        	ret
activ20 endp 

cs_len equ $-start

code ends

end start 