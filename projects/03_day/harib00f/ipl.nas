; haribote-ipl
; TAB=4

CYLS	EQU		10				; EQU 伪指令把一个符号名称与一个整数表达式或一个任意文本连接起来。（类似宏）

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

entry:
		MOV		AX,0
		MOV		SS,AX
		MOV		SP,0x7c00
		MOV		DS,AX

; 读取磁盘

		MOV		AX,0x0820		; 我猜作者从0X8200开始放是为了计算方便，因为引导盘程序大小正好是0X8000-0X8200。
		MOV		ES,AX
		MOV		CH,0			; 柱面 0
		MOV		DH,0			; 磁头 0
		MOV		CL,2			; 扇区 2
readloop:
		MOV		SI,0			; 记录失败次数的寄存器
retry:
		MOV		AH,0x02			; AH=0x02 : 读入磁盘
		MOV		AL,1			; 一个扇区
		MOV		BX,0
		MOV		DL,0x00			; A驱动器
		INT		0x13			; BIOS终端
		JNC		next			; 读下一个盘
		ADD		SI,1			; 异常次数++
		CMP		SI,5			; 比较异常和5
		JAE		error			; SI >= 5 打印错误
		MOV		AH,0x00			;
		MOV		DL,0x00			;
		INT		0x13			; 重置驱动器
		JMP		retry
next:
		MOV		AX,ES			; 给ES+0x0020，包括以下三行
		ADD		AX,0x0020
		MOV		ES,AX			; 
		ADD		CL,1			; 扇区号
		CMP		CL,18			; 看看是不是读完了18个扇区
		JBE		readloop		; jump if below 如果没读完就跳到readloop继续读
		MOV		CL,1			; 读完了一个磁头，读另一个磁头
		ADD		DH,1			;
		CMP		DH,2			;
		JB		readloop		; 读完一个柱面两个磁头的全部18个扇区后
		MOV		DH,0			; 重新从磁头1开始
		ADD		CH,1			; 读下一个柱面
		CMP		CH,CYLS			; 判断一下跟磁头常数
		JB		readloop		; 

; 参考资料 http://blog.sina.com.cn/s/blog_3edcf6b80100crz1.html
; 跳去执行0xc200 haribote.nas程序，关于为什么是这个地址，要参考上述参考资料
; 磁头0 柱面0 扇区1， 引导程序 boots，共1个扇区 1号
; 磁头0 柱面0 扇区 2-10， 文件分配表1，共9个扇区 2-10号
; 磁头0 柱面0 扇区 11 - 磁头1 柱面0 扇区 1， 文件分配表2（FAT1和FAT2的内容相同，当FAT1表出错的时候可以使用FAT2来恢复文件分配表。），9个扇区， 11-20号
; 根目录扇区位置=FAT表数量*FAT表所占用的扇区数量+隐藏扇区数量 + 文件分配表使用后基址, 2*9=18， 21-39号
; 用户数据开始位置=40号---

		JMP		0xc200			;

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
fin:
		HLT
		JMP		fin
msg:
		DB		0x0a, 0x0a		; 换行*2
		DB		"load error"
		DB		0x0a			; 换行
		DB		0

		RESB	0x7dfe-$		; 后面补0到0x7dfe

		DB		0x55, 0xaa		; 结束
