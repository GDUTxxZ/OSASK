void io_hlt(void);

void HariMain(void)
{
	// 这都只跟编译器有关，在汇编中类似性质是 [内存地址]
	int i; // i 此时在代码里代表的值是 对应内存地址和类型，int代表的是i存储的是两个字节的数字, 
	char *p; // p 同理，char * 代表了p存储的是一个字节的内存地址,p的值还是自身的内存地址，其实就是(char *) p

	for (i = 0xa0000; i <= 0xaffff; i++) {

		// = 操作的含义是，执行汇编的MOV [左边的值],[右边]
		p = i; 
		*p = i & 0x0f; // MOV [p对应的内存的值], (i & 0x0f)

	}

	for (;;) {
		io_hlt();
	}
}
