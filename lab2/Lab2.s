;*----------------------------------------------------------------------------
;* Name:    Lab1_T.s 
;* Purpose: To Transmit a message using Morse code using an LED 
;* Author: 	Rasoul Keshavarzi 
;* Revision: 0.1
;* Changelog: Oct-2-2020 by Reinier Torres: Ported to STM32F401RE and added
;*			  comments to improve understanding and encourage thinking. Also
;*			  rearanged the main program.
;*----------------------------------------------------------------------------*/
;************************** DO NOT CHANGE THIS CODE **************************
; Set up the MCU for work and enables peripherals for STM32F401RE and match
; startup_stm32f401xe.s file 
		THUMB	; Thumb instruction set 
		AREA 	My_code, CODE, READONLY
		EXPORT 	__MAIN
		ENTRY 
__MAIN

; Use the EQU directive to improve readability of your programs it also
; helps the assembler optimize your code
RCC_AHB1ENR	EQU 0x40023830	; address of enable register for AHB1
GPIOA_MOD 	EQU 0x40020000	; address of mode register GPIOA
GPIOA_OUT 	EQU 0x04	; offset of output type register for GPIOA
GPIOA_DAT 	EQU 0x14	; offset of data register output for GPIOA
	
B5_CLR_MSK	EQU 0xFFFFFFDF ;use this mask to clear bit 5  of any DWord
B5_SET_MSK	EQU 0x00000020 ;use this mask to set bit 5 of any DWord
	
;Hint: Use DELAY_CNT in DelayN it will prove handy when debugging or testing 
;	   the delay code. If you change this number to a small number (3-5) then 
;	   you can move very quickly throgh the rest of the code test the LEDs are
;	   working as expected	
DELAY_CNT	EQU 4000000	
	
;***************************** PERIPHERAL SETUP *******************************
	; We will use a technique called Read/Modify/Write Back. This is commonly
	; used when programming embedded application. Note that just writing our
	; wanted configuration may ruin the configuration for other pins/peripherals.
	; Reading what is in the peripheral register before modifying it allows us to
	; set our configuration whilst keeping previous configurations that shouldn't
	; be changed.
	; We encorage you to follow this practice, it will help you avoid crashes.
	LDR	R1,  =RCC_AHB1ENR ;Set the pointer to RCC_AHB1ENR register
	LDR	R0,  [R1]  ; Read: RCC_AHB1ENR from mapped memory 
	ORR	R0,  #0x01 ; Modify: Set b0 to enable the clock for GPIOA
	STR	R0,  [R1]  ; Write Back: Write back to RCC_AHB1ENR
	; GPIOA is now enable but GPIOA.PIN5 must be configured
	; Deep dive: Comment out the Write Back operation and see what happens to
	; the MCU. HINT: You will end up in the hard fault handler, look the RCC_AHB1ENR
	; register in the datasheet and try to understand why the system fails

	LDR	R1,=GPIOA_MOD ;Load pointer for GPIOA mode
	LDR	R0, [R1]	; Read GPIOA mode register
	ORR	R0, #0x0500  ; Set GPIOA_PIN5 as an output 
	STR	R0, [R1]	; Write back the mode
	
	LDR	R0, [R1, #GPIOA_OUT]	; Read GPIOA output type register
	AND	R0, #0xFFFFFFDF  ; Set GPIOA_PIN5 as a push-pull output (clears OT5) 
	STR	R0, [R1, #GPIOA_OUT]	; Write back the output type	
	; GPIOA_PIN5 is now configured
	
	; Testing GPIOA_PIN5. To see this happening you must debug the lines that 
	; follow step by step, otherwise the LED will turn on then off in a matter 
	; of microseconds
	;Turn LED On
	LDR	R0, [R1, #GPIOA_DAT]	; Read GPIOA data register
	ORR	R0, #B5_SET_MSK  ; Turn on LED (Sets ODR5) 
	STR	R0, [R1, #GPIOA_DAT]	; Write back the data to output data register

	;Turn LED Off
	LDR	R0, [R1, #GPIOA_DAT]	; Read GPIOA data register
	AND	R0, #B5_CLR_MSK  ; Turn off LED (clears ODR5) 
	STR	R0, [R1, #GPIOA_DAT]	; Write back the data to output data register
	
	
;----------------------------- END OF SETUP CODE ------------------------------

;************************* USER CODE STARTS HERE ******************************
main_loop
	LDR		R5, =InputLUT  ; assign R5 to the character string address: InputLUT
	LDRB	R0, [R5]       ; Read a (byte) character to convert to a Morse pattern
	;R0 now stores an ASCII Character

while_IsChar_cond	
	TEQ		R0, #0 ; Reading the NULL character breaks the loop
	BEQ		while_IsChar_end	;Entire word is over
while_IsChar_body
	; Call CharToMorse for the current character. Note that CharToMorse takes
	; the current character (R0) as a parameter and should return the Morse code 
	; in a register of your choice.
	; Hint: You can reuse registers used as input parameters provided that you do
	;       not need the input parameter in further operations.
	BL CharToMorse ;R0 now holds the morse code

	; Call function that will send the Morse code for current character to the LED
	; Hint: TransmitMorse makes calls to ToggleLED and DelayN
	BL TransmitMorse

    ; Get next character from input string
	ADD		R5, #1 ; Point to next character - increment the pointer by 1 byte
	LDRB	R0, [R5] ; Read the character	
	B		while_IsChar_cond
	
while_IsChar_end
    ; Finished procesisng the string, the loop condition is no longer true
	; Prepare for the next iteration over the string
	MOV	R0, #4      ; delay 4 extra spaces (7 total) between words
	BL	DelayN
	B	main_loop ;Also end of main program

; *****************************  CharToMorse  *********************************
; Input:  R0 Uppercase ASCII Char to be converted to Morse pattern
; Output: Rn Returns the Morse code for input Char. You are free to chose what
;         register to use as output. Remember that post-processing of output 
;		  data occurs after returning to the caller
; WARNING: We provide basic stack/unstack operations but you must include any register
;		   you use that is not part of the subroutine output. For example, if you use
;		   R5 in your subroutine you must push R5, then pop R5 before you leave. 
;		   You will get an incomplete/zero mark if you fail to handle the stack 
;		   properly.

; Hint:   Each MorseLuT element is a half-word (16bits) index increments must
;		  be by steps of 2 bytes. Check LDR reference
CharToMorse
	STMFD	R13!,{R1, R2, R14} ; push Link Register (return address) on stack
		; Hint: An index is usually used to access data stored in memory as a 
		;       block of contigous memory containing elements of fixed size.
		;       e.g. Arrays such as MorseLut. Like when using arrays, here you will
		;       provide the base address and the index within the array.
		;		Check LDR reference for details on how to provide base+offset
		;		addresses
		
		; Hint: The char 'A' in the ASCII table is number 65 or 0x41 but the first
		;       element of an array is always at offset zero. Given a character
		;       you must map it to its corresponding offset within the Morse code
		;		think how to do this for 'A' first, then proceed to check it works
		;		for all other chars. Test with 'Z' to confirm you can reach the 
		;		right MorseCode pattern
		
		; Hint: Unsigned integer multiplication by a factor of 2^n is very fast
		;       and does not require a multiplier. Simply shift-left by n
		MOV			R2, #0
		
		SUB			R0, R0, #0x41 ;R0 holds the char, from 0x41 to 0x60 so this gives offset
		LSL			R0, R0, #1 ;Doubles the offset since morse code is double the bits 
		LDR			R1, =MorseLUT ;Starting address of the Morse look up table
		ADD			R2, R0, R1 ;Offset + Base address gives the address we are looking for
		
		LDRH		R0, [R2] ;Store the content of morse code address (The morse code) into output R0
							 ;Using LDRH since it loads a half word and sign extend it to 32 bit

		LDMFD		R13!,{R1, R2, R15}	; restore LR to PC (R15) to return

;------------------------------------------------------------------------------


; ******************************* TransmitMorse *******************************
; Input:  R0 Morse code pattern
; Output: No output
; WARNING: We provide basic stack/unstack operations but you must include any register
;		   you use that is not part of the subroutine output. For example, if you use
;		   R5 in your subroutine you must push R5, then pop R5 before you leave. 
;		   You will get an incomplete/zero mark if you fail to handle the stack 
;		   properly.

; Hint:   Note that to transmit the Morse code you must shift the pattern to remove 
;         the leading zeroes. Transmission begins once you find the first one in the
;		  sequence. You then process all the bits until the register is empty. Using
;         Logical Shift Left (LSL) you can shift the bits to the right.
; Hint:   LSL will move Rn[31] into the carry bit (C-flag), which you can then use to 
;         perform branches.
; Hint:   The calls to DelayN and ToggleLED are not there to show your were they go
;         it is just a friendly reminder you should use them within TransmitMorse and
;         to help you understand how calling and returning from subroutines work
          
; LED Blinking is the binary representation of hex in R0 (1 is on, 0 is off)
; LSL until we reach a 1 (on), and start transmitting until null
; Then we delay 3 spaces before returning
TransmitMorse
	STMFD	R13!,{R3-R6, R14}	; push Link Register (return address) on stack
	
	MOV			R3, #0x1F ;We need to LSL 31 times to go through the entire binary
	MOV			R4, #0x20000000 ;The 31st bit, which we check and branch on
	
;Loop until the first 1
loop1
	AND 		R5, R0, R4 ;Check if left most bit is 0, if yes then it outputs a 0
	TEQ			R5, #0 ;If the bit is indeed 0
	BEQ if_true2
if_else2
	B	FINISH1
if_true2 ;Bit is 0, we left shift and minus the bit count
	LSL			R0, R0, #1
	SUB			R3, R3, #1
	B	loop1


Loop
	CMP			R3, #0 ;Check if all 32 bits have been checked
	BEQ			DELAY_3TIMES ;If yes then go delay 3 times
	
	LSL			R0, R0, #1 ;Shifts R0 to the left by 1 bit 
	AND 		R5, R0, R4 ;Result to 1 if R0 bit is 1 (ON), and 0 if R0 bit is 0(OFF)
	
FINISH1	
	MOV 		R6, R0 ;Stores the morse code to R6
	MOV			R0, R5 ;R0 needs to be the input into LEDctl
	
	BL LEDCtl ;This line is here to show that subroutine must call LEDCtl
	
	MOV 		R0, R6
	
	SUB			R3, R3, #1
	B 	Loop
	
DELAY_3TIMES	
	MOV 		R0, #3 ;Three delays between each char
	BL			DelayN ;Calls delay for the delays

	LDMFD		R13!,{R3-R6, R15}	; restore LR to PC (R15) to return

;------------------------------------------------------------------------------

; *********************************** LEDCtl **********************************
; Input:  R0 The value which indicates if the LED will be turned ON or OFF
; Output: No output
; WARNING: We provide basic stack/unstack operations but you must include any register
;		   you use that is not part of the subroutine output. For example, if you use
;		   R5 in your subroutine you must push R5, then pop R5 before you leave. 
;		   You will get an incomplete/zero mark if you fail to handle the stack 
;		   properly.
; Hint: C uses zero as false because most architectures will set Z=1 when the
;		result of an operation is zero. ARM is no exception to this method and
;       you can use MOVS to set Z=1 if you move a value of zero to a register,
;	    then you can branch or not by using BNE or BEQ depending on the status
;		the Z-flag. This can be very handy to decide if the LED should be ON/OFF

; Hint: Remember you implemented code to toggle an LED in Lab1.b you may
;		now be able to reuse that code for the LED control operation. Remember you
;		cannot assume registers are going to be preserved across your program so be
; 		careful on how you handle the GPIOA addresses. Look at the initialization 
;		for ideas on how to load addresses into registers.

LEDCtl
		STMFD		R13!,{R0, R14}	; push R3 and Link Register (return address) on stack
		
		TEQ			R0, #0			;check if R0 is equal to 0 (z==1) or not
		BEQ if_else		;when z=1
if_true
		LDR			R0, [R1, GPIOA_DAT]
		ORR			R0, B5_SET_MSK
		STR			R0, [R1, GPIOA_DAT]
		B			FINISH
if_else
		LDR	R0, [R1, #GPIOA_DAT]	; Read GPIOA data register
		AND	R0, #B5_CLR_MSK  ; Turn off LED (clears ODR5) 
		STR	R0, [R1, #GPIOA_DAT]	; Write back the data to output data register
		
FINISH

		MOV 		R0, #1
		BL	DelayN
		
		LDMFD		R13!,{R0, R15}	; restore R3 and LR to R15 the Program Counter to return

;------------------------------------------------------------------------------

; ********************************** DelayN ***********************************
; Input:  R0 DelayMultiplier. Assume R0>0
; Output: No output
; WARNING: We provide basic stack/unstack operations but you must include any register
;		   you use that is not part of the subroutine output. For example, if you use
;		   R5 in your subroutine you must push R5, then pop R5 before you leave. 
;		   You will get an incomplete/zero mark if you fail to handle the stack 
;		   properly.

; Hint:   Remember you implemented a 500ms delay in Lab1. Now you will transform
;		  that code into a configurable delay to make any delay of the form 
;		  R0*500ms. For example, if you need a one second delay you put 2 into R0
;		  before calling DelayN

DelayN
		STMFD		R13!,{R5, R14}
		
		LDR			R5, =DELAY_CNT
		MUL			R5, R5, R0
		
Inner_loop
		TEQ			R5, #0	;Test if R5 == 0, if yes then delay is over and skip to the end
		BEQ if_else1 ;If R5 == 0
if_true1
		SUB			R5, R5, #1
		B			Inner_loop
if_else1		
		LDMFD		R13!,{R5, R15}

;------------------------------------------------------------------------------


;******************* String and Look-up table declarations ********************
; Hint: Read bytes of the string until you find the NULL or "\0".
; Hint: You should use the proper opcode-type when using LDR to load data from
;	 	memory. Check the reference of LDR
;
; Hint: Since the final character of the string is the null character you can 
;       take advantage of its value to end string processing
;

; Write the string you want to "transmit" using Morse code 
	ALIGN	; Forces data to be word-aligned
; WARNING: USE UPPERCASE LETTERS WHEN TYPING THE STRING		
InputLUT	DCB		"BIRDS", 0	; strings must be stored, and read, as BYTES

; Morse Lookup table. Each character has being expanded into a 16-bits
; half word. 
	ALIGN	; Forces data to be word-aligned
MorseLUT 
		DCW 	0x0017, 0x01D5, 0x075D, 0x0075 	; A, B, C, D
		DCW 	0x0001, 0x015D, 0x01DD, 0x0055 	; E, F, G, H
		DCW 	0x0005, 0x1777, 0x01D7, 0x0175 	; I, J, K, L
		DCW 	0x0077, 0x001D, 0x0777, 0x05DD 	; M, N, O, P
		DCW 	0x1DD7, 0x005D, 0x0015, 0x0007 	; Q, R, S, T
		DCW 	0x0057, 0x0157, 0x0177, 0x0757 	; U, V, W, X
		DCW 	0x1D77, 0x0775 					; Y, Z

 	END 

