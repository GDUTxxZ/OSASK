; haribote-os
; TAB=4

; 有关BOOT_INFO
CYLS	EQU		0x0ff0			; 启动区
LEDS	EQU		0x0ff1			; 指示灯状态
VMODE	EQU		0x0ff2			; 颜色数目的信息，颜色的位数
SCRNX	EQU		0x0ff4			; 分辨率X
SCRNY	EQU		0x0ff6			; 分辨率Y
VRAM	EQU		0x0ff8			; 图像缓冲区开始地址

		ORG		0xc200			; 程序装载地址

		MOV		AL,0x13			; VGA显卡，320*200*8位彩色
		MOV		AH,0x00
		INT		0x10			; 设置显卡模式
		MOV		BYTE [VMODE],8	; 8位彩色
		MOV		WORD [SCRNX],320; 分辨率X
		MOV		WORD [SCRNY],200; 分辨率Y
		MOV		DWORD [VRAM],0x000a0000;图像缓冲区开始地址

; 用bios取得键盘上各种功能键的按下状态的状态

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

fin:
		HLT
		JMP		fin
