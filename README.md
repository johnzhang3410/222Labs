# 222Labs
ECE 222: The course is about Computer organization. Memory units, control units, I/O operations. Assembly language programming, translation and loading. Arithmetic logic units. Computer case studies.
All labs were done with the stm32f401re microcontroller, developed/debugged with µVision and simulated on Proteus

Lab #1: Blinky
  - Flashing LED on and off every 500ms
  - Implemented software delays and utilized conditional branches
  
Lab #2: LED-Heliograph
  - Take in a string of characters as input, and output its corresponding morse code through LED
  - Implemented with subroutines
  
Lab #3: Reflex-meter I
  - Implemented an reflex meter where the LED will turn on after a random time
  - Utilized polling method to determine when the button has been pressed
  - Output displays the user's response time in milliseconds
  
Lab #4: Reflex-meter II
  - Implemented reflex meter from lab 3 with interrupt handling instead of polling
  - Masked and Unmasked IRQ to prevent random clicks interferring with the result
