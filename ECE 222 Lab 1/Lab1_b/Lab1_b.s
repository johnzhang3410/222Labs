;*----------------------------------------------------------------------------
;* Name:    Lab1_T.s 
;* Purpose: To flash an LED at approximately 1 Hz 
;* Author: 	Rasoul Keshavarzi 
;* Revision: 0.1
;* Changelog: Aug-26-2020 by Reinier Torres: Ported to STM32F401VE and added
;*			  comments to improve understanding and encourage thinking
;*----------------------------------------------------------------------------*/
;************************** DO NOT CHANGE THIS CODE **************************
; Setups the MCU for work and enables peripherals for STM32F401FE and matches
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
	
DELAY_COUNTER	EQU 0x186A00	;Counter to decrement for delay
	
	; We will use a technique called Read/Modify/Write Back. This is commonly
	; used when programming embedded application. Note that just writing our
	; wanted configuration may ruin the configuration for other pins/peripherals.
	; Reading what is in the peripheral register before modifying it allows us to
	; set our configuration whilst keeping previous configurations that shouldn't
	; be changed.
	; We encorage you to follow this practice, it will help you avoid crashes.
	LDR    R1,  =RCC_AHB1ENR ;Set the pointer to RCC_AHB1ENR register
	LDR    R0,  [R1]  ; Read: RCC_AHB1ENR from mapped memory 
	ORR.W  R0,  #0x01 ; Modify: Set b0 to enable the clock for GPIOA
	STR    R0,  [R1]  ; Write Back: Write back to RCC_AHB1ENR
	; GPIOA is now enable but GPIOA.PIN5 must be configured
	; Deep dive: Comment out the Write Back operation and see what happens to
	; the MCU. HINT: You will end up in the hard fault handler, look the RCC_AHB1ENR
	; register in the datasheet and try to understand why the system fails

	LDR			R1,=GPIOA_MOD ;Load pointer for GPIOA mode
	LDR 		R0, [R1]	; Read GPIOA mode register
	ORR.W		R0, #0x0500  ; Set GPIOA_PIN5 as an output 
	STR 		R0, [R1]	; Write back the mode
	
	LDR 		R0, [R1, GPIOA_OUT]	; Read GPIOA output type register
	AND.W		R0, #0xFFFFFFDF  ; Set GPIOA_PIN5 as a push-pull output (clears OT5) 
	STR 		R0, [R1, GPIOA_OUT]	; Write back the output type	
	; GPIOA_PIN5 is now configured
	
	; Testing GPIOA_PIN5. To see this happening you must debug the lines that 
	; follow step by step, otherwise the LED will turn on then off in a matter 
	; of microseconds
	LDR 		R0, [R1, GPIOA_DAT]	; Read GPIOA data register
	ORR.W		R0, B5_SET_MSK  ; Turn on LED (Sets ODR5) 
	STR 		R0, [R1, GPIOA_DAT]	; Write back the data to output data register
	
	TST			R0, B5_SET_MSK

	LDR 		R0, [R1, GPIOA_DAT]	; Read GPIOA data register
	AND.W		R0, B5_CLR_MSK  ; Turn off LED (clears ODR5) 
	STR 		R0, [R1, GPIOA_DAT]	; Write back the data to output data register
	
;***************************** END OF SETUP CODE ******************************

;************************* USER CODE STARTS HERE ******************************
; We prvide the main loop of the program. You must write the delays and also 
; turn on/off the LED. Use the initialization code as an example on how to
; manipulate the GPIO port

loop
	
	LDR			R2, =DELAY_COUNTER	;Initialize R2 with the DELAY_COUNTER
	
Inner_loop	;inner loop for delay
	TEQ			R2, #0	; Test if R2 == 0, If yes then z=1, else z=0 (continue decrementing)
	BEQ if_else ;Branch to if_else when z==1
if_true	;When R2 is not 0 (z=0)
	SUB			R2, R2, #1	;Decrement R2 by 1
	B			Inner_loop ;Loop back to Inner_loop and continue checking/decrementing R2 if needed	
if_else ;Z==1 Condition (When R2 ==0)
	B			FINISH	;Branch to FINISH, continue with the next parts of instruction
FINISH	

;if the LED is ON, then turn it off, else turn it on
	LDR 		R0, [R1, GPIOA_DAT]	; Read GPIOA data register
	EOR			R0, B5_SET_MSK	;Toggle the bits of R0 to make it on and off
	STR 		R0, [R1, GPIOA_DAT]	; Write back the data to output data register
	;TEQ			R0, 

	
	B			loop ;Unconditional jump to the main loop

	END 

