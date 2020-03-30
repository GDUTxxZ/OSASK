; haribote-os boot asm
; TAB=4

BOTPAK	EQU		0x00280000		; bootpack.hrb代码段
DSKCAC	EQU		0x00100000		; 启动程序
DSKCAC0	EQU		0x00008000		; 在IPL中将磁盘数据读入到了内存0x8000中

; BOOT_INFO信息
CYLS	EQU		0x0ff0			; 柱面
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2			; 显像模式
SCRNX	EQU		0x0ff4			; 分辨率X
SCRNY	EQU		0x0ff6			; 分辨率Y
VRAM	EQU		0x0ff8			; VRAM的开始位置

		ORG		0xc200			; 程序装载位置

; 初始化 显像模式

		MOV		AL,0x13			; 中断到，VGA模式
		MOV		AH,0x00
		INT		0x10
		MOV		BYTE [VMODE],8	; 显像模式为8位彩色
		MOV		WORD [SCRNX],320
		MOV		WORD [SCRNY],200
		MOV		DWORD [VRAM],0x000a0000

; 存放LEDS值

		MOV		AH,0x02
		INT		0x16 			; keyboard BIOS
		MOV		[LEDS],AL

; PIC关闭一切中断
;	根据AT兼容机的规格，如果要初始化PIC，
;	必须在CLI之前进行，否则有时会挂起
;	随后进行PIC的初始化

		MOV		AL,0xff			
		OUT		0x21,AL			; 相当于io_out(PIC0_IMR, 0xff) 禁止主PIC的全部中断
		NOP						; 如果连续执行out指令，有些机种会无法正常运行
		OUT		0xa1,AL			; 相当于io_out(PIC1_IMR, 0xff) 禁止从PIC的全部中断

		CLI						; 禁止CPU级别的中断

; 为了让CPU能访问1MB以上的空间，设定A20GATE，历史背景https://blog.csdn.net/lightseed/article/details/4305865

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; 切换到保护模式 参考资料https://blog.csdn.net/epluguo/article/details/9260429

[INSTRSET "i486p"]				; 操作系统运行在最低支持486指令的CPU上

		LGDT	[GDTR0]			; 设定临时GDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; 设置bit31为0（进制分页 Paging Enable (PG) Bit. Bit 31. 该位控制分页机制，PG=1，启动分页机制；PG=0,不使用分页机制。
		OR		EAX,0x00000001	; 设置bit0为1（切换到保护模式 Protected-Mode Enable (PE) Bit. Bit0. PE=0,表示CPU处于实模式; PE=1表CPU处于保护模式，并使用分段机制。
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			; 可读写的段 32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack的传送

		MOV		ESI,bootpack	; 转送源
		MOV		EDI,BOTPAK		; 转送目的地
		MOV		ECX,512*1024/4
		CALL	memcpy

; 磁盘数据最终转送到他原本的位置去

; 首先从启动扇区开始

		MOV		ESI,0x7c00		; 转送源
		MOV		EDI,DSKCAC		; 转送目的地
		MOV		ECX,512/4
		CALL	memcpy

; 所有剩下的

		MOV		ESI,DSKCAC0+512	; 转送源
		MOV		EDI,DSKCAC+512	; 转送目的地
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; 从柱面数变换成字节数/4
		SUB		ECX,512/4		; 减去IPL
		CALL	memcpy

; 安排好内存布局后，启动bootpack来进行操作系统的初始化

; bootpack的启动

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; 没有要转送的东西
		MOV		ESI,[EBX+20]	; 转送源
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; 转送目的地
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; 栈初始值
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		 AL,0x64
		AND		 AL,0x02
		IN		AL,0x60			; 空读，为了清空数据接收缓冲区内的垃圾数据
		JNZ		waitkbdout		; AND的结果如果不是0，就跳到waitkbdout
		RET

memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			; 减法运算的结果如果不是0，就跳到memcpy程序
		RET

		ALIGNB	16				; 一直添加DBO，直到时机合适为止（地址能被16整除）
GDT0:
		RESB	8				; NULL Selector
		DW		0xffff,0x0000,0x9200,0x00cf	; 可以读写的段 32bit
		DW		0xffff,0x0000,0x9a28,0x0047	; 可以执行的段 32bit（bootpack用）

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
