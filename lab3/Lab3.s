;*----------------------------------------------------------------------------
;* Name:    Lab1_T.s 
;* Purpose: To implement a reflex-meter using a STM32F401RE 
;* Author: 	Reinier Torres 
;* Revision: 0.1
;* Changelog: Oct-27-2020 by Reinier Torres
;*----------------------------------------------------------------------------*/
;************************** DO NOT CHANGE THIS CODE **************************
; Set up the MCU for work and enables peripherals for STM32F401RE and match
; startup_stm32f401xe.s file 
		THUMB	; Thumb instruction set 
		AREA 	My_code, CODE, READONLY
		EXPORT 	__MAIN
		ENTRY 
__MAIN

;***************************  Constant declarations ***************************
;----- GPIO Declarations
RCC_AHB1ENR		EQU 0x40023830	; address of enable register for AHB1
GPIOA_MODER 	EQU 0x40020000	; base address of GPIOA
GPIOB_MODER		EQU	0x40020400	; base address of GPIOB	
GPIOC_MODER		EQU	0x40020800	; base address of GPIOC	

;Offset for GPIOs are the same accross the whole family (neat)
GPIO_OTYPER 	EQU 0x04	; Output TYpE Register
GPIO_OSPEEDR	EQU 0X08	; Output SPEED Register
GPIO_PUPDR		EQU 0x0C	; Pull UP/Down (control) Register
GPIO_IDR 		EQU 0x10	; Input Data Register	
GPIO_ODR 		EQU 0x14	; Output Data Register
	
;----- Other constants
RAND_SEED	EQU 0x2F1
DELAY_CNT	EQU 3250

;********************* Static variable declarations ***************************
RAND_DATA	EQU 0x20000000 ;Reserve address for random number
	LDR R0,	=RAND_SEED ; load the seed number 
	LDR	R1,	=RAND_DATA ; load the address of the static variable
	STR	R0,[R1]		   ; store the random number in memory
	

BCD_TEST	EQU 0xAAAA	
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
	ORR	R0,  #0x05 ; Modify: Enable the clock for GPIOA and GPIOC
	STR	R0,  [R1]  ; Write Back: Write back to RCC_AHB1ENR
	; GPIOA,C are now enable but more stuff must be configured
	; Deep dive: Comment out the Write Back operation and see what happens to
	; the MCU. HINT: You will end up in the hard fault handler, look the RCC_AHB1ENR
	; register in the datasheet and try to understand why the system fails

;---- GPIOA configuration
; We do not use the read/modify/write back in some cases because the whole register can
; be overwritten wothout affecting the proper operation of the system
	LDR	R1,=GPIOA_MODER ;Load pointer for GPIOA mode. This is the base register
	MOV	R0, #0x55555555  ; Set ALL pins of GPIOA as output 
	STR	R0, [R1]	; Write mode
	
	MOV	R0, #0  ; Set GPIOA_PIN5 as a push-pull output 
	STR	R0, [R1, #GPIO_OTYPER]	; Write back the output type	
		
;---- GPIOC configuration
; We use the three bits from GPIOC to control the RGB-LED
	LDR		R1,=GPIOC_MODER ;Load pointer for GPIOB mode. This is the base register
	LDR		R0,[R1] ; Load Output Data Register
	MOV32	R2,#0x15 ; Set PC0..PC2 of GPIOC as outputs all other as inputs
	ORR		R0,R0,R2
	
	STR	R0, [R1]	; Write mode
	
	MOV	R0, #0x0  ; Set GPIOC_PIN[2..0] as a push-pull outputs
	STR	R0, [R1, #GPIO_OTYPER]	; Write back the output type	
	MOV	R0,	#0
	STR	R0, [R1, #GPIO_OSPEEDR]	; Low speed operation
	MOV	R0,	#0x00000000
	STR	R0, [R1, #GPIO_PUPDR]	; No internal pull-ups
	
		
;---- Testing GPIOs. To see this happening you must debug the lines that 
;     follow step by step
;--GPIOA: seven-segement display
	LDR	R1,=GPIOA_MODER
	MOV	R0, #BCD_TEST  ; Write 1234 to display
	STR	R0, [R1, #GPIO_ODR]	; Write the data to output data register

;--GPIOC: RGB-LED
	LDR	R1,=GPIOC_MODER
	MOV	R0, #0x0  ; Turn on three LEDs (LED will shine white) 
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register

	MOV	R0, #0x6  ; RGB RED/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP
	MOV	R0, #0x5  ; RGB GREEN/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP
	MOV	R0, #0x3  ; RGB BLUE/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP	
	MOV	R0, #0x0  ; RGB ALL OFF
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP	
	
;Make sure to not use R0 and R1 in main, those are for LED and Text controls
;Delayed 5s before turning off LEDs and restarting the procedure

;----------------------------- END OF SETUP CODE ------------------------------

;************************* USER CODE STARTS HERE ******************************
main_loop

;Stage 1
;RGB_LED lit red, display shows AAAA
	LDR		R1,=GPIOC_MODER ;Load pointer for GPIOB mode. This is the base register
	MOV	R0, #0x6  ; RGB RED/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP
	
	LDR	R1,=GPIOA_MODER
	MOV	R0, #BCD_TEST  ; Write AAAA to display
	STR	R0, [R1, #GPIO_ODR]	; Write the data to output data register
	
inner_loop
	BL Rand
	
	CMP R8, #0x7D0 ;if R8 > 2000
	BGT inner_loop1 ;branch to inner_loop1 to check if its less than 10000
	
	B	inner_loop ;else branch back to get another random number
	
inner_loop1

	MOV R2, #0x2710
	CMP R8, R2 ;check if the number < 10000
	BLT	end1 ;if less than(yes), random number is within range and exit loop
	
	B	inner_loop ;Else get new Rand
	
end1	

	;At this point we have a random number within range 2000 to 10000 stored in R8
	;We also have LED red and display of AAAA	
	
	MOV	R2, R8
	BL		DelayN ;Delay R2*1ms times
	
	;Delay over, turn all(red) LED off, RGB_LED lit green
	LDR R1,=GPIOC_MODER
	MOV	R0, #0x0  ; RGB ALL OFF
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP
	
	MOV	R0, #0x5  ; RGB GREEN/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP
	
	;stage 2
	;Poll for user input (Button_down logic 0) every 1ms, until one is received	
	MOV R3, #0 ;Increments this counter until input received, convert + display this in stage 3


poll
	
	;Delay 1ms
	MOV R2, #1 ;R2 is the input to DelayN
	BL 		DelayN ;Delay for 1ms
	ADD R3, #1 ;Increments display counter, later convert to BCD using subroutine
	
	LDR	R4, =GPIOC_MODER  ;load R4 with the base address 0x40020800
	LDR	R4, [R4, #GPIO_IDR]	; Write back the data to output data register
	
	;Use AND to check 13th bit, if 0 then button is down	
	AND R4, R4, #0x2000 ;check whether the 13th bit is 0, is 0 then button is down
	TEQ R4, #0
	BEQ End2 ;button is down, stop polling
	
	B 		poll ;button not down, keep polling
	
End2

;stage 3
;Turn LED blue, convert counter to BCD and display it, then delay 5s before looping main
	MOV	R0, #0x3  ; RGB BLUE/ON
	STR	R0, [R1, #GPIO_ODR]	; Write back the data to output data register
	NOP	
	
	MOV R0, R3 ;move counter into the input
	BL		BinToBCD
	
	LDR	R1,=GPIOA_MODER
	MOV	R0, R8  ; Write counter BCD to display
	STR	R0, [R1, #GPIO_ODR]	; Write the data to output data register
	
	MOV R2, #5000 ;delay for 5s
	BL		DelayN

	B	main_loop ;Also end of main program
	
	
;************************* Pseudo Random Num Gen ******************************
; Input:  NA 
; Output: R8 Contains the random number.
; Description: Rand generates a pseudo random number by using the Linear 
;              Feedback Shift Register (LFSR) method, for details on the theory
;			   of LFSR and its applications you can start at: 
;			   https://en.wikipedia.org/wiki/Linear-feedback_shift_register
;			   The seed is initialized at the start of the program and saved in
;			   memory for use within the subroutine. The subroutine does not take
;			   any argument because it saves it using static memory allocation.
;			   That is we are using something like:
;			   static int RandNumber = 0x03FA; //equivalent C code
;			   To achieve the static allocation we first need to reserve a space 
;			   in RAM memory and then load it with the seed value. Later Rand
;			   will only need to read the value at the start of the call an store
;			   the value for future use in RAM
;
; WARNING: I've changed the code from previous versions of this lab that reserve
;		   R11 for exclusive use of Rand. You know from Lab2 that reserving 
;		   registers for exclusive use of subroutines is REALLY BAD practice.
;		   We now use R8 as per convention.
; WARNING: DO NOT MODIFY this subroutine to circumvent the rule about register
;		   reservations you will get a failed grade for Lab3.
Rand	
	STMFD		R13!,{R0-R3, R14}
; Hint: Let's try some C/Assembly mixing, look at the C statement below
; static int RandNumber = 0x03FA; 
; Something as simple as the previous line in C, requires the compiler to 
;  produce code in two different places:
; 1) In the init section of the program the compiler will reserve memory to place
;    the int and will also assign the initial value. Check init section...
; 2) Every time the value is read from memory there has to be code to load the
;	 address into a register and then load the value. Within the subroutine
;    we can cheat a little bit and reserve a register to hold the address but
;    we must load the address in the subroutine code or we will be in violation
;    of the non exclusive reservation rule.
	LDR	R0,	=RAND_DATA ;Load random number address
	LDR	R8,	[R0] ;Load random number
	;Random generation is a traightforward sequence of logic operations				
	AND			R1, R8, #0x2000
	AND			R2, R8, #0x0400
	LSR			R1, #2
	EOR			R3, R1, R2 ;first tab
	
	AND			R1, R8, #0x0400
	LSR			R3, #2
	EOR			R3, R3, R1 ;second tab

	AND			R1, R8, #0x0040
	
	LSR			R3, #4
	EOR			R3, R3, R1	;third tab
	
	
	LSR			R3, #6 ;shift XORED bit to b0
	LSL			R8, #1 ;shit current one to the lefr
	
	ORR			R8, R8, R3 ;assemble new randdom number
	MOV			R1, #0x7FFF ;clear up mask for unwanted bits
	AND			R8, R1	;clear up
				
	STR	R8,[R0] ;save random number in RAM			
	LDMFD		R13!,{R0-R3, R15}	

;------------------------------------------------------------------------------	
	
;******************************** Binary to BCD *******************************
; Input: R0 binary number to convert to BCD. The number is assumed to be positive
;		 and smaller than 0x270F = 9999dec.
; Output: R8 the packed Binary Coded Decimal (BCD) code for the input number. If
;		  the number is greater than 9999 the subroutine will return 0xEEEE
; Hint: For details on the BCD number system you can start at: 
;	    https://en.wikipedia.org/wiki/Binary-coded_decimal
; Note: This is one of those subroutines that seems very long but is indeed very
;       fast compared to most of its C counterparts. You can find C implemenations
;		that take a couple of lines of code. However, it requires the use of division
;		and the modulus (%) operand. If the MCU does not have support for 
;		multiplication and division, then the ASM counterpart based on subtraction
;		ALWAYS wins the race. BCD conversion is one of those things that can drag
;       performance down without triggering any alarm.
BinToBCD
	STMFD		R13!,{R0-R3, R14}
	MOV		R8,#0 ; Initialize return value
if_BCD_logic_1 				; Equivalent C is if(R0 > 9999) {R8=0xEEEE; return;}
	MOV		R1,#9999		; We check the logic statement by subtracting R0 from
	SUBS	R1,R1,R0		; 9999, if the result is negative then R0 > 9999 and
	BPL		if_BCD_end_1 	; the BCD code is ERROR. The branch that terminates 
if_BCD_then_1				; the if statement occurs when the result is positive
	MOV		R8,#0xEEEE		; or zero, meaning R0 \in [0,9999]
	B		BCD_return ;return
if_BCD_end_1

; Binary number in range [0,9999] convert to BCD
; ----- Thousands column
; The equivalent C code for the loop is:
; for(i=R0; i>0; i-R1) {R3++}
	MOV		R3,#0
	MOV 	R1,#1000 ; We use decimal notation. Let the assembler do its job!
for_thousands
	SUBS 	R2,R0,R1
	BMI		for_thousands_end ;terminate the loop R0 < 0
	MOV		R0,R2             ; Update R0 iff subtraction zero or positive
	ADD		R3,#1             ; R3++
	B		for_thousands
for_thousands_end
; The unpacked BCD is now in R3, we need to pack by shifting and ORing
; in C this is equivalent to: R8 = R8 | (R3 << 12);
	LSL		R3,#12
	ORR		R8,R8,R3

; ----- Hundreds column
	MOV		R3,#0
	MOV 	R1,#100 ; We use decimal notation. Let the assembler do its job!
for_hundreds
	SUBS 	R2,R0,R1
	BMI		for_hundreds_end ;terminate the loop R0 < 0
	MOV		R0,R2            ; Update R0 iff subtraction zero or positive
	ADD		R3,#1            ; R3++
	B		for_hundreds
for_hundreds_end
; The unpacked BCD is now in R3, we need to pack by shifting and ORing
; in C this is equivalent to: R8 = R8 | (R3 << 8);
	LSL		R3,#8
	ORR		R8,R8,R3	

; ----- Tens column
	MOV		R3,#0
	MOV 	R1,#10 ; We use decimal notation. Let the assembler do its job!
for_tens
	SUBS 	R2,R0,R1
	BMI		for_tens_end ;terminate the loop R0 < 0
	MOV		R0,R2        ; Update R0 iff subtraction zero or positive
	ADD		R3,#1        ; R3++
	B		for_tens
for_tens_end
; The unpacked BCD is now in R3, we need to pack by shifting and ORing
; in C this is equivalent to: R8 = R8 | (R3 << 4);
	LSL		R3,#4
	ORR		R8,R8,R3	
	
; ---- Ones column	
;Whatever remains in R0 is the ones column	
	ORR		R8,R8,R0 

BCD_return

	LDMFD		R13!,{R0-R3, R15}	
	
;------------------------------------------------------------------------------	
; ********************************** DelayN ***********************************
; Input:  R2 DelayMultiplier. Assume R2>0
; Output: No output
; We will delay R0*DELAY_CNT times

DelayN
		STMFD		R13!,{R1, R14}
		
		LDR			R1, =DELAY_CNT ;Each DELAY_CNT is 1ms
		MUL			R1, R1, R2 ;Will delay 2000 to 10000 ms
		
Inner_loop
		TEQ			R1, #0	;Test if R1 == 0, if yes then delay is over and skip to the end
		BEQ if_else1 ;If R1 == 0
if_true1
		SUB			R1, R1, #1
		B			Inner_loop
if_else1	

		LDMFD		R13!,{R1, R15}
		
;------------------------------------------------------------------------------	

END