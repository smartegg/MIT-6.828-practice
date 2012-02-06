
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
# bootloader to jump to the *physical* address of the entry point.
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# translates virtual addresses [KERNBASE, KERNBASE+4MB) to
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
	movl	$(RELOC(entry_pgdir)), %eax
f010001a:	0f 22 d8             	mov    %eax,%cr3
	movl	%eax, %cr3
	# Turn on paging.
f010001d:	0f 20 c0             	mov    %cr0,%eax
	movl	%cr0, %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100025:	0f 22 c0             	mov    %eax,%cr0
	movl	%eax, %cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	mov	$relocated, %eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
	jmp	*%eax
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp
	movl	$0x0,%ebp			# nuke frame pointer

	# Set the stack pointer
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp
	movl	$(bootstacktop),%esp

	# now to C code
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:
	call	i386_init

	# Should never get here, but in case we do, just spin.
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>
#include <kern/env.h>
#include <kern/trap.h>


void
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
i386_init(void)
{
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
f0100046:	b8 4c dd 17 f0       	mov    $0xf017dd4c,%eax
f010004b:	2d 33 ce 17 f0       	sub    $0xf017ce33,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 33 ce 17 f0 	movl   $0xf017ce33,(%esp)
f0100063:	e8 ce 42 00 00       	call   f0104336 <memset>
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);

	// Initialize the console.
f0100068:	e8 8f 04 00 00       	call   f01004fc <cons_init>
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 48 10 f0 	movl   $0xf0104840,(%esp)
f010007c:	e8 6d 33 00 00       	call   f01033ee <cprintf>

	cprintf("6828 decimal is %o octal!\n", 6828);

f0100081:	e8 af 12 00 00       	call   f0101335 <mem_init>
	// Lab 2 memory management initialization functions
	mem_init();

	// Lab 3 user environment initialization functions
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 46 07 00 00       	call   f01007d8 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
}


f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
/*
 * Variable panicstr contains argument to first call to panic; used as flag
 * to indicate that the kernel has already called panic.
f010009f:	83 3d 40 ce 17 f0 00 	cmpl   $0x0,0xf017ce40
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
 */
const char *panicstr;
f01000a8:	89 35 40 ce 17 f0    	mov    %esi,0xf017ce40

/*
 * Panic is called on unresolvable fatal errors.
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
void
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 5b 48 10 f0 	movl   $0xf010485b,(%esp)
f01000c8:	e8 21 33 00 00       	call   f01033ee <cprintf>
_panic(const char *file, int line, const char *fmt,...)
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 e2 32 00 00       	call   f01033bb <vcprintf>
{
f01000d9:	c7 04 24 df 57 10 f0 	movl   $0xf01057df,(%esp)
f01000e0:	e8 09 33 00 00       	call   f01033ee <cprintf>
	va_list ap;

	if (panicstr)
		goto dead;
	panicstr = fmt;

f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 e7 06 00 00       	call   f01007d8 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
	vcprintf(fmt, ap);
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	cprintf("\n");
	va_end(ap);

f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
dead:
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 73 48 10 f0 	movl   $0xf0104873,(%esp)
f0100112:	e8 d7 32 00 00       	call   f01033ee <cprintf>
	/* break into the kernel monitor */
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 95 32 00 00       	call   f01033bb <vcprintf>
	while (1)
f0100126:	c7 04 24 df 57 10 f0 	movl   $0xf01057df,(%esp)
f010012d:	e8 bc 32 00 00       	call   f01033ee <cprintf>
		monitor(NULL);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 84 d0 17 f0    	mov    0xf017d084,%edx
f010017f:	88 82 80 ce 17 f0    	mov    %al,-0xfe83180(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 84 d0 17 f0       	mov    %eax,0xf017d084
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 c7                	mov    %eax,%edi
f01001b2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001b8:	a8 20                	test   $0x20,%al
f01001ba:	75 1b                	jne    f01001d7 <cons_putc+0x30>
f01001bc:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c1:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c6:	e8 75 ff ff ff       	call   f0100140 <delay>
f01001cb:	89 f2                	mov    %esi,%edx
f01001cd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001ce:	a8 20                	test   $0x20,%al
f01001d0:	75 05                	jne    f01001d7 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d2:	83 eb 01             	sub    $0x1,%ebx
f01001d5:	75 ef                	jne    f01001c6 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f01001d7:	89 fa                	mov    %edi,%edx
f01001d9:	89 f8                	mov    %edi,%eax
f01001db:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001de:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010020f:	ee                   	out    %al,(%dx)
f0100210:	b2 7a                	mov    $0x7a,%dl
f0100212:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100217:	ee                   	out    %al,(%dx)
f0100218:	b8 08 00 00 00       	mov    $0x8,%eax
f010021d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010021e:	89 fa                	mov    %edi,%edx
f0100220:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100226:	89 f8                	mov    %edi,%eax
f0100228:	80 cc 07             	or     $0x7,%ah
f010022b:	85 d2                	test   %edx,%edx
f010022d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100230:	89 f8                	mov    %edi,%eax
f0100232:	25 ff 00 00 00       	and    $0xff,%eax
f0100237:	83 f8 09             	cmp    $0x9,%eax
f010023a:	74 7c                	je     f01002b8 <cons_putc+0x111>
f010023c:	83 f8 09             	cmp    $0x9,%eax
f010023f:	7f 0b                	jg     f010024c <cons_putc+0xa5>
f0100241:	83 f8 08             	cmp    $0x8,%eax
f0100244:	0f 85 a2 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010024a:	eb 16                	jmp    f0100262 <cons_putc+0xbb>
f010024c:	83 f8 0a             	cmp    $0xa,%eax
f010024f:	90                   	nop
f0100250:	74 40                	je     f0100292 <cons_putc+0xeb>
f0100252:	83 f8 0d             	cmp    $0xd,%eax
f0100255:	0f 85 91 00 00 00    	jne    f01002ec <cons_putc+0x145>
f010025b:	90                   	nop
f010025c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100260:	eb 38                	jmp    f010029a <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f0100262:	0f b7 05 94 d0 17 f0 	movzwl 0xf017d094,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e4 00 00 00    	je     f0100356 <cons_putc+0x1af>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 94 d0 17 f0    	mov    %ax,0xf017d094
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100283:	83 cf 20             	or     $0x20,%edi
f0100286:	8b 15 90 d0 17 f0    	mov    0xf017d090,%edx
f010028c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100290:	eb 77                	jmp    f0100309 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100292:	66 83 05 94 d0 17 f0 	addw   $0x50,0xf017d094
f0100299:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029a:	0f b7 05 94 d0 17 f0 	movzwl 0xf017d094,%eax
f01002a1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a7:	c1 e8 16             	shr    $0x16,%eax
f01002aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ad:	c1 e0 04             	shl    $0x4,%eax
f01002b0:	66 a3 94 d0 17 f0    	mov    %ax,0xf017d094
f01002b6:	eb 51                	jmp    f0100309 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f01002b8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002bd:	e8 e5 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c7:	e8 db fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002cc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d1:	e8 d1 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002d6:	b8 20 00 00 00       	mov    $0x20,%eax
f01002db:	e8 c7 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002e0:	b8 20 00 00 00       	mov    $0x20,%eax
f01002e5:	e8 bd fe ff ff       	call   f01001a7 <cons_putc>
f01002ea:	eb 1d                	jmp    f0100309 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002ec:	0f b7 05 94 d0 17 f0 	movzwl 0xf017d094,%eax
f01002f3:	0f b7 c8             	movzwl %ax,%ecx
f01002f6:	8b 15 90 d0 17 f0    	mov    0xf017d090,%edx
f01002fc:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100300:	83 c0 01             	add    $0x1,%eax
f0100303:	66 a3 94 d0 17 f0    	mov    %ax,0xf017d094
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100309:	66 81 3d 94 d0 17 f0 	cmpw   $0x7cf,0xf017d094
f0100310:	cf 07 
f0100312:	76 42                	jbe    f0100356 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100314:	a1 90 d0 17 f0       	mov    0xf017d090,%eax
f0100319:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100320:	00 
f0100321:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100327:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032b:	89 04 24             	mov    %eax,(%esp)
f010032e:	e8 5e 40 00 00       	call   f0104391 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100333:	8b 15 90 d0 17 f0    	mov    0xf017d090,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100339:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010033e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100344:	83 c0 01             	add    $0x1,%eax
f0100347:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010034c:	75 f0                	jne    f010033e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010034e:	66 83 2d 94 d0 17 f0 	subw   $0x50,0xf017d094
f0100355:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100356:	8b 0d 8c d0 17 f0    	mov    0xf017d08c,%ecx
f010035c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100364:	0f b7 35 94 d0 17 f0 	movzwl 0xf017d094,%esi
f010036b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010036e:	89 f0                	mov    %esi,%eax
f0100370:	66 c1 e8 08          	shr    $0x8,%ax
f0100374:	89 da                	mov    %ebx,%edx
f0100376:	ee                   	out    %al,(%dx)
f0100377:	b8 0f 00 00 00       	mov    $0xf,%eax
f010037c:	89 ca                	mov    %ecx,%edx
f010037e:	ee                   	out    %al,(%dx)
f010037f:	89 f0                	mov    %esi,%eax
f0100381:	89 da                	mov    %ebx,%edx
f0100383:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100384:	83 c4 2c             	add    $0x2c,%esp
f0100387:	5b                   	pop    %ebx
f0100388:	5e                   	pop    %esi
f0100389:	5f                   	pop    %edi
f010038a:	5d                   	pop    %ebp
f010038b:	c3                   	ret    

f010038c <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010038c:	55                   	push   %ebp
f010038d:	89 e5                	mov    %esp,%ebp
f010038f:	53                   	push   %ebx
f0100390:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100393:	ba 64 00 00 00       	mov    $0x64,%edx
f0100398:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100399:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010039e:	a8 01                	test   $0x1,%al
f01003a0:	0f 84 de 00 00 00    	je     f0100484 <kbd_proc_data+0xf8>
f01003a6:	b2 60                	mov    $0x60,%dl
f01003a8:	ec                   	in     (%dx),%al
f01003a9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003ab:	3c e0                	cmp    $0xe0,%al
f01003ad:	75 11                	jne    f01003c0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003af:	83 0d 88 d0 17 f0 40 	orl    $0x40,0xf017d088
		return 0;
f01003b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bb:	e9 c4 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003c0:	84 c0                	test   %al,%al
f01003c2:	79 37                	jns    f01003fb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c4:	8b 0d 88 d0 17 f0    	mov    0xf017d088,%ecx
f01003ca:	89 cb                	mov    %ecx,%ebx
f01003cc:	83 e3 40             	and    $0x40,%ebx
f01003cf:	83 e0 7f             	and    $0x7f,%eax
f01003d2:	85 db                	test   %ebx,%ebx
f01003d4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d7:	0f b6 d2             	movzbl %dl,%edx
f01003da:	0f b6 82 c0 48 10 f0 	movzbl -0xfefb740(%edx),%eax
f01003e1:	83 c8 40             	or     $0x40,%eax
f01003e4:	0f b6 c0             	movzbl %al,%eax
f01003e7:	f7 d0                	not    %eax
f01003e9:	21 c1                	and    %eax,%ecx
f01003eb:	89 0d 88 d0 17 f0    	mov    %ecx,0xf017d088
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 89 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fb:	8b 0d 88 d0 17 f0    	mov    0xf017d088,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	74 0e                	je     f0100414 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040e:	89 0d 88 d0 17 f0    	mov    %ecx,0xf017d088
	}

	shift |= shiftcode[data];
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 c0 48 10 f0 	movzbl -0xfefb740(%edx),%eax
f010041e:	0b 05 88 d0 17 f0    	or     0xf017d088,%eax
	shift ^= togglecode[data];
f0100424:	0f b6 8a c0 49 10 f0 	movzbl -0xfefb640(%edx),%ecx
f010042b:	31 c8                	xor    %ecx,%eax
f010042d:	a3 88 d0 17 f0       	mov    %eax,0xf017d088

	c = charcode[shift & (CTL | SHIFT)][data];
f0100432:	89 c1                	mov    %eax,%ecx
f0100434:	83 e1 03             	and    $0x3,%ecx
f0100437:	8b 0c 8d c0 4a 10 f0 	mov    -0xfefb540(,%ecx,4),%ecx
f010043e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100442:	a8 08                	test   $0x8,%al
f0100444:	74 19                	je     f010045f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100446:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100449:	83 fa 19             	cmp    $0x19,%edx
f010044c:	77 05                	ja     f0100453 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010044e:	83 eb 20             	sub    $0x20,%ebx
f0100451:	eb 0c                	jmp    f010045f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100453:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100456:	8d 53 20             	lea    0x20(%ebx),%edx
f0100459:	83 f9 19             	cmp    $0x19,%ecx
f010045c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010045f:	f7 d0                	not    %eax
f0100461:	a8 06                	test   $0x6,%al
f0100463:	75 1f                	jne    f0100484 <kbd_proc_data+0xf8>
f0100465:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010046b:	75 17                	jne    f0100484 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010046d:	c7 04 24 8d 48 10 f0 	movl   $0xf010488d,(%esp)
f0100474:	e8 75 2f 00 00       	call   f01033ee <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100479:	ba 92 00 00 00       	mov    $0x92,%edx
f010047e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100483:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100484:	89 d8                	mov    %ebx,%eax
f0100486:	83 c4 14             	add    $0x14,%esp
f0100489:	5b                   	pop    %ebx
f010048a:	5d                   	pop    %ebp
f010048b:	c3                   	ret    

f010048c <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f010048c:	55                   	push   %ebp
f010048d:	89 e5                	mov    %esp,%ebp
f010048f:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f0100492:	83 3d 60 ce 17 f0 00 	cmpl   $0x0,0xf017ce60
f0100499:	74 0a                	je     f01004a5 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f010049b:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a0:	e8 c5 fc ff ff       	call   f010016a <cons_intr>
}
f01004a5:	c9                   	leave  
f01004a6:	c3                   	ret    

f01004a7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004a7:	55                   	push   %ebp
f01004a8:	89 e5                	mov    %esp,%ebp
f01004aa:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004ad:	b8 8c 03 10 f0       	mov    $0xf010038c,%eax
f01004b2:	e8 b3 fc ff ff       	call   f010016a <cons_intr>
}
f01004b7:	c9                   	leave  
f01004b8:	c3                   	ret    

f01004b9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004b9:	55                   	push   %ebp
f01004ba:	89 e5                	mov    %esp,%ebp
f01004bc:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004bf:	e8 c8 ff ff ff       	call   f010048c <serial_intr>
	kbd_intr();
f01004c4:	e8 de ff ff ff       	call   f01004a7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004c9:	8b 15 80 d0 17 f0    	mov    0xf017d080,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004cf:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d4:	3b 15 84 d0 17 f0    	cmp    0xf017d084,%edx
f01004da:	74 1e                	je     f01004fa <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004dc:	0f b6 82 80 ce 17 f0 	movzbl -0xfe83180(%edx),%eax
f01004e3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f1:	0f 44 d1             	cmove  %ecx,%edx
f01004f4:	89 15 80 d0 17 f0    	mov    %edx,0xf017d080
		return c;
	}
	return 0;
}
f01004fa:	c9                   	leave  
f01004fb:	c3                   	ret    

f01004fc <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004fc:	55                   	push   %ebp
f01004fd:	89 e5                	mov    %esp,%ebp
f01004ff:	57                   	push   %edi
f0100500:	56                   	push   %esi
f0100501:	53                   	push   %ebx
f0100502:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100505:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010050c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100513:	5a a5 
	if (*cp != 0xA55A) {
f0100515:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010051c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100520:	74 11                	je     f0100533 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100522:	c7 05 8c d0 17 f0 b4 	movl   $0x3b4,0xf017d08c
f0100529:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010052c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100531:	eb 16                	jmp    f0100549 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100533:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010053a:	c7 05 8c d0 17 f0 d4 	movl   $0x3d4,0xf017d08c
f0100541:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100544:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100549:	8b 0d 8c d0 17 f0    	mov    0xf017d08c,%ecx
f010054f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100554:	89 ca                	mov    %ecx,%edx
f0100556:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100557:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010055a:	89 da                	mov    %ebx,%edx
f010055c:	ec                   	in     (%dx),%al
f010055d:	0f b6 f8             	movzbl %al,%edi
f0100560:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100563:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100568:	89 ca                	mov    %ecx,%edx
f010056a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010056b:	89 da                	mov    %ebx,%edx
f010056d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010056e:	89 35 90 d0 17 f0    	mov    %esi,0xf017d090
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100574:	0f b6 d8             	movzbl %al,%ebx
f0100577:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100579:	66 89 3d 94 d0 17 f0 	mov    %di,0xf017d094
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100580:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f0100585:	b8 00 00 00 00       	mov    $0x0,%eax
f010058a:	89 da                	mov    %ebx,%edx
f010058c:	ee                   	out    %al,(%dx)
f010058d:	b2 fb                	mov    $0xfb,%dl
f010058f:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100594:	ee                   	out    %al,(%dx)
f0100595:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010059a:	b8 0c 00 00 00       	mov    $0xc,%eax
f010059f:	89 ca                	mov    %ecx,%edx
f01005a1:	ee                   	out    %al,(%dx)
f01005a2:	b2 f9                	mov    $0xf9,%dl
f01005a4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 fb                	mov    $0xfb,%dl
f01005ac:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b2 fc                	mov    $0xfc,%dl
f01005b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b2 f9                	mov    $0xf9,%dl
f01005bc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	b2 fd                	mov    $0xfd,%dl
f01005c4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005c5:	3c ff                	cmp    $0xff,%al
f01005c7:	0f 95 c0             	setne  %al
f01005ca:	0f b6 c0             	movzbl %al,%eax
f01005cd:	89 c6                	mov    %eax,%esi
f01005cf:	a3 60 ce 17 f0       	mov    %eax,0xf017ce60
f01005d4:	89 da                	mov    %ebx,%edx
f01005d6:	ec                   	in     (%dx),%al
f01005d7:	89 ca                	mov    %ecx,%edx
f01005d9:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005da:	85 f6                	test   %esi,%esi
f01005dc:	75 0c                	jne    f01005ea <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f01005de:	c7 04 24 99 48 10 f0 	movl   $0xf0104899,(%esp)
f01005e5:	e8 04 2e 00 00       	call   f01033ee <cprintf>
}
f01005ea:	83 c4 1c             	add    $0x1c,%esp
f01005ed:	5b                   	pop    %ebx
f01005ee:	5e                   	pop    %esi
f01005ef:	5f                   	pop    %edi
f01005f0:	5d                   	pop    %ebp
f01005f1:	c3                   	ret    

f01005f2 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f2:	55                   	push   %ebp
f01005f3:	89 e5                	mov    %esp,%ebp
f01005f5:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01005fb:	e8 a7 fb ff ff       	call   f01001a7 <cons_putc>
}
f0100600:	c9                   	leave  
f0100601:	c3                   	ret    

f0100602 <getchar>:

int
getchar(void)
{
f0100602:	55                   	push   %ebp
f0100603:	89 e5                	mov    %esp,%ebp
f0100605:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100608:	e8 ac fe ff ff       	call   f01004b9 <cons_getc>
f010060d:	85 c0                	test   %eax,%eax
f010060f:	74 f7                	je     f0100608 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100611:	c9                   	leave  
f0100612:	c3                   	ret    

f0100613 <iscons>:

int
iscons(int fdnum)
{
f0100613:	55                   	push   %ebp
f0100614:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100616:	b8 01 00 00 00       	mov    $0x1,%eax
f010061b:	5d                   	pop    %ebp
f010061c:	c3                   	ret    
f010061d:	00 00                	add    %al,(%eax)
	...

f0100620 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100620:	55                   	push   %ebp
f0100621:	89 e5                	mov    %esp,%ebp
f0100623:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100626:	c7 04 24 d0 4a 10 f0 	movl   $0xf0104ad0,(%esp)
f010062d:	e8 bc 2d 00 00       	call   f01033ee <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 90 4b 10 f0 	movl   $0xf0104b90,(%esp)
f0100649:	e8 a0 2d 00 00       	call   f01033ee <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 35 48 10 	movl   $0x104835,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 35 48 10 	movl   $0xf0104835,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 b4 4b 10 f0 	movl   $0xf0104bb4,(%esp)
f0100665:	e8 84 2d 00 00       	call   f01033ee <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 33 ce 17 	movl   $0x17ce33,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 33 ce 17 	movl   $0xf017ce33,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 d8 4b 10 f0 	movl   $0xf0104bd8,(%esp)
f0100681:	e8 68 2d 00 00       	call   f01033ee <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 4c dd 17 	movl   $0x17dd4c,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 4c dd 17 	movl   $0xf017dd4c,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 fc 4b 10 f0 	movl   $0xf0104bfc,(%esp)
f010069d:	e8 4c 2d 00 00       	call   f01033ee <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 4b e1 17 f0       	mov    $0xf017e14b,%eax
f01006a7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006ac:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006b2:	85 c0                	test   %eax,%eax
f01006b4:	0f 48 c2             	cmovs  %edx,%eax
f01006b7:	c1 f8 0a             	sar    $0xa,%eax
f01006ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006be:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f01006c5:	e8 24 2d 00 00       	call   f01033ee <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01006cf:	c9                   	leave  
f01006d0:	c3                   	ret    

f01006d1 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006d1:	55                   	push   %ebp
f01006d2:	89 e5                	mov    %esp,%ebp
f01006d4:	53                   	push   %ebx
f01006d5:	83 ec 14             	sub    $0x14,%esp
f01006d8:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006dd:	8b 83 24 4d 10 f0    	mov    -0xfefb2dc(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 20 4d 10 f0    	mov    -0xfefb2e0(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 e9 4a 10 f0 	movl   $0xf0104ae9,(%esp)
f01006f8:	e8 f1 2c 00 00       	call   f01033ee <cprintf>
f01006fd:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100700:	83 fb 24             	cmp    $0x24,%ebx
f0100703:	75 d8                	jne    f01006dd <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100705:	b8 00 00 00 00       	mov    $0x0,%eax
f010070a:	83 c4 14             	add    $0x14,%esp
f010070d:	5b                   	pop    %ebx
f010070e:	5d                   	pop    %ebp
f010070f:	c3                   	ret    

f0100710 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	57                   	push   %edi
f0100714:	56                   	push   %esi
f0100715:	53                   	push   %ebx
f0100716:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100719:	89 eb                	mov    %ebp,%ebx
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();
f010071b:	89 de                	mov    %ebx,%esi

    cprintf ("Stack backtrace:\n");
f010071d:	c7 04 24 f2 4a 10 f0 	movl   $0xf0104af2,(%esp)
f0100724:	e8 c5 2c 00 00       	call   f01033ee <cprintf>
    while (ebp != 0) {
f0100729:	85 db                	test   %ebx,%ebx
f010072b:	0f 84 9a 00 00 00    	je     f01007cb <mon_backtrace+0xbb>
        
        eip = (uint32_t*) ebp[1];
f0100731:	8b 5e 04             	mov    0x4(%esi),%ebx

        arg0 = ebp[2];
f0100734:	8b 46 08             	mov    0x8(%esi),%eax
f0100737:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        arg1 = ebp[3];
f010073a:	8b 46 0c             	mov    0xc(%esi),%eax
f010073d:	89 45 c0             	mov    %eax,-0x40(%ebp)
        arg2 = ebp[4];
f0100740:	8b 46 10             	mov    0x10(%esi),%eax
f0100743:	89 45 bc             	mov    %eax,-0x44(%ebp)
        arg3 = ebp[5];
f0100746:	8b 46 14             	mov    0x14(%esi),%eax
f0100749:	89 45 b8             	mov    %eax,-0x48(%ebp)
        arg4 = ebp[6];
f010074c:	8b 7e 18             	mov    0x18(%esi),%edi
	
	// Your code here.
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;
f010074f:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100752:	89 44 24 04          	mov    %eax,0x4(%esp)
        arg1 = ebp[3];
        arg2 = ebp[4];
        arg3 = ebp[5];
        arg4 = ebp[6];
        
        debuginfo_eip ((uintptr_t) eip, eipinfo);
f0100756:	89 1c 24             	mov    %ebx,(%esp)
f0100759:	e8 96 31 00 00       	call   f01038f4 <debuginfo_eip>

        cprintf ("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg0, arg1, arg2, arg3, arg4);
f010075e:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
f0100762:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0100765:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100769:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010076c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100770:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100773:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100777:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f010077a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010077e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100782:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100786:	c7 04 24 4c 4c 10 f0 	movl   $0xf0104c4c,(%esp)
f010078d:	e8 5c 2c 00 00       	call   f01033ee <cprintf>
        cprintf ("         %s:%d: %.*s+%d\n", 
f0100792:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f0100795:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f0100799:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010079c:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007a3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007aa:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007ae:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b5:	c7 04 24 04 4b 10 f0 	movl   $0xf0104b04,(%esp)
f01007bc:	e8 2d 2c 00 00       	call   f01033ee <cprintf>
            eipinfo->eip_line, 
            eipinfo->eip_fn_namelen, eipinfo->eip_fn_name,
            (uint32_t) eip - eipinfo->eip_fn_addr);


        ebp = (uint32_t*) ebp[0];
f01007c1:	8b 36                	mov    (%esi),%esi
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();

    cprintf ("Stack backtrace:\n");
    while (ebp != 0) {
f01007c3:	85 f6                	test   %esi,%esi
f01007c5:	0f 85 66 ff ff ff    	jne    f0100731 <mon_backtrace+0x21>


        ebp = (uint32_t*) ebp[0];
    }
	return 0;
}
f01007cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01007d0:	83 c4 5c             	add    $0x5c,%esp
f01007d3:	5b                   	pop    %ebx
f01007d4:	5e                   	pop    %esi
f01007d5:	5f                   	pop    %edi
f01007d6:	5d                   	pop    %ebp
f01007d7:	c3                   	ret    

f01007d8 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007d8:	55                   	push   %ebp
f01007d9:	89 e5                	mov    %esp,%ebp
f01007db:	57                   	push   %edi
f01007dc:	56                   	push   %esi
f01007dd:	53                   	push   %ebx
f01007de:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007e1:	c7 04 24 84 4c 10 f0 	movl   $0xf0104c84,(%esp)
f01007e8:	e8 01 2c 00 00       	call   f01033ee <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ed:	c7 04 24 a8 4c 10 f0 	movl   $0xf0104ca8,(%esp)
f01007f4:	e8 f5 2b 00 00       	call   f01033ee <cprintf>

	if (tf != NULL)
f01007f9:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01007fd:	74 0b                	je     f010080a <monitor+0x32>
		print_trapframe(tf);
f01007ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0100802:	89 04 24             	mov    %eax,(%esp)
f0100805:	e8 0c 2d 00 00       	call   f0103516 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f010080a:	c7 04 24 1d 4b 10 f0 	movl   $0xf0104b1d,(%esp)
f0100811:	e8 9a 38 00 00       	call   f01040b0 <readline>
f0100816:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100818:	85 c0                	test   %eax,%eax
f010081a:	74 ee                	je     f010080a <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010081c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100823:	be 00 00 00 00       	mov    $0x0,%esi
f0100828:	eb 06                	jmp    f0100830 <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010082a:	c6 03 00             	movb   $0x0,(%ebx)
f010082d:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100830:	0f b6 03             	movzbl (%ebx),%eax
f0100833:	84 c0                	test   %al,%al
f0100835:	74 6a                	je     f01008a1 <monitor+0xc9>
f0100837:	0f be c0             	movsbl %al,%eax
f010083a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010083e:	c7 04 24 21 4b 10 f0 	movl   $0xf0104b21,(%esp)
f0100845:	e8 91 3a 00 00       	call   f01042db <strchr>
f010084a:	85 c0                	test   %eax,%eax
f010084c:	75 dc                	jne    f010082a <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f010084e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100851:	74 4e                	je     f01008a1 <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100853:	83 fe 0f             	cmp    $0xf,%esi
f0100856:	75 16                	jne    f010086e <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100858:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010085f:	00 
f0100860:	c7 04 24 26 4b 10 f0 	movl   $0xf0104b26,(%esp)
f0100867:	e8 82 2b 00 00       	call   f01033ee <cprintf>
f010086c:	eb 9c                	jmp    f010080a <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f010086e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100872:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100875:	0f b6 03             	movzbl (%ebx),%eax
f0100878:	84 c0                	test   %al,%al
f010087a:	75 0c                	jne    f0100888 <monitor+0xb0>
f010087c:	eb b2                	jmp    f0100830 <monitor+0x58>
			buf++;
f010087e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100881:	0f b6 03             	movzbl (%ebx),%eax
f0100884:	84 c0                	test   %al,%al
f0100886:	74 a8                	je     f0100830 <monitor+0x58>
f0100888:	0f be c0             	movsbl %al,%eax
f010088b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088f:	c7 04 24 21 4b 10 f0 	movl   $0xf0104b21,(%esp)
f0100896:	e8 40 3a 00 00       	call   f01042db <strchr>
f010089b:	85 c0                	test   %eax,%eax
f010089d:	74 df                	je     f010087e <monitor+0xa6>
f010089f:	eb 8f                	jmp    f0100830 <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f01008a1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008a8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008a9:	85 f6                	test   %esi,%esi
f01008ab:	0f 84 59 ff ff ff    	je     f010080a <monitor+0x32>
f01008b1:	bb 20 4d 10 f0       	mov    $0xf0104d20,%ebx
f01008b6:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008bb:	8b 03                	mov    (%ebx),%eax
f01008bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008c1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008c4:	89 04 24             	mov    %eax,(%esp)
f01008c7:	e8 94 39 00 00       	call   f0104260 <strcmp>
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	75 24                	jne    f01008f4 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f01008d0:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01008d3:	8b 55 08             	mov    0x8(%ebp),%edx
f01008d6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008da:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008dd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008e1:	89 34 24             	mov    %esi,(%esp)
f01008e4:	ff 14 85 28 4d 10 f0 	call   *-0xfefb2d8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008eb:	85 c0                	test   %eax,%eax
f01008ed:	78 28                	js     f0100917 <monitor+0x13f>
f01008ef:	e9 16 ff ff ff       	jmp    f010080a <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008f4:	83 c7 01             	add    $0x1,%edi
f01008f7:	83 c3 0c             	add    $0xc,%ebx
f01008fa:	83 ff 03             	cmp    $0x3,%edi
f01008fd:	75 bc                	jne    f01008bb <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ff:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100902:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100906:	c7 04 24 43 4b 10 f0 	movl   $0xf0104b43,(%esp)
f010090d:	e8 dc 2a 00 00       	call   f01033ee <cprintf>
f0100912:	e9 f3 fe ff ff       	jmp    f010080a <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100917:	83 c4 5c             	add    $0x5c,%esp
f010091a:	5b                   	pop    %ebx
f010091b:	5e                   	pop    %esi
f010091c:	5f                   	pop    %edi
f010091d:	5d                   	pop    %ebp
f010091e:	c3                   	ret    

f010091f <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010091f:	55                   	push   %ebp
f0100920:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100922:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100925:	5d                   	pop    %ebp
f0100926:	c3                   	ret    
	...

f0100928 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100928:	55                   	push   %ebp
f0100929:	89 e5                	mov    %esp,%ebp
f010092b:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010092e:	89 d1                	mov    %edx,%ecx
f0100930:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100933:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100936:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010093b:	f6 c1 01             	test   $0x1,%cl
f010093e:	74 57                	je     f0100997 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100940:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100946:	89 c8                	mov    %ecx,%eax
f0100948:	c1 e8 0c             	shr    $0xc,%eax
f010094b:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f0100951:	72 20                	jb     f0100973 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100953:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100957:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f010095e:	f0 
f010095f:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0100966:	00 
f0100967:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010096e:	e8 21 f7 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100973:	c1 ea 0c             	shr    $0xc,%edx
f0100976:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010097c:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100983:	89 c2                	mov    %eax,%edx
f0100985:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100988:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010098d:	85 d2                	test   %edx,%edx
f010098f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100994:	0f 44 c2             	cmove  %edx,%eax
}
f0100997:	c9                   	leave  
f0100998:	c3                   	ret    

f0100999 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100999:	55                   	push   %ebp
f010099a:	89 e5                	mov    %esp,%ebp
f010099c:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010099f:	83 3d 9c d0 17 f0 00 	cmpl   $0x0,0xf017d09c
f01009a6:	75 11                	jne    f01009b9 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009a8:	ba 4b ed 17 f0       	mov    $0xf017ed4b,%edx
f01009ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009b3:	89 15 9c d0 17 f0    	mov    %edx,0xf017d09c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    assert((uint32_t)nextfree % PGSIZE == 0);
f01009b9:	8b 15 9c d0 17 f0    	mov    0xf017d09c,%edx
f01009bf:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01009c5:	74 24                	je     f01009eb <boot_alloc+0x52>
f01009c7:	c7 44 24 0c 68 4d 10 	movl   $0xf0104d68,0xc(%esp)
f01009ce:	f0 
f01009cf:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01009d6:	f0 
f01009d7:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
f01009de:	00 
f01009df:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01009e6:	e8 a9 f6 ff ff       	call   f0100094 <_panic>
    result = nextfree;
    nextfree += n;
    nextfree = ROUNDUP(nextfree, PGSIZE);
f01009eb:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01009f2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009f7:	a3 9c d0 17 f0       	mov    %eax,0xf017d09c

	return result;
}
f01009fc:	89 d0                	mov    %edx,%eax
f01009fe:	c9                   	leave  
f01009ff:	c3                   	ret    

f0100a00 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a00:	55                   	push   %ebp
f0100a01:	89 e5                	mov    %esp,%ebp
f0100a03:	83 ec 18             	sub    $0x18,%esp
f0100a06:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a09:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a0c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a0e:	89 04 24             	mov    %eax,(%esp)
f0100a11:	e8 6a 29 00 00       	call   f0103380 <mc146818_read>
f0100a16:	89 c6                	mov    %eax,%esi
f0100a18:	83 c3 01             	add    $0x1,%ebx
f0100a1b:	89 1c 24             	mov    %ebx,(%esp)
f0100a1e:	e8 5d 29 00 00       	call   f0103380 <mc146818_read>
f0100a23:	c1 e0 08             	shl    $0x8,%eax
f0100a26:	09 f0                	or     %esi,%eax
}
f0100a28:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a2b:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a2e:	89 ec                	mov    %ebp,%esp
f0100a30:	5d                   	pop    %ebp
f0100a31:	c3                   	ret    

f0100a32 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a32:	55                   	push   %ebp
f0100a33:	89 e5                	mov    %esp,%ebp
f0100a35:	57                   	push   %edi
f0100a36:	56                   	push   %esi
f0100a37:	53                   	push   %ebx
f0100a38:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a3b:	83 f8 01             	cmp    $0x1,%eax
f0100a3e:	19 f6                	sbb    %esi,%esi
f0100a40:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a46:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a49:	8b 1d a0 d0 17 f0    	mov    0xf017d0a0,%ebx
f0100a4f:	85 db                	test   %ebx,%ebx
f0100a51:	75 1c                	jne    f0100a6f <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a53:	c7 44 24 08 8c 4d 10 	movl   $0xf0104d8c,0x8(%esp)
f0100a5a:	f0 
f0100a5b:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0100a62:	00 
f0100a63:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100a6a:	e8 25 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a6f:	85 c0                	test   %eax,%eax
f0100a71:	74 50                	je     f0100ac3 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a73:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a76:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a79:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a7c:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a7f:	89 d8                	mov    %ebx,%eax
f0100a81:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0100a87:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a8a:	c1 e8 16             	shr    $0x16,%eax
f0100a8d:	39 c6                	cmp    %eax,%esi
f0100a8f:	0f 96 c0             	setbe  %al
f0100a92:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100a95:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100a99:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100a9b:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a9f:	8b 1b                	mov    (%ebx),%ebx
f0100aa1:	85 db                	test   %ebx,%ebx
f0100aa3:	75 da                	jne    f0100a7f <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100aa5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100aa8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100aae:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ab1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ab4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ab6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ab9:	89 1d a0 d0 17 f0    	mov    %ebx,0xf017d0a0
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100abf:	85 db                	test   %ebx,%ebx
f0100ac1:	74 67                	je     f0100b2a <check_page_free_list+0xf8>
f0100ac3:	89 d8                	mov    %ebx,%eax
f0100ac5:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0100acb:	c1 f8 03             	sar    $0x3,%eax
f0100ace:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ad1:	89 c2                	mov    %eax,%edx
f0100ad3:	c1 ea 16             	shr    $0x16,%edx
f0100ad6:	39 d6                	cmp    %edx,%esi
f0100ad8:	76 4a                	jbe    f0100b24 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ada:	89 c2                	mov    %eax,%edx
f0100adc:	c1 ea 0c             	shr    $0xc,%edx
f0100adf:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0100ae5:	72 20                	jb     f0100b07 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ae7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100aeb:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0100af2:	f0 
f0100af3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100afa:	00 
f0100afb:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0100b02:	e8 8d f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b07:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b0e:	00 
f0100b0f:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b16:	00 
	return (void *)(pa + KERNBASE);
f0100b17:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b1c:	89 04 24             	mov    %eax,(%esp)
f0100b1f:	e8 12 38 00 00       	call   f0104336 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b24:	8b 1b                	mov    (%ebx),%ebx
f0100b26:	85 db                	test   %ebx,%ebx
f0100b28:	75 99                	jne    f0100ac3 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b2f:	e8 65 fe ff ff       	call   f0100999 <boot_alloc>
f0100b34:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b37:	8b 15 a0 d0 17 f0    	mov    0xf017d0a0,%edx
f0100b3d:	85 d2                	test   %edx,%edx
f0100b3f:	0f 84 f6 01 00 00    	je     f0100d3b <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b45:	8b 1d 48 dd 17 f0    	mov    0xf017dd48,%ebx
f0100b4b:	39 da                	cmp    %ebx,%edx
f0100b4d:	72 4d                	jb     f0100b9c <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b4f:	a1 40 dd 17 f0       	mov    0xf017dd40,%eax
f0100b54:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b57:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b5a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b5d:	39 c2                	cmp    %eax,%edx
f0100b5f:	73 64                	jae    f0100bc5 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b61:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b64:	89 d0                	mov    %edx,%eax
f0100b66:	29 d8                	sub    %ebx,%eax
f0100b68:	a8 07                	test   $0x7,%al
f0100b6a:	0f 85 82 00 00 00    	jne    f0100bf2 <check_page_free_list+0x1c0>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b70:	c1 f8 03             	sar    $0x3,%eax
f0100b73:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b76:	85 c0                	test   %eax,%eax
f0100b78:	0f 84 a2 00 00 00    	je     f0100c20 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b7e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b83:	0f 84 c2 00 00 00    	je     f0100c4b <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b89:	be 00 00 00 00       	mov    $0x0,%esi
f0100b8e:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b93:	e9 d7 00 00 00       	jmp    f0100c6f <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b98:	39 da                	cmp    %ebx,%edx
f0100b9a:	73 24                	jae    f0100bc0 <check_page_free_list+0x18e>
f0100b9c:	c7 44 24 0c 10 55 10 	movl   $0xf0105510,0xc(%esp)
f0100ba3:	f0 
f0100ba4:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100bab:	f0 
f0100bac:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0100bb3:	00 
f0100bb4:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100bbb:	e8 d4 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bc0:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bc3:	72 24                	jb     f0100be9 <check_page_free_list+0x1b7>
f0100bc5:	c7 44 24 0c 1c 55 10 	movl   $0xf010551c,0xc(%esp)
f0100bcc:	f0 
f0100bcd:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100bd4:	f0 
f0100bd5:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0100bdc:	00 
f0100bdd:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100be4:	e8 ab f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100be9:	89 d0                	mov    %edx,%eax
f0100beb:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bee:	a8 07                	test   $0x7,%al
f0100bf0:	74 24                	je     f0100c16 <check_page_free_list+0x1e4>
f0100bf2:	c7 44 24 0c b0 4d 10 	movl   $0xf0104db0,0xc(%esp)
f0100bf9:	f0 
f0100bfa:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100c01:	f0 
f0100c02:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0100c09:	00 
f0100c0a:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100c11:	e8 7e f4 ff ff       	call   f0100094 <_panic>
f0100c16:	c1 f8 03             	sar    $0x3,%eax
f0100c19:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c1c:	85 c0                	test   %eax,%eax
f0100c1e:	75 24                	jne    f0100c44 <check_page_free_list+0x212>
f0100c20:	c7 44 24 0c 30 55 10 	movl   $0xf0105530,0xc(%esp)
f0100c27:	f0 
f0100c28:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100c2f:	f0 
f0100c30:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0100c37:	00 
f0100c38:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100c3f:	e8 50 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c44:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c49:	75 24                	jne    f0100c6f <check_page_free_list+0x23d>
f0100c4b:	c7 44 24 0c 41 55 10 	movl   $0xf0105541,0xc(%esp)
f0100c52:	f0 
f0100c53:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100c5a:	f0 
f0100c5b:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0100c62:	00 
f0100c63:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100c6a:	e8 25 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c6f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c74:	75 24                	jne    f0100c9a <check_page_free_list+0x268>
f0100c76:	c7 44 24 0c e4 4d 10 	movl   $0xf0104de4,0xc(%esp)
f0100c7d:	f0 
f0100c7e:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100c85:	f0 
f0100c86:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0100c8d:	00 
f0100c8e:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100c95:	e8 fa f3 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c9a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c9f:	75 24                	jne    f0100cc5 <check_page_free_list+0x293>
f0100ca1:	c7 44 24 0c 5a 55 10 	movl   $0xf010555a,0xc(%esp)
f0100ca8:	f0 
f0100ca9:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100cb0:	f0 
f0100cb1:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100cb8:	00 
f0100cb9:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100cc0:	e8 cf f3 ff ff       	call   f0100094 <_panic>
f0100cc5:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cc7:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100ccc:	76 57                	jbe    f0100d25 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cce:	c1 e8 0c             	shr    $0xc,%eax
f0100cd1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100cd4:	77 20                	ja     f0100cf6 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cda:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0100ce1:	f0 
f0100ce2:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100ce9:	00 
f0100cea:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0100cf1:	e8 9e f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100cf6:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100cfc:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100cff:	76 29                	jbe    f0100d2a <check_page_free_list+0x2f8>
f0100d01:	c7 44 24 0c 08 4e 10 	movl   $0xf0104e08,0xc(%esp)
f0100d08:	f0 
f0100d09:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100d10:	f0 
f0100d11:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100d18:	00 
f0100d19:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100d20:	e8 6f f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d25:	83 c7 01             	add    $0x1,%edi
f0100d28:	eb 03                	jmp    f0100d2d <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d2a:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2d:	8b 12                	mov    (%edx),%edx
f0100d2f:	85 d2                	test   %edx,%edx
f0100d31:	0f 85 61 fe ff ff    	jne    f0100b98 <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d37:	85 ff                	test   %edi,%edi
f0100d39:	7f 24                	jg     f0100d5f <check_page_free_list+0x32d>
f0100d3b:	c7 44 24 0c 74 55 10 	movl   $0xf0105574,0xc(%esp)
f0100d42:	f0 
f0100d43:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100d4a:	f0 
f0100d4b:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0100d52:	00 
f0100d53:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100d5a:	e8 35 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d5f:	85 f6                	test   %esi,%esi
f0100d61:	7f 24                	jg     f0100d87 <check_page_free_list+0x355>
f0100d63:	c7 44 24 0c 86 55 10 	movl   $0xf0105586,0xc(%esp)
f0100d6a:	f0 
f0100d6b:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100d72:	f0 
f0100d73:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0100d7a:	00 
f0100d7b:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100d82:	e8 0d f3 ff ff       	call   f0100094 <_panic>
}
f0100d87:	83 c4 3c             	add    $0x3c,%esp
f0100d8a:	5b                   	pop    %ebx
f0100d8b:	5e                   	pop    %esi
f0100d8c:	5f                   	pop    %edi
f0100d8d:	5d                   	pop    %ebp
f0100d8e:	c3                   	ret    

f0100d8f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d8f:	55                   	push   %ebp
f0100d90:	89 e5                	mov    %esp,%ebp
f0100d92:	57                   	push   %edi
f0100d93:	56                   	push   %esi
f0100d94:	53                   	push   %ebx
f0100d95:	83 ec 1c             	sub    $0x1c,%esp
	// free pages!
	size_t i;
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
f0100d98:	c7 05 a0 d0 17 f0 00 	movl   $0x0,0xf017d0a0
f0100d9f:	00 00 00 
    first_free_page = (char *) boot_alloc(0);
f0100da2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100da7:	e8 ed fb ff ff       	call   f0100999 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100dac:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100db1:	77 20                	ja     f0100dd3 <page_init+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100db3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100db7:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0100dbe:	f0 
f0100dbf:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
f0100dc6:	00 
f0100dc7:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100dce:	e8 c1 f2 ff ff       	call   f0100094 <_panic>
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
f0100dd3:	8b 15 48 dd 17 f0    	mov    0xf017dd48,%edx
f0100dd9:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
    for (i = 1; i < npages_basemem; i++) {
f0100ddf:	8b 15 98 d0 17 f0    	mov    0xf017d098,%edx
f0100de5:	83 fa 01             	cmp    $0x1,%edx
f0100de8:	76 37                	jbe    f0100e21 <page_init+0x92>
f0100dea:	8b 3d a0 d0 17 f0    	mov    0xf017d0a0,%edi
f0100df0:	b9 01 00 00 00       	mov    $0x1,%ecx
        pages[i].pp_ref = 0;
f0100df5:	8d 1c cd 00 00 00 00 	lea    0x0(,%ecx,8),%ebx
f0100dfc:	8b 35 48 dd 17 f0    	mov    0xf017dd48,%esi
f0100e02:	66 c7 44 1e 04 00 00 	movw   $0x0,0x4(%esi,%ebx,1)
		pages[i].pp_link = page_free_list;
f0100e09:	89 3c ce             	mov    %edi,(%esi,%ecx,8)
		page_free_list = &pages[i];
f0100e0c:	89 df                	mov    %ebx,%edi
f0100e0e:	03 3d 48 dd 17 f0    	add    0xf017dd48,%edi
    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
    for (i = 1; i < npages_basemem; i++) {
f0100e14:	83 c1 01             	add    $0x1,%ecx
f0100e17:	39 d1                	cmp    %edx,%ecx
f0100e19:	72 da                	jb     f0100df5 <page_init+0x66>
f0100e1b:	89 3d a0 d0 17 f0    	mov    %edi,0xf017d0a0
        pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);
f0100e21:	89 d1                	mov    %edx,%ecx
f0100e23:	c1 e1 0c             	shl    $0xc,%ecx
f0100e26:	81 f9 00 00 0a 00    	cmp    $0xa0000,%ecx
f0100e2c:	74 24                	je     f0100e52 <page_init+0xc3>
f0100e2e:	c7 44 24 0c 74 4e 10 	movl   $0xf0104e74,0xc(%esp)
f0100e35:	f0 
f0100e36:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0100e3d:	f0 
f0100e3e:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0100e45:	00 
f0100e46:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100e4d:	e8 42 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e52:	05 00 00 00 10       	add    $0x10000000,%eax
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;
f0100e57:	c1 e8 0c             	shr    $0xc,%eax
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e5a:	39 d0                	cmp    %edx,%eax
f0100e5c:	76 14                	jbe    f0100e72 <page_init+0xe3>
        pages[i].pp_ref = 1;
f0100e5e:	8b 0d 48 dd 17 f0    	mov    0xf017dd48,%ecx
f0100e64:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e6b:	83 c2 01             	add    $0x1,%edx
f0100e6e:	39 d0                	cmp    %edx,%eax
f0100e70:	77 f2                	ja     f0100e64 <page_init+0xd5>
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100e72:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f0100e78:	73 39                	jae    f0100eb3 <page_init+0x124>
f0100e7a:	8b 1d a0 d0 17 f0    	mov    0xf017d0a0,%ebx
f0100e80:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e87:	8b 0d 48 dd 17 f0    	mov    0xf017dd48,%ecx
f0100e8d:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100e94:	89 1c 11             	mov    %ebx,(%ecx,%edx,1)
		page_free_list = &pages[i];
f0100e97:	89 d3                	mov    %edx,%ebx
f0100e99:	03 1d 48 dd 17 f0    	add    0xf017dd48,%ebx
    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100e9f:	83 c0 01             	add    $0x1,%eax
f0100ea2:	83 c2 08             	add    $0x8,%edx
f0100ea5:	39 05 40 dd 17 f0    	cmp    %eax,0xf017dd40
f0100eab:	77 da                	ja     f0100e87 <page_init+0xf8>
f0100ead:	89 1d a0 d0 17 f0    	mov    %ebx,0xf017d0a0
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f0100eb3:	83 c4 1c             	add    $0x1c,%esp
f0100eb6:	5b                   	pop    %ebx
f0100eb7:	5e                   	pop    %esi
f0100eb8:	5f                   	pop    %edi
f0100eb9:	5d                   	pop    %ebp
f0100eba:	c3                   	ret    

f0100ebb <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100ebb:	55                   	push   %ebp
f0100ebc:	89 e5                	mov    %esp,%ebp
f0100ebe:	53                   	push   %ebx
f0100ebf:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
    struct Page* pg;
    if (page_free_list == NULL)
f0100ec2:	8b 1d a0 d0 17 f0    	mov    0xf017d0a0,%ebx
f0100ec8:	85 db                	test   %ebx,%ebx
f0100eca:	74 65                	je     f0100f31 <page_alloc+0x76>
        return NULL;
    pg = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100ecc:	8b 03                	mov    (%ebx),%eax
f0100ece:	a3 a0 d0 17 f0       	mov    %eax,0xf017d0a0

    if (alloc_flags & ALLOC_ZERO) {
f0100ed3:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ed7:	74 58                	je     f0100f31 <page_alloc+0x76>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ed9:	89 d8                	mov    %ebx,%eax
f0100edb:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0100ee1:	c1 f8 03             	sar    $0x3,%eax
f0100ee4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ee7:	89 c2                	mov    %eax,%edx
f0100ee9:	c1 ea 0c             	shr    $0xc,%edx
f0100eec:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0100ef2:	72 20                	jb     f0100f14 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ef4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ef8:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0100eff:	f0 
f0100f00:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f07:	00 
f0100f08:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0100f0f:	e8 80 f1 ff ff       	call   f0100094 <_panic>
        memset(page2kva(pg), 0, PGSIZE);
f0100f14:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f1b:	00 
f0100f1c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f23:	00 
	return (void *)(pa + KERNBASE);
f0100f24:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f29:	89 04 24             	mov    %eax,(%esp)
f0100f2c:	e8 05 34 00 00       	call   f0104336 <memset>
    }
    return pg;
}
f0100f31:	89 d8                	mov    %ebx,%eax
f0100f33:	83 c4 14             	add    $0x14,%esp
f0100f36:	5b                   	pop    %ebx
f0100f37:	5d                   	pop    %ebp
f0100f38:	c3                   	ret    

f0100f39 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f39:	55                   	push   %ebp
f0100f3a:	89 e5                	mov    %esp,%ebp
f0100f3c:	83 ec 18             	sub    $0x18,%esp
f0100f3f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
    if (pp->pp_ref != 0) {
f0100f42:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f47:	74 20                	je     f0100f69 <page_free+0x30>
        panic("page_free: %p pp_ref error\n", pp);
f0100f49:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f4d:	c7 44 24 08 97 55 10 	movl   $0xf0105597,0x8(%esp)
f0100f54:	f0 
f0100f55:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0100f5c:	00 
f0100f5d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100f64:	e8 2b f1 ff ff       	call   f0100094 <_panic>
    }

    pp->pp_link = page_free_list;
f0100f69:	8b 15 a0 d0 17 f0    	mov    0xf017d0a0,%edx
f0100f6f:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;
f0100f71:	a3 a0 d0 17 f0       	mov    %eax,0xf017d0a0
}
f0100f76:	c9                   	leave  
f0100f77:	c3                   	ret    

f0100f78 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f78:	55                   	push   %ebp
f0100f79:	89 e5                	mov    %esp,%ebp
f0100f7b:	83 ec 18             	sub    $0x18,%esp
f0100f7e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f81:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f85:	83 ea 01             	sub    $0x1,%edx
f0100f88:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f8c:	66 85 d2             	test   %dx,%dx
f0100f8f:	75 08                	jne    f0100f99 <page_decref+0x21>
		page_free(pp);
f0100f91:	89 04 24             	mov    %eax,(%esp)
f0100f94:	e8 a0 ff ff ff       	call   f0100f39 <page_free>
}
f0100f99:	c9                   	leave  
f0100f9a:	c3                   	ret    

f0100f9b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f9b:	55                   	push   %ebp
f0100f9c:	89 e5                	mov    %esp,%ebp
f0100f9e:	56                   	push   %esi
f0100f9f:	53                   	push   %ebx
f0100fa0:	83 ec 10             	sub    $0x10,%esp
f0100fa3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fa6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
    if (pgdir == NULL) {
f0100fa9:	85 c0                	test   %eax,%eax
f0100fab:	75 1c                	jne    f0100fc9 <pgdir_walk+0x2e>
        panic("pgdir_walk: pgdir is null");
f0100fad:	c7 44 24 08 b3 55 10 	movl   $0xf01055b3,0x8(%esp)
f0100fb4:	f0 
f0100fb5:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
f0100fbc:	00 
f0100fbd:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0100fc4:	e8 cb f0 ff ff       	call   f0100094 <_panic>
    }

    pde_t pde;
    pte_t* pt;

    pde = pgdir[PDX(va)];
f0100fc9:	89 f2                	mov    %esi,%edx
f0100fcb:	c1 ea 16             	shr    $0x16,%edx
f0100fce:	8d 1c 90             	lea    (%eax,%edx,4),%ebx
f0100fd1:	8b 03                	mov    (%ebx),%eax

    if (pde & PTE_P) {
f0100fd3:	a8 01                	test   $0x1,%al
f0100fd5:	74 47                	je     f010101e <pgdir_walk+0x83>
        pt = KADDR(PTE_ADDR(pde));
f0100fd7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fdc:	89 c2                	mov    %eax,%edx
f0100fde:	c1 ea 0c             	shr    $0xc,%edx
f0100fe1:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0100fe7:	72 20                	jb     f0101009 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fe9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fed:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0100ff4:	f0 
f0100ff5:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f0100ffc:	00 
f0100ffd:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101004:	e8 8b f0 ff ff       	call   f0100094 <_panic>
        return &pt[PTX(va)];
f0101009:	c1 ee 0a             	shr    $0xa,%esi
f010100c:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101012:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101019:	e9 85 00 00 00       	jmp    f01010a3 <pgdir_walk+0x108>
    }

    if (!create) {
f010101e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101022:	74 73                	je     f0101097 <pgdir_walk+0xfc>
        return NULL;
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
f0101024:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010102b:	e8 8b fe ff ff       	call   f0100ebb <page_alloc>
f0101030:	85 c0                	test   %eax,%eax
f0101032:	74 6a                	je     f010109e <pgdir_walk+0x103>
        return NULL;
    pp->pp_ref++;
f0101034:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101039:	89 c2                	mov    %eax,%edx
f010103b:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0101041:	c1 fa 03             	sar    $0x3,%edx
f0101044:	c1 e2 0c             	shl    $0xc,%edx

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;
f0101047:	83 ca 07             	or     $0x7,%edx
f010104a:	89 13                	mov    %edx,(%ebx)
f010104c:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0101052:	c1 f8 03             	sar    $0x3,%eax
f0101055:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101058:	89 c2                	mov    %eax,%edx
f010105a:	c1 ea 0c             	shr    $0xc,%edx
f010105d:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0101063:	72 20                	jb     f0101085 <pgdir_walk+0xea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101065:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101069:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0101070:	f0 
f0101071:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101078:	00 
f0101079:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0101080:	e8 0f f0 ff ff       	call   f0100094 <_panic>


	return &((pte_t*) page2kva(pp))[PTX(va)];
f0101085:	c1 ee 0a             	shr    $0xa,%esi
f0101088:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010108e:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101095:	eb 0c                	jmp    f01010a3 <pgdir_walk+0x108>
        pt = KADDR(PTE_ADDR(pde));
        return &pt[PTX(va)];
    }

    if (!create) {
        return NULL;
f0101097:	b8 00 00 00 00       	mov    $0x0,%eax
f010109c:	eb 05                	jmp    f01010a3 <pgdir_walk+0x108>
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
        return NULL;
f010109e:	b8 00 00 00 00       	mov    $0x0,%eax

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;


	return &((pte_t*) page2kva(pp))[PTX(va)];
}
f01010a3:	83 c4 10             	add    $0x10,%esp
f01010a6:	5b                   	pop    %ebx
f01010a7:	5e                   	pop    %esi
f01010a8:	5d                   	pop    %ebp
f01010a9:	c3                   	ret    

f01010aa <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010aa:	55                   	push   %ebp
f01010ab:	89 e5                	mov    %esp,%ebp
f01010ad:	57                   	push   %edi
f01010ae:	56                   	push   %esi
f01010af:	53                   	push   %ebx
f01010b0:	83 ec 2c             	sub    $0x2c,%esp
f01010b3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010b6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010b9:	89 cf                	mov    %ecx,%edi
f01010bb:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
    assert(size % PGSIZE == 0);
f01010be:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01010c4:	75 14                	jne    f01010da <boot_map_region+0x30>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010c6:	89 d3                	mov    %edx,%ebx
        }

        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
f01010c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010cb:	83 c8 01             	or     $0x1,%eax
f01010ce:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010d1:	85 c9                	test   %ecx,%ecx
f01010d3:	75 50                	jne    f0101125 <boot_map_region+0x7b>
f01010d5:	e9 c0 00 00 00       	jmp    f010119a <boot_map_region+0xf0>
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    assert(size % PGSIZE == 0);
f01010da:	c7 44 24 0c cd 55 10 	movl   $0xf01055cd,0xc(%esp)
f01010e1:	f0 
f01010e2:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01010e9:	f0 
f01010ea:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f01010f1:	00 
f01010f2:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01010f9:	e8 96 ef ff ff       	call   f0100094 <_panic>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010fe:	81 c3 00 10 00 00    	add    $0x1000,%ebx
        if (va < start) { //  need overflow check?
f0101104:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f0101107:	76 1c                	jbe    f0101125 <boot_map_region+0x7b>
            panic("overflow\n");
f0101109:	c7 44 24 08 e0 55 10 	movl   $0xf01055e0,0x8(%esp)
f0101110:	f0 
f0101111:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f0101118:	00 
f0101119:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101120:	e8 6f ef ff ff       	call   f0100094 <_panic>
            break;
        }

        if ((pte = pgdir_walk(pgdir, (void*) va, 1)) == NULL) {
f0101125:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010112c:	00 
f010112d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101131:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101134:	89 04 24             	mov    %eax,(%esp)
f0101137:	e8 5f fe ff ff       	call   f0100f9b <pgdir_walk>
f010113c:	85 c0                	test   %eax,%eax
f010113e:	75 1c                	jne    f010115c <boot_map_region+0xb2>
            panic("fail create\n");
f0101140:	c7 44 24 08 ea 55 10 	movl   $0xf01055ea,0x8(%esp)
f0101147:	f0 
f0101148:	c7 44 24 04 b7 01 00 	movl   $0x1b7,0x4(%esp)
f010114f:	00 
f0101150:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101157:	e8 38 ef ff ff       	call   f0100094 <_panic>
        }

        if (*pte & PTE_P) {
f010115c:	f6 00 01             	testb  $0x1,(%eax)
f010115f:	74 20                	je     f0101181 <boot_map_region+0xd7>
            panic("remapping %p\n", va);
f0101161:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101165:	c7 44 24 08 f7 55 10 	movl   $0xf01055f7,0x8(%esp)
f010116c:	f0 
f010116d:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f0101174:	00 
f0101175:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010117c:	e8 13 ef ff ff       	call   f0100094 <_panic>
        }
        *pte = pa | perm | PTE_P;
f0101181:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101184:	09 f2                	or     %esi,%edx
f0101186:	89 10                	mov    %edx,(%eax)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f0101188:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010118e:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0101194:	0f 85 64 ff ff ff    	jne    f01010fe <boot_map_region+0x54>
        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
    }
}
f010119a:	83 c4 2c             	add    $0x2c,%esp
f010119d:	5b                   	pop    %ebx
f010119e:	5e                   	pop    %esi
f010119f:	5f                   	pop    %edi
f01011a0:	5d                   	pop    %ebp
f01011a1:	c3                   	ret    

f01011a2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011a2:	55                   	push   %ebp
f01011a3:	89 e5                	mov    %esp,%ebp
f01011a5:	53                   	push   %ebx
f01011a6:	83 ec 14             	sub    $0x14,%esp
f01011a9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f01011ac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01011b3:	00 
f01011b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011bb:	8b 45 08             	mov    0x8(%ebp),%eax
f01011be:	89 04 24             	mov    %eax,(%esp)
f01011c1:	e8 d5 fd ff ff       	call   f0100f9b <pgdir_walk>
f01011c6:	89 c2                	mov    %eax,%edx

    if (pte == NULL || !(*pte & PTE_P)) {
f01011c8:	85 c0                	test   %eax,%eax
f01011ca:	74 3e                	je     f010120a <page_lookup+0x68>
f01011cc:	8b 00                	mov    (%eax),%eax
f01011ce:	a8 01                	test   $0x1,%al
f01011d0:	74 3f                	je     f0101211 <page_lookup+0x6f>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011d2:	c1 e8 0c             	shr    $0xc,%eax
f01011d5:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f01011db:	72 1c                	jb     f01011f9 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01011dd:	c7 44 24 08 9c 4e 10 	movl   $0xf0104e9c,0x8(%esp)
f01011e4:	f0 
f01011e5:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01011ec:	00 
f01011ed:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f01011f4:	e8 9b ee ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01011f9:	c1 e0 03             	shl    $0x3,%eax
f01011fc:	03 05 48 dd 17 f0    	add    0xf017dd48,%eax
        return NULL;
    }
    
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
f0101202:	85 db                	test   %ebx,%ebx
f0101204:	74 10                	je     f0101216 <page_lookup+0x74>
        *pte_store = pte;
f0101206:	89 13                	mov    %edx,(%ebx)
f0101208:	eb 0c                	jmp    f0101216 <page_lookup+0x74>
{
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);

    if (pte == NULL || !(*pte & PTE_P)) {
        return NULL;
f010120a:	b8 00 00 00 00       	mov    $0x0,%eax
f010120f:	eb 05                	jmp    f0101216 <page_lookup+0x74>
f0101211:	b8 00 00 00 00       	mov    $0x0,%eax
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
        *pte_store = pte;
    }
	return pp;
}
f0101216:	83 c4 14             	add    $0x14,%esp
f0101219:	5b                   	pop    %ebx
f010121a:	5d                   	pop    %ebp
f010121b:	c3                   	ret    

f010121c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010121c:	55                   	push   %ebp
f010121d:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010121f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101222:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101225:	5d                   	pop    %ebp
f0101226:	c3                   	ret    

f0101227 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101227:	55                   	push   %ebp
f0101228:	89 e5                	mov    %esp,%ebp
f010122a:	83 ec 28             	sub    $0x28,%esp
f010122d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101230:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101233:	8b 75 08             	mov    0x8(%ebp),%esi
f0101236:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t* pte;
    struct Page* pp = page_lookup(pgdir, va, &pte);
f0101239:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010123c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101240:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101244:	89 34 24             	mov    %esi,(%esp)
f0101247:	e8 56 ff ff ff       	call   f01011a2 <page_lookup>

    if (pp) {
f010124c:	85 c0                	test   %eax,%eax
f010124e:	74 1d                	je     f010126d <page_remove+0x46>
        page_decref(pp);
f0101250:	89 04 24             	mov    %eax,(%esp)
f0101253:	e8 20 fd ff ff       	call   f0100f78 <page_decref>
        *pte = 0;
f0101258:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010125b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, va);
f0101261:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101265:	89 34 24             	mov    %esi,(%esp)
f0101268:	e8 af ff ff ff       	call   f010121c <tlb_invalidate>
    }
}
f010126d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101270:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101273:	89 ec                	mov    %ebp,%esp
f0101275:	5d                   	pop    %ebp
f0101276:	c3                   	ret    

f0101277 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101277:	55                   	push   %ebp
f0101278:	89 e5                	mov    %esp,%ebp
f010127a:	83 ec 38             	sub    $0x38,%esp
f010127d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101280:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101283:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101286:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101289:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f010128c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101293:	00 
f0101294:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101298:	8b 45 08             	mov    0x8(%ebp),%eax
f010129b:	89 04 24             	mov    %eax,(%esp)
f010129e:	e8 f8 fc ff ff       	call   f0100f9b <pgdir_walk>
f01012a3:	89 c3                	mov    %eax,%ebx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01012a5:	a1 48 dd 17 f0       	mov    0xf017dd48,%eax
f01012aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    physaddr_t ppa = page2pa(pp);

    if (pte != NULL) {
f01012ad:	85 db                	test   %ebx,%ebx
f01012af:	74 25                	je     f01012d6 <page_insert+0x5f>
        if (*pte & PTE_P) 
f01012b1:	f6 03 01             	testb  $0x1,(%ebx)
f01012b4:	74 0f                	je     f01012c5 <page_insert+0x4e>
            page_remove(pgdir, va);
f01012b6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01012bd:	89 04 24             	mov    %eax,(%esp)
f01012c0:	e8 62 ff ff ff       	call   f0101227 <page_remove>
        if (pp == page_free_list)
f01012c5:	3b 35 a0 d0 17 f0    	cmp    0xf017d0a0,%esi
f01012cb:	75 26                	jne    f01012f3 <page_insert+0x7c>
            page_free_list = page_free_list->pp_link;
f01012cd:	8b 06                	mov    (%esi),%eax
f01012cf:	a3 a0 d0 17 f0       	mov    %eax,0xf017d0a0
f01012d4:	eb 1d                	jmp    f01012f3 <page_insert+0x7c>
    } else {
        pte = pgdir_walk(pgdir, va, 1);
f01012d6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01012dd:	00 
f01012de:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01012e5:	89 04 24             	mov    %eax,(%esp)
f01012e8:	e8 ae fc ff ff       	call   f0100f9b <pgdir_walk>
f01012ed:	89 c3                	mov    %eax,%ebx
        if (pte == NULL)
f01012ef:	85 c0                	test   %eax,%eax
f01012f1:	74 30                	je     f0101323 <page_insert+0xac>
            return -E_NO_MEM;
    }

    *pte = ppa | perm | PTE_P;
f01012f3:	8b 55 14             	mov    0x14(%ebp),%edx
f01012f6:	83 ca 01             	or     $0x1,%edx
f01012f9:	89 f0                	mov    %esi,%eax
f01012fb:	2b 45 e4             	sub    -0x1c(%ebp),%eax
f01012fe:	c1 f8 03             	sar    $0x3,%eax
f0101301:	c1 e0 0c             	shl    $0xc,%eax
f0101304:	09 d0                	or     %edx,%eax
f0101306:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f0101308:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
    tlb_invalidate(pgdir, va);
f010130d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101311:	8b 45 08             	mov    0x8(%ebp),%eax
f0101314:	89 04 24             	mov    %eax,(%esp)
f0101317:	e8 00 ff ff ff       	call   f010121c <tlb_invalidate>

	return 0;
f010131c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101321:	eb 05                	jmp    f0101328 <page_insert+0xb1>
        if (pp == page_free_list)
            page_free_list = page_free_list->pp_link;
    } else {
        pte = pgdir_walk(pgdir, va, 1);
        if (pte == NULL)
            return -E_NO_MEM;
f0101323:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = ppa | perm | PTE_P;
    pp->pp_ref++;
    tlb_invalidate(pgdir, va);

	return 0;
}
f0101328:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010132b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010132e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101331:	89 ec                	mov    %ebp,%esp
f0101333:	5d                   	pop    %ebp
f0101334:	c3                   	ret    

f0101335 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101335:	55                   	push   %ebp
f0101336:	89 e5                	mov    %esp,%ebp
f0101338:	57                   	push   %edi
f0101339:	56                   	push   %esi
f010133a:	53                   	push   %ebx
f010133b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010133e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101343:	e8 b8 f6 ff ff       	call   f0100a00 <nvram_read>
f0101348:	c1 e0 0a             	shl    $0xa,%eax
f010134b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101351:	85 c0                	test   %eax,%eax
f0101353:	0f 48 c2             	cmovs  %edx,%eax
f0101356:	c1 f8 0c             	sar    $0xc,%eax
f0101359:	a3 98 d0 17 f0       	mov    %eax,0xf017d098
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010135e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101363:	e8 98 f6 ff ff       	call   f0100a00 <nvram_read>
f0101368:	c1 e0 0a             	shl    $0xa,%eax
f010136b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101371:	85 c0                	test   %eax,%eax
f0101373:	0f 48 c2             	cmovs  %edx,%eax
f0101376:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101379:	85 c0                	test   %eax,%eax
f010137b:	74 0e                	je     f010138b <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010137d:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101383:	89 15 40 dd 17 f0    	mov    %edx,0xf017dd40
f0101389:	eb 0c                	jmp    f0101397 <mem_init+0x62>
	else
		npages = npages_basemem;
f010138b:	8b 15 98 d0 17 f0    	mov    0xf017d098,%edx
f0101391:	89 15 40 dd 17 f0    	mov    %edx,0xf017dd40

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101397:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010139a:	c1 e8 0a             	shr    $0xa,%eax
f010139d:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01013a1:	a1 98 d0 17 f0       	mov    0xf017d098,%eax
f01013a6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013a9:	c1 e8 0a             	shr    $0xa,%eax
f01013ac:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01013b0:	a1 40 dd 17 f0       	mov    0xf017dd40,%eax
f01013b5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013b8:	c1 e8 0a             	shr    $0xa,%eax
f01013bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013bf:	c7 04 24 bc 4e 10 f0 	movl   $0xf0104ebc,(%esp)
f01013c6:	e8 23 20 00 00       	call   f01033ee <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013cb:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013d0:	e8 c4 f5 ff ff       	call   f0100999 <boot_alloc>
f01013d5:	a3 44 dd 17 f0       	mov    %eax,0xf017dd44
	memset(kern_pgdir, 0, PGSIZE);
f01013da:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01013e1:	00 
f01013e2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013e9:	00 
f01013ea:	89 04 24             	mov    %eax,(%esp)
f01013ed:	e8 44 2f 00 00       	call   f0104336 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013f2:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013f7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013fc:	77 20                	ja     f010141e <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013fe:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101402:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0101409:	f0 
f010140a:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
f0101411:	00 
f0101412:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101419:	e8 76 ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010141e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101424:	83 ca 05             	or     $0x5,%edx
f0101427:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
    n = sizeof(struct Page) * npages;
f010142d:	8b 1d 40 dd 17 f0    	mov    0xf017dd40,%ebx
f0101433:	c1 e3 03             	shl    $0x3,%ebx
    pages = boot_alloc(n);
f0101436:	89 d8                	mov    %ebx,%eax
f0101438:	e8 5c f5 ff ff       	call   f0100999 <boot_alloc>
f010143d:	a3 48 dd 17 f0       	mov    %eax,0xf017dd48
    memset(pages, 0, n);
f0101442:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101446:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010144d:	00 
f010144e:	89 04 24             	mov    %eax,(%esp)
f0101451:	e8 e0 2e 00 00       	call   f0104336 <memset>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
    envs = boot_alloc(sizeof(struct Env) * NENV);
f0101456:	b8 00 80 01 00       	mov    $0x18000,%eax
f010145b:	e8 39 f5 ff ff       	call   f0100999 <boot_alloc>
f0101460:	a3 a8 d0 17 f0       	mov    %eax,0xf017d0a8
    memset(envs, 0, sizeof(struct Env) * NENV);
f0101465:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f010146c:	00 
f010146d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101474:	00 
f0101475:	89 04 24             	mov    %eax,(%esp)
f0101478:	e8 b9 2e 00 00       	call   f0104336 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f010147d:	e8 0d f9 ff ff       	call   f0100d8f <page_init>

	check_page_free_list(1);
f0101482:	b8 01 00 00 00       	mov    $0x1,%eax
f0101487:	e8 a6 f5 ff ff       	call   f0100a32 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f010148c:	83 3d 48 dd 17 f0 00 	cmpl   $0x0,0xf017dd48
f0101493:	75 1c                	jne    f01014b1 <mem_init+0x17c>
		panic("'pages' is a null pointer!");
f0101495:	c7 44 24 08 05 56 10 	movl   $0xf0105605,0x8(%esp)
f010149c:	f0 
f010149d:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f01014a4:	00 
f01014a5:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01014ac:	e8 e3 eb ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014b1:	a1 a0 d0 17 f0       	mov    0xf017d0a0,%eax
f01014b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014bb:	85 c0                	test   %eax,%eax
f01014bd:	74 09                	je     f01014c8 <mem_init+0x193>
		++nfree;
f01014bf:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014c2:	8b 00                	mov    (%eax),%eax
f01014c4:	85 c0                	test   %eax,%eax
f01014c6:	75 f7                	jne    f01014bf <mem_init+0x18a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014cf:	e8 e7 f9 ff ff       	call   f0100ebb <page_alloc>
f01014d4:	89 c6                	mov    %eax,%esi
f01014d6:	85 c0                	test   %eax,%eax
f01014d8:	75 24                	jne    f01014fe <mem_init+0x1c9>
f01014da:	c7 44 24 0c 20 56 10 	movl   $0xf0105620,0xc(%esp)
f01014e1:	f0 
f01014e2:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01014e9:	f0 
f01014ea:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f01014f1:	00 
f01014f2:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01014f9:	e8 96 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01014fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101505:	e8 b1 f9 ff ff       	call   f0100ebb <page_alloc>
f010150a:	89 c7                	mov    %eax,%edi
f010150c:	85 c0                	test   %eax,%eax
f010150e:	75 24                	jne    f0101534 <mem_init+0x1ff>
f0101510:	c7 44 24 0c 36 56 10 	movl   $0xf0105636,0xc(%esp)
f0101517:	f0 
f0101518:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010151f:	f0 
f0101520:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101527:	00 
f0101528:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010152f:	e8 60 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101534:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010153b:	e8 7b f9 ff ff       	call   f0100ebb <page_alloc>
f0101540:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101543:	85 c0                	test   %eax,%eax
f0101545:	75 24                	jne    f010156b <mem_init+0x236>
f0101547:	c7 44 24 0c 4c 56 10 	movl   $0xf010564c,0xc(%esp)
f010154e:	f0 
f010154f:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101556:	f0 
f0101557:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f010155e:	00 
f010155f:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101566:	e8 29 eb ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010156b:	39 fe                	cmp    %edi,%esi
f010156d:	75 24                	jne    f0101593 <mem_init+0x25e>
f010156f:	c7 44 24 0c 62 56 10 	movl   $0xf0105662,0xc(%esp)
f0101576:	f0 
f0101577:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010157e:	f0 
f010157f:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0101586:	00 
f0101587:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010158e:	e8 01 eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101593:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101596:	74 05                	je     f010159d <mem_init+0x268>
f0101598:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010159b:	75 24                	jne    f01015c1 <mem_init+0x28c>
f010159d:	c7 44 24 0c f8 4e 10 	movl   $0xf0104ef8,0xc(%esp)
f01015a4:	f0 
f01015a5:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01015ac:	f0 
f01015ad:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01015b4:	00 
f01015b5:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01015bc:	e8 d3 ea ff ff       	call   f0100094 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01015c1:	8b 15 48 dd 17 f0    	mov    0xf017dd48,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01015c7:	a1 40 dd 17 f0       	mov    0xf017dd40,%eax
f01015cc:	c1 e0 0c             	shl    $0xc,%eax
f01015cf:	89 f1                	mov    %esi,%ecx
f01015d1:	29 d1                	sub    %edx,%ecx
f01015d3:	c1 f9 03             	sar    $0x3,%ecx
f01015d6:	c1 e1 0c             	shl    $0xc,%ecx
f01015d9:	39 c1                	cmp    %eax,%ecx
f01015db:	72 24                	jb     f0101601 <mem_init+0x2cc>
f01015dd:	c7 44 24 0c 74 56 10 	movl   $0xf0105674,0xc(%esp)
f01015e4:	f0 
f01015e5:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01015ec:	f0 
f01015ed:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f01015f4:	00 
f01015f5:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01015fc:	e8 93 ea ff ff       	call   f0100094 <_panic>
f0101601:	89 f9                	mov    %edi,%ecx
f0101603:	29 d1                	sub    %edx,%ecx
f0101605:	c1 f9 03             	sar    $0x3,%ecx
f0101608:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010160b:	39 c8                	cmp    %ecx,%eax
f010160d:	77 24                	ja     f0101633 <mem_init+0x2fe>
f010160f:	c7 44 24 0c 91 56 10 	movl   $0xf0105691,0xc(%esp)
f0101616:	f0 
f0101617:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010161e:	f0 
f010161f:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101626:	00 
f0101627:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010162e:	e8 61 ea ff ff       	call   f0100094 <_panic>
f0101633:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101636:	29 d1                	sub    %edx,%ecx
f0101638:	89 ca                	mov    %ecx,%edx
f010163a:	c1 fa 03             	sar    $0x3,%edx
f010163d:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101640:	39 d0                	cmp    %edx,%eax
f0101642:	77 24                	ja     f0101668 <mem_init+0x333>
f0101644:	c7 44 24 0c ae 56 10 	movl   $0xf01056ae,0xc(%esp)
f010164b:	f0 
f010164c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101653:	f0 
f0101654:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f010165b:	00 
f010165c:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101663:	e8 2c ea ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101668:	a1 a0 d0 17 f0       	mov    0xf017d0a0,%eax
f010166d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101670:	c7 05 a0 d0 17 f0 00 	movl   $0x0,0xf017d0a0
f0101677:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010167a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101681:	e8 35 f8 ff ff       	call   f0100ebb <page_alloc>
f0101686:	85 c0                	test   %eax,%eax
f0101688:	74 24                	je     f01016ae <mem_init+0x379>
f010168a:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f0101691:	f0 
f0101692:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101699:	f0 
f010169a:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f01016a1:	00 
f01016a2:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01016a9:	e8 e6 e9 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016ae:	89 34 24             	mov    %esi,(%esp)
f01016b1:	e8 83 f8 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f01016b6:	89 3c 24             	mov    %edi,(%esp)
f01016b9:	e8 7b f8 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f01016be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016c1:	89 04 24             	mov    %eax,(%esp)
f01016c4:	e8 70 f8 ff ff       	call   f0100f39 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016d0:	e8 e6 f7 ff ff       	call   f0100ebb <page_alloc>
f01016d5:	89 c6                	mov    %eax,%esi
f01016d7:	85 c0                	test   %eax,%eax
f01016d9:	75 24                	jne    f01016ff <mem_init+0x3ca>
f01016db:	c7 44 24 0c 20 56 10 	movl   $0xf0105620,0xc(%esp)
f01016e2:	f0 
f01016e3:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01016ea:	f0 
f01016eb:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f01016f2:	00 
f01016f3:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01016fa:	e8 95 e9 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01016ff:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101706:	e8 b0 f7 ff ff       	call   f0100ebb <page_alloc>
f010170b:	89 c7                	mov    %eax,%edi
f010170d:	85 c0                	test   %eax,%eax
f010170f:	75 24                	jne    f0101735 <mem_init+0x400>
f0101711:	c7 44 24 0c 36 56 10 	movl   $0xf0105636,0xc(%esp)
f0101718:	f0 
f0101719:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101720:	f0 
f0101721:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0101728:	00 
f0101729:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101730:	e8 5f e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101735:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010173c:	e8 7a f7 ff ff       	call   f0100ebb <page_alloc>
f0101741:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101744:	85 c0                	test   %eax,%eax
f0101746:	75 24                	jne    f010176c <mem_init+0x437>
f0101748:	c7 44 24 0c 4c 56 10 	movl   $0xf010564c,0xc(%esp)
f010174f:	f0 
f0101750:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101757:	f0 
f0101758:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f010175f:	00 
f0101760:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101767:	e8 28 e9 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010176c:	39 fe                	cmp    %edi,%esi
f010176e:	75 24                	jne    f0101794 <mem_init+0x45f>
f0101770:	c7 44 24 0c 62 56 10 	movl   $0xf0105662,0xc(%esp)
f0101777:	f0 
f0101778:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010177f:	f0 
f0101780:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f0101787:	00 
f0101788:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010178f:	e8 00 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101794:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101797:	74 05                	je     f010179e <mem_init+0x469>
f0101799:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010179c:	75 24                	jne    f01017c2 <mem_init+0x48d>
f010179e:	c7 44 24 0c f8 4e 10 	movl   $0xf0104ef8,0xc(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f01017b5:	00 
f01017b6:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01017bd:	e8 d2 e8 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01017c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c9:	e8 ed f6 ff ff       	call   f0100ebb <page_alloc>
f01017ce:	85 c0                	test   %eax,%eax
f01017d0:	74 24                	je     f01017f6 <mem_init+0x4c1>
f01017d2:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f01017d9:	f0 
f01017da:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01017e1:	f0 
f01017e2:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f01017e9:	00 
f01017ea:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01017f1:	e8 9e e8 ff ff       	call   f0100094 <_panic>
f01017f6:	89 f0                	mov    %esi,%eax
f01017f8:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f01017fe:	c1 f8 03             	sar    $0x3,%eax
f0101801:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101804:	89 c2                	mov    %eax,%edx
f0101806:	c1 ea 0c             	shr    $0xc,%edx
f0101809:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f010180f:	72 20                	jb     f0101831 <mem_init+0x4fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101811:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101815:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f010181c:	f0 
f010181d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101824:	00 
f0101825:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f010182c:	e8 63 e8 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101831:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101838:	00 
f0101839:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101840:	00 
	return (void *)(pa + KERNBASE);
f0101841:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101846:	89 04 24             	mov    %eax,(%esp)
f0101849:	e8 e8 2a 00 00       	call   f0104336 <memset>
	page_free(pp0);
f010184e:	89 34 24             	mov    %esi,(%esp)
f0101851:	e8 e3 f6 ff ff       	call   f0100f39 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101856:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010185d:	e8 59 f6 ff ff       	call   f0100ebb <page_alloc>
f0101862:	85 c0                	test   %eax,%eax
f0101864:	75 24                	jne    f010188a <mem_init+0x555>
f0101866:	c7 44 24 0c da 56 10 	movl   $0xf01056da,0xc(%esp)
f010186d:	f0 
f010186e:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101875:	f0 
f0101876:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f010187d:	00 
f010187e:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101885:	e8 0a e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010188a:	39 c6                	cmp    %eax,%esi
f010188c:	74 24                	je     f01018b2 <mem_init+0x57d>
f010188e:	c7 44 24 0c f8 56 10 	movl   $0xf01056f8,0xc(%esp)
f0101895:	f0 
f0101896:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010189d:	f0 
f010189e:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f01018a5:	00 
f01018a6:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01018ad:	e8 e2 e7 ff ff       	call   f0100094 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01018b2:	89 f2                	mov    %esi,%edx
f01018b4:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f01018ba:	c1 fa 03             	sar    $0x3,%edx
f01018bd:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018c0:	89 d0                	mov    %edx,%eax
f01018c2:	c1 e8 0c             	shr    $0xc,%eax
f01018c5:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f01018cb:	72 20                	jb     f01018ed <mem_init+0x5b8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01018d1:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f01018d8:	f0 
f01018d9:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01018e0:	00 
f01018e1:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f01018e8:	e8 a7 e7 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018ed:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01018f4:	75 11                	jne    f0101907 <mem_init+0x5d2>
f01018f6:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01018fc:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101902:	80 38 00             	cmpb   $0x0,(%eax)
f0101905:	74 24                	je     f010192b <mem_init+0x5f6>
f0101907:	c7 44 24 0c 08 57 10 	movl   $0xf0105708,0xc(%esp)
f010190e:	f0 
f010190f:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101916:	f0 
f0101917:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010191e:	00 
f010191f:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101926:	e8 69 e7 ff ff       	call   f0100094 <_panic>
f010192b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010192e:	39 d0                	cmp    %edx,%eax
f0101930:	75 d0                	jne    f0101902 <mem_init+0x5cd>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101932:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101935:	89 15 a0 d0 17 f0    	mov    %edx,0xf017d0a0

	// free the pages we took
	page_free(pp0);
f010193b:	89 34 24             	mov    %esi,(%esp)
f010193e:	e8 f6 f5 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f0101943:	89 3c 24             	mov    %edi,(%esp)
f0101946:	e8 ee f5 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f010194b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010194e:	89 04 24             	mov    %eax,(%esp)
f0101951:	e8 e3 f5 ff ff       	call   f0100f39 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101956:	a1 a0 d0 17 f0       	mov    0xf017d0a0,%eax
f010195b:	85 c0                	test   %eax,%eax
f010195d:	74 09                	je     f0101968 <mem_init+0x633>
		--nfree;
f010195f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101962:	8b 00                	mov    (%eax),%eax
f0101964:	85 c0                	test   %eax,%eax
f0101966:	75 f7                	jne    f010195f <mem_init+0x62a>
		--nfree;
	assert(nfree == 0);
f0101968:	85 db                	test   %ebx,%ebx
f010196a:	74 24                	je     f0101990 <mem_init+0x65b>
f010196c:	c7 44 24 0c 12 57 10 	movl   $0xf0105712,0xc(%esp)
f0101973:	f0 
f0101974:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010197b:	f0 
f010197c:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101983:	00 
f0101984:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010198b:	e8 04 e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101990:	c7 04 24 18 4f 10 f0 	movl   $0xf0104f18,(%esp)
f0101997:	e8 52 1a 00 00       	call   f01033ee <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010199c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a3:	e8 13 f5 ff ff       	call   f0100ebb <page_alloc>
f01019a8:	89 c3                	mov    %eax,%ebx
f01019aa:	85 c0                	test   %eax,%eax
f01019ac:	75 24                	jne    f01019d2 <mem_init+0x69d>
f01019ae:	c7 44 24 0c 20 56 10 	movl   $0xf0105620,0xc(%esp)
f01019b5:	f0 
f01019b6:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01019bd:	f0 
f01019be:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f01019c5:	00 
f01019c6:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01019cd:	e8 c2 e6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01019d2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d9:	e8 dd f4 ff ff       	call   f0100ebb <page_alloc>
f01019de:	89 c7                	mov    %eax,%edi
f01019e0:	85 c0                	test   %eax,%eax
f01019e2:	75 24                	jne    f0101a08 <mem_init+0x6d3>
f01019e4:	c7 44 24 0c 36 56 10 	movl   $0xf0105636,0xc(%esp)
f01019eb:	f0 
f01019ec:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01019f3:	f0 
f01019f4:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f01019fb:	00 
f01019fc:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101a03:	e8 8c e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a08:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a0f:	e8 a7 f4 ff ff       	call   f0100ebb <page_alloc>
f0101a14:	89 c6                	mov    %eax,%esi
f0101a16:	85 c0                	test   %eax,%eax
f0101a18:	75 24                	jne    f0101a3e <mem_init+0x709>
f0101a1a:	c7 44 24 0c 4c 56 10 	movl   $0xf010564c,0xc(%esp)
f0101a21:	f0 
f0101a22:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101a29:	f0 
f0101a2a:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101a31:	00 
f0101a32:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101a39:	e8 56 e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a3e:	39 fb                	cmp    %edi,%ebx
f0101a40:	75 24                	jne    f0101a66 <mem_init+0x731>
f0101a42:	c7 44 24 0c 62 56 10 	movl   $0xf0105662,0xc(%esp)
f0101a49:	f0 
f0101a4a:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101a51:	f0 
f0101a52:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101a59:	00 
f0101a5a:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101a61:	e8 2e e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a66:	39 c7                	cmp    %eax,%edi
f0101a68:	74 04                	je     f0101a6e <mem_init+0x739>
f0101a6a:	39 c3                	cmp    %eax,%ebx
f0101a6c:	75 24                	jne    f0101a92 <mem_init+0x75d>
f0101a6e:	c7 44 24 0c f8 4e 10 	movl   $0xf0104ef8,0xc(%esp)
f0101a75:	f0 
f0101a76:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101a7d:	f0 
f0101a7e:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101a85:	00 
f0101a86:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101a8d:	e8 02 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a92:	8b 15 a0 d0 17 f0    	mov    0xf017d0a0,%edx
f0101a98:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101a9b:	c7 05 a0 d0 17 f0 00 	movl   $0x0,0xf017d0a0
f0101aa2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101aa5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aac:	e8 0a f4 ff ff       	call   f0100ebb <page_alloc>
f0101ab1:	85 c0                	test   %eax,%eax
f0101ab3:	74 24                	je     f0101ad9 <mem_init+0x7a4>
f0101ab5:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f0101abc:	f0 
f0101abd:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101ac4:	f0 
f0101ac5:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101acc:	00 
f0101acd:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101ad4:	e8 bb e5 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101ad9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101adc:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ae0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101ae7:	00 
f0101ae8:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101aed:	89 04 24             	mov    %eax,(%esp)
f0101af0:	e8 ad f6 ff ff       	call   f01011a2 <page_lookup>
f0101af5:	85 c0                	test   %eax,%eax
f0101af7:	74 24                	je     f0101b1d <mem_init+0x7e8>
f0101af9:	c7 44 24 0c 38 4f 10 	movl   $0xf0104f38,0xc(%esp)
f0101b00:	f0 
f0101b01:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101b08:	f0 
f0101b09:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101b10:	00 
f0101b11:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101b18:	e8 77 e5 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b1d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b24:	00 
f0101b25:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b2c:	00 
f0101b2d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b31:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101b36:	89 04 24             	mov    %eax,(%esp)
f0101b39:	e8 39 f7 ff ff       	call   f0101277 <page_insert>
f0101b3e:	85 c0                	test   %eax,%eax
f0101b40:	78 24                	js     f0101b66 <mem_init+0x831>
f0101b42:	c7 44 24 0c 70 4f 10 	movl   $0xf0104f70,0xc(%esp)
f0101b49:	f0 
f0101b4a:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101b51:	f0 
f0101b52:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101b59:	00 
f0101b5a:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101b61:	e8 2e e5 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b66:	89 1c 24             	mov    %ebx,(%esp)
f0101b69:	e8 cb f3 ff ff       	call   f0100f39 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b6e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b75:	00 
f0101b76:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b7d:	00 
f0101b7e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b82:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101b87:	89 04 24             	mov    %eax,(%esp)
f0101b8a:	e8 e8 f6 ff ff       	call   f0101277 <page_insert>
f0101b8f:	85 c0                	test   %eax,%eax
f0101b91:	74 24                	je     f0101bb7 <mem_init+0x882>
f0101b93:	c7 44 24 0c a0 4f 10 	movl   $0xf0104fa0,0xc(%esp)
f0101b9a:	f0 
f0101b9b:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101ba2:	f0 
f0101ba3:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0101baa:	00 
f0101bab:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101bb2:	e8 dd e4 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101bb7:	8b 0d 44 dd 17 f0    	mov    0xf017dd44,%ecx
f0101bbd:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bc0:	a1 48 dd 17 f0       	mov    0xf017dd48,%eax
f0101bc5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bc8:	8b 11                	mov    (%ecx),%edx
f0101bca:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101bd0:	89 d8                	mov    %ebx,%eax
f0101bd2:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101bd5:	c1 f8 03             	sar    $0x3,%eax
f0101bd8:	c1 e0 0c             	shl    $0xc,%eax
f0101bdb:	39 c2                	cmp    %eax,%edx
f0101bdd:	74 24                	je     f0101c03 <mem_init+0x8ce>
f0101bdf:	c7 44 24 0c d0 4f 10 	movl   $0xf0104fd0,0xc(%esp)
f0101be6:	f0 
f0101be7:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101bee:	f0 
f0101bef:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101bf6:	00 
f0101bf7:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101bfe:	e8 91 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c03:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c08:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c0b:	e8 18 ed ff ff       	call   f0100928 <check_va2pa>
f0101c10:	89 fa                	mov    %edi,%edx
f0101c12:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101c15:	c1 fa 03             	sar    $0x3,%edx
f0101c18:	c1 e2 0c             	shl    $0xc,%edx
f0101c1b:	39 d0                	cmp    %edx,%eax
f0101c1d:	74 24                	je     f0101c43 <mem_init+0x90e>
f0101c1f:	c7 44 24 0c f8 4f 10 	movl   $0xf0104ff8,0xc(%esp)
f0101c26:	f0 
f0101c27:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101c2e:	f0 
f0101c2f:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101c36:	00 
f0101c37:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101c3e:	e8 51 e4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101c43:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c48:	74 24                	je     f0101c6e <mem_init+0x939>
f0101c4a:	c7 44 24 0c 1d 57 10 	movl   $0xf010571d,0xc(%esp)
f0101c51:	f0 
f0101c52:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101c59:	f0 
f0101c5a:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101c61:	00 
f0101c62:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101c69:	e8 26 e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101c6e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c73:	74 24                	je     f0101c99 <mem_init+0x964>
f0101c75:	c7 44 24 0c 2e 57 10 	movl   $0xf010572e,0xc(%esp)
f0101c7c:	f0 
f0101c7d:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101c84:	f0 
f0101c85:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101c8c:	00 
f0101c8d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101c94:	e8 fb e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c99:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ca0:	00 
f0101ca1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ca8:	00 
f0101ca9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cad:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101cb0:	89 14 24             	mov    %edx,(%esp)
f0101cb3:	e8 bf f5 ff ff       	call   f0101277 <page_insert>
f0101cb8:	85 c0                	test   %eax,%eax
f0101cba:	74 24                	je     f0101ce0 <mem_init+0x9ab>
f0101cbc:	c7 44 24 0c 28 50 10 	movl   $0xf0105028,0xc(%esp)
f0101cc3:	f0 
f0101cc4:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101cd3:	00 
f0101cd4:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101cdb:	e8 b4 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce5:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101cea:	e8 39 ec ff ff       	call   f0100928 <check_va2pa>
f0101cef:	89 f2                	mov    %esi,%edx
f0101cf1:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0101cf7:	c1 fa 03             	sar    $0x3,%edx
f0101cfa:	c1 e2 0c             	shl    $0xc,%edx
f0101cfd:	39 d0                	cmp    %edx,%eax
f0101cff:	74 24                	je     f0101d25 <mem_init+0x9f0>
f0101d01:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0101d08:	f0 
f0101d09:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101d10:	f0 
f0101d11:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101d18:	00 
f0101d19:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101d20:	e8 6f e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d25:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d2a:	74 24                	je     f0101d50 <mem_init+0xa1b>
f0101d2c:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101d33:	f0 
f0101d34:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101d3b:	f0 
f0101d3c:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101d43:	00 
f0101d44:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101d4b:	e8 44 e3 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101d50:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d57:	e8 5f f1 ff ff       	call   f0100ebb <page_alloc>
f0101d5c:	85 c0                	test   %eax,%eax
f0101d5e:	74 24                	je     f0101d84 <mem_init+0xa4f>
f0101d60:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f0101d67:	f0 
f0101d68:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101d6f:	f0 
f0101d70:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101d77:	00 
f0101d78:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101d7f:	e8 10 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d84:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d8b:	00 
f0101d8c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d93:	00 
f0101d94:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d98:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101d9d:	89 04 24             	mov    %eax,(%esp)
f0101da0:	e8 d2 f4 ff ff       	call   f0101277 <page_insert>
f0101da5:	85 c0                	test   %eax,%eax
f0101da7:	74 24                	je     f0101dcd <mem_init+0xa98>
f0101da9:	c7 44 24 0c 28 50 10 	movl   $0xf0105028,0xc(%esp)
f0101db0:	f0 
f0101db1:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101dc0:	00 
f0101dc1:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101dc8:	e8 c7 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dcd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd2:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101dd7:	e8 4c eb ff ff       	call   f0100928 <check_va2pa>
f0101ddc:	89 f2                	mov    %esi,%edx
f0101dde:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0101de4:	c1 fa 03             	sar    $0x3,%edx
f0101de7:	c1 e2 0c             	shl    $0xc,%edx
f0101dea:	39 d0                	cmp    %edx,%eax
f0101dec:	74 24                	je     f0101e12 <mem_init+0xadd>
f0101dee:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0101df5:	f0 
f0101df6:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101dfd:	f0 
f0101dfe:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101e05:	00 
f0101e06:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101e0d:	e8 82 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e12:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e17:	74 24                	je     f0101e3d <mem_init+0xb08>
f0101e19:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101e20:	f0 
f0101e21:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101e28:	f0 
f0101e29:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101e30:	00 
f0101e31:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101e38:	e8 57 e2 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e3d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e44:	e8 72 f0 ff ff       	call   f0100ebb <page_alloc>
f0101e49:	85 c0                	test   %eax,%eax
f0101e4b:	74 24                	je     f0101e71 <mem_init+0xb3c>
f0101e4d:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f0101e54:	f0 
f0101e55:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0101e64:	00 
f0101e65:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101e6c:	e8 23 e2 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e71:	8b 15 44 dd 17 f0    	mov    0xf017dd44,%edx
f0101e77:	8b 02                	mov    (%edx),%eax
f0101e79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e7e:	89 c1                	mov    %eax,%ecx
f0101e80:	c1 e9 0c             	shr    $0xc,%ecx
f0101e83:	3b 0d 40 dd 17 f0    	cmp    0xf017dd40,%ecx
f0101e89:	72 20                	jb     f0101eab <mem_init+0xb76>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e8b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e8f:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0101e96:	f0 
f0101e97:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0101e9e:	00 
f0101e9f:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101ea6:	e8 e9 e1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101eab:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101eb0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101eb3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eba:	00 
f0101ebb:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ec2:	00 
f0101ec3:	89 14 24             	mov    %edx,(%esp)
f0101ec6:	e8 d0 f0 ff ff       	call   f0100f9b <pgdir_walk>
f0101ecb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101ece:	83 c2 04             	add    $0x4,%edx
f0101ed1:	39 d0                	cmp    %edx,%eax
f0101ed3:	74 24                	je     f0101ef9 <mem_init+0xbc4>
f0101ed5:	c7 44 24 0c 94 50 10 	movl   $0xf0105094,0xc(%esp)
f0101edc:	f0 
f0101edd:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101ee4:	f0 
f0101ee5:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101eec:	00 
f0101eed:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101ef4:	e8 9b e1 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ef9:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101f00:	00 
f0101f01:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f08:	00 
f0101f09:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f0d:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0101f12:	89 04 24             	mov    %eax,(%esp)
f0101f15:	e8 5d f3 ff ff       	call   f0101277 <page_insert>
f0101f1a:	85 c0                	test   %eax,%eax
f0101f1c:	74 24                	je     f0101f42 <mem_init+0xc0d>
f0101f1e:	c7 44 24 0c d4 50 10 	movl   $0xf01050d4,0xc(%esp)
f0101f25:	f0 
f0101f26:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101f2d:	f0 
f0101f2e:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101f35:	00 
f0101f36:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101f3d:	e8 52 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f42:	8b 0d 44 dd 17 f0    	mov    0xf017dd44,%ecx
f0101f48:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101f4b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f50:	89 c8                	mov    %ecx,%eax
f0101f52:	e8 d1 e9 ff ff       	call   f0100928 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f57:	89 f2                	mov    %esi,%edx
f0101f59:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0101f5f:	c1 fa 03             	sar    $0x3,%edx
f0101f62:	c1 e2 0c             	shl    $0xc,%edx
f0101f65:	39 d0                	cmp    %edx,%eax
f0101f67:	74 24                	je     f0101f8d <mem_init+0xc58>
f0101f69:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0101f70:	f0 
f0101f71:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101f78:	f0 
f0101f79:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0101f80:	00 
f0101f81:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101f88:	e8 07 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f8d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f92:	74 24                	je     f0101fb8 <mem_init+0xc83>
f0101f94:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101f9b:	f0 
f0101f9c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101fab:	00 
f0101fac:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101fb3:	e8 dc e0 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101fb8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fbf:	00 
f0101fc0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fc7:	00 
f0101fc8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fcb:	89 04 24             	mov    %eax,(%esp)
f0101fce:	e8 c8 ef ff ff       	call   f0100f9b <pgdir_walk>
f0101fd3:	f6 00 04             	testb  $0x4,(%eax)
f0101fd6:	75 24                	jne    f0101ffc <mem_init+0xcc7>
f0101fd8:	c7 44 24 0c 14 51 10 	movl   $0xf0105114,0xc(%esp)
f0101fdf:	f0 
f0101fe0:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0101fe7:	f0 
f0101fe8:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101fef:	00 
f0101ff0:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0101ff7:	e8 98 e0 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101ffc:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102001:	f6 00 04             	testb  $0x4,(%eax)
f0102004:	75 24                	jne    f010202a <mem_init+0xcf5>
f0102006:	c7 44 24 0c 50 57 10 	movl   $0xf0105750,0xc(%esp)
f010200d:	f0 
f010200e:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102015:	f0 
f0102016:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f010201d:	00 
f010201e:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102025:	e8 6a e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010202a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102031:	00 
f0102032:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102039:	00 
f010203a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010203e:	89 04 24             	mov    %eax,(%esp)
f0102041:	e8 31 f2 ff ff       	call   f0101277 <page_insert>
f0102046:	85 c0                	test   %eax,%eax
f0102048:	78 24                	js     f010206e <mem_init+0xd39>
f010204a:	c7 44 24 0c 48 51 10 	movl   $0xf0105148,0xc(%esp)
f0102051:	f0 
f0102052:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102059:	f0 
f010205a:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102061:	00 
f0102062:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102069:	e8 26 e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010206e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102075:	00 
f0102076:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010207d:	00 
f010207e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102082:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102087:	89 04 24             	mov    %eax,(%esp)
f010208a:	e8 e8 f1 ff ff       	call   f0101277 <page_insert>
f010208f:	85 c0                	test   %eax,%eax
f0102091:	74 24                	je     f01020b7 <mem_init+0xd82>
f0102093:	c7 44 24 0c 80 51 10 	movl   $0xf0105180,0xc(%esp)
f010209a:	f0 
f010209b:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01020a2:	f0 
f01020a3:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01020aa:	00 
f01020ab:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01020b2:	e8 dd df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020b7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020be:	00 
f01020bf:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020c6:	00 
f01020c7:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f01020cc:	89 04 24             	mov    %eax,(%esp)
f01020cf:	e8 c7 ee ff ff       	call   f0100f9b <pgdir_walk>
f01020d4:	f6 00 04             	testb  $0x4,(%eax)
f01020d7:	74 24                	je     f01020fd <mem_init+0xdc8>
f01020d9:	c7 44 24 0c bc 51 10 	movl   $0xf01051bc,0xc(%esp)
f01020e0:	f0 
f01020e1:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01020e8:	f0 
f01020e9:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f01020f0:	00 
f01020f1:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01020f8:	e8 97 df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020fd:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102102:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102105:	ba 00 00 00 00       	mov    $0x0,%edx
f010210a:	e8 19 e8 ff ff       	call   f0100928 <check_va2pa>
f010210f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102112:	89 f8                	mov    %edi,%eax
f0102114:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f010211a:	c1 f8 03             	sar    $0x3,%eax
f010211d:	c1 e0 0c             	shl    $0xc,%eax
f0102120:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102123:	74 24                	je     f0102149 <mem_init+0xe14>
f0102125:	c7 44 24 0c f4 51 10 	movl   $0xf01051f4,0xc(%esp)
f010212c:	f0 
f010212d:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102134:	f0 
f0102135:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f010213c:	00 
f010213d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102144:	e8 4b df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102149:	ba 00 10 00 00       	mov    $0x1000,%edx
f010214e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102151:	e8 d2 e7 ff ff       	call   f0100928 <check_va2pa>
f0102156:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102159:	74 24                	je     f010217f <mem_init+0xe4a>
f010215b:	c7 44 24 0c 20 52 10 	movl   $0xf0105220,0xc(%esp)
f0102162:	f0 
f0102163:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010216a:	f0 
f010216b:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102172:	00 
f0102173:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010217a:	e8 15 df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010217f:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102184:	74 24                	je     f01021aa <mem_init+0xe75>
f0102186:	c7 44 24 0c 66 57 10 	movl   $0xf0105766,0xc(%esp)
f010218d:	f0 
f010218e:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102195:	f0 
f0102196:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f010219d:	00 
f010219e:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01021a5:	e8 ea de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01021aa:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021af:	74 24                	je     f01021d5 <mem_init+0xea0>
f01021b1:	c7 44 24 0c 77 57 10 	movl   $0xf0105777,0xc(%esp)
f01021b8:	f0 
f01021b9:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01021c0:	f0 
f01021c1:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01021c8:	00 
f01021c9:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01021d0:	e8 bf de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01021d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021dc:	e8 da ec ff ff       	call   f0100ebb <page_alloc>
f01021e1:	85 c0                	test   %eax,%eax
f01021e3:	74 04                	je     f01021e9 <mem_init+0xeb4>
f01021e5:	39 c6                	cmp    %eax,%esi
f01021e7:	74 24                	je     f010220d <mem_init+0xed8>
f01021e9:	c7 44 24 0c 50 52 10 	movl   $0xf0105250,0xc(%esp)
f01021f0:	f0 
f01021f1:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01021f8:	f0 
f01021f9:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102200:	00 
f0102201:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102208:	e8 87 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010220d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102214:	00 
f0102215:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f010221a:	89 04 24             	mov    %eax,(%esp)
f010221d:	e8 05 f0 ff ff       	call   f0101227 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102222:	8b 15 44 dd 17 f0    	mov    0xf017dd44,%edx
f0102228:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010222b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102230:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102233:	e8 f0 e6 ff ff       	call   f0100928 <check_va2pa>
f0102238:	83 f8 ff             	cmp    $0xffffffff,%eax
f010223b:	74 24                	je     f0102261 <mem_init+0xf2c>
f010223d:	c7 44 24 0c 74 52 10 	movl   $0xf0105274,0xc(%esp)
f0102244:	f0 
f0102245:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010224c:	f0 
f010224d:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102254:	00 
f0102255:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010225c:	e8 33 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102261:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102266:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102269:	e8 ba e6 ff ff       	call   f0100928 <check_va2pa>
f010226e:	89 fa                	mov    %edi,%edx
f0102270:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0102276:	c1 fa 03             	sar    $0x3,%edx
f0102279:	c1 e2 0c             	shl    $0xc,%edx
f010227c:	39 d0                	cmp    %edx,%eax
f010227e:	74 24                	je     f01022a4 <mem_init+0xf6f>
f0102280:	c7 44 24 0c 20 52 10 	movl   $0xf0105220,0xc(%esp)
f0102287:	f0 
f0102288:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010228f:	f0 
f0102290:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0102297:	00 
f0102298:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010229f:	e8 f0 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01022a4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01022a9:	74 24                	je     f01022cf <mem_init+0xf9a>
f01022ab:	c7 44 24 0c 1d 57 10 	movl   $0xf010571d,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01022ca:	e8 c5 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022cf:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01022d4:	74 24                	je     f01022fa <mem_init+0xfc5>
f01022d6:	c7 44 24 0c 77 57 10 	movl   $0xf0105777,0xc(%esp)
f01022dd:	f0 
f01022de:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01022e5:	f0 
f01022e6:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f01022ed:	00 
f01022ee:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01022f5:	e8 9a dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102301:	00 
f0102302:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102305:	89 0c 24             	mov    %ecx,(%esp)
f0102308:	e8 1a ef ff ff       	call   f0101227 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010230d:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102312:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102315:	ba 00 00 00 00       	mov    $0x0,%edx
f010231a:	e8 09 e6 ff ff       	call   f0100928 <check_va2pa>
f010231f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102322:	74 24                	je     f0102348 <mem_init+0x1013>
f0102324:	c7 44 24 0c 74 52 10 	movl   $0xf0105274,0xc(%esp)
f010232b:	f0 
f010232c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102333:	f0 
f0102334:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f010233b:	00 
f010233c:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102343:	e8 4c dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102348:	ba 00 10 00 00       	mov    $0x1000,%edx
f010234d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102350:	e8 d3 e5 ff ff       	call   f0100928 <check_va2pa>
f0102355:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102358:	74 24                	je     f010237e <mem_init+0x1049>
f010235a:	c7 44 24 0c 98 52 10 	movl   $0xf0105298,0xc(%esp)
f0102361:	f0 
f0102362:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102369:	f0 
f010236a:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102371:	00 
f0102372:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102379:	e8 16 dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010237e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102383:	74 24                	je     f01023a9 <mem_init+0x1074>
f0102385:	c7 44 24 0c 88 57 10 	movl   $0xf0105788,0xc(%esp)
f010238c:	f0 
f010238d:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102394:	f0 
f0102395:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f010239c:	00 
f010239d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01023a4:	e8 eb dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01023a9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023ae:	74 24                	je     f01023d4 <mem_init+0x109f>
f01023b0:	c7 44 24 0c 77 57 10 	movl   $0xf0105777,0xc(%esp)
f01023b7:	f0 
f01023b8:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01023bf:	f0 
f01023c0:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01023c7:	00 
f01023c8:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01023cf:	e8 c0 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01023d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023db:	e8 db ea ff ff       	call   f0100ebb <page_alloc>
f01023e0:	85 c0                	test   %eax,%eax
f01023e2:	74 04                	je     f01023e8 <mem_init+0x10b3>
f01023e4:	39 c7                	cmp    %eax,%edi
f01023e6:	74 24                	je     f010240c <mem_init+0x10d7>
f01023e8:	c7 44 24 0c c0 52 10 	movl   $0xf01052c0,0xc(%esp)
f01023ef:	f0 
f01023f0:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01023f7:	f0 
f01023f8:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01023ff:	00 
f0102400:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102407:	e8 88 dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010240c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102413:	e8 a3 ea ff ff       	call   f0100ebb <page_alloc>
f0102418:	85 c0                	test   %eax,%eax
f010241a:	74 24                	je     f0102440 <mem_init+0x110b>
f010241c:	c7 44 24 0c cb 56 10 	movl   $0xf01056cb,0xc(%esp)
f0102423:	f0 
f0102424:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010242b:	f0 
f010242c:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102433:	00 
f0102434:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010243b:	e8 54 dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102440:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102445:	8b 08                	mov    (%eax),%ecx
f0102447:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010244d:	89 da                	mov    %ebx,%edx
f010244f:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0102455:	c1 fa 03             	sar    $0x3,%edx
f0102458:	c1 e2 0c             	shl    $0xc,%edx
f010245b:	39 d1                	cmp    %edx,%ecx
f010245d:	74 24                	je     f0102483 <mem_init+0x114e>
f010245f:	c7 44 24 0c d0 4f 10 	movl   $0xf0104fd0,0xc(%esp)
f0102466:	f0 
f0102467:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010246e:	f0 
f010246f:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102476:	00 
f0102477:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010247e:	e8 11 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102483:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102489:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010248e:	74 24                	je     f01024b4 <mem_init+0x117f>
f0102490:	c7 44 24 0c 2e 57 10 	movl   $0xf010572e,0xc(%esp)
f0102497:	f0 
f0102498:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010249f:	f0 
f01024a0:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01024a7:	00 
f01024a8:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01024af:	e8 e0 db ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01024b4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024ba:	89 1c 24             	mov    %ebx,(%esp)
f01024bd:	e8 77 ea ff ff       	call   f0100f39 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024c2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024c9:	00 
f01024ca:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01024d1:	00 
f01024d2:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f01024d7:	89 04 24             	mov    %eax,(%esp)
f01024da:	e8 bc ea ff ff       	call   f0100f9b <pgdir_walk>
f01024df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024e2:	8b 0d 44 dd 17 f0    	mov    0xf017dd44,%ecx
f01024e8:	8b 51 04             	mov    0x4(%ecx),%edx
f01024eb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01024f1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024f4:	8b 15 40 dd 17 f0    	mov    0xf017dd40,%edx
f01024fa:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01024fd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102500:	c1 ea 0c             	shr    $0xc,%edx
f0102503:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102506:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102509:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010250c:	72 23                	jb     f0102531 <mem_init+0x11fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010250e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102511:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102515:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f010251c:	f0 
f010251d:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102524:	00 
f0102525:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010252c:	e8 63 db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102531:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102534:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010253a:	39 d0                	cmp    %edx,%eax
f010253c:	74 24                	je     f0102562 <mem_init+0x122d>
f010253e:	c7 44 24 0c 99 57 10 	movl   $0xf0105799,0xc(%esp)
f0102545:	f0 
f0102546:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010254d:	f0 
f010254e:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102555:	00 
f0102556:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010255d:	e8 32 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102562:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102569:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010256f:	89 d8                	mov    %ebx,%eax
f0102571:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0102577:	c1 f8 03             	sar    $0x3,%eax
f010257a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010257d:	89 c1                	mov    %eax,%ecx
f010257f:	c1 e9 0c             	shr    $0xc,%ecx
f0102582:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102585:	77 20                	ja     f01025a7 <mem_init+0x1272>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102587:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010258b:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0102592:	f0 
f0102593:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010259a:	00 
f010259b:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f01025a2:	e8 ed da ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025a7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025ae:	00 
f01025af:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025b6:	00 
	return (void *)(pa + KERNBASE);
f01025b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025bc:	89 04 24             	mov    %eax,(%esp)
f01025bf:	e8 72 1d 00 00       	call   f0104336 <memset>
	page_free(pp0);
f01025c4:	89 1c 24             	mov    %ebx,(%esp)
f01025c7:	e8 6d e9 ff ff       	call   f0100f39 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025cc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01025d3:	00 
f01025d4:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025db:	00 
f01025dc:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f01025e1:	89 04 24             	mov    %eax,(%esp)
f01025e4:	e8 b2 e9 ff ff       	call   f0100f9b <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01025e9:	89 da                	mov    %ebx,%edx
f01025eb:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f01025f1:	c1 fa 03             	sar    $0x3,%edx
f01025f4:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025f7:	89 d0                	mov    %edx,%eax
f01025f9:	c1 e8 0c             	shr    $0xc,%eax
f01025fc:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f0102602:	72 20                	jb     f0102624 <mem_init+0x12ef>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102604:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102608:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f010260f:	f0 
f0102610:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102617:	00 
f0102618:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f010261f:	e8 70 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102624:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010262a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010262d:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102634:	75 11                	jne    f0102647 <mem_init+0x1312>
f0102636:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010263c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102642:	f6 00 01             	testb  $0x1,(%eax)
f0102645:	74 24                	je     f010266b <mem_init+0x1336>
f0102647:	c7 44 24 0c b1 57 10 	movl   $0xf01057b1,0xc(%esp)
f010264e:	f0 
f010264f:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102656:	f0 
f0102657:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f010265e:	00 
f010265f:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102666:	e8 29 da ff ff       	call   f0100094 <_panic>
f010266b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010266e:	39 d0                	cmp    %edx,%eax
f0102670:	75 d0                	jne    f0102642 <mem_init+0x130d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102672:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102677:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010267d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102683:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102686:	89 0d a0 d0 17 f0    	mov    %ecx,0xf017d0a0

	// free the pages we took
	page_free(pp0);
f010268c:	89 1c 24             	mov    %ebx,(%esp)
f010268f:	e8 a5 e8 ff ff       	call   f0100f39 <page_free>
	page_free(pp1);
f0102694:	89 3c 24             	mov    %edi,(%esp)
f0102697:	e8 9d e8 ff ff       	call   f0100f39 <page_free>
	page_free(pp2);
f010269c:	89 34 24             	mov    %esi,(%esp)
f010269f:	e8 95 e8 ff ff       	call   f0100f39 <page_free>

	cprintf("check_page() succeeded!\n");
f01026a4:	c7 04 24 c8 57 10 f0 	movl   $0xf01057c8,(%esp)
f01026ab:	e8 3e 0d 00 00       	call   f01033ee <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct Page),
f01026b0:	a1 48 dd 17 f0       	mov    0xf017dd48,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026b5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026ba:	77 20                	ja     f01026dc <mem_init+0x13a7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026c0:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f01026c7:	f0 
f01026c8:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f01026cf:	00 
f01026d0:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01026d7:	e8 b8 d9 ff ff       	call   f0100094 <_panic>
f01026dc:	8b 15 40 dd 17 f0    	mov    0xf017dd40,%edx
f01026e2:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026e9:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026ef:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01026f6:	00 
	return (physaddr_t)kva - KERNBASE;
f01026f7:	05 00 00 00 10       	add    $0x10000000,%eax
f01026fc:	89 04 24             	mov    %eax,(%esp)
f01026ff:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102704:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102709:	e8 9c e9 ff ff       	call   f01010aa <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
    boot_map_region(kern_pgdir, UENVS, ROUNDUP(npages * sizeof(struct Env),
f010270e:	a1 a8 d0 17 f0       	mov    0xf017d0a8,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102713:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102718:	77 20                	ja     f010273a <mem_init+0x1405>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010271a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010271e:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0102725:	f0 
f0102726:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
f010272d:	00 
f010272e:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102735:	e8 5a d9 ff ff       	call   f0100094 <_panic>
f010273a:	8b 15 40 dd 17 f0    	mov    0xf017dd40,%edx
f0102740:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0102743:	c1 e1 05             	shl    $0x5,%ecx
f0102746:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f010274c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102752:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102759:	00 
	return (physaddr_t)kva - KERNBASE;
f010275a:	05 00 00 00 10       	add    $0x10000000,%eax
f010275f:	89 04 24             	mov    %eax,(%esp)
f0102762:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102767:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f010276c:	e8 39 e9 ff ff       	call   f01010aa <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102771:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f0102776:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010277b:	77 20                	ja     f010279d <mem_init+0x1468>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010277d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102781:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0102788:	f0 
f0102789:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
f0102790:	00 
f0102791:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102798:	e8 f7 d8 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE,
f010279d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027a4:	00 
f01027a5:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f01027ac:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027b1:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01027b6:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f01027bb:	e8 ea e8 ff ff       	call   f01010aa <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, ~KERNBASE + 1, 0x0, PTE_W);
f01027c0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027c7:	00 
f01027c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027cf:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027d4:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027d9:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f01027de:	e8 c7 e8 ff ff       	call   f01010aa <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027e3:	8b 1d 44 dd 17 f0    	mov    0xf017dd44,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f01027e9:	8b 15 40 dd 17 f0    	mov    0xf017dd40,%edx
f01027ef:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01027f2:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f01027f9:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f01027ff:	0f 84 80 00 00 00    	je     f0102885 <mem_init+0x1550>
f0102805:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010280a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102810:	89 d8                	mov    %ebx,%eax
f0102812:	e8 11 e1 ff ff       	call   f0100928 <check_va2pa>
f0102817:	8b 15 48 dd 17 f0    	mov    0xf017dd48,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010281d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102823:	77 20                	ja     f0102845 <mem_init+0x1510>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102825:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102829:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0102830:	f0 
f0102831:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102838:	00 
f0102839:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102840:	e8 4f d8 ff ff       	call   f0100094 <_panic>
f0102845:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f010284c:	39 d0                	cmp    %edx,%eax
f010284e:	74 24                	je     f0102874 <mem_init+0x153f>
f0102850:	c7 44 24 0c e4 52 10 	movl   $0xf01052e4,0xc(%esp)
f0102857:	f0 
f0102858:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f010285f:	f0 
f0102860:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102867:	00 
f0102868:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f010286f:	e8 20 d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102874:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010287a:	39 f7                	cmp    %esi,%edi
f010287c:	77 8c                	ja     f010280a <mem_init+0x14d5>
f010287e:	be 00 00 00 00       	mov    $0x0,%esi
f0102883:	eb 05                	jmp    f010288a <mem_init+0x1555>
f0102885:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010288a:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102890:	89 d8                	mov    %ebx,%eax
f0102892:	e8 91 e0 ff ff       	call   f0100928 <check_va2pa>
f0102897:	8b 15 a8 d0 17 f0    	mov    0xf017d0a8,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010289d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01028a3:	77 20                	ja     f01028c5 <mem_init+0x1590>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028a5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01028a9:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f01028b0:	f0 
f01028b1:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01028b8:	00 
f01028b9:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01028c0:	e8 cf d7 ff ff       	call   f0100094 <_panic>
f01028c5:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01028cc:	39 d0                	cmp    %edx,%eax
f01028ce:	74 24                	je     f01028f4 <mem_init+0x15bf>
f01028d0:	c7 44 24 0c 18 53 10 	movl   $0xf0105318,0xc(%esp)
f01028d7:	f0 
f01028d8:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01028df:	f0 
f01028e0:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01028e7:	00 
f01028e8:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01028ef:	e8 a0 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028f4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028fa:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0102900:	75 88                	jne    f010288a <mem_init+0x1555>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102902:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102905:	c1 e7 0c             	shl    $0xc,%edi
f0102908:	85 ff                	test   %edi,%edi
f010290a:	74 44                	je     f0102950 <mem_init+0x161b>
f010290c:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102911:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102917:	89 d8                	mov    %ebx,%eax
f0102919:	e8 0a e0 ff ff       	call   f0100928 <check_va2pa>
f010291e:	39 c6                	cmp    %eax,%esi
f0102920:	74 24                	je     f0102946 <mem_init+0x1611>
f0102922:	c7 44 24 0c 4c 53 10 	movl   $0xf010534c,0xc(%esp)
f0102929:	f0 
f010292a:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102931:	f0 
f0102932:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0102939:	00 
f010293a:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102941:	e8 4e d7 ff ff       	call   f0100094 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102946:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010294c:	39 fe                	cmp    %edi,%esi
f010294e:	72 c1                	jb     f0102911 <mem_init+0x15dc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102950:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102955:	89 d8                	mov    %ebx,%eax
f0102957:	e8 cc df ff ff       	call   f0100928 <check_va2pa>
f010295c:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102961:	bf 00 10 11 f0       	mov    $0xf0111000,%edi
f0102966:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f010296c:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010296f:	39 c2                	cmp    %eax,%edx
f0102971:	74 24                	je     f0102997 <mem_init+0x1662>
f0102973:	c7 44 24 0c 74 53 10 	movl   $0xf0105374,0xc(%esp)
f010297a:	f0 
f010297b:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102982:	f0 
f0102983:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f010298a:	00 
f010298b:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102992:	e8 fd d6 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102997:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f010299d:	0f 85 27 05 00 00    	jne    f0102eca <mem_init+0x1b95>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029a3:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01029a8:	89 d8                	mov    %ebx,%eax
f01029aa:	e8 79 df ff ff       	call   f0100928 <check_va2pa>
f01029af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029b2:	74 24                	je     f01029d8 <mem_init+0x16a3>
f01029b4:	c7 44 24 0c bc 53 10 	movl   $0xf01053bc,0xc(%esp)
f01029bb:	f0 
f01029bc:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01029c3:	f0 
f01029c4:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01029cb:	00 
f01029cc:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f01029d3:	e8 bc d6 ff ff       	call   f0100094 <_panic>
f01029d8:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01029dd:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01029e3:	83 fa 03             	cmp    $0x3,%edx
f01029e6:	77 2e                	ja     f0102a16 <mem_init+0x16e1>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f01029e8:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01029ec:	0f 85 aa 00 00 00    	jne    f0102a9c <mem_init+0x1767>
f01029f2:	c7 44 24 0c e1 57 10 	movl   $0xf01057e1,0xc(%esp)
f01029f9:	f0 
f01029fa:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102a01:	f0 
f0102a02:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102a09:	00 
f0102a0a:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102a11:	e8 7e d6 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a16:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a1b:	76 55                	jbe    f0102a72 <mem_init+0x173d>
				assert(pgdir[i] & PTE_P);
f0102a1d:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102a20:	f6 c2 01             	test   $0x1,%dl
f0102a23:	75 24                	jne    f0102a49 <mem_init+0x1714>
f0102a25:	c7 44 24 0c e1 57 10 	movl   $0xf01057e1,0xc(%esp)
f0102a2c:	f0 
f0102a2d:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102a34:	f0 
f0102a35:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102a3c:	00 
f0102a3d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102a44:	e8 4b d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a49:	f6 c2 02             	test   $0x2,%dl
f0102a4c:	75 4e                	jne    f0102a9c <mem_init+0x1767>
f0102a4e:	c7 44 24 0c f2 57 10 	movl   $0xf01057f2,0xc(%esp)
f0102a55:	f0 
f0102a56:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102a5d:	f0 
f0102a5e:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102a65:	00 
f0102a66:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102a6d:	e8 22 d6 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a72:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102a76:	74 24                	je     f0102a9c <mem_init+0x1767>
f0102a78:	c7 44 24 0c 03 58 10 	movl   $0xf0105803,0xc(%esp)
f0102a7f:	f0 
f0102a80:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102a87:	f0 
f0102a88:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102a8f:	00 
f0102a90:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102a97:	e8 f8 d5 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102a9c:	83 c0 01             	add    $0x1,%eax
f0102a9f:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102aa4:	0f 85 33 ff ff ff    	jne    f01029dd <mem_init+0x16a8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102aaa:	c7 04 24 ec 53 10 f0 	movl   $0xf01053ec,(%esp)
f0102ab1:	e8 38 09 00 00       	call   f01033ee <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ab6:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102abb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ac0:	77 20                	ja     f0102ae2 <mem_init+0x17ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ac2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102ac6:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0102acd:	f0 
f0102ace:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0102ad5:	00 
f0102ad6:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102add:	e8 b2 d5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102ae2:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102ae7:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102aea:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aef:	e8 3e df ff ff       	call   f0100a32 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102af4:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102af7:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102afc:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102aff:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b09:	e8 ad e3 ff ff       	call   f0100ebb <page_alloc>
f0102b0e:	89 c6                	mov    %eax,%esi
f0102b10:	85 c0                	test   %eax,%eax
f0102b12:	75 24                	jne    f0102b38 <mem_init+0x1803>
f0102b14:	c7 44 24 0c 20 56 10 	movl   $0xf0105620,0xc(%esp)
f0102b1b:	f0 
f0102b1c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102b23:	f0 
f0102b24:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b2b:	00 
f0102b2c:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102b33:	e8 5c d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b3f:	e8 77 e3 ff ff       	call   f0100ebb <page_alloc>
f0102b44:	89 c7                	mov    %eax,%edi
f0102b46:	85 c0                	test   %eax,%eax
f0102b48:	75 24                	jne    f0102b6e <mem_init+0x1839>
f0102b4a:	c7 44 24 0c 36 56 10 	movl   $0xf0105636,0xc(%esp)
f0102b51:	f0 
f0102b52:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102b59:	f0 
f0102b5a:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f0102b61:	00 
f0102b62:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102b69:	e8 26 d5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b75:	e8 41 e3 ff ff       	call   f0100ebb <page_alloc>
f0102b7a:	89 c3                	mov    %eax,%ebx
f0102b7c:	85 c0                	test   %eax,%eax
f0102b7e:	75 24                	jne    f0102ba4 <mem_init+0x186f>
f0102b80:	c7 44 24 0c 4c 56 10 	movl   $0xf010564c,0xc(%esp)
f0102b87:	f0 
f0102b88:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102b8f:	f0 
f0102b90:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102b97:	00 
f0102b98:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102b9f:	e8 f0 d4 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102ba4:	89 34 24             	mov    %esi,(%esp)
f0102ba7:	e8 8d e3 ff ff       	call   f0100f39 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bac:	89 f8                	mov    %edi,%eax
f0102bae:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0102bb4:	c1 f8 03             	sar    $0x3,%eax
f0102bb7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bba:	89 c2                	mov    %eax,%edx
f0102bbc:	c1 ea 0c             	shr    $0xc,%edx
f0102bbf:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0102bc5:	72 20                	jb     f0102be7 <mem_init+0x18b2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bc7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bcb:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0102bd2:	f0 
f0102bd3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102bda:	00 
f0102bdb:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0102be2:	e8 ad d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102be7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bee:	00 
f0102bef:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102bf6:	00 
	return (void *)(pa + KERNBASE);
f0102bf7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bfc:	89 04 24             	mov    %eax,(%esp)
f0102bff:	e8 32 17 00 00       	call   f0104336 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c04:	89 d8                	mov    %ebx,%eax
f0102c06:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0102c0c:	c1 f8 03             	sar    $0x3,%eax
f0102c0f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c12:	89 c2                	mov    %eax,%edx
f0102c14:	c1 ea 0c             	shr    $0xc,%edx
f0102c17:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0102c1d:	72 20                	jb     f0102c3f <mem_init+0x190a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c1f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c23:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0102c2a:	f0 
f0102c2b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102c32:	00 
f0102c33:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0102c3a:	e8 55 d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c3f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c46:	00 
f0102c47:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c4e:	00 
	return (void *)(pa + KERNBASE);
f0102c4f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c54:	89 04 24             	mov    %eax,(%esp)
f0102c57:	e8 da 16 00 00       	call   f0104336 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c5c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c63:	00 
f0102c64:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c6b:	00 
f0102c6c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102c70:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102c75:	89 04 24             	mov    %eax,(%esp)
f0102c78:	e8 fa e5 ff ff       	call   f0101277 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c7d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c82:	74 24                	je     f0102ca8 <mem_init+0x1973>
f0102c84:	c7 44 24 0c 1d 57 10 	movl   $0xf010571d,0xc(%esp)
f0102c8b:	f0 
f0102c8c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102c93:	f0 
f0102c94:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0102c9b:	00 
f0102c9c:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102ca3:	e8 ec d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ca8:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102caf:	01 01 01 
f0102cb2:	74 24                	je     f0102cd8 <mem_init+0x19a3>
f0102cb4:	c7 44 24 0c 0c 54 10 	movl   $0xf010540c,0xc(%esp)
f0102cbb:	f0 
f0102cbc:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102cc3:	f0 
f0102cc4:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0102ccb:	00 
f0102ccc:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102cd3:	e8 bc d3 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102cd8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102cdf:	00 
f0102ce0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ce7:	00 
f0102ce8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cec:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102cf1:	89 04 24             	mov    %eax,(%esp)
f0102cf4:	e8 7e e5 ff ff       	call   f0101277 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cf9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d00:	02 02 02 
f0102d03:	74 24                	je     f0102d29 <mem_init+0x19f4>
f0102d05:	c7 44 24 0c 30 54 10 	movl   $0xf0105430,0xc(%esp)
f0102d0c:	f0 
f0102d0d:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102d14:	f0 
f0102d15:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0102d1c:	00 
f0102d1d:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102d24:	e8 6b d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102d29:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d2e:	74 24                	je     f0102d54 <mem_init+0x1a1f>
f0102d30:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0102d37:	f0 
f0102d38:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102d3f:	f0 
f0102d40:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0102d47:	00 
f0102d48:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102d4f:	e8 40 d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102d54:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d59:	74 24                	je     f0102d7f <mem_init+0x1a4a>
f0102d5b:	c7 44 24 0c 88 57 10 	movl   $0xf0105788,0xc(%esp)
f0102d62:	f0 
f0102d63:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102d6a:	f0 
f0102d6b:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102d72:	00 
f0102d73:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102d7a:	e8 15 d3 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d7f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d86:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d89:	89 d8                	mov    %ebx,%eax
f0102d8b:	2b 05 48 dd 17 f0    	sub    0xf017dd48,%eax
f0102d91:	c1 f8 03             	sar    $0x3,%eax
f0102d94:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d97:	89 c2                	mov    %eax,%edx
f0102d99:	c1 ea 0c             	shr    $0xc,%edx
f0102d9c:	3b 15 40 dd 17 f0    	cmp    0xf017dd40,%edx
f0102da2:	72 20                	jb     f0102dc4 <mem_init+0x1a8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102da4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102da8:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f0102daf:	f0 
f0102db0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102db7:	00 
f0102db8:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f0102dbf:	e8 d0 d2 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dc4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102dcb:	03 03 03 
f0102dce:	74 24                	je     f0102df4 <mem_init+0x1abf>
f0102dd0:	c7 44 24 0c 54 54 10 	movl   $0xf0105454,0xc(%esp)
f0102dd7:	f0 
f0102dd8:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102ddf:	f0 
f0102de0:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102de7:	00 
f0102de8:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102def:	e8 a0 d2 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102df4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102dfb:	00 
f0102dfc:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102e01:	89 04 24             	mov    %eax,(%esp)
f0102e04:	e8 1e e4 ff ff       	call   f0101227 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e09:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102e0e:	74 24                	je     f0102e34 <mem_init+0x1aff>
f0102e10:	c7 44 24 0c 77 57 10 	movl   $0xf0105777,0xc(%esp)
f0102e17:	f0 
f0102e18:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102e1f:	f0 
f0102e20:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102e27:	00 
f0102e28:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102e2f:	e8 60 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e34:	a1 44 dd 17 f0       	mov    0xf017dd44,%eax
f0102e39:	8b 08                	mov    (%eax),%ecx
f0102e3b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e41:	89 f2                	mov    %esi,%edx
f0102e43:	2b 15 48 dd 17 f0    	sub    0xf017dd48,%edx
f0102e49:	c1 fa 03             	sar    $0x3,%edx
f0102e4c:	c1 e2 0c             	shl    $0xc,%edx
f0102e4f:	39 d1                	cmp    %edx,%ecx
f0102e51:	74 24                	je     f0102e77 <mem_init+0x1b42>
f0102e53:	c7 44 24 0c d0 4f 10 	movl   $0xf0104fd0,0xc(%esp)
f0102e5a:	f0 
f0102e5b:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102e62:	f0 
f0102e63:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102e6a:	00 
f0102e6b:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102e72:	e8 1d d2 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102e77:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102e7d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102e82:	74 24                	je     f0102ea8 <mem_init+0x1b73>
f0102e84:	c7 44 24 0c 2e 57 10 	movl   $0xf010572e,0xc(%esp)
f0102e8b:	f0 
f0102e8c:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0102e93:	f0 
f0102e94:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0102e9b:	00 
f0102e9c:	c7 04 24 e1 54 10 f0 	movl   $0xf01054e1,(%esp)
f0102ea3:	e8 ec d1 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102ea8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102eae:	89 34 24             	mov    %esi,(%esp)
f0102eb1:	e8 83 e0 ff ff       	call   f0100f39 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102eb6:	c7 04 24 80 54 10 f0 	movl   $0xf0105480,(%esp)
f0102ebd:	e8 2c 05 00 00       	call   f01033ee <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ec2:	83 c4 3c             	add    $0x3c,%esp
f0102ec5:	5b                   	pop    %ebx
f0102ec6:	5e                   	pop    %esi
f0102ec7:	5f                   	pop    %edi
f0102ec8:	5d                   	pop    %ebp
f0102ec9:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102eca:	89 f2                	mov    %esi,%edx
f0102ecc:	89 d8                	mov    %ebx,%eax
f0102ece:	e8 55 da ff ff       	call   f0100928 <check_va2pa>
f0102ed3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102ed9:	e9 8e fa ff ff       	jmp    f010296c <mem_init+0x1637>

f0102ede <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102ede:	55                   	push   %ebp
f0102edf:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102ee1:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ee6:	5d                   	pop    %ebp
f0102ee7:	c3                   	ret    

f0102ee8 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102ee8:	55                   	push   %ebp
f0102ee9:	89 e5                	mov    %esp,%ebp
f0102eeb:	53                   	push   %ebx
f0102eec:	83 ec 14             	sub    $0x14,%esp
f0102eef:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102ef2:	8b 45 14             	mov    0x14(%ebp),%eax
f0102ef5:	83 c8 04             	or     $0x4,%eax
f0102ef8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102efc:	8b 45 10             	mov    0x10(%ebp),%eax
f0102eff:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f03:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f06:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f0a:	89 1c 24             	mov    %ebx,(%esp)
f0102f0d:	e8 cc ff ff ff       	call   f0102ede <user_mem_check>
f0102f12:	85 c0                	test   %eax,%eax
f0102f14:	79 23                	jns    f0102f39 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f16:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102f1d:	00 
f0102f1e:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f25:	c7 04 24 ac 54 10 f0 	movl   $0xf01054ac,(%esp)
f0102f2c:	e8 bd 04 00 00       	call   f01033ee <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f31:	89 1c 24             	mov    %ebx,(%esp)
f0102f34:	e8 cb 03 00 00       	call   f0103304 <env_destroy>
	}
}
f0102f39:	83 c4 14             	add    $0x14,%esp
f0102f3c:	5b                   	pop    %ebx
f0102f3d:	5d                   	pop    %ebp
f0102f3e:	c3                   	ret    
	...

f0102f40 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102f40:	55                   	push   %ebp
f0102f41:	89 e5                	mov    %esp,%ebp
f0102f43:	53                   	push   %ebx
f0102f44:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f47:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102f4a:	85 c0                	test   %eax,%eax
f0102f4c:	75 0e                	jne    f0102f5c <envid2env+0x1c>
		*env_store = curenv;
f0102f4e:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f0102f53:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102f55:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f5a:	eb 57                	jmp    f0102fb3 <envid2env+0x73>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102f5c:	89 c2                	mov    %eax,%edx
f0102f5e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0102f64:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102f67:	c1 e2 05             	shl    $0x5,%edx
f0102f6a:	03 15 a8 d0 17 f0    	add    0xf017d0a8,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102f70:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0102f74:	74 05                	je     f0102f7b <envid2env+0x3b>
f0102f76:	39 42 48             	cmp    %eax,0x48(%edx)
f0102f79:	74 0d                	je     f0102f88 <envid2env+0x48>
		*env_store = 0;
f0102f7b:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0102f81:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102f86:	eb 2b                	jmp    f0102fb3 <envid2env+0x73>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102f88:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0102f8c:	74 1e                	je     f0102fac <envid2env+0x6c>
f0102f8e:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f0102f93:	39 c2                	cmp    %eax,%edx
f0102f95:	74 15                	je     f0102fac <envid2env+0x6c>
f0102f97:	8b 58 48             	mov    0x48(%eax),%ebx
f0102f9a:	39 5a 4c             	cmp    %ebx,0x4c(%edx)
f0102f9d:	74 0d                	je     f0102fac <envid2env+0x6c>
		*env_store = 0;
f0102f9f:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0102fa5:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102faa:	eb 07                	jmp    f0102fb3 <envid2env+0x73>
	}

	*env_store = e;
f0102fac:	89 11                	mov    %edx,(%ecx)
	return 0;
f0102fae:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fb3:	5b                   	pop    %ebx
f0102fb4:	5d                   	pop    %ebp
f0102fb5:	c3                   	ret    

f0102fb6 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102fb6:	55                   	push   %ebp
f0102fb7:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102fb9:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f0102fbe:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102fc1:	b8 23 00 00 00       	mov    $0x23,%eax
f0102fc6:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102fc8:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102fca:	b0 10                	mov    $0x10,%al
f0102fcc:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102fce:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102fd0:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102fd2:	ea d9 2f 10 f0 08 00 	ljmp   $0x8,$0xf0102fd9
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102fd9:	b0 00                	mov    $0x0,%al
f0102fdb:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102fde:	5d                   	pop    %ebp
f0102fdf:	c3                   	ret    

f0102fe0 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102fe0:	55                   	push   %ebp
f0102fe1:	89 e5                	mov    %esp,%ebp
	// Set up envs array
	// LAB 3: Your code here.

	// Per-CPU part of the initialization
	env_init_percpu();
f0102fe3:	e8 ce ff ff ff       	call   f0102fb6 <env_init_percpu>
}
f0102fe8:	5d                   	pop    %ebp
f0102fe9:	c3                   	ret    

f0102fea <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102fea:	55                   	push   %ebp
f0102feb:	89 e5                	mov    %esp,%ebp
f0102fed:	53                   	push   %ebx
f0102fee:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102ff1:	8b 1d ac d0 17 f0    	mov    0xf017d0ac,%ebx
f0102ff7:	85 db                	test   %ebx,%ebx
f0102ff9:	0f 84 06 01 00 00    	je     f0103105 <env_alloc+0x11b>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102fff:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103006:	e8 b0 de ff ff       	call   f0100ebb <page_alloc>
f010300b:	85 c0                	test   %eax,%eax
f010300d:	0f 84 f9 00 00 00    	je     f010310c <env_alloc+0x122>

	// LAB 3: Your code here.

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103013:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103016:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010301b:	77 20                	ja     f010303d <env_alloc+0x53>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010301d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103021:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f0103028:	f0 
f0103029:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f0103030:	00 
f0103031:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f0103038:	e8 57 d0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010303d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0103043:	83 ca 05             	or     $0x5,%edx
f0103046:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f010304c:	8b 43 48             	mov    0x48(%ebx),%eax
f010304f:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103054:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103059:	ba 00 10 00 00       	mov    $0x1000,%edx
f010305e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0103061:	89 da                	mov    %ebx,%edx
f0103063:	2b 15 a8 d0 17 f0    	sub    0xf017d0a8,%edx
f0103069:	c1 fa 05             	sar    $0x5,%edx
f010306c:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0103072:	09 d0                	or     %edx,%eax
f0103074:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103077:	8b 45 0c             	mov    0xc(%ebp),%eax
f010307a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f010307d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103084:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f010308b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103092:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103099:	00 
f010309a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01030a1:	00 
f01030a2:	89 1c 24             	mov    %ebx,(%esp)
f01030a5:	e8 8c 12 00 00       	call   f0104336 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01030aa:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f01030b0:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f01030b6:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f01030bc:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f01030c3:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f01030c9:	8b 43 44             	mov    0x44(%ebx),%eax
f01030cc:	a3 ac d0 17 f0       	mov    %eax,0xf017d0ac
	*newenv_store = e;
f01030d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01030d4:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01030d6:	8b 4b 48             	mov    0x48(%ebx),%ecx
f01030d9:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f01030de:	ba 00 00 00 00       	mov    $0x0,%edx
f01030e3:	85 c0                	test   %eax,%eax
f01030e5:	74 03                	je     f01030ea <env_alloc+0x100>
f01030e7:	8b 50 48             	mov    0x48(%eax),%edx
f01030ea:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01030ee:	89 54 24 04          	mov    %edx,0x4(%esp)
f01030f2:	c7 04 24 55 58 10 f0 	movl   $0xf0105855,(%esp)
f01030f9:	e8 f0 02 00 00       	call   f01033ee <cprintf>
	return 0;
f01030fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0103103:	eb 0c                	jmp    f0103111 <env_alloc+0x127>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103105:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010310a:	eb 05                	jmp    f0103111 <env_alloc+0x127>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010310c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103111:	83 c4 14             	add    $0x14,%esp
f0103114:	5b                   	pop    %ebx
f0103115:	5d                   	pop    %ebp
f0103116:	c3                   	ret    

f0103117 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f0103117:	55                   	push   %ebp
f0103118:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.
}
f010311a:	5d                   	pop    %ebp
f010311b:	c3                   	ret    

f010311c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010311c:	55                   	push   %ebp
f010311d:	89 e5                	mov    %esp,%ebp
f010311f:	57                   	push   %edi
f0103120:	56                   	push   %esi
f0103121:	53                   	push   %ebx
f0103122:	83 ec 2c             	sub    $0x2c,%esp
f0103125:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103128:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f010312d:	39 c7                	cmp    %eax,%edi
f010312f:	75 37                	jne    f0103168 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f0103131:	8b 15 44 dd 17 f0    	mov    0xf017dd44,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103137:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010313d:	77 20                	ja     f010315f <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010313f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103143:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f010314a:	f0 
f010314b:	c7 44 24 04 68 01 00 	movl   $0x168,0x4(%esp)
f0103152:	00 
f0103153:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f010315a:	e8 35 cf ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010315f:	81 c2 00 00 00 10    	add    $0x10000000,%edx
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103165:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103168:	8b 4f 48             	mov    0x48(%edi),%ecx
f010316b:	ba 00 00 00 00       	mov    $0x0,%edx
f0103170:	85 c0                	test   %eax,%eax
f0103172:	74 03                	je     f0103177 <env_free+0x5b>
f0103174:	8b 50 48             	mov    0x48(%eax),%edx
f0103177:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010317b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010317f:	c7 04 24 6a 58 10 f0 	movl   $0xf010586a,(%esp)
f0103186:	e8 63 02 00 00       	call   f01033ee <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f010318b:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103192:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103195:	c1 e0 02             	shl    $0x2,%eax
f0103198:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010319b:	8b 47 5c             	mov    0x5c(%edi),%eax
f010319e:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01031a1:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01031a4:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01031aa:	0f 84 b8 00 00 00    	je     f0103268 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01031b0:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031b6:	89 f0                	mov    %esi,%eax
f01031b8:	c1 e8 0c             	shr    $0xc,%eax
f01031bb:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01031be:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f01031c4:	72 20                	jb     f01031e6 <env_free+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031c6:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01031ca:	c7 44 24 08 44 4d 10 	movl   $0xf0104d44,0x8(%esp)
f01031d1:	f0 
f01031d2:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f01031d9:	00 
f01031da:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f01031e1:	e8 ae ce ff ff       	call   f0100094 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031e6:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01031e9:	c1 e2 16             	shl    $0x16,%edx
f01031ec:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01031ef:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f01031f4:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f01031fb:	01 
f01031fc:	74 17                	je     f0103215 <env_free+0xf9>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01031fe:	89 d8                	mov    %ebx,%eax
f0103200:	c1 e0 0c             	shl    $0xc,%eax
f0103203:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103206:	89 44 24 04          	mov    %eax,0x4(%esp)
f010320a:	8b 47 5c             	mov    0x5c(%edi),%eax
f010320d:	89 04 24             	mov    %eax,(%esp)
f0103210:	e8 12 e0 ff ff       	call   f0101227 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103215:	83 c3 01             	add    $0x1,%ebx
f0103218:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010321e:	75 d4                	jne    f01031f4 <env_free+0xd8>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103220:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103223:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103226:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010322d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103230:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f0103236:	72 1c                	jb     f0103254 <env_free+0x138>
		panic("pa2page called with invalid pa");
f0103238:	c7 44 24 08 9c 4e 10 	movl   $0xf0104e9c,0x8(%esp)
f010323f:	f0 
f0103240:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103247:	00 
f0103248:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f010324f:	e8 40 ce ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0103254:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103257:	c1 e0 03             	shl    $0x3,%eax
f010325a:	03 05 48 dd 17 f0    	add    0xf017dd48,%eax
		page_decref(pa2page(pa));
f0103260:	89 04 24             	mov    %eax,(%esp)
f0103263:	e8 10 dd ff ff       	call   f0100f78 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103268:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010326c:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103273:	0f 85 19 ff ff ff    	jne    f0103192 <env_free+0x76>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103279:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010327c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103281:	77 20                	ja     f01032a3 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103283:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103287:	c7 44 24 08 50 4e 10 	movl   $0xf0104e50,0x8(%esp)
f010328e:	f0 
f010328f:	c7 44 24 04 85 01 00 	movl   $0x185,0x4(%esp)
f0103296:	00 
f0103297:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f010329e:	e8 f1 cd ff ff       	call   f0100094 <_panic>
	e->env_pgdir = 0;
f01032a3:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01032aa:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01032af:	c1 e8 0c             	shr    $0xc,%eax
f01032b2:	3b 05 40 dd 17 f0    	cmp    0xf017dd40,%eax
f01032b8:	72 1c                	jb     f01032d6 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f01032ba:	c7 44 24 08 9c 4e 10 	movl   $0xf0104e9c,0x8(%esp)
f01032c1:	f0 
f01032c2:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01032c9:	00 
f01032ca:	c7 04 24 02 55 10 f0 	movl   $0xf0105502,(%esp)
f01032d1:	e8 be cd ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01032d6:	c1 e0 03             	shl    $0x3,%eax
f01032d9:	03 05 48 dd 17 f0    	add    0xf017dd48,%eax
	page_decref(pa2page(pa));
f01032df:	89 04 24             	mov    %eax,(%esp)
f01032e2:	e8 91 dc ff ff       	call   f0100f78 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01032e7:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01032ee:	a1 ac d0 17 f0       	mov    0xf017d0ac,%eax
f01032f3:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01032f6:	89 3d ac d0 17 f0    	mov    %edi,0xf017d0ac
}
f01032fc:	83 c4 2c             	add    $0x2c,%esp
f01032ff:	5b                   	pop    %ebx
f0103300:	5e                   	pop    %esi
f0103301:	5f                   	pop    %edi
f0103302:	5d                   	pop    %ebp
f0103303:	c3                   	ret    

f0103304 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103304:	55                   	push   %ebp
f0103305:	89 e5                	mov    %esp,%ebp
f0103307:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f010330a:	8b 45 08             	mov    0x8(%ebp),%eax
f010330d:	89 04 24             	mov    %eax,(%esp)
f0103310:	e8 07 fe ff ff       	call   f010311c <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103315:	c7 04 24 14 58 10 f0 	movl   $0xf0105814,(%esp)
f010331c:	e8 cd 00 00 00       	call   f01033ee <cprintf>
	while (1)
		monitor(NULL);
f0103321:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103328:	e8 ab d4 ff ff       	call   f01007d8 <monitor>
f010332d:	eb f2                	jmp    f0103321 <env_destroy+0x1d>

f010332f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010332f:	55                   	push   %ebp
f0103330:	89 e5                	mov    %esp,%ebp
f0103332:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103335:	8b 65 08             	mov    0x8(%ebp),%esp
f0103338:	61                   	popa   
f0103339:	07                   	pop    %es
f010333a:	1f                   	pop    %ds
f010333b:	83 c4 08             	add    $0x8,%esp
f010333e:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010333f:	c7 44 24 08 80 58 10 	movl   $0xf0105880,0x8(%esp)
f0103346:	f0 
f0103347:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f010334e:	00 
f010334f:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f0103356:	e8 39 cd ff ff       	call   f0100094 <_panic>

f010335b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010335b:	55                   	push   %ebp
f010335c:	89 e5                	mov    %esp,%ebp
f010335e:	83 ec 18             	sub    $0x18,%esp
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	panic("env_run not yet implemented");
f0103361:	c7 44 24 08 8c 58 10 	movl   $0xf010588c,0x8(%esp)
f0103368:	f0 
f0103369:	c7 44 24 04 cc 01 00 	movl   $0x1cc,0x4(%esp)
f0103370:	00 
f0103371:	c7 04 24 4a 58 10 f0 	movl   $0xf010584a,(%esp)
f0103378:	e8 17 cd ff ff       	call   f0100094 <_panic>
f010337d:	00 00                	add    %al,(%eax)
	...

f0103380 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103380:	55                   	push   %ebp
f0103381:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103383:	ba 70 00 00 00       	mov    $0x70,%edx
f0103388:	8b 45 08             	mov    0x8(%ebp),%eax
f010338b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010338c:	b2 71                	mov    $0x71,%dl
f010338e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010338f:	0f b6 c0             	movzbl %al,%eax
}
f0103392:	5d                   	pop    %ebp
f0103393:	c3                   	ret    

f0103394 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103394:	55                   	push   %ebp
f0103395:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103397:	ba 70 00 00 00       	mov    $0x70,%edx
f010339c:	8b 45 08             	mov    0x8(%ebp),%eax
f010339f:	ee                   	out    %al,(%dx)
f01033a0:	b2 71                	mov    $0x71,%dl
f01033a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033a5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01033a6:	5d                   	pop    %ebp
f01033a7:	c3                   	ret    

f01033a8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01033a8:	55                   	push   %ebp
f01033a9:	89 e5                	mov    %esp,%ebp
f01033ab:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01033ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b1:	89 04 24             	mov    %eax,(%esp)
f01033b4:	e8 39 d2 ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f01033b9:	c9                   	leave  
f01033ba:	c3                   	ret    

f01033bb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01033bb:	55                   	push   %ebp
f01033bc:	89 e5                	mov    %esp,%ebp
f01033be:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01033c1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01033c8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033cb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01033d2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033d6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01033d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033dd:	c7 04 24 a8 33 10 f0 	movl   $0xf01033a8,(%esp)
f01033e4:	e8 71 08 00 00       	call   f0103c5a <vprintfmt>
	return cnt;
}
f01033e9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01033ec:	c9                   	leave  
f01033ed:	c3                   	ret    

f01033ee <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01033ee:	55                   	push   %ebp
f01033ef:	89 e5                	mov    %esp,%ebp
f01033f1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01033f4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01033f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01033fe:	89 04 24             	mov    %eax,(%esp)
f0103401:	e8 b5 ff ff ff       	call   f01033bb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103406:	c9                   	leave  
f0103407:	c3                   	ret    

f0103408 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103408:	55                   	push   %ebp
f0103409:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f010340b:	c7 05 c4 d8 17 f0 00 	movl   $0xefc00000,0xf017d8c4
f0103412:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f0103415:	66 c7 05 c8 d8 17 f0 	movw   $0x10,0xf017d8c8
f010341c:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010341e:	66 c7 05 48 b3 11 f0 	movw   $0x68,0xf011b348
f0103425:	68 00 
f0103427:	b8 c0 d8 17 f0       	mov    $0xf017d8c0,%eax
f010342c:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f0103432:	89 c2                	mov    %eax,%edx
f0103434:	c1 ea 10             	shr    $0x10,%edx
f0103437:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f010343d:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f0103444:	c1 e8 18             	shr    $0x18,%eax
f0103447:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f010344c:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f0103453:	b8 28 00 00 00       	mov    $0x28,%eax
f0103458:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f010345b:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f0103460:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103463:	5d                   	pop    %ebp
f0103464:	c3                   	ret    

f0103465 <trap_init>:
}


void
trap_init(void)
{
f0103465:	55                   	push   %ebp
f0103466:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f0103468:	e8 9b ff ff ff       	call   f0103408 <trap_init_percpu>
}
f010346d:	5d                   	pop    %ebp
f010346e:	c3                   	ret    

f010346f <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010346f:	55                   	push   %ebp
f0103470:	89 e5                	mov    %esp,%ebp
f0103472:	53                   	push   %ebx
f0103473:	83 ec 14             	sub    $0x14,%esp
f0103476:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103479:	8b 03                	mov    (%ebx),%eax
f010347b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010347f:	c7 04 24 a8 58 10 f0 	movl   $0xf01058a8,(%esp)
f0103486:	e8 63 ff ff ff       	call   f01033ee <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f010348b:	8b 43 04             	mov    0x4(%ebx),%eax
f010348e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103492:	c7 04 24 b7 58 10 f0 	movl   $0xf01058b7,(%esp)
f0103499:	e8 50 ff ff ff       	call   f01033ee <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f010349e:	8b 43 08             	mov    0x8(%ebx),%eax
f01034a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034a5:	c7 04 24 c6 58 10 f0 	movl   $0xf01058c6,(%esp)
f01034ac:	e8 3d ff ff ff       	call   f01033ee <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01034b1:	8b 43 0c             	mov    0xc(%ebx),%eax
f01034b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034b8:	c7 04 24 d5 58 10 f0 	movl   $0xf01058d5,(%esp)
f01034bf:	e8 2a ff ff ff       	call   f01033ee <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01034c4:	8b 43 10             	mov    0x10(%ebx),%eax
f01034c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034cb:	c7 04 24 e4 58 10 f0 	movl   $0xf01058e4,(%esp)
f01034d2:	e8 17 ff ff ff       	call   f01033ee <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01034d7:	8b 43 14             	mov    0x14(%ebx),%eax
f01034da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034de:	c7 04 24 f3 58 10 f0 	movl   $0xf01058f3,(%esp)
f01034e5:	e8 04 ff ff ff       	call   f01033ee <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01034ea:	8b 43 18             	mov    0x18(%ebx),%eax
f01034ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034f1:	c7 04 24 02 59 10 f0 	movl   $0xf0105902,(%esp)
f01034f8:	e8 f1 fe ff ff       	call   f01033ee <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01034fd:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0103500:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103504:	c7 04 24 11 59 10 f0 	movl   $0xf0105911,(%esp)
f010350b:	e8 de fe ff ff       	call   f01033ee <cprintf>
}
f0103510:	83 c4 14             	add    $0x14,%esp
f0103513:	5b                   	pop    %ebx
f0103514:	5d                   	pop    %ebp
f0103515:	c3                   	ret    

f0103516 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103516:	55                   	push   %ebp
f0103517:	89 e5                	mov    %esp,%ebp
f0103519:	56                   	push   %esi
f010351a:	53                   	push   %ebx
f010351b:	83 ec 10             	sub    $0x10,%esp
f010351e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f0103521:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103525:	c7 04 24 47 5a 10 f0 	movl   $0xf0105a47,(%esp)
f010352c:	e8 bd fe ff ff       	call   f01033ee <cprintf>
	print_regs(&tf->tf_regs);
f0103531:	89 1c 24             	mov    %ebx,(%esp)
f0103534:	e8 36 ff ff ff       	call   f010346f <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103539:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010353d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103541:	c7 04 24 62 59 10 f0 	movl   $0xf0105962,(%esp)
f0103548:	e8 a1 fe ff ff       	call   f01033ee <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010354d:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103551:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103555:	c7 04 24 75 59 10 f0 	movl   $0xf0105975,(%esp)
f010355c:	e8 8d fe ff ff       	call   f01033ee <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103561:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103564:	83 f8 13             	cmp    $0x13,%eax
f0103567:	77 09                	ja     f0103572 <print_trapframe+0x5c>
		return excnames[trapno];
f0103569:	8b 14 85 20 5c 10 f0 	mov    -0xfefa3e0(,%eax,4),%edx
f0103570:	eb 10                	jmp    f0103582 <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f0103572:	83 f8 30             	cmp    $0x30,%eax
f0103575:	ba 20 59 10 f0       	mov    $0xf0105920,%edx
f010357a:	b9 2c 59 10 f0       	mov    $0xf010592c,%ecx
f010357f:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103582:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103586:	89 44 24 04          	mov    %eax,0x4(%esp)
f010358a:	c7 04 24 88 59 10 f0 	movl   $0xf0105988,(%esp)
f0103591:	e8 58 fe ff ff       	call   f01033ee <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103596:	3b 1d 28 d9 17 f0    	cmp    0xf017d928,%ebx
f010359c:	75 19                	jne    f01035b7 <print_trapframe+0xa1>
f010359e:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01035a2:	75 13                	jne    f01035b7 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01035a4:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01035a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035ab:	c7 04 24 9a 59 10 f0 	movl   $0xf010599a,(%esp)
f01035b2:	e8 37 fe ff ff       	call   f01033ee <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f01035b7:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01035ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035be:	c7 04 24 a9 59 10 f0 	movl   $0xf01059a9,(%esp)
f01035c5:	e8 24 fe ff ff       	call   f01033ee <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01035ca:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01035ce:	75 51                	jne    f0103621 <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01035d0:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01035d3:	89 c2                	mov    %eax,%edx
f01035d5:	83 e2 01             	and    $0x1,%edx
f01035d8:	ba 3b 59 10 f0       	mov    $0xf010593b,%edx
f01035dd:	b9 46 59 10 f0       	mov    $0xf0105946,%ecx
f01035e2:	0f 45 ca             	cmovne %edx,%ecx
f01035e5:	89 c2                	mov    %eax,%edx
f01035e7:	83 e2 02             	and    $0x2,%edx
f01035ea:	ba 52 59 10 f0       	mov    $0xf0105952,%edx
f01035ef:	be 58 59 10 f0       	mov    $0xf0105958,%esi
f01035f4:	0f 44 d6             	cmove  %esi,%edx
f01035f7:	83 e0 04             	and    $0x4,%eax
f01035fa:	b8 5d 59 10 f0       	mov    $0xf010595d,%eax
f01035ff:	be 72 5a 10 f0       	mov    $0xf0105a72,%esi
f0103604:	0f 44 c6             	cmove  %esi,%eax
f0103607:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010360b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010360f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103613:	c7 04 24 b7 59 10 f0 	movl   $0xf01059b7,(%esp)
f010361a:	e8 cf fd ff ff       	call   f01033ee <cprintf>
f010361f:	eb 0c                	jmp    f010362d <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103621:	c7 04 24 df 57 10 f0 	movl   $0xf01057df,(%esp)
f0103628:	e8 c1 fd ff ff       	call   f01033ee <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010362d:	8b 43 30             	mov    0x30(%ebx),%eax
f0103630:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103634:	c7 04 24 c6 59 10 f0 	movl   $0xf01059c6,(%esp)
f010363b:	e8 ae fd ff ff       	call   f01033ee <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103640:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103644:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103648:	c7 04 24 d5 59 10 f0 	movl   $0xf01059d5,(%esp)
f010364f:	e8 9a fd ff ff       	call   f01033ee <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103654:	8b 43 38             	mov    0x38(%ebx),%eax
f0103657:	89 44 24 04          	mov    %eax,0x4(%esp)
f010365b:	c7 04 24 e8 59 10 f0 	movl   $0xf01059e8,(%esp)
f0103662:	e8 87 fd ff ff       	call   f01033ee <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103667:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010366b:	74 27                	je     f0103694 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010366d:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103670:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103674:	c7 04 24 f7 59 10 f0 	movl   $0xf01059f7,(%esp)
f010367b:	e8 6e fd ff ff       	call   f01033ee <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103680:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103684:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103688:	c7 04 24 06 5a 10 f0 	movl   $0xf0105a06,(%esp)
f010368f:	e8 5a fd ff ff       	call   f01033ee <cprintf>
	}
}
f0103694:	83 c4 10             	add    $0x10,%esp
f0103697:	5b                   	pop    %ebx
f0103698:	5e                   	pop    %esi
f0103699:	5d                   	pop    %ebp
f010369a:	c3                   	ret    

f010369b <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f010369b:	55                   	push   %ebp
f010369c:	89 e5                	mov    %esp,%ebp
f010369e:	57                   	push   %edi
f010369f:	56                   	push   %esi
f01036a0:	83 ec 10             	sub    $0x10,%esp
f01036a3:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f01036a6:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01036a7:	9c                   	pushf  
f01036a8:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01036a9:	f6 c4 02             	test   $0x2,%ah
f01036ac:	74 24                	je     f01036d2 <trap+0x37>
f01036ae:	c7 44 24 0c 19 5a 10 	movl   $0xf0105a19,0xc(%esp)
f01036b5:	f0 
f01036b6:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f01036bd:	f0 
f01036be:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
f01036c5:	00 
f01036c6:	c7 04 24 32 5a 10 f0 	movl   $0xf0105a32,(%esp)
f01036cd:	e8 c2 c9 ff ff       	call   f0100094 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f01036d2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01036d6:	c7 04 24 3e 5a 10 f0 	movl   $0xf0105a3e,(%esp)
f01036dd:	e8 0c fd ff ff       	call   f01033ee <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f01036e2:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01036e6:	83 e0 03             	and    $0x3,%eax
f01036e9:	83 f8 03             	cmp    $0x3,%eax
f01036ec:	75 3c                	jne    f010372a <trap+0x8f>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f01036ee:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f01036f3:	85 c0                	test   %eax,%eax
f01036f5:	75 24                	jne    f010371b <trap+0x80>
f01036f7:	c7 44 24 0c 59 5a 10 	movl   $0xf0105a59,0xc(%esp)
f01036fe:	f0 
f01036ff:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0103706:	f0 
f0103707:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
f010370e:	00 
f010370f:	c7 04 24 32 5a 10 f0 	movl   $0xf0105a32,(%esp)
f0103716:	e8 79 c9 ff ff       	call   f0100094 <_panic>
		curenv->env_tf = *tf;
f010371b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103720:	89 c7                	mov    %eax,%edi
f0103722:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103724:	8b 35 a4 d0 17 f0    	mov    0xf017d0a4,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010372a:	89 35 28 d9 17 f0    	mov    %esi,0xf017d928
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103730:	89 34 24             	mov    %esi,(%esp)
f0103733:	e8 de fd ff ff       	call   f0103516 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103738:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f010373d:	75 1c                	jne    f010375b <trap+0xc0>
		panic("unhandled trap in kernel");
f010373f:	c7 44 24 08 60 5a 10 	movl   $0xf0105a60,0x8(%esp)
f0103746:	f0 
f0103747:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f010374e:	00 
f010374f:	c7 04 24 32 5a 10 f0 	movl   $0xf0105a32,(%esp)
f0103756:	e8 39 c9 ff ff       	call   f0100094 <_panic>
	else {
		env_destroy(curenv);
f010375b:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f0103760:	89 04 24             	mov    %eax,(%esp)
f0103763:	e8 9c fb ff ff       	call   f0103304 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103768:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f010376d:	85 c0                	test   %eax,%eax
f010376f:	74 06                	je     f0103777 <trap+0xdc>
f0103771:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103775:	74 24                	je     f010379b <trap+0x100>
f0103777:	c7 44 24 0c bc 5b 10 	movl   $0xf0105bbc,0xc(%esp)
f010377e:	f0 
f010377f:	c7 44 24 08 ed 54 10 	movl   $0xf01054ed,0x8(%esp)
f0103786:	f0 
f0103787:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f010378e:	00 
f010378f:	c7 04 24 32 5a 10 f0 	movl   $0xf0105a32,(%esp)
f0103796:	e8 f9 c8 ff ff       	call   f0100094 <_panic>
	env_run(curenv);
f010379b:	89 04 24             	mov    %eax,(%esp)
f010379e:	e8 b8 fb ff ff       	call   f010335b <env_run>

f01037a3 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01037a3:	55                   	push   %ebp
f01037a4:	89 e5                	mov    %esp,%ebp
f01037a6:	53                   	push   %ebx
f01037a7:	83 ec 14             	sub    $0x14,%esp
f01037aa:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01037ad:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01037b0:	8b 53 30             	mov    0x30(%ebx),%edx
f01037b3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01037b7:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01037bb:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01037c0:	8b 40 48             	mov    0x48(%eax),%eax
f01037c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037c7:	c7 04 24 e8 5b 10 f0 	movl   $0xf0105be8,(%esp)
f01037ce:	e8 1b fc ff ff       	call   f01033ee <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01037d3:	89 1c 24             	mov    %ebx,(%esp)
f01037d6:	e8 3b fd ff ff       	call   f0103516 <print_trapframe>
	env_destroy(curenv);
f01037db:	a1 a4 d0 17 f0       	mov    0xf017d0a4,%eax
f01037e0:	89 04 24             	mov    %eax,(%esp)
f01037e3:	e8 1c fb ff ff       	call   f0103304 <env_destroy>
}
f01037e8:	83 c4 14             	add    $0x14,%esp
f01037eb:	5b                   	pop    %ebx
f01037ec:	5d                   	pop    %ebp
f01037ed:	c3                   	ret    
	...

f01037f0 <syscall>:
f01037f0:	55                   	push   %ebp
f01037f1:	89 e5                	mov    %esp,%ebp
f01037f3:	83 ec 18             	sub    $0x18,%esp
f01037f6:	c7 44 24 08 70 5c 10 	movl   $0xf0105c70,0x8(%esp)
f01037fd:	f0 
f01037fe:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103805:	00 
f0103806:	c7 04 24 88 5c 10 f0 	movl   $0xf0105c88,(%esp)
f010380d:	e8 82 c8 ff ff       	call   f0100094 <_panic>
	...

f0103814 <stab_binsearch>:
//		13     SO     f0100040
//		117    SO     f0100176
//		118    SO     f0100178
//		555    SO     f0100652
//		556    SO     f0100654
//		657    SO     f0100849
f0103814:	55                   	push   %ebp
f0103815:	89 e5                	mov    %esp,%ebp
f0103817:	57                   	push   %edi
f0103818:	56                   	push   %esi
f0103819:	53                   	push   %ebx
f010381a:	83 ec 10             	sub    $0x10,%esp
f010381d:	89 c3                	mov    %eax,%ebx
f010381f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103822:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103825:	8b 75 08             	mov    0x8(%ebp),%esi
//	this code:
f0103828:	8b 0a                	mov    (%edx),%ecx
f010382a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010382d:	8b 00                	mov    (%eax),%eax
f010382f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103832:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
f0103839:	eb 77                	jmp    f01038b2 <stab_binsearch+0x9e>
//	will exit setting left = 118, right = 554.
f010383b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010383e:	01 c8                	add    %ecx,%eax
f0103840:	bf 02 00 00 00       	mov    $0x2,%edi
f0103845:	99                   	cltd   
f0103846:	f7 ff                	idiv   %edi
f0103848:	89 c2                	mov    %eax,%edx
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010384a:	eb 01                	jmp    f010384d <stab_binsearch+0x39>
	       int type, uintptr_t addr)
f010384c:	4a                   	dec    %edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010384d:	39 ca                	cmp    %ecx,%edx
f010384f:	7c 1d                	jl     f010386e <stab_binsearch+0x5a>
//		Index  Type   Address
//		0      SO     f0100000
//		13     SO     f0100040
//		117    SO     f0100176
//		118    SO     f0100178
//		555    SO     f0100652
f0103851:	6b fa 0c             	imul   $0xc,%edx,%edi
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103854:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0103859:	39 f7                	cmp    %esi,%edi
f010385b:	75 ef                	jne    f010384c <stab_binsearch+0x38>
f010385d:	89 55 ec             	mov    %edx,-0x14(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103860:	6b fa 0c             	imul   $0xc,%edx,%edi
f0103863:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0103867:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010386a:	73 18                	jae    f0103884 <stab_binsearch+0x70>
f010386c:	eb 05                	jmp    f0103873 <stab_binsearch+0x5f>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f010386e:	8d 48 01             	lea    0x1(%eax),%ecx
	
f0103871:	eb 3f                	jmp    f01038b2 <stab_binsearch+0x9e>
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103873:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103876:	89 11                	mov    %edx,(%ecx)
		if (m < l) {	// no match in [l, m]
f0103878:	8d 48 01             	lea    0x1(%eax),%ecx
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
f010387b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103882:	eb 2e                	jmp    f01038b2 <stab_binsearch+0x9e>
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103884:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0103887:	76 15                	jbe    f010389e <stab_binsearch+0x8a>
			continue;
f0103889:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010388c:	4f                   	dec    %edi
f010388d:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0103890:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103893:	89 38                	mov    %edi,(%eax)
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
f0103895:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010389c:	eb 14                	jmp    f01038b2 <stab_binsearch+0x9e>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010389e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01038a1:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01038a4:	89 39                	mov    %edi,(%ecx)
			*region_left = m;
			l = true_m + 1;
f01038a6:	ff 45 0c             	incl   0xc(%ebp)
f01038a9:	89 d1                	mov    %edx,%ecx
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
f01038ab:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
//		555    SO     f0100652
//		556    SO     f0100654
//		657    SO     f0100849
//	this code:
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
f01038b2:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01038b5:	7e 84                	jle    f010383b <stab_binsearch+0x27>
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
			*region_right = m - 1;
			r = m - 1;
		} else {
f01038b7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01038bb:	75 0d                	jne    f01038ca <stab_binsearch+0xb6>
			// exact match for 'addr', but continue loop to find
f01038bd:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01038c0:	8b 02                	mov    (%edx),%eax
f01038c2:	48                   	dec    %eax
f01038c3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01038c6:	89 01                	mov    %eax,(%ecx)
f01038c8:	eb 22                	jmp    f01038ec <stab_binsearch+0xd8>
			// *region_right
			*region_left = m;
			l = m;
f01038ca:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01038cd:	8b 01                	mov    (%ecx),%eax
			addr++;
f01038cf:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01038d2:	8b 0a                	mov    (%edx),%ecx
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
			l = m;
f01038d4:	eb 01                	jmp    f01038d7 <stab_binsearch+0xc3>
			addr++;
		}
f01038d6:	48                   	dec    %eax
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
			l = m;
f01038d7:	39 c1                	cmp    %eax,%ecx
f01038d9:	7d 0c                	jge    f01038e7 <stab_binsearch+0xd3>
//		Index  Type   Address
//		0      SO     f0100000
//		13     SO     f0100040
//		117    SO     f0100176
//		118    SO     f0100178
//		555    SO     f0100652
f01038db:	6b d0 0c             	imul   $0xc,%eax,%edx
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
			l = m;
			addr++;
f01038de:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f01038e3:	39 f2                	cmp    %esi,%edx
f01038e5:	75 ef                	jne    f01038d6 <stab_binsearch+0xc2>
		}
	}

f01038e7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01038ea:	89 02                	mov    %eax,(%edx)
	if (!any_matches)
		*region_right = *region_left - 1;
f01038ec:	83 c4 10             	add    $0x10,%esp
f01038ef:	5b                   	pop    %ebx
f01038f0:	5e                   	pop    %esi
f01038f1:	5f                   	pop    %edi
f01038f2:	5d                   	pop    %ebp
f01038f3:	c3                   	ret    

f01038f4 <debuginfo_eip>:
		*region_left = l;
	}
}


// debuginfo_eip(addr, info)
f01038f4:	55                   	push   %ebp
f01038f5:	89 e5                	mov    %esp,%ebp
f01038f7:	83 ec 38             	sub    $0x38,%esp
f01038fa:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01038fd:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103900:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103903:	8b 75 08             	mov    0x8(%ebp),%esi
f0103906:	8b 5d 0c             	mov    0xc(%ebp),%ebx
//
//	Fill in the 'info' structure with information about the specified
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
f0103909:	c7 03 97 5c 10 f0    	movl   $0xf0105c97,(%ebx)
int
f010390f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103916:	c7 43 08 97 5c 10 f0 	movl   $0xf0105c97,0x8(%ebx)
{
f010391d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	const struct Stab *stabs, *stab_end;
f0103924:	89 73 10             	mov    %esi,0x10(%ebx)
	const char *stabstr, *stabstr_end;
f0103927:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
f010392e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103934:	76 12                	jbe    f0103948 <debuginfo_eip+0x54>
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103936:	b8 8c 04 11 f0       	mov    $0xf011048c,%eax
f010393b:	3d e9 d5 10 f0       	cmp    $0xf010d5e9,%eax
f0103940:	0f 86 9b 01 00 00    	jbe    f0103ae1 <debuginfo_eip+0x1ed>
f0103946:	eb 1c                	jmp    f0103964 <debuginfo_eip+0x70>
	info->eip_line = 0;
	info->eip_fn_name = "<unknown>";
	info->eip_fn_namelen = 9;
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

f0103948:	c7 44 24 08 a1 5c 10 	movl   $0xf0105ca1,0x8(%esp)
f010394f:	f0 
f0103950:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0103957:	00 
f0103958:	c7 04 24 ae 5c 10 f0 	movl   $0xf0105cae,(%esp)
f010395f:	e8 30 c7 ff ff       	call   f0100094 <_panic>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103964:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103969:	80 3d 8b 04 11 f0 00 	cmpb   $0x0,0xf011048b
f0103970:	0f 85 77 01 00 00    	jne    f0103aed <debuginfo_eip+0x1f9>
		// The user-application linker script, user/user.ld,
		// puts information about the application's stabs (equivalent
		// to __STAB_BEGIN__, __STAB_END__, __STABSTR_BEGIN__, and
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;
f0103976:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)

f010397d:	b8 e8 d5 10 f0       	mov    $0xf010d5e8,%eax
f0103982:	2d cc 5e 10 f0       	sub    $0xf0105ecc,%eax
f0103987:	c1 f8 02             	sar    $0x2,%eax
f010398a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103990:	83 e8 01             	sub    $0x1,%eax
f0103993:	89 45 e0             	mov    %eax,-0x20(%ebp)
		// Make sure this memory is valid.
f0103996:	89 74 24 04          	mov    %esi,0x4(%esp)
f010399a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01039a1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01039a4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01039a7:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f01039ac:	e8 63 fe ff ff       	call   f0103814 <stab_binsearch>
		// Return -1 if it is not.  Hint: Call user_mem_check.
f01039b1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		// LAB 3: Your code here.
f01039b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// __STABSTR_END__) in a structure located at virtual address
		// USTABDATA.
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
f01039b9:	85 d2                	test   %edx,%edx
f01039bb:	0f 84 2c 01 00 00    	je     f0103aed <debuginfo_eip+0x1f9>
		// LAB 3: Your code here.

		stabs = usd->stabs;
		stab_end = usd->stab_end;
		stabstr = usd->stabstr;
f01039c1:	89 55 dc             	mov    %edx,-0x24(%ebp)
		stabstr_end = usd->stabstr_end;
f01039c4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039c7:	89 45 d8             	mov    %eax,-0x28(%ebp)

f01039ca:	89 74 24 04          	mov    %esi,0x4(%esp)
f01039ce:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01039d5:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01039d8:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01039db:	b8 cc 5e 10 f0       	mov    $0xf0105ecc,%eax
f01039e0:	e8 2f fe ff ff       	call   f0103814 <stab_binsearch>
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
f01039e5:	8b 7d dc             	mov    -0x24(%ebp),%edi
f01039e8:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f01039eb:	7f 2e                	jg     f0103a1b <debuginfo_eip+0x127>
	}

	// String table validity checks
f01039ed:	6b c7 0c             	imul   $0xc,%edi,%eax
f01039f0:	8d 90 cc 5e 10 f0    	lea    -0xfefa134(%eax),%edx
f01039f6:	8b 80 cc 5e 10 f0    	mov    -0xfefa134(%eax),%eax
f01039fc:	b9 8c 04 11 f0       	mov    $0xf011048c,%ecx
f0103a01:	81 e9 e9 d5 10 f0    	sub    $0xf010d5e9,%ecx
f0103a07:	39 c8                	cmp    %ecx,%eax
f0103a09:	73 08                	jae    f0103a13 <debuginfo_eip+0x11f>
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103a0b:	05 e9 d5 10 f0       	add    $0xf010d5e9,%eax
f0103a10:	89 43 08             	mov    %eax,0x8(%ebx)
		return -1;
f0103a13:	8b 42 08             	mov    0x8(%edx),%eax
f0103a16:	89 43 10             	mov    %eax,0x10(%ebx)
f0103a19:	eb 06                	jmp    f0103a21 <debuginfo_eip+0x12d>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103a1b:	89 73 10             	mov    %esi,0x10(%ebx)
	rfile = (stab_end - stabs) - 1;
f0103a1e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;

f0103a21:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103a28:	00 
f0103a29:	8b 43 08             	mov    0x8(%ebx),%eax
f0103a2c:	89 04 24             	mov    %eax,(%esp)
f0103a2f:	e8 db 08 00 00       	call   f010430f <strfind>
f0103a34:	2b 43 08             	sub    0x8(%ebx),%eax
f0103a37:	89 43 0c             	mov    %eax,0xc(%ebx)
		// Search within the function definition for the line number.
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
f0103a3a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103a3d:	39 d7                	cmp    %edx,%edi
f0103a3f:	7c 5f                	jl     f0103aa0 <debuginfo_eip+0x1ac>
		info->eip_fn_addr = addr;
f0103a41:	89 f8                	mov    %edi,%eax
f0103a43:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0103a46:	80 b9 d0 5e 10 f0 84 	cmpb   $0x84,-0xfefa130(%ecx)
f0103a4d:	75 18                	jne    f0103a67 <debuginfo_eip+0x173>
f0103a4f:	eb 30                	jmp    f0103a81 <debuginfo_eip+0x18d>
		lline = lfile;
		rline = rfile;
f0103a51:	83 ef 01             	sub    $0x1,%edi
		// Search within the function definition for the line number.
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
f0103a54:	39 fa                	cmp    %edi,%edx
f0103a56:	7f 48                	jg     f0103aa0 <debuginfo_eip+0x1ac>
		info->eip_fn_addr = addr;
f0103a58:	89 f8                	mov    %edi,%eax
f0103a5a:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0103a5d:	80 3c 8d d0 5e 10 f0 	cmpb   $0x84,-0xfefa130(,%ecx,4)
f0103a64:	84 
f0103a65:	74 1a                	je     f0103a81 <debuginfo_eip+0x18d>
		lline = lfile;
f0103a67:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103a6a:	8d 04 85 cc 5e 10 f0 	lea    -0xfefa134(,%eax,4),%eax
f0103a71:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0103a75:	75 da                	jne    f0103a51 <debuginfo_eip+0x15d>
f0103a77:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0103a7b:	74 d4                	je     f0103a51 <debuginfo_eip+0x15d>
		rline = rfile;
	}
f0103a7d:	39 fa                	cmp    %edi,%edx
f0103a7f:	7f 1f                	jg     f0103aa0 <debuginfo_eip+0x1ac>
f0103a81:	6b ff 0c             	imul   $0xc,%edi,%edi
f0103a84:	8b 87 cc 5e 10 f0    	mov    -0xfefa134(%edi),%eax
f0103a8a:	ba 8c 04 11 f0       	mov    $0xf011048c,%edx
f0103a8f:	81 ea e9 d5 10 f0    	sub    $0xf010d5e9,%edx
f0103a95:	39 d0                	cmp    %edx,%eax
f0103a97:	73 07                	jae    f0103aa0 <debuginfo_eip+0x1ac>
	// Ignore stuff after the colon.
f0103a99:	05 e9 d5 10 f0       	add    $0xf010d5e9,%eax
f0103a9e:	89 03                	mov    %eax,(%ebx)
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;

	
	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
f0103aa0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103aa3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
	// If not found, return -1.
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
f0103aa6:	b8 00 00 00 00       	mov    $0x0,%eax
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;

	
	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
f0103aab:	39 ca                	cmp    %ecx,%edx
f0103aad:	7d 3e                	jge    f0103aed <debuginfo_eip+0x1f9>
	// If not found, return -1.
f0103aaf:	83 c2 01             	add    $0x1,%edx
f0103ab2:	39 d1                	cmp    %edx,%ecx
f0103ab4:	7e 37                	jle    f0103aed <debuginfo_eip+0x1f9>
	//
f0103ab6:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103ab9:	80 be d0 5e 10 f0 a0 	cmpb   $0xa0,-0xfefa130(%esi)
f0103ac0:	75 2b                	jne    f0103aed <debuginfo_eip+0x1f9>
	// Hint:
	//	There's a particular stabs type used for line numbers.
f0103ac2:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	
	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
	// If not found, return -1.
	//
	// Hint:
f0103ac6:	83 c2 01             	add    $0x1,%edx
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;

	
	// Search within [lline, rline] for the line number stab.
	// If found, set info->eip_line to the right line number.
	// If not found, return -1.
f0103ac9:	39 d1                	cmp    %edx,%ecx
f0103acb:	7e 1b                	jle    f0103ae8 <debuginfo_eip+0x1f4>
	//
f0103acd:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103ad0:	80 3c 85 d0 5e 10 f0 	cmpb   $0xa0,-0xfefa130(,%eax,4)
f0103ad7:	a0 
f0103ad8:	74 e8                	je     f0103ac2 <debuginfo_eip+0x1ce>
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
f0103ada:	b8 00 00 00 00       	mov    $0x0,%eax
f0103adf:	eb 0c                	jmp    f0103aed <debuginfo_eip+0x1f9>

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103ae1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103ae6:	eb 05                	jmp    f0103aed <debuginfo_eip+0x1f9>
	// If not found, return -1.
	//
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
f0103ae8:	b8 00 00 00 00       	mov    $0x0,%eax
	// Your code here.
f0103aed:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103af0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103af3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103af6:	89 ec                	mov    %ebp,%esp
f0103af8:	5d                   	pop    %ebp
f0103af9:	c3                   	ret    
f0103afa:	00 00                	add    %al,(%eax)
f0103afc:	00 00                	add    %al,(%eax)
	...

f0103b00 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103b00:	55                   	push   %ebp
f0103b01:	89 e5                	mov    %esp,%ebp
f0103b03:	57                   	push   %edi
f0103b04:	56                   	push   %esi
f0103b05:	53                   	push   %ebx
f0103b06:	83 ec 3c             	sub    $0x3c,%esp
f0103b09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103b0c:	89 d7                	mov    %edx,%edi
f0103b0e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b11:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103b14:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b17:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103b1a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103b1d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103b20:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b25:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103b28:	72 11                	jb     f0103b3b <printnum+0x3b>
f0103b2a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b2d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103b30:	76 09                	jbe    f0103b3b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b32:	83 eb 01             	sub    $0x1,%ebx
f0103b35:	85 db                	test   %ebx,%ebx
f0103b37:	7f 51                	jg     f0103b8a <printnum+0x8a>
f0103b39:	eb 5e                	jmp    f0103b99 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103b3b:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103b3f:	83 eb 01             	sub    $0x1,%ebx
f0103b42:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103b46:	8b 45 10             	mov    0x10(%ebp),%eax
f0103b49:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b4d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103b51:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103b55:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103b5c:	00 
f0103b5d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103b60:	89 04 24             	mov    %eax,(%esp)
f0103b63:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103b66:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b6a:	e8 21 0a 00 00       	call   f0104590 <__udivdi3>
f0103b6f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103b73:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103b77:	89 04 24             	mov    %eax,(%esp)
f0103b7a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103b7e:	89 fa                	mov    %edi,%edx
f0103b80:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b83:	e8 78 ff ff ff       	call   f0103b00 <printnum>
f0103b88:	eb 0f                	jmp    f0103b99 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103b8a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b8e:	89 34 24             	mov    %esi,(%esp)
f0103b91:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103b94:	83 eb 01             	sub    $0x1,%ebx
f0103b97:	75 f1                	jne    f0103b8a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103b99:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103b9d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103ba1:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ba4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ba8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103baf:	00 
f0103bb0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103bb3:	89 04 24             	mov    %eax,(%esp)
f0103bb6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103bb9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbd:	e8 fe 0a 00 00       	call   f01046c0 <__umoddi3>
f0103bc2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103bc6:	0f be 80 bc 5c 10 f0 	movsbl -0xfefa344(%eax),%eax
f0103bcd:	89 04 24             	mov    %eax,(%esp)
f0103bd0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103bd3:	83 c4 3c             	add    $0x3c,%esp
f0103bd6:	5b                   	pop    %ebx
f0103bd7:	5e                   	pop    %esi
f0103bd8:	5f                   	pop    %edi
f0103bd9:	5d                   	pop    %ebp
f0103bda:	c3                   	ret    

f0103bdb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103bdb:	55                   	push   %ebp
f0103bdc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103bde:	83 fa 01             	cmp    $0x1,%edx
f0103be1:	7e 0e                	jle    f0103bf1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103be3:	8b 10                	mov    (%eax),%edx
f0103be5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103be8:	89 08                	mov    %ecx,(%eax)
f0103bea:	8b 02                	mov    (%edx),%eax
f0103bec:	8b 52 04             	mov    0x4(%edx),%edx
f0103bef:	eb 22                	jmp    f0103c13 <getuint+0x38>
	else if (lflag)
f0103bf1:	85 d2                	test   %edx,%edx
f0103bf3:	74 10                	je     f0103c05 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103bf5:	8b 10                	mov    (%eax),%edx
f0103bf7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103bfa:	89 08                	mov    %ecx,(%eax)
f0103bfc:	8b 02                	mov    (%edx),%eax
f0103bfe:	ba 00 00 00 00       	mov    $0x0,%edx
f0103c03:	eb 0e                	jmp    f0103c13 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103c05:	8b 10                	mov    (%eax),%edx
f0103c07:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103c0a:	89 08                	mov    %ecx,(%eax)
f0103c0c:	8b 02                	mov    (%edx),%eax
f0103c0e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103c13:	5d                   	pop    %ebp
f0103c14:	c3                   	ret    

f0103c15 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103c15:	55                   	push   %ebp
f0103c16:	89 e5                	mov    %esp,%ebp
f0103c18:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103c1b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103c1f:	8b 10                	mov    (%eax),%edx
f0103c21:	3b 50 04             	cmp    0x4(%eax),%edx
f0103c24:	73 0a                	jae    f0103c30 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103c26:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103c29:	88 0a                	mov    %cl,(%edx)
f0103c2b:	83 c2 01             	add    $0x1,%edx
f0103c2e:	89 10                	mov    %edx,(%eax)
}
f0103c30:	5d                   	pop    %ebp
f0103c31:	c3                   	ret    

f0103c32 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103c32:	55                   	push   %ebp
f0103c33:	89 e5                	mov    %esp,%ebp
f0103c35:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103c38:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103c3b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c3f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c42:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c46:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c49:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c4d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c50:	89 04 24             	mov    %eax,(%esp)
f0103c53:	e8 02 00 00 00       	call   f0103c5a <vprintfmt>
	va_end(ap);
}
f0103c58:	c9                   	leave  
f0103c59:	c3                   	ret    

f0103c5a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103c5a:	55                   	push   %ebp
f0103c5b:	89 e5                	mov    %esp,%ebp
f0103c5d:	57                   	push   %edi
f0103c5e:	56                   	push   %esi
f0103c5f:	53                   	push   %ebx
f0103c60:	83 ec 4c             	sub    $0x4c,%esp
f0103c63:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103c66:	8b 75 10             	mov    0x10(%ebp),%esi
f0103c69:	eb 12                	jmp    f0103c7d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103c6b:	85 c0                	test   %eax,%eax
f0103c6d:	0f 84 a9 03 00 00    	je     f010401c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103c73:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c77:	89 04 24             	mov    %eax,(%esp)
f0103c7a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103c7d:	0f b6 06             	movzbl (%esi),%eax
f0103c80:	83 c6 01             	add    $0x1,%esi
f0103c83:	83 f8 25             	cmp    $0x25,%eax
f0103c86:	75 e3                	jne    f0103c6b <vprintfmt+0x11>
f0103c88:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103c8c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103c93:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103c98:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103c9f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103ca4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103ca7:	eb 2b                	jmp    f0103cd4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ca9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103cac:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103cb0:	eb 22                	jmp    f0103cd4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cb2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103cb5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103cb9:	eb 19                	jmp    f0103cd4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cbb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103cbe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103cc5:	eb 0d                	jmp    f0103cd4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103cc7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103cca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ccd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cd4:	0f b6 06             	movzbl (%esi),%eax
f0103cd7:	0f b6 d0             	movzbl %al,%edx
f0103cda:	8d 7e 01             	lea    0x1(%esi),%edi
f0103cdd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103ce0:	83 e8 23             	sub    $0x23,%eax
f0103ce3:	3c 55                	cmp    $0x55,%al
f0103ce5:	0f 87 0b 03 00 00    	ja     f0103ff6 <vprintfmt+0x39c>
f0103ceb:	0f b6 c0             	movzbl %al,%eax
f0103cee:	ff 24 85 48 5d 10 f0 	jmp    *-0xfefa2b8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103cf5:	83 ea 30             	sub    $0x30,%edx
f0103cf8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0103cfb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103cff:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d02:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103d05:	83 fa 09             	cmp    $0x9,%edx
f0103d08:	77 4a                	ja     f0103d54 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d0a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103d0d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103d10:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103d13:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103d17:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103d1a:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103d1d:	83 fa 09             	cmp    $0x9,%edx
f0103d20:	76 eb                	jbe    f0103d0d <vprintfmt+0xb3>
f0103d22:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103d25:	eb 2d                	jmp    f0103d54 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103d27:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d2a:	8d 50 04             	lea    0x4(%eax),%edx
f0103d2d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d30:	8b 00                	mov    (%eax),%eax
f0103d32:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d35:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103d38:	eb 1a                	jmp    f0103d54 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d3a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103d3d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d41:	79 91                	jns    f0103cd4 <vprintfmt+0x7a>
f0103d43:	e9 73 ff ff ff       	jmp    f0103cbb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d48:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103d4b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103d52:	eb 80                	jmp    f0103cd4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103d54:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103d58:	0f 89 76 ff ff ff    	jns    f0103cd4 <vprintfmt+0x7a>
f0103d5e:	e9 64 ff ff ff       	jmp    f0103cc7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103d63:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d66:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103d69:	e9 66 ff ff ff       	jmp    f0103cd4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103d6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d71:	8d 50 04             	lea    0x4(%eax),%edx
f0103d74:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d77:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d7b:	8b 00                	mov    (%eax),%eax
f0103d7d:	89 04 24             	mov    %eax,(%esp)
f0103d80:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103d83:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103d86:	e9 f2 fe ff ff       	jmp    f0103c7d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103d8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d8e:	8d 50 04             	lea    0x4(%eax),%edx
f0103d91:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d94:	8b 00                	mov    (%eax),%eax
f0103d96:	89 c2                	mov    %eax,%edx
f0103d98:	c1 fa 1f             	sar    $0x1f,%edx
f0103d9b:	31 d0                	xor    %edx,%eax
f0103d9d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103d9f:	83 f8 06             	cmp    $0x6,%eax
f0103da2:	7f 0b                	jg     f0103daf <vprintfmt+0x155>
f0103da4:	8b 14 85 a0 5e 10 f0 	mov    -0xfefa160(,%eax,4),%edx
f0103dab:	85 d2                	test   %edx,%edx
f0103dad:	75 23                	jne    f0103dd2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0103daf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103db3:	c7 44 24 08 d4 5c 10 	movl   $0xf0105cd4,0x8(%esp)
f0103dba:	f0 
f0103dbb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dbf:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103dc2:	89 3c 24             	mov    %edi,(%esp)
f0103dc5:	e8 68 fe ff ff       	call   f0103c32 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dca:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103dcd:	e9 ab fe ff ff       	jmp    f0103c7d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103dd2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103dd6:	c7 44 24 08 ff 54 10 	movl   $0xf01054ff,0x8(%esp)
f0103ddd:	f0 
f0103dde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103de2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103de5:	89 3c 24             	mov    %edi,(%esp)
f0103de8:	e8 45 fe ff ff       	call   f0103c32 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ded:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103df0:	e9 88 fe ff ff       	jmp    f0103c7d <vprintfmt+0x23>
f0103df5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103df8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103dfb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103dfe:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e01:	8d 50 04             	lea    0x4(%eax),%edx
f0103e04:	89 55 14             	mov    %edx,0x14(%ebp)
f0103e07:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103e09:	85 f6                	test   %esi,%esi
f0103e0b:	ba cd 5c 10 f0       	mov    $0xf0105ccd,%edx
f0103e10:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103e13:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103e17:	7e 06                	jle    f0103e1f <vprintfmt+0x1c5>
f0103e19:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103e1d:	75 10                	jne    f0103e2f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e1f:	0f be 06             	movsbl (%esi),%eax
f0103e22:	83 c6 01             	add    $0x1,%esi
f0103e25:	85 c0                	test   %eax,%eax
f0103e27:	0f 85 86 00 00 00    	jne    f0103eb3 <vprintfmt+0x259>
f0103e2d:	eb 76                	jmp    f0103ea5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e2f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103e33:	89 34 24             	mov    %esi,(%esp)
f0103e36:	e8 60 03 00 00       	call   f010419b <strnlen>
f0103e3b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103e3e:	29 c2                	sub    %eax,%edx
f0103e40:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103e43:	85 d2                	test   %edx,%edx
f0103e45:	7e d8                	jle    f0103e1f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103e47:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103e4b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103e4e:	89 d6                	mov    %edx,%esi
f0103e50:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103e53:	89 c7                	mov    %eax,%edi
f0103e55:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e59:	89 3c 24             	mov    %edi,(%esp)
f0103e5c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103e5f:	83 ee 01             	sub    $0x1,%esi
f0103e62:	75 f1                	jne    f0103e55 <vprintfmt+0x1fb>
f0103e64:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103e67:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103e6a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0103e6d:	eb b0                	jmp    f0103e1f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103e6f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103e73:	74 18                	je     f0103e8d <vprintfmt+0x233>
f0103e75:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103e78:	83 fa 5e             	cmp    $0x5e,%edx
f0103e7b:	76 10                	jbe    f0103e8d <vprintfmt+0x233>
					putch('?', putdat);
f0103e7d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e81:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103e88:	ff 55 08             	call   *0x8(%ebp)
f0103e8b:	eb 0a                	jmp    f0103e97 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0103e8d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103e91:	89 04 24             	mov    %eax,(%esp)
f0103e94:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103e97:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103e9b:	0f be 06             	movsbl (%esi),%eax
f0103e9e:	83 c6 01             	add    $0x1,%esi
f0103ea1:	85 c0                	test   %eax,%eax
f0103ea3:	75 0e                	jne    f0103eb3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ea5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ea8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103eac:	7f 16                	jg     f0103ec4 <vprintfmt+0x26a>
f0103eae:	e9 ca fd ff ff       	jmp    f0103c7d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103eb3:	85 ff                	test   %edi,%edi
f0103eb5:	78 b8                	js     f0103e6f <vprintfmt+0x215>
f0103eb7:	83 ef 01             	sub    $0x1,%edi
f0103eba:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ec0:	79 ad                	jns    f0103e6f <vprintfmt+0x215>
f0103ec2:	eb e1                	jmp    f0103ea5 <vprintfmt+0x24b>
f0103ec4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103ec7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103eca:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ece:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103ed5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ed7:	83 ee 01             	sub    $0x1,%esi
f0103eda:	75 ee                	jne    f0103eca <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103edc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103edf:	e9 99 fd ff ff       	jmp    f0103c7d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103ee4:	83 f9 01             	cmp    $0x1,%ecx
f0103ee7:	7e 10                	jle    f0103ef9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103ee9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103eec:	8d 50 08             	lea    0x8(%eax),%edx
f0103eef:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ef2:	8b 30                	mov    (%eax),%esi
f0103ef4:	8b 78 04             	mov    0x4(%eax),%edi
f0103ef7:	eb 26                	jmp    f0103f1f <vprintfmt+0x2c5>
	else if (lflag)
f0103ef9:	85 c9                	test   %ecx,%ecx
f0103efb:	74 12                	je     f0103f0f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f0103efd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f00:	8d 50 04             	lea    0x4(%eax),%edx
f0103f03:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f06:	8b 30                	mov    (%eax),%esi
f0103f08:	89 f7                	mov    %esi,%edi
f0103f0a:	c1 ff 1f             	sar    $0x1f,%edi
f0103f0d:	eb 10                	jmp    f0103f1f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f0103f0f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f12:	8d 50 04             	lea    0x4(%eax),%edx
f0103f15:	89 55 14             	mov    %edx,0x14(%ebp)
f0103f18:	8b 30                	mov    (%eax),%esi
f0103f1a:	89 f7                	mov    %esi,%edi
f0103f1c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103f1f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103f24:	85 ff                	test   %edi,%edi
f0103f26:	0f 89 8c 00 00 00    	jns    f0103fb8 <vprintfmt+0x35e>
				putch('-', putdat);
f0103f2c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f30:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103f37:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103f3a:	f7 de                	neg    %esi
f0103f3c:	83 d7 00             	adc    $0x0,%edi
f0103f3f:	f7 df                	neg    %edi
			}
			base = 10;
f0103f41:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103f46:	eb 70                	jmp    f0103fb8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103f48:	89 ca                	mov    %ecx,%edx
f0103f4a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f4d:	e8 89 fc ff ff       	call   f0103bdb <getuint>
f0103f52:	89 c6                	mov    %eax,%esi
f0103f54:	89 d7                	mov    %edx,%edi
			base = 10;
f0103f56:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103f5b:	eb 5b                	jmp    f0103fb8 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap, lflag);
f0103f5d:	89 ca                	mov    %ecx,%edx
f0103f5f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103f62:	e8 74 fc ff ff       	call   f0103bdb <getuint>
f0103f67:	89 c6                	mov    %eax,%esi
f0103f69:	89 d7                	mov    %edx,%edi
            base = 8;
f0103f6b:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f0103f70:	eb 46                	jmp    f0103fb8 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f0103f72:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f76:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103f7d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103f80:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f84:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103f8b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103f8e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103f91:	8d 50 04             	lea    0x4(%eax),%edx
f0103f94:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103f97:	8b 30                	mov    (%eax),%esi
f0103f99:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103f9e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103fa3:	eb 13                	jmp    f0103fb8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103fa5:	89 ca                	mov    %ecx,%edx
f0103fa7:	8d 45 14             	lea    0x14(%ebp),%eax
f0103faa:	e8 2c fc ff ff       	call   f0103bdb <getuint>
f0103faf:	89 c6                	mov    %eax,%esi
f0103fb1:	89 d7                	mov    %edx,%edi
			base = 16;
f0103fb3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103fb8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103fbc:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103fc0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103fc3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103fc7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fcb:	89 34 24             	mov    %esi,(%esp)
f0103fce:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103fd2:	89 da                	mov    %ebx,%edx
f0103fd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fd7:	e8 24 fb ff ff       	call   f0103b00 <printnum>
			break;
f0103fdc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103fdf:	e9 99 fc ff ff       	jmp    f0103c7d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103fe4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103fe8:	89 14 24             	mov    %edx,(%esp)
f0103feb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103fee:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103ff1:	e9 87 fc ff ff       	jmp    f0103c7d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103ff6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ffa:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0104001:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104004:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0104008:	0f 84 6f fc ff ff    	je     f0103c7d <vprintfmt+0x23>
f010400e:	83 ee 01             	sub    $0x1,%esi
f0104011:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0104015:	75 f7                	jne    f010400e <vprintfmt+0x3b4>
f0104017:	e9 61 fc ff ff       	jmp    f0103c7d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010401c:	83 c4 4c             	add    $0x4c,%esp
f010401f:	5b                   	pop    %ebx
f0104020:	5e                   	pop    %esi
f0104021:	5f                   	pop    %edi
f0104022:	5d                   	pop    %ebp
f0104023:	c3                   	ret    

f0104024 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104024:	55                   	push   %ebp
f0104025:	89 e5                	mov    %esp,%ebp
f0104027:	83 ec 28             	sub    $0x28,%esp
f010402a:	8b 45 08             	mov    0x8(%ebp),%eax
f010402d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104030:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104033:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104037:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010403a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104041:	85 c0                	test   %eax,%eax
f0104043:	74 30                	je     f0104075 <vsnprintf+0x51>
f0104045:	85 d2                	test   %edx,%edx
f0104047:	7e 2c                	jle    f0104075 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104049:	8b 45 14             	mov    0x14(%ebp),%eax
f010404c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104050:	8b 45 10             	mov    0x10(%ebp),%eax
f0104053:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104057:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010405a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010405e:	c7 04 24 15 3c 10 f0 	movl   $0xf0103c15,(%esp)
f0104065:	e8 f0 fb ff ff       	call   f0103c5a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010406a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010406d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104070:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104073:	eb 05                	jmp    f010407a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104075:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010407a:	c9                   	leave  
f010407b:	c3                   	ret    

f010407c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010407c:	55                   	push   %ebp
f010407d:	89 e5                	mov    %esp,%ebp
f010407f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104082:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104085:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104089:	8b 45 10             	mov    0x10(%ebp),%eax
f010408c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104090:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104093:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104097:	8b 45 08             	mov    0x8(%ebp),%eax
f010409a:	89 04 24             	mov    %eax,(%esp)
f010409d:	e8 82 ff ff ff       	call   f0104024 <vsnprintf>
	va_end(ap);

	return rc;
}
f01040a2:	c9                   	leave  
f01040a3:	c3                   	ret    
	...

f01040b0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01040b0:	55                   	push   %ebp
f01040b1:	89 e5                	mov    %esp,%ebp
f01040b3:	57                   	push   %edi
f01040b4:	56                   	push   %esi
f01040b5:	53                   	push   %ebx
f01040b6:	83 ec 1c             	sub    $0x1c,%esp
f01040b9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01040bc:	85 c0                	test   %eax,%eax
f01040be:	74 10                	je     f01040d0 <readline+0x20>
		cprintf("%s", prompt);
f01040c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040c4:	c7 04 24 ff 54 10 f0 	movl   $0xf01054ff,(%esp)
f01040cb:	e8 1e f3 ff ff       	call   f01033ee <cprintf>

	i = 0;
	echoing = iscons(0);
f01040d0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01040d7:	e8 37 c5 ff ff       	call   f0100613 <iscons>
f01040dc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01040de:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01040e3:	e8 1a c5 ff ff       	call   f0100602 <getchar>
f01040e8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01040ea:	85 c0                	test   %eax,%eax
f01040ec:	79 17                	jns    f0104105 <readline+0x55>
			cprintf("read error: %e\n", c);
f01040ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040f2:	c7 04 24 bc 5e 10 f0 	movl   $0xf0105ebc,(%esp)
f01040f9:	e8 f0 f2 ff ff       	call   f01033ee <cprintf>
			return NULL;
f01040fe:	b8 00 00 00 00       	mov    $0x0,%eax
f0104103:	eb 6d                	jmp    f0104172 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104105:	83 f8 08             	cmp    $0x8,%eax
f0104108:	74 05                	je     f010410f <readline+0x5f>
f010410a:	83 f8 7f             	cmp    $0x7f,%eax
f010410d:	75 19                	jne    f0104128 <readline+0x78>
f010410f:	85 f6                	test   %esi,%esi
f0104111:	7e 15                	jle    f0104128 <readline+0x78>
			if (echoing)
f0104113:	85 ff                	test   %edi,%edi
f0104115:	74 0c                	je     f0104123 <readline+0x73>
				cputchar('\b');
f0104117:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010411e:	e8 cf c4 ff ff       	call   f01005f2 <cputchar>
			i--;
f0104123:	83 ee 01             	sub    $0x1,%esi
f0104126:	eb bb                	jmp    f01040e3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104128:	83 fb 1f             	cmp    $0x1f,%ebx
f010412b:	7e 1f                	jle    f010414c <readline+0x9c>
f010412d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104133:	7f 17                	jg     f010414c <readline+0x9c>
			if (echoing)
f0104135:	85 ff                	test   %edi,%edi
f0104137:	74 08                	je     f0104141 <readline+0x91>
				cputchar(c);
f0104139:	89 1c 24             	mov    %ebx,(%esp)
f010413c:	e8 b1 c4 ff ff       	call   f01005f2 <cputchar>
			buf[i++] = c;
f0104141:	88 9e 40 d9 17 f0    	mov    %bl,-0xfe826c0(%esi)
f0104147:	83 c6 01             	add    $0x1,%esi
f010414a:	eb 97                	jmp    f01040e3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010414c:	83 fb 0a             	cmp    $0xa,%ebx
f010414f:	74 05                	je     f0104156 <readline+0xa6>
f0104151:	83 fb 0d             	cmp    $0xd,%ebx
f0104154:	75 8d                	jne    f01040e3 <readline+0x33>
			if (echoing)
f0104156:	85 ff                	test   %edi,%edi
f0104158:	74 0c                	je     f0104166 <readline+0xb6>
				cputchar('\n');
f010415a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104161:	e8 8c c4 ff ff       	call   f01005f2 <cputchar>
			buf[i] = 0;
f0104166:	c6 86 40 d9 17 f0 00 	movb   $0x0,-0xfe826c0(%esi)
			return buf;
f010416d:	b8 40 d9 17 f0       	mov    $0xf017d940,%eax
		}
	}
}
f0104172:	83 c4 1c             	add    $0x1c,%esp
f0104175:	5b                   	pop    %ebx
f0104176:	5e                   	pop    %esi
f0104177:	5f                   	pop    %edi
f0104178:	5d                   	pop    %ebp
f0104179:	c3                   	ret    
f010417a:	00 00                	add    %al,(%eax)
f010417c:	00 00                	add    %al,(%eax)
	...

f0104180 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104180:	55                   	push   %ebp
f0104181:	89 e5                	mov    %esp,%ebp
f0104183:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104186:	b8 00 00 00 00       	mov    $0x0,%eax
f010418b:	80 3a 00             	cmpb   $0x0,(%edx)
f010418e:	74 09                	je     f0104199 <strlen+0x19>
		n++;
f0104190:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104193:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104197:	75 f7                	jne    f0104190 <strlen+0x10>
		n++;
	return n;
}
f0104199:	5d                   	pop    %ebp
f010419a:	c3                   	ret    

f010419b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010419b:	55                   	push   %ebp
f010419c:	89 e5                	mov    %esp,%ebp
f010419e:	53                   	push   %ebx
f010419f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01041a2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041a5:	b8 00 00 00 00       	mov    $0x0,%eax
f01041aa:	85 c9                	test   %ecx,%ecx
f01041ac:	74 1a                	je     f01041c8 <strnlen+0x2d>
f01041ae:	80 3b 00             	cmpb   $0x0,(%ebx)
f01041b1:	74 15                	je     f01041c8 <strnlen+0x2d>
f01041b3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01041b8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01041ba:	39 ca                	cmp    %ecx,%edx
f01041bc:	74 0a                	je     f01041c8 <strnlen+0x2d>
f01041be:	83 c2 01             	add    $0x1,%edx
f01041c1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01041c6:	75 f0                	jne    f01041b8 <strnlen+0x1d>
		n++;
	return n;
}
f01041c8:	5b                   	pop    %ebx
f01041c9:	5d                   	pop    %ebp
f01041ca:	c3                   	ret    

f01041cb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01041cb:	55                   	push   %ebp
f01041cc:	89 e5                	mov    %esp,%ebp
f01041ce:	53                   	push   %ebx
f01041cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01041d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01041d5:	ba 00 00 00 00       	mov    $0x0,%edx
f01041da:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01041de:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01041e1:	83 c2 01             	add    $0x1,%edx
f01041e4:	84 c9                	test   %cl,%cl
f01041e6:	75 f2                	jne    f01041da <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01041e8:	5b                   	pop    %ebx
f01041e9:	5d                   	pop    %ebp
f01041ea:	c3                   	ret    

f01041eb <strncpy>:

char *
strcat(char *dst, const char *src)
f01041eb:	55                   	push   %ebp
f01041ec:	89 e5                	mov    %esp,%ebp
f01041ee:	56                   	push   %esi
f01041ef:	53                   	push   %ebx
f01041f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01041f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01041f6:	8b 75 10             	mov    0x10(%ebp),%esi
{
	int len = strlen(dst);
	strcpy(dst + len, src);
	return dst;
}
f01041f9:	85 f6                	test   %esi,%esi
f01041fb:	74 18                	je     f0104215 <strncpy+0x2a>
f01041fd:	b9 00 00 00 00       	mov    $0x0,%ecx

f0104202:	0f b6 1a             	movzbl (%edx),%ebx
f0104205:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
char *
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
f0104208:	80 3a 01             	cmpb   $0x1,(%edx)
f010420b:	83 da ff             	sbb    $0xffffffff,%edx
strcat(char *dst, const char *src)
{
	int len = strlen(dst);
	strcpy(dst + len, src);
	return dst;
}
f010420e:	83 c1 01             	add    $0x1,%ecx
f0104211:	39 f1                	cmp    %esi,%ecx
f0104213:	75 ed                	jne    f0104202 <strncpy+0x17>
char *
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
f0104215:	5b                   	pop    %ebx
f0104216:	5e                   	pop    %esi
f0104217:	5d                   	pop    %ebp
f0104218:	c3                   	ret    

f0104219 <strlcpy>:
	for (i = 0; i < size; i++) {
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
f0104219:	55                   	push   %ebp
f010421a:	89 e5                	mov    %esp,%ebp
f010421c:	57                   	push   %edi
f010421d:	56                   	push   %esi
f010421e:	53                   	push   %ebx
f010421f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104222:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104225:	8b 75 10             	mov    0x10(%ebp),%esi
			src++;
	}
	return ret;
}
f0104228:	89 f8                	mov    %edi,%eax
f010422a:	85 f6                	test   %esi,%esi
f010422c:	74 2b                	je     f0104259 <strlcpy+0x40>

f010422e:	83 fe 01             	cmp    $0x1,%esi
f0104231:	74 23                	je     f0104256 <strlcpy+0x3d>
f0104233:	0f b6 0b             	movzbl (%ebx),%ecx
f0104236:	84 c9                	test   %cl,%cl
f0104238:	74 1c                	je     f0104256 <strlcpy+0x3d>
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
		*dst++ = *src;
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
f010423a:	83 ee 02             	sub    $0x2,%esi
f010423d:	ba 00 00 00 00       	mov    $0x0,%edx
			src++;
	}
	return ret;
}

size_t
f0104242:	88 08                	mov    %cl,(%eax)
f0104244:	83 c0 01             	add    $0x1,%eax
		if (*src != '\0')
			src++;
	}
	return ret;
}

f0104247:	39 f2                	cmp    %esi,%edx
f0104249:	74 0b                	je     f0104256 <strlcpy+0x3d>
f010424b:	83 c2 01             	add    $0x1,%edx
f010424e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0104252:	84 c9                	test   %cl,%cl
f0104254:	75 ec                	jne    f0104242 <strlcpy+0x29>
size_t
strlcpy(char *dst, const char *src, size_t size)
f0104256:	c6 00 00             	movb   $0x0,(%eax)
{
	char *dst_in;
f0104259:	29 f8                	sub    %edi,%eax

f010425b:	5b                   	pop    %ebx
f010425c:	5e                   	pop    %esi
f010425d:	5f                   	pop    %edi
f010425e:	5d                   	pop    %ebp
f010425f:	c3                   	ret    

f0104260 <strcmp>:
	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104260:	55                   	push   %ebp
f0104261:	89 e5                	mov    %esp,%ebp
f0104263:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104266:	8b 55 0c             	mov    0xc(%ebp),%edx
		*dst = '\0';
f0104269:	0f b6 01             	movzbl (%ecx),%eax
f010426c:	84 c0                	test   %al,%al
f010426e:	74 16                	je     f0104286 <strcmp+0x26>
f0104270:	3a 02                	cmp    (%edx),%al
f0104272:	75 12                	jne    f0104286 <strcmp+0x26>
	}
f0104274:	83 c2 01             	add    $0x1,%edx

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
		*dst = '\0';
f0104277:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010427b:	84 c0                	test   %al,%al
f010427d:	74 07                	je     f0104286 <strcmp+0x26>
f010427f:	83 c1 01             	add    $0x1,%ecx
f0104282:	3a 02                	cmp    (%edx),%al
f0104284:	74 ee                	je     f0104274 <strcmp+0x14>
	}
	return dst - dst_in;
f0104286:	0f b6 c0             	movzbl %al,%eax
f0104289:	0f b6 12             	movzbl (%edx),%edx
f010428c:	29 d0                	sub    %edx,%eax
}
f010428e:	5d                   	pop    %ebp
f010428f:	c3                   	ret    

f0104290 <strncmp>:

int
strcmp(const char *p, const char *q)
{
f0104290:	55                   	push   %ebp
f0104291:	89 e5                	mov    %esp,%ebp
f0104293:	53                   	push   %ebx
f0104294:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104297:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010429a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (*p && *p == *q)
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010429d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042a2:	85 d2                	test   %edx,%edx
f01042a4:	74 28                	je     f01042ce <strncmp+0x3e>
f01042a6:	0f b6 01             	movzbl (%ecx),%eax
f01042a9:	84 c0                	test   %al,%al
f01042ab:	74 24                	je     f01042d1 <strncmp+0x41>
f01042ad:	3a 03                	cmp    (%ebx),%al
f01042af:	75 20                	jne    f01042d1 <strncmp+0x41>
f01042b1:	83 ea 01             	sub    $0x1,%edx
f01042b4:	74 13                	je     f01042c9 <strncmp+0x39>
		p++, q++;
f01042b6:	83 c1 01             	add    $0x1,%ecx
f01042b9:	83 c3 01             	add    $0x1,%ebx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01042bc:	0f b6 01             	movzbl (%ecx),%eax
f01042bf:	84 c0                	test   %al,%al
f01042c1:	74 0e                	je     f01042d1 <strncmp+0x41>
f01042c3:	3a 03                	cmp    (%ebx),%al
f01042c5:	74 ea                	je     f01042b1 <strncmp+0x21>
f01042c7:	eb 08                	jmp    f01042d1 <strncmp+0x41>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01042c9:	b8 00 00 00 00       	mov    $0x0,%eax

int
strncmp(const char *p, const char *q, size_t n)
f01042ce:	5b                   	pop    %ebx
f01042cf:	5d                   	pop    %ebp
f01042d0:	c3                   	ret    
	while (*p && *p == *q)
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
}

int
f01042d1:	0f b6 01             	movzbl (%ecx),%eax
f01042d4:	0f b6 13             	movzbl (%ebx),%edx
f01042d7:	29 d0                	sub    %edx,%eax
f01042d9:	eb f3                	jmp    f01042ce <strncmp+0x3e>

f01042db <strchr>:
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
f01042db:	55                   	push   %ebp
f01042dc:	89 e5                	mov    %esp,%ebp
f01042de:	8b 45 08             	mov    0x8(%ebp),%eax
f01042e1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042e5:	0f b6 10             	movzbl (%eax),%edx
f01042e8:	84 d2                	test   %dl,%dl
f01042ea:	74 1c                	je     f0104308 <strchr+0x2d>
}
f01042ec:	38 ca                	cmp    %cl,%dl
f01042ee:	75 09                	jne    f01042f9 <strchr+0x1e>
f01042f0:	eb 1b                	jmp    f010430d <strchr+0x32>
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042f2:	83 c0 01             	add    $0x1,%eax
}
f01042f5:	38 ca                	cmp    %cl,%dl
f01042f7:	74 14                	je     f010430d <strchr+0x32>
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01042f9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01042fd:	84 d2                	test   %dl,%dl
f01042ff:	75 f1                	jne    f01042f2 <strchr+0x17>
}

// Return a pointer to the first occurrence of 'c' in 's',
f0104301:	b8 00 00 00 00       	mov    $0x0,%eax
f0104306:	eb 05                	jmp    f010430d <strchr+0x32>
f0104308:	b8 00 00 00 00       	mov    $0x0,%eax
// or a null pointer if the string has no 'c'.
f010430d:	5d                   	pop    %ebp
f010430e:	c3                   	ret    

f010430f <strfind>:
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
		if (*s == c)
			return (char *) s;
f010430f:	55                   	push   %ebp
f0104310:	89 e5                	mov    %esp,%ebp
f0104312:	8b 45 08             	mov    0x8(%ebp),%eax
f0104315:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	return 0;
f0104319:	0f b6 10             	movzbl (%eax),%edx
f010431c:	84 d2                	test   %dl,%dl
f010431e:	74 14                	je     f0104334 <strfind+0x25>
}
f0104320:	38 ca                	cmp    %cl,%dl
f0104322:	75 06                	jne    f010432a <strfind+0x1b>
f0104324:	eb 0e                	jmp    f0104334 <strfind+0x25>
f0104326:	38 ca                	cmp    %cl,%dl
f0104328:	74 0a                	je     f0104334 <strfind+0x25>
strchr(const char *s, char c)
{
	for (; *s; s++)
		if (*s == c)
			return (char *) s;
	return 0;
f010432a:	83 c0 01             	add    $0x1,%eax
f010432d:	0f b6 10             	movzbl (%eax),%edx
f0104330:	84 d2                	test   %dl,%dl
f0104332:	75 f2                	jne    f0104326 <strfind+0x17>
}

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
f0104334:	5d                   	pop    %ebp
f0104335:	c3                   	ret    

f0104336 <memset>:
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
		if (*s == c)
f0104336:	55                   	push   %ebp
f0104337:	89 e5                	mov    %esp,%ebp
f0104339:	83 ec 0c             	sub    $0xc,%esp
f010433c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010433f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104342:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104345:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104348:	8b 45 0c             	mov    0xc(%ebp),%eax
f010434b:	8b 4d 10             	mov    0x10(%ebp),%ecx
			break;
	return (char *) s;
}
f010434e:	85 c9                	test   %ecx,%ecx
f0104350:	74 30                	je     f0104382 <memset+0x4c>

#if ASM
f0104352:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104358:	75 25                	jne    f010437f <memset+0x49>
f010435a:	f6 c1 03             	test   $0x3,%cl
f010435d:	75 20                	jne    f010437f <memset+0x49>
void *
f010435f:	0f b6 d0             	movzbl %al,%edx
memset(void *v, int c, size_t n)
f0104362:	89 d3                	mov    %edx,%ebx
f0104364:	c1 e3 08             	shl    $0x8,%ebx
f0104367:	89 d6                	mov    %edx,%esi
f0104369:	c1 e6 18             	shl    $0x18,%esi
f010436c:	89 d0                	mov    %edx,%eax
f010436e:	c1 e0 10             	shl    $0x10,%eax
f0104371:	09 f0                	or     %esi,%eax
f0104373:	09 d0                	or     %edx,%eax
f0104375:	09 d8                	or     %ebx,%eax
{
	char *p;
f0104377:	c1 e9 02             	shr    $0x2,%ecx
}

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010437a:	fc                   	cld    
f010437b:	f3 ab                	rep stos %eax,%es:(%edi)
f010437d:	eb 03                	jmp    f0104382 <memset+0x4c>
	char *p;

	if (n == 0)
		return v;
f010437f:	fc                   	cld    
f0104380:	f3 aa                	rep stos %al,%es:(%edi)
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104382:	89 f8                	mov    %edi,%eax
f0104384:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104387:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010438a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010438d:	89 ec                	mov    %ebp,%esp
f010438f:	5d                   	pop    %ebp
f0104390:	c3                   	ret    

f0104391 <memmove>:
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104391:	55                   	push   %ebp
f0104392:	89 e5                	mov    %esp,%ebp
f0104394:	83 ec 08             	sub    $0x8,%esp
f0104397:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010439a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010439d:	8b 45 08             	mov    0x8(%ebp),%eax
f01043a0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043a3:	8b 4d 10             	mov    0x10(%ebp),%ecx
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}

void *
f01043a6:	39 c6                	cmp    %eax,%esi
f01043a8:	73 36                	jae    f01043e0 <memmove+0x4f>
f01043aa:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01043ad:	39 d0                	cmp    %edx,%eax
f01043af:	73 2f                	jae    f01043e0 <memmove+0x4f>
memmove(void *dst, const void *src, size_t n)
{
f01043b1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
	const char *s;
f01043b4:	f6 c2 03             	test   $0x3,%dl
f01043b7:	75 1b                	jne    f01043d4 <memmove+0x43>
f01043b9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01043bf:	75 13                	jne    f01043d4 <memmove+0x43>
f01043c1:	f6 c1 03             	test   $0x3,%cl
f01043c4:	75 0e                	jne    f01043d4 <memmove+0x43>
	char *d;
	
f01043c6:	83 ef 04             	sub    $0x4,%edi
f01043c9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01043cc:	c1 e9 02             	shr    $0x2,%ecx

void *
memmove(void *dst, const void *src, size_t n)
{
	const char *s;
	char *d;
f01043cf:	fd                   	std    
f01043d0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043d2:	eb 09                	jmp    f01043dd <memmove+0x4c>
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01043d4:	83 ef 01             	sub    $0x1,%edi
f01043d7:	8d 72 ff             	lea    -0x1(%edx),%esi
{
	const char *s;
	char *d;
	
	s = src;
	d = dst;
f01043da:	fd                   	std    
f01043db:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
	if (s < d && s + n > d) {
		s += n;
		d += n;
f01043dd:	fc                   	cld    
f01043de:	eb 20                	jmp    f0104400 <memmove+0x6f>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01043e0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01043e6:	75 13                	jne    f01043fb <memmove+0x6a>
f01043e8:	a8 03                	test   $0x3,%al
f01043ea:	75 0f                	jne    f01043fb <memmove+0x6a>
f01043ec:	f6 c1 03             	test   $0x3,%cl
f01043ef:	75 0a                	jne    f01043fb <memmove+0x6a>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
f01043f1:	c1 e9 02             	shr    $0x2,%ecx
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01043f4:	89 c7                	mov    %eax,%edi
f01043f6:	fc                   	cld    
f01043f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01043f9:	eb 05                	jmp    f0104400 <memmove+0x6f>
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01043fb:	89 c7                	mov    %eax,%edi
f01043fd:	fc                   	cld    
f01043fe:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104400:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104403:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104406:	89 ec                	mov    %ebp,%esp
f0104408:	5d                   	pop    %ebp
f0104409:	c3                   	ret    

f010440a <memcpy>:
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;

	return dst;
f010440a:	55                   	push   %ebp
f010440b:	89 e5                	mov    %esp,%ebp
f010440d:	83 ec 0c             	sub    $0xc,%esp
}
f0104410:	8b 45 10             	mov    0x10(%ebp),%eax
f0104413:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104417:	8b 45 0c             	mov    0xc(%ebp),%eax
f010441a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010441e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104421:	89 04 24             	mov    %eax,(%esp)
f0104424:	e8 68 ff ff ff       	call   f0104391 <memmove>
#endif
f0104429:	c9                   	leave  
f010442a:	c3                   	ret    

f010442b <memcmp>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
f010442b:	55                   	push   %ebp
f010442c:	89 e5                	mov    %esp,%ebp
f010442e:	57                   	push   %edi
f010442f:	56                   	push   %esi
f0104430:	53                   	push   %ebx
f0104431:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104434:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104437:	8b 7d 10             	mov    0x10(%ebp),%edi

int
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f010443a:	b8 00 00 00 00       	mov    $0x0,%eax
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
	return memmove(dst, src, n);
}
f010443f:	85 ff                	test   %edi,%edi
f0104441:	74 37                	je     f010447a <memcmp+0x4f>

f0104443:	0f b6 03             	movzbl (%ebx),%eax
f0104446:	0f b6 0e             	movzbl (%esi),%ecx
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
	return memmove(dst, src, n);
}
f0104449:	83 ef 01             	sub    $0x1,%edi
f010444c:	ba 00 00 00 00       	mov    $0x0,%edx

f0104451:	38 c8                	cmp    %cl,%al
f0104453:	74 1c                	je     f0104471 <memcmp+0x46>
f0104455:	eb 10                	jmp    f0104467 <memcmp+0x3c>
f0104457:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010445c:	83 c2 01             	add    $0x1,%edx
f010445f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0104463:	38 c8                	cmp    %cl,%al
f0104465:	74 0a                	je     f0104471 <memcmp+0x46>
int
f0104467:	0f b6 c0             	movzbl %al,%eax
f010446a:	0f b6 c9             	movzbl %cl,%ecx
f010446d:	29 c8                	sub    %ecx,%eax
f010446f:	eb 09                	jmp    f010447a <memcmp+0x4f>
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
	return memmove(dst, src, n);
}
f0104471:	39 fa                	cmp    %edi,%edx
f0104473:	75 e2                	jne    f0104457 <memcmp+0x2c>

int
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;
f0104475:	b8 00 00 00 00       	mov    $0x0,%eax

f010447a:	5b                   	pop    %ebx
f010447b:	5e                   	pop    %esi
f010447c:	5f                   	pop    %edi
f010447d:	5d                   	pop    %ebp
f010447e:	c3                   	ret    

f010447f <memfind>:
	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010447f:	55                   	push   %ebp
f0104480:	89 e5                	mov    %esp,%ebp
f0104482:	8b 45 08             	mov    0x8(%ebp),%eax
	}
f0104485:	89 c2                	mov    %eax,%edx
f0104487:	03 55 10             	add    0x10(%ebp),%edx

f010448a:	39 d0                	cmp    %edx,%eax
f010448c:	73 15                	jae    f01044a3 <memfind+0x24>
	return 0;
f010448e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0104492:	38 08                	cmp    %cl,(%eax)
f0104494:	75 06                	jne    f010449c <memfind+0x1d>
f0104496:	eb 0b                	jmp    f01044a3 <memfind+0x24>
f0104498:	38 08                	cmp    %cl,(%eax)
f010449a:	74 07                	je     f01044a3 <memfind+0x24>
	while (n-- > 0) {
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

f010449c:	83 c0 01             	add    $0x1,%eax
f010449f:	39 d0                	cmp    %edx,%eax
f01044a1:	75 f5                	jne    f0104498 <memfind+0x19>
	return 0;
}

void *
f01044a3:	5d                   	pop    %ebp
f01044a4:	c3                   	ret    

f01044a5 <strtol>:
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01044a5:	55                   	push   %ebp
f01044a6:	89 e5                	mov    %esp,%ebp
f01044a8:	57                   	push   %edi
f01044a9:	56                   	push   %esi
f01044aa:	53                   	push   %ebx
f01044ab:	8b 55 08             	mov    0x8(%ebp),%edx
f01044ae:	8b 5d 10             	mov    0x10(%ebp),%ebx
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}

f01044b1:	0f b6 02             	movzbl (%edx),%eax
f01044b4:	3c 20                	cmp    $0x20,%al
f01044b6:	74 04                	je     f01044bc <strtol+0x17>
f01044b8:	3c 09                	cmp    $0x9,%al
f01044ba:	75 0e                	jne    f01044ca <strtol+0x25>
long
f01044bc:	83 c2 01             	add    $0x1,%edx
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}

f01044bf:	0f b6 02             	movzbl (%edx),%eax
f01044c2:	3c 20                	cmp    $0x20,%al
f01044c4:	74 f6                	je     f01044bc <strtol+0x17>
f01044c6:	3c 09                	cmp    $0x9,%al
f01044c8:	74 f2                	je     f01044bc <strtol+0x17>
long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01044ca:	3c 2b                	cmp    $0x2b,%al
f01044cc:	75 0a                	jne    f01044d8 <strtol+0x33>
	long val = 0;
f01044ce:	83 c2 01             	add    $0x1,%edx
void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
		if (*(const unsigned char *) s == (unsigned char) c)
f01044d1:	bf 00 00 00 00       	mov    $0x0,%edi
f01044d6:	eb 10                	jmp    f01044e8 <strtol+0x43>
f01044d8:	bf 00 00 00 00       	mov    $0x0,%edi
long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
	long val = 0;

f01044dd:	3c 2d                	cmp    $0x2d,%al
f01044df:	75 07                	jne    f01044e8 <strtol+0x43>
	// gobble initial whitespace
f01044e1:	83 c2 01             	add    $0x1,%edx
f01044e4:	66 bf 01 00          	mov    $0x1,%di
	while (*s == ' ' || *s == '\t')
		s++;

f01044e8:	85 db                	test   %ebx,%ebx
f01044ea:	0f 94 c0             	sete   %al
f01044ed:	74 05                	je     f01044f4 <strtol+0x4f>
f01044ef:	83 fb 10             	cmp    $0x10,%ebx
f01044f2:	75 15                	jne    f0104509 <strtol+0x64>
f01044f4:	80 3a 30             	cmpb   $0x30,(%edx)
f01044f7:	75 10                	jne    f0104509 <strtol+0x64>
f01044f9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01044fd:	75 0a                	jne    f0104509 <strtol+0x64>
	// plus/minus sign
f01044ff:	83 c2 02             	add    $0x2,%edx
f0104502:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104507:	eb 13                	jmp    f010451c <strtol+0x77>
	if (*s == '+')
f0104509:	84 c0                	test   %al,%al
f010450b:	74 0f                	je     f010451c <strtol+0x77>
		s++;
	else if (*s == '-')
		s++, neg = 1;
f010450d:	bb 0a 00 00 00       	mov    $0xa,%ebx
	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
		s++;

	// plus/minus sign
	if (*s == '+')
f0104512:	80 3a 30             	cmpb   $0x30,(%edx)
f0104515:	75 05                	jne    f010451c <strtol+0x77>
		s++;
f0104517:	83 c2 01             	add    $0x1,%edx
f010451a:	b3 08                	mov    $0x8,%bl
	else if (*s == '-')
		s++, neg = 1;
f010451c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104521:	89 de                	mov    %ebx,%esi

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
f0104523:	0f b6 0a             	movzbl (%edx),%ecx
f0104526:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104529:	80 fb 09             	cmp    $0x9,%bl
f010452c:	77 08                	ja     f0104536 <strtol+0x91>
	else if (base == 0)
f010452e:	0f be c9             	movsbl %cl,%ecx
f0104531:	83 e9 30             	sub    $0x30,%ecx
f0104534:	eb 1e                	jmp    f0104554 <strtol+0xaf>
		base = 10;
f0104536:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104539:	80 fb 19             	cmp    $0x19,%bl
f010453c:	77 08                	ja     f0104546 <strtol+0xa1>

f010453e:	0f be c9             	movsbl %cl,%ecx
f0104541:	83 e9 57             	sub    $0x57,%ecx
f0104544:	eb 0e                	jmp    f0104554 <strtol+0xaf>
	// digits
f0104546:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104549:	80 fb 19             	cmp    $0x19,%bl
f010454c:	77 14                	ja     f0104562 <strtol+0xbd>
	while (1) {
f010454e:	0f be c9             	movsbl %cl,%ecx
f0104551:	83 e9 37             	sub    $0x37,%ecx
		int dig;

		if (*s >= '0' && *s <= '9')
f0104554:	39 f1                	cmp    %esi,%ecx
f0104556:	7d 0e                	jge    f0104566 <strtol+0xc1>
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0104558:	83 c2 01             	add    $0x1,%edx
f010455b:	0f af c6             	imul   %esi,%eax
f010455e:	01 c8                	add    %ecx,%eax
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104560:	eb c1                	jmp    f0104523 <strtol+0x7e>
	else if (base == 0 && s[0] == '0')
		s++, base = 8;
	else if (base == 0)
		base = 10;

	// digits
f0104562:	89 c1                	mov    %eax,%ecx
f0104564:	eb 02                	jmp    f0104568 <strtol+0xc3>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104566:	89 c1                	mov    %eax,%ecx
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
f0104568:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010456c:	74 05                	je     f0104573 <strtol+0xce>
			break;
f010456e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104571:	89 13                	mov    %edx,(%ebx)
		if (dig >= base)
f0104573:	89 ca                	mov    %ecx,%edx
f0104575:	f7 da                	neg    %edx
f0104577:	85 ff                	test   %edi,%edi
f0104579:	0f 45 c2             	cmovne %edx,%eax
			break;
f010457c:	5b                   	pop    %ebx
f010457d:	5e                   	pop    %esi
f010457e:	5f                   	pop    %edi
f010457f:	5d                   	pop    %ebp
f0104580:	c3                   	ret    
	...

f0104590 <__udivdi3>:
f0104590:	83 ec 1c             	sub    $0x1c,%esp
f0104593:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104597:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010459b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010459f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01045a3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01045a7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01045ab:	85 ff                	test   %edi,%edi
f01045ad:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01045b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01045b5:	89 cd                	mov    %ecx,%ebp
f01045b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01045bb:	75 33                	jne    f01045f0 <__udivdi3+0x60>
f01045bd:	39 f1                	cmp    %esi,%ecx
f01045bf:	77 57                	ja     f0104618 <__udivdi3+0x88>
f01045c1:	85 c9                	test   %ecx,%ecx
f01045c3:	75 0b                	jne    f01045d0 <__udivdi3+0x40>
f01045c5:	b8 01 00 00 00       	mov    $0x1,%eax
f01045ca:	31 d2                	xor    %edx,%edx
f01045cc:	f7 f1                	div    %ecx
f01045ce:	89 c1                	mov    %eax,%ecx
f01045d0:	89 f0                	mov    %esi,%eax
f01045d2:	31 d2                	xor    %edx,%edx
f01045d4:	f7 f1                	div    %ecx
f01045d6:	89 c6                	mov    %eax,%esi
f01045d8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01045dc:	f7 f1                	div    %ecx
f01045de:	89 f2                	mov    %esi,%edx
f01045e0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01045e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01045e8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01045ec:	83 c4 1c             	add    $0x1c,%esp
f01045ef:	c3                   	ret    
f01045f0:	31 d2                	xor    %edx,%edx
f01045f2:	31 c0                	xor    %eax,%eax
f01045f4:	39 f7                	cmp    %esi,%edi
f01045f6:	77 e8                	ja     f01045e0 <__udivdi3+0x50>
f01045f8:	0f bd cf             	bsr    %edi,%ecx
f01045fb:	83 f1 1f             	xor    $0x1f,%ecx
f01045fe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104602:	75 2c                	jne    f0104630 <__udivdi3+0xa0>
f0104604:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104608:	76 04                	jbe    f010460e <__udivdi3+0x7e>
f010460a:	39 f7                	cmp    %esi,%edi
f010460c:	73 d2                	jae    f01045e0 <__udivdi3+0x50>
f010460e:	31 d2                	xor    %edx,%edx
f0104610:	b8 01 00 00 00       	mov    $0x1,%eax
f0104615:	eb c9                	jmp    f01045e0 <__udivdi3+0x50>
f0104617:	90                   	nop
f0104618:	89 f2                	mov    %esi,%edx
f010461a:	f7 f1                	div    %ecx
f010461c:	31 d2                	xor    %edx,%edx
f010461e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104622:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104626:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010462a:	83 c4 1c             	add    $0x1c,%esp
f010462d:	c3                   	ret    
f010462e:	66 90                	xchg   %ax,%ax
f0104630:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104635:	b8 20 00 00 00       	mov    $0x20,%eax
f010463a:	89 ea                	mov    %ebp,%edx
f010463c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104640:	d3 e7                	shl    %cl,%edi
f0104642:	89 c1                	mov    %eax,%ecx
f0104644:	d3 ea                	shr    %cl,%edx
f0104646:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010464b:	09 fa                	or     %edi,%edx
f010464d:	89 f7                	mov    %esi,%edi
f010464f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104653:	89 f2                	mov    %esi,%edx
f0104655:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104659:	d3 e5                	shl    %cl,%ebp
f010465b:	89 c1                	mov    %eax,%ecx
f010465d:	d3 ef                	shr    %cl,%edi
f010465f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104664:	d3 e2                	shl    %cl,%edx
f0104666:	89 c1                	mov    %eax,%ecx
f0104668:	d3 ee                	shr    %cl,%esi
f010466a:	09 d6                	or     %edx,%esi
f010466c:	89 fa                	mov    %edi,%edx
f010466e:	89 f0                	mov    %esi,%eax
f0104670:	f7 74 24 0c          	divl   0xc(%esp)
f0104674:	89 d7                	mov    %edx,%edi
f0104676:	89 c6                	mov    %eax,%esi
f0104678:	f7 e5                	mul    %ebp
f010467a:	39 d7                	cmp    %edx,%edi
f010467c:	72 22                	jb     f01046a0 <__udivdi3+0x110>
f010467e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104682:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104687:	d3 e5                	shl    %cl,%ebp
f0104689:	39 c5                	cmp    %eax,%ebp
f010468b:	73 04                	jae    f0104691 <__udivdi3+0x101>
f010468d:	39 d7                	cmp    %edx,%edi
f010468f:	74 0f                	je     f01046a0 <__udivdi3+0x110>
f0104691:	89 f0                	mov    %esi,%eax
f0104693:	31 d2                	xor    %edx,%edx
f0104695:	e9 46 ff ff ff       	jmp    f01045e0 <__udivdi3+0x50>
f010469a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01046a0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01046a3:	31 d2                	xor    %edx,%edx
f01046a5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01046a9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01046ad:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01046b1:	83 c4 1c             	add    $0x1c,%esp
f01046b4:	c3                   	ret    
	...

f01046c0 <__umoddi3>:
f01046c0:	83 ec 1c             	sub    $0x1c,%esp
f01046c3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01046c7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01046cb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01046cf:	89 74 24 10          	mov    %esi,0x10(%esp)
f01046d3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01046d7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01046db:	85 ed                	test   %ebp,%ebp
f01046dd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01046e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046e5:	89 cf                	mov    %ecx,%edi
f01046e7:	89 04 24             	mov    %eax,(%esp)
f01046ea:	89 f2                	mov    %esi,%edx
f01046ec:	75 1a                	jne    f0104708 <__umoddi3+0x48>
f01046ee:	39 f1                	cmp    %esi,%ecx
f01046f0:	76 4e                	jbe    f0104740 <__umoddi3+0x80>
f01046f2:	f7 f1                	div    %ecx
f01046f4:	89 d0                	mov    %edx,%eax
f01046f6:	31 d2                	xor    %edx,%edx
f01046f8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01046fc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104700:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104704:	83 c4 1c             	add    $0x1c,%esp
f0104707:	c3                   	ret    
f0104708:	39 f5                	cmp    %esi,%ebp
f010470a:	77 54                	ja     f0104760 <__umoddi3+0xa0>
f010470c:	0f bd c5             	bsr    %ebp,%eax
f010470f:	83 f0 1f             	xor    $0x1f,%eax
f0104712:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104716:	75 60                	jne    f0104778 <__umoddi3+0xb8>
f0104718:	3b 0c 24             	cmp    (%esp),%ecx
f010471b:	0f 87 07 01 00 00    	ja     f0104828 <__umoddi3+0x168>
f0104721:	89 f2                	mov    %esi,%edx
f0104723:	8b 34 24             	mov    (%esp),%esi
f0104726:	29 ce                	sub    %ecx,%esi
f0104728:	19 ea                	sbb    %ebp,%edx
f010472a:	89 34 24             	mov    %esi,(%esp)
f010472d:	8b 04 24             	mov    (%esp),%eax
f0104730:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104734:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104738:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010473c:	83 c4 1c             	add    $0x1c,%esp
f010473f:	c3                   	ret    
f0104740:	85 c9                	test   %ecx,%ecx
f0104742:	75 0b                	jne    f010474f <__umoddi3+0x8f>
f0104744:	b8 01 00 00 00       	mov    $0x1,%eax
f0104749:	31 d2                	xor    %edx,%edx
f010474b:	f7 f1                	div    %ecx
f010474d:	89 c1                	mov    %eax,%ecx
f010474f:	89 f0                	mov    %esi,%eax
f0104751:	31 d2                	xor    %edx,%edx
f0104753:	f7 f1                	div    %ecx
f0104755:	8b 04 24             	mov    (%esp),%eax
f0104758:	f7 f1                	div    %ecx
f010475a:	eb 98                	jmp    f01046f4 <__umoddi3+0x34>
f010475c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104760:	89 f2                	mov    %esi,%edx
f0104762:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104766:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010476a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010476e:	83 c4 1c             	add    $0x1c,%esp
f0104771:	c3                   	ret    
f0104772:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104778:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010477d:	89 e8                	mov    %ebp,%eax
f010477f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104784:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104788:	89 fa                	mov    %edi,%edx
f010478a:	d3 e0                	shl    %cl,%eax
f010478c:	89 e9                	mov    %ebp,%ecx
f010478e:	d3 ea                	shr    %cl,%edx
f0104790:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104795:	09 c2                	or     %eax,%edx
f0104797:	8b 44 24 08          	mov    0x8(%esp),%eax
f010479b:	89 14 24             	mov    %edx,(%esp)
f010479e:	89 f2                	mov    %esi,%edx
f01047a0:	d3 e7                	shl    %cl,%edi
f01047a2:	89 e9                	mov    %ebp,%ecx
f01047a4:	d3 ea                	shr    %cl,%edx
f01047a6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01047ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01047af:	d3 e6                	shl    %cl,%esi
f01047b1:	89 e9                	mov    %ebp,%ecx
f01047b3:	d3 e8                	shr    %cl,%eax
f01047b5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01047ba:	09 f0                	or     %esi,%eax
f01047bc:	8b 74 24 08          	mov    0x8(%esp),%esi
f01047c0:	f7 34 24             	divl   (%esp)
f01047c3:	d3 e6                	shl    %cl,%esi
f01047c5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01047c9:	89 d6                	mov    %edx,%esi
f01047cb:	f7 e7                	mul    %edi
f01047cd:	39 d6                	cmp    %edx,%esi
f01047cf:	89 c1                	mov    %eax,%ecx
f01047d1:	89 d7                	mov    %edx,%edi
f01047d3:	72 3f                	jb     f0104814 <__umoddi3+0x154>
f01047d5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01047d9:	72 35                	jb     f0104810 <__umoddi3+0x150>
f01047db:	8b 44 24 08          	mov    0x8(%esp),%eax
f01047df:	29 c8                	sub    %ecx,%eax
f01047e1:	19 fe                	sbb    %edi,%esi
f01047e3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01047e8:	89 f2                	mov    %esi,%edx
f01047ea:	d3 e8                	shr    %cl,%eax
f01047ec:	89 e9                	mov    %ebp,%ecx
f01047ee:	d3 e2                	shl    %cl,%edx
f01047f0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01047f5:	09 d0                	or     %edx,%eax
f01047f7:	89 f2                	mov    %esi,%edx
f01047f9:	d3 ea                	shr    %cl,%edx
f01047fb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01047ff:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104803:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104807:	83 c4 1c             	add    $0x1c,%esp
f010480a:	c3                   	ret    
f010480b:	90                   	nop
f010480c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104810:	39 d6                	cmp    %edx,%esi
f0104812:	75 c7                	jne    f01047db <__umoddi3+0x11b>
f0104814:	89 d7                	mov    %edx,%edi
f0104816:	89 c1                	mov    %eax,%ecx
f0104818:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010481c:	1b 3c 24             	sbb    (%esp),%edi
f010481f:	eb ba                	jmp    f01047db <__umoddi3+0x11b>
f0104821:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104828:	39 f5                	cmp    %esi,%ebp
f010482a:	0f 82 f1 fe ff ff    	jb     f0104721 <__umoddi3+0x61>
f0104830:	e9 f8 fe ff ff       	jmp    f010472d <__umoddi3+0x6d>
