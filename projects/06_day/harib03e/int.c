#include "bootpack.h"

// #define PIC0_ICW1		0x0020
// #define PIC0_OCW2		0x0020
// #define PIC0_IMR		0x0021
// #define PIC0_ICW2		0x0021
// #define PIC0_ICW3		0x0021
// #define PIC0_ICW4		0x0021
// #define PIC1_ICW1		0x00a0
// #define PIC1_OCW2		0x00a0
// #define PIC1_IMR		0x00a1
// #define PIC1_ICW2		0x00a1
// #define PIC1_ICW3		0x00a1
// #define PIC1_ICW4		0x00a1

void init_pic(void)
/* PIC初始化 */
{
	io_out8(PIC0_IMR,  0xff  ); /* 禁止所有中断 */
	io_out8(PIC1_IMR,  0xff  ); /* 禁止所有中断 */

	io_out8(PIC0_ICW1, 0x11  ); /* 边沿触发模式 */
	io_out8(PIC0_ICW2, 0x20  ); /* 产生中断时候的中断号基值，IRQ0-7 由 INT20-27 接收， 比如产生了中断IRQ-0， 就会产生INT 0x20 中断信号 */
	io_out8(PIC0_ICW3, 1 << 2); /* PIC1 由 IRQ2 连接 */
	io_out8(PIC0_ICW4, 0x01  ); /* 无缓冲区模式 */

	io_out8(PIC1_ICW1, 0x11  ); /* 边沿触发模式 */
	io_out8(PIC1_ICW2, 0x28  ); /* IRQ8-15 由 INT28-2f 接收 */
	io_out8(PIC1_ICW3, 2     ); /* PIC1 由 IRQ2 连接 */
	io_out8(PIC1_ICW4, 0x01  ); /* 无缓冲区模式 */

	io_out8(PIC0_IMR,  0xfb  ); /* 11111011 PIC1以外全部禁止 */
	io_out8(PIC1_IMR,  0xff  ); /* 11111111 禁止所有中断 */

	return;
}


void inthandler21(int *esp)
/* 来自PS/2的键盘中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 21 (IRQ-1) : PS/2 keyboard");
	for (;;) {
		io_hlt();
	}
}

void inthandler2c(int *esp)
/* 来自PS/2的鼠标中断 */
{
	struct BOOTINFO *binfo = (struct BOOTINFO *) ADR_BOOTINFO;
	boxfill8(binfo->vram, binfo->scrnx, COL8_000000, 0, 0, 32 * 8 - 1, 15);
	putfonts8_asc(binfo->vram, binfo->scrnx, 0, 0, COL8_FFFFFF, "INT 2C (IRQ-12) : PS/2 mouse");
	for (;;) {
		io_hlt();
	}
}

void inthandler27(int *esp)
/* PIC0����̕s���S���荞�ݑ΍� */
/* Athlon64X2�@�Ȃǂł̓`�b�v�Z�b�g�̓s���ɂ��PIC�̏��������ɂ��̊��荞�݂�1�x���������� */
/* ���̊��荞�ݏ����֐��́A���̊��荞�݂ɑ΂��ĉ������Ȃ��ł��߂��� */
/* �Ȃ��������Ȃ��Ă����́H
	��  ���̊��荞�݂�PIC���������̓d�C�I�ȃm�C�Y�ɂ���Ĕ����������̂Ȃ̂ŁA
		�܂��߂ɉ����������Ă��K�v���Ȃ��B									*/
{
	io_out8(PIC0_OCW2, 0x67); /* IRQ-07��t������PIC�ɒʒm(7-1�Q��) */
	return;
}
