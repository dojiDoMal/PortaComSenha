	    org 0000h
RS   	Equ  	P1.3	; P1.3 = RS
E	    Equ     P1.2	; P1.2 - E
        ajmp inicio
;----------------------------Interrupcao Externa------------------------------            
        org 0003h		; Vetor de interrupcao externa INT0
        jnb B.0, liga	; B.0 esta sendo usada como flag de
        clr B.0			; controle pra saber se foi apertado
		call Clear		; o switch 7 (P3.2) para interrupcao.
		setb RS         ; Caso B.0 = 0, ele chama a funcao 
        mov DPTR, #ESP2 ; ModoManual que escreve o texto 'Modo 
        call Escreve    ; Manual' no display, retorna e 
        setb RS			; entra no loop na linha 46 
        mov DPTR, #LUT1 ; Caso B.0 = 1, ele limpa esse bit  
        call Escreve    ; e sai do loop da linha 46
        reti
liga:   setb B.0
        call ModoManual
        reti
;------------------------------------------------------------------------------
; ---------------------------------- Main -------------------------------------
inicio: mov R5, 00h			; R5 e usado para contar quantas 
        mov A, #10000001b   ; vezes a senha foi digitada errada
        
		mov IE, A           ; inicio da configuracao da interrupcao
        mov A, #0h          ;
        mov IP, A           ;
        mov A, #01h         ;
        mov TCON, A         ; fim da configuracao da interrupcao

Main:	mov R2, 00h
		mov R3, 00h
		mov R4, 00h
		clr RS		   		; RS=0 - seleciona o registrador de instrucoes 
;-------------------------- Inicializacao do LCD -------------------------------
		call FuncSet		; Coloca o display no modo de 4 bits
		call DispCon		; Liga o display e o cursor 
		call EntryMode		; Move o cursor pra direita
			
		setb RS             ; RS=1 - seleciona o registrador de dados
		mov DPTR, #LUT1     ; para enviar o texto da LUT1 pro LCD
		call Escreve        ; Escreve a mensagem 'Digite a Senha:'
		clr RS
;--------------------------- Le o teclado matricial ----------------------------		
Next:	call ScanKeyPad     ; Chama a subrotina de ler o teclado
repete: nop                 ; Loop de espera do servico de interrupcao 
        jb B.0, repete      ;
	    
		setB RS				 
		clr A
		mov A,R7
		
		cjne R2, #00h, Dig2 ; Salva o primeiro numero digitado
	    mov R2, A           ; pelo usuário no registrador R2
	    jmp Send
	 
Dig2:   cjne R3, #00h, Dig3 ; Salva o segundo numero digitado
        mov R3, A           ; pelo usuário no registrador R3
        jmp Send
            
Dig3:   cjne R4, #00h, Send ; Salva o terceiro numero digitado
        mov R4, A           ; pelo usuário no registrador R4
			
Send:   mov A, #'*'
        call SendChar		; Escreve no display quando digitado
		cjne R4, #00h, EndHere
		jmp Next
		            
EndHere:	call Clear
            setb RS
            cjne R2, #31h, Erro ; Confere o primeiro digito da senha
            cjne R3, #32h, Erro ; Confere o segundo digito da senha
            cjne R4, #33h, Erro ; Confere o terceiro digito da senha
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
; ------------------------------ Function set ---------------------------------
FuncSet:	clr  P1.7		
			clr  P1.6		
			setb P1.5		
			clr  P1.4		; DL=0 - configura o LCD no modo 4 bits
	
			call Pulse      ; Pulso
			call Delay		; Espera
			call Pulse      ; Pulso
							
			setb P1.7		; Ativa o modo de duas linhas 
			clr  P1.6
			clr  P1.5
			clr  P1.4
			
			call Pulse      ; Pulso
			call Delay      ; Espera
			ret
;------------------------------------------------------------------------------
;------------------------------ Liga/Desliga o LCD ----------------------------
DispCon:	clr P1.7		
			clr P1.6		
			clr P1.5		
			clr P1.4		

			call Pulse      ; Pulso

			setb P1.7		
			setb P1.6		; Liga todo o display
			setb P1.5		; Liga o cursor
			setb P1.4		; Deixa o cursor piscando
			
			call Pulse      ; Pulso
			call Delay		; Espera	
			ret
;------------------------------------------------------------------
;------------------------- Modo de 4 bits -------------------------
EntryMode:	clr P1.7		
			clr P1.6		
			clr P1.5		
			clr P1.4		

			call Pulse      ; Pulso

			clr  P1.7		; Incrementa o endereço e deixa cursor a direita
			setb P1.6	
			setb P1.5		
			clr  P1.4		
 
			call Pulse      ; Pulso
			call Delay		; Espera
			ret
;---------------------------------------------------------------------------------
;---------------------------- Erra a senha 3 vezes -------------------------------
Erro:       mov DPTR, #LUT3     ; Mostra mensagem de 'Senha Invalida'
            call Escreve
            call Delay
            call Clear
            setb RS
            mov DPTR, #ESP
            call Escreve
            inc R5              ; Incrementa o contador de tentativas erradas
            cjne R5, #03H, pula ; se tiver errado tres vezes, precisa esperar
            call Clear
            call LEDS           
            clr P2.0            ; Acende led vermelho indicando que errou
            setb RS 
            mov DPTR, #LUT5     ; Mostra mensagem 'Espere 30s'
            call Escreve
            mov R5, #0ADH       ; Loop aninhado
volta:      mov R6, #0ADH       ; 0ADh = 173d
chama:      call Timer          ; Aprox 30000 ms de delay (30 s)
            djnz R6, chama
            djnz R5, volta
            mov R5, 00h
            call Clear
            setb RS
            mov DPTR, #ESP2
            call Escreve
            setb RS
            mov DPTR, #LUT1     ; Mostra mensagem 'Digite a senha:'
            call Escreve
pula:       ljmp Main
;-------------------------------------------------------------------------------
;---------------------------Apaga todos os LEDS---------------------------------
LEDS:       mov A, #0ffh
            mov P2, A
            ret
;-------------------------------------------------------------------------------
;--------------------------Texto do Modo Manual---------------------------------
ModoManual: call Clear
            setb RS
            mov DPTR, #ESP2
            call Escreve
            setb RS
            mov DPTR, #LUT6 ; Mostra mensagem 'Modo Manual'
            call Escreve
            ret
;-------------------------------------------------------------------------------
;-------------------------- Limpa o texto do display ---------------------------
Clear:  clr RS
        clr P1.7
        clr P1.6	
        clr P1.5	
        clr P1.4	

	    call Pulse		; Pulso

	    clr  P1.7		
	    clr P1.6		
	    clr P1.5		
	    setb  P1.4		
 
	    call Pulse      ; Pulso
	    call Delay		; Espera
	    ret
;---------------------------------------------------------------------------------
;------------------------- Escreve e pula uma linha ------------------------------
Escreve:    clr A
	        movc A,@A+DPTR  
	        jz NextLn
	        call SendChar
	        inc DPTR
	        jmp Escreve
NextLn:     call CursorPos
            ret
;---------------------------------------------------------------------------------
;------------------------- Move o cursor pro inicio ------------------------------			
CursorPos:	clr RS
		    setb P1.7		; Configura o endereco da DDRAM
		    setb P1.6		; Comeco do endereco '1'
		    clr P1.5		; 					 '0'
		    clr P1.4		; 					 '0' 
						 	
		    call Pulse      ; Pulso

		    clr P1.7		; 					 '0'
		    clr P1.6		; 					 '0'
		    clr P1.5		; 					 '0'
		    clr P1.4		; 					 '0'
							; Entao o endereco e 100 0000 (40H)
		    call Pulse		; Pulso
		    call Delay		; Espera	
		    ret		
;--------------------------------------------------------------------------------			
;------------------------------------ Pulso --------------------------------------
Pulse:		setb E		; E = P1.2
			clr  E		; Causa uma borda de descida	
			ret
;---------------------------------------------------------------------------------
;---------------------------- Escreve o caractere no LCD -------------------------			
SendChar:	mov C, ACC.7		
		    mov P1.7, C			
		    mov C, ACC.6		
		    mov P1.6, C			
		    mov C, ACC.5		
		    mov P1.5, C			
		    mov C, ACC.4		
		    mov P1.4, C			
		
		    call Pulse          ; Pulso

		    mov C, ACC.3		
		    mov P1.7, C			
		    mov C, ACC.2		
		    mov P1.6, C			
		    mov C, ACC.1		
		    mov P1.5, C			
		    mov C, ACC.0		
		    mov P1.4, C			 

		    call Pulse          ; Pulso
		    call Delay			; Espera
			
		    mov R1,#55h
		    ret
;--------------------------------------------------------------------------------
;------------------------------------- Delay ------------------------------------			
Delay:	mov R0, #50
		djnz R0, $
		ret
;--------------------------------------------------------------------------------
;------------------------------- Carrega o timer --------------------------------
Timer:  mov TMOD, #01h ; Timer 0 no modo 1 (16 bits)
    	mov TH0, #0FCh ; Carregado FC18h (64536) no timer
        mov TL0, #018h ; para que ele conte 1 ms de tempo
        setb TR0       ; Liga o timer
LP:     jnb TF0, LP    ; loop ate a contagem terminar
    	clr TR0
        clr TF0
        ret
;---------------------------------------------------------------------------------
;-------------------------- Leitura do teclado matricial -------------------------
ScanKeyPad:	clr P0.3			; Limpa a linha 3
			call IDCode0		; escaneia a coluna
			setb P0.3			; Liga a linha 3
			jb F0,Done  		; Se F0=1 para de escanear 
						
			clr P0.2			; Limpa a linha 2
			call IDCode1		; escaneia a coluna
			setb P0.2			; Liga a linha 2
			jb F0,Done		 	; Se F0=1 para de escanear						

			clr P0.1			; Limpa a linha 1
			call IDCode2		; escaneia a coluna
			setb P0.1			; Liga a linha 1
			jb F0,Done			; Se F0=1 para de escanear
		
			clr P0.0			; Limpa a linha 1 0
			call IDCode3		; escaneia a coluna
			setb P0.0			; Liga a linha 1
			jb F0,Done			; Se F0=1 para de escanear
													
			jmp ScanKeyPad		; Continua escaneando

Done:		clr F0		        ; Limpa F0 antes de retornar
			ret
;--------------------------------------------------------------------------------			
;-------------------------------- Para cada tecla -------------------------------
IDCode0:	jnb P0.4, KeyCode03	; Se a Col0 Linha3 = 0, tecla foi pressionada
			jnb P0.5, KeyCode13	; Se a Col1 Linha3 = 0, tecla foi pressionada
			jnb P0.6, KeyCode23	; Se a Col2 Linha3 = 0, tecla foi pressionada
			ret					
KeyCode03:	setb F0			
			mov R7,#'3'		; Tecla '3'
			ret				
KeyCode13:	setb F0			
			mov R7,#'2'		; Tecla '2'
			ret				
KeyCode23:	setb F0			
			mov R7,#'1'		; Tecla '1
			ret				

IDCode1:	jnb P0.4, KeyCode02	; Se a Col0 Linha2 = 0, tecla foi pressionada 
			jnb P0.5, KeyCode12	; Se a Col1 Linha2 = 0, tecla foi pressionada 
			jnb P0.6, KeyCode22	; Se a Col2 Linha2 = 0, tecla foi pressionada 
			ret					
KeyCode02:	setb F0			
			mov R7,#'6'		; Tecla '6'
			ret				
KeyCode12:	setb F0			
			mov R7,#'5'		; Tecla '5'
			ret				
KeyCode22:	setb F0			
			mov R7,#'4'		; Tecla '4'
			ret				

IDCode2:	jnb P0.4, KeyCode01	; Se a Col0 Linha1 = 0, tecla foi pressionada 
			jnb P0.5, KeyCode11	; Se a Col1 Linha1 = 0, tecla foi pressionada 
			jnb P0.6, KeyCode21	; Se a Col2 Linha1 = 0, tecla foi pressionada 
			ret					
KeyCode01:	setb F0			
			mov R7,#'9'		; Tecla '9' 
			ret				
KeyCode11:	setb F0			
			mov R7,#'8'		; Tecla '8'
			ret				
KeyCode21:	setb F0			
			mov R7,#'7'		; Tecla '7'
			ret				

IDCode3:	jnb P0.4, KeyCode00	; Se a Col0 Linha0 = 0, tecla foi pressionada
			jnb P0.5, KeyCode10	; Se a Col1 Linha0 = 0, tecla foi pressionada 
			jnb P0.6, KeyCode20	; Se a Col2 Linha0 = 0, tecla foi pressionada 
			ret					
KeyCode00:	setb F0			
			mov R7,#'#'		; Tecla '#' 
			ret				
KeyCode10:	setb F0			
			mov R7,#'0'		; Tecla '0'
			ret				
KeyCode20:	setb F0			
			mov R7,#'*'	   	; Tecla '*' 
			ret		
;-----------------------------------------------------------------------------------	
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