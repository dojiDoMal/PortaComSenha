	    org 0000h
	
RS   	Equ  	P1.3
E	    Equ     P1.2
        ajmp inicio
            
;----------------------------Interrupcao Externa-----------------------------            
        org 0003h
        jnb B.0, liga
        clr B.0
		call Clear
		setb RS
        mov DPTR, #ESP2
        call Escreve
        setb RS
        mov DPTR, #LUT1
        call Escreve
        reti
liga:   setb B.0
        call ModoManual
        reti
;------------------------------------------------------------------------------

inicio:
; ---------------------------------- Main -------------------------------------
        mov R5, 00h
        mov A, #10000001b
        mov IE, A
        mov A, #0h
        mov IP, A
        mov A, #01h
        mov TCON, A

Main:	mov R2, 00h
		mov R3, 00h
		mov R4, 00h
		clr RS		   		; RS=0 - Instruction register is selected. 
;-------------------------- Instructions Code ---------------------------------
		call FuncSet		; Function set (4-bit mode)
	
		call DispCon		; Turn display and cusor on/off 
			
		call EntryMode		; Entry mode set - shift cursor to the right
			
		setb RS
		mov DPTR, #LUT1
		call Escreve
		clr RS
;----------------------------- Scan for the keys -------------------------------		
Next:		call ScanKeyPad
repete: nop
        jb B.0, repete
	    setB RS				; RS=1 - Data register is selected. 
		clr A
		mov A,R7
		
		cjne R2, #00h, Dig2 
	    mov R2, A
	    jmp Send
	 
Dig2:   cjne R3, #00h, Dig3 
        mov R3, A
        jmp Send
            
Dig3:   cjne R4, #00h, Send
        mov R4, A
			
Send:   mov A, #'*'
        call SendChar		;Display the key that is pressed.
		cjne R4, #00h, EndHere
		jmp Next
		            
EndHere:	call Clear
            setb RS
            cjne R2, #31h, Erro
            cjne R3, #32h, Erro
            cjne R4, #33h, Erro
            mov DPTR, #LUT2
            call Escreve
            setb RS
            mov DPTR, #LUT4
            call Escreve
            call LEDS           
            clr P2.2            ;Acende led verde indicando que acertou a senha
            jmp $
;------------------------------- Fim do Main ----------------------------------
;-------------------------------- Subrotinas ----------------------------------				
; ------------------------- Function set --------------------------------------
FuncSet:	clr  P1.7		
			clr  P1.6		
			setb P1.5		; | bit 5=1
			clr  P1.4		; | (DB4)DL=0 - puts LCD module into 4-bit mode 
	
			call Pulse

			call Delay		; wait for BF to clear

			call Pulse
							
			setb P1.7		; P1.7=1 (N) - 2 lines 
			clr  P1.6
			clr  P1.5
			clr  P1.4
			
			call Pulse
			
			call Delay
			ret
;------------------------------------------------------------------------------
;------------------------------- Display on/off control -----------------------
; The display is turned on, the cursor is turned on
DispCon:	clr P1.7		; |
			clr P1.6		; |
			clr P1.5		; |
			clr P1.4		; | high nibble set (0H - hex)

			call Pulse

			setb P1.7		; |
			setb P1.6		; |Sets entire display ON
			setb P1.5		; |Cursor ON
			setb P1.4		; |Cursor blinking ON
			
			call Pulse

			call Delay		; wait for BF to clear	
			ret

;----------------------------- Entry mode set (4-bit mode) ----------------------
;    Set to increment the address by one and cursor shifted to the right
EntryMode:	clr P1.7		; |P1.7=0
			clr P1.6		; |P1.6=0
			clr P1.5		; |P1.5=0
			clr P1.4		; |P1.4=0

			call Pulse

			clr  P1.7		; |P1.7 = '0'
			setb P1.6		; |P1.6 = '1'
			setb P1.5		; |P1.5 = '1'
			clr  P1.4		; |P1.4 = '0'
 
			call Pulse

			call Delay		; wait for BF to clear
			ret
			
;-----------------------Rotina de quando erra a senha-----------------------------
Erro:       mov DPTR, #LUT3
            call Escreve
            call Delay
            call Clear
            setb RS
            mov DPTR, #ESP
            call Escreve
            inc R5
            cjne R5, #03H, pula ;se tiver errado tres vezes, precisa esperar
            call Clear
            call LEDS        
            clr P2.0       ;acende led vermelho indicando que errou
            setb RS 
            mov DPTR, #LUT5
            call Escreve
            mov R5, #0ADH   
volta:      mov R6, #0ADH   ;0ADh = 173d
chama:      call Timer      ;aprox 30000 ms de delay (30 s)
            djnz R6, chama
            djnz R5, volta
            mov R5, 00h
            call Clear
            setb RS
            mov DPTR, #ESP2
            call Escreve
            setb RS
            mov DPTR, #LUT1
            call Escreve
pula:       ljmp Main
;---------------------------Apaga todos os LEDS--------------------------------
LEDS:       mov A, #0ffh
            mov P2, A
            ret
;--------------------------Texto do Modo Manual---------------------------------
ModoManual: call Clear
            setb RS
            mov DPTR, #ESP2
            call Escreve
            setb RS
            mov DPTR, #LUT6
            call Escreve
            ret
;------------------------------Limpa o display-----------------------------------
Clear:  clr RS
        clr P1.7		; |P1.7=0
        clr P1.6		; |P1.6=0
        clr P1.5		; |P1.5=0
        clr P1.4		; |P1.4=0

	    call Pulse

	    clr  P1.7		; |P1.7 = '0'
	    clr P1.6		; |P1.6 = '0'
	    clr P1.5		; |P1.5 = '0'
	    setb  P1.4		; |P1.4 = '1'
 
	    call Pulse

	    call Delay		; wait for BF to clear
	    ret
;--------------------------Escreve e pula uma linha-------------------------------
Escreve:    clr A
	        movc A,@A+DPTR
	        jz NextLn
	        call SendChar
	        inc DPTR
	        jmp Escreve
			
NextLn:     call CursorPos
            ret
;--------------------------Move o cursor pro inicio-------------------------------			
CursorPos:	clr RS
		    setb P1.7		; Sets the DDRAM address
		    setb P1.6		; Set address. Address starts here - '1'
		    clr P1.5		; 									 '0'
		    clr P1.4		; 									 '0' 
							; high nibble
		    call Pulse

		    clr P1.7		; 									 '0'
		    clr P1.6		; 									 '0'
		    clr P1.5		; 									 '0'
		    clr P1.4		; 									 '0'
							; low nibble
							; Therefore address is 100 0000 or 40H
		    call Pulse

		    call Delay		; wait for BF to clear	
		    ret		
;--------------------------------------------------------------------------------			
;------------------------------------ Pulse --------------------------------------
Pulse:		setb E		; |*P1.2 is connected to 'E' pin of LCD module*
			clr  E		; | negative edge on E	
			ret
;---------------------------------------------------------------------------------
;-----------------------------Escreve o caractere no LCD--------------------------			
SendChar:	mov C, ACC.7		; |
		    mov P1.7, C			; |
		    mov C, ACC.6		; |
		    mov P1.6, C			; |
		    mov C, ACC.5		; |
		    mov P1.5, C			; |
		    mov C, ACC.4		; |
		    mov P1.4, C			; | high nibble set
		
		    call Pulse

		    mov C, ACC.3		; |
		    mov P1.7, C			; |
		    mov C, ACC.2		; |
		    mov P1.6, C			; |
		    mov C, ACC.1		; |
		    mov P1.5, C			; |
		    mov C, ACC.0		; |
		    mov P1.4, C			; | low nibble set

		    call Pulse

		    call Delay			; wait for BF to clear
			
		    mov R1,#55h
		    ret
;--------------------------------------------------------------------------------
;------------------------------------- Delay ------------------------------------			
Delay:		mov R0, #50
		    djnz R0, $
		    ret
;--------------------------------Carrega o timer---------------------------------
Timer:      mov TMOD, #01h      ;Timer 0 no modo 1 (16 bits)
            mov TH0, #0FCh      ;Carregado FC18h no timer para
            mov TL0, #018h      ;que ele conte 1 ms de tempo
            setb TR0            ;Liga o timer
LP:         jnb TF0, LP         ;loop até o tempo acabar
            clr TR0
            clr TF0
            ret
;-------------------------Rotina que le o teclado matricial-----------------------
ScanKeyPad:	clr P0.3			;Clear Row3
		call IDCode0		;call scan column subroutine
		setb P0.3			;Set Row 3
		jb F0,Done  		;If F0 is set, end scan 
						
			;Scan Row2
		clr P0.2			;Clear Row2
		call IDCode1		;call scan column subroutine
		setb P0.2			;Set Row 2
		jb F0,Done		 	;If F0 is set, end scan 						

			;Scan Row1
		clr P0.1			;Clear Row1
		call IDCode2		;call scan column subroutine
		setb P0.1			;Set Row 1
		jb F0,Done			;If F0 is set, end scan

			;Scan Row0			
		clr P0.0			;Clear Row0
		call IDCode3		;call scan column subroutine
		setb P0.0			;Set Row 0
		jb F0,Done			;If F0 is set, end scan 
													
		jmp ScanKeyPad		;Go back to scan Row3
							
Done:		clr F0		        ;Clear F0 flag before exit
		ret
;--------------------------------------------------------------------------------			
;-------------------------------- Para cada tecla -------------------------------
IDCode0:	jnb P0.4, KeyCode03	;If Col0 Row3 is cleared - key found
		jnb P0.5, KeyCode13	;If Col1 Row3 is cleared - key found
		jnb P0.6, KeyCode23	;If Col2 Row3 is cleared - key found
		ret					

KeyCode03:	SETB F0			;Key found - set F0
		mov R7,#'3'		;Code for '3'
		ret				

KeyCode13:	SETB F0			;Key found - set F0
		mov R7,#'2'		;Code for '2'
		ret				

KeyCode23:	SETB F0			;Key found - set F0
		mov R7,#'1'		;Code for '1'
		ret				

IDCode1:	jnb P0.4, KeyCode02	;If Col0 Row2 is cleared - key found
		jnb P0.5, KeyCode12	;If Col1 Row2 is cleared - key found
		jnb P0.6, KeyCode22	;If Col2 Row2 is cleared - key found
		ret					

KeyCode02:	SETB F0			;Key found - set F0
		mov R7,#'6'		;Code for '6'

		ret				

KeyCode12:	SETB F0			;Key found - set F0
		mov R7,#'5'		;Code for '5'
		ret				

KeyCode22:	SETB F0			;Key found - set F0
		mov R7,#'4'		;Code for '4'
		ret				

IDCode2:	jnb P0.4, KeyCode01	;If Col0 Row1 is cleared - key found
		jnb P0.5, KeyCode11	;If Col1 Row1 is cleared - key found
		jnb P0.6, KeyCode21	;If Col2 Row1 is cleared - key found
		ret					

KeyCode01:	SETB F0			;Key found - set F0
		mov R7,#'9'		;Code for '9'
		ret				

KeyCode11:	SETB F0			;Key found - set F0
		mov R7,#'8'		;Code for '8'
		ret				

KeyCode21:	SETB F0			;Key found - set F0
		mov R7,#'7'		;Code for '7'
		ret				

IDCode3:	jnb P0.4, KeyCode00	;If Col0 Row0 is cleared - key found
		jnb P0.5, KeyCode10	;If Col1 Row0 is cleared - key found
		jnb P0.6, KeyCode20	;If Col2 Row0 is cleared - key found
		ret					

KeyCode00:	SETB F0			;Key found - set F0
		mov R7,#'#'		;Code for '#' 
		ret				

KeyCode10:	SETB F0			;Key found - set F0
		mov R7,#'0'		;Code for '0'
		ret				

KeyCode20:	setb F0			;Key found - set F0
		mov R7,#'*'	   	;Code for '*' 
		ret		
						
;------------------------------ Look-Up Table (LUT) --------------------------------
			Org 0300h
LUT1:       DB 'D', 'i', 'g', 'i', 't', 'e', ' ', 'a', ' ', 'S', 'e', 'n', 'h', 'a', ':', 0
LUT2:       DB ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', 'S', 'e', 'n', 'h', 'a', ' ', 'C', 'o', 'r', 'r', 'e', 't', 'a', '!', 0
LUT3:       DB ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', 'S', 'e', 'n', 'h', 'a', ' ', 'I', 'n', 'v', 'a', 'l', 'i', 'd','a', 0
ESP:        DB ' ', ' ', ' ', ' ', ' ', ' ', ' ', 0
ESP2:       DB ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', 0
LUT4:       DB ' ', ' ', 'P', 'o', 'r', 't', 'a', ' ', 'A', 'b', 'e', 'r', 't', 'a', 0
LUT5:       DB ' ', 'E', 's', 'p', 'e', 'r', 'e', ' ', '3', '0', 's', 0
LUT6:       DB 'M', 'o', 'd', 'o', ' ', 'M', 'a', 'n', 'u', 'a', 'l', 0
;------------------------------------------------------------------------------------
Stop:	    Jmp $
	
	    End