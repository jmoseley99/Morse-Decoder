;;; import all symbol definitions for the seven segment display.
#include "7segment.S"


;;; This subroutine converts a number from 0x0 to 0xF to its digit
;;; representation on the 7-segment-display

;;; Input:
;;; r24: hexadecimal number to display
;;;
;;; Output:
;;; r24: 7-segment representation of the digit
;;;

	.global get_digit

get_digit:

	push r30		; save Z reg low
	push r31		; save Z reg hi

	//andi r21, 0x		; make sure r24 is between 0 and 0xF

	ldi r30, lo8(digit_table) ; make Z point to the table with the digits.
	ldi r31, hi8(digit_table)

	add r30, r21	       ; the number in r24 is the offset into the table
	brcc 1f		       ; if no overflow from Z low, continue at 1
	inc r31		       ; else add overflow to Z high byte

1:
	lpm r21, Z		; load seven seg representation from the table (in prog memory)

	pop r31			; restore used registers.
	pop r30

	ret			; return from subroutine



;;; This table stores the 7-segment representations for the digits
;;; from 0x0 to 0xF in program memory (that is alright as it does not
;;; need change):

digit_table:
	.byte CHAR_BLANK, CHAR_BLANK, CHAR_E , CHAR_T, CHAR_I, CHAR_N, CHAR_A, CHAR_M, CHAR_S, CHAR_D, CHAR_R, CHAR_G, CHAR_U, CHAR_K, CHAR_W, CHAR_O, CHAR_H, CHAR_B, CHAR_L, CHAR_Z, CHAR_F, CHAR_C, CHAR_P, CHAR_ERROR, CHAR_V, CHAR_X, CHAR_Z, CHAR_Q, ALL_SEGS, CHAR_Y, CHAR_J
