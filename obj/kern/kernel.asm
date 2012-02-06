
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
	# until we set up our real page table in i386_vm_init in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 00 1a 10 f0 	movl   $0xf0101a00,(%esp)
f0100055:	e8 64 09 00 00       	call   f01009be <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 e9 06 00 00       	call   f0100770 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 1c 1a 10 f0 	movl   $0xf0101a1c,(%esp)
f0100092:	e8 27 09 00 00       	call   f01009be <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 60 29 11 f0       	mov    $0xf0112960,%eax
f01000a8:	2d 00 23 11 f0       	sub    $0xf0112300,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 00 23 11 f0 	movl   $0xf0112300,(%esp)
f01000c0:	e8 31 14 00 00       	call   f01014f6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 92 04 00 00       	call   f010055c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f01000d9:	e8 e0 08 00 00       	call   f01009be <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 42 07 00 00       	call   f0100838 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 00 23 11 f0 00 	cmpl   $0x0,0xf0112300
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 00 23 11 f0    	mov    %esi,0xf0112300

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 52 1a 10 f0 	movl   $0xf0101a52,(%esp)
f010012c:	e8 8d 08 00 00       	call   f01009be <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 4e 08 00 00       	call   f010098b <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100144:	e8 75 08 00 00       	call   f01009be <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 e3 06 00 00       	call   f0100838 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 6a 1a 10 f0 	movl   $0xf0101a6a,(%esp)
f0100176:	e8 43 08 00 00       	call   f01009be <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 01 08 00 00       	call   f010098b <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 8e 1a 10 f0 	movl   $0xf0101a8e,(%esp)
f0100191:	e8 28 08 00 00       	call   f01009be <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01001df:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 25 11 f0       	mov    %eax,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 c7                	mov    %eax,%edi
f0100212:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100217:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f0100218:	a8 20                	test   $0x20,%al
f010021a:	75 1b                	jne    f0100237 <cons_putc+0x30>
f010021c:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100221:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100226:	e8 75 ff ff ff       	call   f01001a0 <delay>
f010022b:	89 f2                	mov    %esi,%edx
f010022d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f010022e:	a8 20                	test   $0x20,%al
f0100230:	75 05                	jne    f0100237 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100232:	83 eb 01             	sub    $0x1,%ebx
f0100235:	75 ef                	jne    f0100226 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100237:	89 fa                	mov    %edi,%edx
f0100239:	89 f8                	mov    %edi,%eax
f010023b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010026f:	ee                   	out    %al,(%dx)
f0100270:	b2 7a                	mov    $0x7a,%dl
f0100272:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100277:	ee                   	out    %al,(%dx)
f0100278:	b8 08 00 00 00       	mov    $0x8,%eax
f010027d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010027e:	89 fa                	mov    %edi,%edx
f0100280:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100286:	89 f8                	mov    %edi,%eax
f0100288:	80 cc 07             	or     $0x7,%ah
f010028b:	85 d2                	test   %edx,%edx
f010028d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100290:	89 f8                	mov    %edi,%eax
f0100292:	25 ff 00 00 00       	and    $0xff,%eax
f0100297:	83 f8 09             	cmp    $0x9,%eax
f010029a:	74 7c                	je     f0100318 <cons_putc+0x111>
f010029c:	83 f8 09             	cmp    $0x9,%eax
f010029f:	7f 0b                	jg     f01002ac <cons_putc+0xa5>
f01002a1:	83 f8 08             	cmp    $0x8,%eax
f01002a4:	0f 85 a2 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002aa:	eb 16                	jmp    f01002c2 <cons_putc+0xbb>
f01002ac:	83 f8 0a             	cmp    $0xa,%eax
f01002af:	90                   	nop
f01002b0:	74 40                	je     f01002f2 <cons_putc+0xeb>
f01002b2:	83 f8 0d             	cmp    $0xd,%eax
f01002b5:	0f 85 91 00 00 00    	jne    f010034c <cons_putc+0x145>
f01002bb:	90                   	nop
f01002bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002c0:	eb 38                	jmp    f01002fa <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f01002c2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002c9:	66 85 c0             	test   %ax,%ax
f01002cc:	0f 84 e4 00 00 00    	je     f01003b6 <cons_putc+0x1af>
			crt_pos--;
f01002d2:	83 e8 01             	sub    $0x1,%eax
f01002d5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002db:	0f b7 c0             	movzwl %ax,%eax
f01002de:	66 81 e7 00 ff       	and    $0xff00,%di
f01002e3:	83 cf 20             	or     $0x20,%edi
f01002e6:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f01002ec:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002f0:	eb 77                	jmp    f0100369 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002f2:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f01002f9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002fa:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100301:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100307:	c1 e8 16             	shr    $0x16,%eax
f010030a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010030d:	c1 e0 04             	shl    $0x4,%eax
f0100310:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f0100316:	eb 51                	jmp    f0100369 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f0100318:	b8 20 00 00 00       	mov    $0x20,%eax
f010031d:	e8 e5 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100322:	b8 20 00 00 00       	mov    $0x20,%eax
f0100327:	e8 db fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100331:	e8 d1 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100336:	b8 20 00 00 00       	mov    $0x20,%eax
f010033b:	e8 c7 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100340:	b8 20 00 00 00       	mov    $0x20,%eax
f0100345:	e8 bd fe ff ff       	call   f0100207 <cons_putc>
f010034a:	eb 1d                	jmp    f0100369 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010034c:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100353:	0f b7 c8             	movzwl %ax,%ecx
f0100356:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
f010035c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100360:	83 c0 01             	add    $0x1,%eax
f0100363:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100369:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f0100370:	cf 07 
f0100372:	76 42                	jbe    f01003b6 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100374:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100379:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100380:	00 
f0100381:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100387:	89 54 24 04          	mov    %edx,0x4(%esp)
f010038b:	89 04 24             	mov    %eax,(%esp)
f010038e:	e8 be 11 00 00       	call   f0101551 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100393:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100399:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010039e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01003a4:	83 c0 01             	add    $0x1,%eax
f01003a7:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01003ac:	75 f0                	jne    f010039e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01003ae:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003b5:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003b6:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003bc:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003c1:	89 ca                	mov    %ecx,%edx
f01003c3:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003c4:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
f01003cb:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ce:	89 f0                	mov    %esi,%eax
f01003d0:	66 c1 e8 08          	shr    $0x8,%ax
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	ee                   	out    %al,(%dx)
f01003d7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003dc:	89 ca                	mov    %ecx,%edx
f01003de:	ee                   	out    %al,(%dx)
f01003df:	89 f0                	mov    %esi,%eax
f01003e1:	89 da                	mov    %ebx,%edx
f01003e3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003e4:	83 c4 2c             	add    $0x2c,%esp
f01003e7:	5b                   	pop    %ebx
f01003e8:	5e                   	pop    %esi
f01003e9:	5f                   	pop    %edi
f01003ea:	5d                   	pop    %ebp
f01003eb:	c3                   	ret    

f01003ec <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003ec:	55                   	push   %ebp
f01003ed:	89 e5                	mov    %esp,%ebp
f01003ef:	53                   	push   %ebx
f01003f0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003f3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003f8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003f9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003fe:	a8 01                	test   $0x1,%al
f0100400:	0f 84 de 00 00 00    	je     f01004e4 <kbd_proc_data+0xf8>
f0100406:	b2 60                	mov    $0x60,%dl
f0100408:	ec                   	in     (%dx),%al
f0100409:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f010040b:	3c e0                	cmp    $0xe0,%al
f010040d:	75 11                	jne    f0100420 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010040f:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100416:	bb 00 00 00 00       	mov    $0x0,%ebx
f010041b:	e9 c4 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f0100420:	84 c0                	test   %al,%al
f0100422:	79 37                	jns    f010045b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100424:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010042a:	89 cb                	mov    %ecx,%ebx
f010042c:	83 e3 40             	and    $0x40,%ebx
f010042f:	83 e0 7f             	and    $0x7f,%eax
f0100432:	85 db                	test   %ebx,%ebx
f0100434:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100437:	0f b6 d2             	movzbl %dl,%edx
f010043a:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f0100441:	83 c8 40             	or     $0x40,%eax
f0100444:	0f b6 c0             	movzbl %al,%eax
f0100447:	f7 d0                	not    %eax
f0100449:	21 c1                	and    %eax,%ecx
f010044b:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f0100451:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100456:	e9 89 00 00 00       	jmp    f01004e4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010045b:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100461:	f6 c1 40             	test   $0x40,%cl
f0100464:	74 0e                	je     f0100474 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100466:	89 c2                	mov    %eax,%edx
f0100468:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010046b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010046e:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100474:	0f b6 d2             	movzbl %dl,%edx
f0100477:	0f b6 82 c0 1a 10 f0 	movzbl -0xfefe540(%edx),%eax
f010047e:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100484:	0f b6 8a c0 1b 10 f0 	movzbl -0xfefe440(%edx),%ecx
f010048b:	31 c8                	xor    %ecx,%eax
f010048d:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f0100492:	89 c1                	mov    %eax,%ecx
f0100494:	83 e1 03             	and    $0x3,%ecx
f0100497:	8b 0c 8d c0 1c 10 f0 	mov    -0xfefe340(,%ecx,4),%ecx
f010049e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f01004a2:	a8 08                	test   $0x8,%al
f01004a4:	74 19                	je     f01004bf <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f01004a6:	8d 53 9f             	lea    -0x61(%ebx),%edx
f01004a9:	83 fa 19             	cmp    $0x19,%edx
f01004ac:	77 05                	ja     f01004b3 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f01004ae:	83 eb 20             	sub    $0x20,%ebx
f01004b1:	eb 0c                	jmp    f01004bf <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004b3:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004b6:	8d 53 20             	lea    0x20(%ebx),%edx
f01004b9:	83 f9 19             	cmp    $0x19,%ecx
f01004bc:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004bf:	f7 d0                	not    %eax
f01004c1:	a8 06                	test   $0x6,%al
f01004c3:	75 1f                	jne    f01004e4 <kbd_proc_data+0xf8>
f01004c5:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004cb:	75 17                	jne    f01004e4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004cd:	c7 04 24 84 1a 10 f0 	movl   $0xf0101a84,(%esp)
f01004d4:	e8 e5 04 00 00       	call   f01009be <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004d9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004de:	b8 03 00 00 00       	mov    $0x3,%eax
f01004e3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004e4:	89 d8                	mov    %ebx,%eax
f01004e6:	83 c4 14             	add    $0x14,%esp
f01004e9:	5b                   	pop    %ebx
f01004ea:	5d                   	pop    %ebp
f01004eb:	c3                   	ret    

f01004ec <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004ec:	55                   	push   %ebp
f01004ed:	89 e5                	mov    %esp,%ebp
f01004ef:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004f2:	83 3d 20 23 11 f0 00 	cmpl   $0x0,0xf0112320
f01004f9:	74 0a                	je     f0100505 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004fb:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100500:	e8 c5 fc ff ff       	call   f01001ca <cons_intr>
}
f0100505:	c9                   	leave  
f0100506:	c3                   	ret    

f0100507 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100507:	55                   	push   %ebp
f0100508:	89 e5                	mov    %esp,%ebp
f010050a:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010050d:	b8 ec 03 10 f0       	mov    $0xf01003ec,%eax
f0100512:	e8 b3 fc ff ff       	call   f01001ca <cons_intr>
}
f0100517:	c9                   	leave  
f0100518:	c3                   	ret    

f0100519 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100519:	55                   	push   %ebp
f010051a:	89 e5                	mov    %esp,%ebp
f010051c:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010051f:	e8 c8 ff ff ff       	call   f01004ec <serial_intr>
	kbd_intr();
f0100524:	e8 de ff ff ff       	call   f0100507 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100529:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f010052f:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100534:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f010053a:	74 1e                	je     f010055a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010053c:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f0100543:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100546:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010054c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100551:	0f 44 d1             	cmove  %ecx,%edx
f0100554:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f010055a:	c9                   	leave  
f010055b:	c3                   	ret    

f010055c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010055c:	55                   	push   %ebp
f010055d:	89 e5                	mov    %esp,%ebp
f010055f:	57                   	push   %edi
f0100560:	56                   	push   %esi
f0100561:	53                   	push   %ebx
f0100562:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100565:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010056c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100573:	5a a5 
	if (*cp != 0xA55A) {
f0100575:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010057c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100580:	74 11                	je     f0100593 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100582:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100589:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010058c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100591:	eb 16                	jmp    f01005a9 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100593:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010059a:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f01005a1:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005a4:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a9:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01005af:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005b4:	89 ca                	mov    %ecx,%edx
f01005b6:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005b7:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ec                   	in     (%dx),%al
f01005bd:	0f b6 f8             	movzbl %al,%edi
f01005c0:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005c3:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c8:	89 ca                	mov    %ecx,%edx
f01005ca:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005cb:	89 da                	mov    %ebx,%edx
f01005cd:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005ce:	89 35 50 25 11 f0    	mov    %esi,0xf0112550
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005d4:	0f b6 d8             	movzbl %al,%ebx
f01005d7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d9:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ea:	89 da                	mov    %ebx,%edx
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b2 fb                	mov    $0xfb,%dl
f01005ef:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005fa:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005ff:	89 ca                	mov    %ecx,%edx
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 f9                	mov    $0xf9,%dl
f0100604:	b8 00 00 00 00       	mov    $0x0,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fb                	mov    $0xfb,%dl
f010060c:	b8 03 00 00 00       	mov    $0x3,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fc                	mov    $0xfc,%dl
f0100614:	b8 00 00 00 00       	mov    $0x0,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 f9                	mov    $0xf9,%dl
f010061c:	b8 01 00 00 00       	mov    $0x1,%eax
f0100621:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100622:	b2 fd                	mov    $0xfd,%dl
f0100624:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100625:	3c ff                	cmp    $0xff,%al
f0100627:	0f 95 c0             	setne  %al
f010062a:	0f b6 c0             	movzbl %al,%eax
f010062d:	89 c6                	mov    %eax,%esi
f010062f:	a3 20 23 11 f0       	mov    %eax,0xf0112320
f0100634:	89 da                	mov    %ebx,%edx
f0100636:	ec                   	in     (%dx),%al
f0100637:	89 ca                	mov    %ecx,%edx
f0100639:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063a:	85 f6                	test   %esi,%esi
f010063c:	75 0c                	jne    f010064a <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010063e:	c7 04 24 90 1a 10 f0 	movl   $0xf0101a90,(%esp)
f0100645:	e8 74 03 00 00       	call   f01009be <cprintf>
}
f010064a:	83 c4 1c             	add    $0x1c,%esp
f010064d:	5b                   	pop    %ebx
f010064e:	5e                   	pop    %esi
f010064f:	5f                   	pop    %edi
f0100650:	5d                   	pop    %ebp
f0100651:	c3                   	ret    

f0100652 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100652:	55                   	push   %ebp
f0100653:	89 e5                	mov    %esp,%ebp
f0100655:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100658:	8b 45 08             	mov    0x8(%ebp),%eax
f010065b:	e8 a7 fb ff ff       	call   f0100207 <cons_putc>
}
f0100660:	c9                   	leave  
f0100661:	c3                   	ret    

f0100662 <getchar>:

int
getchar(void)
{
f0100662:	55                   	push   %ebp
f0100663:	89 e5                	mov    %esp,%ebp
f0100665:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100668:	e8 ac fe ff ff       	call   f0100519 <cons_getc>
f010066d:	85 c0                	test   %eax,%eax
f010066f:	74 f7                	je     f0100668 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100671:	c9                   	leave  
f0100672:	c3                   	ret    

f0100673 <iscons>:

int
iscons(int fdnum)
{
f0100673:	55                   	push   %ebp
f0100674:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100676:	b8 01 00 00 00       	mov    $0x1,%eax
f010067b:	5d                   	pop    %ebp
f010067c:	c3                   	ret    
f010067d:	00 00                	add    %al,(%eax)
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 d0 1c 10 f0 	movl   $0xf0101cd0,(%esp)
f010068d:	e8 2c 03 00 00       	call   f01009be <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100692:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100699:	00 
f010069a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006a1:	f0 
f01006a2:	c7 04 24 90 1d 10 f0 	movl   $0xf0101d90,(%esp)
f01006a9:	e8 10 03 00 00       	call   f01009be <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006ae:	c7 44 24 08 f5 19 10 	movl   $0x1019f5,0x8(%esp)
f01006b5:	00 
f01006b6:	c7 44 24 04 f5 19 10 	movl   $0xf01019f5,0x4(%esp)
f01006bd:	f0 
f01006be:	c7 04 24 b4 1d 10 f0 	movl   $0xf0101db4,(%esp)
f01006c5:	e8 f4 02 00 00       	call   f01009be <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ca:	c7 44 24 08 00 23 11 	movl   $0x112300,0x8(%esp)
f01006d1:	00 
f01006d2:	c7 44 24 04 00 23 11 	movl   $0xf0112300,0x4(%esp)
f01006d9:	f0 
f01006da:	c7 04 24 d8 1d 10 f0 	movl   $0xf0101dd8,(%esp)
f01006e1:	e8 d8 02 00 00       	call   f01009be <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006e6:	c7 44 24 08 60 29 11 	movl   $0x112960,0x8(%esp)
f01006ed:	00 
f01006ee:	c7 44 24 04 60 29 11 	movl   $0xf0112960,0x4(%esp)
f01006f5:	f0 
f01006f6:	c7 04 24 fc 1d 10 f0 	movl   $0xf0101dfc,(%esp)
f01006fd:	e8 bc 02 00 00       	call   f01009be <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f0100702:	b8 5f 2d 11 f0       	mov    $0xf0112d5f,%eax
f0100707:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010070c:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100712:	85 c0                	test   %eax,%eax
f0100714:	0f 48 c2             	cmovs  %edx,%eax
f0100717:	c1 f8 0a             	sar    $0xa,%eax
f010071a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071e:	c7 04 24 20 1e 10 f0 	movl   $0xf0101e20,(%esp)
f0100725:	e8 94 02 00 00       	call   f01009be <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f010072a:	b8 00 00 00 00       	mov    $0x0,%eax
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
f0100734:	53                   	push   %ebx
f0100735:	83 ec 14             	sub    $0x14,%esp
f0100738:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010073d:	8b 83 24 1f 10 f0    	mov    -0xfefe0dc(%ebx),%eax
f0100743:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100747:	8b 83 20 1f 10 f0    	mov    -0xfefe0e0(%ebx),%eax
f010074d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100751:	c7 04 24 e9 1c 10 f0 	movl   $0xf0101ce9,(%esp)
f0100758:	e8 61 02 00 00       	call   f01009be <cprintf>
f010075d:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100760:	83 fb 24             	cmp    $0x24,%ebx
f0100763:	75 d8                	jne    f010073d <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100765:	b8 00 00 00 00       	mov    $0x0,%eax
f010076a:	83 c4 14             	add    $0x14,%esp
f010076d:	5b                   	pop    %ebx
f010076e:	5d                   	pop    %ebp
f010076f:	c3                   	ret    

f0100770 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100770:	55                   	push   %ebp
f0100771:	89 e5                	mov    %esp,%ebp
f0100773:	57                   	push   %edi
f0100774:	56                   	push   %esi
f0100775:	53                   	push   %ebx
f0100776:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100779:	89 eb                	mov    %ebp,%ebx
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();
f010077b:	89 de                	mov    %ebx,%esi

    cprintf ("Stack backtrace:\n");
f010077d:	c7 04 24 f2 1c 10 f0 	movl   $0xf0101cf2,(%esp)
f0100784:	e8 35 02 00 00       	call   f01009be <cprintf>
    while (ebp != 0) {
f0100789:	85 db                	test   %ebx,%ebx
f010078b:	0f 84 9a 00 00 00    	je     f010082b <mon_backtrace+0xbb>
        
        eip = (uint32_t*) ebp[1];
f0100791:	8b 5e 04             	mov    0x4(%esi),%ebx

        arg0 = ebp[2];
f0100794:	8b 46 08             	mov    0x8(%esi),%eax
f0100797:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        arg1 = ebp[3];
f010079a:	8b 46 0c             	mov    0xc(%esi),%eax
f010079d:	89 45 c0             	mov    %eax,-0x40(%ebp)
        arg2 = ebp[4];
f01007a0:	8b 46 10             	mov    0x10(%esi),%eax
f01007a3:	89 45 bc             	mov    %eax,-0x44(%ebp)
        arg3 = ebp[5];
f01007a6:	8b 46 14             	mov    0x14(%esi),%eax
f01007a9:	89 45 b8             	mov    %eax,-0x48(%ebp)
        arg4 = ebp[6];
f01007ac:	8b 7e 18             	mov    0x18(%esi),%edi
	
	// Your code here.
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;
f01007af:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007b2:	89 44 24 04          	mov    %eax,0x4(%esp)
        arg1 = ebp[3];
        arg2 = ebp[4];
        arg3 = ebp[5];
        arg4 = ebp[6];
        
        debuginfo_eip ((uintptr_t) eip, eipinfo);
f01007b6:	89 1c 24             	mov    %ebx,(%esp)
f01007b9:	e8 fa 02 00 00       	call   f0100ab8 <debuginfo_eip>

        cprintf ("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg0, arg1, arg2, arg3, arg4);
f01007be:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
f01007c2:	8b 45 b8             	mov    -0x48(%ebp),%eax
f01007c5:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007c9:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01007cc:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007d0:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01007d3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007d7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007de:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01007e2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007e6:	c7 04 24 4c 1e 10 f0 	movl   $0xf0101e4c,(%esp)
f01007ed:	e8 cc 01 00 00       	call   f01009be <cprintf>
        cprintf ("         %s:%d: %.*s+%d\n", 
f01007f2:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007f5:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01007f9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007fc:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100800:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100803:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100807:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010080a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010080e:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100811:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100815:	c7 04 24 04 1d 10 f0 	movl   $0xf0101d04,(%esp)
f010081c:	e8 9d 01 00 00       	call   f01009be <cprintf>
            eipinfo->eip_line, 
            eipinfo->eip_fn_namelen, eipinfo->eip_fn_name,
            (uint32_t) eip - eipinfo->eip_fn_addr);


        ebp = (uint32_t*) ebp[0];
f0100821:	8b 36                	mov    (%esi),%esi
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();

    cprintf ("Stack backtrace:\n");
    while (ebp != 0) {
f0100823:	85 f6                	test   %esi,%esi
f0100825:	0f 85 66 ff ff ff    	jne    f0100791 <mon_backtrace+0x21>


        ebp = (uint32_t*) ebp[0];
    }
	return 0;
}
f010082b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100830:	83 c4 5c             	add    $0x5c,%esp
f0100833:	5b                   	pop    %ebx
f0100834:	5e                   	pop    %esi
f0100835:	5f                   	pop    %edi
f0100836:	5d                   	pop    %ebp
f0100837:	c3                   	ret    

f0100838 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100838:	55                   	push   %ebp
f0100839:	89 e5                	mov    %esp,%ebp
f010083b:	57                   	push   %edi
f010083c:	56                   	push   %esi
f010083d:	53                   	push   %ebx
f010083e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100841:	c7 04 24 84 1e 10 f0 	movl   $0xf0101e84,(%esp)
f0100848:	e8 71 01 00 00       	call   f01009be <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010084d:	c7 04 24 a8 1e 10 f0 	movl   $0xf0101ea8,(%esp)
f0100854:	e8 65 01 00 00       	call   f01009be <cprintf>


	while (1) {
		buf = readline("K> ");
f0100859:	c7 04 24 1d 1d 10 f0 	movl   $0xf0101d1d,(%esp)
f0100860:	e8 0b 0a 00 00       	call   f0101270 <readline>
f0100865:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100867:	85 c0                	test   %eax,%eax
f0100869:	74 ee                	je     f0100859 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010086b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100872:	be 00 00 00 00       	mov    $0x0,%esi
f0100877:	eb 06                	jmp    f010087f <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100879:	c6 03 00             	movb   $0x0,(%ebx)
f010087c:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f010087f:	0f b6 03             	movzbl (%ebx),%eax
f0100882:	84 c0                	test   %al,%al
f0100884:	74 6a                	je     f01008f0 <monitor+0xb8>
f0100886:	0f be c0             	movsbl %al,%eax
f0100889:	89 44 24 04          	mov    %eax,0x4(%esp)
f010088d:	c7 04 24 21 1d 10 f0 	movl   $0xf0101d21,(%esp)
f0100894:	e8 02 0c 00 00       	call   f010149b <strchr>
f0100899:	85 c0                	test   %eax,%eax
f010089b:	75 dc                	jne    f0100879 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010089d:	80 3b 00             	cmpb   $0x0,(%ebx)
f01008a0:	74 4e                	je     f01008f0 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01008a2:	83 fe 0f             	cmp    $0xf,%esi
f01008a5:	75 16                	jne    f01008bd <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01008a7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01008ae:	00 
f01008af:	c7 04 24 26 1d 10 f0 	movl   $0xf0101d26,(%esp)
f01008b6:	e8 03 01 00 00       	call   f01009be <cprintf>
f01008bb:	eb 9c                	jmp    f0100859 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f01008bd:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008c1:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008c4:	0f b6 03             	movzbl (%ebx),%eax
f01008c7:	84 c0                	test   %al,%al
f01008c9:	75 0c                	jne    f01008d7 <monitor+0x9f>
f01008cb:	eb b2                	jmp    f010087f <monitor+0x47>
			buf++;
f01008cd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008d0:	0f b6 03             	movzbl (%ebx),%eax
f01008d3:	84 c0                	test   %al,%al
f01008d5:	74 a8                	je     f010087f <monitor+0x47>
f01008d7:	0f be c0             	movsbl %al,%eax
f01008da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008de:	c7 04 24 21 1d 10 f0 	movl   $0xf0101d21,(%esp)
f01008e5:	e8 b1 0b 00 00       	call   f010149b <strchr>
f01008ea:	85 c0                	test   %eax,%eax
f01008ec:	74 df                	je     f01008cd <monitor+0x95>
f01008ee:	eb 8f                	jmp    f010087f <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f01008f0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008f7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008f8:	85 f6                	test   %esi,%esi
f01008fa:	0f 84 59 ff ff ff    	je     f0100859 <monitor+0x21>
f0100900:	bb 20 1f 10 f0       	mov    $0xf0101f20,%ebx
f0100905:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010090a:	8b 03                	mov    (%ebx),%eax
f010090c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100910:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100913:	89 04 24             	mov    %eax,(%esp)
f0100916:	e8 05 0b 00 00       	call   f0101420 <strcmp>
f010091b:	85 c0                	test   %eax,%eax
f010091d:	75 24                	jne    f0100943 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f010091f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100922:	8b 55 08             	mov    0x8(%ebp),%edx
f0100925:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100929:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010092c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100930:	89 34 24             	mov    %esi,(%esp)
f0100933:	ff 14 85 28 1f 10 f0 	call   *-0xfefe0d8(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010093a:	85 c0                	test   %eax,%eax
f010093c:	78 28                	js     f0100966 <monitor+0x12e>
f010093e:	e9 16 ff ff ff       	jmp    f0100859 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100943:	83 c7 01             	add    $0x1,%edi
f0100946:	83 c3 0c             	add    $0xc,%ebx
f0100949:	83 ff 03             	cmp    $0x3,%edi
f010094c:	75 bc                	jne    f010090a <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010094e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100951:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100955:	c7 04 24 43 1d 10 f0 	movl   $0xf0101d43,(%esp)
f010095c:	e8 5d 00 00 00       	call   f01009be <cprintf>
f0100961:	e9 f3 fe ff ff       	jmp    f0100859 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100966:	83 c4 5c             	add    $0x5c,%esp
f0100969:	5b                   	pop    %ebx
f010096a:	5e                   	pop    %esi
f010096b:	5f                   	pop    %edi
f010096c:	5d                   	pop    %ebp
f010096d:	c3                   	ret    

f010096e <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010096e:	55                   	push   %ebp
f010096f:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100971:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100974:	5d                   	pop    %ebp
f0100975:	c3                   	ret    
	...

f0100978 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100978:	55                   	push   %ebp
f0100979:	89 e5                	mov    %esp,%ebp
f010097b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010097e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100981:	89 04 24             	mov    %eax,(%esp)
f0100984:	e8 c9 fc ff ff       	call   f0100652 <cputchar>
	*cnt++;
}
f0100989:	c9                   	leave  
f010098a:	c3                   	ret    

f010098b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010098b:	55                   	push   %ebp
f010098c:	89 e5                	mov    %esp,%ebp
f010098e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100991:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100998:	8b 45 0c             	mov    0xc(%ebp),%eax
f010099b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010099f:	8b 45 08             	mov    0x8(%ebp),%eax
f01009a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009a6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01009a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ad:	c7 04 24 78 09 10 f0 	movl   $0xf0100978,(%esp)
f01009b4:	e8 61 04 00 00       	call   f0100e1a <vprintfmt>
	return cnt;
}
f01009b9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009bc:	c9                   	leave  
f01009bd:	c3                   	ret    

f01009be <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009be:	55                   	push   %ebp
f01009bf:	89 e5                	mov    %esp,%ebp
f01009c1:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f01009c4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f01009c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01009ce:	89 04 24             	mov    %eax,(%esp)
f01009d1:	e8 b5 ff ff ff       	call   f010098b <vcprintf>
	va_end(ap);

	return cnt;
}
f01009d6:	c9                   	leave  
f01009d7:	c3                   	ret    

f01009d8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01009d8:	55                   	push   %ebp
f01009d9:	89 e5                	mov    %esp,%ebp
f01009db:	57                   	push   %edi
f01009dc:	56                   	push   %esi
f01009dd:	53                   	push   %ebx
f01009de:	83 ec 10             	sub    $0x10,%esp
f01009e1:	89 c3                	mov    %eax,%ebx
f01009e3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01009e6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01009e9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01009ec:	8b 0a                	mov    (%edx),%ecx
f01009ee:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01009f1:	8b 00                	mov    (%eax),%eax
f01009f3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01009f6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
	
	while (l <= r) {
f01009fd:	eb 77                	jmp    f0100a76 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01009ff:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100a02:	01 c8                	add    %ecx,%eax
f0100a04:	bf 02 00 00 00       	mov    $0x2,%edi
f0100a09:	99                   	cltd   
f0100a0a:	f7 ff                	idiv   %edi
f0100a0c:	89 c2                	mov    %eax,%edx
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a0e:	eb 01                	jmp    f0100a11 <stab_binsearch+0x39>
			m--;
f0100a10:	4a                   	dec    %edx
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a11:	39 ca                	cmp    %ecx,%edx
f0100a13:	7c 1d                	jl     f0100a32 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a15:	6b fa 0c             	imul   $0xc,%edx,%edi
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100a18:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100a1d:	39 f7                	cmp    %esi,%edi
f0100a1f:	75 ef                	jne    f0100a10 <stab_binsearch+0x38>
f0100a21:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100a24:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100a27:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100a2b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a2e:	73 18                	jae    f0100a48 <stab_binsearch+0x70>
f0100a30:	eb 05                	jmp    f0100a37 <stab_binsearch+0x5f>
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100a32:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100a35:	eb 3f                	jmp    f0100a76 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100a37:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a3a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100a3c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a3f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a46:	eb 2e                	jmp    f0100a76 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100a48:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100a4b:	76 15                	jbe    f0100a62 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100a4d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a50:	4f                   	dec    %edi
f0100a51:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100a54:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a57:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a59:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100a60:	eb 14                	jmp    f0100a76 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100a62:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100a65:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100a68:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100a6a:	ff 45 0c             	incl   0xc(%ebp)
f0100a6d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100a6f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0100a76:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100a79:	7e 84                	jle    f01009ff <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100a7b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100a7f:	75 0d                	jne    f0100a8e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100a81:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a84:	8b 02                	mov    (%edx),%eax
f0100a86:	48                   	dec    %eax
f0100a87:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a8a:	89 01                	mov    %eax,(%ecx)
f0100a8c:	eb 22                	jmp    f0100ab0 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a8e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100a91:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100a93:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100a96:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a98:	eb 01                	jmp    f0100a9b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100a9a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100a9b:	39 c1                	cmp    %eax,%ecx
f0100a9d:	7d 0c                	jge    f0100aab <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100a9f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100aa2:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100aa7:	39 f2                	cmp    %esi,%edx
f0100aa9:	75 ef                	jne    f0100a9a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100aab:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100aae:	89 02                	mov    %eax,(%edx)
	}
}
f0100ab0:	83 c4 10             	add    $0x10,%esp
f0100ab3:	5b                   	pop    %ebx
f0100ab4:	5e                   	pop    %esi
f0100ab5:	5f                   	pop    %edi
f0100ab6:	5d                   	pop    %ebp
f0100ab7:	c3                   	ret    

f0100ab8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100ab8:	55                   	push   %ebp
f0100ab9:	89 e5                	mov    %esp,%ebp
f0100abb:	83 ec 38             	sub    $0x38,%esp
f0100abe:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100ac1:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ac4:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100ac7:	8b 75 08             	mov    0x8(%ebp),%esi
f0100aca:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100acd:	c7 03 44 1f 10 f0    	movl   $0xf0101f44,(%ebx)
	info->eip_line = 0;
f0100ad3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ada:	c7 43 08 44 1f 10 f0 	movl   $0xf0101f44,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100ae1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ae8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100aeb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100af2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100af8:	76 12                	jbe    f0100b0c <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100afa:	b8 51 77 10 f0       	mov    $0xf0107751,%eax
f0100aff:	3d 59 5d 10 f0       	cmp    $0xf0105d59,%eax
f0100b04:	0f 86 9b 01 00 00    	jbe    f0100ca5 <debuginfo_eip+0x1ed>
f0100b0a:	eb 1c                	jmp    f0100b28 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100b0c:	c7 44 24 08 4e 1f 10 	movl   $0xf0101f4e,0x8(%esp)
f0100b13:	f0 
f0100b14:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100b1b:	00 
f0100b1c:	c7 04 24 5b 1f 10 f0 	movl   $0xf0101f5b,(%esp)
f0100b23:	e8 d0 f5 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100b28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100b2d:	80 3d 50 77 10 f0 00 	cmpb   $0x0,0xf0107750
f0100b34:	0f 85 77 01 00 00    	jne    f0100cb1 <debuginfo_eip+0x1f9>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100b3a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100b41:	b8 58 5d 10 f0       	mov    $0xf0105d58,%eax
f0100b46:	2d 7c 21 10 f0       	sub    $0xf010217c,%eax
f0100b4b:	c1 f8 02             	sar    $0x2,%eax
f0100b4e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100b54:	83 e8 01             	sub    $0x1,%eax
f0100b57:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100b5a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b5e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100b65:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100b68:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100b6b:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100b70:	e8 63 fe ff ff       	call   f01009d8 <stab_binsearch>
	if (lfile == 0)
f0100b75:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100b78:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100b7d:	85 d2                	test   %edx,%edx
f0100b7f:	0f 84 2c 01 00 00    	je     f0100cb1 <debuginfo_eip+0x1f9>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100b85:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100b88:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b8b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100b8e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100b92:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100b99:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100b9c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b9f:	b8 7c 21 10 f0       	mov    $0xf010217c,%eax
f0100ba4:	e8 2f fe ff ff       	call   f01009d8 <stab_binsearch>

	if (lfun <= rfun) {
f0100ba9:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0100bac:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0100baf:	7f 2e                	jg     f0100bdf <debuginfo_eip+0x127>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100bb1:	6b c7 0c             	imul   $0xc,%edi,%eax
f0100bb4:	8d 90 7c 21 10 f0    	lea    -0xfefde84(%eax),%edx
f0100bba:	8b 80 7c 21 10 f0    	mov    -0xfefde84(%eax),%eax
f0100bc0:	b9 51 77 10 f0       	mov    $0xf0107751,%ecx
f0100bc5:	81 e9 59 5d 10 f0    	sub    $0xf0105d59,%ecx
f0100bcb:	39 c8                	cmp    %ecx,%eax
f0100bcd:	73 08                	jae    f0100bd7 <debuginfo_eip+0x11f>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100bcf:	05 59 5d 10 f0       	add    $0xf0105d59,%eax
f0100bd4:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100bd7:	8b 42 08             	mov    0x8(%edx),%eax
f0100bda:	89 43 10             	mov    %eax,0x10(%ebx)
f0100bdd:	eb 06                	jmp    f0100be5 <debuginfo_eip+0x12d>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100bdf:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100be2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100be5:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100bec:	00 
f0100bed:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bf0:	89 04 24             	mov    %eax,(%esp)
f0100bf3:	e8 d7 08 00 00       	call   f01014cf <strfind>
f0100bf8:	2b 43 08             	sub    0x8(%ebx),%eax
f0100bfb:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100bfe:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100c01:	39 d7                	cmp    %edx,%edi
f0100c03:	7c 5f                	jl     f0100c64 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100c05:	89 f8                	mov    %edi,%eax
f0100c07:	6b cf 0c             	imul   $0xc,%edi,%ecx
f0100c0a:	80 b9 80 21 10 f0 84 	cmpb   $0x84,-0xfefde80(%ecx)
f0100c11:	75 18                	jne    f0100c2b <debuginfo_eip+0x173>
f0100c13:	eb 30                	jmp    f0100c45 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100c15:	83 ef 01             	sub    $0x1,%edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c18:	39 fa                	cmp    %edi,%edx
f0100c1a:	7f 48                	jg     f0100c64 <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0100c1c:	89 f8                	mov    %edi,%eax
f0100c1e:	8d 0c 7f             	lea    (%edi,%edi,2),%ecx
f0100c21:	80 3c 8d 80 21 10 f0 	cmpb   $0x84,-0xfefde80(,%ecx,4)
f0100c28:	84 
f0100c29:	74 1a                	je     f0100c45 <debuginfo_eip+0x18d>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100c2b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100c2e:	8d 04 85 7c 21 10 f0 	lea    -0xfefde84(,%eax,4),%eax
f0100c35:	80 78 04 64          	cmpb   $0x64,0x4(%eax)
f0100c39:	75 da                	jne    f0100c15 <debuginfo_eip+0x15d>
f0100c3b:	83 78 08 00          	cmpl   $0x0,0x8(%eax)
f0100c3f:	74 d4                	je     f0100c15 <debuginfo_eip+0x15d>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100c41:	39 fa                	cmp    %edi,%edx
f0100c43:	7f 1f                	jg     f0100c64 <debuginfo_eip+0x1ac>
f0100c45:	6b ff 0c             	imul   $0xc,%edi,%edi
f0100c48:	8b 87 7c 21 10 f0    	mov    -0xfefde84(%edi),%eax
f0100c4e:	ba 51 77 10 f0       	mov    $0xf0107751,%edx
f0100c53:	81 ea 59 5d 10 f0    	sub    $0xf0105d59,%edx
f0100c59:	39 d0                	cmp    %edx,%eax
f0100c5b:	73 07                	jae    f0100c64 <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100c5d:	05 59 5d 10 f0       	add    $0xf0105d59,%eax
f0100c62:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c64:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c67:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c6a:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100c6f:	39 ca                	cmp    %ecx,%edx
f0100c71:	7d 3e                	jge    f0100cb1 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
f0100c73:	83 c2 01             	add    $0x1,%edx
f0100c76:	39 d1                	cmp    %edx,%ecx
f0100c78:	7e 37                	jle    f0100cb1 <debuginfo_eip+0x1f9>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c7a:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100c7d:	80 be 80 21 10 f0 a0 	cmpb   $0xa0,-0xfefde80(%esi)
f0100c84:	75 2b                	jne    f0100cb1 <debuginfo_eip+0x1f9>
		     lline++)
			info->eip_fn_narg++;
f0100c86:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100c8a:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100c8d:	39 d1                	cmp    %edx,%ecx
f0100c8f:	7e 1b                	jle    f0100cac <debuginfo_eip+0x1f4>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100c91:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100c94:	80 3c 85 80 21 10 f0 	cmpb   $0xa0,-0xfefde80(,%eax,4)
f0100c9b:	a0 
f0100c9c:	74 e8                	je     f0100c86 <debuginfo_eip+0x1ce>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100c9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ca3:	eb 0c                	jmp    f0100cb1 <debuginfo_eip+0x1f9>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ca5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100caa:	eb 05                	jmp    f0100cb1 <debuginfo_eip+0x1f9>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0100cac:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100cb1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100cb4:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100cb7:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100cba:	89 ec                	mov    %ebp,%esp
f0100cbc:	5d                   	pop    %ebp
f0100cbd:	c3                   	ret    
	...

f0100cc0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100cc0:	55                   	push   %ebp
f0100cc1:	89 e5                	mov    %esp,%ebp
f0100cc3:	57                   	push   %edi
f0100cc4:	56                   	push   %esi
f0100cc5:	53                   	push   %ebx
f0100cc6:	83 ec 3c             	sub    $0x3c,%esp
f0100cc9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ccc:	89 d7                	mov    %edx,%edi
f0100cce:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cd1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100cd4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100cd7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100cda:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100cdd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100ce0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ce5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0100ce8:	72 11                	jb     f0100cfb <printnum+0x3b>
f0100cea:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ced:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100cf0:	76 09                	jbe    f0100cfb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100cf2:	83 eb 01             	sub    $0x1,%ebx
f0100cf5:	85 db                	test   %ebx,%ebx
f0100cf7:	7f 51                	jg     f0100d4a <printnum+0x8a>
f0100cf9:	eb 5e                	jmp    f0100d59 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100cfb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100cff:	83 eb 01             	sub    $0x1,%ebx
f0100d02:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100d06:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d09:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d0d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0100d11:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0100d15:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d1c:	00 
f0100d1d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d20:	89 04 24             	mov    %eax,(%esp)
f0100d23:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d26:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d2a:	e8 21 0a 00 00       	call   f0101750 <__udivdi3>
f0100d2f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100d33:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100d37:	89 04 24             	mov    %eax,(%esp)
f0100d3a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100d3e:	89 fa                	mov    %edi,%edx
f0100d40:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d43:	e8 78 ff ff ff       	call   f0100cc0 <printnum>
f0100d48:	eb 0f                	jmp    f0100d59 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100d4a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d4e:	89 34 24             	mov    %esi,(%esp)
f0100d51:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100d54:	83 eb 01             	sub    $0x1,%ebx
f0100d57:	75 f1                	jne    f0100d4a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100d59:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d5d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100d61:	8b 45 10             	mov    0x10(%ebp),%eax
f0100d64:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100d68:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0100d6f:	00 
f0100d70:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d73:	89 04 24             	mov    %eax,(%esp)
f0100d76:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d79:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d7d:	e8 fe 0a 00 00       	call   f0101880 <__umoddi3>
f0100d82:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d86:	0f be 80 69 1f 10 f0 	movsbl -0xfefe097(%eax),%eax
f0100d8d:	89 04 24             	mov    %eax,(%esp)
f0100d90:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0100d93:	83 c4 3c             	add    $0x3c,%esp
f0100d96:	5b                   	pop    %ebx
f0100d97:	5e                   	pop    %esi
f0100d98:	5f                   	pop    %edi
f0100d99:	5d                   	pop    %ebp
f0100d9a:	c3                   	ret    

f0100d9b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100d9b:	55                   	push   %ebp
f0100d9c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100d9e:	83 fa 01             	cmp    $0x1,%edx
f0100da1:	7e 0e                	jle    f0100db1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100da3:	8b 10                	mov    (%eax),%edx
f0100da5:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100da8:	89 08                	mov    %ecx,(%eax)
f0100daa:	8b 02                	mov    (%edx),%eax
f0100dac:	8b 52 04             	mov    0x4(%edx),%edx
f0100daf:	eb 22                	jmp    f0100dd3 <getuint+0x38>
	else if (lflag)
f0100db1:	85 d2                	test   %edx,%edx
f0100db3:	74 10                	je     f0100dc5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100db5:	8b 10                	mov    (%eax),%edx
f0100db7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dba:	89 08                	mov    %ecx,(%eax)
f0100dbc:	8b 02                	mov    (%edx),%eax
f0100dbe:	ba 00 00 00 00       	mov    $0x0,%edx
f0100dc3:	eb 0e                	jmp    f0100dd3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100dc5:	8b 10                	mov    (%eax),%edx
f0100dc7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100dca:	89 08                	mov    %ecx,(%eax)
f0100dcc:	8b 02                	mov    (%edx),%eax
f0100dce:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100dd3:	5d                   	pop    %ebp
f0100dd4:	c3                   	ret    

f0100dd5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100dd5:	55                   	push   %ebp
f0100dd6:	89 e5                	mov    %esp,%ebp
f0100dd8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100ddb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100ddf:	8b 10                	mov    (%eax),%edx
f0100de1:	3b 50 04             	cmp    0x4(%eax),%edx
f0100de4:	73 0a                	jae    f0100df0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100de6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0100de9:	88 0a                	mov    %cl,(%edx)
f0100deb:	83 c2 01             	add    $0x1,%edx
f0100dee:	89 10                	mov    %edx,(%eax)
}
f0100df0:	5d                   	pop    %ebp
f0100df1:	c3                   	ret    

f0100df2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100df2:	55                   	push   %ebp
f0100df3:	89 e5                	mov    %esp,%ebp
f0100df5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0100df8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100dfb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dff:	8b 45 10             	mov    0x10(%ebp),%eax
f0100e02:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0d:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e10:	89 04 24             	mov    %eax,(%esp)
f0100e13:	e8 02 00 00 00       	call   f0100e1a <vprintfmt>
	va_end(ap);
}
f0100e18:	c9                   	leave  
f0100e19:	c3                   	ret    

f0100e1a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100e1a:	55                   	push   %ebp
f0100e1b:	89 e5                	mov    %esp,%ebp
f0100e1d:	57                   	push   %edi
f0100e1e:	56                   	push   %esi
f0100e1f:	53                   	push   %ebx
f0100e20:	83 ec 4c             	sub    $0x4c,%esp
f0100e23:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e26:	8b 75 10             	mov    0x10(%ebp),%esi
f0100e29:	eb 12                	jmp    f0100e3d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100e2b:	85 c0                	test   %eax,%eax
f0100e2d:	0f 84 a9 03 00 00    	je     f01011dc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0100e33:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100e37:	89 04 24             	mov    %eax,(%esp)
f0100e3a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100e3d:	0f b6 06             	movzbl (%esi),%eax
f0100e40:	83 c6 01             	add    $0x1,%esi
f0100e43:	83 f8 25             	cmp    $0x25,%eax
f0100e46:	75 e3                	jne    f0100e2b <vprintfmt+0x11>
f0100e48:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0100e4c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0100e53:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100e58:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0100e5f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100e64:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e67:	eb 2b                	jmp    f0100e94 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e69:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100e6c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0100e70:	eb 22                	jmp    f0100e94 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e72:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100e75:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0100e79:	eb 19                	jmp    f0100e94 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e7b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0100e7e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0100e85:	eb 0d                	jmp    f0100e94 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100e87:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100e8a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100e8d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100e94:	0f b6 06             	movzbl (%esi),%eax
f0100e97:	0f b6 d0             	movzbl %al,%edx
f0100e9a:	8d 7e 01             	lea    0x1(%esi),%edi
f0100e9d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0100ea0:	83 e8 23             	sub    $0x23,%eax
f0100ea3:	3c 55                	cmp    $0x55,%al
f0100ea5:	0f 87 0b 03 00 00    	ja     f01011b6 <vprintfmt+0x39c>
f0100eab:	0f b6 c0             	movzbl %al,%eax
f0100eae:	ff 24 85 f8 1f 10 f0 	jmp    *-0xfefe008(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100eb5:	83 ea 30             	sub    $0x30,%edx
f0100eb8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0100ebb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100ebf:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ec2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0100ec5:	83 fa 09             	cmp    $0x9,%edx
f0100ec8:	77 4a                	ja     f0100f14 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100eca:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100ecd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100ed0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0100ed3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0100ed7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100eda:	8d 50 d0             	lea    -0x30(%eax),%edx
f0100edd:	83 fa 09             	cmp    $0x9,%edx
f0100ee0:	76 eb                	jbe    f0100ecd <vprintfmt+0xb3>
f0100ee2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ee5:	eb 2d                	jmp    f0100f14 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100ee7:	8b 45 14             	mov    0x14(%ebp),%eax
f0100eea:	8d 50 04             	lea    0x4(%eax),%edx
f0100eed:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ef0:	8b 00                	mov    (%eax),%eax
f0100ef2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100ef8:	eb 1a                	jmp    f0100f14 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100efa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0100efd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f01:	79 91                	jns    f0100e94 <vprintfmt+0x7a>
f0100f03:	e9 73 ff ff ff       	jmp    f0100e7b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f08:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100f0b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0100f12:	eb 80                	jmp    f0100e94 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0100f14:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0100f18:	0f 89 76 ff ff ff    	jns    f0100e94 <vprintfmt+0x7a>
f0100f1e:	e9 64 ff ff ff       	jmp    f0100e87 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100f23:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f26:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100f29:	e9 66 ff ff ff       	jmp    f0100e94 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100f2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f31:	8d 50 04             	lea    0x4(%eax),%edx
f0100f34:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f37:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f3b:	8b 00                	mov    (%eax),%eax
f0100f3d:	89 04 24             	mov    %eax,(%esp)
f0100f40:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f43:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0100f46:	e9 f2 fe ff ff       	jmp    f0100e3d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100f4b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f4e:	8d 50 04             	lea    0x4(%eax),%edx
f0100f51:	89 55 14             	mov    %edx,0x14(%ebp)
f0100f54:	8b 00                	mov    (%eax),%eax
f0100f56:	89 c2                	mov    %eax,%edx
f0100f58:	c1 fa 1f             	sar    $0x1f,%edx
f0100f5b:	31 d0                	xor    %edx,%eax
f0100f5d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f5f:	83 f8 06             	cmp    $0x6,%eax
f0100f62:	7f 0b                	jg     f0100f6f <vprintfmt+0x155>
f0100f64:	8b 14 85 50 21 10 f0 	mov    -0xfefdeb0(,%eax,4),%edx
f0100f6b:	85 d2                	test   %edx,%edx
f0100f6d:	75 23                	jne    f0100f92 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0100f6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f73:	c7 44 24 08 81 1f 10 	movl   $0xf0101f81,0x8(%esp)
f0100f7a:	f0 
f0100f7b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f7f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100f82:	89 3c 24             	mov    %edi,(%esp)
f0100f85:	e8 68 fe ff ff       	call   f0100df2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100f8a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0100f8d:	e9 ab fe ff ff       	jmp    f0100e3d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0100f92:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100f96:	c7 44 24 08 8a 1f 10 	movl   $0xf0101f8a,0x8(%esp)
f0100f9d:	f0 
f0100f9e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100fa2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100fa5:	89 3c 24             	mov    %edi,(%esp)
f0100fa8:	e8 45 fe ff ff       	call   f0100df2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100fad:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0100fb0:	e9 88 fe ff ff       	jmp    f0100e3d <vprintfmt+0x23>
f0100fb5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100fb8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100fbb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100fbe:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fc1:	8d 50 04             	lea    0x4(%eax),%edx
f0100fc4:	89 55 14             	mov    %edx,0x14(%ebp)
f0100fc7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0100fc9:	85 f6                	test   %esi,%esi
f0100fcb:	ba 7a 1f 10 f0       	mov    $0xf0101f7a,%edx
f0100fd0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0100fd3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100fd7:	7e 06                	jle    f0100fdf <vprintfmt+0x1c5>
f0100fd9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0100fdd:	75 10                	jne    f0100fef <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100fdf:	0f be 06             	movsbl (%esi),%eax
f0100fe2:	83 c6 01             	add    $0x1,%esi
f0100fe5:	85 c0                	test   %eax,%eax
f0100fe7:	0f 85 86 00 00 00    	jne    f0101073 <vprintfmt+0x259>
f0100fed:	eb 76                	jmp    f0101065 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100fef:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ff3:	89 34 24             	mov    %esi,(%esp)
f0100ff6:	e8 60 03 00 00       	call   f010135b <strnlen>
f0100ffb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100ffe:	29 c2                	sub    %eax,%edx
f0101000:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101003:	85 d2                	test   %edx,%edx
f0101005:	7e d8                	jle    f0100fdf <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101007:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010100b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010100e:	89 d6                	mov    %edx,%esi
f0101010:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101013:	89 c7                	mov    %eax,%edi
f0101015:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101019:	89 3c 24             	mov    %edi,(%esp)
f010101c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010101f:	83 ee 01             	sub    $0x1,%esi
f0101022:	75 f1                	jne    f0101015 <vprintfmt+0x1fb>
f0101024:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101027:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010102a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010102d:	eb b0                	jmp    f0100fdf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010102f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101033:	74 18                	je     f010104d <vprintfmt+0x233>
f0101035:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101038:	83 fa 5e             	cmp    $0x5e,%edx
f010103b:	76 10                	jbe    f010104d <vprintfmt+0x233>
					putch('?', putdat);
f010103d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101041:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101048:	ff 55 08             	call   *0x8(%ebp)
f010104b:	eb 0a                	jmp    f0101057 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010104d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101051:	89 04 24             	mov    %eax,(%esp)
f0101054:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101057:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010105b:	0f be 06             	movsbl (%esi),%eax
f010105e:	83 c6 01             	add    $0x1,%esi
f0101061:	85 c0                	test   %eax,%eax
f0101063:	75 0e                	jne    f0101073 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101065:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101068:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010106c:	7f 16                	jg     f0101084 <vprintfmt+0x26a>
f010106e:	e9 ca fd ff ff       	jmp    f0100e3d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101073:	85 ff                	test   %edi,%edi
f0101075:	78 b8                	js     f010102f <vprintfmt+0x215>
f0101077:	83 ef 01             	sub    $0x1,%edi
f010107a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101080:	79 ad                	jns    f010102f <vprintfmt+0x215>
f0101082:	eb e1                	jmp    f0101065 <vprintfmt+0x24b>
f0101084:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101087:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010108a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010108e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101095:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101097:	83 ee 01             	sub    $0x1,%esi
f010109a:	75 ee                	jne    f010108a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010109c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010109f:	e9 99 fd ff ff       	jmp    f0100e3d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01010a4:	83 f9 01             	cmp    $0x1,%ecx
f01010a7:	7e 10                	jle    f01010b9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01010a9:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ac:	8d 50 08             	lea    0x8(%eax),%edx
f01010af:	89 55 14             	mov    %edx,0x14(%ebp)
f01010b2:	8b 30                	mov    (%eax),%esi
f01010b4:	8b 78 04             	mov    0x4(%eax),%edi
f01010b7:	eb 26                	jmp    f01010df <vprintfmt+0x2c5>
	else if (lflag)
f01010b9:	85 c9                	test   %ecx,%ecx
f01010bb:	74 12                	je     f01010cf <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01010bd:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c0:	8d 50 04             	lea    0x4(%eax),%edx
f01010c3:	89 55 14             	mov    %edx,0x14(%ebp)
f01010c6:	8b 30                	mov    (%eax),%esi
f01010c8:	89 f7                	mov    %esi,%edi
f01010ca:	c1 ff 1f             	sar    $0x1f,%edi
f01010cd:	eb 10                	jmp    f01010df <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01010cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01010d2:	8d 50 04             	lea    0x4(%eax),%edx
f01010d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01010d8:	8b 30                	mov    (%eax),%esi
f01010da:	89 f7                	mov    %esi,%edi
f01010dc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01010df:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01010e4:	85 ff                	test   %edi,%edi
f01010e6:	0f 89 8c 00 00 00    	jns    f0101178 <vprintfmt+0x35e>
				putch('-', putdat);
f01010ec:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01010f0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01010f7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01010fa:	f7 de                	neg    %esi
f01010fc:	83 d7 00             	adc    $0x0,%edi
f01010ff:	f7 df                	neg    %edi
			}
			base = 10;
f0101101:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101106:	eb 70                	jmp    f0101178 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101108:	89 ca                	mov    %ecx,%edx
f010110a:	8d 45 14             	lea    0x14(%ebp),%eax
f010110d:	e8 89 fc ff ff       	call   f0100d9b <getuint>
f0101112:	89 c6                	mov    %eax,%esi
f0101114:	89 d7                	mov    %edx,%edi
			base = 10;
f0101116:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010111b:	eb 5b                	jmp    f0101178 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap, lflag);
f010111d:	89 ca                	mov    %ecx,%edx
f010111f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101122:	e8 74 fc ff ff       	call   f0100d9b <getuint>
f0101127:	89 c6                	mov    %eax,%esi
f0101129:	89 d7                	mov    %edx,%edi
            base = 8;
f010112b:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f0101130:	eb 46                	jmp    f0101178 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f0101132:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101136:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010113d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101140:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101144:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010114b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010114e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101151:	8d 50 04             	lea    0x4(%eax),%edx
f0101154:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101157:	8b 30                	mov    (%eax),%esi
f0101159:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010115e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101163:	eb 13                	jmp    f0101178 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101165:	89 ca                	mov    %ecx,%edx
f0101167:	8d 45 14             	lea    0x14(%ebp),%eax
f010116a:	e8 2c fc ff ff       	call   f0100d9b <getuint>
f010116f:	89 c6                	mov    %eax,%esi
f0101171:	89 d7                	mov    %edx,%edi
			base = 16;
f0101173:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101178:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010117c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101180:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101183:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101187:	89 44 24 08          	mov    %eax,0x8(%esp)
f010118b:	89 34 24             	mov    %esi,(%esp)
f010118e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101192:	89 da                	mov    %ebx,%edx
f0101194:	8b 45 08             	mov    0x8(%ebp),%eax
f0101197:	e8 24 fb ff ff       	call   f0100cc0 <printnum>
			break;
f010119c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010119f:	e9 99 fc ff ff       	jmp    f0100e3d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01011a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011a8:	89 14 24             	mov    %edx,(%esp)
f01011ab:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ae:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01011b1:	e9 87 fc ff ff       	jmp    f0100e3d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01011b6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01011ba:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01011c1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01011c4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01011c8:	0f 84 6f fc ff ff    	je     f0100e3d <vprintfmt+0x23>
f01011ce:	83 ee 01             	sub    $0x1,%esi
f01011d1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01011d5:	75 f7                	jne    f01011ce <vprintfmt+0x3b4>
f01011d7:	e9 61 fc ff ff       	jmp    f0100e3d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01011dc:	83 c4 4c             	add    $0x4c,%esp
f01011df:	5b                   	pop    %ebx
f01011e0:	5e                   	pop    %esi
f01011e1:	5f                   	pop    %edi
f01011e2:	5d                   	pop    %ebp
f01011e3:	c3                   	ret    

f01011e4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01011e4:	55                   	push   %ebp
f01011e5:	89 e5                	mov    %esp,%ebp
f01011e7:	83 ec 28             	sub    $0x28,%esp
f01011ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ed:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01011f0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01011f3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01011f7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01011fa:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101201:	85 c0                	test   %eax,%eax
f0101203:	74 30                	je     f0101235 <vsnprintf+0x51>
f0101205:	85 d2                	test   %edx,%edx
f0101207:	7e 2c                	jle    f0101235 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101209:	8b 45 14             	mov    0x14(%ebp),%eax
f010120c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101210:	8b 45 10             	mov    0x10(%ebp),%eax
f0101213:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101217:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010121a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010121e:	c7 04 24 d5 0d 10 f0 	movl   $0xf0100dd5,(%esp)
f0101225:	e8 f0 fb ff ff       	call   f0100e1a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010122a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010122d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101230:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101233:	eb 05                	jmp    f010123a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101235:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010123a:	c9                   	leave  
f010123b:	c3                   	ret    

f010123c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010123c:	55                   	push   %ebp
f010123d:	89 e5                	mov    %esp,%ebp
f010123f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101242:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101245:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101249:	8b 45 10             	mov    0x10(%ebp),%eax
f010124c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101250:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101253:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101257:	8b 45 08             	mov    0x8(%ebp),%eax
f010125a:	89 04 24             	mov    %eax,(%esp)
f010125d:	e8 82 ff ff ff       	call   f01011e4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101262:	c9                   	leave  
f0101263:	c3                   	ret    
	...

f0101270 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101270:	55                   	push   %ebp
f0101271:	89 e5                	mov    %esp,%ebp
f0101273:	57                   	push   %edi
f0101274:	56                   	push   %esi
f0101275:	53                   	push   %ebx
f0101276:	83 ec 1c             	sub    $0x1c,%esp
f0101279:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010127c:	85 c0                	test   %eax,%eax
f010127e:	74 10                	je     f0101290 <readline+0x20>
		cprintf("%s", prompt);
f0101280:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101284:	c7 04 24 8a 1f 10 f0 	movl   $0xf0101f8a,(%esp)
f010128b:	e8 2e f7 ff ff       	call   f01009be <cprintf>

	i = 0;
	echoing = iscons(0);
f0101290:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101297:	e8 d7 f3 ff ff       	call   f0100673 <iscons>
f010129c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010129e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01012a3:	e8 ba f3 ff ff       	call   f0100662 <getchar>
f01012a8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01012aa:	85 c0                	test   %eax,%eax
f01012ac:	79 17                	jns    f01012c5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01012ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b2:	c7 04 24 6c 21 10 f0 	movl   $0xf010216c,(%esp)
f01012b9:	e8 00 f7 ff ff       	call   f01009be <cprintf>
			return NULL;
f01012be:	b8 00 00 00 00       	mov    $0x0,%eax
f01012c3:	eb 6d                	jmp    f0101332 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01012c5:	83 f8 08             	cmp    $0x8,%eax
f01012c8:	74 05                	je     f01012cf <readline+0x5f>
f01012ca:	83 f8 7f             	cmp    $0x7f,%eax
f01012cd:	75 19                	jne    f01012e8 <readline+0x78>
f01012cf:	85 f6                	test   %esi,%esi
f01012d1:	7e 15                	jle    f01012e8 <readline+0x78>
			if (echoing)
f01012d3:	85 ff                	test   %edi,%edi
f01012d5:	74 0c                	je     f01012e3 <readline+0x73>
				cputchar('\b');
f01012d7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01012de:	e8 6f f3 ff ff       	call   f0100652 <cputchar>
			i--;
f01012e3:	83 ee 01             	sub    $0x1,%esi
f01012e6:	eb bb                	jmp    f01012a3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01012e8:	83 fb 1f             	cmp    $0x1f,%ebx
f01012eb:	7e 1f                	jle    f010130c <readline+0x9c>
f01012ed:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01012f3:	7f 17                	jg     f010130c <readline+0x9c>
			if (echoing)
f01012f5:	85 ff                	test   %edi,%edi
f01012f7:	74 08                	je     f0101301 <readline+0x91>
				cputchar(c);
f01012f9:	89 1c 24             	mov    %ebx,(%esp)
f01012fc:	e8 51 f3 ff ff       	call   f0100652 <cputchar>
			buf[i++] = c;
f0101301:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101307:	83 c6 01             	add    $0x1,%esi
f010130a:	eb 97                	jmp    f01012a3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010130c:	83 fb 0a             	cmp    $0xa,%ebx
f010130f:	74 05                	je     f0101316 <readline+0xa6>
f0101311:	83 fb 0d             	cmp    $0xd,%ebx
f0101314:	75 8d                	jne    f01012a3 <readline+0x33>
			if (echoing)
f0101316:	85 ff                	test   %edi,%edi
f0101318:	74 0c                	je     f0101326 <readline+0xb6>
				cputchar('\n');
f010131a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101321:	e8 2c f3 ff ff       	call   f0100652 <cputchar>
			buf[i] = 0;
f0101326:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010132d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101332:	83 c4 1c             	add    $0x1c,%esp
f0101335:	5b                   	pop    %ebx
f0101336:	5e                   	pop    %esi
f0101337:	5f                   	pop    %edi
f0101338:	5d                   	pop    %ebp
f0101339:	c3                   	ret    
f010133a:	00 00                	add    %al,(%eax)
f010133c:	00 00                	add    %al,(%eax)
	...

f0101340 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101340:	55                   	push   %ebp
f0101341:	89 e5                	mov    %esp,%ebp
f0101343:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101346:	b8 00 00 00 00       	mov    $0x0,%eax
f010134b:	80 3a 00             	cmpb   $0x0,(%edx)
f010134e:	74 09                	je     f0101359 <strlen+0x19>
		n++;
f0101350:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101353:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101357:	75 f7                	jne    f0101350 <strlen+0x10>
		n++;
	return n;
}
f0101359:	5d                   	pop    %ebp
f010135a:	c3                   	ret    

f010135b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010135b:	55                   	push   %ebp
f010135c:	89 e5                	mov    %esp,%ebp
f010135e:	53                   	push   %ebx
f010135f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101362:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101365:	b8 00 00 00 00       	mov    $0x0,%eax
f010136a:	85 c9                	test   %ecx,%ecx
f010136c:	74 1a                	je     f0101388 <strnlen+0x2d>
f010136e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101371:	74 15                	je     f0101388 <strnlen+0x2d>
f0101373:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101378:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010137a:	39 ca                	cmp    %ecx,%edx
f010137c:	74 0a                	je     f0101388 <strnlen+0x2d>
f010137e:	83 c2 01             	add    $0x1,%edx
f0101381:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101386:	75 f0                	jne    f0101378 <strnlen+0x1d>
		n++;
	return n;
}
f0101388:	5b                   	pop    %ebx
f0101389:	5d                   	pop    %ebp
f010138a:	c3                   	ret    

f010138b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010138b:	55                   	push   %ebp
f010138c:	89 e5                	mov    %esp,%ebp
f010138e:	53                   	push   %ebx
f010138f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101392:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101395:	ba 00 00 00 00       	mov    $0x0,%edx
f010139a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010139e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01013a1:	83 c2 01             	add    $0x1,%edx
f01013a4:	84 c9                	test   %cl,%cl
f01013a6:	75 f2                	jne    f010139a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01013a8:	5b                   	pop    %ebx
f01013a9:	5d                   	pop    %ebp
f01013aa:	c3                   	ret    

f01013ab <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01013ab:	55                   	push   %ebp
f01013ac:	89 e5                	mov    %esp,%ebp
f01013ae:	56                   	push   %esi
f01013af:	53                   	push   %ebx
f01013b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01013b3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01013b6:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013b9:	85 f6                	test   %esi,%esi
f01013bb:	74 18                	je     f01013d5 <strncpy+0x2a>
f01013bd:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01013c2:	0f b6 1a             	movzbl (%edx),%ebx
f01013c5:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01013c8:	80 3a 01             	cmpb   $0x1,(%edx)
f01013cb:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01013ce:	83 c1 01             	add    $0x1,%ecx
f01013d1:	39 f1                	cmp    %esi,%ecx
f01013d3:	75 ed                	jne    f01013c2 <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01013d5:	5b                   	pop    %ebx
f01013d6:	5e                   	pop    %esi
f01013d7:	5d                   	pop    %ebp
f01013d8:	c3                   	ret    

f01013d9 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01013d9:	55                   	push   %ebp
f01013da:	89 e5                	mov    %esp,%ebp
f01013dc:	57                   	push   %edi
f01013dd:	56                   	push   %esi
f01013de:	53                   	push   %ebx
f01013df:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01013e5:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01013e8:	89 f8                	mov    %edi,%eax
f01013ea:	85 f6                	test   %esi,%esi
f01013ec:	74 2b                	je     f0101419 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f01013ee:	83 fe 01             	cmp    $0x1,%esi
f01013f1:	74 23                	je     f0101416 <strlcpy+0x3d>
f01013f3:	0f b6 0b             	movzbl (%ebx),%ecx
f01013f6:	84 c9                	test   %cl,%cl
f01013f8:	74 1c                	je     f0101416 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f01013fa:	83 ee 02             	sub    $0x2,%esi
f01013fd:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101402:	88 08                	mov    %cl,(%eax)
f0101404:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101407:	39 f2                	cmp    %esi,%edx
f0101409:	74 0b                	je     f0101416 <strlcpy+0x3d>
f010140b:	83 c2 01             	add    $0x1,%edx
f010140e:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101412:	84 c9                	test   %cl,%cl
f0101414:	75 ec                	jne    f0101402 <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101416:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101419:	29 f8                	sub    %edi,%eax
}
f010141b:	5b                   	pop    %ebx
f010141c:	5e                   	pop    %esi
f010141d:	5f                   	pop    %edi
f010141e:	5d                   	pop    %ebp
f010141f:	c3                   	ret    

f0101420 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101420:	55                   	push   %ebp
f0101421:	89 e5                	mov    %esp,%ebp
f0101423:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101426:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101429:	0f b6 01             	movzbl (%ecx),%eax
f010142c:	84 c0                	test   %al,%al
f010142e:	74 16                	je     f0101446 <strcmp+0x26>
f0101430:	3a 02                	cmp    (%edx),%al
f0101432:	75 12                	jne    f0101446 <strcmp+0x26>
		p++, q++;
f0101434:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101437:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f010143b:	84 c0                	test   %al,%al
f010143d:	74 07                	je     f0101446 <strcmp+0x26>
f010143f:	83 c1 01             	add    $0x1,%ecx
f0101442:	3a 02                	cmp    (%edx),%al
f0101444:	74 ee                	je     f0101434 <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101446:	0f b6 c0             	movzbl %al,%eax
f0101449:	0f b6 12             	movzbl (%edx),%edx
f010144c:	29 d0                	sub    %edx,%eax
}
f010144e:	5d                   	pop    %ebp
f010144f:	c3                   	ret    

f0101450 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101450:	55                   	push   %ebp
f0101451:	89 e5                	mov    %esp,%ebp
f0101453:	53                   	push   %ebx
f0101454:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101457:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010145a:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010145d:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101462:	85 d2                	test   %edx,%edx
f0101464:	74 28                	je     f010148e <strncmp+0x3e>
f0101466:	0f b6 01             	movzbl (%ecx),%eax
f0101469:	84 c0                	test   %al,%al
f010146b:	74 24                	je     f0101491 <strncmp+0x41>
f010146d:	3a 03                	cmp    (%ebx),%al
f010146f:	75 20                	jne    f0101491 <strncmp+0x41>
f0101471:	83 ea 01             	sub    $0x1,%edx
f0101474:	74 13                	je     f0101489 <strncmp+0x39>
		n--, p++, q++;
f0101476:	83 c1 01             	add    $0x1,%ecx
f0101479:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010147c:	0f b6 01             	movzbl (%ecx),%eax
f010147f:	84 c0                	test   %al,%al
f0101481:	74 0e                	je     f0101491 <strncmp+0x41>
f0101483:	3a 03                	cmp    (%ebx),%al
f0101485:	74 ea                	je     f0101471 <strncmp+0x21>
f0101487:	eb 08                	jmp    f0101491 <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101489:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010148e:	5b                   	pop    %ebx
f010148f:	5d                   	pop    %ebp
f0101490:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101491:	0f b6 01             	movzbl (%ecx),%eax
f0101494:	0f b6 13             	movzbl (%ebx),%edx
f0101497:	29 d0                	sub    %edx,%eax
f0101499:	eb f3                	jmp    f010148e <strncmp+0x3e>

f010149b <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010149b:	55                   	push   %ebp
f010149c:	89 e5                	mov    %esp,%ebp
f010149e:	8b 45 08             	mov    0x8(%ebp),%eax
f01014a1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014a5:	0f b6 10             	movzbl (%eax),%edx
f01014a8:	84 d2                	test   %dl,%dl
f01014aa:	74 1c                	je     f01014c8 <strchr+0x2d>
		if (*s == c)
f01014ac:	38 ca                	cmp    %cl,%dl
f01014ae:	75 09                	jne    f01014b9 <strchr+0x1e>
f01014b0:	eb 1b                	jmp    f01014cd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014b2:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01014b5:	38 ca                	cmp    %cl,%dl
f01014b7:	74 14                	je     f01014cd <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01014b9:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01014bd:	84 d2                	test   %dl,%dl
f01014bf:	75 f1                	jne    f01014b2 <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01014c1:	b8 00 00 00 00       	mov    $0x0,%eax
f01014c6:	eb 05                	jmp    f01014cd <strchr+0x32>
f01014c8:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014cd:	5d                   	pop    %ebp
f01014ce:	c3                   	ret    

f01014cf <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01014cf:	55                   	push   %ebp
f01014d0:	89 e5                	mov    %esp,%ebp
f01014d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d5:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01014d9:	0f b6 10             	movzbl (%eax),%edx
f01014dc:	84 d2                	test   %dl,%dl
f01014de:	74 14                	je     f01014f4 <strfind+0x25>
		if (*s == c)
f01014e0:	38 ca                	cmp    %cl,%dl
f01014e2:	75 06                	jne    f01014ea <strfind+0x1b>
f01014e4:	eb 0e                	jmp    f01014f4 <strfind+0x25>
f01014e6:	38 ca                	cmp    %cl,%dl
f01014e8:	74 0a                	je     f01014f4 <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01014ea:	83 c0 01             	add    $0x1,%eax
f01014ed:	0f b6 10             	movzbl (%eax),%edx
f01014f0:	84 d2                	test   %dl,%dl
f01014f2:	75 f2                	jne    f01014e6 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f01014f4:	5d                   	pop    %ebp
f01014f5:	c3                   	ret    

f01014f6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01014f6:	55                   	push   %ebp
f01014f7:	89 e5                	mov    %esp,%ebp
f01014f9:	83 ec 0c             	sub    $0xc,%esp
f01014fc:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01014ff:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101502:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101505:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101508:	8b 45 0c             	mov    0xc(%ebp),%eax
f010150b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010150e:	85 c9                	test   %ecx,%ecx
f0101510:	74 30                	je     f0101542 <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101512:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101518:	75 25                	jne    f010153f <memset+0x49>
f010151a:	f6 c1 03             	test   $0x3,%cl
f010151d:	75 20                	jne    f010153f <memset+0x49>
		c &= 0xFF;
f010151f:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101522:	89 d3                	mov    %edx,%ebx
f0101524:	c1 e3 08             	shl    $0x8,%ebx
f0101527:	89 d6                	mov    %edx,%esi
f0101529:	c1 e6 18             	shl    $0x18,%esi
f010152c:	89 d0                	mov    %edx,%eax
f010152e:	c1 e0 10             	shl    $0x10,%eax
f0101531:	09 f0                	or     %esi,%eax
f0101533:	09 d0                	or     %edx,%eax
f0101535:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101537:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010153a:	fc                   	cld    
f010153b:	f3 ab                	rep stos %eax,%es:(%edi)
f010153d:	eb 03                	jmp    f0101542 <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010153f:	fc                   	cld    
f0101540:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101542:	89 f8                	mov    %edi,%eax
f0101544:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101547:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010154a:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010154d:	89 ec                	mov    %ebp,%esp
f010154f:	5d                   	pop    %ebp
f0101550:	c3                   	ret    

f0101551 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101551:	55                   	push   %ebp
f0101552:	89 e5                	mov    %esp,%ebp
f0101554:	83 ec 08             	sub    $0x8,%esp
f0101557:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010155a:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010155d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101560:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101563:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101566:	39 c6                	cmp    %eax,%esi
f0101568:	73 36                	jae    f01015a0 <memmove+0x4f>
f010156a:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f010156d:	39 d0                	cmp    %edx,%eax
f010156f:	73 2f                	jae    f01015a0 <memmove+0x4f>
		s += n;
		d += n;
f0101571:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101574:	f6 c2 03             	test   $0x3,%dl
f0101577:	75 1b                	jne    f0101594 <memmove+0x43>
f0101579:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010157f:	75 13                	jne    f0101594 <memmove+0x43>
f0101581:	f6 c1 03             	test   $0x3,%cl
f0101584:	75 0e                	jne    f0101594 <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101586:	83 ef 04             	sub    $0x4,%edi
f0101589:	8d 72 fc             	lea    -0x4(%edx),%esi
f010158c:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010158f:	fd                   	std    
f0101590:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101592:	eb 09                	jmp    f010159d <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101594:	83 ef 01             	sub    $0x1,%edi
f0101597:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f010159a:	fd                   	std    
f010159b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010159d:	fc                   	cld    
f010159e:	eb 20                	jmp    f01015c0 <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01015a0:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01015a6:	75 13                	jne    f01015bb <memmove+0x6a>
f01015a8:	a8 03                	test   $0x3,%al
f01015aa:	75 0f                	jne    f01015bb <memmove+0x6a>
f01015ac:	f6 c1 03             	test   $0x3,%cl
f01015af:	75 0a                	jne    f01015bb <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01015b1:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01015b4:	89 c7                	mov    %eax,%edi
f01015b6:	fc                   	cld    
f01015b7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01015b9:	eb 05                	jmp    f01015c0 <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01015bb:	89 c7                	mov    %eax,%edi
f01015bd:	fc                   	cld    
f01015be:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01015c0:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01015c3:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01015c6:	89 ec                	mov    %ebp,%esp
f01015c8:	5d                   	pop    %ebp
f01015c9:	c3                   	ret    

f01015ca <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01015ca:	55                   	push   %ebp
f01015cb:	89 e5                	mov    %esp,%ebp
f01015cd:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01015d0:	8b 45 10             	mov    0x10(%ebp),%eax
f01015d3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015de:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e1:	89 04 24             	mov    %eax,(%esp)
f01015e4:	e8 68 ff ff ff       	call   f0101551 <memmove>
}
f01015e9:	c9                   	leave  
f01015ea:	c3                   	ret    

f01015eb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01015eb:	55                   	push   %ebp
f01015ec:	89 e5                	mov    %esp,%ebp
f01015ee:	57                   	push   %edi
f01015ef:	56                   	push   %esi
f01015f0:	53                   	push   %ebx
f01015f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01015f4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01015f7:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01015fa:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01015ff:	85 ff                	test   %edi,%edi
f0101601:	74 37                	je     f010163a <memcmp+0x4f>
		if (*s1 != *s2)
f0101603:	0f b6 03             	movzbl (%ebx),%eax
f0101606:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101609:	83 ef 01             	sub    $0x1,%edi
f010160c:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101611:	38 c8                	cmp    %cl,%al
f0101613:	74 1c                	je     f0101631 <memcmp+0x46>
f0101615:	eb 10                	jmp    f0101627 <memcmp+0x3c>
f0101617:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010161c:	83 c2 01             	add    $0x1,%edx
f010161f:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101623:	38 c8                	cmp    %cl,%al
f0101625:	74 0a                	je     f0101631 <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101627:	0f b6 c0             	movzbl %al,%eax
f010162a:	0f b6 c9             	movzbl %cl,%ecx
f010162d:	29 c8                	sub    %ecx,%eax
f010162f:	eb 09                	jmp    f010163a <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101631:	39 fa                	cmp    %edi,%edx
f0101633:	75 e2                	jne    f0101617 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101635:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010163a:	5b                   	pop    %ebx
f010163b:	5e                   	pop    %esi
f010163c:	5f                   	pop    %edi
f010163d:	5d                   	pop    %ebp
f010163e:	c3                   	ret    

f010163f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010163f:	55                   	push   %ebp
f0101640:	89 e5                	mov    %esp,%ebp
f0101642:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101645:	89 c2                	mov    %eax,%edx
f0101647:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010164a:	39 d0                	cmp    %edx,%eax
f010164c:	73 15                	jae    f0101663 <memfind+0x24>
		if (*(const unsigned char *) s == (unsigned char) c)
f010164e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101652:	38 08                	cmp    %cl,(%eax)
f0101654:	75 06                	jne    f010165c <memfind+0x1d>
f0101656:	eb 0b                	jmp    f0101663 <memfind+0x24>
f0101658:	38 08                	cmp    %cl,(%eax)
f010165a:	74 07                	je     f0101663 <memfind+0x24>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f010165c:	83 c0 01             	add    $0x1,%eax
f010165f:	39 d0                	cmp    %edx,%eax
f0101661:	75 f5                	jne    f0101658 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101663:	5d                   	pop    %ebp
f0101664:	c3                   	ret    

f0101665 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101665:	55                   	push   %ebp
f0101666:	89 e5                	mov    %esp,%ebp
f0101668:	57                   	push   %edi
f0101669:	56                   	push   %esi
f010166a:	53                   	push   %ebx
f010166b:	8b 55 08             	mov    0x8(%ebp),%edx
f010166e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101671:	0f b6 02             	movzbl (%edx),%eax
f0101674:	3c 20                	cmp    $0x20,%al
f0101676:	74 04                	je     f010167c <strtol+0x17>
f0101678:	3c 09                	cmp    $0x9,%al
f010167a:	75 0e                	jne    f010168a <strtol+0x25>
		s++;
f010167c:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010167f:	0f b6 02             	movzbl (%edx),%eax
f0101682:	3c 20                	cmp    $0x20,%al
f0101684:	74 f6                	je     f010167c <strtol+0x17>
f0101686:	3c 09                	cmp    $0x9,%al
f0101688:	74 f2                	je     f010167c <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f010168a:	3c 2b                	cmp    $0x2b,%al
f010168c:	75 0a                	jne    f0101698 <strtol+0x33>
		s++;
f010168e:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101691:	bf 00 00 00 00       	mov    $0x0,%edi
f0101696:	eb 10                	jmp    f01016a8 <strtol+0x43>
f0101698:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010169d:	3c 2d                	cmp    $0x2d,%al
f010169f:	75 07                	jne    f01016a8 <strtol+0x43>
		s++, neg = 1;
f01016a1:	83 c2 01             	add    $0x1,%edx
f01016a4:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01016a8:	85 db                	test   %ebx,%ebx
f01016aa:	0f 94 c0             	sete   %al
f01016ad:	74 05                	je     f01016b4 <strtol+0x4f>
f01016af:	83 fb 10             	cmp    $0x10,%ebx
f01016b2:	75 15                	jne    f01016c9 <strtol+0x64>
f01016b4:	80 3a 30             	cmpb   $0x30,(%edx)
f01016b7:	75 10                	jne    f01016c9 <strtol+0x64>
f01016b9:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01016bd:	75 0a                	jne    f01016c9 <strtol+0x64>
		s += 2, base = 16;
f01016bf:	83 c2 02             	add    $0x2,%edx
f01016c2:	bb 10 00 00 00       	mov    $0x10,%ebx
f01016c7:	eb 13                	jmp    f01016dc <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01016c9:	84 c0                	test   %al,%al
f01016cb:	74 0f                	je     f01016dc <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01016cd:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01016d2:	80 3a 30             	cmpb   $0x30,(%edx)
f01016d5:	75 05                	jne    f01016dc <strtol+0x77>
		s++, base = 8;
f01016d7:	83 c2 01             	add    $0x1,%edx
f01016da:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01016dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01016e1:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01016e3:	0f b6 0a             	movzbl (%edx),%ecx
f01016e6:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01016e9:	80 fb 09             	cmp    $0x9,%bl
f01016ec:	77 08                	ja     f01016f6 <strtol+0x91>
			dig = *s - '0';
f01016ee:	0f be c9             	movsbl %cl,%ecx
f01016f1:	83 e9 30             	sub    $0x30,%ecx
f01016f4:	eb 1e                	jmp    f0101714 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01016f6:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01016f9:	80 fb 19             	cmp    $0x19,%bl
f01016fc:	77 08                	ja     f0101706 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01016fe:	0f be c9             	movsbl %cl,%ecx
f0101701:	83 e9 57             	sub    $0x57,%ecx
f0101704:	eb 0e                	jmp    f0101714 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101706:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101709:	80 fb 19             	cmp    $0x19,%bl
f010170c:	77 14                	ja     f0101722 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010170e:	0f be c9             	movsbl %cl,%ecx
f0101711:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101714:	39 f1                	cmp    %esi,%ecx
f0101716:	7d 0e                	jge    f0101726 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101718:	83 c2 01             	add    $0x1,%edx
f010171b:	0f af c6             	imul   %esi,%eax
f010171e:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101720:	eb c1                	jmp    f01016e3 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101722:	89 c1                	mov    %eax,%ecx
f0101724:	eb 02                	jmp    f0101728 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101726:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101728:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010172c:	74 05                	je     f0101733 <strtol+0xce>
		*endptr = (char *) s;
f010172e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101731:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101733:	89 ca                	mov    %ecx,%edx
f0101735:	f7 da                	neg    %edx
f0101737:	85 ff                	test   %edi,%edi
f0101739:	0f 45 c2             	cmovne %edx,%eax
}
f010173c:	5b                   	pop    %ebx
f010173d:	5e                   	pop    %esi
f010173e:	5f                   	pop    %edi
f010173f:	5d                   	pop    %ebp
f0101740:	c3                   	ret    
	...

f0101750 <__udivdi3>:
f0101750:	83 ec 1c             	sub    $0x1c,%esp
f0101753:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101757:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010175b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010175f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101763:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101767:	8b 74 24 24          	mov    0x24(%esp),%esi
f010176b:	85 ff                	test   %edi,%edi
f010176d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101771:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101775:	89 cd                	mov    %ecx,%ebp
f0101777:	89 44 24 04          	mov    %eax,0x4(%esp)
f010177b:	75 33                	jne    f01017b0 <__udivdi3+0x60>
f010177d:	39 f1                	cmp    %esi,%ecx
f010177f:	77 57                	ja     f01017d8 <__udivdi3+0x88>
f0101781:	85 c9                	test   %ecx,%ecx
f0101783:	75 0b                	jne    f0101790 <__udivdi3+0x40>
f0101785:	b8 01 00 00 00       	mov    $0x1,%eax
f010178a:	31 d2                	xor    %edx,%edx
f010178c:	f7 f1                	div    %ecx
f010178e:	89 c1                	mov    %eax,%ecx
f0101790:	89 f0                	mov    %esi,%eax
f0101792:	31 d2                	xor    %edx,%edx
f0101794:	f7 f1                	div    %ecx
f0101796:	89 c6                	mov    %eax,%esi
f0101798:	8b 44 24 04          	mov    0x4(%esp),%eax
f010179c:	f7 f1                	div    %ecx
f010179e:	89 f2                	mov    %esi,%edx
f01017a0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017a4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017a8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ac:	83 c4 1c             	add    $0x1c,%esp
f01017af:	c3                   	ret    
f01017b0:	31 d2                	xor    %edx,%edx
f01017b2:	31 c0                	xor    %eax,%eax
f01017b4:	39 f7                	cmp    %esi,%edi
f01017b6:	77 e8                	ja     f01017a0 <__udivdi3+0x50>
f01017b8:	0f bd cf             	bsr    %edi,%ecx
f01017bb:	83 f1 1f             	xor    $0x1f,%ecx
f01017be:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01017c2:	75 2c                	jne    f01017f0 <__udivdi3+0xa0>
f01017c4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f01017c8:	76 04                	jbe    f01017ce <__udivdi3+0x7e>
f01017ca:	39 f7                	cmp    %esi,%edi
f01017cc:	73 d2                	jae    f01017a0 <__udivdi3+0x50>
f01017ce:	31 d2                	xor    %edx,%edx
f01017d0:	b8 01 00 00 00       	mov    $0x1,%eax
f01017d5:	eb c9                	jmp    f01017a0 <__udivdi3+0x50>
f01017d7:	90                   	nop
f01017d8:	89 f2                	mov    %esi,%edx
f01017da:	f7 f1                	div    %ecx
f01017dc:	31 d2                	xor    %edx,%edx
f01017de:	8b 74 24 10          	mov    0x10(%esp),%esi
f01017e2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01017e6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01017ea:	83 c4 1c             	add    $0x1c,%esp
f01017ed:	c3                   	ret    
f01017ee:	66 90                	xchg   %ax,%ax
f01017f0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01017f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01017fa:	89 ea                	mov    %ebp,%edx
f01017fc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101800:	d3 e7                	shl    %cl,%edi
f0101802:	89 c1                	mov    %eax,%ecx
f0101804:	d3 ea                	shr    %cl,%edx
f0101806:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010180b:	09 fa                	or     %edi,%edx
f010180d:	89 f7                	mov    %esi,%edi
f010180f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101813:	89 f2                	mov    %esi,%edx
f0101815:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101819:	d3 e5                	shl    %cl,%ebp
f010181b:	89 c1                	mov    %eax,%ecx
f010181d:	d3 ef                	shr    %cl,%edi
f010181f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101824:	d3 e2                	shl    %cl,%edx
f0101826:	89 c1                	mov    %eax,%ecx
f0101828:	d3 ee                	shr    %cl,%esi
f010182a:	09 d6                	or     %edx,%esi
f010182c:	89 fa                	mov    %edi,%edx
f010182e:	89 f0                	mov    %esi,%eax
f0101830:	f7 74 24 0c          	divl   0xc(%esp)
f0101834:	89 d7                	mov    %edx,%edi
f0101836:	89 c6                	mov    %eax,%esi
f0101838:	f7 e5                	mul    %ebp
f010183a:	39 d7                	cmp    %edx,%edi
f010183c:	72 22                	jb     f0101860 <__udivdi3+0x110>
f010183e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101842:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101847:	d3 e5                	shl    %cl,%ebp
f0101849:	39 c5                	cmp    %eax,%ebp
f010184b:	73 04                	jae    f0101851 <__udivdi3+0x101>
f010184d:	39 d7                	cmp    %edx,%edi
f010184f:	74 0f                	je     f0101860 <__udivdi3+0x110>
f0101851:	89 f0                	mov    %esi,%eax
f0101853:	31 d2                	xor    %edx,%edx
f0101855:	e9 46 ff ff ff       	jmp    f01017a0 <__udivdi3+0x50>
f010185a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101860:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101863:	31 d2                	xor    %edx,%edx
f0101865:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101869:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010186d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101871:	83 c4 1c             	add    $0x1c,%esp
f0101874:	c3                   	ret    
	...

f0101880 <__umoddi3>:
f0101880:	83 ec 1c             	sub    $0x1c,%esp
f0101883:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101887:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010188b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010188f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101893:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101897:	8b 74 24 24          	mov    0x24(%esp),%esi
f010189b:	85 ed                	test   %ebp,%ebp
f010189d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01018a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018a5:	89 cf                	mov    %ecx,%edi
f01018a7:	89 04 24             	mov    %eax,(%esp)
f01018aa:	89 f2                	mov    %esi,%edx
f01018ac:	75 1a                	jne    f01018c8 <__umoddi3+0x48>
f01018ae:	39 f1                	cmp    %esi,%ecx
f01018b0:	76 4e                	jbe    f0101900 <__umoddi3+0x80>
f01018b2:	f7 f1                	div    %ecx
f01018b4:	89 d0                	mov    %edx,%eax
f01018b6:	31 d2                	xor    %edx,%edx
f01018b8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018bc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018c0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018c4:	83 c4 1c             	add    $0x1c,%esp
f01018c7:	c3                   	ret    
f01018c8:	39 f5                	cmp    %esi,%ebp
f01018ca:	77 54                	ja     f0101920 <__umoddi3+0xa0>
f01018cc:	0f bd c5             	bsr    %ebp,%eax
f01018cf:	83 f0 1f             	xor    $0x1f,%eax
f01018d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018d6:	75 60                	jne    f0101938 <__umoddi3+0xb8>
f01018d8:	3b 0c 24             	cmp    (%esp),%ecx
f01018db:	0f 87 07 01 00 00    	ja     f01019e8 <__umoddi3+0x168>
f01018e1:	89 f2                	mov    %esi,%edx
f01018e3:	8b 34 24             	mov    (%esp),%esi
f01018e6:	29 ce                	sub    %ecx,%esi
f01018e8:	19 ea                	sbb    %ebp,%edx
f01018ea:	89 34 24             	mov    %esi,(%esp)
f01018ed:	8b 04 24             	mov    (%esp),%eax
f01018f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01018f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01018f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01018fc:	83 c4 1c             	add    $0x1c,%esp
f01018ff:	c3                   	ret    
f0101900:	85 c9                	test   %ecx,%ecx
f0101902:	75 0b                	jne    f010190f <__umoddi3+0x8f>
f0101904:	b8 01 00 00 00       	mov    $0x1,%eax
f0101909:	31 d2                	xor    %edx,%edx
f010190b:	f7 f1                	div    %ecx
f010190d:	89 c1                	mov    %eax,%ecx
f010190f:	89 f0                	mov    %esi,%eax
f0101911:	31 d2                	xor    %edx,%edx
f0101913:	f7 f1                	div    %ecx
f0101915:	8b 04 24             	mov    (%esp),%eax
f0101918:	f7 f1                	div    %ecx
f010191a:	eb 98                	jmp    f01018b4 <__umoddi3+0x34>
f010191c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101920:	89 f2                	mov    %esi,%edx
f0101922:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101926:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010192a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010192e:	83 c4 1c             	add    $0x1c,%esp
f0101931:	c3                   	ret    
f0101932:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101938:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010193d:	89 e8                	mov    %ebp,%eax
f010193f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101944:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101948:	89 fa                	mov    %edi,%edx
f010194a:	d3 e0                	shl    %cl,%eax
f010194c:	89 e9                	mov    %ebp,%ecx
f010194e:	d3 ea                	shr    %cl,%edx
f0101950:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101955:	09 c2                	or     %eax,%edx
f0101957:	8b 44 24 08          	mov    0x8(%esp),%eax
f010195b:	89 14 24             	mov    %edx,(%esp)
f010195e:	89 f2                	mov    %esi,%edx
f0101960:	d3 e7                	shl    %cl,%edi
f0101962:	89 e9                	mov    %ebp,%ecx
f0101964:	d3 ea                	shr    %cl,%edx
f0101966:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010196b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010196f:	d3 e6                	shl    %cl,%esi
f0101971:	89 e9                	mov    %ebp,%ecx
f0101973:	d3 e8                	shr    %cl,%eax
f0101975:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010197a:	09 f0                	or     %esi,%eax
f010197c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101980:	f7 34 24             	divl   (%esp)
f0101983:	d3 e6                	shl    %cl,%esi
f0101985:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101989:	89 d6                	mov    %edx,%esi
f010198b:	f7 e7                	mul    %edi
f010198d:	39 d6                	cmp    %edx,%esi
f010198f:	89 c1                	mov    %eax,%ecx
f0101991:	89 d7                	mov    %edx,%edi
f0101993:	72 3f                	jb     f01019d4 <__umoddi3+0x154>
f0101995:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101999:	72 35                	jb     f01019d0 <__umoddi3+0x150>
f010199b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010199f:	29 c8                	sub    %ecx,%eax
f01019a1:	19 fe                	sbb    %edi,%esi
f01019a3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019a8:	89 f2                	mov    %esi,%edx
f01019aa:	d3 e8                	shr    %cl,%eax
f01019ac:	89 e9                	mov    %ebp,%ecx
f01019ae:	d3 e2                	shl    %cl,%edx
f01019b0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019b5:	09 d0                	or     %edx,%eax
f01019b7:	89 f2                	mov    %esi,%edx
f01019b9:	d3 ea                	shr    %cl,%edx
f01019bb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01019bf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01019c3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01019c7:	83 c4 1c             	add    $0x1c,%esp
f01019ca:	c3                   	ret    
f01019cb:	90                   	nop
f01019cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	39 d6                	cmp    %edx,%esi
f01019d2:	75 c7                	jne    f010199b <__umoddi3+0x11b>
f01019d4:	89 d7                	mov    %edx,%edi
f01019d6:	89 c1                	mov    %eax,%ecx
f01019d8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01019dc:	1b 3c 24             	sbb    (%esp),%edi
f01019df:	eb ba                	jmp    f010199b <__umoddi3+0x11b>
f01019e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019e8:	39 f5                	cmp    %esi,%ebp
f01019ea:	0f 82 f1 fe ff ff    	jb     f01018e1 <__umoddi3+0x61>
f01019f0:	e9 f8 fe ff ff       	jmp    f01018ed <__umoddi3+0x6d>
