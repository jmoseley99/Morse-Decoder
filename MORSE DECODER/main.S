;;	|----------------------------------------------------------|
;;	|							   |
;;	|      	Morse Code Encoder - Completed [02.12.18]          |
;;	|----------------------------------------------------------|
;;	|							   |
;;	|	         By Luke Price, Jacob Moseley		   |
;;	|                   & Bradley Seager			   |
;;	|						           |
;;	|----------------------------------------------------------|
	CPU_FREQ = 16000000
	TICKS_PER_SEC = CPU_FREQ / (256 * 1024)

	DECISION_LIMIT = TICKS_PER_SEC / 5 ; 200ms
	TIMEOUT = 2 * TICKS_PER_SEC / 5	   ; 400ms
;;; include all port definitions
#define __SFR_OFFSET 0
#include <avr/io.h> 				

;;; Button is connected to PIN 8, PORTB, Bit 0, because that doubles as the ICP1 for timer1.
	BUTTON = 0
;;; Red, yellow, green LEDs are connected to those bits of PORTB:
	RED = 5	
	YELLOW = 4
	GREEN = 3
;;; include all port definitions
#define __SFR_OFFSET 0
#include <avr/io.h>

;;; include all symbol definitions for the seven segement display:
#include "7segment.S"

	.global main

main:
	ldi r26, 0b00000000 		; The register 'r26' is used to store the sequence of dots vs dashes, starting from the left
	ldi r27, 0b00000001 		; The register 'r27' is used to store the location of the pointer
	ldi r31, ALL_SEGS		; Set 'r31' to display all segments at start of the sequence
	out DDRD, r31 			; Make pins of PORTD output (except pin 0)
					; Setup for the button, DDRB0 is automatically an input.
	sbi PORTB, BUTTON 	
	clr r16				; Set up the timer ([ATmega328p], Section 15.11.1 (p126))
	sts TCCR1A, r16 		; Seting timer output mode: no output
					; Pin used, normal counting up. 
	ldi r16, TIMEOUT		; Time in 16ms ticks to detect a TIMEOUT,
					; about 400ms.
	sts OCR1AH, r16			; move into high byte of compare match
					; register A
	clr r16				; low byte of compare match is just 0.
	sts OCR1AL, r16        		; note 16bit registers always have to
					; be written high byte first, see
					; [ATmega328p], Chapter 15.3, p 106
	
					; Enable input capture interrupt (to time button presses) and
					; Compare match interrupt (the time-out to switch on the
	ldi r16, _BV(ICIE1) | _BV(OCIE1A)
	sts TIMSK1, r16	
					;; Enable noise canceller, set prescaler to 1024, and start
					;; Timer in CTC mode, [ATmega328p] section  15.11.2, p128
	
	ldi r16,  _BV(ICNC1) | _BV(CS12) | _BV(CS10) | _BV(WGM12)
	sts TCCR1B, r16
	clr r19				; Reset overflow flag to defined state
	sei				; Enable interrupts globally.
	
fourE4:	rjmp fourE4 			; Do nothing - just wait for the
					; Interrupts to occur -- forever.
					; This interrupt service routine is called whenever timer1 has
					; counted up to match the value stored in OCA1, ie when more then
					; GAP_LIMIT time has elapses since the last button press or release.
	.global timer1_compa_isr	; Export symbol to overwrite weak
					; definition in init.S
					; This is the start of the interrupt service routine: push all registers you use in the ISR for a local state, and probably have another value globally
timer1_compa_isr:
	push r16			; Because we use it in the ISR: button release or press
					; in this ISR, we reused r16 to update the ports
	in r16, SREG			; Save the status register.
	push r16	
					; Sheck whether we are waiting for a button press or release:
	lds r16, TCCR1B
	sbrs r16, ICES1 		; Skip if waiting for positive edge (ie for button release)
	rjmp awaiting_press
	
awaiting_release:
	ldi r31, 0b11111111		; Reset Screen by turning all segments off
	out PORTD, r31
	ser r19 			; Using r19 as a flag to indicate a
	rjmp 1f

awaiting_press:
	or r26, r27
	mov r21, r26
	rcall display_char		; Responsible for displaying the letter stored in 'r26'
		
1:	pop r16
	out SREG, r16 			; Restore status register in reverse order of pushing
	pop r16
	reti
	.global timer1_cpt_isr

timer1_cpt_isr:
	push r17		; use it to check the button release or press, and update the next status
	push r16	 	; we use this register to update the ports 

	push r8			; use it to store the timer count

	in r8, SREG 		; save the status register.
	push r8


	lds r8, ICR1L		; get the timer count when the capture event happened.
	lds r8, ICR1H           ; we discard the low part, only
				; interested in the high part, but
				; reading low byte is necessary to get
				; a correct high byte in ICR1H, see
				; documentation [ATmega328p] Section 15.11.7 p131
	mov r17,r19		;  If there is no timer-overflow (ie a
				;  very long button press and
	or r17,r8		;  ICR1H is still zero, then 
				;  less than 16ms have elapsed since
				;  last release or press
	breq  end_isr 		;  and we do nothing - no updates to ports

	clr r17
	sts TCNT1H, r17 	; reset timer, first writing the high byte to the latch
	sts TCNT1L, r17		; then the low byte -- Section 16.3 of [328] again.
	
	;; check whether the input was a button press or release:
	lds r17, TCCR1B
	sbrs r17, ICES1 	; skip if waiting for positive edge (ie for button release)
	rjmp pressed

released:
	andi r17, ~(_BV(ICES1)) 	; we have had positive edge, so next
	tst r19 			; Did we have a timer overflow
	brne long_press			; if yes, then signal is a long
					; Press in any case
	ldi r16, DECISION_LIMIT		; Is the signal longer than DECISION_LIMIT?
	cp r8,r16
	brcs short_press		; If it is shorter jump to label short
	
long_press:
	or r26, r27			; Toggle the value of 'r26' in using a logical OR
	lsl r27				; Shift the value of the pointer to the left
	rjmp 1f

short_press:
	lsl r27				; As a dot is represented by a '0' there is no need to invert the bit, just shift pointer
	rjmp 1f				; End updating ports
	
pressed:				; Call depressed -  more code to execute, perhaps for the coursework?
	ori r17, _BV(ICES1)		; Next time detect positive edge, ie a
	
1:
	sts TCCR1B, r17 		; Write r17 to TCCR1B to activate the
	clr r19				; Clear overflow flag in case it was set
end_isr:
	pop r8
	out SREG, r8 			; Restore status register
	pop r8				; This has the debounce code already
	pop r16				; No seperate label has been made for this
	pop r17

	reti

display_char:
	rcall get_digit			; Converts 'r21' contents to its segment counterpart
	out PORTD, r21			; Output this segment config
	clr r26				; Clear 'r26'
	ldi r27, 0b00000001		; Reset pointer
	ret				; Return;;; Program counts from 0 to F with 1s delays and displays the count on a seven segement display
