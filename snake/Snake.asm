;*********************************************************************
;* Microprocessor-Based Systems
;* 2020-2021
;* Lab 4C
;* Author: Pedro Urbina Rodriguez
;* Group: 2291
;*********************************************************************/

code SEGMENT
	blue_initial_x_pos db 50
	blue_initial_y_pos db 100
	red_initial_x_pos db 200
	red_initial_y_pos db 100

	start:

    ASSUME cs:code
	
	; set video mode
	MOV AH,0Fh ; Asking for video mode
	INT 10h ; Call to BIOS
	push ax ; We save the video mode into the stack

	mov ah, 00h ; We set the video mode
	mov al, 13h ; 640x480 16 color graphics (VGA)
	int 10h 

	; access variables of the 1CH isr using es:bx
	mov ax, 0 
	mov es, ax  
	mov di, es:[1Ch*4]
	mov es, es:[1Ch*4 + 2] 

	mov al, blue_initial_x_pos 
	mov ah, blue_initial_y_pos ; ax = initial blue
	mov dl, red_initial_x_pos 
	mov dh, red_initial_y_pos ; dx = initial red

	; set initial square positions, stored in resident memory of 1Ch isr
	mov es:[di - 4], ax
	mov es:[di - 2], dx

	mov bx, 0 ; bx will contain the movement of the blue snake and cx the red one
	mov cx, 0 ; do not move snakes yet
	mov BYTE PTR es:[di - 5], 1 ; start executing 1CH isr

	; check keyboard input
	loop1:
		mov ah, 01h
		int 16h
		jnz loop1 

	; check if game has ended while wiating for input 
	cmp BYTE PTR es:[di - 5], 1 ; access game_state variable in isr
	jne end_game2 ; if game_state != 1 game has ended

	; get pressed letter
	mov ah, 00h
	int 16h ; al now has the ascii code of the pressed letter 


	; load bx and cx with the indicated movement so that when the isr is 
	; called it has the dx and dy of each snake in bx and cx

	; blue snake: bh contains dy, bl contains the dx
	cmp al, 'w'
	jne next1 
	mov bx, 0 
	sub bh, 10
	jmp loop1

	next1:
		cmp al, 's'
		jne next2 
		mov bx, 0 
		add bh, 10
		jmp loop1
	
	next2:
		cmp al, 'a'
		jne next3
		mov bx, 0 
		sub bl, 10
		jmp loop1


	next3:
		cmp al, 'd'
		jne next4
		mov bx, 0 
		add bl, 10
		jmp loop1

	jmp next4
	jmploop1:
		jmp loop1 
	
	; red snake: ch contains dy, cl contains the dx
	next4:
		cmp al, 'i'
		jne next5
		mov cx, 0 
		sub ch, 10
		jmp loop1

	next5:
		cmp al, 'k'
		jne next6 
		mov cx, 0 
		add ch, 10
		jmp loop1
	
	next6:
		cmp al, 'j'
		jne next7
		mov cx, 0 
		sub cl, 10
		jmp jmploop1


	next7:
		cmp al, 'l'
		jne next8
		mov cx, 0 
		add cl, 10
		jmp jmploop1

	next8:
		cmp al, 'q'
		jne jmploop1 ; if 'q' pressed end game else continue 
		mov BYTE PTR es:[di - 5], 4 ; clean game variables before ending
		int 1Ch ; clean variables
		jmp end_game2 


	end_game2:
		mov ah, 00h ; Restore the input configuration to video mode
		pop bx ; we extract the video mode from the stack
		mov al, bl ; set al according to the value saved in the stack
		int 10h

		mov ax, 4c00h
		int 21h

code ENDS
end start