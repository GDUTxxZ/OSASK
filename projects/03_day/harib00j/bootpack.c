/* 函数预声明 */

void io_hlt(void);

void HariMain(void)
{

fin:
	io_hlt(); /* 调用naskfunc.nas里面的函数io_hlt */
	goto fin;

}
