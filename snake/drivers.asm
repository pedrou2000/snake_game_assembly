;*********************************************************************
;* Microprocessor-Based Systems
;* 2020-2021
;* Lab 4C
;* Author: Pedro Urbina Rodriguez
;* Group: 2291
;*********************************************************************/

code SEGMENT
    ASSUME cs:code

	ORG 256 ; space for psp

	start:
		jmp main 

	; global variables 
	signature dw 6248 ; my dni's final digits

	; interrupt service routine of 55h, print a blue square
	isr55h PROC FAR 
		push ax bx cx dx si di ; save value of changed registers

		; initialise variables to loop through square's pixels
		mov ch, 0
		mov cl, al ; cx containts the x position
		mov dh, 0
		mov dl, ah ; dx containts the y position

		; check if correct video mode
		mov ah, 0Fh
		int 10h
		cmp al, 13h
		jne end1

		; error control		
		cmp dx, 190 
		jg end1
		cmp cx, 0 
		jl end1
		cmp dx, 0 
		jl end1

		mov di, cx 
		add di, 10 ; di contains the x end of the square
		mov si, dx 
		add si, 10 ; si contains the y end of the square
		
		; int10H draw pixel --> AH=0Ch 	AL = Colour, BH = PageNumber, CX = x, DX = y
		mov ah, 0Ch
		mov bh, 00h ; page number (keep it always to zero)
		mov al, 1h ; al contains the colour: blue

		loop1: ; loop to through the whole square
				int 10h ; print a pixel
				inc cx ; next pixel in square
				cmp cx, di ; di contains x coordinate of the right side of the square
				jne loop1 ; if cx == di nex row of the square 
			
			inc dx ; dx points to y coordinate => next row of square
			sub cx, 10 ; initial x position 
			cmp dx, si ; dx contains y coordinate of the low side of the square
			jne loop1 ; if that was the last row finish
		
		end1:
			pop di si dx cx bx ax ; restore value of changed registers

			iret
	isr55h ENDP 

	; interrupt service routine of 57h, print a red square
	isr57h PROC FAR 
		push ax bx cx dx si di ; save value of changed registers

		; initialise variables to loop through square's pixels
		mov ch, 0
		mov cl, al ; cx containts the x position
		mov dh, 0
		mov dl, ah ; dx containts the y position

		; check if correct video mode
		mov ah, 0Fh
		int 10h
		cmp al, 13h
		jne end2

		; error control		
		cmp dx, 190 
		jg end2
		cmp cx, 0 
		jl end2
		cmp dx, 0 
		jl end2

		mov di, cx 
		add di, 10 ; di contains the x end of the square
		mov si, dx 
		add si, 10 ; si contains the y end of the square
		
		; int10H draw pixel --> AH=0Ch 	AL = Colour, BH = PageNumber, CX = x, DX = y
		mov ah, 0Ch
		mov bh, 00h ; page number (keep it always to zero)
		mov al, 4h ; al contains the colour: red

		loop2: ; loop to through the whole square
				int 10h ; print a pixel
				inc cx ; next pixel in square
				cmp cx, di ; di contains x coordinate of the right side of the square
				jne loop2 ; if cx == di nex row of the square 
			
			inc dx ; dx points to y coordinate => next row of square
			sub cx, 10 ; initial x position 
			cmp dx, si ; dx contains y coordinate of the low side of the square
			jne loop2 ; if that was the last row finish
		
		end2:
			pop di si dx cx bx ax ; restore value of changed registers

			iret
	isr57h ENDP 

	; interrupt service routine of 58h, print a yellow square
	isr58h PROC FAR 
		push ax bx cx dx si di ; save value of changed registers

		; initialise variables to loop through square's pixels
		mov ch, 0
		mov cl, al ; cx containts the x position
		mov dh, 0
		mov dl, ah ; dx containts the y position

		; check if correct video mode
		mov ah, 0Fh
		int 10h
		cmp al, 13h
		jne end5

		; error control		
		cmp dx, 190 
		jg end5
		cmp cx, 0 
		jl end5
		cmp dx, 0 
		jl end5

		mov di, cx 
		add di, 10 ; di contains the x end of the square
		mov si, dx 
		add si, 10 ; si contains the y end of the square
		
		; int10H draw pixel --> AH=0Ch 	AL = Colour, BH = PageNumber, CX = x, DX = y
		mov ah, 0Ch
		mov bh, 00h ; page number (keep it always to zero)
		mov al, 0Eh ; al contains the colour: red

		loop3: ; loop to through the whole square
				int 10h ; print a pixel
				inc cx ; next pixel in square
				cmp cx, di ; di contains x coordinate of the right side of the square
				jne loop3 ; if cx == di nex row of the square 
			
			inc dx ; dx points to y coordinate => next row of square
			sub cx, 10 ; initial x position 
			cmp dx, si ; dx contains y coordinate of the low side of the square
			jne loop3 ; if that was the last row finish
		
		end5:
			pop di si dx cx bx ax ; restore value of changed registers

			iret
	isr58h ENDP 

	BUFFER_SIZE EQU 100 ; maximum size of snakes

	; yellow squares which give 10 points when picked
	yellow_square_1 dw 0FFFFh ; higher byte x pos and lower y pos
	yellow_square_2 dw 0FFFFh ; higher byte x pos and lower y pos

	score_red db 0 ; score of red snake
	score_blue db 0 ; score of blue snake
	
	red_won_message db "Red won! Press any key to continue"
	blue_won_message db "Blue won! Press any key to continue"

	seconds_counter db 0 ; counter from 0 to 18 in a second
	game_counter db 0 ; from 0 to game_rate, when = game_rate execute game
	game_rate db 18 ; fractions of seconds between movement, initially = 1 sec
	seconds_passed dw 0 ; number of seconds that have passed since start of game 
	
	blue_positions dw BUFFER_SIZE dup(0) ; circular buffer containing blue snake squares
	red_positions dw BUFFER_SIZE dup(0) ; circular buffer containing red snake squares
	tail_pointer dw 0 ; pointer to the tail of the snake
	start_pointer dw 0 ; pointer to the head of the snake

	game_state db 0 ; 0 => game did not start; 1 => game being played 
					; 2 => blue has died; 3 => red has died; 4 => user has pressed 'q'
	
	blue_pos dw 0 ; represents the head of the blue snake
	red_pos dw 0 ; represents the head of the red snake

	; interrupt service routine 
	isr1Ch PROC FAR 
		; if game is not being played return
		cmp game_state, 0 
		je return1 

		; game being played
		inc seconds_counter 
		cmp seconds_counter, 18 ; if counter is 18 it has passed a second
		jne not_second 
		
		; it has passed a second (or 18 tics)
		inc seconds_passed ; increase the varible containing the number of seconds played

		push ax dx 

		; BIGGER SNAKES: one more square per snake every 10 seconds
		mov ax, seconds_passed 
		mov dl, 10 ; snake size increases by 1 square each 10 seconds
		div dl ; ah = ax mod 10
		cmp ah, 0 ; if seconds_passed multiple of 10...
		jne continue_1 
		cmp start_pointer, 0 ; start_pointer-- mod BUFFER_SIZE
		jne substract_only ; the range of printed squares is increased by one
		mov start_pointer, BUFFER_SIZE*2 - 2 ; it is a cyclic buffer 
		substract_only:	sub start_pointer, 2
		continue_1:
		
		; SPEEDUP: increase game movement by 10% every 15 seconds
		mov ax, seconds_passed 
		mov dl, 15 ; increase game speed every 15 seconds
		div dl ; ah = ax mod 15
		cmp ah, 0 ; if seconds_passed multiple of 15... 
		jne continue_2 		
		mov ah, 0 ; 15 seconds have passed, calculate the 10% of game rate 
		mov al, game_rate
		mov dl, 10 ; increase game speed by 10%
		div dl ; 10% of game rate is now in remainder al
		sub game_rate, al ; update game rate (-10% previous)

		continue_2:

		pop dx ax

		mov seconds_counter, 0 ; reset the counter, start counting again to 18 for a second to pass
		not_second: 
			push ax
			inc game_counter 
			mov al, game_rate
			cmp al, game_counter
			jbe execute ; if game_rate <= game_counter execute the game
			pop ax
		return1: iret

		execute: 
			pop ax ; from the not_second push

			; if user has pressed 'q' clean and end
			cmp game_state, 4  
			jne pushh
			call clean_before_leaving 
			mov game_counter, 0
			iret

			pushh: ; save changed registers
				push ax bx cx dx si di ds es bp 

			; clear screen 
			mov ah, 00h ; We set the video mode
			mov al, 13h ; 640x480 16 color graphics (VGA)
			int 10h	
			

			; BLUE SNAKE: next position and check collisions 
			; recalculate blue's position
			mov ax, blue_pos 
			add al, bl 
			add ah, bh 

			; check collisions with borders
			call check_collisions_borders
			cmp dx, 1 
			je blue_died	

			; check if it has caught a yellow square 
			call check_yellow_squares_blue

			; check collisions with opponent 
			call check_collisions_with_red 
			cmp dx, 1 
			je blue_died

			; check collisions with himself 
			call check_collisions_with_blue
			cmp dx, 1 
			je blue_died
		
			; save new position
			mov blue_pos, ax
			mov blue_positions[si], ax 


			; RED SNAKE: next position and check collisions 
			; recalculate red's position
			mov ax, red_pos 
			add al, cl 
			add ah, ch 

			; check collisions with borders
			call check_collisions_borders
			cmp dx, 1 
			je red_died	

			; check if it has caught a yellow square 
			call check_yellow_squares_red 

			; check collisions with opponent
			call check_collisions_with_blue
			cmp dx, 1 
			je red_died

			; check collisions with himself 
			call check_collisions_with_red
			cmp dx, 1 
			je red_died

			; save new position
			mov red_pos, ax
			mov red_positions[si], ax 

			
			jmp prints 
			blue_died: ; if someone has died set game_state accordingly and finish
				call red_won 
				jmp end3
			red_died: ; if someone has died set game_state accordingly and finish
				call blue_won
				jmp end3
			
			prints:

			; PRINT: print the different elements of the game
			; print yellow squares 
			mov ax, yellow_square_1 
			int 58h 
			mov ax, yellow_square_2
			int 58h 

			; print scoreboard 
			call print_scoreboard 

			; print the snakes 
			call print_snakes 

			; update circular array pointers 
			; tail_pointer++ mod BUFFER_SIZE			
			add tail_pointer, 2
			cmp tail_pointer, 2*BUFFER_SIZE ; circular array...
			jne next9 
			mov tail_pointer, 0 
			next9:
			; start_pointer++ mod BUFFER_SIZE		
			add start_pointer, 2
			cmp start_pointer, 2*BUFFER_SIZE ; circular array...
			jne end3 
			mov start_pointer, 0

			end3: ; finish 1Ch isr
				mov game_counter, 0 ; restart countng 18 for a second
				pop bp es ds di si dx cx bx ax
				iret 

	isr1Ch ENDP 

	; check if the input in ax has hit the borders, dx = 1 => yes, dx = 0 => no.
	check_collisions_borders PROC 
		cmp al, 0 ; check if collisions with borders
		jb collision_border 
		cmp al, 240 
		jae collision_border
		cmp ah, 0 
		jb collision_border 
		cmp ah, 180 
		jae collision_border 

		mov dx, 0
		ret 

		collision_border: 
			mov dx, 1
			ret
	check_collisions_borders ENDP

	; print the snakes ussing the circular buffer which stores theirs squares positions
	print_snakes PROC 
		mov si, start_pointer 
		loop5:
			mov ax, blue_positions[si]
			int 55h ; print blue snake
			mov ax, red_positions[si]
			int 57h ; print red snake
			cmp si, tail_pointer ; check if that was the last square to print
			je end10 
			add si, 2 ; si ++ mod BUFFER_SIZE ...
			cmp si, 2*BUFFER_SIZE ; circular array...
			jne loop5 
			mov si, 0
			jmp loop5 
		end10:
			ret
	print_snakes ENDP 

	score_message db "SCORE"
	score_red_message db "RED:  000" 
	score_blue_message DB "BLUE: 000"
	start_moving_message db "Start moving or in 10 secs loose!"

	; prints the scoreboard using the function int 10h with ah = 13h
	print_scoreboard PROC 
		mov ah, 13h 
		mov al, 0h 
		mov bh, 0h 
		mov bl, 022h 
		; print the score message
		lea bp, score_message
		mov cx, 5 ; string length
		mov dh, 6 ; row
		mov dl, 32 ; column 
		int 10h 
		mov bl, 021h 
		; print blue's score 
		lea bp, score_blue_message
		mov cx, 9 ; string length
		mov dh, 9 ; row
		mov dl, 30 ; column 
		int 10h 
		; print red's score 
		lea bp, score_red_message
		mov dh, 11 ; row
		mov dl, 30 ; column 
		int 10h 
		; print start moving message 
		lea bp, start_moving_message
		mov bl, 029h 
		mov cx, 33 ; string length
		mov dh, 23 ; row
		mov dl, 2 ; column 
		int 10h 

		ret
	print_scoreboard ENDP

	; if red has won print a message and set game_state accordingly
	red_won PROC 
		mov game_state, 2 

		; print message of who has won
		mov ah, 13h 
		mov al, 0h 
		mov bh, 0h 
		mov bl, 022h 
		lea bp, red_won_message
		mov cx, offset blue_won_message ; string length 
		sub cx, offset red_won_message
		mov dh, 10 ; row
		mov dl, 3 ; column 
		int 10h 
		; print scores
		mov bl, 02Ah ; colour
		lea bp, points_message ; string to print
		mov cx, 7 ; string length
		mov dh, 13 ; row
		mov dl, 5 ; column 
		int 10h 
		mov bl, 028h ; colour
		lea bp, score_red_message ; string to print
		mov cx, 9 ; string length
		mov dh, 13 ; row
		mov dl, 14 ; column 
		int 10h 
		mov bl, 021h ; colour
		lea bp, score_blue_message ; string to print
		mov cx, 9 ; string length
		mov dh, 13 ; row
		mov dl, 25 ; column 
		int 10h 

		call clean_before_leaving
		ret 
	red_won ENDP

	points_message db "Points:"

	; if blue has won print a message and set game_state accordingly
	blue_won PROC  
		mov game_state, 3

		; print message of who has won
		mov ah, 13h ; function: print a string
		mov al, 0h 
		mov bh, 0h ; page
		mov bl, 022h ; colour
		lea bp, blue_won_message ; string to print
		mov cx, 35 ; string length
		mov dh, 10 ; row
		mov dl, 3 ; column 
		int 10h 
		; print scores
		mov bl, 02Ah ; colour
		lea bp, points_message ; string to print
		mov cx, 7 ; string length
		mov dh, 13 ; row
		mov dl, 5 ; column 
		int 10h 
		mov bl, 021h ; colour
		lea bp, score_blue_message ; string to print
		mov cx, 9 ; string length
		mov dh, 13 ; row
		mov dl, 14 ; column 
		int 10h 
		mov bl, 028h ; colour
		lea bp, score_red_message ; string to print
		mov cx, 9 ; string length
		mov dh, 13 ; row
		mov dl, 25 ; column 
		int 10h 

		call clean_before_leaving
		ret 
	blue_won ENDP 

	error_message db "ERROR, si:  , sp:  , tp:  "

	; used to debug only
	print_error PROC  
		mov game_state, 0
		mov ax, si 
		add al, '0'
		mov error_message[11], al
		mov ax, start_pointer 
		add al, '0'
		mov error_message[18], al
		mov ax, tail_pointer 
		add al, '0'
		mov error_message[25], al

		mov ah, 13h 
		mov al, 0h 
		mov bh, 0h 
		mov bl, 022h 
		lea bp, error_message
		mov cx, 26 ; string length
		mov dh, 10 ; row
		mov dl, 3 ; column 
		int 10h 

		call clean_before_leaving
		iret 
	print_error ENDP

	;  checks if position in ax is in collision with the red snake: dx = 1 => yes, dx = 0 => no.
	check_collisions_with_red PROC 

		mov si, start_pointer 
		mov dx, 0
		while2: ; trascend all the red snake's list
			mov dx, red_positions[si] 
			cmp ax, dx ; check if new position coincides with previous of the opponent
			je collision_red 
			cmp si, tail_pointer 
			je endwhile2
			add si, 2 ; si++ mod BUFFER_SIZE ...
			cmp si, 2*BUFFER_SIZE ; it is a circular array
			jne while2
			mov si, 0 ; if it has reached the end of the array continue overriding from begining
			jmp while2 
		collision_red: 
			mov dx, 1 
		endwhile2:
			ret 
	check_collisions_with_red ENDP

	;  checks if position in ax is in collision with the blue snake: dx = 1 => yes, dx = 0 => no.
	check_collisions_with_blue PROC 

		mov si, start_pointer 
		mov dx, 0
		while3: ; trascend all the blue snake's list
			mov dx, blue_positions[si] 
			cmp ax, dx ; check if new position coincides with previous of the opponent
			je collision_blue
			cmp si, tail_pointer 
			je endwhile3
			add si, 2 ; si++ mod BUFFER_SIZE ...
			cmp si, 2*BUFFER_SIZE ; it is a circular array
			jne while3
			mov si, 0 ; if it has reached the end of the array continue overriding from begining
			jmp while3
		collision_blue: 
			mov dx, 1
		endwhile3:
			ret 
	check_collisions_with_blue ENDP

	; clean the resident variables so that the next game works normally
	clean_before_leaving PROC 
		mov tail_pointer, 0 
		mov start_pointer, 0 
		mov game_state, 0
		mov score_blue, 0 
		mov score_red, 0 
		call generate_yellow_squares 
		mov game_rate, 18
		mov seconds_counter, 0 
		mov game_counter, 0 
		mov seconds_passed, 0

		; clean the arrays so that there are not confusions in future games
		mov si, 0 
		loop33:
			mov blue_positions[si], 0FFFFh
			mov red_positions[si], 0FFFFh 
			add si, 2
			cmp si, BUFFER_SIZE 
			jne loop33

		ret	
	clean_before_leaving ENDP

	; checks if current ax postion, representing the blue sanke's head has found a yellow square
	; eliminating it in that case, updating its score and generating 2 more if there are no more yellow sqaures
	check_yellow_squares_blue PROC 
		push dx 
		mov dl, 0 ; dl contains the number of yellow squares picked 

		; picked fisrt square?
		cmp ax, yellow_square_1 
		jne nextt1 
		mov yellow_square_1, 0FFFFh 
		inc dl
		nextt1:
		; picked second square?
		cmp ax, yellow_square_2 
		jne nextt2 
		mov yellow_square_2, 0FFFFh 
		inc dl 

		nextt2: 
		add score_blue, dl ; update points of blue snake
		call refresh_blue_score_message ; refresh blue score message
		
		cmp yellow_square_1, 0FFFFh 
		jne end4 
		cmp yellow_square_2, 0FFFFh 
		jne end4 ; are both yellow squres already picked up?

		call generate_yellow_squares ; then generate other 2

		end4: 
			pop dx
			ret

	check_yellow_squares_blue ENDP 


	; checks if current ax postion, representing the red snake's head has found a yellow square
	; eliminating it in that case, updating its score and generating 2 more if there are no more yellow sqaures
	check_yellow_squares_red PROC 
		push dx 
		mov dl, 0 ; dl contains the number of yellow squares picked 

		; picked fisrt square?
		cmp ax, yellow_square_1 
		jne nextt3
		mov yellow_square_1, 0FFFFh 
		inc dl
		nextt3:
		; picked second square?
		cmp ax, yellow_square_2 
		jne nextt4
		mov yellow_square_2, 0FFFFh 
		inc dl 

		nextt4: 
		add score_red, dl ; update points of blue snake
		call refresh_red_score_message ; refresh blue score message
		
		cmp yellow_square_1, 0FFFFh 
		jne end8
		cmp yellow_square_2, 0FFFFh 
		jne end8 ; are both yellow squres already picked up?

		call generate_yellow_squares ; then generate other 2

		end8: 
			pop dx
			ret

	check_yellow_squares_red ENDP 

	; updates the blue score message with the value in score_blue
	refresh_blue_score_message PROC 
		push ax dx 

		mov ah, 0
		mov al, score_blue ; ax contains the blue score
		mov dl, 10 ; divide by 10
		div dl ; al quotient & ah remainder 
		add ah, '0' ; convert to ascii
		add al, '0' ; convert to ascii
		mov score_blue_message[7], ah ; update corresponding bytes
		mov score_blue_message[6], al ; update corresponding bytes

		pop dx ax
		ret	
	refresh_blue_score_message ENDP

	; updates the red score message with the value in score_red
	refresh_red_score_message PROC 
		push ax dx
		mov ah, 0 ; ax contains the red score
		mov al, score_red
		mov dl, 10 ; divide by 10
		div dl ; al quotient & ah remainder 
		add ah, '0' ; convert to ascii
		add al, '0' ; convert to ascii
		mov score_red_message[7], ah ; update corresponding bytes
		mov score_red_message[6], al ; update corresponding bytes

		pop dx ax
		ret	
	refresh_red_score_message ENDP

	; update yellow_square_1 and yellow_square_2 with 2 random values (which represent valid squares in game)
	generate_yellow_squares PROC 

		push ax cx dx 

		; new y position of yellow_square_1
		mov ah,  00h 
		int 1Ah ; CX:DX now hold number of clock ticks since midnight 
		mov ax, dx 
		mov cx, 17 ; 170 is the maximum y of the square start 
		mov dx, 0
		div cx ; ax quotient & dx remainder 
		mov ax, dx 
		mov cl, 10 
		mul cl ; ax holds (number of clock ticks mod 23) * 10 
		mov BYTE PTR yellow_square_1[1], al ; new y pos of yellow square is the calculated ax

		; new x position of yellow_square_1
		mov ah,  00h 
		int 1Ah ; CX:DX now hold number of clock ticks since midnight 
		mov ax, dx 
		mov cx, 23 ; 230 is the maximum x of the square start 
		mov dx, 0
		div cx ; ax quotient & dx remainder 
		mov ax, dx 
		mov cl, 10 
		mul cl ; ax holds (number of clock ticks mod 23) * 10 
		mov BYTE PTR yellow_square_1[0], al ; new x pos of yellow squear is the calculated ax	

		; new y position of yellow_square_2
		mov ah,  00h 
		int 1Ah ; CX:DX now hold number of clock ticks since midnight 
		mov ax, dx 
		mov dx, 0 
		mov cx, 44 
		div cx 
		mov dx, 0
		mov cx, 17 ; 170 is the maximum y of the square start 
		div cx ; ax quotient & dx remainder 
		mov ax, dx 
		mov cl, 10 
		mul cl ; ax holds (number of clock ticks mod 17) * 10 
		mov BYTE PTR yellow_square_2[1], al ; new y pos of yellow squear is the calculated ax

		; new x position of yellow_square_2
		mov ah,  00h 
		int 1Ah ; CX:DX now hold number of clock ticks since midnight 
		mov ax, dx 
		mov dx, 0
		mov cx, 44 
		div cx 
		mov dx, 0
		mov cx, 23 ; 230 is the maximum x of the square start 
		div cx ; ax quotient & dx remainder 
		mov ax, dx 
		mov cl, 10 
		mul cl ; ax holds (number of clock ticks mod 23) * 10 
		mov BYTE PTR yellow_square_2[0], al ; new x pos of yellow squear is the calculated ax	 

		pop dx cx ax

		ret
	generate_yellow_squares ENDP

	isr1Ch_seg dw 0
	isr1Ch_offset dw 0

	installer PROC
		mov	ax,	0
		mov	es,	ax
		mov	ax,	OFFSET isr55h
		mov	bx,	cs

		cli
		; install 55h
		mov	es:[55h*4],	ax
		mov	es:[55h*4+2], bx
		; install 57h
		mov	ax,	OFFSET isr57h
		mov	bx,	cs
		mov	es:[57h*4],	ax
		mov	es:[57h*4+2], bx
		; install 58h
		mov	ax,	OFFSET isr58h
		mov	bx,	cs
		mov	es:[58h*4],	ax
		mov	es:[58h*4+2], bx
		sti

		; save the old routine for uninstallation time
		mov ax, es:[1Ch*4+2] 
		mov isr1Ch_seg, ax 
		mov ax, es:[1Ch*4] 
		mov isr1Ch_offset, ax  		
		
        ; inhibition of the timer
        in al, 21h 
        or al, 00000001b ; activate inhibition bit pin IR0
        out 21h, al ; modify IMR of the master PIC 
		
        ; install 1Ch
        mov ax, offset isr1Ch
        mov bx, cs
        mov es:[1Ch*4], ax
        mov es:[1Ch*4+2], bx

        ; desinhibion of the timer
        in al, 21h 
        and al, 11111110b ; disable inhibition bit for pin IR0
        out 21h, al ; modify IMR of the master PIC

		mov	dx,	OFFSET	installer
		int	27h	;	Terminate	and	stay	resident
				;	PSP,	variables,	isr	routine.
		mov ax, 4C00h
        int 21h
	installer	ENDP

	uninstall PROC	;	Uninstall	ISR	of	INT	55h
		push ax	bx cx ds es
		mov	cx,	0
		mov	ds,	cx	; Segment	of	interrupt	vectors
		
		; interrupt 55h unistallation
		mov	es,	ds:[55h*4+2]	;	Read	ISR	segment
		mov	bx,	es:[2Ch]	;	Read	segment	of	environment	from	ISR’s	PSP.
		mov	ah,	49h
		int	21h	; Release	ISR	segment	 (es)
		mov	es,	bx
		int	21h	; Release	segment	of	environment	variables	of	ISR
		;	Set	vector	of	interrupt	55h	to	zero
		cli
		mov	ds:[55h*4],	cx	;	cx	=	0
		mov	ds:[55h*4+2], cx
		sti
		
		; interrupt 57h unistallation
		mov	es,	ds:[57h*4+2]	;	Read	ISR	segment
		mov	bx,	es:[2Ch]	;	Read	segment	of	environment	from	ISR’s	PSP.
		mov	ah,	49h
		int	21h	; Release	ISR	segment	 (es)
		mov	es,	bx
		int	21h	; Release	segment	of	environment	variables	of	ISR
		;	Set	vector	of	interrupt	57h	to	zero
		cli
		mov	ds:[57h*4],	cx	;	cx	=	0
		mov	ds:[57h*4+2], cx
		sti
		
		; interrupt 58h unistallation
		mov	es,	ds:[58h*4+2]	;	Read	ISR	segment
		mov	bx,	es:[2Ch]	;	Read	segment	of	environment	from	ISR’s	PSP.
		mov	ah,	49h
		int	21h	; Release	ISR	segment	 (es)
		mov	es,	bx
		int	21h	; Release	segment	of	environment	variables	of	ISR
		;	Set	vector	of	interrupt	57h	to	zero
		cli
		mov	ds:[58h*4],	cx	;	cx	=	0
		mov	ds:[58h*4+2], cx
		sti

		; interrupt 1Ch unistallation
		;	Set	vector	of	interrupt	1Ch	to previous value
;		cli 
;		mov ax, isr1Ch_offset
;		mov	ds:[1Ch*4],	ax	; restore original isr
;		mov ax, isr1Ch_seg
;		mov	ds:[1Ch*4+2], ax
;		sti 
		
		pop	es	ds	cx	bx	ax 

		ret
	uninstall ENDP

	; returns 1 in ax if installed 0 otherwise
	check_installed proc far 
		push es ds bx

		mov ax, 0
		mov es, ax
		; ds:bx points to the start of isr in the interrupt table
		lds bx, es:[55h*4] 
		; ax should have the signature if the driver is installed
		mov ax, ds:[bx-2]

		cmp ax, signature ; if one is installed the rest are installed
		je end7 ; no need to check each of the interruptions
		mov ax, 0 ; return 0
		jmp end6

		end7: 
			mov ax, 1 ; return 1

		end6: 
			pop bx ds es 
			ret
		
	check_installed endp
	
	; variables declared here so that they arenot kept resident in memory
	info_installed db "Driver created by Pedro. Driver already installed. In order to uninstall it run it appending /U (i.e Lab4a.com /U).", 13, 10, '$'
	info_not_installed db "Driver created by Pedro. Driver has not been installed yet. In order to install it run it appending /I (i.e Lab4a.com /I).", 13, 10, '$'

	main proc far
		call check_installed

		; [80h] contains the number of characters passed as argument
		mov bl, ds:[80h]	
		cmp bl, 3
		jne info ; if different than 3 jump to end

		mov bl, ds:[81h]
		cmp bl, ' '
		jne info ; if first character is not a space jump to end
		
		mov bl, ds:[82h]
		cmp bl, '/'
		jne info ; if second character is not a / jump to end

		mov bl, ds:[83h]
		
		cmp bl, 'I'
		jne next2

		; the user wants to install the driver
		cmp ax, 1 
		je info ; if check_installed said it was installed do not install
		jmp installer

		next2:
		cmp bl, 'U'
		jne info

		; the user wants to unistall the program
		cmp ax, 0
		je info ; if check_installed said it was not installed do not uninstall
		call uninstall 
		
		mov ax, 4c00h
		int 21h


		info: ; print info depending if driver is installed or not
			cmp ax, 0 
			je not_installed
			lea dx, info_installed
			jmp print1
			not_installed: 
				lea dx, info_not_installed

			print1:
				mov ah,9
				int 21H

			
		mov ax, 4c00h
		int 21h

	main endp

code ENDS
END	start