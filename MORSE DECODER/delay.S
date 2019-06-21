; This file creates a delay to work with 
.global delay
delay:

	push r24
	push r17
	push r2
	push r1

outermost_delay:

	ldi r17, 82		; 1000ms delay, see below

outer_delay:
	clr r1
middle_delay:
	clr r2
inner_delay:
	dec r2			; 1 clock tick
	brne inner_delay	; 2 clock ticks when z!=0, 1 tick when z=0.

	dec r1			; when this line is reached, about
				; 256*3 = 768 ticks have been consumed since inner_delay.
	brne middle_delay	;

	dec r17                 ; when this line is reache, about
				; 256*256*3 = 196608 ticks have been
				; consumed since middle delay.
	brne outer_delay
	;; moving past brne outer_delay we have consumed about
	;; 82*196608 = 16.121.856 clock ticks. As the CPU is running at
	;; 16MHz = 16.000.000 clock ticks / s we have consumed about
	;; 1s of time.

	dec r24
	brne outermost_delay

	pop r1
	pop r2
	pop r17
	pop r24

	ret
