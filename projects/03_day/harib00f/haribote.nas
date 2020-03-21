; haribote-os
; TAB=4

		ORG		0xc200			; 这个程序编译后装载在0Xc200
fin:
		HLT
		JMP		fin
