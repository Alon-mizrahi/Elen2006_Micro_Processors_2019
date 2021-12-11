;
; MicrosProject2019.asm
;
; Created: 2019/09/08 19:27:31
; Author : Alon Mizrahi
;student no.: 1405583
;

.include "./m328Pdef.inc"

.DEF temp= r16
.DEF Number = r17
.DEF modeCheck = r18 
.DEF StartGame = r19
;.DEF Time = r20 
.DEF round = r21
.DEF score = r22
.DEF distance = r23
.DEF distance2 = r24
.DEF ONE  = r28
.DEF ZERO = r29

;INTERRUPT VECTOR TABLE------------------------------------------------------------------------------------------------------
.org 0x0000
	rjmp reset

.org 0x0002 ;INT0 pinD2     use for sonic jmp to time calc pcint2
	rjmp Sonic0
.org 0x0004 ;INT1 pinD3     use for push button
	rjmp StartButton
.org 0x000A ;PCINT use for modeswap
	rjmp modeSwap
.org 0x0016 ;TIMER1 COMPA Timer/Counter1 Compare Match A
	rjmp timeClr1
.org 0x001C ;TIMER0 COMPA Timer/Counter0 Compare Match A
	rjmp timeClr0


;RESET---------------------------------------------------------------------------------------------------------------------
reset:
cli
	clr round
	clr temp
	clr distance
	clr distance2
	clr modeCheck
	clr StartGame
	clr number

	ldi score, 6
	ldi ONE, 1
	ldi ZERO, 0

;PORT SETUP-------------------------------------------------------------------
	ldi temp, 0b11111111
		out DDRB, temp   ;portb output for bcd display
	ldi temp, 0b00111111
		out DDRC, temp   ;portC set up for LEDS
	ldi temp, 0b01000000
		out DDRD, temp   ;portd set up for ints
		out portc,ZERO
		out portd, ZERO
;SET UP INTERRUPTS-----------------------------------------------------------------
	ldi temp, 0b00001110													;;check this if being wierd
	sts EICRA, temp			;int1 falling edge   int0 falling edge

	ldi temp, 0b00000010
	out EIMSK, temp			;enable int0 and int1

	ldi temp, 0b00000100
	sts PCICR, temp			;enable pcint2 23:16

	ldi temp, 0b01000000
	sts PCMSK2, temp		;enable pcint22 only PIND6


;SET UP TIMER0------------------------------------------------------------------------------------
	
		LDI temp,0b00000000     ;SET TO normal MODE 
	    OUT TCCR0A,temp
	
	    LDI temp,0b00000000    ;timer off set prescaler to 1 when start
	    OUT TCCR0B,temp

		LDI temp,0xFF           ;OUR COMPARE VALUE
		out OCR0A,temp          ;INTO THE COMPARE REGISTER

		ldi temp, 0b00000000    ;disable ocra interrupt
		sts TIMSK0,temp			;enable in sonic

;SET UP TIMER1----------------------------------------------------------------------------------
	; 16 bit timer used for random number gen
	
	ldi temp, 0b00000000	;com mode normal port operation
	sts TCCR1A, temp
		
	; timer 16 bit but only need 8, time stored in  TCNT1L
	
	ldi temp, 0b10001101	;clock off change ;sb to 101 to start
	sts TCCR1B, temp		;turn on in play mode	

	ldi temp, 255		;max value of rand gen number 0-8  ;can inc num for 1-9
	sts OCR1AL, temp

	ldi temp, 0b00000010 ;
	sts TIMSK1, temp ; ocr1aa inturrupt enable 



;--------------------------------------------------------------------------------------------
	ldi StartGame, 0
	ldi modeCheck,0

	ldi temp, 0b00000010
	out EIMSK, temp			; disable int0 and enable int1 only push button active not echo
	;main code
	main:
		sei
		out portb,ZERO
		rjmp main

;SWAP MODES---------------------------------------------------------------------------------------
modeSwap:
	out portc, ZERO
	out portb,ZERO
	ldi StartGame, 0
		ldi temp, 0b00000010
		out EIMSK, temp			; disable int0 and enable int1 only push button active not echo

	CPSE modeCheck, ONE ;if modecheck = 1 go to playmode else testmode
	rjmp testmode
	rjmp playmode

;TESTMODE-----------------------------------------------------------------------------------
testmode: ;modecheck= 0

	ldi modeCheck, 1

	in temp,portc
	ori temp,0b00100000
	out portc,temp

		ldi temp, 0b10001101	;turn timer1 off
		sts TCCR1B, temp
	
	sei

	CPSE StartGame, ONE
	rjmp testmode		;loop until button push
	
	in temp,portc      ;turn both leds on
	ori temp,0b00110000
	out portc,temp

	ldi temp, 0b00000010
	out EIMSK, temp			; disable int0 and enable int1 only push button active not echo

testmodeS:	;testmode ACTIVE-------------------------------
	sei


	rjmp Sonic
postSonicTest:

	out portb, distance2
			
	ldi  temp, 82 ;1 sec delay
    ldi  r25, 43
    ldi  r26, 0
onedel: 
	dec  r26
    brne onedel
    dec  r25
    brne onedel
    dec  temp
    brne onedel
    lpm
    nop


	rjmp testmodeS


;PLAYMODE-----------------------------------------------------------------------------------
playmode: ;modecheck =1
	ldi modeCheck, 0

	in temp,portc
	ori temp,0b00010000
	out portc,temp
	
	ldi round, 0
	ldi score, 6

	sei	
	
	;ldi temp, 0b10000101	;clock1 start
	;sts TCCR1B, temp

	CPSE StartGame, ONE
	rjmp playmode		;loop until button push

	ldi temp,0b00110000
	out portc,temp

	ldi temp, 0b00000010
	out EIMSK, temp			; disable int0 and enable int1 only push button active not echo

playmodeS:	;playmode ACTIVE------------------------------------

	CPI round, 6;if turns equal 6 jmp end round
	breq wait1	

	rjmp randGen		;go to randGen
postGen:
	inc number					;should have number
	out portb, Number					
	
	rjmp sonic			;go to sonic
postsonicPlay:						;compair
						;checkscore
	rjmp ScoreCheck

	rjmp playmodeS
	
;RANDOM NUMBER GEN------------------------------------------------------------------------------
randGen:
	lds number, TCNT1L
	andi number, 0b00001111
	
	cpi number,15
		breq rand15
	cpi number,14
		breq rand14
	cpi number,13
		breq rand13
	cpi number,12
		breq rand12
	cpi number,11
		breq rand11
	cpi number,10
		breq rand10
	cpi number,0
		breq rand0
	rjmp postGen

rand15:
lsr number
	rjmp postGen
rand14:
lsr number
	rjmp postGen
rand13:
lsr number
	rjmp postGen
rand12:
lsr number
	rjmp postGen
rand11:
lsr number
	rjmp postGen
rand10:
lsr number
	rjmp postGen
rand0:
inc number
	rjmp postGen

;TIMER1 OCR1A JMP----------------------------------------------------------------------
timeClr1:
	sts TCNT1L, ZERO
	reti

;START BUTTON INTERRUPT----------------------------------------------------------------------
StartButton:
	ldi StartGame, 1
	reti


	wait1:
		rjmp wait
;START OF SONIC-----------------------------------------------------------------
sonic:
	clr distance
	clr distance2
	out TCNT0, ZERO

	ldi temp, 0b00000001
	out EIMSK, temp			; disable int1 and enable int0
	cli

	cpse modeCheck, ONE ;test mode skips
		rjmp threeSecDelay ;play mode goes to delay before sonic active

postDel:

	out portc, ONE;pulse to trigg

	ldi  temp, 53
L1: dec  temp
    brne L1	
	
	ldi temp,0b00110000
	out portC, temp		;end pulse
	
	    LDI temp,0b00000001    ;SET PRESCALER TO /1 start timer
	    OUT TCCR0B,temp

		ldi temp, 0b00000010 ;enable ocra interupt
		sts TIMSK0,temp

	chill:
	sei
	rjmp chill


Sonic0:	
	cli
	;sei

	ldi temp, 0b00000000 ;disable ocra interupt
	sts TIMSK0,temp

	ldi temp, 0b00000000 ;   turns clock off     change cs 101 for pre scaler of 1024 and start clock
	out TCCR0B , temp
	
	ldi temp, 0b00000000
	out EIMSK, temp			; disable int1 and enable int0

	CPSE modeCheck, ONE ;if modecheck = 0 go to playmode else testmode
	rjmp postsonicPlay
	rjmp postSonicTest
			
distanceToBig:
	ldi distance2,0
		rjmp chill

timeClr0:				
	inc distance
	cpi distance, 24 ;determines distance between each seg
	breq distOverflow
	out TCNT0, ZERO
timeClr00:	
	reti

distOverflow:	
	inc distance2
	clr distance
	cpi distance2, 10
	breq  distanceToBig;if dist2 equal to a high value then out zero since no finger 10	
	rjmp timeClr00


threeSecDelay:
	pop r19
	ldi  temp, 244
    ldi  r19, 130
    ldi  r20, 6
Del: dec  r20
    brne Del
    dec  r19
    brne Del
    dec  temp
    brne Del
	
	push r19
	
	rjmp postDel

;--------------------------------------------------------------------------------------------

	wait:
	rjmp endRound

;SCORE CHECKING----------------------------------------------------------------------------------------------
ScoreCheck:
	cli
	inc round
	
	cpi Distance2, 0			;no finger detected  can change num if output isnt 0
	breq noFinger

	cp Number, Distance2
	Brne Wrong



;IS SCORE CORRECT?-----------------------------------------------------------------------------------------
correct:
		inc score
	
	ldi temp, 0b00111000   ;FLASH green led 1 sec
	out portc, temp

		pop r18
		pop r19
		pop r20
	ldi  r18, 82
    ldi  r19, 43
    ldi  r20, 0
D1: dec  r20
    brne D1
    dec  r19
    brne D1
    dec  r18
    brne D1
    lpm
	nop
		push r20
		push r19
		push r18

	ldi temp, 0b00110000   ;FLASH green led 1 sec
	out portc, temp

		rjmp playmodeS

wrong:
	ldi temp, 0b00110010  ;flash red led 1 sec
	out portc, temp

	dec score

		pop r18
		pop r19
		pop r20
	ldi  r18, 82
    ldi  r19, 43
    ldi  r20, 0
D2: dec  r20
    brne D2
    dec  r19
    brne D2
    dec  r18
    brne D2
    lpm
	nop
		push r20
		push r19
		push r18

	ldi temp, 0b00110000
	out portc, temp
	
		rjmp playmodeS

noFinger:
	ldi temp, 0b00110100  ;flash orange led 1 sec
	out portc, temp

		pop r18
		pop r19
		pop r20
	ldi  r18, 82
    ldi  r19, 43
    ldi  r20, 0
D3: dec  r20
    brne D3
    dec  r19
    brne D3
    dec  r18
    brne D3
    lpm
	nop
		push r20
		push r19
		push r18

	ldi temp, 0b00110000
	out portc, temp

		pop r18
		pop r19
		pop r20
	ldi  r18, 82
    ldi  r19, 43
    ldi  r20, 0
D6: dec  r20
    brne D6
    dec  r19
    brne D6
    dec  r18
    brne D6
    lpm
	nop
		push r20
		push r19
		push r18

		rjmp playmodeS

;END ROUND--------------------------------------------------------------------------------
endRound:
out portb,ZERO

	cpi score, 0
	breq NegScore
	cpi score, 1
		breq NegScore
	cpi score, 2
		breq NegScore
	cpi score, 3
		breq NegScore
	cpi score, 4
		breq NegScore
	cpi score, 5
		breq NegScore

		;if pos score will cont into PosScore
PosScore:
	ldi temp,0b00111000 
	out portc, temp   ;green led
	
	;4sec delay
	ldi  r18, 2
    ldi  r19, 69
    ldi  r20, 173
    ldi  r21, 7
D0: dec  r21
    brne D0
    dec  r20
    brne D0
    dec  r19
    brne D0
    dec  r18
    brne D0
	
	rjmp reset

NegScore:
	ldi temp,0b00110010
	out portc,temp  ;red led
	
	;4sec delay
	ldi  r18, 2
    ldi  r19, 69
    ldi  r20, 173
    ldi  r21, 7
L2: dec  r21
    brne L2
    dec  r20
    brne L2
    dec  r19
    brne L2
    dec  r18
    brne L2

	rjmp reset








/*
setup interupts
setup timer

reset:
	all values to zero

test mode:
	ldi modeCheck, 0b00000001
	rjmp sonic value
	out distance to ddrb(aquired from sonic value loop)

	rjump test


modeSwap:
	CSPE modeCheck, 0b00000001
	rjmp testmode
	rjmp playmode

play mode:
	ldi modeCheck, 0b00000000
	random select value 
	display value on bcd
	jmp to soniv value
	1 second delay
	jmp to soniv value		need four second delay and check sonic

	check value equal to target val...jmp to correct wrong or no finger
	1 second delay
	jmp to soniv value
	check value equal to target val...jmp to correct wrong or no finger
	1 second delay
	jmp to soniv value
	check value equal to target val...jmp to correct wrong or no finger
	1 second delay

sonic value:
	timer set to zero
	pulse high 10 ms
	when echo set to high start clock
	when echo set to low
	stop clock

	reset clock
	do convertion for distance
	return

interupt casued from switch:
	if high rjmp playmode

	else jump to test mode

interupt caused from button:
		
	

correct:
	flash green led 1 sec
	inc turns
	if turns equal six jmp end round

wrong:
	flash red led 1 sec
	inc turns
	if turns equal six jmp end round

no finger:
	flash orange led 1 sec
	inc turns
	if turns equal six jmp end round

end round:
	if good flash led
	if bad flash red
	
	4 sec delay

	jmp to rest
*/
