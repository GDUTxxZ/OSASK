; 一个有重试功能的读盘程序
; haribote-ipl
; TAB=4

		ORG		0x7c00			; 程序装载位置

; FTA12标准格式软盘

		JMP		entry			; 一个short的跳转指令,跳转范围是 [-128, 127]
		DB		0x90
		DB		"HARIBOTE"		; 厂商名
		DW		512				; 每扇区字节数（Bytes/Sector）
		DB		1				; 每簇扇区数（Sector/Cluster）
		DW		1				; Boot记录占用多少扇区
		DB		2				; 共有多少FAT表
		DW		224				; 根目录区文件最大数
		DW		2880			; 扇区总数
		DB		0xf0			; 介质描述符
		DW		9				; 每个FAT表所占扇区数
		DW		18				; 每磁道扇区数（Sector/track）
		DW		2				; 磁头数（面数）
		DD		0				; 隐藏扇区数
		DD		2880			; 如果 扇区总数=0,则由这里给出扇区数
		DB		0,0,0x29		; INT 13H的驱动器号 ; 保留，未使用 ; 扩展引导标记(29h)
		DD		0xffffffff		; 卷序列号
		DB		"HARIBOTEOS "	; 卷标
		DB		"FAT12   "		; 文件系统类型
		RESB	18				; 引导代码及其他数据

; 程序主体

entry:
		MOV		AX,0			; 初始化
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820
		MOV		ES,AX			; [ES:BX]缓冲地址
		MOV		CH,0			; 柱面 0
		MOV		DH,0			; 磁头 0
		MOV		CL,2			; 扇区 2

		MOV		SI,0			; source index 源变址寄存器，此处记录失败次数
retry:
		MOV		AH,0x02			; AH=0x02 : 读盘
		MOV		AL,1			; 1个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 调用磁盘BIOS
		JNC		fin				; 没出错就跳转到fin
		ADD		SI,1			; 出错的话寄存器++
		CMP		SI,5			; 比较SI和5
		JAE		error			; SI >= 5 显示错误信息
		MOV		AH,0x00			; bios使用复位驱动器功能
		MOV		DL,0x00			; A驱动器
		INT		0x13			; 复位驱动器
		JMP		retry

fin:
		HLT						; 等待
		JMP		fin				; 结束

error:
		MOV		SI,msg
putloop:
		MOV		AL,[SI]
		ADD		SI,1			; 读下一个字符
		CMP		AL,0
		JE		fin
		MOV		AH,0x0e			; 设定 INT 0x10 的时候执行打印命令
		MOV		BX,15			; 指定字符颜色（实际上应该用BL）
		INT		0x10			; 调用打印BIOS指令
		JMP		putloop
msg:
		DB		0x0a, 0x0a		; 换行*2
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 后面补0到0x7dfe

		DB		0x55, 0xaa		; 结束
=