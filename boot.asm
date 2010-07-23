macro offsetdisp
{
	bits = 16
	display 'Offset 0'
	repeat bits/4
		d = '0' + $ shr (bits-%*4) and 0Fh
		if d > '9'
			d = d + 'A'-'9'-1
		end if
		display d
	end repeat
	display "h", 10
}

org 07C00h
	jmp 0:start
b.drv:	db 0
offsetdisp
b.off:	dd 100000h
start:
	cli
	mov [b.drv], dl

	xor ax, ax
	mov ds, ax
	mov ss, ax
	mov sp, 9C00h

	in al, 092h	; Enable A20
	or al, 2
	out 092h, al

; {{{ Enter unreal mode
	cli
	push ds

	lgdt [GDT]
	mov eax, cr0
	or al, 1
	mov cr0, eax

	mov bx, SEL_DATA
	mov ds, bx

	and al, 0FEh
	mov cr0, eax

	pop ds
	sti
; }}}
	xor ah, ah
	mov dl, [b.drv]
	int 13h
copy:
	xor dh, dh	
	xor cx, cx
	inc cl
	
.loop:
	call read_sector
	inc ch
	cmp ch, 80
	jne .loop

;copy2:
;	mov dh, 1
;	xor cx, cx
;	inc cl
;.loop:
;	call read_sector
;	inc ch
;	cmp ch, 80
;	jne .loop


; VESA PLOX =D
	mov di, VESA
	mov cx, 112h ;or (1 shl 15)
	mov ax, 4F01h ; Get VESA info
	int 10h

	xor di, di
	mov bx, 112h ;or (1 shl 15)
	mov ax, 4F02h ; Set VESA mode (640x480@24bpp)
	int 10h

; Protected mode
	cli
	mov eax, cr0
	or al, 1
	mov cr0, eax

	jmp SEL_CODE:.here

use32
.here:	jmp main
use16

; {{{ read_sector

; Cylynder to read goes in ch
; cl is one
; Head in dh
read_sector:
	xor ax, ax
	mov es, ax
	mov bx, 1000h
	mov ax, 0224h
	mov dl, [b.drv]
	int 13h
	jc .fail


	mov edi, [b.off]
	mov esi, 1000h
	mov ebx, 36*512

.loop:	mov al, [esi]
	mov [edi], al
	inc esi
	inc edi
	dec ebx
	jnz .loop
	mov [b.off], edi
	ret

.fail:
	cmp ah, 80h
	je read_sector

	xchg bx, bx
	cli
@@:	hlt
	jmp @b

; }}}
SEL_CODE = 1 shl 3
SEL_DATA = 2 shl 3

align 8
GDT:
	dw 3*8-1
	dd GDT
	dw 0
.1:	dq 0000000011011111100110100000000000000000000000001111111111111111b
.2:	dq 0000000011011111100100100000000000000000000000001111111111111111b

times (1FEh - ($-07C00h)) db 0
	db 55h
	db 0AAh

org 100200h
include 'main.asm'


virtual at 1000h
VESA:
	.ModeAttributes:         rw      1
	.WinAAttributes:         rb      1
	.WinBAttributes:         rb      1
	.WinGranularity:         rw      1
	.WinSize:                rw      1
	.WinASegment:            rw      1
	.WinBSegment:            rw      1
	.WinFuncPtr:             rd      1
	.BytesPerScanLine:       rw      1
	.XResolution:            rw      1
	.YResolution:            rw      1
	.XCharSize:              rb      1
	.YCharSize:              rb      1
	.NumberOfPlanes:         rb      1
	.BitsPerPixel:           rb      1
	.NumberOfBanks:          rb      1
	.MemoryModel:            rb      1
	.BankSize:               rb      1
	.NumberOfImagePages:     rb      1
	.Reserved_page:          rb      1
	.RedMaskSize:            rb      1
	.RedMaskPos:             rb      1
	.GreenMaskSize:          rb      1
	.GreenMaskPos:           rb      1
	.BlueMaskSize:           rb      1
	.BlueMaskPos:            rb      1
	.ReservedMaskSize:       rb      1
	.ReservedMaskPos:        rb      1
	.DirectColorModeInfo:    rb      1
	; VBE 2.0 extensions
	.PhysBasePtr:            rd      1
	.OffScreenMemOffset:     rd      1
	.OffScreenMemSize:       rw      1
	; VBE 3.0 extensions
	.LinBytesPerScanLine:    rw      1
	.BnkNumberOfPages:       rb      1
	.LinNumberOfPages:       rb      1
	.LinRedMaskSize:         rb      1
	.LinRedFieldPos:         rb      1
	.LinGreenMaskSize:       rb      1
	.LinGreenFieldPos:       rb      1
	.LinBlueMaskSize:        rb      1
	.LinBlueFieldPos:        rb      1
	.LinRsvdMaskSize:        rb      1
	.LinRsvdFieldPos:        rb      1
	.MaxPixelClock:          rd      1
	; Reserved
	.Reserved:               rb      190
end virtual
; vim: ts=8 sw=8 syn=fasm
