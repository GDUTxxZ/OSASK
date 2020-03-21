; haribote-os
; TAB=4

		ORG		0xc200			; 这个程序编译后装载在0Xc200

		MOV		AL,0x13			; VGA显卡，320*200*8位彩色
		MOV		AH,0x00
		INT		0x10			; 设置显卡模式
fin:
		HLT
		JMP		fin
