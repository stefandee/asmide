P8086          ;select the processor
MODEL TINY     ;always must be TINY model

CODESEG        ;this marks the start of executable code
   STARTUPCODE
   ;COM has all available memory allocated to it
   XOR AX,AX
   MOV DS,AX	
   MOV SI,417h	
   ;reset keyboard flags
   MOV AL,70h
   NOT AL
   AND [SI],AL	 
   ;reset leds
   MOV DL,0
   CALL LEDS

   MOV CX,0FFFFH
DL0: LOOP DL0	   
   mov bx,20h

EFFECT :
   ;TURN ON NUMLOCK
   mov dl,2
   call leds
   OR  byte ptr [SI],20H
   call CXWAIT
   ;TURN OFF NUMLOCK
   MOV AL,20H
   NOT AL
   AND [SI],AL
   mov dl,0
   call leds
   
   OR byte ptr [SI],40H
   call CXWAIT
   MOV AL,40H
   NOT AL
   AND [SI],AL

   OR byte ptr [SI],10H
   call CXWAIT
   MOV AL,10H
   NOT AL
   AND [SI],AL

   DEC BX
   JNZ EFFECT  

   ;Exit to DOS when complete
   MOV AH,4CH     
   INT 21H

LEDS PROC
   MOV AL,0EDH
   OUT 64H,AL
   MOV CX,0FFFFH
DELAY : LOOP DELAY
   MOV AL,DL
   OUT 64H,AL
   RET
ENDP LEDS

CXWAIT proc
   mov cx,05h	
dl1 :
    push cx
    mov cx,0ffffh
dl11: loop dl11
    pop cx
    loop dl1	 
    ret
endp CXWAIT

END
