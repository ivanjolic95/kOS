BITS 16

start:
    mov ax, 07C0h			; Set up 4K stack space after this bootloader
    add ax, 288				; (4096 + 512) / 16 bytes per paragraph
    mov ss, ax
    mov sp, 4096

    mov ax, 07C0h			; Set data segment to where we're loaded
    mov ds, ax


    call set_video_mode		; Set video mode

    mov si, os_info1		; Put string position into SI
    call print_string		; Call our string-printing routine

    mov si, os_info2
    call print_string

    call start_console 		; Start console

    jmp $					; Jump here - infinite loop!


	; LIST OF MESSAGES
    os_info1 db 'Welcome to kOS 0.0.1 alpha', 0Dh, 0Ah, 0
    os_info2 db 'Authors: Zdeslav Jambresic, Ivan Jolic', 0Dh, 0Ah, 0
	; END OF THE LIST

	; CONSOLE CURSOR
    console_cursor db ' >> ', 0
    
	; LIST OF COMMANDS:    
    command_cls db 'cls', 0
    command_hi db 'hi', 0
	; END OF THE LIST


set_video_mode:				; Routine: set video mode
    mov ah, 00h				; BIOS interrupt -> set video mode
    mov al, 03h				; Text mode, 80x25, 16 colors, 8 pages	
    int 10h					; Call interrupt -> Video Services
    ret
	

print_string:				; Routine: output string in SI to screen
	mov ah, 0Eh				; BIOS interrupt -> write character

  .repeat:
    lodsb					; Get character from string
    cmp al, 0				; If char is zero, 
    je .done				; End of string
    int 10h					; Otherwise, call interrupt -> Video Services
    jmp .repeat				; Repeat the subroutine

  .done:
    ret


move_cursor:				; Routine: move cursor
    mov ah, 02h				; BIOS interrupt -> set cursor position
    xor bh, bh				; Set bh to 0
    mov dh, 02h				; Set the third row
    mov dl, 05h				; Set the fifth column
    int 10h					; Call interrupt -> Video Services
    ret

enter_string:				; Routine: enter a string
	xor cl, cl				; Set counter to zero

 .repeat:
    mov ah, 00h				; BIOS interrupt -> set video mode
    int 16h					; Call interrupt -> Video Services

    cmp al, 0Dh  			; enter pressed?
    je .done
    
    cmp al, 08h				; backspace pressed?
    je .backspace

    mov ah, 0Eh				; BIOS interrupt -> teletype output
    int 10h					; Call interrupt -> Video Services
    stosb					; Store the key code
    inc cl					; Increase cursor position
    jmp .repeat				; Repeat the subroutine
    
  .backspace:				; In case of backspace is pressed
    cmp cl, 0				; If nothing is written
    je .repeat				; Go back to .repeat subroutine
    
    dec di					; Decrease the data segment pointer
    mov byte [di], 0		; Put 0 except of the current byte
    dec cl					; Decrease cursor position
    
    mov ah, 0Eh				; BIOS interrupt -> teletype output
    mov al, 08h				; Print the backspace byte
    int 10h					; Call interrupt -> Video Services
    
    mov al, ' '				; Print the space
    int 10h					; Call interrupt -> Video Services
    
    mov al, 08h				; Print the backspace byte
    int 10h					; Call interrupt -> Video Services
    
    jmp .repeat				; Repeat the subroutine

  .done:
    mov al, 0				
    stosb					; Store the key code

    ret
	
start_console:
    mov si, console_cursor	; Put string position into SI
    call print_string		; Call our string-printing routine
    
    call enter_string		; Call our string-entering routine
    
    jmp $					; Repeat the process

times 510-($-$$) db 0		; Set the first 510 bytes of HD to 0
dw 0xAA55					; The last two of the first sector
							; are AA-55 (boot record signature)


