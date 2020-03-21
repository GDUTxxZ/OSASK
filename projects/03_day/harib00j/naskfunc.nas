; naskfunc
; TAB=4

[FORMAT "WCOFF"]				; 制作目标文件的模式
[BITS 32]						; 32位bit


; 制作目标文件的信息

[FILE "naskfunc.nas"]			; 原文件名

		GLOBAL	_io_hlt			; 程序中包含的函数名


; 函数实现

[SECTION .text]		; 目标文件写了这些之后再写程序

_io_hlt:	; void io_hlt(void);
		HLT
		RET

; 本程序包含的知识点 https://www.cnblogs.com/snail-micheal/p/4189632.html