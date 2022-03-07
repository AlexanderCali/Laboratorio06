; Archivo:	Laboratorio06.s
; Dispositivo:	PIC16F887
; Autor: Florencio Calí
; Compilador:	pic-as (v2.35), MPLABX V6.00
;                
; Programa:	implementar TIMER2  para un led intermitente a cada 500ms  junto a dos display que representen los segundos
; Hardware:	LEDs en el puert  PORTD
;
; Creado:	02 de marzo de 2022
; Última modificación: 05 de marzo de  2022
    
PROCESSOR 16F887
#include <xc.inc> 
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
  ;--------------Macros-----------------------------------------------------------
  REINICIAR_TMR0    MACRO	;Resetear timer0
    BANKSEL TMR0		;Selección del banco a utilizar
    MOVLW   0X1F		
    MOVWF   TMR0		;mover el valor a timer0
    BCF	    T0IF		;limpiar bandera de Timer0
    BANKSEL PORTA		;regreso al banco 0
    ENDM
    
REINICIAR_TMR1 MACRO
    BANKSEL	TMR1L
    MOVLW 0XC2			;valor byte superior
    MOVWF TMR1H			;cargar a byte superior
    MOVLW 0XF7			;valor para byte inferior
    MOVWF TMR1L			;carrgar a byte inferior
    BCF PIR1,0
    ENDM
    
RUTINA_BCD MACRO		;conversión de binario a decimal
    CLRF    DECENA		;limpio la variable decena
    CLRF    CENTENA		;limpio la variable centena
    CLRF    UNIDAD
    MOVF    CONTADOR, W		;paso el valor que quiero convertir, utilizando w
    MOVWF   UNIDAD		;muevo el valor a la variable -unidad-
    
BCD_0:				
    MOVLW   0X0A		;muevo el valor de 10 a w
    SUBWF   UNIDAD, W		;resto el valor de 10 a unidad y lo guardo en w
    BTFSS   STATUS, 0		;verifico el carry de status
    GOTO    BCD_Fin		;si el valor es 0 salta al final 
    
BCD_1:
    MOVWF UNIDAD		;regreso el valor a la unidad
    INCF  DECENA, F		;incremento en 1 el valor de las decenas
    MOVLW 0X0A			;nuevamente coloco 10 a W
    SUBWF DECENA, W		;resto el valor
    BTFSS STATUS, 0		;verifico el carry de status	
    GOTO BCD_0			;si el valor es 0 se vuelve negativo
    
    
BCD_2:
    CLRF DECENA			;limpio las decenas
    INCF CENTENA, F		;incremento centenas
    GOTO BCD_0			;vuelvo al inicio

BCD_Fin:			
    MOVF UNIDAD,W
    MOVWF UNIDAD_TEMP
    MOVF DECENA, W
    MOVWF DECENA_TEMP

    ENDM
;----------Variables temporales-------------------------------------------------
    
 PSECT udata_bank0        ;common memory - ---
    CONTADOR: DS 1
    UNIDAD_TEMP: DS 1
    DECENA_TEMP: DS 1
    ENABLE_DISPLAYS: DS 1
    DECENA: DS 1
    CENTENA: DS 1
    UNIDAD: DS 1

PSECT udata_shr
    W_TEMP:	    DS 1  ;guardo temporalmento el registro en interrupción
    STATUS_TEMP: DS 1	  ;guardo temporalmento el registro en interrupción
    
;---------Vector Reset----------------------------------------------------------
PSECT resVect, class=CODE, abs, delta=2
    ORG 00h			    ;posición 0000h para el reset
	resetVec:
	PAGESEL MAIN
	GOTO MAIN

PSECT intVect, class=CODE, abs, delta=2
	ORG 04h

	
ALMACENAR_REGISTROS:	    ;aqui comienza la interrupción
    MOVWF W_TEMP
    SWAPF STATUS, W	    ;almacena registros en variables temporales	    
    MOVWF STATUS_TEMP
;-------------------------TIMER0------------------------------------------------
EJECUTAR_INTERRUPCION:
    BTFSS INTCON, 2
    GOTO INTERRUPCION_TIMER1	 ;En caso de no estar activada la bandera vamos a interrupción de PORTB
    MOVLW 0X03
    XORWF PORTE			 ;aplico  XOR para realizar el multiplexado
    CLRF PORTC
    REINICIAR_TMR0
   
    
;-------------------------TIMER1------------------------------------------------    
INTERRUPCION_TIMER1:
    BTFSS  PIR1, 0		;Verificar bandera
    GOTO INTERRUPCION_TIMER2
    MOVLW 0X01
    ADDWF CONTADOR		;aumenta el valor del contador 
    REINICIAR_TMR1
    
;-------------------------TIMER2------------------------------------------------
INTERRUPCION_TIMER2:
    BTFSS PIR1, 1		;verificar bandera
    GOTO RESTAURAR_REGISTROS
    MOVLW 0X01
    XORWF PORTA			;enciendo el LED
    XORWF ENABLE_DISPLAYS	;Se enciende  y se apagan los display 
    BCF PIR1,1			;limpio bandera
    
    
RESTAURAR_REGISTROS:
    SWAPF STATUS_TEMP, W	;Recupero los registros sin modificar las banderas
    MOVWF STATUS		
    SWAPF W_TEMP, 1
    SWAPF W_TEMP, W
    RETFIE			;salgo de la interrupción
    
PSECT code, delta=2, abs
 ORG 100h

TABLAS:
    CLRF PCLATH 
    BSF  PCLATH, 0
    ADDWF PCL 
    
    retlw       00111111B   ;0
    retlw       00000110B   ;1
    retlw       01011011B   ;2
    retlw       01001111B   ;3
    retlw       01100110B   ;4
    retlw       01101101B   ;5
    retlw       01111101B   ;6
    retlw       00000111B   ;7
    retlw       01111111B   ;8
    retlw       01101111B   ;9

CONFIGURAR_IO:
    BANKSEL ANSEL	    ;salida digital
    CLRF ANSEL		    ;salida digital
    CLRF ANSELH
    
    BANKSEL TRISA
    CLRF TRISA		    ;salida para configurar el tiempo de los displays
    CLRF TRISC
    CLRF TRISE
    
    BANKSEL PORTA
    CLRF PORTA              ;limpian los puertos
    CLRF PORTC
    CLRF PORTE
    RETURN
   
CONFIGURAR_INTERRUPCIONES:
    BANKSEL INTCON
    BSF INTCON, 7
    BSF INTCON, 5	    ;Habilita interrupción TMR0
    BSF INTCON, 2	    ;bandera del TMR0
    BSF INTCON, 6	    ;Se habilita  -peripherial interrupt- para TMR1 y TMR2
    BANKSEL PIE1
    BSF PIE1, 0		    ;TMR1 OVERFLOW INTERRUPT
    BSF PIE1, 1		    ;TMR2 OVERFLOW INTERRUPT
    BANKSEL PORTA
    RETURN

CONFIGURAR_RELOJ:		;configuración del oscilador interno
    BANKSEL OSCCON		;configuración a 500khz
    BCF OSCCON, 6
    BSF OSCCON, 5
    BSF OSCCON, 4 
    BCF SCS 
    BANKSEL PORTA
    RETURN
    
CONFIGURAR_TMR0:
    BANKSEL TRISA	    ;voy al banco 1
    BCF T0CS		    ;configuración de - Fosc/4-
    BCF PSA		    ;asigno el prescaler al Timer0
    BCF PS2 
    BCF PS1		    ;configuro el prescaler a 1:2
    BCF PS0
    BANKSEL PORTA 
    REINICIAR_TMR0	    ;reinicio el timer0
    RETURN 

CONFIGURAR_TMR1:
    BANKSEL T1CON	    ;prescaler
    BSF T1CON, 5
    BSF T1CON, 4
    BCF T1CON, 1
    BSF T1CON, 0
    BANKSEL PORTA
    REINICIAR_TMR1
    RETURN
    
CONFIGURAR_TMMR2:	    ;prescaler
    BANKSEL T2CON
    BSF	T2CON,1
    BSF	T2CON,0
    BSF	T2CON,6
    BSF	T2CON,5
    BSF	T2CON,4
    BSF	T2CON,3
    BSF	T2CON,2
    MOVLW 150 ;150
    MOVWF PR2
    BCF PIR1, 1
    RETURN
   
;--------------- MAIN PRINCIPAL-------------------------------------------------    
MAIN:
    CALL CONFIGURAR_IO
    CALL CONFIGURAR_INTERRUPCIONES
    CALL CONFIGURAR_RELOJ
    CALL CONFIGURAR_TMR0
    CALL CONFIGURAR_TMR1
    CALL CONFIGURAR_TMMR2
    MOVLW 0X01
    MOVWF PORTE				;VALOR INICIAL
    
LOOP:
    RUTINA_BCD				;conversión de binario a decimal
    
    BTFSS ENABLE_DISPLAYS, 0		;se ejecuta esta instrucción si el enable esta encendido
    GOTO APAGAR_DISPLAYS		;se ejecuta esta instrucción si el enable esta apagado
    BTFSC PORTE, 0
    CALL DISPLAY1
    BTFSC PORTE, 1
    CALL DISPLAY2
    GOTO LOOP
    
APAGAR_DISPLAYS:
    CLRF PORTC 
    GOTO LOOP

DISPLAY1:			;representa el valor de decenas
    MOVF DECENA_TEMP, W
    CALL TABLAS
    MOVWF PORTC
    RETURN
    
DISPLAY2:			;representa el valor para las unidades
    MOVF UNIDAD_TEMP,W
    CALL TABLAS
    MOVWF PORTC
    RETURN
END
    
    
    
    
  
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    