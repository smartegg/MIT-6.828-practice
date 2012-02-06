
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# physical addresses [0, 4MB).  This 4MB region will be suffice
	# until we set up our real page table in mem_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 50 11 00       	mov    $0x115000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 50 11 f0       	mov    $0xf0115000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 8c 79 11 f0       	mov    $0xf011798c,%eax
f010004b:	2d 00 73 11 f0       	sub    $0xf0117300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 73 11 f0 	movl   $0xf0117300,(%esp)
f0100063:	e8 fe 38 00 00       	call   f0103966 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 8f 04 00 00       	call   f01004fc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 3e 10 f0 	movl   $0xf0103e80,(%esp)
f010007c:	e8 a9 2d 00 00       	call   f0102e2a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 9f 12 00 00       	call   f0101325 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 46 07 00 00       	call   f01007d8 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 00 73 11 f0 00 	cmpl   $0x0,0xf0117300
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 00 73 11 f0    	mov    %esi,0xf0117300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 9b 3e 10 f0 	movl   $0xf0103e9b,(%esp)
f01000c8:	e8 5d 2d 00 00       	call   f0102e2a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 1e 2d 00 00       	call   f0102df7 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 b6 4d 10 f0 	movl   $0xf0104db6,(%esp)
f01000e0:	e8 45 2d 00 00       	call   f0102e2a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 e7 06 00 00       	call   f01007d8 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 b3 3e 10 f0 	movl   $0xf0103eb3,(%esp)
f0100112:	e8 13 2d 00 00       	call   f0102e2a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 d1 2c 00 00       	call   f0102df7 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 b6 4d 10 f0 	movl   $0xf0104db6,(%esp)
f010012d:	e8 f8 2c 00 00       	call   f0102e2a <cprintf>
	va_end(ap);
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
f0100179:	8b 15 44 75 11 f0    	mov    0xf0117544,%edx
f010017f:	88 82 40 73 11 f0    	mov    %al,-0xfee8cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 75 11 f0       	mov    %eax,0xf0117544
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
f0100262:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f0100269:	66 85 c0             	test   %ax,%ax
f010026c:	0f 84 e4 00 00 00    	je     f0100356 <cons_putc+0x1af>
			crt_pos--;
f0100272:	83 e8 01             	sub    $0x1,%eax
f0100275:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010027b:	0f b7 c0             	movzwl %ax,%eax
f010027e:	66 81 e7 00 ff       	and    $0xff00,%di
f0100283:	83 cf 20             	or     $0x20,%edi
f0100286:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f010028c:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100290:	eb 77                	jmp    f0100309 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100292:	66 83 05 54 75 11 f0 	addw   $0x50,0xf0117554
f0100299:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f010029a:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002a1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002a7:	c1 e8 16             	shr    $0x16,%eax
f01002aa:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ad:	c1 e0 04             	shl    $0x4,%eax
f01002b0:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
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
f01002ec:	0f b7 05 54 75 11 f0 	movzwl 0xf0117554,%eax
f01002f3:	0f b7 c8             	movzwl %ax,%ecx
f01002f6:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
f01002fc:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100300:	83 c0 01             	add    $0x1,%eax
f0100303:	66 a3 54 75 11 f0    	mov    %ax,0xf0117554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100309:	66 81 3d 54 75 11 f0 	cmpw   $0x7cf,0xf0117554
f0100310:	cf 07 
f0100312:	76 42                	jbe    f0100356 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100314:	a1 50 75 11 f0       	mov    0xf0117550,%eax
f0100319:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100320:	00 
f0100321:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100327:	89 54 24 04          	mov    %edx,0x4(%esp)
f010032b:	89 04 24             	mov    %eax,(%esp)
f010032e:	e8 8e 36 00 00       	call   f01039c1 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100333:	8b 15 50 75 11 f0    	mov    0xf0117550,%edx
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
f010034e:	66 83 2d 54 75 11 f0 	subw   $0x50,0xf0117554
f0100355:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100356:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
f010035c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100364:	0f b7 35 54 75 11 f0 	movzwl 0xf0117554,%esi
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
f01003af:	83 0d 48 75 11 f0 40 	orl    $0x40,0xf0117548
		return 0;
f01003b6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003bb:	e9 c4 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003c0:	84 c0                	test   %al,%al
f01003c2:	79 37                	jns    f01003fb <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003c4:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f01003ca:	89 cb                	mov    %ecx,%ebx
f01003cc:	83 e3 40             	and    $0x40,%ebx
f01003cf:	83 e0 7f             	and    $0x7f,%eax
f01003d2:	85 db                	test   %ebx,%ebx
f01003d4:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003d7:	0f b6 d2             	movzbl %dl,%edx
f01003da:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f01003e1:	83 c8 40             	or     $0x40,%eax
f01003e4:	0f b6 c0             	movzbl %al,%eax
f01003e7:	f7 d0                	not    %eax
f01003e9:	21 c1                	and    %eax,%ecx
f01003eb:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
		return 0;
f01003f1:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f6:	e9 89 00 00 00       	jmp    f0100484 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003fb:	8b 0d 48 75 11 f0    	mov    0xf0117548,%ecx
f0100401:	f6 c1 40             	test   $0x40,%cl
f0100404:	74 0e                	je     f0100414 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100406:	89 c2                	mov    %eax,%edx
f0100408:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010040b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010040e:	89 0d 48 75 11 f0    	mov    %ecx,0xf0117548
	}

	shift |= shiftcode[data];
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 00 3f 10 f0 	movzbl -0xfefc100(%edx),%eax
f010041e:	0b 05 48 75 11 f0    	or     0xf0117548,%eax
	shift ^= togglecode[data];
f0100424:	0f b6 8a 00 40 10 f0 	movzbl -0xfefc000(%edx),%ecx
f010042b:	31 c8                	xor    %ecx,%eax
f010042d:	a3 48 75 11 f0       	mov    %eax,0xf0117548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100432:	89 c1                	mov    %eax,%ecx
f0100434:	83 e1 03             	and    $0x3,%ecx
f0100437:	8b 0c 8d 00 41 10 f0 	mov    -0xfefbf00(,%ecx,4),%ecx
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
f010046d:	c7 04 24 cd 3e 10 f0 	movl   $0xf0103ecd,(%esp)
f0100474:	e8 b1 29 00 00       	call   f0102e2a <cprintf>
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
f0100492:	83 3d 20 73 11 f0 00 	cmpl   $0x0,0xf0117320
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
f01004c9:	8b 15 40 75 11 f0    	mov    0xf0117540,%edx
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
f01004d4:	3b 15 44 75 11 f0    	cmp    0xf0117544,%edx
f01004da:	74 1e                	je     f01004fa <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004dc:	0f b6 82 40 73 11 f0 	movzbl -0xfee8cc0(%edx),%eax
f01004e3:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004e6:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004ec:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f1:	0f 44 d1             	cmove  %ecx,%edx
f01004f4:	89 15 40 75 11 f0    	mov    %edx,0xf0117540
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
f0100522:	c7 05 4c 75 11 f0 b4 	movl   $0x3b4,0xf011754c
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
f010053a:	c7 05 4c 75 11 f0 d4 	movl   $0x3d4,0xf011754c
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
f0100549:	8b 0d 4c 75 11 f0    	mov    0xf011754c,%ecx
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
f010056e:	89 35 50 75 11 f0    	mov    %esi,0xf0117550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100574:	0f b6 d8             	movzbl %al,%ebx
f0100577:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100579:	66 89 3d 54 75 11 f0 	mov    %di,0xf0117554
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
f01005cf:	a3 20 73 11 f0       	mov    %eax,0xf0117320
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
f01005de:	c7 04 24 d9 3e 10 f0 	movl   $0xf0103ed9,(%esp)
f01005e5:	e8 40 28 00 00       	call   f0102e2a <cprintf>
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
f0100626:	c7 04 24 10 41 10 f0 	movl   $0xf0104110,(%esp)
f010062d:	e8 f8 27 00 00       	call   f0102e2a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100632:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100639:	00 
f010063a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100641:	f0 
f0100642:	c7 04 24 d0 41 10 f0 	movl   $0xf01041d0,(%esp)
f0100649:	e8 dc 27 00 00       	call   f0102e2a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010064e:	c7 44 24 08 65 3e 10 	movl   $0x103e65,0x8(%esp)
f0100655:	00 
f0100656:	c7 44 24 04 65 3e 10 	movl   $0xf0103e65,0x4(%esp)
f010065d:	f0 
f010065e:	c7 04 24 f4 41 10 f0 	movl   $0xf01041f4,(%esp)
f0100665:	e8 c0 27 00 00       	call   f0102e2a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010066a:	c7 44 24 08 00 73 11 	movl   $0x117300,0x8(%esp)
f0100671:	00 
f0100672:	c7 44 24 04 00 73 11 	movl   $0xf0117300,0x4(%esp)
f0100679:	f0 
f010067a:	c7 04 24 18 42 10 f0 	movl   $0xf0104218,(%esp)
f0100681:	e8 a4 27 00 00       	call   f0102e2a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100686:	c7 44 24 08 8c 79 11 	movl   $0x11798c,0x8(%esp)
f010068d:	00 
f010068e:	c7 44 24 04 8c 79 11 	movl   $0xf011798c,0x4(%esp)
f0100695:	f0 
f0100696:	c7 04 24 3c 42 10 f0 	movl   $0xf010423c,(%esp)
f010069d:	e8 88 27 00 00       	call   f0102e2a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006a2:	b8 8b 7d 11 f0       	mov    $0xf0117d8b,%eax
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
f01006be:	c7 04 24 60 42 10 f0 	movl   $0xf0104260,(%esp)
f01006c5:	e8 60 27 00 00       	call   f0102e2a <cprintf>
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
f01006dd:	8b 83 64 43 10 f0    	mov    -0xfefbc9c(%ebx),%eax
f01006e3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01006e7:	8b 83 60 43 10 f0    	mov    -0xfefbca0(%ebx),%eax
f01006ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006f1:	c7 04 24 29 41 10 f0 	movl   $0xf0104129,(%esp)
f01006f8:	e8 2d 27 00 00       	call   f0102e2a <cprintf>
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
f010071d:	c7 04 24 32 41 10 f0 	movl   $0xf0104132,(%esp)
f0100724:	e8 01 27 00 00       	call   f0102e2a <cprintf>
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
f0100759:	e8 c6 27 00 00       	call   f0102f24 <debuginfo_eip>

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
f0100786:	c7 04 24 8c 42 10 f0 	movl   $0xf010428c,(%esp)
f010078d:	e8 98 26 00 00       	call   f0102e2a <cprintf>
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
f01007b5:	c7 04 24 44 41 10 f0 	movl   $0xf0104144,(%esp)
f01007bc:	e8 69 26 00 00       	call   f0102e2a <cprintf>
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
f01007e1:	c7 04 24 c4 42 10 f0 	movl   $0xf01042c4,(%esp)
f01007e8:	e8 3d 26 00 00       	call   f0102e2a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007ed:	c7 04 24 e8 42 10 f0 	movl   $0xf01042e8,(%esp)
f01007f4:	e8 31 26 00 00       	call   f0102e2a <cprintf>


	while (1) {
		buf = readline("K> ");
f01007f9:	c7 04 24 5d 41 10 f0 	movl   $0xf010415d,(%esp)
f0100800:	e8 db 2e 00 00       	call   f01036e0 <readline>
f0100805:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100807:	85 c0                	test   %eax,%eax
f0100809:	74 ee                	je     f01007f9 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010080b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100812:	be 00 00 00 00       	mov    $0x0,%esi
f0100817:	eb 06                	jmp    f010081f <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100819:	c6 03 00             	movb   $0x0,(%ebx)
f010081c:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010081f:	0f b6 03             	movzbl (%ebx),%eax
f0100822:	84 c0                	test   %al,%al
f0100824:	74 6a                	je     f0100890 <monitor+0xb8>
f0100826:	0f be c0             	movsbl %al,%eax
f0100829:	89 44 24 04          	mov    %eax,0x4(%esp)
f010082d:	c7 04 24 61 41 10 f0 	movl   $0xf0104161,(%esp)
f0100834:	e8 d2 30 00 00       	call   f010390b <strchr>
f0100839:	85 c0                	test   %eax,%eax
f010083b:	75 dc                	jne    f0100819 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010083d:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100840:	74 4e                	je     f0100890 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100842:	83 fe 0f             	cmp    $0xf,%esi
f0100845:	75 16                	jne    f010085d <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100847:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010084e:	00 
f010084f:	c7 04 24 66 41 10 f0 	movl   $0xf0104166,(%esp)
f0100856:	e8 cf 25 00 00       	call   f0102e2a <cprintf>
f010085b:	eb 9c                	jmp    f01007f9 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010085d:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100861:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100864:	0f b6 03             	movzbl (%ebx),%eax
f0100867:	84 c0                	test   %al,%al
f0100869:	75 0c                	jne    f0100877 <monitor+0x9f>
f010086b:	eb b2                	jmp    f010081f <monitor+0x47>
			buf++;
f010086d:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100870:	0f b6 03             	movzbl (%ebx),%eax
f0100873:	84 c0                	test   %al,%al
f0100875:	74 a8                	je     f010081f <monitor+0x47>
f0100877:	0f be c0             	movsbl %al,%eax
f010087a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010087e:	c7 04 24 61 41 10 f0 	movl   $0xf0104161,(%esp)
f0100885:	e8 81 30 00 00       	call   f010390b <strchr>
f010088a:	85 c0                	test   %eax,%eax
f010088c:	74 df                	je     f010086d <monitor+0x95>
f010088e:	eb 8f                	jmp    f010081f <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100890:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100897:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100898:	85 f6                	test   %esi,%esi
f010089a:	0f 84 59 ff ff ff    	je     f01007f9 <monitor+0x21>
f01008a0:	bb 60 43 10 f0       	mov    $0xf0104360,%ebx
f01008a5:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008aa:	8b 03                	mov    (%ebx),%eax
f01008ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b0:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008b3:	89 04 24             	mov    %eax,(%esp)
f01008b6:	e8 d5 2f 00 00       	call   f0103890 <strcmp>
f01008bb:	85 c0                	test   %eax,%eax
f01008bd:	75 24                	jne    f01008e3 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01008bf:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01008c2:	8b 55 08             	mov    0x8(%ebp),%edx
f01008c5:	89 54 24 08          	mov    %edx,0x8(%esp)
f01008c9:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008cc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008d0:	89 34 24             	mov    %esi,(%esp)
f01008d3:	ff 14 85 68 43 10 f0 	call   *-0xfefbc98(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008da:	85 c0                	test   %eax,%eax
f01008dc:	78 28                	js     f0100906 <monitor+0x12e>
f01008de:	e9 16 ff ff ff       	jmp    f01007f9 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008e3:	83 c7 01             	add    $0x1,%edi
f01008e6:	83 c3 0c             	add    $0xc,%ebx
f01008e9:	83 ff 03             	cmp    $0x3,%edi
f01008ec:	75 bc                	jne    f01008aa <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008ee:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f5:	c7 04 24 83 41 10 f0 	movl   $0xf0104183,(%esp)
f01008fc:	e8 29 25 00 00       	call   f0102e2a <cprintf>
f0100901:	e9 f3 fe ff ff       	jmp    f01007f9 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100906:	83 c4 5c             	add    $0x5c,%esp
f0100909:	5b                   	pop    %ebx
f010090a:	5e                   	pop    %esi
f010090b:	5f                   	pop    %edi
f010090c:	5d                   	pop    %ebp
f010090d:	c3                   	ret    

f010090e <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010090e:	55                   	push   %ebp
f010090f:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100911:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100914:	5d                   	pop    %ebp
f0100915:	c3                   	ret    
	...

f0100918 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100918:	55                   	push   %ebp
f0100919:	89 e5                	mov    %esp,%ebp
f010091b:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010091e:	89 d1                	mov    %edx,%ecx
f0100920:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100923:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100926:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010092b:	f6 c1 01             	test   $0x1,%cl
f010092e:	74 57                	je     f0100987 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100930:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100936:	89 c8                	mov    %ecx,%eax
f0100938:	c1 e8 0c             	shr    $0xc,%eax
f010093b:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0100941:	72 20                	jb     f0100963 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100943:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100947:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f010094e:	f0 
f010094f:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f0100956:	00 
f0100957:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010095e:	e8 31 f7 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100963:	c1 ea 0c             	shr    $0xc,%edx
f0100966:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010096c:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100973:	89 c2                	mov    %eax,%edx
f0100975:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100978:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010097d:	85 d2                	test   %edx,%edx
f010097f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100984:	0f 44 c2             	cmove  %edx,%eax
}
f0100987:	c9                   	leave  
f0100988:	c3                   	ret    

f0100989 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100989:	55                   	push   %ebp
f010098a:	89 e5                	mov    %esp,%ebp
f010098c:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f010098f:	83 3d 5c 75 11 f0 00 	cmpl   $0x0,0xf011755c
f0100996:	75 11                	jne    f01009a9 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100998:	ba 8b 89 11 f0       	mov    $0xf011898b,%edx
f010099d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009a3:	89 15 5c 75 11 f0    	mov    %edx,0xf011755c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    assert((uint32_t)nextfree % PGSIZE == 0);
f01009a9:	8b 15 5c 75 11 f0    	mov    0xf011755c,%edx
f01009af:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01009b5:	74 24                	je     f01009db <boot_alloc+0x52>
f01009b7:	c7 44 24 0c a8 43 10 	movl   $0xf01043a8,0xc(%esp)
f01009be:	f0 
f01009bf:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01009c6:	f0 
f01009c7:	c7 44 24 04 65 00 00 	movl   $0x65,0x4(%esp)
f01009ce:	00 
f01009cf:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01009d6:	e8 b9 f6 ff ff       	call   f0100094 <_panic>
    result = nextfree;
    nextfree += n;
    nextfree = ROUNDUP(nextfree, PGSIZE);
f01009db:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f01009e2:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009e7:	a3 5c 75 11 f0       	mov    %eax,0xf011755c

	return result;
}
f01009ec:	89 d0                	mov    %edx,%eax
f01009ee:	c9                   	leave  
f01009ef:	c3                   	ret    

f01009f0 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01009f0:	55                   	push   %ebp
f01009f1:	89 e5                	mov    %esp,%ebp
f01009f3:	83 ec 18             	sub    $0x18,%esp
f01009f6:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01009f9:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01009fc:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01009fe:	89 04 24             	mov    %eax,(%esp)
f0100a01:	e8 b6 23 00 00       	call   f0102dbc <mc146818_read>
f0100a06:	89 c6                	mov    %eax,%esi
f0100a08:	83 c3 01             	add    $0x1,%ebx
f0100a0b:	89 1c 24             	mov    %ebx,(%esp)
f0100a0e:	e8 a9 23 00 00       	call   f0102dbc <mc146818_read>
f0100a13:	c1 e0 08             	shl    $0x8,%eax
f0100a16:	09 f0                	or     %esi,%eax
}
f0100a18:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a1b:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a1e:	89 ec                	mov    %ebp,%esp
f0100a20:	5d                   	pop    %ebp
f0100a21:	c3                   	ret    

f0100a22 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a22:	55                   	push   %ebp
f0100a23:	89 e5                	mov    %esp,%ebp
f0100a25:	57                   	push   %edi
f0100a26:	56                   	push   %esi
f0100a27:	53                   	push   %ebx
f0100a28:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a2b:	83 f8 01             	cmp    $0x1,%eax
f0100a2e:	19 f6                	sbb    %esi,%esi
f0100a30:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a36:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a39:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100a3f:	85 db                	test   %ebx,%ebx
f0100a41:	75 1c                	jne    f0100a5f <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a43:	c7 44 24 08 cc 43 10 	movl   $0xf01043cc,0x8(%esp)
f0100a4a:	f0 
f0100a4b:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100a52:	00 
f0100a53:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100a5a:	e8 35 f6 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100a5f:	85 c0                	test   %eax,%eax
f0100a61:	74 50                	je     f0100ab3 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100a63:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100a66:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100a69:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100a6c:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100a6f:	89 d8                	mov    %ebx,%eax
f0100a71:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100a77:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100a7a:	c1 e8 16             	shr    $0x16,%eax
f0100a7d:	39 f0                	cmp    %esi,%eax
f0100a7f:	0f 93 c0             	setae  %al
f0100a82:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100a85:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100a89:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100a8b:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a8f:	8b 1b                	mov    (%ebx),%ebx
f0100a91:	85 db                	test   %ebx,%ebx
f0100a93:	75 da                	jne    f0100a6f <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100a95:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100a98:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100a9e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100aa1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100aa4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100aa6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100aa9:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aaf:	85 db                	test   %ebx,%ebx
f0100ab1:	74 67                	je     f0100b1a <check_page_free_list+0xf8>
f0100ab3:	89 d8                	mov    %ebx,%eax
f0100ab5:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100abb:	c1 f8 03             	sar    $0x3,%eax
f0100abe:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ac1:	89 c2                	mov    %eax,%edx
f0100ac3:	c1 ea 16             	shr    $0x16,%edx
f0100ac6:	39 f2                	cmp    %esi,%edx
f0100ac8:	73 4a                	jae    f0100b14 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100aca:	89 c2                	mov    %eax,%edx
f0100acc:	c1 ea 0c             	shr    $0xc,%edx
f0100acf:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100ad5:	72 20                	jb     f0100af7 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ad7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100adb:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0100ae2:	f0 
f0100ae3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100aea:	00 
f0100aeb:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0100af2:	e8 9d f5 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100af7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100afe:	00 
f0100aff:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b06:	00 
	return (void *)(pa + KERNBASE);
f0100b07:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b0c:	89 04 24             	mov    %eax,(%esp)
f0100b0f:	e8 52 2e 00 00       	call   f0103966 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b14:	8b 1b                	mov    (%ebx),%ebx
f0100b16:	85 db                	test   %ebx,%ebx
f0100b18:	75 99                	jne    f0100ab3 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b1f:	e8 65 fe ff ff       	call   f0100989 <boot_alloc>
f0100b24:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b27:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100b2d:	85 d2                	test   %edx,%edx
f0100b2f:	0f 84 f6 01 00 00    	je     f0100d2b <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b35:	8b 1d 88 79 11 f0    	mov    0xf0117988,%ebx
f0100b3b:	39 da                	cmp    %ebx,%edx
f0100b3d:	72 4d                	jb     f0100b8c <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b3f:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0100b44:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b47:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b4a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b4d:	39 c2                	cmp    %eax,%edx
f0100b4f:	73 64                	jae    f0100bb5 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b51:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b54:	89 d0                	mov    %edx,%eax
f0100b56:	29 d8                	sub    %ebx,%eax
f0100b58:	a8 07                	test   $0x7,%al
f0100b5a:	0f 85 82 00 00 00    	jne    f0100be2 <check_page_free_list+0x1c0>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b60:	c1 f8 03             	sar    $0x3,%eax
f0100b63:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100b66:	85 c0                	test   %eax,%eax
f0100b68:	0f 84 a2 00 00 00    	je     f0100c10 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b6e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b73:	0f 84 c2 00 00 00    	je     f0100c3b <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	int pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100b79:	be 00 00 00 00       	mov    $0x0,%esi
f0100b7e:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b83:	e9 d7 00 00 00       	jmp    f0100c5f <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b88:	39 da                	cmp    %ebx,%edx
f0100b8a:	73 24                	jae    f0100bb0 <check_page_free_list+0x18e>
f0100b8c:	c7 44 24 0c e7 4a 10 	movl   $0xf0104ae7,0xc(%esp)
f0100b93:	f0 
f0100b94:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100b9b:	f0 
f0100b9c:	c7 44 24 04 50 02 00 	movl   $0x250,0x4(%esp)
f0100ba3:	00 
f0100ba4:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100bab:	e8 e4 f4 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100bb0:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bb3:	72 24                	jb     f0100bd9 <check_page_free_list+0x1b7>
f0100bb5:	c7 44 24 0c f3 4a 10 	movl   $0xf0104af3,0xc(%esp)
f0100bbc:	f0 
f0100bbd:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100bc4:	f0 
f0100bc5:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f0100bcc:	00 
f0100bcd:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100bd4:	e8 bb f4 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100bd9:	89 d0                	mov    %edx,%eax
f0100bdb:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100bde:	a8 07                	test   $0x7,%al
f0100be0:	74 24                	je     f0100c06 <check_page_free_list+0x1e4>
f0100be2:	c7 44 24 0c f0 43 10 	movl   $0xf01043f0,0xc(%esp)
f0100be9:	f0 
f0100bea:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100bf1:	f0 
f0100bf2:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100bf9:	00 
f0100bfa:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100c01:	e8 8e f4 ff ff       	call   f0100094 <_panic>
f0100c06:	c1 f8 03             	sar    $0x3,%eax
f0100c09:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c0c:	85 c0                	test   %eax,%eax
f0100c0e:	75 24                	jne    f0100c34 <check_page_free_list+0x212>
f0100c10:	c7 44 24 0c 07 4b 10 	movl   $0xf0104b07,0xc(%esp)
f0100c17:	f0 
f0100c18:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100c1f:	f0 
f0100c20:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0100c27:	00 
f0100c28:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100c2f:	e8 60 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c34:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c39:	75 24                	jne    f0100c5f <check_page_free_list+0x23d>
f0100c3b:	c7 44 24 0c 18 4b 10 	movl   $0xf0104b18,0xc(%esp)
f0100c42:	f0 
f0100c43:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100c4a:	f0 
f0100c4b:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0100c52:	00 
f0100c53:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100c5a:	e8 35 f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c5f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100c64:	75 24                	jne    f0100c8a <check_page_free_list+0x268>
f0100c66:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0100c6d:	f0 
f0100c6e:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100c75:	f0 
f0100c76:	c7 44 24 04 57 02 00 	movl   $0x257,0x4(%esp)
f0100c7d:	00 
f0100c7e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100c85:	e8 0a f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100c8a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100c8f:	75 24                	jne    f0100cb5 <check_page_free_list+0x293>
f0100c91:	c7 44 24 0c 31 4b 10 	movl   $0xf0104b31,0xc(%esp)
f0100c98:	f0 
f0100c99:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100ca0:	f0 
f0100ca1:	c7 44 24 04 58 02 00 	movl   $0x258,0x4(%esp)
f0100ca8:	00 
f0100ca9:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100cb0:	e8 df f3 ff ff       	call   f0100094 <_panic>
f0100cb5:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cb7:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cbc:	76 57                	jbe    f0100d15 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cbe:	c1 e8 0c             	shr    $0xc,%eax
f0100cc1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100cc4:	77 20                	ja     f0100ce6 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cc6:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100cca:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0100cd1:	f0 
f0100cd2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100cd9:	00 
f0100cda:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0100ce1:	e8 ae f3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100ce6:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100cec:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100cef:	76 29                	jbe    f0100d1a <check_page_free_list+0x2f8>
f0100cf1:	c7 44 24 0c 48 44 10 	movl   $0xf0104448,0xc(%esp)
f0100cf8:	f0 
f0100cf9:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100d00:	f0 
f0100d01:	c7 44 24 04 59 02 00 	movl   $0x259,0x4(%esp)
f0100d08:	00 
f0100d09:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100d10:	e8 7f f3 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d15:	83 c7 01             	add    $0x1,%edi
f0100d18:	eb 03                	jmp    f0100d1d <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d1a:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d1d:	8b 12                	mov    (%edx),%edx
f0100d1f:	85 d2                	test   %edx,%edx
f0100d21:	0f 85 61 fe ff ff    	jne    f0100b88 <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d27:	85 ff                	test   %edi,%edi
f0100d29:	7f 24                	jg     f0100d4f <check_page_free_list+0x32d>
f0100d2b:	c7 44 24 0c 4b 4b 10 	movl   $0xf0104b4b,0xc(%esp)
f0100d32:	f0 
f0100d33:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100d3a:	f0 
f0100d3b:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f0100d42:	00 
f0100d43:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100d4a:	e8 45 f3 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100d4f:	85 f6                	test   %esi,%esi
f0100d51:	7f 24                	jg     f0100d77 <check_page_free_list+0x355>
f0100d53:	c7 44 24 0c 5d 4b 10 	movl   $0xf0104b5d,0xc(%esp)
f0100d5a:	f0 
f0100d5b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100d62:	f0 
f0100d63:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0100d6a:	00 
f0100d6b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100d72:	e8 1d f3 ff ff       	call   f0100094 <_panic>
}
f0100d77:	83 c4 3c             	add    $0x3c,%esp
f0100d7a:	5b                   	pop    %ebx
f0100d7b:	5e                   	pop    %esi
f0100d7c:	5f                   	pop    %edi
f0100d7d:	5d                   	pop    %ebp
f0100d7e:	c3                   	ret    

f0100d7f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100d7f:	55                   	push   %ebp
f0100d80:	89 e5                	mov    %esp,%ebp
f0100d82:	57                   	push   %edi
f0100d83:	56                   	push   %esi
f0100d84:	53                   	push   %ebx
f0100d85:	83 ec 1c             	sub    $0x1c,%esp
	// free pages!
	size_t i;
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
f0100d88:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0100d8f:	00 00 00 
    first_free_page = (char *) boot_alloc(0);
f0100d92:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d97:	e8 ed fb ff ff       	call   f0100989 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100d9c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100da1:	77 20                	ja     f0100dc3 <page_init+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100da3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100da7:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f0100dae:	f0 
f0100daf:	c7 44 24 04 0b 01 00 	movl   $0x10b,0x4(%esp)
f0100db6:	00 
f0100db7:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100dbe:	e8 d1 f2 ff ff       	call   f0100094 <_panic>
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
f0100dc3:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
f0100dc9:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
    for (i = 1; i < npages_basemem; i++) {
f0100dcf:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
f0100dd5:	83 fa 01             	cmp    $0x1,%edx
f0100dd8:	76 37                	jbe    f0100e11 <page_init+0x92>
f0100dda:	8b 3d 60 75 11 f0    	mov    0xf0117560,%edi
f0100de0:	b9 01 00 00 00       	mov    $0x1,%ecx
        pages[i].pp_ref = 0;
f0100de5:	8d 1c cd 00 00 00 00 	lea    0x0(,%ecx,8),%ebx
f0100dec:	8b 35 88 79 11 f0    	mov    0xf0117988,%esi
f0100df2:	66 c7 44 1e 04 00 00 	movw   $0x0,0x4(%esi,%ebx,1)
		pages[i].pp_link = page_free_list;
f0100df9:	89 3c ce             	mov    %edi,(%esi,%ecx,8)
		page_free_list = &pages[i];
f0100dfc:	89 df                	mov    %ebx,%edi
f0100dfe:	03 3d 88 79 11 f0    	add    0xf0117988,%edi
    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
    for (i = 1; i < npages_basemem; i++) {
f0100e04:	83 c1 01             	add    $0x1,%ecx
f0100e07:	39 d1                	cmp    %edx,%ecx
f0100e09:	72 da                	jb     f0100de5 <page_init+0x66>
f0100e0b:	89 3d 60 75 11 f0    	mov    %edi,0xf0117560
        pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);
f0100e11:	89 d1                	mov    %edx,%ecx
f0100e13:	c1 e1 0c             	shl    $0xc,%ecx
f0100e16:	81 f9 00 00 0a 00    	cmp    $0xa0000,%ecx
f0100e1c:	74 24                	je     f0100e42 <page_init+0xc3>
f0100e1e:	c7 44 24 0c b4 44 10 	movl   $0xf01044b4,0xc(%esp)
f0100e25:	f0 
f0100e26:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0100e2d:	f0 
f0100e2e:	c7 44 24 04 14 01 00 	movl   $0x114,0x4(%esp)
f0100e35:	00 
f0100e36:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100e3d:	e8 52 f2 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e42:	05 00 00 00 10       	add    $0x10000000,%eax
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;
f0100e47:	c1 e8 0c             	shr    $0xc,%eax
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e4a:	39 d0                	cmp    %edx,%eax
f0100e4c:	76 14                	jbe    f0100e62 <page_init+0xe3>
        pages[i].pp_ref = 1;
f0100e4e:	8b 0d 88 79 11 f0    	mov    0xf0117988,%ecx
f0100e54:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e5b:	83 c2 01             	add    $0x1,%edx
f0100e5e:	39 d0                	cmp    %edx,%eax
f0100e60:	77 f2                	ja     f0100e54 <page_init+0xd5>
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100e62:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0100e68:	73 39                	jae    f0100ea3 <page_init+0x124>
f0100e6a:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100e70:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100e77:	8b 0d 88 79 11 f0    	mov    0xf0117988,%ecx
f0100e7d:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100e84:	89 1c 11             	mov    %ebx,(%ecx,%edx,1)
		page_free_list = &pages[i];
f0100e87:	89 d3                	mov    %edx,%ebx
f0100e89:	03 1d 88 79 11 f0    	add    0xf0117988,%ebx
    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100e8f:	83 c0 01             	add    $0x1,%eax
f0100e92:	83 c2 08             	add    $0x8,%edx
f0100e95:	39 05 80 79 11 f0    	cmp    %eax,0xf0117980
f0100e9b:	77 da                	ja     f0100e77 <page_init+0xf8>
f0100e9d:	89 1d 60 75 11 f0    	mov    %ebx,0xf0117560
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f0100ea3:	83 c4 1c             	add    $0x1c,%esp
f0100ea6:	5b                   	pop    %ebx
f0100ea7:	5e                   	pop    %esi
f0100ea8:	5f                   	pop    %edi
f0100ea9:	5d                   	pop    %ebp
f0100eaa:	c3                   	ret    

f0100eab <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100eab:	55                   	push   %ebp
f0100eac:	89 e5                	mov    %esp,%ebp
f0100eae:	53                   	push   %ebx
f0100eaf:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
    struct Page* pg;
    if (page_free_list == NULL)
f0100eb2:	8b 1d 60 75 11 f0    	mov    0xf0117560,%ebx
f0100eb8:	85 db                	test   %ebx,%ebx
f0100eba:	74 65                	je     f0100f21 <page_alloc+0x76>
        return NULL;
    pg = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100ebc:	8b 03                	mov    (%ebx),%eax
f0100ebe:	a3 60 75 11 f0       	mov    %eax,0xf0117560

    if (alloc_flags & ALLOC_ZERO) {
f0100ec3:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100ec7:	74 58                	je     f0100f21 <page_alloc+0x76>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ec9:	89 d8                	mov    %ebx,%eax
f0100ecb:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0100ed1:	c1 f8 03             	sar    $0x3,%eax
f0100ed4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ed7:	89 c2                	mov    %eax,%edx
f0100ed9:	c1 ea 0c             	shr    $0xc,%edx
f0100edc:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100ee2:	72 20                	jb     f0100f04 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ee8:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0100eef:	f0 
f0100ef0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100ef7:	00 
f0100ef8:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0100eff:	e8 90 f1 ff ff       	call   f0100094 <_panic>
        memset(page2kva(pg), 0, PGSIZE);
f0100f04:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f0b:	00 
f0100f0c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f13:	00 
	return (void *)(pa + KERNBASE);
f0100f14:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f19:	89 04 24             	mov    %eax,(%esp)
f0100f1c:	e8 45 2a 00 00       	call   f0103966 <memset>
    }
    return pg;
}
f0100f21:	89 d8                	mov    %ebx,%eax
f0100f23:	83 c4 14             	add    $0x14,%esp
f0100f26:	5b                   	pop    %ebx
f0100f27:	5d                   	pop    %ebp
f0100f28:	c3                   	ret    

f0100f29 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f29:	55                   	push   %ebp
f0100f2a:	89 e5                	mov    %esp,%ebp
f0100f2c:	83 ec 18             	sub    $0x18,%esp
f0100f2f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
    if (pp->pp_ref != 0) {
f0100f32:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f37:	74 20                	je     f0100f59 <page_free+0x30>
        panic("page_free: %p pp_ref error\n", pp);
f0100f39:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f3d:	c7 44 24 08 6e 4b 10 	movl   $0xf0104b6e,0x8(%esp)
f0100f44:	f0 
f0100f45:	c7 44 24 04 43 01 00 	movl   $0x143,0x4(%esp)
f0100f4c:	00 
f0100f4d:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100f54:	e8 3b f1 ff ff       	call   f0100094 <_panic>
    }

    pp->pp_link = page_free_list;
f0100f59:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0100f5f:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;
f0100f61:	a3 60 75 11 f0       	mov    %eax,0xf0117560
}
f0100f66:	c9                   	leave  
f0100f67:	c3                   	ret    

f0100f68 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100f68:	55                   	push   %ebp
f0100f69:	89 e5                	mov    %esp,%ebp
f0100f6b:	83 ec 18             	sub    $0x18,%esp
f0100f6e:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100f71:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100f75:	83 ea 01             	sub    $0x1,%edx
f0100f78:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100f7c:	66 85 d2             	test   %dx,%dx
f0100f7f:	75 08                	jne    f0100f89 <page_decref+0x21>
		page_free(pp);
f0100f81:	89 04 24             	mov    %eax,(%esp)
f0100f84:	e8 a0 ff ff ff       	call   f0100f29 <page_free>
}
f0100f89:	c9                   	leave  
f0100f8a:	c3                   	ret    

f0100f8b <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100f8b:	55                   	push   %ebp
f0100f8c:	89 e5                	mov    %esp,%ebp
f0100f8e:	56                   	push   %esi
f0100f8f:	53                   	push   %ebx
f0100f90:	83 ec 10             	sub    $0x10,%esp
f0100f93:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f96:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
    if (pgdir == NULL) {
f0100f99:	85 c0                	test   %eax,%eax
f0100f9b:	75 1c                	jne    f0100fb9 <pgdir_walk+0x2e>
        panic("pgdir_walk: pgdir is null");
f0100f9d:	c7 44 24 08 8a 4b 10 	movl   $0xf0104b8a,0x8(%esp)
f0100fa4:	f0 
f0100fa5:	c7 44 24 04 70 01 00 	movl   $0x170,0x4(%esp)
f0100fac:	00 
f0100fad:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100fb4:	e8 db f0 ff ff       	call   f0100094 <_panic>
    }

    pde_t pde;
    pte_t* pt;

    pde = pgdir[PDX(va)];
f0100fb9:	89 f2                	mov    %esi,%edx
f0100fbb:	c1 ea 16             	shr    $0x16,%edx
f0100fbe:	8d 1c 90             	lea    (%eax,%edx,4),%ebx
f0100fc1:	8b 03                	mov    (%ebx),%eax

    if (pde & PTE_P) {
f0100fc3:	a8 01                	test   $0x1,%al
f0100fc5:	74 47                	je     f010100e <pgdir_walk+0x83>
        pt = KADDR(PTE_ADDR(pde));
f0100fc7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fcc:	89 c2                	mov    %eax,%edx
f0100fce:	c1 ea 0c             	shr    $0xc,%edx
f0100fd1:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0100fd7:	72 20                	jb     f0100ff9 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fdd:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0100fe4:	f0 
f0100fe5:	c7 44 24 04 79 01 00 	movl   $0x179,0x4(%esp)
f0100fec:	00 
f0100fed:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0100ff4:	e8 9b f0 ff ff       	call   f0100094 <_panic>
        return &pt[PTX(va)];
f0100ff9:	c1 ee 0a             	shr    $0xa,%esi
f0100ffc:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101002:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101009:	e9 85 00 00 00       	jmp    f0101093 <pgdir_walk+0x108>
    }

    if (!create) {
f010100e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101012:	74 73                	je     f0101087 <pgdir_walk+0xfc>
        return NULL;
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
f0101014:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010101b:	e8 8b fe ff ff       	call   f0100eab <page_alloc>
f0101020:	85 c0                	test   %eax,%eax
f0101022:	74 6a                	je     f010108e <pgdir_walk+0x103>
        return NULL;
    pp->pp_ref++;
f0101024:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101029:	89 c2                	mov    %eax,%edx
f010102b:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101031:	c1 fa 03             	sar    $0x3,%edx
f0101034:	c1 e2 0c             	shl    $0xc,%edx

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;
f0101037:	83 ca 07             	or     $0x7,%edx
f010103a:	89 13                	mov    %edx,(%ebx)
f010103c:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0101042:	c1 f8 03             	sar    $0x3,%eax
f0101045:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101048:	89 c2                	mov    %eax,%edx
f010104a:	c1 ea 0c             	shr    $0xc,%edx
f010104d:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0101053:	72 20                	jb     f0101075 <pgdir_walk+0xea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101055:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101059:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0101060:	f0 
f0101061:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101068:	00 
f0101069:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0101070:	e8 1f f0 ff ff       	call   f0100094 <_panic>


	return &((pte_t*) page2kva(pp))[PTX(va)];
f0101075:	c1 ee 0a             	shr    $0xa,%esi
f0101078:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010107e:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101085:	eb 0c                	jmp    f0101093 <pgdir_walk+0x108>
        pt = KADDR(PTE_ADDR(pde));
        return &pt[PTX(va)];
    }

    if (!create) {
        return NULL;
f0101087:	b8 00 00 00 00       	mov    $0x0,%eax
f010108c:	eb 05                	jmp    f0101093 <pgdir_walk+0x108>
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
        return NULL;
f010108e:	b8 00 00 00 00       	mov    $0x0,%eax

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;


	return &((pte_t*) page2kva(pp))[PTX(va)];
}
f0101093:	83 c4 10             	add    $0x10,%esp
f0101096:	5b                   	pop    %ebx
f0101097:	5e                   	pop    %esi
f0101098:	5d                   	pop    %ebp
f0101099:	c3                   	ret    

f010109a <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010109a:	55                   	push   %ebp
f010109b:	89 e5                	mov    %esp,%ebp
f010109d:	57                   	push   %edi
f010109e:	56                   	push   %esi
f010109f:	53                   	push   %ebx
f01010a0:	83 ec 2c             	sub    $0x2c,%esp
f01010a3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010a6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010a9:	89 cf                	mov    %ecx,%edi
f01010ab:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
    assert(size % PGSIZE == 0);
f01010ae:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01010b4:	75 14                	jne    f01010ca <boot_map_region+0x30>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010b6:	89 d3                	mov    %edx,%ebx
        }

        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
f01010b8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010bb:	83 c8 01             	or     $0x1,%eax
f01010be:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010c1:	85 c9                	test   %ecx,%ecx
f01010c3:	75 50                	jne    f0101115 <boot_map_region+0x7b>
f01010c5:	e9 c0 00 00 00       	jmp    f010118a <boot_map_region+0xf0>
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    assert(size % PGSIZE == 0);
f01010ca:	c7 44 24 0c a4 4b 10 	movl   $0xf0104ba4,0xc(%esp)
f01010d1:	f0 
f01010d2:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01010d9:	f0 
f01010da:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f01010e1:	00 
f01010e2:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01010e9:	e8 a6 ef ff ff       	call   f0100094 <_panic>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010ee:	81 c3 00 10 00 00    	add    $0x1000,%ebx
        if (va < start) { //  need overflow check?
f01010f4:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f01010f7:	76 1c                	jbe    f0101115 <boot_map_region+0x7b>
            panic("overflow\n");
f01010f9:	c7 44 24 08 b7 4b 10 	movl   $0xf0104bb7,0x8(%esp)
f0101100:	f0 
f0101101:	c7 44 24 04 a0 01 00 	movl   $0x1a0,0x4(%esp)
f0101108:	00 
f0101109:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101110:	e8 7f ef ff ff       	call   f0100094 <_panic>
            break;
        }

        if ((pte = pgdir_walk(pgdir, (void*) va, 1)) == NULL) {
f0101115:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010111c:	00 
f010111d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101121:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101124:	89 04 24             	mov    %eax,(%esp)
f0101127:	e8 5f fe ff ff       	call   f0100f8b <pgdir_walk>
f010112c:	85 c0                	test   %eax,%eax
f010112e:	75 1c                	jne    f010114c <boot_map_region+0xb2>
            panic("fail create\n");
f0101130:	c7 44 24 08 c1 4b 10 	movl   $0xf0104bc1,0x8(%esp)
f0101137:	f0 
f0101138:	c7 44 24 04 a5 01 00 	movl   $0x1a5,0x4(%esp)
f010113f:	00 
f0101140:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101147:	e8 48 ef ff ff       	call   f0100094 <_panic>
        }

        if (*pte & PTE_P) {
f010114c:	f6 00 01             	testb  $0x1,(%eax)
f010114f:	74 20                	je     f0101171 <boot_map_region+0xd7>
            panic("remapping %p\n", va);
f0101151:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101155:	c7 44 24 08 ce 4b 10 	movl   $0xf0104bce,0x8(%esp)
f010115c:	f0 
f010115d:	c7 44 24 04 a9 01 00 	movl   $0x1a9,0x4(%esp)
f0101164:	00 
f0101165:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010116c:	e8 23 ef ff ff       	call   f0100094 <_panic>
        }
        *pte = pa | perm | PTE_P;
f0101171:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101174:	09 f2                	or     %esi,%edx
f0101176:	89 10                	mov    %edx,(%eax)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f0101178:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010117e:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0101184:	0f 85 64 ff ff ff    	jne    f01010ee <boot_map_region+0x54>
        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
    }
}
f010118a:	83 c4 2c             	add    $0x2c,%esp
f010118d:	5b                   	pop    %ebx
f010118e:	5e                   	pop    %esi
f010118f:	5f                   	pop    %edi
f0101190:	5d                   	pop    %ebp
f0101191:	c3                   	ret    

f0101192 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101192:	55                   	push   %ebp
f0101193:	89 e5                	mov    %esp,%ebp
f0101195:	53                   	push   %ebx
f0101196:	83 ec 14             	sub    $0x14,%esp
f0101199:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f010119c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01011a3:	00 
f01011a4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011ab:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ae:	89 04 24             	mov    %eax,(%esp)
f01011b1:	e8 d5 fd ff ff       	call   f0100f8b <pgdir_walk>
f01011b6:	89 c2                	mov    %eax,%edx

    if (pte == NULL || !(*pte & PTE_P)) {
f01011b8:	85 c0                	test   %eax,%eax
f01011ba:	74 3e                	je     f01011fa <page_lookup+0x68>
f01011bc:	8b 00                	mov    (%eax),%eax
f01011be:	a8 01                	test   $0x1,%al
f01011c0:	74 3f                	je     f0101201 <page_lookup+0x6f>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011c2:	c1 e8 0c             	shr    $0xc,%eax
f01011c5:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01011cb:	72 1c                	jb     f01011e9 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01011cd:	c7 44 24 08 dc 44 10 	movl   $0xf01044dc,0x8(%esp)
f01011d4:	f0 
f01011d5:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01011dc:	00 
f01011dd:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f01011e4:	e8 ab ee ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01011e9:	c1 e0 03             	shl    $0x3,%eax
f01011ec:	03 05 88 79 11 f0    	add    0xf0117988,%eax
        return NULL;
    }
    
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
f01011f2:	85 db                	test   %ebx,%ebx
f01011f4:	74 10                	je     f0101206 <page_lookup+0x74>
        *pte_store = pte;
f01011f6:	89 13                	mov    %edx,(%ebx)
f01011f8:	eb 0c                	jmp    f0101206 <page_lookup+0x74>
{
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);

    if (pte == NULL || !(*pte & PTE_P)) {
        return NULL;
f01011fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ff:	eb 05                	jmp    f0101206 <page_lookup+0x74>
f0101201:	b8 00 00 00 00       	mov    $0x0,%eax
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
        *pte_store = pte;
    }
	return pp;
}
f0101206:	83 c4 14             	add    $0x14,%esp
f0101209:	5b                   	pop    %ebx
f010120a:	5d                   	pop    %ebp
f010120b:	c3                   	ret    

f010120c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010120c:	55                   	push   %ebp
f010120d:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010120f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101212:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101215:	5d                   	pop    %ebp
f0101216:	c3                   	ret    

f0101217 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101217:	55                   	push   %ebp
f0101218:	89 e5                	mov    %esp,%ebp
f010121a:	83 ec 28             	sub    $0x28,%esp
f010121d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101220:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101223:	8b 75 08             	mov    0x8(%ebp),%esi
f0101226:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t* pte;
    struct Page* pp = page_lookup(pgdir, va, &pte);
f0101229:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010122c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101230:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101234:	89 34 24             	mov    %esi,(%esp)
f0101237:	e8 56 ff ff ff       	call   f0101192 <page_lookup>

    if (pp) {
f010123c:	85 c0                	test   %eax,%eax
f010123e:	74 1d                	je     f010125d <page_remove+0x46>
        page_decref(pp);
f0101240:	89 04 24             	mov    %eax,(%esp)
f0101243:	e8 20 fd ff ff       	call   f0100f68 <page_decref>
        *pte = 0;
f0101248:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010124b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, va);
f0101251:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101255:	89 34 24             	mov    %esi,(%esp)
f0101258:	e8 af ff ff ff       	call   f010120c <tlb_invalidate>
    }
}
f010125d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101260:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0101263:	89 ec                	mov    %ebp,%esp
f0101265:	5d                   	pop    %ebp
f0101266:	c3                   	ret    

f0101267 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f0101267:	55                   	push   %ebp
f0101268:	89 e5                	mov    %esp,%ebp
f010126a:	83 ec 38             	sub    $0x38,%esp
f010126d:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101270:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101273:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101276:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101279:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f010127c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101283:	00 
f0101284:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101288:	8b 45 08             	mov    0x8(%ebp),%eax
f010128b:	89 04 24             	mov    %eax,(%esp)
f010128e:	e8 f8 fc ff ff       	call   f0100f8b <pgdir_walk>
f0101293:	89 c3                	mov    %eax,%ebx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101295:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f010129a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    physaddr_t ppa = page2pa(pp);

    if (pte != NULL) {
f010129d:	85 db                	test   %ebx,%ebx
f010129f:	74 25                	je     f01012c6 <page_insert+0x5f>
        if (*pte & PTE_P) 
f01012a1:	f6 03 01             	testb  $0x1,(%ebx)
f01012a4:	74 0f                	je     f01012b5 <page_insert+0x4e>
            page_remove(pgdir, va);
f01012a6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012aa:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ad:	89 04 24             	mov    %eax,(%esp)
f01012b0:	e8 62 ff ff ff       	call   f0101217 <page_remove>
        if (pp == page_free_list)
f01012b5:	3b 35 60 75 11 f0    	cmp    0xf0117560,%esi
f01012bb:	75 26                	jne    f01012e3 <page_insert+0x7c>
            page_free_list = page_free_list->pp_link;
f01012bd:	8b 06                	mov    (%esi),%eax
f01012bf:	a3 60 75 11 f0       	mov    %eax,0xf0117560
f01012c4:	eb 1d                	jmp    f01012e3 <page_insert+0x7c>
    } else {
        pte = pgdir_walk(pgdir, va, 1);
f01012c6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01012cd:	00 
f01012ce:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01012d5:	89 04 24             	mov    %eax,(%esp)
f01012d8:	e8 ae fc ff ff       	call   f0100f8b <pgdir_walk>
f01012dd:	89 c3                	mov    %eax,%ebx
        if (pte == NULL)
f01012df:	85 c0                	test   %eax,%eax
f01012e1:	74 30                	je     f0101313 <page_insert+0xac>
            return -E_NO_MEM;
    }

    *pte = ppa | perm | PTE_P;
f01012e3:	8b 55 14             	mov    0x14(%ebp),%edx
f01012e6:	83 ca 01             	or     $0x1,%edx
f01012e9:	89 f0                	mov    %esi,%eax
f01012eb:	2b 45 e4             	sub    -0x1c(%ebp),%eax
f01012ee:	c1 f8 03             	sar    $0x3,%eax
f01012f1:	c1 e0 0c             	shl    $0xc,%eax
f01012f4:	09 d0                	or     %edx,%eax
f01012f6:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f01012f8:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
    tlb_invalidate(pgdir, va);
f01012fd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101301:	8b 45 08             	mov    0x8(%ebp),%eax
f0101304:	89 04 24             	mov    %eax,(%esp)
f0101307:	e8 00 ff ff ff       	call   f010120c <tlb_invalidate>

	return 0;
f010130c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101311:	eb 05                	jmp    f0101318 <page_insert+0xb1>
        if (pp == page_free_list)
            page_free_list = page_free_list->pp_link;
    } else {
        pte = pgdir_walk(pgdir, va, 1);
        if (pte == NULL)
            return -E_NO_MEM;
f0101313:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = ppa | perm | PTE_P;
    pp->pp_ref++;
    tlb_invalidate(pgdir, va);

	return 0;
}
f0101318:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010131b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010131e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101321:	89 ec                	mov    %ebp,%esp
f0101323:	5d                   	pop    %ebp
f0101324:	c3                   	ret    

f0101325 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101325:	55                   	push   %ebp
f0101326:	89 e5                	mov    %esp,%ebp
f0101328:	57                   	push   %edi
f0101329:	56                   	push   %esi
f010132a:	53                   	push   %ebx
f010132b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010132e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101333:	e8 b8 f6 ff ff       	call   f01009f0 <nvram_read>
f0101338:	c1 e0 0a             	shl    $0xa,%eax
f010133b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101341:	85 c0                	test   %eax,%eax
f0101343:	0f 48 c2             	cmovs  %edx,%eax
f0101346:	c1 f8 0c             	sar    $0xc,%eax
f0101349:	a3 58 75 11 f0       	mov    %eax,0xf0117558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010134e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101353:	e8 98 f6 ff ff       	call   f01009f0 <nvram_read>
f0101358:	c1 e0 0a             	shl    $0xa,%eax
f010135b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101361:	85 c0                	test   %eax,%eax
f0101363:	0f 48 c2             	cmovs  %edx,%eax
f0101366:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101369:	85 c0                	test   %eax,%eax
f010136b:	74 0e                	je     f010137b <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010136d:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101373:	89 15 80 79 11 f0    	mov    %edx,0xf0117980
f0101379:	eb 0c                	jmp    f0101387 <mem_init+0x62>
	else
		npages = npages_basemem;
f010137b:	8b 15 58 75 11 f0    	mov    0xf0117558,%edx
f0101381:	89 15 80 79 11 f0    	mov    %edx,0xf0117980

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101387:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010138a:	c1 e8 0a             	shr    $0xa,%eax
f010138d:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101391:	a1 58 75 11 f0       	mov    0xf0117558,%eax
f0101396:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101399:	c1 e8 0a             	shr    $0xa,%eax
f010139c:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01013a0:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f01013a5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013a8:	c1 e8 0a             	shr    $0xa,%eax
f01013ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013af:	c7 04 24 fc 44 10 f0 	movl   $0xf01044fc,(%esp)
f01013b6:	e8 6f 1a 00 00       	call   f0102e2a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013bb:	b8 00 10 00 00       	mov    $0x1000,%eax
f01013c0:	e8 c4 f5 ff ff       	call   f0100989 <boot_alloc>
f01013c5:	a3 84 79 11 f0       	mov    %eax,0xf0117984
	memset(kern_pgdir, 0, PGSIZE);
f01013ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01013d1:	00 
f01013d2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01013d9:	00 
f01013da:	89 04 24             	mov    %eax,(%esp)
f01013dd:	e8 84 25 00 00       	call   f0103966 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01013e2:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013e7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013ec:	77 20                	ja     f010140e <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013ee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013f2:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f01013f9:	f0 
f01013fa:	c7 44 24 04 8e 00 00 	movl   $0x8e,0x4(%esp)
f0101401:	00 
f0101402:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101409:	e8 86 ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010140e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101414:	83 ca 05             	or     $0x5,%edx
f0101417:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
    n = sizeof(struct Page) * npages;
f010141d:	8b 1d 80 79 11 f0    	mov    0xf0117980,%ebx
f0101423:	c1 e3 03             	shl    $0x3,%ebx
    pages = boot_alloc(n);
f0101426:	89 d8                	mov    %ebx,%eax
f0101428:	e8 5c f5 ff ff       	call   f0100989 <boot_alloc>
f010142d:	a3 88 79 11 f0       	mov    %eax,0xf0117988
    memset(pages, 0, n);
f0101432:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101436:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010143d:	00 
f010143e:	89 04 24             	mov    %eax,(%esp)
f0101441:	e8 20 25 00 00       	call   f0103966 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101446:	e8 34 f9 ff ff       	call   f0100d7f <page_init>

	check_page_free_list(1);
f010144b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101450:	e8 cd f5 ff ff       	call   f0100a22 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f0101455:	83 3d 88 79 11 f0 00 	cmpl   $0x0,0xf0117988
f010145c:	75 1c                	jne    f010147a <mem_init+0x155>
		panic("'pages' is a null pointer!");
f010145e:	c7 44 24 08 dc 4b 10 	movl   $0xf0104bdc,0x8(%esp)
f0101465:	f0 
f0101466:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f010146d:	00 
f010146e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101475:	e8 1a ec ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010147a:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f010147f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101484:	85 c0                	test   %eax,%eax
f0101486:	74 09                	je     f0101491 <mem_init+0x16c>
		++nfree;
f0101488:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010148b:	8b 00                	mov    (%eax),%eax
f010148d:	85 c0                	test   %eax,%eax
f010148f:	75 f7                	jne    f0101488 <mem_init+0x163>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101491:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101498:	e8 0e fa ff ff       	call   f0100eab <page_alloc>
f010149d:	89 c6                	mov    %eax,%esi
f010149f:	85 c0                	test   %eax,%eax
f01014a1:	75 24                	jne    f01014c7 <mem_init+0x1a2>
f01014a3:	c7 44 24 0c f7 4b 10 	movl   $0xf0104bf7,0xc(%esp)
f01014aa:	f0 
f01014ab:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01014b2:	f0 
f01014b3:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f01014ba:	00 
f01014bb:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01014c2:	e8 cd eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01014c7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ce:	e8 d8 f9 ff ff       	call   f0100eab <page_alloc>
f01014d3:	89 c7                	mov    %eax,%edi
f01014d5:	85 c0                	test   %eax,%eax
f01014d7:	75 24                	jne    f01014fd <mem_init+0x1d8>
f01014d9:	c7 44 24 0c 0d 4c 10 	movl   $0xf0104c0d,0xc(%esp)
f01014e0:	f0 
f01014e1:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01014e8:	f0 
f01014e9:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f01014f0:	00 
f01014f1:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01014f8:	e8 97 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01014fd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101504:	e8 a2 f9 ff ff       	call   f0100eab <page_alloc>
f0101509:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010150c:	85 c0                	test   %eax,%eax
f010150e:	75 24                	jne    f0101534 <mem_init+0x20f>
f0101510:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0101517:	f0 
f0101518:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010151f:	f0 
f0101520:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101527:	00 
f0101528:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010152f:	e8 60 eb ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101534:	39 fe                	cmp    %edi,%esi
f0101536:	75 24                	jne    f010155c <mem_init+0x237>
f0101538:	c7 44 24 0c 39 4c 10 	movl   $0xf0104c39,0xc(%esp)
f010153f:	f0 
f0101540:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101547:	f0 
f0101548:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f010154f:	00 
f0101550:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101557:	e8 38 eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010155c:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010155f:	74 05                	je     f0101566 <mem_init+0x241>
f0101561:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101564:	75 24                	jne    f010158a <mem_init+0x265>
f0101566:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f010156d:	f0 
f010156e:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101575:	f0 
f0101576:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f010157d:	00 
f010157e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101585:	e8 0a eb ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010158a:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101590:	a1 80 79 11 f0       	mov    0xf0117980,%eax
f0101595:	c1 e0 0c             	shl    $0xc,%eax
f0101598:	89 f1                	mov    %esi,%ecx
f010159a:	29 d1                	sub    %edx,%ecx
f010159c:	c1 f9 03             	sar    $0x3,%ecx
f010159f:	c1 e1 0c             	shl    $0xc,%ecx
f01015a2:	39 c1                	cmp    %eax,%ecx
f01015a4:	72 24                	jb     f01015ca <mem_init+0x2a5>
f01015a6:	c7 44 24 0c 4b 4c 10 	movl   $0xf0104c4b,0xc(%esp)
f01015ad:	f0 
f01015ae:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01015b5:	f0 
f01015b6:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f01015bd:	00 
f01015be:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01015c5:	e8 ca ea ff ff       	call   f0100094 <_panic>
f01015ca:	89 f9                	mov    %edi,%ecx
f01015cc:	29 d1                	sub    %edx,%ecx
f01015ce:	c1 f9 03             	sar    $0x3,%ecx
f01015d1:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01015d4:	39 c8                	cmp    %ecx,%eax
f01015d6:	77 24                	ja     f01015fc <mem_init+0x2d7>
f01015d8:	c7 44 24 0c 68 4c 10 	movl   $0xf0104c68,0xc(%esp)
f01015df:	f0 
f01015e0:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01015e7:	f0 
f01015e8:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f01015ef:	00 
f01015f0:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01015f7:	e8 98 ea ff ff       	call   f0100094 <_panic>
f01015fc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01015ff:	29 d1                	sub    %edx,%ecx
f0101601:	89 ca                	mov    %ecx,%edx
f0101603:	c1 fa 03             	sar    $0x3,%edx
f0101606:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101609:	39 d0                	cmp    %edx,%eax
f010160b:	77 24                	ja     f0101631 <mem_init+0x30c>
f010160d:	c7 44 24 0c 85 4c 10 	movl   $0xf0104c85,0xc(%esp)
f0101614:	f0 
f0101615:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010161c:	f0 
f010161d:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101624:	00 
f0101625:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010162c:	e8 63 ea ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101631:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f0101636:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101639:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0101640:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101643:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010164a:	e8 5c f8 ff ff       	call   f0100eab <page_alloc>
f010164f:	85 c0                	test   %eax,%eax
f0101651:	74 24                	je     f0101677 <mem_init+0x352>
f0101653:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f010165a:	f0 
f010165b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101662:	f0 
f0101663:	c7 44 24 04 8b 02 00 	movl   $0x28b,0x4(%esp)
f010166a:	00 
f010166b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101672:	e8 1d ea ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101677:	89 34 24             	mov    %esi,(%esp)
f010167a:	e8 aa f8 ff ff       	call   f0100f29 <page_free>
	page_free(pp1);
f010167f:	89 3c 24             	mov    %edi,(%esp)
f0101682:	e8 a2 f8 ff ff       	call   f0100f29 <page_free>
	page_free(pp2);
f0101687:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010168a:	89 04 24             	mov    %eax,(%esp)
f010168d:	e8 97 f8 ff ff       	call   f0100f29 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101692:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101699:	e8 0d f8 ff ff       	call   f0100eab <page_alloc>
f010169e:	89 c6                	mov    %eax,%esi
f01016a0:	85 c0                	test   %eax,%eax
f01016a2:	75 24                	jne    f01016c8 <mem_init+0x3a3>
f01016a4:	c7 44 24 0c f7 4b 10 	movl   $0xf0104bf7,0xc(%esp)
f01016ab:	f0 
f01016ac:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01016b3:	f0 
f01016b4:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f01016bb:	00 
f01016bc:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01016c3:	e8 cc e9 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01016c8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016cf:	e8 d7 f7 ff ff       	call   f0100eab <page_alloc>
f01016d4:	89 c7                	mov    %eax,%edi
f01016d6:	85 c0                	test   %eax,%eax
f01016d8:	75 24                	jne    f01016fe <mem_init+0x3d9>
f01016da:	c7 44 24 0c 0d 4c 10 	movl   $0xf0104c0d,0xc(%esp)
f01016e1:	f0 
f01016e2:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01016e9:	f0 
f01016ea:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f01016f1:	00 
f01016f2:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01016f9:	e8 96 e9 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01016fe:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101705:	e8 a1 f7 ff ff       	call   f0100eab <page_alloc>
f010170a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010170d:	85 c0                	test   %eax,%eax
f010170f:	75 24                	jne    f0101735 <mem_init+0x410>
f0101711:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0101718:	f0 
f0101719:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101720:	f0 
f0101721:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0101728:	00 
f0101729:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101730:	e8 5f e9 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101735:	39 fe                	cmp    %edi,%esi
f0101737:	75 24                	jne    f010175d <mem_init+0x438>
f0101739:	c7 44 24 0c 39 4c 10 	movl   $0xf0104c39,0xc(%esp)
f0101740:	f0 
f0101741:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101748:	f0 
f0101749:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0101750:	00 
f0101751:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101758:	e8 37 e9 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010175d:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101760:	74 05                	je     f0101767 <mem_init+0x442>
f0101762:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101765:	75 24                	jne    f010178b <mem_init+0x466>
f0101767:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f010176e:	f0 
f010176f:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101776:	f0 
f0101777:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f010177e:	00 
f010177f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101786:	e8 09 e9 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f010178b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101792:	e8 14 f7 ff ff       	call   f0100eab <page_alloc>
f0101797:	85 c0                	test   %eax,%eax
f0101799:	74 24                	je     f01017bf <mem_init+0x49a>
f010179b:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f01017a2:	f0 
f01017a3:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01017aa:	f0 
f01017ab:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f01017b2:	00 
f01017b3:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01017ba:	e8 d5 e8 ff ff       	call   f0100094 <_panic>
f01017bf:	89 f0                	mov    %esi,%eax
f01017c1:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01017c7:	c1 f8 03             	sar    $0x3,%eax
f01017ca:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017cd:	89 c2                	mov    %eax,%edx
f01017cf:	c1 ea 0c             	shr    $0xc,%edx
f01017d2:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f01017d8:	72 20                	jb     f01017fa <mem_init+0x4d5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01017da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01017de:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f01017e5:	f0 
f01017e6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01017ed:	00 
f01017ee:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f01017f5:	e8 9a e8 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01017fa:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101801:	00 
f0101802:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101809:	00 
	return (void *)(pa + KERNBASE);
f010180a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010180f:	89 04 24             	mov    %eax,(%esp)
f0101812:	e8 4f 21 00 00       	call   f0103966 <memset>
	page_free(pp0);
f0101817:	89 34 24             	mov    %esi,(%esp)
f010181a:	e8 0a f7 ff ff       	call   f0100f29 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010181f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101826:	e8 80 f6 ff ff       	call   f0100eab <page_alloc>
f010182b:	85 c0                	test   %eax,%eax
f010182d:	75 24                	jne    f0101853 <mem_init+0x52e>
f010182f:	c7 44 24 0c b1 4c 10 	movl   $0xf0104cb1,0xc(%esp)
f0101836:	f0 
f0101837:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010183e:	f0 
f010183f:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f0101846:	00 
f0101847:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010184e:	e8 41 e8 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101853:	39 c6                	cmp    %eax,%esi
f0101855:	74 24                	je     f010187b <mem_init+0x556>
f0101857:	c7 44 24 0c cf 4c 10 	movl   $0xf0104ccf,0xc(%esp)
f010185e:	f0 
f010185f:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101866:	f0 
f0101867:	c7 44 24 04 9e 02 00 	movl   $0x29e,0x4(%esp)
f010186e:	00 
f010186f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101876:	e8 19 e8 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010187b:	89 f2                	mov    %esi,%edx
f010187d:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101883:	c1 fa 03             	sar    $0x3,%edx
f0101886:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101889:	89 d0                	mov    %edx,%eax
f010188b:	c1 e8 0c             	shr    $0xc,%eax
f010188e:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f0101894:	72 20                	jb     f01018b6 <mem_init+0x591>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101896:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010189a:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f01018a1:	f0 
f01018a2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01018a9:	00 
f01018aa:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f01018b1:	e8 de e7 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018b6:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01018bd:	75 11                	jne    f01018d0 <mem_init+0x5ab>
f01018bf:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01018c5:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018cb:	80 38 00             	cmpb   $0x0,(%eax)
f01018ce:	74 24                	je     f01018f4 <mem_init+0x5cf>
f01018d0:	c7 44 24 0c df 4c 10 	movl   $0xf0104cdf,0xc(%esp)
f01018d7:	f0 
f01018d8:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01018df:	f0 
f01018e0:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f01018e7:	00 
f01018e8:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01018ef:	e8 a0 e7 ff ff       	call   f0100094 <_panic>
f01018f4:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018f7:	39 d0                	cmp    %edx,%eax
f01018f9:	75 d0                	jne    f01018cb <mem_init+0x5a6>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01018fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01018fe:	89 15 60 75 11 f0    	mov    %edx,0xf0117560

	// free the pages we took
	page_free(pp0);
f0101904:	89 34 24             	mov    %esi,(%esp)
f0101907:	e8 1d f6 ff ff       	call   f0100f29 <page_free>
	page_free(pp1);
f010190c:	89 3c 24             	mov    %edi,(%esp)
f010190f:	e8 15 f6 ff ff       	call   f0100f29 <page_free>
	page_free(pp2);
f0101914:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101917:	89 04 24             	mov    %eax,(%esp)
f010191a:	e8 0a f6 ff ff       	call   f0100f29 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010191f:	a1 60 75 11 f0       	mov    0xf0117560,%eax
f0101924:	85 c0                	test   %eax,%eax
f0101926:	74 09                	je     f0101931 <mem_init+0x60c>
		--nfree;
f0101928:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010192b:	8b 00                	mov    (%eax),%eax
f010192d:	85 c0                	test   %eax,%eax
f010192f:	75 f7                	jne    f0101928 <mem_init+0x603>
		--nfree;
	assert(nfree == 0);
f0101931:	85 db                	test   %ebx,%ebx
f0101933:	74 24                	je     f0101959 <mem_init+0x634>
f0101935:	c7 44 24 0c e9 4c 10 	movl   $0xf0104ce9,0xc(%esp)
f010193c:	f0 
f010193d:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101944:	f0 
f0101945:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f010194c:	00 
f010194d:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101954:	e8 3b e7 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101959:	c7 04 24 58 45 10 f0 	movl   $0xf0104558,(%esp)
f0101960:	e8 c5 14 00 00       	call   f0102e2a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101965:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196c:	e8 3a f5 ff ff       	call   f0100eab <page_alloc>
f0101971:	89 c3                	mov    %eax,%ebx
f0101973:	85 c0                	test   %eax,%eax
f0101975:	75 24                	jne    f010199b <mem_init+0x676>
f0101977:	c7 44 24 0c f7 4b 10 	movl   $0xf0104bf7,0xc(%esp)
f010197e:	f0 
f010197f:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101986:	f0 
f0101987:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f010198e:	00 
f010198f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101996:	e8 f9 e6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010199b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a2:	e8 04 f5 ff ff       	call   f0100eab <page_alloc>
f01019a7:	89 c7                	mov    %eax,%edi
f01019a9:	85 c0                	test   %eax,%eax
f01019ab:	75 24                	jne    f01019d1 <mem_init+0x6ac>
f01019ad:	c7 44 24 0c 0d 4c 10 	movl   $0xf0104c0d,0xc(%esp)
f01019b4:	f0 
f01019b5:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01019bc:	f0 
f01019bd:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01019c4:	00 
f01019c5:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01019cc:	e8 c3 e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01019d1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d8:	e8 ce f4 ff ff       	call   f0100eab <page_alloc>
f01019dd:	89 c6                	mov    %eax,%esi
f01019df:	85 c0                	test   %eax,%eax
f01019e1:	75 24                	jne    f0101a07 <mem_init+0x6e2>
f01019e3:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f01019ea:	f0 
f01019eb:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01019f2:	f0 
f01019f3:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f01019fa:	00 
f01019fb:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101a02:	e8 8d e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a07:	39 fb                	cmp    %edi,%ebx
f0101a09:	75 24                	jne    f0101a2f <mem_init+0x70a>
f0101a0b:	c7 44 24 0c 39 4c 10 	movl   $0xf0104c39,0xc(%esp)
f0101a12:	f0 
f0101a13:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101a1a:	f0 
f0101a1b:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0101a22:	00 
f0101a23:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101a2a:	e8 65 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a2f:	39 c7                	cmp    %eax,%edi
f0101a31:	74 04                	je     f0101a37 <mem_init+0x712>
f0101a33:	39 c3                	cmp    %eax,%ebx
f0101a35:	75 24                	jne    f0101a5b <mem_init+0x736>
f0101a37:	c7 44 24 0c 38 45 10 	movl   $0xf0104538,0xc(%esp)
f0101a3e:	f0 
f0101a3f:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101a46:	f0 
f0101a47:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101a4e:	00 
f0101a4f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101a56:	e8 39 e6 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a5b:	8b 15 60 75 11 f0    	mov    0xf0117560,%edx
f0101a61:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101a64:	c7 05 60 75 11 f0 00 	movl   $0x0,0xf0117560
f0101a6b:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a75:	e8 31 f4 ff ff       	call   f0100eab <page_alloc>
f0101a7a:	85 c0                	test   %eax,%eax
f0101a7c:	74 24                	je     f0101aa2 <mem_init+0x77d>
f0101a7e:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101a8d:	f0 
f0101a8e:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0101a95:	00 
f0101a96:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101a9d:	e8 f2 e5 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101aa2:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101aa5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101aa9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101ab0:	00 
f0101ab1:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101ab6:	89 04 24             	mov    %eax,(%esp)
f0101ab9:	e8 d4 f6 ff ff       	call   f0101192 <page_lookup>
f0101abe:	85 c0                	test   %eax,%eax
f0101ac0:	74 24                	je     f0101ae6 <mem_init+0x7c1>
f0101ac2:	c7 44 24 0c 78 45 10 	movl   $0xf0104578,0xc(%esp)
f0101ac9:	f0 
f0101aca:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101ad9:	00 
f0101ada:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101ae1:	e8 ae e5 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101ae6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101aed:	00 
f0101aee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101af5:	00 
f0101af6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101afa:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101aff:	89 04 24             	mov    %eax,(%esp)
f0101b02:	e8 60 f7 ff ff       	call   f0101267 <page_insert>
f0101b07:	85 c0                	test   %eax,%eax
f0101b09:	78 24                	js     f0101b2f <mem_init+0x80a>
f0101b0b:	c7 44 24 0c b0 45 10 	movl   $0xf01045b0,0xc(%esp)
f0101b12:	f0 
f0101b13:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101b1a:	f0 
f0101b1b:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101b22:	00 
f0101b23:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101b2a:	e8 65 e5 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b2f:	89 1c 24             	mov    %ebx,(%esp)
f0101b32:	e8 f2 f3 ff ff       	call   f0100f29 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b37:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b3e:	00 
f0101b3f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b46:	00 
f0101b47:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b4b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101b50:	89 04 24             	mov    %eax,(%esp)
f0101b53:	e8 0f f7 ff ff       	call   f0101267 <page_insert>
f0101b58:	85 c0                	test   %eax,%eax
f0101b5a:	74 24                	je     f0101b80 <mem_init+0x85b>
f0101b5c:	c7 44 24 0c e0 45 10 	movl   $0xf01045e0,0xc(%esp)
f0101b63:	f0 
f0101b64:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101b6b:	f0 
f0101b6c:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0101b73:	00 
f0101b74:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101b7b:	e8 14 e5 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b80:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f0101b86:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b89:	a1 88 79 11 f0       	mov    0xf0117988,%eax
f0101b8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101b91:	8b 11                	mov    (%ecx),%edx
f0101b93:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b99:	89 d8                	mov    %ebx,%eax
f0101b9b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101b9e:	c1 f8 03             	sar    $0x3,%eax
f0101ba1:	c1 e0 0c             	shl    $0xc,%eax
f0101ba4:	39 c2                	cmp    %eax,%edx
f0101ba6:	74 24                	je     f0101bcc <mem_init+0x8a7>
f0101ba8:	c7 44 24 0c 10 46 10 	movl   $0xf0104610,0xc(%esp)
f0101baf:	f0 
f0101bb0:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101bb7:	f0 
f0101bb8:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0101bbf:	00 
f0101bc0:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101bc7:	e8 c8 e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101bcc:	ba 00 00 00 00       	mov    $0x0,%edx
f0101bd1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bd4:	e8 3f ed ff ff       	call   f0100918 <check_va2pa>
f0101bd9:	89 fa                	mov    %edi,%edx
f0101bdb:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101bde:	c1 fa 03             	sar    $0x3,%edx
f0101be1:	c1 e2 0c             	shl    $0xc,%edx
f0101be4:	39 d0                	cmp    %edx,%eax
f0101be6:	74 24                	je     f0101c0c <mem_init+0x8e7>
f0101be8:	c7 44 24 0c 38 46 10 	movl   $0xf0104638,0xc(%esp)
f0101bef:	f0 
f0101bf0:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101bf7:	f0 
f0101bf8:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101bff:	00 
f0101c00:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101c07:	e8 88 e4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101c0c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c11:	74 24                	je     f0101c37 <mem_init+0x912>
f0101c13:	c7 44 24 0c f4 4c 10 	movl   $0xf0104cf4,0xc(%esp)
f0101c1a:	f0 
f0101c1b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101c2a:	00 
f0101c2b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101c32:	e8 5d e4 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101c37:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c3c:	74 24                	je     f0101c62 <mem_init+0x93d>
f0101c3e:	c7 44 24 0c 05 4d 10 	movl   $0xf0104d05,0xc(%esp)
f0101c45:	f0 
f0101c46:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101c4d:	f0 
f0101c4e:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101c55:	00 
f0101c56:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101c5d:	e8 32 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c62:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c69:	00 
f0101c6a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101c71:	00 
f0101c72:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c76:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101c79:	89 14 24             	mov    %edx,(%esp)
f0101c7c:	e8 e6 f5 ff ff       	call   f0101267 <page_insert>
f0101c81:	85 c0                	test   %eax,%eax
f0101c83:	74 24                	je     f0101ca9 <mem_init+0x984>
f0101c85:	c7 44 24 0c 68 46 10 	movl   $0xf0104668,0xc(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101c94:	f0 
f0101c95:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101c9c:	00 
f0101c9d:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101ca4:	e8 eb e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ca9:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cae:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101cb3:	e8 60 ec ff ff       	call   f0100918 <check_va2pa>
f0101cb8:	89 f2                	mov    %esi,%edx
f0101cba:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101cc0:	c1 fa 03             	sar    $0x3,%edx
f0101cc3:	c1 e2 0c             	shl    $0xc,%edx
f0101cc6:	39 d0                	cmp    %edx,%eax
f0101cc8:	74 24                	je     f0101cee <mem_init+0x9c9>
f0101cca:	c7 44 24 0c a4 46 10 	movl   $0xf01046a4,0xc(%esp)
f0101cd1:	f0 
f0101cd2:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101cd9:	f0 
f0101cda:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0101ce1:	00 
f0101ce2:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101ce9:	e8 a6 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101cee:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cf3:	74 24                	je     f0101d19 <mem_init+0x9f4>
f0101cf5:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f0101cfc:	f0 
f0101cfd:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101d04:	f0 
f0101d05:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f0101d0c:	00 
f0101d0d:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101d14:	e8 7b e3 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101d19:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d20:	e8 86 f1 ff ff       	call   f0100eab <page_alloc>
f0101d25:	85 c0                	test   %eax,%eax
f0101d27:	74 24                	je     f0101d4d <mem_init+0xa28>
f0101d29:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f0101d30:	f0 
f0101d31:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101d38:	f0 
f0101d39:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101d40:	00 
f0101d41:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101d48:	e8 47 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d4d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d54:	00 
f0101d55:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d5c:	00 
f0101d5d:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101d61:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101d66:	89 04 24             	mov    %eax,(%esp)
f0101d69:	e8 f9 f4 ff ff       	call   f0101267 <page_insert>
f0101d6e:	85 c0                	test   %eax,%eax
f0101d70:	74 24                	je     f0101d96 <mem_init+0xa71>
f0101d72:	c7 44 24 0c 68 46 10 	movl   $0xf0104668,0xc(%esp)
f0101d79:	f0 
f0101d7a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101d81:	f0 
f0101d82:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0101d89:	00 
f0101d8a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101d91:	e8 fe e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d96:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d9b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101da0:	e8 73 eb ff ff       	call   f0100918 <check_va2pa>
f0101da5:	89 f2                	mov    %esi,%edx
f0101da7:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101dad:	c1 fa 03             	sar    $0x3,%edx
f0101db0:	c1 e2 0c             	shl    $0xc,%edx
f0101db3:	39 d0                	cmp    %edx,%eax
f0101db5:	74 24                	je     f0101ddb <mem_init+0xab6>
f0101db7:	c7 44 24 0c a4 46 10 	movl   $0xf01046a4,0xc(%esp)
f0101dbe:	f0 
f0101dbf:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101dc6:	f0 
f0101dc7:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101dce:	00 
f0101dcf:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101dd6:	e8 b9 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ddb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101de0:	74 24                	je     f0101e06 <mem_init+0xae1>
f0101de2:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f0101de9:	f0 
f0101dea:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101df1:	f0 
f0101df2:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0101df9:	00 
f0101dfa:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101e01:	e8 8e e2 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e06:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e0d:	e8 99 f0 ff ff       	call   f0100eab <page_alloc>
f0101e12:	85 c0                	test   %eax,%eax
f0101e14:	74 24                	je     f0101e3a <mem_init+0xb15>
f0101e16:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f0101e1d:	f0 
f0101e1e:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0101e2d:	00 
f0101e2e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101e35:	e8 5a e2 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e3a:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f0101e40:	8b 02                	mov    (%edx),%eax
f0101e42:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e47:	89 c1                	mov    %eax,%ecx
f0101e49:	c1 e9 0c             	shr    $0xc,%ecx
f0101e4c:	3b 0d 80 79 11 f0    	cmp    0xf0117980,%ecx
f0101e52:	72 20                	jb     f0101e74 <mem_init+0xb4f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e54:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e58:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0101e5f:	f0 
f0101e60:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101e67:	00 
f0101e68:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101e6f:	e8 20 e2 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101e74:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e7c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e83:	00 
f0101e84:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e8b:	00 
f0101e8c:	89 14 24             	mov    %edx,(%esp)
f0101e8f:	e8 f7 f0 ff ff       	call   f0100f8b <pgdir_walk>
f0101e94:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101e97:	83 c2 04             	add    $0x4,%edx
f0101e9a:	39 d0                	cmp    %edx,%eax
f0101e9c:	74 24                	je     f0101ec2 <mem_init+0xb9d>
f0101e9e:	c7 44 24 0c d4 46 10 	movl   $0xf01046d4,0xc(%esp)
f0101ea5:	f0 
f0101ea6:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101ead:	f0 
f0101eae:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101eb5:	00 
f0101eb6:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101ebd:	e8 d2 e1 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101ec2:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101ec9:	00 
f0101eca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ed1:	00 
f0101ed2:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ed6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101edb:	89 04 24             	mov    %eax,(%esp)
f0101ede:	e8 84 f3 ff ff       	call   f0101267 <page_insert>
f0101ee3:	85 c0                	test   %eax,%eax
f0101ee5:	74 24                	je     f0101f0b <mem_init+0xbe6>
f0101ee7:	c7 44 24 0c 14 47 10 	movl   $0xf0104714,0xc(%esp)
f0101eee:	f0 
f0101eef:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101ef6:	f0 
f0101ef7:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0101efe:	00 
f0101eff:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101f06:	e8 89 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f0b:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f0101f11:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101f14:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f19:	89 c8                	mov    %ecx,%eax
f0101f1b:	e8 f8 e9 ff ff       	call   f0100918 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f20:	89 f2                	mov    %esi,%edx
f0101f22:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0101f28:	c1 fa 03             	sar    $0x3,%edx
f0101f2b:	c1 e2 0c             	shl    $0xc,%edx
f0101f2e:	39 d0                	cmp    %edx,%eax
f0101f30:	74 24                	je     f0101f56 <mem_init+0xc31>
f0101f32:	c7 44 24 0c a4 46 10 	movl   $0xf01046a4,0xc(%esp)
f0101f39:	f0 
f0101f3a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101f41:	f0 
f0101f42:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101f49:	00 
f0101f4a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101f51:	e8 3e e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f56:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101f5b:	74 24                	je     f0101f81 <mem_init+0xc5c>
f0101f5d:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f0101f64:	f0 
f0101f65:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101f6c:	f0 
f0101f6d:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101f74:	00 
f0101f75:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101f7c:	e8 13 e1 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101f81:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f88:	00 
f0101f89:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f90:	00 
f0101f91:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f94:	89 04 24             	mov    %eax,(%esp)
f0101f97:	e8 ef ef ff ff       	call   f0100f8b <pgdir_walk>
f0101f9c:	f6 00 04             	testb  $0x4,(%eax)
f0101f9f:	75 24                	jne    f0101fc5 <mem_init+0xca0>
f0101fa1:	c7 44 24 0c 54 47 10 	movl   $0xf0104754,0xc(%esp)
f0101fa8:	f0 
f0101fa9:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101fb0:	f0 
f0101fb1:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101fb8:	00 
f0101fb9:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101fc0:	e8 cf e0 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101fc5:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0101fca:	f6 00 04             	testb  $0x4,(%eax)
f0101fcd:	75 24                	jne    f0101ff3 <mem_init+0xcce>
f0101fcf:	c7 44 24 0c 27 4d 10 	movl   $0xf0104d27,0xc(%esp)
f0101fd6:	f0 
f0101fd7:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0101fde:	f0 
f0101fdf:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101fe6:	00 
f0101fe7:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0101fee:	e8 a1 e0 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101ff3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ffa:	00 
f0101ffb:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102002:	00 
f0102003:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102007:	89 04 24             	mov    %eax,(%esp)
f010200a:	e8 58 f2 ff ff       	call   f0101267 <page_insert>
f010200f:	85 c0                	test   %eax,%eax
f0102011:	78 24                	js     f0102037 <mem_init+0xd12>
f0102013:	c7 44 24 0c 88 47 10 	movl   $0xf0104788,0xc(%esp)
f010201a:	f0 
f010201b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102022:	f0 
f0102023:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f010202a:	00 
f010202b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102032:	e8 5d e0 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102037:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010203e:	00 
f010203f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102046:	00 
f0102047:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010204b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102050:	89 04 24             	mov    %eax,(%esp)
f0102053:	e8 0f f2 ff ff       	call   f0101267 <page_insert>
f0102058:	85 c0                	test   %eax,%eax
f010205a:	74 24                	je     f0102080 <mem_init+0xd5b>
f010205c:	c7 44 24 0c c0 47 10 	movl   $0xf01047c0,0xc(%esp)
f0102063:	f0 
f0102064:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010206b:	f0 
f010206c:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0102073:	00 
f0102074:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010207b:	e8 14 e0 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102080:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102087:	00 
f0102088:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010208f:	00 
f0102090:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102095:	89 04 24             	mov    %eax,(%esp)
f0102098:	e8 ee ee ff ff       	call   f0100f8b <pgdir_walk>
f010209d:	f6 00 04             	testb  $0x4,(%eax)
f01020a0:	74 24                	je     f01020c6 <mem_init+0xda1>
f01020a2:	c7 44 24 0c fc 47 10 	movl   $0xf01047fc,0xc(%esp)
f01020a9:	f0 
f01020aa:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01020b1:	f0 
f01020b2:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f01020b9:	00 
f01020ba:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01020c1:	e8 ce df ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01020c6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01020cb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01020ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01020d3:	e8 40 e8 ff ff       	call   f0100918 <check_va2pa>
f01020d8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01020db:	89 f8                	mov    %edi,%eax
f01020dd:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f01020e3:	c1 f8 03             	sar    $0x3,%eax
f01020e6:	c1 e0 0c             	shl    $0xc,%eax
f01020e9:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01020ec:	74 24                	je     f0102112 <mem_init+0xded>
f01020ee:	c7 44 24 0c 34 48 10 	movl   $0xf0104834,0xc(%esp)
f01020f5:	f0 
f01020f6:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01020fd:	f0 
f01020fe:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102105:	00 
f0102106:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010210d:	e8 82 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102112:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102117:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010211a:	e8 f9 e7 ff ff       	call   f0100918 <check_va2pa>
f010211f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102122:	74 24                	je     f0102148 <mem_init+0xe23>
f0102124:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f010212b:	f0 
f010212c:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102133:	f0 
f0102134:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f010213b:	00 
f010213c:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102143:	e8 4c df ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102148:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010214d:	74 24                	je     f0102173 <mem_init+0xe4e>
f010214f:	c7 44 24 0c 3d 4d 10 	movl   $0xf0104d3d,0xc(%esp)
f0102156:	f0 
f0102157:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010215e:	f0 
f010215f:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102166:	00 
f0102167:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010216e:	e8 21 df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102173:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102178:	74 24                	je     f010219e <mem_init+0xe79>
f010217a:	c7 44 24 0c 4e 4d 10 	movl   $0xf0104d4e,0xc(%esp)
f0102181:	f0 
f0102182:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102189:	f0 
f010218a:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102191:	00 
f0102192:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102199:	e8 f6 de ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010219e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01021a5:	e8 01 ed ff ff       	call   f0100eab <page_alloc>
f01021aa:	85 c0                	test   %eax,%eax
f01021ac:	74 04                	je     f01021b2 <mem_init+0xe8d>
f01021ae:	39 c6                	cmp    %eax,%esi
f01021b0:	74 24                	je     f01021d6 <mem_init+0xeb1>
f01021b2:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f01021b9:	f0 
f01021ba:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01021c1:	f0 
f01021c2:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01021c9:	00 
f01021ca:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01021d1:	e8 be de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01021d6:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01021dd:	00 
f01021de:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01021e3:	89 04 24             	mov    %eax,(%esp)
f01021e6:	e8 2c f0 ff ff       	call   f0101217 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021eb:	8b 15 84 79 11 f0    	mov    0xf0117984,%edx
f01021f1:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01021f4:	ba 00 00 00 00       	mov    $0x0,%edx
f01021f9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021fc:	e8 17 e7 ff ff       	call   f0100918 <check_va2pa>
f0102201:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102204:	74 24                	je     f010222a <mem_init+0xf05>
f0102206:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f010220d:	f0 
f010220e:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102215:	f0 
f0102216:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f010221d:	00 
f010221e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102225:	e8 6a de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010222a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010222f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102232:	e8 e1 e6 ff ff       	call   f0100918 <check_va2pa>
f0102237:	89 fa                	mov    %edi,%edx
f0102239:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010223f:	c1 fa 03             	sar    $0x3,%edx
f0102242:	c1 e2 0c             	shl    $0xc,%edx
f0102245:	39 d0                	cmp    %edx,%eax
f0102247:	74 24                	je     f010226d <mem_init+0xf48>
f0102249:	c7 44 24 0c 60 48 10 	movl   $0xf0104860,0xc(%esp)
f0102250:	f0 
f0102251:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102258:	f0 
f0102259:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102260:	00 
f0102261:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102268:	e8 27 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010226d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102272:	74 24                	je     f0102298 <mem_init+0xf73>
f0102274:	c7 44 24 0c f4 4c 10 	movl   $0xf0104cf4,0xc(%esp)
f010227b:	f0 
f010227c:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102283:	f0 
f0102284:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f010228b:	00 
f010228c:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102293:	e8 fc dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102298:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010229d:	74 24                	je     f01022c3 <mem_init+0xf9e>
f010229f:	c7 44 24 0c 4e 4d 10 	movl   $0xf0104d4e,0xc(%esp)
f01022a6:	f0 
f01022a7:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01022ae:	f0 
f01022af:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f01022b6:	00 
f01022b7:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01022be:	e8 d1 dd ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01022c3:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022ca:	00 
f01022cb:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01022ce:	89 0c 24             	mov    %ecx,(%esp)
f01022d1:	e8 41 ef ff ff       	call   f0101217 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01022d6:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01022db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01022de:	ba 00 00 00 00       	mov    $0x0,%edx
f01022e3:	e8 30 e6 ff ff       	call   f0100918 <check_va2pa>
f01022e8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01022eb:	74 24                	je     f0102311 <mem_init+0xfec>
f01022ed:	c7 44 24 0c b4 48 10 	movl   $0xf01048b4,0xc(%esp)
f01022f4:	f0 
f01022f5:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01022fc:	f0 
f01022fd:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f0102304:	00 
f0102305:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010230c:	e8 83 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102311:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102316:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102319:	e8 fa e5 ff ff       	call   f0100918 <check_va2pa>
f010231e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102321:	74 24                	je     f0102347 <mem_init+0x1022>
f0102323:	c7 44 24 0c d8 48 10 	movl   $0xf01048d8,0xc(%esp)
f010232a:	f0 
f010232b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102332:	f0 
f0102333:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f010233a:	00 
f010233b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102342:	e8 4d dd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102347:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010234c:	74 24                	je     f0102372 <mem_init+0x104d>
f010234e:	c7 44 24 0c 5f 4d 10 	movl   $0xf0104d5f,0xc(%esp)
f0102355:	f0 
f0102356:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010235d:	f0 
f010235e:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f0102365:	00 
f0102366:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010236d:	e8 22 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102372:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102377:	74 24                	je     f010239d <mem_init+0x1078>
f0102379:	c7 44 24 0c 4e 4d 10 	movl   $0xf0104d4e,0xc(%esp)
f0102380:	f0 
f0102381:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102388:	f0 
f0102389:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102390:	00 
f0102391:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102398:	e8 f7 dc ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010239d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023a4:	e8 02 eb ff ff       	call   f0100eab <page_alloc>
f01023a9:	85 c0                	test   %eax,%eax
f01023ab:	74 04                	je     f01023b1 <mem_init+0x108c>
f01023ad:	39 c7                	cmp    %eax,%edi
f01023af:	74 24                	je     f01023d5 <mem_init+0x10b0>
f01023b1:	c7 44 24 0c 00 49 10 	movl   $0xf0104900,0xc(%esp)
f01023b8:	f0 
f01023b9:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01023c0:	f0 
f01023c1:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f01023c8:	00 
f01023c9:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01023d0:	e8 bf dc ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01023d5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023dc:	e8 ca ea ff ff       	call   f0100eab <page_alloc>
f01023e1:	85 c0                	test   %eax,%eax
f01023e3:	74 24                	je     f0102409 <mem_init+0x10e4>
f01023e5:	c7 44 24 0c a2 4c 10 	movl   $0xf0104ca2,0xc(%esp)
f01023ec:	f0 
f01023ed:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01023f4:	f0 
f01023f5:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f01023fc:	00 
f01023fd:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102404:	e8 8b dc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102409:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f010240e:	8b 08                	mov    (%eax),%ecx
f0102410:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102416:	89 da                	mov    %ebx,%edx
f0102418:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f010241e:	c1 fa 03             	sar    $0x3,%edx
f0102421:	c1 e2 0c             	shl    $0xc,%edx
f0102424:	39 d1                	cmp    %edx,%ecx
f0102426:	74 24                	je     f010244c <mem_init+0x1127>
f0102428:	c7 44 24 0c 10 46 10 	movl   $0xf0104610,0xc(%esp)
f010242f:	f0 
f0102430:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102437:	f0 
f0102438:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f010243f:	00 
f0102440:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102447:	e8 48 dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010244c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102452:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102457:	74 24                	je     f010247d <mem_init+0x1158>
f0102459:	c7 44 24 0c 05 4d 10 	movl   $0xf0104d05,0xc(%esp)
f0102460:	f0 
f0102461:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102468:	f0 
f0102469:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0102470:	00 
f0102471:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102478:	e8 17 dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010247d:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102483:	89 1c 24             	mov    %ebx,(%esp)
f0102486:	e8 9e ea ff ff       	call   f0100f29 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010248b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102492:	00 
f0102493:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010249a:	00 
f010249b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01024a0:	89 04 24             	mov    %eax,(%esp)
f01024a3:	e8 e3 ea ff ff       	call   f0100f8b <pgdir_walk>
f01024a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01024ab:	8b 0d 84 79 11 f0    	mov    0xf0117984,%ecx
f01024b1:	8b 51 04             	mov    0x4(%ecx),%edx
f01024b4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01024ba:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024bd:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f01024c3:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01024c6:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024c9:	c1 ea 0c             	shr    $0xc,%edx
f01024cc:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01024cf:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01024d2:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01024d5:	72 23                	jb     f01024fa <mem_init+0x11d5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024d7:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01024da:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01024de:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f01024e5:	f0 
f01024e6:	c7 44 24 04 6f 03 00 	movl   $0x36f,0x4(%esp)
f01024ed:	00 
f01024ee:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01024f5:	e8 9a db ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01024fa:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01024fd:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102503:	39 d0                	cmp    %edx,%eax
f0102505:	74 24                	je     f010252b <mem_init+0x1206>
f0102507:	c7 44 24 0c 70 4d 10 	movl   $0xf0104d70,0xc(%esp)
f010250e:	f0 
f010250f:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102516:	f0 
f0102517:	c7 44 24 04 70 03 00 	movl   $0x370,0x4(%esp)
f010251e:	00 
f010251f:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102526:	e8 69 db ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010252b:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102532:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102538:	89 d8                	mov    %ebx,%eax
f010253a:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102540:	c1 f8 03             	sar    $0x3,%eax
f0102543:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102546:	89 c1                	mov    %eax,%ecx
f0102548:	c1 e9 0c             	shr    $0xc,%ecx
f010254b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010254e:	77 20                	ja     f0102570 <mem_init+0x124b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102550:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102554:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f010255b:	f0 
f010255c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102563:	00 
f0102564:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f010256b:	e8 24 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102570:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102577:	00 
f0102578:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f010257f:	00 
	return (void *)(pa + KERNBASE);
f0102580:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102585:	89 04 24             	mov    %eax,(%esp)
f0102588:	e8 d9 13 00 00       	call   f0103966 <memset>
	page_free(pp0);
f010258d:	89 1c 24             	mov    %ebx,(%esp)
f0102590:	e8 94 e9 ff ff       	call   f0100f29 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102595:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010259c:	00 
f010259d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025a4:	00 
f01025a5:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01025aa:	89 04 24             	mov    %eax,(%esp)
f01025ad:	e8 d9 e9 ff ff       	call   f0100f8b <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01025b2:	89 da                	mov    %ebx,%edx
f01025b4:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f01025ba:	c1 fa 03             	sar    $0x3,%edx
f01025bd:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025c0:	89 d0                	mov    %edx,%eax
f01025c2:	c1 e8 0c             	shr    $0xc,%eax
f01025c5:	3b 05 80 79 11 f0    	cmp    0xf0117980,%eax
f01025cb:	72 20                	jb     f01025ed <mem_init+0x12c8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025cd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01025d1:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f01025d8:	f0 
f01025d9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01025e0:	00 
f01025e1:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f01025e8:	e8 a7 da ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01025ed:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01025f3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01025f6:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01025fd:	75 11                	jne    f0102610 <mem_init+0x12eb>
f01025ff:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102605:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010260b:	f6 00 01             	testb  $0x1,(%eax)
f010260e:	74 24                	je     f0102634 <mem_init+0x130f>
f0102610:	c7 44 24 0c 88 4d 10 	movl   $0xf0104d88,0xc(%esp)
f0102617:	f0 
f0102618:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010261f:	f0 
f0102620:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0102627:	00 
f0102628:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010262f:	e8 60 da ff ff       	call   f0100094 <_panic>
f0102634:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102637:	39 d0                	cmp    %edx,%eax
f0102639:	75 d0                	jne    f010260b <mem_init+0x12e6>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010263b:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102640:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102646:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f010264c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010264f:	89 0d 60 75 11 f0    	mov    %ecx,0xf0117560

	// free the pages we took
	page_free(pp0);
f0102655:	89 1c 24             	mov    %ebx,(%esp)
f0102658:	e8 cc e8 ff ff       	call   f0100f29 <page_free>
	page_free(pp1);
f010265d:	89 3c 24             	mov    %edi,(%esp)
f0102660:	e8 c4 e8 ff ff       	call   f0100f29 <page_free>
	page_free(pp2);
f0102665:	89 34 24             	mov    %esi,(%esp)
f0102668:	e8 bc e8 ff ff       	call   f0100f29 <page_free>

	cprintf("check_page() succeeded!\n");
f010266d:	c7 04 24 9f 4d 10 f0 	movl   $0xf0104d9f,(%esp)
f0102674:	e8 b1 07 00 00       	call   f0102e2a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct Page),
f0102679:	a1 88 79 11 f0       	mov    0xf0117988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010267e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102683:	77 20                	ja     f01026a5 <mem_init+0x1380>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102685:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102689:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f0102690:	f0 
f0102691:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102698:	00 
f0102699:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01026a0:	e8 ef d9 ff ff       	call   f0100094 <_panic>
f01026a5:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f01026ab:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026b2:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026b8:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01026bf:	00 
	return (physaddr_t)kva - KERNBASE;
f01026c0:	05 00 00 00 10       	add    $0x10000000,%eax
f01026c5:	89 04 24             	mov    %eax,(%esp)
f01026c8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026cd:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f01026d2:	e8 c3 e9 ff ff       	call   f010109a <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026d7:	b8 00 d0 10 f0       	mov    $0xf010d000,%eax
f01026dc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026e1:	77 20                	ja     f0102703 <mem_init+0x13de>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026e3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026e7:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f01026ee:	f0 
f01026ef:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
f01026f6:	00 
f01026f7:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01026fe:	e8 91 d9 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE,
f0102703:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010270a:	00 
f010270b:	c7 04 24 00 d0 10 00 	movl   $0x10d000,(%esp)
f0102712:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102717:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f010271c:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102721:	e8 74 e9 ff ff       	call   f010109a <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, ~KERNBASE + 1, 0x0, PTE_W);
f0102726:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010272d:	00 
f010272e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102735:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010273a:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010273f:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102744:	e8 51 e9 ff ff       	call   f010109a <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102749:	8b 1d 84 79 11 f0    	mov    0xf0117984,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f010274f:	8b 15 80 79 11 f0    	mov    0xf0117980,%edx
f0102755:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102758:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f010275f:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102765:	74 79                	je     f01027e0 <mem_init+0x14bb>
f0102767:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010276c:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102772:	89 d8                	mov    %ebx,%eax
f0102774:	e8 9f e1 ff ff       	call   f0100918 <check_va2pa>
f0102779:	8b 15 88 79 11 f0    	mov    0xf0117988,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010277f:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102785:	77 20                	ja     f01027a7 <mem_init+0x1482>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102787:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010278b:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f0102792:	f0 
f0102793:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f010279a:	00 
f010279b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01027a2:	e8 ed d8 ff ff       	call   f0100094 <_panic>
f01027a7:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01027ae:	39 d0                	cmp    %edx,%eax
f01027b0:	74 24                	je     f01027d6 <mem_init+0x14b1>
f01027b2:	c7 44 24 0c 24 49 10 	movl   $0xf0104924,0xc(%esp)
f01027b9:	f0 
f01027ba:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01027c1:	f0 
f01027c2:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f01027c9:	00 
f01027ca:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01027d1:	e8 be d8 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01027d6:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01027dc:	39 f7                	cmp    %esi,%edi
f01027de:	77 8c                	ja     f010276c <mem_init+0x1447>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01027e0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01027e3:	c1 e7 0c             	shl    $0xc,%edi
f01027e6:	85 ff                	test   %edi,%edi
f01027e8:	74 44                	je     f010282e <mem_init+0x1509>
f01027ea:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027ef:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01027f5:	89 d8                	mov    %ebx,%eax
f01027f7:	e8 1c e1 ff ff       	call   f0100918 <check_va2pa>
f01027fc:	39 c6                	cmp    %eax,%esi
f01027fe:	74 24                	je     f0102824 <mem_init+0x14ff>
f0102800:	c7 44 24 0c 58 49 10 	movl   $0xf0104958,0xc(%esp)
f0102807:	f0 
f0102808:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010280f:	f0 
f0102810:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0102817:	00 
f0102818:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010281f:	e8 70 d8 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102824:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010282a:	39 fe                	cmp    %edi,%esi
f010282c:	72 c1                	jb     f01027ef <mem_init+0x14ca>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010282e:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102833:	89 d8                	mov    %ebx,%eax
f0102835:	e8 de e0 ff ff       	call   f0100918 <check_va2pa>
f010283a:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010283f:	bf 00 d0 10 f0       	mov    $0xf010d000,%edi
f0102844:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f010284a:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010284d:	39 c2                	cmp    %eax,%edx
f010284f:	74 24                	je     f0102875 <mem_init+0x1550>
f0102851:	c7 44 24 0c 80 49 10 	movl   $0xf0104980,0xc(%esp)
f0102858:	f0 
f0102859:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102860:	f0 
f0102861:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0102868:	00 
f0102869:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102870:	e8 1f d8 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102875:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f010287b:	0f 85 27 05 00 00    	jne    f0102da8 <mem_init+0x1a83>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102881:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f0102886:	89 d8                	mov    %ebx,%eax
f0102888:	e8 8b e0 ff ff       	call   f0100918 <check_va2pa>
f010288d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102890:	74 24                	je     f01028b6 <mem_init+0x1591>
f0102892:	c7 44 24 0c c8 49 10 	movl   $0xf01049c8,0xc(%esp)
f0102899:	f0 
f010289a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01028a1:	f0 
f01028a2:	c7 44 24 04 d0 02 00 	movl   $0x2d0,0x4(%esp)
f01028a9:	00 
f01028aa:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01028b1:	e8 de d7 ff ff       	call   f0100094 <_panic>
f01028b6:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01028bb:	8d 90 44 fc ff ff    	lea    -0x3bc(%eax),%edx
f01028c1:	83 fa 02             	cmp    $0x2,%edx
f01028c4:	77 2e                	ja     f01028f4 <mem_init+0x15cf>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01028c6:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01028ca:	0f 85 aa 00 00 00    	jne    f010297a <mem_init+0x1655>
f01028d0:	c7 44 24 0c b8 4d 10 	movl   $0xf0104db8,0xc(%esp)
f01028d7:	f0 
f01028d8:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f01028df:	f0 
f01028e0:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f01028e7:	00 
f01028e8:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01028ef:	e8 a0 d7 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01028f4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01028f9:	76 55                	jbe    f0102950 <mem_init+0x162b>
				assert(pgdir[i] & PTE_P);
f01028fb:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f01028fe:	f6 c2 01             	test   $0x1,%dl
f0102901:	75 24                	jne    f0102927 <mem_init+0x1602>
f0102903:	c7 44 24 0c b8 4d 10 	movl   $0xf0104db8,0xc(%esp)
f010290a:	f0 
f010290b:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102912:	f0 
f0102913:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f010291a:	00 
f010291b:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102922:	e8 6d d7 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102927:	f6 c2 02             	test   $0x2,%dl
f010292a:	75 4e                	jne    f010297a <mem_init+0x1655>
f010292c:	c7 44 24 0c c9 4d 10 	movl   $0xf0104dc9,0xc(%esp)
f0102933:	f0 
f0102934:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f010293b:	f0 
f010293c:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0102943:	00 
f0102944:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f010294b:	e8 44 d7 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102950:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102954:	74 24                	je     f010297a <mem_init+0x1655>
f0102956:	c7 44 24 0c da 4d 10 	movl   $0xf0104dda,0xc(%esp)
f010295d:	f0 
f010295e:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102965:	f0 
f0102966:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f010296d:	00 
f010296e:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102975:	e8 1a d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f010297a:	83 c0 01             	add    $0x1,%eax
f010297d:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102982:	0f 85 33 ff ff ff    	jne    f01028bb <mem_init+0x1596>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102988:	c7 04 24 f8 49 10 f0 	movl   $0xf01049f8,(%esp)
f010298f:	e8 96 04 00 00       	call   f0102e2a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102994:	a1 84 79 11 f0       	mov    0xf0117984,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102999:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010299e:	77 20                	ja     f01029c0 <mem_init+0x169b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029a0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029a4:	c7 44 24 08 90 44 10 	movl   $0xf0104490,0x8(%esp)
f01029ab:	f0 
f01029ac:	c7 44 24 04 d6 00 00 	movl   $0xd6,0x4(%esp)
f01029b3:	00 
f01029b4:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f01029bb:	e8 d4 d6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01029c0:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01029c5:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01029c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01029cd:	e8 50 e0 ff ff       	call   f0100a22 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01029d2:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f01029d5:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f01029da:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01029dd:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01029e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01029e7:	e8 bf e4 ff ff       	call   f0100eab <page_alloc>
f01029ec:	89 c6                	mov    %eax,%esi
f01029ee:	85 c0                	test   %eax,%eax
f01029f0:	75 24                	jne    f0102a16 <mem_init+0x16f1>
f01029f2:	c7 44 24 0c f7 4b 10 	movl   $0xf0104bf7,0xc(%esp)
f01029f9:	f0 
f01029fa:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102a01:	f0 
f0102a02:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102a09:	00 
f0102a0a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102a11:	e8 7e d6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102a16:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a1d:	e8 89 e4 ff ff       	call   f0100eab <page_alloc>
f0102a22:	89 c7                	mov    %eax,%edi
f0102a24:	85 c0                	test   %eax,%eax
f0102a26:	75 24                	jne    f0102a4c <mem_init+0x1727>
f0102a28:	c7 44 24 0c 0d 4c 10 	movl   $0xf0104c0d,0xc(%esp)
f0102a2f:	f0 
f0102a30:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102a37:	f0 
f0102a38:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102a3f:	00 
f0102a40:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102a47:	e8 48 d6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102a4c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a53:	e8 53 e4 ff ff       	call   f0100eab <page_alloc>
f0102a58:	89 c3                	mov    %eax,%ebx
f0102a5a:	85 c0                	test   %eax,%eax
f0102a5c:	75 24                	jne    f0102a82 <mem_init+0x175d>
f0102a5e:	c7 44 24 0c 23 4c 10 	movl   $0xf0104c23,0xc(%esp)
f0102a65:	f0 
f0102a66:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102a6d:	f0 
f0102a6e:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102a75:	00 
f0102a76:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102a7d:	e8 12 d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102a82:	89 34 24             	mov    %esi,(%esp)
f0102a85:	e8 9f e4 ff ff       	call   f0100f29 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a8a:	89 f8                	mov    %edi,%eax
f0102a8c:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102a92:	c1 f8 03             	sar    $0x3,%eax
f0102a95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a98:	89 c2                	mov    %eax,%edx
f0102a9a:	c1 ea 0c             	shr    $0xc,%edx
f0102a9d:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0102aa3:	72 20                	jb     f0102ac5 <mem_init+0x17a0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102aa5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102aa9:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0102ab0:	f0 
f0102ab1:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ab8:	00 
f0102ab9:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0102ac0:	e8 cf d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102ac5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102acc:	00 
f0102acd:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102ad4:	00 
	return (void *)(pa + KERNBASE);
f0102ad5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ada:	89 04 24             	mov    %eax,(%esp)
f0102add:	e8 84 0e 00 00       	call   f0103966 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102ae2:	89 d8                	mov    %ebx,%eax
f0102ae4:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102aea:	c1 f8 03             	sar    $0x3,%eax
f0102aed:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102af0:	89 c2                	mov    %eax,%edx
f0102af2:	c1 ea 0c             	shr    $0xc,%edx
f0102af5:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0102afb:	72 20                	jb     f0102b1d <mem_init+0x17f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102afd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b01:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0102b08:	f0 
f0102b09:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b10:	00 
f0102b11:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0102b18:	e8 77 d5 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102b1d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b24:	00 
f0102b25:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102b2c:	00 
	return (void *)(pa + KERNBASE);
f0102b2d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b32:	89 04 24             	mov    %eax,(%esp)
f0102b35:	e8 2c 0e 00 00       	call   f0103966 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102b3a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102b41:	00 
f0102b42:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b49:	00 
f0102b4a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102b4e:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102b53:	89 04 24             	mov    %eax,(%esp)
f0102b56:	e8 0c e7 ff ff       	call   f0101267 <page_insert>
	assert(pp1->pp_ref == 1);
f0102b5b:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102b60:	74 24                	je     f0102b86 <mem_init+0x1861>
f0102b62:	c7 44 24 0c f4 4c 10 	movl   $0xf0104cf4,0xc(%esp)
f0102b69:	f0 
f0102b6a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102b71:	f0 
f0102b72:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0102b79:	00 
f0102b7a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102b81:	e8 0e d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102b86:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102b8d:	01 01 01 
f0102b90:	74 24                	je     f0102bb6 <mem_init+0x1891>
f0102b92:	c7 44 24 0c 18 4a 10 	movl   $0xf0104a18,0xc(%esp)
f0102b99:	f0 
f0102b9a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102ba1:	f0 
f0102ba2:	c7 44 24 04 9d 03 00 	movl   $0x39d,0x4(%esp)
f0102ba9:	00 
f0102baa:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102bb1:	e8 de d4 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102bb6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102bbd:	00 
f0102bbe:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102bc5:	00 
f0102bc6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102bca:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102bcf:	89 04 24             	mov    %eax,(%esp)
f0102bd2:	e8 90 e6 ff ff       	call   f0101267 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102bd7:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102bde:	02 02 02 
f0102be1:	74 24                	je     f0102c07 <mem_init+0x18e2>
f0102be3:	c7 44 24 0c 3c 4a 10 	movl   $0xf0104a3c,0xc(%esp)
f0102bea:	f0 
f0102beb:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102bf2:	f0 
f0102bf3:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f0102bfa:	00 
f0102bfb:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102c02:	e8 8d d4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102c07:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102c0c:	74 24                	je     f0102c32 <mem_init+0x190d>
f0102c0e:	c7 44 24 0c 16 4d 10 	movl   $0xf0104d16,0xc(%esp)
f0102c15:	f0 
f0102c16:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102c1d:	f0 
f0102c1e:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f0102c25:	00 
f0102c26:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102c2d:	e8 62 d4 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102c32:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102c37:	74 24                	je     f0102c5d <mem_init+0x1938>
f0102c39:	c7 44 24 0c 5f 4d 10 	movl   $0xf0104d5f,0xc(%esp)
f0102c40:	f0 
f0102c41:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102c48:	f0 
f0102c49:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102c50:	00 
f0102c51:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102c58:	e8 37 d4 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102c5d:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102c64:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c67:	89 d8                	mov    %ebx,%eax
f0102c69:	2b 05 88 79 11 f0    	sub    0xf0117988,%eax
f0102c6f:	c1 f8 03             	sar    $0x3,%eax
f0102c72:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c75:	89 c2                	mov    %eax,%edx
f0102c77:	c1 ea 0c             	shr    $0xc,%edx
f0102c7a:	3b 15 80 79 11 f0    	cmp    0xf0117980,%edx
f0102c80:	72 20                	jb     f0102ca2 <mem_init+0x197d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c82:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c86:	c7 44 24 08 84 43 10 	movl   $0xf0104384,0x8(%esp)
f0102c8d:	f0 
f0102c8e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c95:	00 
f0102c96:	c7 04 24 d9 4a 10 f0 	movl   $0xf0104ad9,(%esp)
f0102c9d:	e8 f2 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102ca2:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ca9:	03 03 03 
f0102cac:	74 24                	je     f0102cd2 <mem_init+0x19ad>
f0102cae:	c7 44 24 0c 60 4a 10 	movl   $0xf0104a60,0xc(%esp)
f0102cb5:	f0 
f0102cb6:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102cbd:	f0 
f0102cbe:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f0102cc5:	00 
f0102cc6:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102ccd:	e8 c2 d3 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102cd2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102cd9:	00 
f0102cda:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102cdf:	89 04 24             	mov    %eax,(%esp)
f0102ce2:	e8 30 e5 ff ff       	call   f0101217 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ce7:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102cec:	74 24                	je     f0102d12 <mem_init+0x19ed>
f0102cee:	c7 44 24 0c 4e 4d 10 	movl   $0xf0104d4e,0xc(%esp)
f0102cf5:	f0 
f0102cf6:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102cfd:	f0 
f0102cfe:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102d05:	00 
f0102d06:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102d0d:	e8 82 d3 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d12:	a1 84 79 11 f0       	mov    0xf0117984,%eax
f0102d17:	8b 08                	mov    (%eax),%ecx
f0102d19:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d1f:	89 f2                	mov    %esi,%edx
f0102d21:	2b 15 88 79 11 f0    	sub    0xf0117988,%edx
f0102d27:	c1 fa 03             	sar    $0x3,%edx
f0102d2a:	c1 e2 0c             	shl    $0xc,%edx
f0102d2d:	39 d1                	cmp    %edx,%ecx
f0102d2f:	74 24                	je     f0102d55 <mem_init+0x1a30>
f0102d31:	c7 44 24 0c 10 46 10 	movl   $0xf0104610,0xc(%esp)
f0102d38:	f0 
f0102d39:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102d40:	f0 
f0102d41:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102d48:	00 
f0102d49:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102d50:	e8 3f d3 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102d55:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102d5b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102d60:	74 24                	je     f0102d86 <mem_init+0x1a61>
f0102d62:	c7 44 24 0c 05 4d 10 	movl   $0xf0104d05,0xc(%esp)
f0102d69:	f0 
f0102d6a:	c7 44 24 08 c4 4a 10 	movl   $0xf0104ac4,0x8(%esp)
f0102d71:	f0 
f0102d72:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102d79:	00 
f0102d7a:	c7 04 24 b8 4a 10 f0 	movl   $0xf0104ab8,(%esp)
f0102d81:	e8 0e d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102d86:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102d8c:	89 34 24             	mov    %esi,(%esp)
f0102d8f:	e8 95 e1 ff ff       	call   f0100f29 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102d94:	c7 04 24 8c 4a 10 f0 	movl   $0xf0104a8c,(%esp)
f0102d9b:	e8 8a 00 00 00       	call   f0102e2a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102da0:	83 c4 3c             	add    $0x3c,%esp
f0102da3:	5b                   	pop    %ebx
f0102da4:	5e                   	pop    %esi
f0102da5:	5f                   	pop    %edi
f0102da6:	5d                   	pop    %ebp
f0102da7:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102da8:	89 f2                	mov    %esi,%edx
f0102daa:	89 d8                	mov    %ebx,%eax
f0102dac:	e8 67 db ff ff       	call   f0100918 <check_va2pa>
f0102db1:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102db7:	e9 8e fa ff ff       	jmp    f010284a <mem_init+0x1525>

f0102dbc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102dbc:	55                   	push   %ebp
f0102dbd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102dbf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102dc7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102dc8:	b2 71                	mov    $0x71,%dl
f0102dca:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102dcb:	0f b6 c0             	movzbl %al,%eax
}
f0102dce:	5d                   	pop    %ebp
f0102dcf:	c3                   	ret    

f0102dd0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102dd0:	55                   	push   %ebp
f0102dd1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102dd3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102dd8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ddb:	ee                   	out    %al,(%dx)
f0102ddc:	b2 71                	mov    $0x71,%dl
f0102dde:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102de1:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102de2:	5d                   	pop    %ebp
f0102de3:	c3                   	ret    

f0102de4 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102de4:	55                   	push   %ebp
f0102de5:	89 e5                	mov    %esp,%ebp
f0102de7:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102dea:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ded:	89 04 24             	mov    %eax,(%esp)
f0102df0:	e8 fd d7 ff ff       	call   f01005f2 <cputchar>
	*cnt++;
}
f0102df5:	c9                   	leave  
f0102df6:	c3                   	ret    

f0102df7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102df7:	55                   	push   %ebp
f0102df8:	89 e5                	mov    %esp,%ebp
f0102dfa:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102dfd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102e04:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102e07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e0e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102e12:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102e15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e19:	c7 04 24 e4 2d 10 f0 	movl   $0xf0102de4,(%esp)
f0102e20:	e8 65 04 00 00       	call   f010328a <vprintfmt>
	return cnt;
}
f0102e25:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102e28:	c9                   	leave  
f0102e29:	c3                   	ret    

f0102e2a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102e2a:	55                   	push   %ebp
f0102e2b:	89 e5                	mov    %esp,%ebp
f0102e2d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102e30:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102e33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e37:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e3a:	89 04 24             	mov    %eax,(%esp)
f0102e3d:	e8 b5 ff ff ff       	call   f0102df7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102e42:	c9                   	leave  
f0102e43:	c3                   	ret    

f0102e44 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102e44:	55                   	push   %ebp
f0102e45:	89 e5                	mov    %esp,%ebp
f0102e47:	57                   	push   %edi
f0102e48:	56                   	push   %esi
f0102e49:	53                   	push   %ebx
f0102e4a:	83 ec 10             	sub    $0x10,%esp
f0102e4d:	89 c3                	mov    %eax,%ebx
f0102e4f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102e52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102e55:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102e58:	8b 0a                	mov    (%edx),%ecx
f0102e5a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102e5d:	8b 00                	mov    (%eax),%eax
f0102e5f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102e62:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f0102e69:	eb 77                	jmp    f0102ee2 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102e6b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102e6e:	01 c8                	add    %ecx,%eax
f0102e70:	bf 02 00 00 00       	mov    $0x2,%edi
f0102e75:	99                   	cltd   
f0102e76:	f7 ff                	idiv   %edi
f0102e78:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e7a:	eb 01                	jmp    f0102e7d <stab_binsearch+0x39>
			m--;
f0102e7c:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e7d:	39 ca                	cmp    %ecx,%edx
f0102e7f:	7c 1d                	jl     f0102e9e <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e81:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102e84:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102e89:	39 f7                	cmp    %esi,%edi
f0102e8b:	75 ef                	jne    f0102e7c <stab_binsearch+0x38>
f0102e8d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102e90:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102e93:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102e97:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102e9a:	73 18                	jae    f0102eb4 <stab_binsearch+0x70>
f0102e9c:	eb 05                	jmp    f0102ea3 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102e9e:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102ea1:	eb 3f                	jmp    f0102ee2 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ea3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102ea6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102ea8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102eab:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102eb2:	eb 2e                	jmp    f0102ee2 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102eb4:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102eb7:	76 15                	jbe    f0102ece <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102eb9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102ebc:	4f                   	dec    %edi
f0102ebd:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102ec0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102ec3:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102ec5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102ecc:	eb 14                	jmp    f0102ee2 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102ece:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102ed1:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102ed4:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102ed6:	ff 45 0c             	incl   0xc(%ebp)
f0102ed9:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102edb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0102ee2:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102ee5:	7e 84                	jle    f0102e6b <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102ee7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102eeb:	75 0d                	jne    f0102efa <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102eed:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102ef0:	8b 02                	mov    (%edx),%eax
f0102ef2:	48                   	dec    %eax
f0102ef3:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102ef6:	89 01                	mov    %eax,(%ecx)
f0102ef8:	eb 22                	jmp    f0102f1c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102efa:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102efd:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102eff:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f02:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102f04:	eb 01                	jmp    f0102f07 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102f06:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102f07:	39 c1                	cmp    %eax,%ecx
f0102f09:	7d 0c                	jge    f0102f17 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102f0b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102f0e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102f13:	39 f2                	cmp    %esi,%edx
f0102f15:	75 ef                	jne    f0102f06 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102f17:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102f1a:	89 02                	mov    %eax,(%edx)
	}
}
f0102f1c:	83 c4 10             	add    $0x10,%esp
f0102f1f:	5b                   	pop    %ebx
f0102f20:	5e                   	pop    %esi
f0102f21:	5f                   	pop    %edi
f0102f22:	5d                   	pop    %ebp
f0102f23:	c3                   	ret    

f0102f24 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102f24:	55                   	push   %ebp
f0102f25:	89 e5                	mov    %esp,%ebp
f0102f27:	83 ec 38             	sub    $0x38,%esp
f0102f2a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102f2d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102f30:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102f33:	8b 75 08             	mov    0x8(%ebp),%esi
f0102f36:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102f39:	c7 03 e8 4d 10 f0    	movl   $0xf0104de8,(%ebx)
	info->eip_line = 0;
f0102f3f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102f46:	c7 43 08 e8 4d 10 f0 	movl   $0xf0104de8,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102f4d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102f54:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102f57:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102f5e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102f64:	76 12                	jbe    f0102f78 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f66:	b8 8b cf 10 f0       	mov    $0xf010cf8b,%eax
f0102f6b:	3d 79 b1 10 f0       	cmp    $0xf010b179,%eax
f0102f70:	0f 86 9b 01 00 00    	jbe    f0103111 <debuginfo_eip+0x1ed>
f0102f76:	eb 1c                	jmp    f0102f94 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102f78:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102f7f:	f0 
f0102f80:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102f87:	00 
f0102f88:	c7 04 24 ff 4d 10 f0 	movl   $0xf0104dff,(%esp)
f0102f8f:	e8 00 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102f94:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102f99:	80 3d 8a cf 10 f0 00 	cmpb   $0x0,0xf010cf8a
f0102fa0:	0f 85 77 01 00 00    	jne    f010311d <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102fa6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102fad:	b8 78 b1 10 f0       	mov    $0xf010b178,%eax
f0102fb2:	2d 1c 50 10 f0       	sub    $0xf010501c,%eax
f0102fb7:	c1 f8 02             	sar    $0x2,%eax
f0102fba:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102fc0:	83 e8 01             	sub    $0x1,%eax
f0102fc3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102fc6:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102fca:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102fd1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102fd4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102fd7:	b8 1c 50 10 f0       	mov    $0xf010501c,%eax
f0102fdc:	e8 63 fe ff ff       	call   f0102e44 <stab_binsearch>
	if (lfile == 0)
f0102fe1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102fe4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102fe9:	85 d2                	test   %edx,%edx
f0102feb:	0f 84 2c 01 00 00    	je     f010311d <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102ff1:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102ff4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102ff7:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102ffa:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ffe:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103005:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103008:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010300b:	b8 1c 50 10 f0       	mov    $0xf010501c,%eax
f0103010:	e8 2f fe ff ff       	call   f0102e44 <stab_binsearch>

	if (lfun <= rfun) {
f0103015:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0103018:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f010301b:	7f 2e                	jg     f010304b <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010301d:	6b c7 0c             	imul   $0xc,%edi,%eax
f0103020:	8d 90 1c 50 10 f0    	lea    -0xfefafe4(%eax),%edx
f0103026:	8b 80 1c 50 10 f0    	mov    -0xfefafe4(%eax),%eax
f010302c:	b9 8b cf 10 f0       	mov    $0xf010cf8b,%ecx
f0103031:	81 e9 79 b1 10 f0    	sub    $0xf010b179,%ecx
f0103037:	39 c8                	cmp    %ecx,%eax
f0103039:	73 08                	jae    f0103043 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010303b:	05 79 b1 10 f0       	add    $0xf010b179,%eax
f0103040:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103043:	8b 42 08             	mov    0x8(%edx),%eax
f0103046:	89 43 10             	mov    %eax,0x10(%ebx)
f0103049:	eb 06                	jmp    f0103051 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010304b:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010304e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103051:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103058:	00 
f0103059:	8b 43 08             	mov    0x8(%ebx),%eax
f010305c:	89 04 24             	mov    %eax,(%esp)
f010305f:	e8 db 08 00 00       	call   f010393f <strfind>
f0103064:	2b 43 08             	sub    0x8(%ebx),%eax
f0103067:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010306a:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010306d:	39 d7                	cmp    %edx,%edi
f010306f:	7c 5f                	jl     f01030d0 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0103071:	89 f8                	mov    %edi,%eax
f0103073:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0103076:	80 b9 20 50 10 f0 84 	cmpb   $0x84,-0xfefafe0(%ecx)
f010307d:	75 18                	jne    f0103097 <debuginfo_eip+0x173>
f010307f:	eb 30                	jmp    f01030b1 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103081:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103084:	39 fa                	cmp    %edi,%edx
f0103086:	7f 48                	jg     f01030d0 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0103088:	89 f8                	mov    %edi,%eax
f010308a:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f010308d:	80 3c 8d 20 50 10 f0 	cmpb   $0x84,-0xfefafe0(,%ecx,4)
f0103094:	84 
f0103095:	74 1a                	je     f01030b1 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103097:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010309a:	8d 04 85 1c 50 10 f0 	lea    -0xfefafe4(,%eax,4),%eax
f01030a1:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f01030a5:	75 da                	jne    f0103081 <debuginfo_eip+0x15d>
f01030a7:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f01030ab:	74 d4                	je     f0103081 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01030ad:	39 fa                	cmp    %edi,%edx
f01030af:	7f 1f                	jg     f01030d0 <debuginfo_eip+0x1ac>
f01030b1:	6b ff 0c             	imul   $0xc,%edi,%edi
f01030b4:	8b 87 1c 50 10 f0    	mov    -0xfefafe4(%edi),%eax
f01030ba:	ba 8b cf 10 f0       	mov    $0xf010cf8b,%edx
f01030bf:	81 ea 79 b1 10 f0    	sub    $0xf010b179,%edx
f01030c5:	39 d0                	cmp    %edx,%eax
f01030c7:	73 07                	jae    f01030d0 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01030c9:	05 79 b1 10 f0       	add    $0xf010b179,%eax
f01030ce:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030d0:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01030d3:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f01030d6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01030db:	39 ca                	cmp    %ecx,%edx
f01030dd:	7d 3e                	jge    f010311d <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f01030df:	83 c2 01             	add    $0x1,%edx
f01030e2:	39 d1                	cmp    %edx,%ecx
f01030e4:	7e 37                	jle    f010311d <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030e6:	6b f2 0c             	imul   $0xc,%edx,%esi
f01030e9:	80 be 20 50 10 f0 a0 	cmpb   $0xa0,-0xfefafe0(%esi)
f01030f0:	75 2b                	jne    f010311d <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f01030f2:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01030f6:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01030f9:	39 d1                	cmp    %edx,%ecx
f01030fb:	7e 1b                	jle    f0103118 <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01030fd:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103100:	80 3c 85 20 50 10 f0 	cmpb   $0xa0,-0xfefafe0(,%eax,4)
f0103107:	a0 
f0103108:	74 e8                	je     f01030f2 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f010310a:	b8 00 00 00 00       	mov    $0x0,%eax
f010310f:	eb 0c                	jmp    f010311d <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103111:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103116:	eb 05                	jmp    f010311d <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103118:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010311d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103120:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103123:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103126:	89 ec                	mov    %ebp,%esp
f0103128:	5d                   	pop    %ebp
f0103129:	c3                   	ret    
f010312a:	00 00                	add    %al,(%eax)
f010312c:	00 00                	add    %al,(%eax)
	...

f0103130 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103130:	55                   	push   %ebp
f0103131:	89 e5                	mov    %esp,%ebp
f0103133:	57                   	push   %edi
f0103134:	56                   	push   %esi
f0103135:	53                   	push   %ebx
f0103136:	83 ec 3c             	sub    $0x3c,%esp
f0103139:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010313c:	89 d7                	mov    %edx,%edi
f010313e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103141:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103144:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103147:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010314a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010314d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103150:	b8 00 00 00 00       	mov    $0x0,%eax
f0103155:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103158:	72 11                	jb     f010316b <printnum+0x3b>
f010315a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010315d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103160:	76 09                	jbe    f010316b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103162:	83 eb 01             	sub    $0x1,%ebx
f0103165:	85 db                	test   %ebx,%ebx
f0103167:	7f 51                	jg     f01031ba <printnum+0x8a>
f0103169:	eb 5e                	jmp    f01031c9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010316b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010316f:	83 eb 01             	sub    $0x1,%ebx
f0103172:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103176:	8b 45 10             	mov    0x10(%ebp),%eax
f0103179:	89 44 24 08          	mov    %eax,0x8(%esp)
f010317d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103181:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103185:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010318c:	00 
f010318d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103190:	89 04 24             	mov    %eax,(%esp)
f0103193:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103196:	89 44 24 04          	mov    %eax,0x4(%esp)
f010319a:	e8 21 0a 00 00       	call   f0103bc0 <__udivdi3>
f010319f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01031a3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01031a7:	89 04 24             	mov    %eax,(%esp)
f01031aa:	89 54 24 04          	mov    %edx,0x4(%esp)
f01031ae:	89 fa                	mov    %edi,%edx
f01031b0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b3:	e8 78 ff ff ff       	call   f0103130 <printnum>
f01031b8:	eb 0f                	jmp    f01031c9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01031ba:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031be:	89 34 24             	mov    %esi,(%esp)
f01031c1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01031c4:	83 eb 01             	sub    $0x1,%ebx
f01031c7:	75 f1                	jne    f01031ba <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01031c9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031cd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01031d1:	8b 45 10             	mov    0x10(%ebp),%eax
f01031d4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01031d8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01031df:	00 
f01031e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01031e3:	89 04 24             	mov    %eax,(%esp)
f01031e6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01031ed:	e8 fe 0a 00 00       	call   f0103cf0 <__umoddi3>
f01031f2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01031f6:	0f be 80 0d 4e 10 f0 	movsbl -0xfefb1f3(%eax),%eax
f01031fd:	89 04 24             	mov    %eax,(%esp)
f0103200:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103203:	83 c4 3c             	add    $0x3c,%esp
f0103206:	5b                   	pop    %ebx
f0103207:	5e                   	pop    %esi
f0103208:	5f                   	pop    %edi
f0103209:	5d                   	pop    %ebp
f010320a:	c3                   	ret    

f010320b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010320b:	55                   	push   %ebp
f010320c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010320e:	83 fa 01             	cmp    $0x1,%edx
f0103211:	7e 0e                	jle    f0103221 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103213:	8b 10                	mov    (%eax),%edx
f0103215:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103218:	89 08                	mov    %ecx,(%eax)
f010321a:	8b 02                	mov    (%edx),%eax
f010321c:	8b 52 04             	mov    0x4(%edx),%edx
f010321f:	eb 22                	jmp    f0103243 <getuint+0x38>
	else if (lflag)
f0103221:	85 d2                	test   %edx,%edx
f0103223:	74 10                	je     f0103235 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103225:	8b 10                	mov    (%eax),%edx
f0103227:	8d 4a 04             	lea    0x4(%edx),%ecx
f010322a:	89 08                	mov    %ecx,(%eax)
f010322c:	8b 02                	mov    (%edx),%eax
f010322e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103233:	eb 0e                	jmp    f0103243 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103235:	8b 10                	mov    (%eax),%edx
f0103237:	8d 4a 04             	lea    0x4(%edx),%ecx
f010323a:	89 08                	mov    %ecx,(%eax)
f010323c:	8b 02                	mov    (%edx),%eax
f010323e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103243:	5d                   	pop    %ebp
f0103244:	c3                   	ret    

f0103245 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103245:	55                   	push   %ebp
f0103246:	89 e5                	mov    %esp,%ebp
f0103248:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010324b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010324f:	8b 10                	mov    (%eax),%edx
f0103251:	3b 50 04             	cmp    0x4(%eax),%edx
f0103254:	73 0a                	jae    f0103260 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103256:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103259:	88 0a                	mov    %cl,(%edx)
f010325b:	83 c2 01             	add    $0x1,%edx
f010325e:	89 10                	mov    %edx,(%eax)
}
f0103260:	5d                   	pop    %ebp
f0103261:	c3                   	ret    

f0103262 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103262:	55                   	push   %ebp
f0103263:	89 e5                	mov    %esp,%ebp
f0103265:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103268:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010326b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010326f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103272:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103276:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103279:	89 44 24 04          	mov    %eax,0x4(%esp)
f010327d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103280:	89 04 24             	mov    %eax,(%esp)
f0103283:	e8 02 00 00 00       	call   f010328a <vprintfmt>
	va_end(ap);
}
f0103288:	c9                   	leave  
f0103289:	c3                   	ret    

f010328a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010328a:	55                   	push   %ebp
f010328b:	89 e5                	mov    %esp,%ebp
f010328d:	57                   	push   %edi
f010328e:	56                   	push   %esi
f010328f:	53                   	push   %ebx
f0103290:	83 ec 4c             	sub    $0x4c,%esp
f0103293:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103296:	8b 75 10             	mov    0x10(%ebp),%esi
f0103299:	eb 12                	jmp    f01032ad <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010329b:	85 c0                	test   %eax,%eax
f010329d:	0f 84 a9 03 00 00    	je     f010364c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f01032a3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032a7:	89 04 24             	mov    %eax,(%esp)
f01032aa:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01032ad:	0f b6 06             	movzbl (%esi),%eax
f01032b0:	83 c6 01             	add    $0x1,%esi
f01032b3:	83 f8 25             	cmp    $0x25,%eax
f01032b6:	75 e3                	jne    f010329b <vprintfmt+0x11>
f01032b8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01032bc:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01032c3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01032c8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01032cf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01032d4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01032d7:	eb 2b                	jmp    f0103304 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032d9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01032dc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01032e0:	eb 22                	jmp    f0103304 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01032e5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01032e9:	eb 19                	jmp    f0103304 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032eb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01032ee:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01032f5:	eb 0d                	jmp    f0103304 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01032f7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032fd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103304:	0f b6 06             	movzbl (%esi),%eax
f0103307:	0f b6 d0             	movzbl %al,%edx
f010330a:	8d 7e 01             	lea    0x1(%esi),%edi
f010330d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103310:	83 e8 23             	sub    $0x23,%eax
f0103313:	3c 55                	cmp    $0x55,%al
f0103315:	0f 87 0b 03 00 00    	ja     f0103626 <vprintfmt+0x39c>
f010331b:	0f b6 c0             	movzbl %al,%eax
f010331e:	ff 24 85 98 4e 10 f0 	jmp    *-0xfefb168(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103325:	83 ea 30             	sub    $0x30,%edx
f0103328:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010332b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010332f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103332:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103335:	83 fa 09             	cmp    $0x9,%edx
f0103338:	77 4a                	ja     f0103384 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010333a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010333d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103340:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103343:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103347:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010334a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010334d:	83 fa 09             	cmp    $0x9,%edx
f0103350:	76 eb                	jbe    f010333d <vprintfmt+0xb3>
f0103352:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103355:	eb 2d                	jmp    f0103384 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103357:	8b 45 14             	mov    0x14(%ebp),%eax
f010335a:	8d 50 04             	lea    0x4(%eax),%edx
f010335d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103360:	8b 00                	mov    (%eax),%eax
f0103362:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103365:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103368:	eb 1a                	jmp    f0103384 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010336a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010336d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103371:	79 91                	jns    f0103304 <vprintfmt+0x7a>
f0103373:	e9 73 ff ff ff       	jmp    f01032eb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103378:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010337b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103382:	eb 80                	jmp    f0103304 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103384:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103388:	0f 89 76 ff ff ff    	jns    f0103304 <vprintfmt+0x7a>
f010338e:	e9 64 ff ff ff       	jmp    f01032f7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103393:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103396:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103399:	e9 66 ff ff ff       	jmp    f0103304 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010339e:	8b 45 14             	mov    0x14(%ebp),%eax
f01033a1:	8d 50 04             	lea    0x4(%eax),%edx
f01033a4:	89 55 14             	mov    %edx,0x14(%ebp)
f01033a7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033ab:	8b 00                	mov    (%eax),%eax
f01033ad:	89 04 24             	mov    %eax,(%esp)
f01033b0:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033b3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01033b6:	e9 f2 fe ff ff       	jmp    f01032ad <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01033bb:	8b 45 14             	mov    0x14(%ebp),%eax
f01033be:	8d 50 04             	lea    0x4(%eax),%edx
f01033c1:	89 55 14             	mov    %edx,0x14(%ebp)
f01033c4:	8b 00                	mov    (%eax),%eax
f01033c6:	89 c2                	mov    %eax,%edx
f01033c8:	c1 fa 1f             	sar    $0x1f,%edx
f01033cb:	31 d0                	xor    %edx,%eax
f01033cd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01033cf:	83 f8 06             	cmp    $0x6,%eax
f01033d2:	7f 0b                	jg     f01033df <vprintfmt+0x155>
f01033d4:	8b 14 85 f0 4f 10 f0 	mov    -0xfefb010(,%eax,4),%edx
f01033db:	85 d2                	test   %edx,%edx
f01033dd:	75 23                	jne    f0103402 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f01033df:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033e3:	c7 44 24 08 25 4e 10 	movl   $0xf0104e25,0x8(%esp)
f01033ea:	f0 
f01033eb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033ef:	8b 7d 08             	mov    0x8(%ebp),%edi
f01033f2:	89 3c 24             	mov    %edi,(%esp)
f01033f5:	e8 68 fe ff ff       	call   f0103262 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033fa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01033fd:	e9 ab fe ff ff       	jmp    f01032ad <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103402:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103406:	c7 44 24 08 d6 4a 10 	movl   $0xf0104ad6,0x8(%esp)
f010340d:	f0 
f010340e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103412:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103415:	89 3c 24             	mov    %edi,(%esp)
f0103418:	e8 45 fe ff ff       	call   f0103262 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010341d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103420:	e9 88 fe ff ff       	jmp    f01032ad <vprintfmt+0x23>
f0103425:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103428:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010342b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010342e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103431:	8d 50 04             	lea    0x4(%eax),%edx
f0103434:	89 55 14             	mov    %edx,0x14(%ebp)
f0103437:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103439:	85 f6                	test   %esi,%esi
f010343b:	ba 1e 4e 10 f0       	mov    $0xf0104e1e,%edx
f0103440:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103443:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103447:	7e 06                	jle    f010344f <vprintfmt+0x1c5>
f0103449:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010344d:	75 10                	jne    f010345f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010344f:	0f be 06             	movsbl (%esi),%eax
f0103452:	83 c6 01             	add    $0x1,%esi
f0103455:	85 c0                	test   %eax,%eax
f0103457:	0f 85 86 00 00 00    	jne    f01034e3 <vprintfmt+0x259>
f010345d:	eb 76                	jmp    f01034d5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010345f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103463:	89 34 24             	mov    %esi,(%esp)
f0103466:	e8 60 03 00 00       	call   f01037cb <strnlen>
f010346b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010346e:	29 c2                	sub    %eax,%edx
f0103470:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103473:	85 d2                	test   %edx,%edx
f0103475:	7e d8                	jle    f010344f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103477:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010347b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010347e:	89 d6                	mov    %edx,%esi
f0103480:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103483:	89 c7                	mov    %eax,%edi
f0103485:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103489:	89 3c 24             	mov    %edi,(%esp)
f010348c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010348f:	83 ee 01             	sub    $0x1,%esi
f0103492:	75 f1                	jne    f0103485 <vprintfmt+0x1fb>
f0103494:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103497:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010349a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010349d:	eb b0                	jmp    f010344f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010349f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01034a3:	74 18                	je     f01034bd <vprintfmt+0x233>
f01034a5:	8d 50 e0             	lea    -0x20(%eax),%edx
f01034a8:	83 fa 5e             	cmp    $0x5e,%edx
f01034ab:	76 10                	jbe    f01034bd <vprintfmt+0x233>
					putch('?', putdat);
f01034ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034b1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01034b8:	ff 55 08             	call   *0x8(%ebp)
f01034bb:	eb 0a                	jmp    f01034c7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f01034bd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034c1:	89 04 24             	mov    %eax,(%esp)
f01034c4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034c7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01034cb:	0f be 06             	movsbl (%esi),%eax
f01034ce:	83 c6 01             	add    $0x1,%esi
f01034d1:	85 c0                	test   %eax,%eax
f01034d3:	75 0e                	jne    f01034e3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01034d8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01034dc:	7f 16                	jg     f01034f4 <vprintfmt+0x26a>
f01034de:	e9 ca fd ff ff       	jmp    f01032ad <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01034e3:	85 ff                	test   %edi,%edi
f01034e5:	78 b8                	js     f010349f <vprintfmt+0x215>
f01034e7:	83 ef 01             	sub    $0x1,%edi
f01034ea:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01034f0:	79 ad                	jns    f010349f <vprintfmt+0x215>
f01034f2:	eb e1                	jmp    f01034d5 <vprintfmt+0x24b>
f01034f4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01034f7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01034fa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034fe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103505:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103507:	83 ee 01             	sub    $0x1,%esi
f010350a:	75 ee                	jne    f01034fa <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010350c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010350f:	e9 99 fd ff ff       	jmp    f01032ad <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103514:	83 f9 01             	cmp    $0x1,%ecx
f0103517:	7e 10                	jle    f0103529 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103519:	8b 45 14             	mov    0x14(%ebp),%eax
f010351c:	8d 50 08             	lea    0x8(%eax),%edx
f010351f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103522:	8b 30                	mov    (%eax),%esi
f0103524:	8b 78 04             	mov    0x4(%eax),%edi
f0103527:	eb 26                	jmp    f010354f <vprintfmt+0x2c5>
	else if (lflag)
f0103529:	85 c9                	test   %ecx,%ecx
f010352b:	74 12                	je     f010353f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010352d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103530:	8d 50 04             	lea    0x4(%eax),%edx
f0103533:	89 55 14             	mov    %edx,0x14(%ebp)
f0103536:	8b 30                	mov    (%eax),%esi
f0103538:	89 f7                	mov    %esi,%edi
f010353a:	c1 ff 1f             	sar    $0x1f,%edi
f010353d:	eb 10                	jmp    f010354f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010353f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103542:	8d 50 04             	lea    0x4(%eax),%edx
f0103545:	89 55 14             	mov    %edx,0x14(%ebp)
f0103548:	8b 30                	mov    (%eax),%esi
f010354a:	89 f7                	mov    %esi,%edi
f010354c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010354f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103554:	85 ff                	test   %edi,%edi
f0103556:	0f 89 8c 00 00 00    	jns    f01035e8 <vprintfmt+0x35e>
				putch('-', putdat);
f010355c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103560:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103567:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010356a:	f7 de                	neg    %esi
f010356c:	83 d7 00             	adc    $0x0,%edi
f010356f:	f7 df                	neg    %edi
			}
			base = 10;
f0103571:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103576:	eb 70                	jmp    f01035e8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103578:	89 ca                	mov    %ecx,%edx
f010357a:	8d 45 14             	lea    0x14(%ebp),%eax
f010357d:	e8 89 fc ff ff       	call   f010320b <getuint>
f0103582:	89 c6                	mov    %eax,%esi
f0103584:	89 d7                	mov    %edx,%edi
			base = 10;
f0103586:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010358b:	eb 5b                	jmp    f01035e8 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap, lflag);
f010358d:	89 ca                	mov    %ecx,%edx
f010358f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103592:	e8 74 fc ff ff       	call   f010320b <getuint>
f0103597:	89 c6                	mov    %eax,%esi
f0103599:	89 d7                	mov    %edx,%edi
            base = 8;
f010359b:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f01035a0:	eb 46                	jmp    f01035e8 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f01035a2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035a6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f01035ad:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01035b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035b4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01035bb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01035be:	8b 45 14             	mov    0x14(%ebp),%eax
f01035c1:	8d 50 04             	lea    0x4(%eax),%edx
f01035c4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01035c7:	8b 30                	mov    (%eax),%esi
f01035c9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01035ce:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01035d3:	eb 13                	jmp    f01035e8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01035d5:	89 ca                	mov    %ecx,%edx
f01035d7:	8d 45 14             	lea    0x14(%ebp),%eax
f01035da:	e8 2c fc ff ff       	call   f010320b <getuint>
f01035df:	89 c6                	mov    %eax,%esi
f01035e1:	89 d7                	mov    %edx,%edi
			base = 16;
f01035e3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01035e8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01035ec:	89 54 24 10          	mov    %edx,0x10(%esp)
f01035f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01035f3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035f7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01035fb:	89 34 24             	mov    %esi,(%esp)
f01035fe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103602:	89 da                	mov    %ebx,%edx
f0103604:	8b 45 08             	mov    0x8(%ebp),%eax
f0103607:	e8 24 fb ff ff       	call   f0103130 <printnum>
			break;
f010360c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010360f:	e9 99 fc ff ff       	jmp    f01032ad <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103614:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103618:	89 14 24             	mov    %edx,(%esp)
f010361b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010361e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103621:	e9 87 fc ff ff       	jmp    f01032ad <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103626:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010362a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103631:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103634:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103638:	0f 84 6f fc ff ff    	je     f01032ad <vprintfmt+0x23>
f010363e:	83 ee 01             	sub    $0x1,%esi
f0103641:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103645:	75 f7                	jne    f010363e <vprintfmt+0x3b4>
f0103647:	e9 61 fc ff ff       	jmp    f01032ad <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010364c:	83 c4 4c             	add    $0x4c,%esp
f010364f:	5b                   	pop    %ebx
f0103650:	5e                   	pop    %esi
f0103651:	5f                   	pop    %edi
f0103652:	5d                   	pop    %ebp
f0103653:	c3                   	ret    

f0103654 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103654:	55                   	push   %ebp
f0103655:	89 e5                	mov    %esp,%ebp
f0103657:	83 ec 28             	sub    $0x28,%esp
f010365a:	8b 45 08             	mov    0x8(%ebp),%eax
f010365d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103660:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103663:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103667:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010366a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103671:	85 c0                	test   %eax,%eax
f0103673:	74 30                	je     f01036a5 <vsnprintf+0x51>
f0103675:	85 d2                	test   %edx,%edx
f0103677:	7e 2c                	jle    f01036a5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103679:	8b 45 14             	mov    0x14(%ebp),%eax
f010367c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103680:	8b 45 10             	mov    0x10(%ebp),%eax
f0103683:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103687:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010368a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010368e:	c7 04 24 45 32 10 f0 	movl   $0xf0103245,(%esp)
f0103695:	e8 f0 fb ff ff       	call   f010328a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010369a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010369d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01036a0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01036a3:	eb 05                	jmp    f01036aa <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01036a5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01036aa:	c9                   	leave  
f01036ab:	c3                   	ret    

f01036ac <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01036ac:	55                   	push   %ebp
f01036ad:	89 e5                	mov    %esp,%ebp
f01036af:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01036b2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01036b5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036b9:	8b 45 10             	mov    0x10(%ebp),%eax
f01036bc:	89 44 24 08          	mov    %eax,0x8(%esp)
f01036c0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036c3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01036ca:	89 04 24             	mov    %eax,(%esp)
f01036cd:	e8 82 ff ff ff       	call   f0103654 <vsnprintf>
	va_end(ap);

	return rc;
}
f01036d2:	c9                   	leave  
f01036d3:	c3                   	ret    
	...

f01036e0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01036e0:	55                   	push   %ebp
f01036e1:	89 e5                	mov    %esp,%ebp
f01036e3:	57                   	push   %edi
f01036e4:	56                   	push   %esi
f01036e5:	53                   	push   %ebx
f01036e6:	83 ec 1c             	sub    $0x1c,%esp
f01036e9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01036ec:	85 c0                	test   %eax,%eax
f01036ee:	74 10                	je     f0103700 <readline+0x20>
		cprintf("%s", prompt);
f01036f0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036f4:	c7 04 24 d6 4a 10 f0 	movl   $0xf0104ad6,(%esp)
f01036fb:	e8 2a f7 ff ff       	call   f0102e2a <cprintf>

	i = 0;
	echoing = iscons(0);
f0103700:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103707:	e8 07 cf ff ff       	call   f0100613 <iscons>
f010370c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010370e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103713:	e8 ea ce ff ff       	call   f0100602 <getchar>
f0103718:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010371a:	85 c0                	test   %eax,%eax
f010371c:	79 17                	jns    f0103735 <readline+0x55>
			cprintf("read error: %e\n", c);
f010371e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103722:	c7 04 24 0c 50 10 f0 	movl   $0xf010500c,(%esp)
f0103729:	e8 fc f6 ff ff       	call   f0102e2a <cprintf>
			return NULL;
f010372e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103733:	eb 6d                	jmp    f01037a2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103735:	83 f8 08             	cmp    $0x8,%eax
f0103738:	74 05                	je     f010373f <readline+0x5f>
f010373a:	83 f8 7f             	cmp    $0x7f,%eax
f010373d:	75 19                	jne    f0103758 <readline+0x78>
f010373f:	85 f6                	test   %esi,%esi
f0103741:	7e 15                	jle    f0103758 <readline+0x78>
			if (echoing)
f0103743:	85 ff                	test   %edi,%edi
f0103745:	74 0c                	je     f0103753 <readline+0x73>
				cputchar('\b');
f0103747:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010374e:	e8 9f ce ff ff       	call   f01005f2 <cputchar>
			i--;
f0103753:	83 ee 01             	sub    $0x1,%esi
f0103756:	eb bb                	jmp    f0103713 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103758:	83 fb 1f             	cmp    $0x1f,%ebx
f010375b:	7e 1f                	jle    f010377c <readline+0x9c>
f010375d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103763:	7f 17                	jg     f010377c <readline+0x9c>
			if (echoing)
f0103765:	85 ff                	test   %edi,%edi
f0103767:	74 08                	je     f0103771 <readline+0x91>
				cputchar(c);
f0103769:	89 1c 24             	mov    %ebx,(%esp)
f010376c:	e8 81 ce ff ff       	call   f01005f2 <cputchar>
			buf[i++] = c;
f0103771:	88 9e 80 75 11 f0    	mov    %bl,-0xfee8a80(%esi)
f0103777:	83 c6 01             	add    $0x1,%esi
f010377a:	eb 97                	jmp    f0103713 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010377c:	83 fb 0a             	cmp    $0xa,%ebx
f010377f:	74 05                	je     f0103786 <readline+0xa6>
f0103781:	83 fb 0d             	cmp    $0xd,%ebx
f0103784:	75 8d                	jne    f0103713 <readline+0x33>
			if (echoing)
f0103786:	85 ff                	test   %edi,%edi
f0103788:	74 0c                	je     f0103796 <readline+0xb6>
				cputchar('\n');
f010378a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103791:	e8 5c ce ff ff       	call   f01005f2 <cputchar>
			buf[i] = 0;
f0103796:	c6 86 80 75 11 f0 00 	movb   $0x0,-0xfee8a80(%esi)
			return buf;
f010379d:	b8 80 75 11 f0       	mov    $0xf0117580,%eax
		}
	}
}
f01037a2:	83 c4 1c             	add    $0x1c,%esp
f01037a5:	5b                   	pop    %ebx
f01037a6:	5e                   	pop    %esi
f01037a7:	5f                   	pop    %edi
f01037a8:	5d                   	pop    %ebp
f01037a9:	c3                   	ret    
f01037aa:	00 00                	add    %al,(%eax)
f01037ac:	00 00                	add    %al,(%eax)
	...

f01037b0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01037b0:	55                   	push   %ebp
f01037b1:	89 e5                	mov    %esp,%ebp
f01037b3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01037b6:	b8 00 00 00 00       	mov    $0x0,%eax
f01037bb:	80 3a 00             	cmpb   $0x0,(%edx)
f01037be:	74 09                	je     f01037c9 <strlen+0x19>
		n++;
f01037c0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01037c3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01037c7:	75 f7                	jne    f01037c0 <strlen+0x10>
		n++;
	return n;
}
f01037c9:	5d                   	pop    %ebp
f01037ca:	c3                   	ret    

f01037cb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01037cb:	55                   	push   %ebp
f01037cc:	89 e5                	mov    %esp,%ebp
f01037ce:	53                   	push   %ebx
f01037cf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01037d2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037d5:	b8 00 00 00 00       	mov    $0x0,%eax
f01037da:	85 c9                	test   %ecx,%ecx
f01037dc:	74 1a                	je     f01037f8 <strnlen+0x2d>
f01037de:	80 3b 00             	cmpb   $0x0,(%ebx)
f01037e1:	74 15                	je     f01037f8 <strnlen+0x2d>
f01037e3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01037e8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01037ea:	39 ca                	cmp    %ecx,%edx
f01037ec:	74 0a                	je     f01037f8 <strnlen+0x2d>
f01037ee:	83 c2 01             	add    $0x1,%edx
f01037f1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01037f6:	75 f0                	jne    f01037e8 <strnlen+0x1d>
		n++;
	return n;
}
f01037f8:	5b                   	pop    %ebx
f01037f9:	5d                   	pop    %ebp
f01037fa:	c3                   	ret    

f01037fb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01037fb:	55                   	push   %ebp
f01037fc:	89 e5                	mov    %esp,%ebp
f01037fe:	53                   	push   %ebx
f01037ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0103802:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103805:	ba 00 00 00 00       	mov    $0x0,%edx
f010380a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010380e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103811:	83 c2 01             	add    $0x1,%edx
f0103814:	84 c9                	test   %cl,%cl
f0103816:	75 f2                	jne    f010380a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103818:	5b                   	pop    %ebx
f0103819:	5d                   	pop    %ebp
f010381a:	c3                   	ret    

f010381b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010381b:	55                   	push   %ebp
f010381c:	89 e5                	mov    %esp,%ebp
f010381e:	56                   	push   %esi
f010381f:	53                   	push   %ebx
f0103820:	8b 45 08             	mov    0x8(%ebp),%eax
f0103823:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103826:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103829:	85 f6                	test   %esi,%esi
f010382b:	74 18                	je     f0103845 <strncpy+0x2a>
f010382d:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103832:	0f b6 1a             	movzbl (%edx),%ebx
f0103835:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103838:	80 3a 01             	cmpb   $0x1,(%edx)
f010383b:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010383e:	83 c1 01             	add    $0x1,%ecx
f0103841:	39 f1                	cmp    %esi,%ecx
f0103843:	75 ed                	jne    f0103832 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103845:	5b                   	pop    %ebx
f0103846:	5e                   	pop    %esi
f0103847:	5d                   	pop    %ebp
f0103848:	c3                   	ret    

f0103849 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103849:	55                   	push   %ebp
f010384a:	89 e5                	mov    %esp,%ebp
f010384c:	57                   	push   %edi
f010384d:	56                   	push   %esi
f010384e:	53                   	push   %ebx
f010384f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103852:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103855:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103858:	89 f8                	mov    %edi,%eax
f010385a:	85 f6                	test   %esi,%esi
f010385c:	74 2b                	je     f0103889 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f010385e:	83 fe 01             	cmp    $0x1,%esi
f0103861:	74 23                	je     f0103886 <strlcpy+0x3d>
f0103863:	0f b6 0b             	movzbl (%ebx),%ecx
f0103866:	84 c9                	test   %cl,%cl
f0103868:	74 1c                	je     f0103886 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f010386a:	83 ee 02             	sub    $0x2,%esi
f010386d:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103872:	88 08                	mov    %cl,(%eax)
f0103874:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103877:	39 f2                	cmp    %esi,%edx
f0103879:	74 0b                	je     f0103886 <strlcpy+0x3d>
f010387b:	83 c2 01             	add    $0x1,%edx
f010387e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103882:	84 c9                	test   %cl,%cl
f0103884:	75 ec                	jne    f0103872 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103886:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103889:	29 f8                	sub    %edi,%eax
}
f010388b:	5b                   	pop    %ebx
f010388c:	5e                   	pop    %esi
f010388d:	5f                   	pop    %edi
f010388e:	5d                   	pop    %ebp
f010388f:	c3                   	ret    

f0103890 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103890:	55                   	push   %ebp
f0103891:	89 e5                	mov    %esp,%ebp
f0103893:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103896:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103899:	0f b6 01             	movzbl (%ecx),%eax
f010389c:	84 c0                	test   %al,%al
f010389e:	74 16                	je     f01038b6 <strcmp+0x26>
f01038a0:	3a 02                	cmp    (%edx),%al
f01038a2:	75 12                	jne    f01038b6 <strcmp+0x26>
		p++, q++;
f01038a4:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01038a7:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01038ab:	84 c0                	test   %al,%al
f01038ad:	74 07                	je     f01038b6 <strcmp+0x26>
f01038af:	83 c1 01             	add    $0x1,%ecx
f01038b2:	3a 02                	cmp    (%edx),%al
f01038b4:	74 ee                	je     f01038a4 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01038b6:	0f b6 c0             	movzbl %al,%eax
f01038b9:	0f b6 12             	movzbl (%edx),%edx
f01038bc:	29 d0                	sub    %edx,%eax
}
f01038be:	5d                   	pop    %ebp
f01038bf:	c3                   	ret    

f01038c0 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01038c0:	55                   	push   %ebp
f01038c1:	89 e5                	mov    %esp,%ebp
f01038c3:	53                   	push   %ebx
f01038c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01038c7:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038ca:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038cd:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038d2:	85 d2                	test   %edx,%edx
f01038d4:	74 28                	je     f01038fe <strncmp+0x3e>
f01038d6:	0f b6 01             	movzbl (%ecx),%eax
f01038d9:	84 c0                	test   %al,%al
f01038db:	74 24                	je     f0103901 <strncmp+0x41>
f01038dd:	3a 03                	cmp    (%ebx),%al
f01038df:	75 20                	jne    f0103901 <strncmp+0x41>
f01038e1:	83 ea 01             	sub    $0x1,%edx
f01038e4:	74 13                	je     f01038f9 <strncmp+0x39>
		n--, p++, q++;
f01038e6:	83 c1 01             	add    $0x1,%ecx
f01038e9:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01038ec:	0f b6 01             	movzbl (%ecx),%eax
f01038ef:	84 c0                	test   %al,%al
f01038f1:	74 0e                	je     f0103901 <strncmp+0x41>
f01038f3:	3a 03                	cmp    (%ebx),%al
f01038f5:	74 ea                	je     f01038e1 <strncmp+0x21>
f01038f7:	eb 08                	jmp    f0103901 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01038f9:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01038fe:	5b                   	pop    %ebx
f01038ff:	5d                   	pop    %ebp
f0103900:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103901:	0f b6 01             	movzbl (%ecx),%eax
f0103904:	0f b6 13             	movzbl (%ebx),%edx
f0103907:	29 d0                	sub    %edx,%eax
f0103909:	eb f3                	jmp    f01038fe <strncmp+0x3e>

f010390b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010390b:	55                   	push   %ebp
f010390c:	89 e5                	mov    %esp,%ebp
f010390e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103911:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103915:	0f b6 10             	movzbl (%eax),%edx
f0103918:	84 d2                	test   %dl,%dl
f010391a:	74 1c                	je     f0103938 <strchr+0x2d>
		if (*s == c)
f010391c:	38 ca                	cmp    %cl,%dl
f010391e:	75 09                	jne    f0103929 <strchr+0x1e>
f0103920:	eb 1b                	jmp    f010393d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103922:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103925:	38 ca                	cmp    %cl,%dl
f0103927:	74 14                	je     f010393d <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103929:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f010392d:	84 d2                	test   %dl,%dl
f010392f:	75 f1                	jne    f0103922 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103931:	b8 00 00 00 00       	mov    $0x0,%eax
f0103936:	eb 05                	jmp    f010393d <strchr+0x32>
f0103938:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010393d:	5d                   	pop    %ebp
f010393e:	c3                   	ret    

f010393f <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010393f:	55                   	push   %ebp
f0103940:	89 e5                	mov    %esp,%ebp
f0103942:	8b 45 08             	mov    0x8(%ebp),%eax
f0103945:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103949:	0f b6 10             	movzbl (%eax),%edx
f010394c:	84 d2                	test   %dl,%dl
f010394e:	74 14                	je     f0103964 <strfind+0x25>
		if (*s == c)
f0103950:	38 ca                	cmp    %cl,%dl
f0103952:	75 06                	jne    f010395a <strfind+0x1b>
f0103954:	eb 0e                	jmp    f0103964 <strfind+0x25>
f0103956:	38 ca                	cmp    %cl,%dl
f0103958:	74 0a                	je     f0103964 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010395a:	83 c0 01             	add    $0x1,%eax
f010395d:	0f b6 10             	movzbl (%eax),%edx
f0103960:	84 d2                	test   %dl,%dl
f0103962:	75 f2                	jne    f0103956 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103964:	5d                   	pop    %ebp
f0103965:	c3                   	ret    

f0103966 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103966:	55                   	push   %ebp
f0103967:	89 e5                	mov    %esp,%ebp
f0103969:	83 ec 0c             	sub    $0xc,%esp
f010396c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010396f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103972:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103975:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103978:	8b 45 0c             	mov    0xc(%ebp),%eax
f010397b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010397e:	85 c9                	test   %ecx,%ecx
f0103980:	74 30                	je     f01039b2 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103982:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103988:	75 25                	jne    f01039af <memset+0x49>
f010398a:	f6 c1 03             	test   $0x3,%cl
f010398d:	75 20                	jne    f01039af <memset+0x49>
		c &= 0xFF;
f010398f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103992:	89 d3                	mov    %edx,%ebx
f0103994:	c1 e3 08             	shl    $0x8,%ebx
f0103997:	89 d6                	mov    %edx,%esi
f0103999:	c1 e6 18             	shl    $0x18,%esi
f010399c:	89 d0                	mov    %edx,%eax
f010399e:	c1 e0 10             	shl    $0x10,%eax
f01039a1:	09 f0                	or     %esi,%eax
f01039a3:	09 d0                	or     %edx,%eax
f01039a5:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01039a7:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01039aa:	fc                   	cld    
f01039ab:	f3 ab                	rep stos %eax,%es:(%edi)
f01039ad:	eb 03                	jmp    f01039b2 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01039af:	fc                   	cld    
f01039b0:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01039b2:	89 f8                	mov    %edi,%eax
f01039b4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01039b7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01039ba:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01039bd:	89 ec                	mov    %ebp,%esp
f01039bf:	5d                   	pop    %ebp
f01039c0:	c3                   	ret    

f01039c1 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01039c1:	55                   	push   %ebp
f01039c2:	89 e5                	mov    %esp,%ebp
f01039c4:	83 ec 08             	sub    $0x8,%esp
f01039c7:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01039ca:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01039cd:	8b 45 08             	mov    0x8(%ebp),%eax
f01039d0:	8b 75 0c             	mov    0xc(%ebp),%esi
f01039d3:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01039d6:	39 c6                	cmp    %eax,%esi
f01039d8:	73 36                	jae    f0103a10 <memmove+0x4f>
f01039da:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01039dd:	39 d0                	cmp    %edx,%eax
f01039df:	73 2f                	jae    f0103a10 <memmove+0x4f>
		s += n;
		d += n;
f01039e1:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01039e4:	f6 c2 03             	test   $0x3,%dl
f01039e7:	75 1b                	jne    f0103a04 <memmove+0x43>
f01039e9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01039ef:	75 13                	jne    f0103a04 <memmove+0x43>
f01039f1:	f6 c1 03             	test   $0x3,%cl
f01039f4:	75 0e                	jne    f0103a04 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01039f6:	83 ef 04             	sub    $0x4,%edi
f01039f9:	8d 72 fc             	lea    -0x4(%edx),%esi
f01039fc:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01039ff:	fd                   	std    
f0103a00:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a02:	eb 09                	jmp    f0103a0d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103a04:	83 ef 01             	sub    $0x1,%edi
f0103a07:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103a0a:	fd                   	std    
f0103a0b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103a0d:	fc                   	cld    
f0103a0e:	eb 20                	jmp    f0103a30 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103a10:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103a16:	75 13                	jne    f0103a2b <memmove+0x6a>
f0103a18:	a8 03                	test   $0x3,%al
f0103a1a:	75 0f                	jne    f0103a2b <memmove+0x6a>
f0103a1c:	f6 c1 03             	test   $0x3,%cl
f0103a1f:	75 0a                	jne    f0103a2b <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103a21:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103a24:	89 c7                	mov    %eax,%edi
f0103a26:	fc                   	cld    
f0103a27:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103a29:	eb 05                	jmp    f0103a30 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103a2b:	89 c7                	mov    %eax,%edi
f0103a2d:	fc                   	cld    
f0103a2e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103a30:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103a33:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103a36:	89 ec                	mov    %ebp,%esp
f0103a38:	5d                   	pop    %ebp
f0103a39:	c3                   	ret    

f0103a3a <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f0103a3a:	55                   	push   %ebp
f0103a3b:	89 e5                	mov    %esp,%ebp
f0103a3d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103a40:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a43:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a47:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a4e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a51:	89 04 24             	mov    %eax,(%esp)
f0103a54:	e8 68 ff ff ff       	call   f01039c1 <memmove>
}
f0103a59:	c9                   	leave  
f0103a5a:	c3                   	ret    

f0103a5b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103a5b:	55                   	push   %ebp
f0103a5c:	89 e5                	mov    %esp,%ebp
f0103a5e:	57                   	push   %edi
f0103a5f:	56                   	push   %esi
f0103a60:	53                   	push   %ebx
f0103a61:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a64:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103a67:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103a6a:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a6f:	85 ff                	test   %edi,%edi
f0103a71:	74 37                	je     f0103aaa <memcmp+0x4f>
		if (*s1 != *s2)
f0103a73:	0f b6 03             	movzbl (%ebx),%eax
f0103a76:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103a79:	83 ef 01             	sub    $0x1,%edi
f0103a7c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103a81:	38 c8                	cmp    %cl,%al
f0103a83:	74 1c                	je     f0103aa1 <memcmp+0x46>
f0103a85:	eb 10                	jmp    f0103a97 <memcmp+0x3c>
f0103a87:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103a8c:	83 c2 01             	add    $0x1,%edx
f0103a8f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103a93:	38 c8                	cmp    %cl,%al
f0103a95:	74 0a                	je     f0103aa1 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103a97:	0f b6 c0             	movzbl %al,%eax
f0103a9a:	0f b6 c9             	movzbl %cl,%ecx
f0103a9d:	29 c8                	sub    %ecx,%eax
f0103a9f:	eb 09                	jmp    f0103aaa <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103aa1:	39 fa                	cmp    %edi,%edx
f0103aa3:	75 e2                	jne    f0103a87 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103aa5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103aaa:	5b                   	pop    %ebx
f0103aab:	5e                   	pop    %esi
f0103aac:	5f                   	pop    %edi
f0103aad:	5d                   	pop    %ebp
f0103aae:	c3                   	ret    

f0103aaf <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103aaf:	55                   	push   %ebp
f0103ab0:	89 e5                	mov    %esp,%ebp
f0103ab2:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103ab5:	89 c2                	mov    %eax,%edx
f0103ab7:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103aba:	39 d0                	cmp    %edx,%eax
f0103abc:	73 15                	jae    f0103ad3 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103abe:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103ac2:	38 08                	cmp    %cl,(%eax)
f0103ac4:	75 06                	jne    f0103acc <memfind+0x1d>
f0103ac6:	eb 0b                	jmp    f0103ad3 <memfind+0x24>
f0103ac8:	38 08                	cmp    %cl,(%eax)
f0103aca:	74 07                	je     f0103ad3 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103acc:	83 c0 01             	add    $0x1,%eax
f0103acf:	39 d0                	cmp    %edx,%eax
f0103ad1:	75 f5                	jne    f0103ac8 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103ad3:	5d                   	pop    %ebp
f0103ad4:	c3                   	ret    

f0103ad5 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103ad5:	55                   	push   %ebp
f0103ad6:	89 e5                	mov    %esp,%ebp
f0103ad8:	57                   	push   %edi
f0103ad9:	56                   	push   %esi
f0103ada:	53                   	push   %ebx
f0103adb:	8b 55 08             	mov    0x8(%ebp),%edx
f0103ade:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103ae1:	0f b6 02             	movzbl (%edx),%eax
f0103ae4:	3c 20                	cmp    $0x20,%al
f0103ae6:	74 04                	je     f0103aec <strtol+0x17>
f0103ae8:	3c 09                	cmp    $0x9,%al
f0103aea:	75 0e                	jne    f0103afa <strtol+0x25>
		s++;
f0103aec:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103aef:	0f b6 02             	movzbl (%edx),%eax
f0103af2:	3c 20                	cmp    $0x20,%al
f0103af4:	74 f6                	je     f0103aec <strtol+0x17>
f0103af6:	3c 09                	cmp    $0x9,%al
f0103af8:	74 f2                	je     f0103aec <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103afa:	3c 2b                	cmp    $0x2b,%al
f0103afc:	75 0a                	jne    f0103b08 <strtol+0x33>
		s++;
f0103afe:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103b01:	bf 00 00 00 00       	mov    $0x0,%edi
f0103b06:	eb 10                	jmp    f0103b18 <strtol+0x43>
f0103b08:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103b0d:	3c 2d                	cmp    $0x2d,%al
f0103b0f:	75 07                	jne    f0103b18 <strtol+0x43>
		s++, neg = 1;
f0103b11:	83 c2 01             	add    $0x1,%edx
f0103b14:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103b18:	85 db                	test   %ebx,%ebx
f0103b1a:	0f 94 c0             	sete   %al
f0103b1d:	74 05                	je     f0103b24 <strtol+0x4f>
f0103b1f:	83 fb 10             	cmp    $0x10,%ebx
f0103b22:	75 15                	jne    f0103b39 <strtol+0x64>
f0103b24:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b27:	75 10                	jne    f0103b39 <strtol+0x64>
f0103b29:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103b2d:	75 0a                	jne    f0103b39 <strtol+0x64>
		s += 2, base = 16;
f0103b2f:	83 c2 02             	add    $0x2,%edx
f0103b32:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103b37:	eb 13                	jmp    f0103b4c <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103b39:	84 c0                	test   %al,%al
f0103b3b:	74 0f                	je     f0103b4c <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103b3d:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103b42:	80 3a 30             	cmpb   $0x30,(%edx)
f0103b45:	75 05                	jne    f0103b4c <strtol+0x77>
		s++, base = 8;
f0103b47:	83 c2 01             	add    $0x1,%edx
f0103b4a:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103b4c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b51:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103b53:	0f b6 0a             	movzbl (%edx),%ecx
f0103b56:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103b59:	80 fb 09             	cmp    $0x9,%bl
f0103b5c:	77 08                	ja     f0103b66 <strtol+0x91>
			dig = *s - '0';
f0103b5e:	0f be c9             	movsbl %cl,%ecx
f0103b61:	83 e9 30             	sub    $0x30,%ecx
f0103b64:	eb 1e                	jmp    f0103b84 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103b66:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103b69:	80 fb 19             	cmp    $0x19,%bl
f0103b6c:	77 08                	ja     f0103b76 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103b6e:	0f be c9             	movsbl %cl,%ecx
f0103b71:	83 e9 57             	sub    $0x57,%ecx
f0103b74:	eb 0e                	jmp    f0103b84 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103b76:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103b79:	80 fb 19             	cmp    $0x19,%bl
f0103b7c:	77 14                	ja     f0103b92 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103b7e:	0f be c9             	movsbl %cl,%ecx
f0103b81:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103b84:	39 f1                	cmp    %esi,%ecx
f0103b86:	7d 0e                	jge    f0103b96 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103b88:	83 c2 01             	add    $0x1,%edx
f0103b8b:	0f af c6             	imul   %esi,%eax
f0103b8e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103b90:	eb c1                	jmp    f0103b53 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103b92:	89 c1                	mov    %eax,%ecx
f0103b94:	eb 02                	jmp    f0103b98 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103b96:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103b98:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103b9c:	74 05                	je     f0103ba3 <strtol+0xce>
		*endptr = (char *) s;
f0103b9e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103ba1:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103ba3:	89 ca                	mov    %ecx,%edx
f0103ba5:	f7 da                	neg    %edx
f0103ba7:	85 ff                	test   %edi,%edi
f0103ba9:	0f 45 c2             	cmovne %edx,%eax
}
f0103bac:	5b                   	pop    %ebx
f0103bad:	5e                   	pop    %esi
f0103bae:	5f                   	pop    %edi
f0103baf:	5d                   	pop    %ebp
f0103bb0:	c3                   	ret    
	...

f0103bc0 <__udivdi3>:
f0103bc0:	83 ec 1c             	sub    $0x1c,%esp
f0103bc3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103bc7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103bcb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103bcf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103bd3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103bd7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103bdb:	85 ff                	test   %edi,%edi
f0103bdd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103be1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103be5:	89 cd                	mov    %ecx,%ebp
f0103be7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103beb:	75 33                	jne    f0103c20 <__udivdi3+0x60>
f0103bed:	39 f1                	cmp    %esi,%ecx
f0103bef:	77 57                	ja     f0103c48 <__udivdi3+0x88>
f0103bf1:	85 c9                	test   %ecx,%ecx
f0103bf3:	75 0b                	jne    f0103c00 <__udivdi3+0x40>
f0103bf5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103bfa:	31 d2                	xor    %edx,%edx
f0103bfc:	f7 f1                	div    %ecx
f0103bfe:	89 c1                	mov    %eax,%ecx
f0103c00:	89 f0                	mov    %esi,%eax
f0103c02:	31 d2                	xor    %edx,%edx
f0103c04:	f7 f1                	div    %ecx
f0103c06:	89 c6                	mov    %eax,%esi
f0103c08:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103c0c:	f7 f1                	div    %ecx
f0103c0e:	89 f2                	mov    %esi,%edx
f0103c10:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c14:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c18:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c1c:	83 c4 1c             	add    $0x1c,%esp
f0103c1f:	c3                   	ret    
f0103c20:	31 d2                	xor    %edx,%edx
f0103c22:	31 c0                	xor    %eax,%eax
f0103c24:	39 f7                	cmp    %esi,%edi
f0103c26:	77 e8                	ja     f0103c10 <__udivdi3+0x50>
f0103c28:	0f bd cf             	bsr    %edi,%ecx
f0103c2b:	83 f1 1f             	xor    $0x1f,%ecx
f0103c2e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103c32:	75 2c                	jne    f0103c60 <__udivdi3+0xa0>
f0103c34:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103c38:	76 04                	jbe    f0103c3e <__udivdi3+0x7e>
f0103c3a:	39 f7                	cmp    %esi,%edi
f0103c3c:	73 d2                	jae    f0103c10 <__udivdi3+0x50>
f0103c3e:	31 d2                	xor    %edx,%edx
f0103c40:	b8 01 00 00 00       	mov    $0x1,%eax
f0103c45:	eb c9                	jmp    f0103c10 <__udivdi3+0x50>
f0103c47:	90                   	nop
f0103c48:	89 f2                	mov    %esi,%edx
f0103c4a:	f7 f1                	div    %ecx
f0103c4c:	31 d2                	xor    %edx,%edx
f0103c4e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103c52:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103c56:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103c5a:	83 c4 1c             	add    $0x1c,%esp
f0103c5d:	c3                   	ret    
f0103c5e:	66 90                	xchg   %ax,%ax
f0103c60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c65:	b8 20 00 00 00       	mov    $0x20,%eax
f0103c6a:	89 ea                	mov    %ebp,%edx
f0103c6c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103c70:	d3 e7                	shl    %cl,%edi
f0103c72:	89 c1                	mov    %eax,%ecx
f0103c74:	d3 ea                	shr    %cl,%edx
f0103c76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c7b:	09 fa                	or     %edi,%edx
f0103c7d:	89 f7                	mov    %esi,%edi
f0103c7f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c83:	89 f2                	mov    %esi,%edx
f0103c85:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103c89:	d3 e5                	shl    %cl,%ebp
f0103c8b:	89 c1                	mov    %eax,%ecx
f0103c8d:	d3 ef                	shr    %cl,%edi
f0103c8f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103c94:	d3 e2                	shl    %cl,%edx
f0103c96:	89 c1                	mov    %eax,%ecx
f0103c98:	d3 ee                	shr    %cl,%esi
f0103c9a:	09 d6                	or     %edx,%esi
f0103c9c:	89 fa                	mov    %edi,%edx
f0103c9e:	89 f0                	mov    %esi,%eax
f0103ca0:	f7 74 24 0c          	divl   0xc(%esp)
f0103ca4:	89 d7                	mov    %edx,%edi
f0103ca6:	89 c6                	mov    %eax,%esi
f0103ca8:	f7 e5                	mul    %ebp
f0103caa:	39 d7                	cmp    %edx,%edi
f0103cac:	72 22                	jb     f0103cd0 <__udivdi3+0x110>
f0103cae:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103cb2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103cb7:	d3 e5                	shl    %cl,%ebp
f0103cb9:	39 c5                	cmp    %eax,%ebp
f0103cbb:	73 04                	jae    f0103cc1 <__udivdi3+0x101>
f0103cbd:	39 d7                	cmp    %edx,%edi
f0103cbf:	74 0f                	je     f0103cd0 <__udivdi3+0x110>
f0103cc1:	89 f0                	mov    %esi,%eax
f0103cc3:	31 d2                	xor    %edx,%edx
f0103cc5:	e9 46 ff ff ff       	jmp    f0103c10 <__udivdi3+0x50>
f0103cca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cd0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103cd3:	31 d2                	xor    %edx,%edx
f0103cd5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103cd9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103cdd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ce1:	83 c4 1c             	add    $0x1c,%esp
f0103ce4:	c3                   	ret    
	...

f0103cf0 <__umoddi3>:
f0103cf0:	83 ec 1c             	sub    $0x1c,%esp
f0103cf3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103cf7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103cfb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103cff:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103d03:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103d07:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103d0b:	85 ed                	test   %ebp,%ebp
f0103d0d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103d11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d15:	89 cf                	mov    %ecx,%edi
f0103d17:	89 04 24             	mov    %eax,(%esp)
f0103d1a:	89 f2                	mov    %esi,%edx
f0103d1c:	75 1a                	jne    f0103d38 <__umoddi3+0x48>
f0103d1e:	39 f1                	cmp    %esi,%ecx
f0103d20:	76 4e                	jbe    f0103d70 <__umoddi3+0x80>
f0103d22:	f7 f1                	div    %ecx
f0103d24:	89 d0                	mov    %edx,%eax
f0103d26:	31 d2                	xor    %edx,%edx
f0103d28:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d2c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d30:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d34:	83 c4 1c             	add    $0x1c,%esp
f0103d37:	c3                   	ret    
f0103d38:	39 f5                	cmp    %esi,%ebp
f0103d3a:	77 54                	ja     f0103d90 <__umoddi3+0xa0>
f0103d3c:	0f bd c5             	bsr    %ebp,%eax
f0103d3f:	83 f0 1f             	xor    $0x1f,%eax
f0103d42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d46:	75 60                	jne    f0103da8 <__umoddi3+0xb8>
f0103d48:	3b 0c 24             	cmp    (%esp),%ecx
f0103d4b:	0f 87 07 01 00 00    	ja     f0103e58 <__umoddi3+0x168>
f0103d51:	89 f2                	mov    %esi,%edx
f0103d53:	8b 34 24             	mov    (%esp),%esi
f0103d56:	29 ce                	sub    %ecx,%esi
f0103d58:	19 ea                	sbb    %ebp,%edx
f0103d5a:	89 34 24             	mov    %esi,(%esp)
f0103d5d:	8b 04 24             	mov    (%esp),%eax
f0103d60:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d64:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d68:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d6c:	83 c4 1c             	add    $0x1c,%esp
f0103d6f:	c3                   	ret    
f0103d70:	85 c9                	test   %ecx,%ecx
f0103d72:	75 0b                	jne    f0103d7f <__umoddi3+0x8f>
f0103d74:	b8 01 00 00 00       	mov    $0x1,%eax
f0103d79:	31 d2                	xor    %edx,%edx
f0103d7b:	f7 f1                	div    %ecx
f0103d7d:	89 c1                	mov    %eax,%ecx
f0103d7f:	89 f0                	mov    %esi,%eax
f0103d81:	31 d2                	xor    %edx,%edx
f0103d83:	f7 f1                	div    %ecx
f0103d85:	8b 04 24             	mov    (%esp),%eax
f0103d88:	f7 f1                	div    %ecx
f0103d8a:	eb 98                	jmp    f0103d24 <__umoddi3+0x34>
f0103d8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d90:	89 f2                	mov    %esi,%edx
f0103d92:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103d96:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103d9a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103d9e:	83 c4 1c             	add    $0x1c,%esp
f0103da1:	c3                   	ret    
f0103da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103da8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dad:	89 e8                	mov    %ebp,%eax
f0103daf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103db4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103db8:	89 fa                	mov    %edi,%edx
f0103dba:	d3 e0                	shl    %cl,%eax
f0103dbc:	89 e9                	mov    %ebp,%ecx
f0103dbe:	d3 ea                	shr    %cl,%edx
f0103dc0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dc5:	09 c2                	or     %eax,%edx
f0103dc7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103dcb:	89 14 24             	mov    %edx,(%esp)
f0103dce:	89 f2                	mov    %esi,%edx
f0103dd0:	d3 e7                	shl    %cl,%edi
f0103dd2:	89 e9                	mov    %ebp,%ecx
f0103dd4:	d3 ea                	shr    %cl,%edx
f0103dd6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ddb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103ddf:	d3 e6                	shl    %cl,%esi
f0103de1:	89 e9                	mov    %ebp,%ecx
f0103de3:	d3 e8                	shr    %cl,%eax
f0103de5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103dea:	09 f0                	or     %esi,%eax
f0103dec:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103df0:	f7 34 24             	divl   (%esp)
f0103df3:	d3 e6                	shl    %cl,%esi
f0103df5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103df9:	89 d6                	mov    %edx,%esi
f0103dfb:	f7 e7                	mul    %edi
f0103dfd:	39 d6                	cmp    %edx,%esi
f0103dff:	89 c1                	mov    %eax,%ecx
f0103e01:	89 d7                	mov    %edx,%edi
f0103e03:	72 3f                	jb     f0103e44 <__umoddi3+0x154>
f0103e05:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103e09:	72 35                	jb     f0103e40 <__umoddi3+0x150>
f0103e0b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103e0f:	29 c8                	sub    %ecx,%eax
f0103e11:	19 fe                	sbb    %edi,%esi
f0103e13:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e18:	89 f2                	mov    %esi,%edx
f0103e1a:	d3 e8                	shr    %cl,%eax
f0103e1c:	89 e9                	mov    %ebp,%ecx
f0103e1e:	d3 e2                	shl    %cl,%edx
f0103e20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e25:	09 d0                	or     %edx,%eax
f0103e27:	89 f2                	mov    %esi,%edx
f0103e29:	d3 ea                	shr    %cl,%edx
f0103e2b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e2f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e33:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e37:	83 c4 1c             	add    $0x1c,%esp
f0103e3a:	c3                   	ret    
f0103e3b:	90                   	nop
f0103e3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103e40:	39 d6                	cmp    %edx,%esi
f0103e42:	75 c7                	jne    f0103e0b <__umoddi3+0x11b>
f0103e44:	89 d7                	mov    %edx,%edi
f0103e46:	89 c1                	mov    %eax,%ecx
f0103e48:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0103e4c:	1b 3c 24             	sbb    (%esp),%edi
f0103e4f:	eb ba                	jmp    f0103e0b <__umoddi3+0x11b>
f0103e51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0103e58:	39 f5                	cmp    %esi,%ebp
f0103e5a:	0f 82 f1 fe ff ff    	jb     f0103d51 <__umoddi3+0x61>
f0103e60:	e9 f8 fe ff ff       	jmp    f0103d5d <__umoddi3+0x6d>
