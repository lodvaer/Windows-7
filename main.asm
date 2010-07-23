use32
main:

LINE equ 640*3

macro intvector_setregs where, selector, flags
{
	mov eax, (selector shl 10h) or (where and 0FFFFh)
	mov ebx, (where and 0FFFF0000h) or flags
}

interrupts:
	mov al, 11h
	out 020h, al
	out 0A0h, al
	mov al, 20h
	out 021h, al
	mov al, 28h
	out 0A1h, al
	mov al, 4
	out 021h, al
	shr al, 1
	out 0A1h, al
	shr al, 1
	out 021h, al
	out 0A1h, al

	in al, 021h
	mov al, 11111101b
	out 021h, al
	in al, 0A1h
	mov al, 11111111b
	out 0A1h, al

	intvector_setregs null_interrupt, SEL_CODE, 8F00h
	mov ecx, 512
.loop:
	mov [ecx * 4 - 8], eax
	mov [ecx * 4 - 4], ebx
	dec ecx
	loop .loop
	
	intvector_setregs keyboard_interrupt, SEL_CODE, 8F00h
	mov [21h * 8], eax
	mov [21h * 8 + 4], ebx

	lidt [IDTR]
	sti


draw_img:
	mov esi, img_ende
	sub esi, LINE
	mov ebx, [VESA.PhysBasePtr]

	mov edi, 480

.outer:	mov ecx, 640*3

.loop:	mov al, [esi + ecx -3] ; B
	mov [ebx + ecx - 3], al
	mov al, [esi + ecx -2] ; G
	mov [ebx + ecx - 2], al
	mov al, [esi + ecx -1] ; R
	mov [ebx + ecx - 1], al
	sub ecx, 3
	jnz .loop

	sub esi, LINE
	add ebx, 2048
	dec edi
	jnz .outer

	xchg bx, bx
@@:	hlt
	jmp @b

flash_eyes.back:
	inc al
	mov ecx, 4000000h
@@:	rep nop
	loop @b
	jmp flash_eyes.over
flash_eyes:
	xor al, al
.over:
irp pos, 173,174,175,176,177,178 {
	mov ebx, [VESA.PhysBasePtr]
	add ebx, pos*2048 + 3*326 ; Left pupil
	mov ecx, 10
@@:	xor byte [ebx + 2], 080h
	add ebx, 3
	loop @b
}
irp pos, 176,177,178,179,180,181,182 {
	mov ebx, [VESA.PhysBasePtr]
	add ebx, pos*2048 + 3*400 ; Left pupil
	mov ecx, 8
@@:	add byte [ebx + 2], 080h
	add ebx, 3
	loop @b
}
	cmp al, 0
	je .back
	ret

IDTR:
	dw 256*8-1
	dd 0
	dw 0


null_interrupt:
	iret

key_states:
.ctrl: db 0
.alt: db 0

keyboard_interrupt:
	pusha
	
	in al, 60h
	mov ebx, eax
	
	cmp bl, 1dh
	je .set_ctrl
	cmp bl, 9dh
	je .unset_ctrl

	cmp bl, 38h
	je .set_alt
	cmp bl, 0B8h
	je .unset_alt

	cmp bl, 53h
	je .del

.out:
	mov al, 20h
	out 20h, al
	popa
	iret

.set_ctrl:
	mov byte [key_states.ctrl], 1
	jmp .out
.unset_ctrl:
	mov byte [key_states.ctrl], 0
	jmp .out
.set_alt:
	mov byte [key_states.alt], 1
	jmp .out
.unset_alt:
	mov byte [key_states.alt], 0
	jmp .out

.del:
	cmp byte [key_states.ctrl], 1
	jne .out
	cmp byte [key_states.alt], 1
	jne .out

	call flash_eyes
	jmp .out

img:
virtual at img
	img.magic	dw 0 ; BM
	img.size	dd 0
	img.resv	dd 0
	img.offset	dd 0
end virtual
file 'Hitler.bmp'
img_ende = $

img_size = img_ende - img

; vim: ts=8 sw=8 syn=fasm
