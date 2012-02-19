
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
f0100015:	b8 00 90 11 00       	mov    $0x119000,%eax
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
f0100034:	bc 00 90 11 f0       	mov    $0xf0119000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


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
f0100046:	b8 30 dd 17 f0       	mov    $0xf017dd30,%eax
f010004b:	2d 33 ce 17 f0       	sub    $0xf017ce33,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 33 ce 17 f0 	movl   $0xf017ce33,(%esp)
f0100063:	e8 a9 46 00 00       	call   f0104711 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 bf 04 00 00       	call   f010052c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 4c 10 f0 	movl   $0xf0104c20,(%esp)
f010007c:	e8 c9 36 00 00       	call   f010374a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 df 12 00 00       	call   f0101365 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100086:	e8 26 30 00 00       	call   f01030b1 <env_init>
	trap_init();
f010008b:	90                   	nop
f010008c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100090:	e8 2c 37 00 00       	call   f01037c1 <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f0100095:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010009c:	00 
f010009d:	c7 44 24 04 2e 78 00 	movl   $0x782e,0x4(%esp)
f01000a4:	00 
f01000a5:	c7 04 24 58 b3 11 f0 	movl   $0xf011b358,(%esp)
f01000ac:	e8 12 32 00 00       	call   f01032c3 <env_create>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000b1:	a1 88 d0 17 f0       	mov    0xf017d088,%eax
f01000b6:	89 04 24             	mov    %eax,(%esp)
f01000b9:	e8 ab 35 00 00       	call   f0103669 <env_run>

f01000be <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000be:	55                   	push   %ebp
f01000bf:	89 e5                	mov    %esp,%ebp
f01000c1:	56                   	push   %esi
f01000c2:	53                   	push   %ebx
f01000c3:	83 ec 10             	sub    $0x10,%esp
f01000c6:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000c9:	83 3d 20 dd 17 f0 00 	cmpl   $0x0,0xf017dd20
f01000d0:	75 3d                	jne    f010010f <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000d2:	89 35 20 dd 17 f0    	mov    %esi,0xf017dd20

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000d8:	fa                   	cli    
f01000d9:	fc                   	cld    

	va_start(ap, fmt);
f01000da:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000e0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01000e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000eb:	c7 04 24 3b 4c 10 f0 	movl   $0xf0104c3b,(%esp)
f01000f2:	e8 53 36 00 00       	call   f010374a <cprintf>
	vcprintf(fmt, ap);
f01000f7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000fb:	89 34 24             	mov    %esi,(%esp)
f01000fe:	e8 14 36 00 00       	call   f0103717 <vcprintf>
	cprintf("\n");
f0100103:	c7 04 24 bf 5b 10 f0 	movl   $0xf0105bbf,(%esp)
f010010a:	e8 3b 36 00 00       	call   f010374a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010010f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100116:	e8 ed 06 00 00       	call   f0100808 <monitor>
f010011b:	eb f2                	jmp    f010010f <_panic+0x51>

f010011d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011d:	55                   	push   %ebp
f010011e:	89 e5                	mov    %esp,%ebp
f0100120:	53                   	push   %ebx
f0100121:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100124:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100127:	8b 45 0c             	mov    0xc(%ebp),%eax
f010012a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010012e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100131:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100135:	c7 04 24 53 4c 10 f0 	movl   $0xf0104c53,(%esp)
f010013c:	e8 09 36 00 00       	call   f010374a <cprintf>
	vcprintf(fmt, ap);
f0100141:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100145:	8b 45 10             	mov    0x10(%ebp),%eax
f0100148:	89 04 24             	mov    %eax,(%esp)
f010014b:	e8 c7 35 00 00       	call   f0103717 <vcprintf>
	cprintf("\n");
f0100150:	c7 04 24 bf 5b 10 f0 	movl   $0xf0105bbf,(%esp)
f0100157:	e8 ee 35 00 00       	call   f010374a <cprintf>
	va_end(ap);
}
f010015c:	83 c4 14             	add    $0x14,%esp
f010015f:	5b                   	pop    %ebx
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    
	...

f0100170 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100170:	55                   	push   %ebp
f0100171:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100173:	ba 84 00 00 00       	mov    $0x84,%edx
f0100178:	ec                   	in     (%dx),%al
f0100179:	ec                   	in     (%dx),%al
f010017a:	ec                   	in     (%dx),%al
f010017b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010017c:	5d                   	pop    %ebp
f010017d:	c3                   	ret    

f010017e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010017e:	55                   	push   %ebp
f010017f:	89 e5                	mov    %esp,%ebp
f0100181:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100186:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100187:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010018c:	a8 01                	test   $0x1,%al
f010018e:	74 06                	je     f0100196 <serial_proc_data+0x18>
f0100190:	b2 f8                	mov    $0xf8,%dl
f0100192:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100193:	0f b6 c8             	movzbl %al,%ecx
}
f0100196:	89 c8                	mov    %ecx,%eax
f0100198:	5d                   	pop    %ebp
f0100199:	c3                   	ret    

f010019a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010019a:	55                   	push   %ebp
f010019b:	89 e5                	mov    %esp,%ebp
f010019d:	53                   	push   %ebx
f010019e:	83 ec 04             	sub    $0x4,%esp
f01001a1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001a3:	eb 25                	jmp    f01001ca <cons_intr+0x30>
		if (c == 0)
f01001a5:	85 c0                	test   %eax,%eax
f01001a7:	74 21                	je     f01001ca <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a9:	8b 15 64 d0 17 f0    	mov    0xf017d064,%edx
f01001af:	88 82 60 ce 17 f0    	mov    %al,-0xfe831a0(%edx)
f01001b5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001b8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001bd:	ba 00 00 00 00       	mov    $0x0,%edx
f01001c2:	0f 44 c2             	cmove  %edx,%eax
f01001c5:	a3 64 d0 17 f0       	mov    %eax,0xf017d064
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ca:	ff d3                	call   *%ebx
f01001cc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001cf:	75 d4                	jne    f01001a5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001d1:	83 c4 04             	add    $0x4,%esp
f01001d4:	5b                   	pop    %ebx
f01001d5:	5d                   	pop    %ebp
f01001d6:	c3                   	ret    

f01001d7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001d7:	55                   	push   %ebp
f01001d8:	89 e5                	mov    %esp,%ebp
f01001da:	57                   	push   %edi
f01001db:	56                   	push   %esi
f01001dc:	53                   	push   %ebx
f01001dd:	83 ec 2c             	sub    $0x2c,%esp
f01001e0:	89 c7                	mov    %eax,%edi
f01001e2:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001e7:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001e8:	a8 20                	test   $0x20,%al
f01001ea:	75 1b                	jne    f0100207 <cons_putc+0x30>
f01001ec:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f1:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001f6:	e8 75 ff ff ff       	call   f0100170 <delay>
f01001fb:	89 f2                	mov    %esi,%edx
f01001fd:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;
	
	for (i = 0;
f01001fe:	a8 20                	test   $0x20,%al
f0100200:	75 05                	jne    f0100207 <cons_putc+0x30>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100202:	83 eb 01             	sub    $0x1,%ebx
f0100205:	75 ef                	jne    f01001f6 <cons_putc+0x1f>
	     i++)
		delay();
	
	outb(COM1 + COM_TX, c);
f0100207:	89 fa                	mov    %edi,%edx
f0100209:	89 f8                	mov    %edi,%eax
f010020b:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010020e:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100213:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100214:	b2 79                	mov    $0x79,%dl
f0100216:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100217:	84 c0                	test   %al,%al
f0100219:	78 1b                	js     f0100236 <cons_putc+0x5f>
f010021b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100220:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100225:	e8 46 ff ff ff       	call   f0100170 <delay>
f010022a:	89 f2                	mov    %esi,%edx
f010022c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010022d:	84 c0                	test   %al,%al
f010022f:	78 05                	js     f0100236 <cons_putc+0x5f>
f0100231:	83 eb 01             	sub    $0x1,%ebx
f0100234:	75 ef                	jne    f0100225 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100236:	ba 78 03 00 00       	mov    $0x378,%edx
f010023b:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f010023f:	ee                   	out    %al,(%dx)
f0100240:	b2 7a                	mov    $0x7a,%dl
f0100242:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100247:	ee                   	out    %al,(%dx)
f0100248:	b8 08 00 00 00       	mov    $0x8,%eax
f010024d:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f010024e:	89 fa                	mov    %edi,%edx
f0100250:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100256:	89 f8                	mov    %edi,%eax
f0100258:	80 cc 07             	or     $0x7,%ah
f010025b:	85 d2                	test   %edx,%edx
f010025d:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100260:	89 f8                	mov    %edi,%eax
f0100262:	25 ff 00 00 00       	and    $0xff,%eax
f0100267:	83 f8 09             	cmp    $0x9,%eax
f010026a:	74 7c                	je     f01002e8 <cons_putc+0x111>
f010026c:	83 f8 09             	cmp    $0x9,%eax
f010026f:	7f 0b                	jg     f010027c <cons_putc+0xa5>
f0100271:	83 f8 08             	cmp    $0x8,%eax
f0100274:	0f 85 a2 00 00 00    	jne    f010031c <cons_putc+0x145>
f010027a:	eb 16                	jmp    f0100292 <cons_putc+0xbb>
f010027c:	83 f8 0a             	cmp    $0xa,%eax
f010027f:	90                   	nop
f0100280:	74 40                	je     f01002c2 <cons_putc+0xeb>
f0100282:	83 f8 0d             	cmp    $0xd,%eax
f0100285:	0f 85 91 00 00 00    	jne    f010031c <cons_putc+0x145>
f010028b:	90                   	nop
f010028c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100290:	eb 38                	jmp    f01002ca <cons_putc+0xf3>
	case '\b':
		if (crt_pos > 0) {
f0100292:	0f b7 05 74 d0 17 f0 	movzwl 0xf017d074,%eax
f0100299:	66 85 c0             	test   %ax,%ax
f010029c:	0f 84 e4 00 00 00    	je     f0100386 <cons_putc+0x1af>
			crt_pos--;
f01002a2:	83 e8 01             	sub    $0x1,%eax
f01002a5:	66 a3 74 d0 17 f0    	mov    %ax,0xf017d074
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002ab:	0f b7 c0             	movzwl %ax,%eax
f01002ae:	66 81 e7 00 ff       	and    $0xff00,%di
f01002b3:	83 cf 20             	or     $0x20,%edi
f01002b6:	8b 15 70 d0 17 f0    	mov    0xf017d070,%edx
f01002bc:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01002c0:	eb 77                	jmp    f0100339 <cons_putc+0x162>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002c2:	66 83 05 74 d0 17 f0 	addw   $0x50,0xf017d074
f01002c9:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002ca:	0f b7 05 74 d0 17 f0 	movzwl 0xf017d074,%eax
f01002d1:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002d7:	c1 e8 16             	shr    $0x16,%eax
f01002da:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002dd:	c1 e0 04             	shl    $0x4,%eax
f01002e0:	66 a3 74 d0 17 f0    	mov    %ax,0xf017d074
f01002e6:	eb 51                	jmp    f0100339 <cons_putc+0x162>
		break;
	case '\t':
		cons_putc(' ');
f01002e8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ed:	e8 e5 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f01002f2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002f7:	e8 db fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f01002fc:	b8 20 00 00 00       	mov    $0x20,%eax
f0100301:	e8 d1 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f0100306:	b8 20 00 00 00       	mov    $0x20,%eax
f010030b:	e8 c7 fe ff ff       	call   f01001d7 <cons_putc>
		cons_putc(' ');
f0100310:	b8 20 00 00 00       	mov    $0x20,%eax
f0100315:	e8 bd fe ff ff       	call   f01001d7 <cons_putc>
f010031a:	eb 1d                	jmp    f0100339 <cons_putc+0x162>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010031c:	0f b7 05 74 d0 17 f0 	movzwl 0xf017d074,%eax
f0100323:	0f b7 c8             	movzwl %ax,%ecx
f0100326:	8b 15 70 d0 17 f0    	mov    0xf017d070,%edx
f010032c:	66 89 3c 4a          	mov    %di,(%edx,%ecx,2)
f0100330:	83 c0 01             	add    $0x1,%eax
f0100333:	66 a3 74 d0 17 f0    	mov    %ax,0xf017d074
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100339:	66 81 3d 74 d0 17 f0 	cmpw   $0x7cf,0xf017d074
f0100340:	cf 07 
f0100342:	76 42                	jbe    f0100386 <cons_putc+0x1af>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100344:	a1 70 d0 17 f0       	mov    0xf017d070,%eax
f0100349:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f0100350:	00 
f0100351:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100357:	89 54 24 04          	mov    %edx,0x4(%esp)
f010035b:	89 04 24             	mov    %eax,(%esp)
f010035e:	e8 09 44 00 00       	call   f010476c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100363:	8b 15 70 d0 17 f0    	mov    0xf017d070,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100369:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010036e:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100374:	83 c0 01             	add    $0x1,%eax
f0100377:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010037c:	75 f0                	jne    f010036e <cons_putc+0x197>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010037e:	66 83 2d 74 d0 17 f0 	subw   $0x50,0xf017d074
f0100385:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100386:	8b 0d 6c d0 17 f0    	mov    0xf017d06c,%ecx
f010038c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100391:	89 ca                	mov    %ecx,%edx
f0100393:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100394:	0f b7 35 74 d0 17 f0 	movzwl 0xf017d074,%esi
f010039b:	8d 59 01             	lea    0x1(%ecx),%ebx
f010039e:	89 f0                	mov    %esi,%eax
f01003a0:	66 c1 e8 08          	shr    $0x8,%ax
f01003a4:	89 da                	mov    %ebx,%edx
f01003a6:	ee                   	out    %al,(%dx)
f01003a7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003ac:	89 ca                	mov    %ecx,%edx
f01003ae:	ee                   	out    %al,(%dx)
f01003af:	89 f0                	mov    %esi,%eax
f01003b1:	89 da                	mov    %ebx,%edx
f01003b3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003b4:	83 c4 2c             	add    $0x2c,%esp
f01003b7:	5b                   	pop    %ebx
f01003b8:	5e                   	pop    %esi
f01003b9:	5f                   	pop    %edi
f01003ba:	5d                   	pop    %ebp
f01003bb:	c3                   	ret    

f01003bc <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003bc:	55                   	push   %ebp
f01003bd:	89 e5                	mov    %esp,%ebp
f01003bf:	53                   	push   %ebx
f01003c0:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c3:	ba 64 00 00 00       	mov    $0x64,%edx
f01003c8:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c9:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003ce:	a8 01                	test   $0x1,%al
f01003d0:	0f 84 de 00 00 00    	je     f01004b4 <kbd_proc_data+0xf8>
f01003d6:	b2 60                	mov    $0x60,%dl
f01003d8:	ec                   	in     (%dx),%al
f01003d9:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003db:	3c e0                	cmp    $0xe0,%al
f01003dd:	75 11                	jne    f01003f0 <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003df:	83 0d 68 d0 17 f0 40 	orl    $0x40,0xf017d068
		return 0;
f01003e6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003eb:	e9 c4 00 00 00       	jmp    f01004b4 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003f0:	84 c0                	test   %al,%al
f01003f2:	79 37                	jns    f010042b <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003f4:	8b 0d 68 d0 17 f0    	mov    0xf017d068,%ecx
f01003fa:	89 cb                	mov    %ecx,%ebx
f01003fc:	83 e3 40             	and    $0x40,%ebx
f01003ff:	83 e0 7f             	and    $0x7f,%eax
f0100402:	85 db                	test   %ebx,%ebx
f0100404:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100407:	0f b6 d2             	movzbl %dl,%edx
f010040a:	0f b6 82 a0 4c 10 f0 	movzbl -0xfefb360(%edx),%eax
f0100411:	83 c8 40             	or     $0x40,%eax
f0100414:	0f b6 c0             	movzbl %al,%eax
f0100417:	f7 d0                	not    %eax
f0100419:	21 c1                	and    %eax,%ecx
f010041b:	89 0d 68 d0 17 f0    	mov    %ecx,0xf017d068
		return 0;
f0100421:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100426:	e9 89 00 00 00       	jmp    f01004b4 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f010042b:	8b 0d 68 d0 17 f0    	mov    0xf017d068,%ecx
f0100431:	f6 c1 40             	test   $0x40,%cl
f0100434:	74 0e                	je     f0100444 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100436:	89 c2                	mov    %eax,%edx
f0100438:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f010043b:	83 e1 bf             	and    $0xffffffbf,%ecx
f010043e:	89 0d 68 d0 17 f0    	mov    %ecx,0xf017d068
	}

	shift |= shiftcode[data];
f0100444:	0f b6 d2             	movzbl %dl,%edx
f0100447:	0f b6 82 a0 4c 10 f0 	movzbl -0xfefb360(%edx),%eax
f010044e:	0b 05 68 d0 17 f0    	or     0xf017d068,%eax
	shift ^= togglecode[data];
f0100454:	0f b6 8a a0 4d 10 f0 	movzbl -0xfefb260(%edx),%ecx
f010045b:	31 c8                	xor    %ecx,%eax
f010045d:	a3 68 d0 17 f0       	mov    %eax,0xf017d068

	c = charcode[shift & (CTL | SHIFT)][data];
f0100462:	89 c1                	mov    %eax,%ecx
f0100464:	83 e1 03             	and    $0x3,%ecx
f0100467:	8b 0c 8d a0 4e 10 f0 	mov    -0xfefb160(,%ecx,4),%ecx
f010046e:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100472:	a8 08                	test   $0x8,%al
f0100474:	74 19                	je     f010048f <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100476:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100479:	83 fa 19             	cmp    $0x19,%edx
f010047c:	77 05                	ja     f0100483 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010047e:	83 eb 20             	sub    $0x20,%ebx
f0100481:	eb 0c                	jmp    f010048f <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100483:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100486:	8d 53 20             	lea    0x20(%ebx),%edx
f0100489:	83 f9 19             	cmp    $0x19,%ecx
f010048c:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010048f:	f7 d0                	not    %eax
f0100491:	a8 06                	test   $0x6,%al
f0100493:	75 1f                	jne    f01004b4 <kbd_proc_data+0xf8>
f0100495:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010049b:	75 17                	jne    f01004b4 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010049d:	c7 04 24 6d 4c 10 f0 	movl   $0xf0104c6d,(%esp)
f01004a4:	e8 a1 32 00 00       	call   f010374a <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004a9:	ba 92 00 00 00       	mov    $0x92,%edx
f01004ae:	b8 03 00 00 00       	mov    $0x3,%eax
f01004b3:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004b4:	89 d8                	mov    %ebx,%eax
f01004b6:	83 c4 14             	add    $0x14,%esp
f01004b9:	5b                   	pop    %ebx
f01004ba:	5d                   	pop    %ebp
f01004bb:	c3                   	ret    

f01004bc <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01004bc:	55                   	push   %ebp
f01004bd:	89 e5                	mov    %esp,%ebp
f01004bf:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004c2:	83 3d 40 ce 17 f0 00 	cmpl   $0x0,0xf017ce40
f01004c9:	74 0a                	je     f01004d5 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004cb:	b8 7e 01 10 f0       	mov    $0xf010017e,%eax
f01004d0:	e8 c5 fc ff ff       	call   f010019a <cons_intr>
}
f01004d5:	c9                   	leave  
f01004d6:	c3                   	ret    

f01004d7 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004d7:	55                   	push   %ebp
f01004d8:	89 e5                	mov    %esp,%ebp
f01004da:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004dd:	b8 bc 03 10 f0       	mov    $0xf01003bc,%eax
f01004e2:	e8 b3 fc ff ff       	call   f010019a <cons_intr>
}
f01004e7:	c9                   	leave  
f01004e8:	c3                   	ret    

f01004e9 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004e9:	55                   	push   %ebp
f01004ea:	89 e5                	mov    %esp,%ebp
f01004ec:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004ef:	e8 c8 ff ff ff       	call   f01004bc <serial_intr>
	kbd_intr();
f01004f4:	e8 de ff ff ff       	call   f01004d7 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004f9:	8b 15 60 d0 17 f0    	mov    0xf017d060,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004ff:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100504:	3b 15 64 d0 17 f0    	cmp    0xf017d064,%edx
f010050a:	74 1e                	je     f010052a <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f010050c:	0f b6 82 60 ce 17 f0 	movzbl -0xfe831a0(%edx),%eax
f0100513:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f0100516:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010051c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100521:	0f 44 d1             	cmove  %ecx,%edx
f0100524:	89 15 60 d0 17 f0    	mov    %edx,0xf017d060
		return c;
	}
	return 0;
}
f010052a:	c9                   	leave  
f010052b:	c3                   	ret    

f010052c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010052c:	55                   	push   %ebp
f010052d:	89 e5                	mov    %esp,%ebp
f010052f:	57                   	push   %edi
f0100530:	56                   	push   %esi
f0100531:	53                   	push   %ebx
f0100532:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100535:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010053c:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100543:	5a a5 
	if (*cp != 0xA55A) {
f0100545:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010054c:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100550:	74 11                	je     f0100563 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100552:	c7 05 6c d0 17 f0 b4 	movl   $0x3b4,0xf017d06c
f0100559:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010055c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100561:	eb 16                	jmp    f0100579 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100563:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010056a:	c7 05 6c d0 17 f0 d4 	movl   $0x3d4,0xf017d06c
f0100571:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100574:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f0100579:	8b 0d 6c d0 17 f0    	mov    0xf017d06c,%ecx
f010057f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100584:	89 ca                	mov    %ecx,%edx
f0100586:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100587:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010058a:	89 da                	mov    %ebx,%edx
f010058c:	ec                   	in     (%dx),%al
f010058d:	0f b6 f8             	movzbl %al,%edi
f0100590:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100593:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100598:	89 ca                	mov    %ecx,%edx
f010059a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010059b:	89 da                	mov    %ebx,%edx
f010059d:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f010059e:	89 35 70 d0 17 f0    	mov    %esi,0xf017d070
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005a4:	0f b6 d8             	movzbl %al,%ebx
f01005a7:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005a9:	66 89 3d 74 d0 17 f0 	mov    %di,0xf017d074
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005b0:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01005ba:	89 da                	mov    %ebx,%edx
f01005bc:	ee                   	out    %al,(%dx)
f01005bd:	b2 fb                	mov    $0xfb,%dl
f01005bf:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005c4:	ee                   	out    %al,(%dx)
f01005c5:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005ca:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005cf:	89 ca                	mov    %ecx,%edx
f01005d1:	ee                   	out    %al,(%dx)
f01005d2:	b2 f9                	mov    $0xf9,%dl
f01005d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005d9:	ee                   	out    %al,(%dx)
f01005da:	b2 fb                	mov    $0xfb,%dl
f01005dc:	b8 03 00 00 00       	mov    $0x3,%eax
f01005e1:	ee                   	out    %al,(%dx)
f01005e2:	b2 fc                	mov    $0xfc,%dl
f01005e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e9:	ee                   	out    %al,(%dx)
f01005ea:	b2 f9                	mov    $0xf9,%dl
f01005ec:	b8 01 00 00 00       	mov    $0x1,%eax
f01005f1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005f2:	b2 fd                	mov    $0xfd,%dl
f01005f4:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005f5:	3c ff                	cmp    $0xff,%al
f01005f7:	0f 95 c0             	setne  %al
f01005fa:	0f b6 c0             	movzbl %al,%eax
f01005fd:	89 c6                	mov    %eax,%esi
f01005ff:	a3 40 ce 17 f0       	mov    %eax,0xf017ce40
f0100604:	89 da                	mov    %ebx,%edx
f0100606:	ec                   	in     (%dx),%al
f0100607:	89 ca                	mov    %ecx,%edx
f0100609:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010060a:	85 f6                	test   %esi,%esi
f010060c:	75 0c                	jne    f010061a <cons_init+0xee>
		cprintf("Serial port does not exist!\n");
f010060e:	c7 04 24 79 4c 10 f0 	movl   $0xf0104c79,(%esp)
f0100615:	e8 30 31 00 00       	call   f010374a <cprintf>
}
f010061a:	83 c4 1c             	add    $0x1c,%esp
f010061d:	5b                   	pop    %ebx
f010061e:	5e                   	pop    %esi
f010061f:	5f                   	pop    %edi
f0100620:	5d                   	pop    %ebp
f0100621:	c3                   	ret    

f0100622 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100622:	55                   	push   %ebp
f0100623:	89 e5                	mov    %esp,%ebp
f0100625:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100628:	8b 45 08             	mov    0x8(%ebp),%eax
f010062b:	e8 a7 fb ff ff       	call   f01001d7 <cons_putc>
}
f0100630:	c9                   	leave  
f0100631:	c3                   	ret    

f0100632 <getchar>:

int
getchar(void)
{
f0100632:	55                   	push   %ebp
f0100633:	89 e5                	mov    %esp,%ebp
f0100635:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100638:	e8 ac fe ff ff       	call   f01004e9 <cons_getc>
f010063d:	85 c0                	test   %eax,%eax
f010063f:	74 f7                	je     f0100638 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100641:	c9                   	leave  
f0100642:	c3                   	ret    

f0100643 <iscons>:

int
iscons(int fdnum)
{
f0100643:	55                   	push   %ebp
f0100644:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100646:	b8 01 00 00 00       	mov    $0x1,%eax
f010064b:	5d                   	pop    %ebp
f010064c:	c3                   	ret    
f010064d:	00 00                	add    %al,(%eax)
	...

f0100650 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100650:	55                   	push   %ebp
f0100651:	89 e5                	mov    %esp,%ebp
f0100653:	83 ec 18             	sub    $0x18,%esp
	extern char entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100656:	c7 04 24 b0 4e 10 f0 	movl   $0xf0104eb0,(%esp)
f010065d:	e8 e8 30 00 00       	call   f010374a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100662:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100669:	00 
f010066a:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100671:	f0 
f0100672:	c7 04 24 70 4f 10 f0 	movl   $0xf0104f70,(%esp)
f0100679:	e8 cc 30 00 00       	call   f010374a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010067e:	c7 44 24 08 05 4c 10 	movl   $0x104c05,0x8(%esp)
f0100685:	00 
f0100686:	c7 44 24 04 05 4c 10 	movl   $0xf0104c05,0x4(%esp)
f010068d:	f0 
f010068e:	c7 04 24 94 4f 10 f0 	movl   $0xf0104f94,(%esp)
f0100695:	e8 b0 30 00 00       	call   f010374a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010069a:	c7 44 24 08 33 ce 17 	movl   $0x17ce33,0x8(%esp)
f01006a1:	00 
f01006a2:	c7 44 24 04 33 ce 17 	movl   $0xf017ce33,0x4(%esp)
f01006a9:	f0 
f01006aa:	c7 04 24 b8 4f 10 f0 	movl   $0xf0104fb8,(%esp)
f01006b1:	e8 94 30 00 00       	call   f010374a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006b6:	c7 44 24 08 30 dd 17 	movl   $0x17dd30,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 30 dd 17 	movl   $0xf017dd30,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 dc 4f 10 f0 	movl   $0xf0104fdc,(%esp)
f01006cd:	e8 78 30 00 00       	call   f010374a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-entry+1023)/1024);
f01006d2:	b8 2f e1 17 f0       	mov    $0xf017e12f,%eax
f01006d7:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006dc:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006e2:	85 c0                	test   %eax,%eax
f01006e4:	0f 48 c2             	cmovs  %edx,%eax
f01006e7:	c1 f8 0a             	sar    $0xa,%eax
f01006ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006ee:	c7 04 24 00 50 10 f0 	movl   $0xf0105000,(%esp)
f01006f5:	e8 50 30 00 00       	call   f010374a <cprintf>
		(end-entry+1023)/1024);
	return 0;
}
f01006fa:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ff:	c9                   	leave  
f0100700:	c3                   	ret    

f0100701 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100701:	55                   	push   %ebp
f0100702:	89 e5                	mov    %esp,%ebp
f0100704:	53                   	push   %ebx
f0100705:	83 ec 14             	sub    $0x14,%esp
f0100708:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010070d:	8b 83 04 51 10 f0    	mov    -0xfefaefc(%ebx),%eax
f0100713:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100717:	8b 83 00 51 10 f0    	mov    -0xfefaf00(%ebx),%eax
f010071d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100721:	c7 04 24 c9 4e 10 f0 	movl   $0xf0104ec9,(%esp)
f0100728:	e8 1d 30 00 00       	call   f010374a <cprintf>
f010072d:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100730:	83 fb 24             	cmp    $0x24,%ebx
f0100733:	75 d8                	jne    f010070d <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f0100735:	b8 00 00 00 00       	mov    $0x0,%eax
f010073a:	83 c4 14             	add    $0x14,%esp
f010073d:	5b                   	pop    %ebx
f010073e:	5d                   	pop    %ebp
f010073f:	c3                   	ret    

f0100740 <mon_backtrace>:
}


int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100740:	55                   	push   %ebp
f0100741:	89 e5                	mov    %esp,%ebp
f0100743:	57                   	push   %edi
f0100744:	56                   	push   %esi
f0100745:	53                   	push   %ebx
f0100746:	83 ec 5c             	sub    $0x5c,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100749:	89 eb                	mov    %ebp,%ebx
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();
f010074b:	89 de                	mov    %ebx,%esi

    cprintf ("Stack backtrace:\n");
f010074d:	c7 04 24 d2 4e 10 f0 	movl   $0xf0104ed2,(%esp)
f0100754:	e8 f1 2f 00 00       	call   f010374a <cprintf>
    while (ebp != 0) {
f0100759:	85 db                	test   %ebx,%ebx
f010075b:	0f 84 9a 00 00 00    	je     f01007fb <mon_backtrace+0xbb>
        
        eip = (uint32_t*) ebp[1];
f0100761:	8b 5e 04             	mov    0x4(%esi),%ebx

        arg0 = ebp[2];
f0100764:	8b 46 08             	mov    0x8(%esi),%eax
f0100767:	89 45 c4             	mov    %eax,-0x3c(%ebp)
        arg1 = ebp[3];
f010076a:	8b 46 0c             	mov    0xc(%esi),%eax
f010076d:	89 45 c0             	mov    %eax,-0x40(%ebp)
        arg2 = ebp[4];
f0100770:	8b 46 10             	mov    0x10(%esi),%eax
f0100773:	89 45 bc             	mov    %eax,-0x44(%ebp)
        arg3 = ebp[5];
f0100776:	8b 46 14             	mov    0x14(%esi),%eax
f0100779:	89 45 b8             	mov    %eax,-0x48(%ebp)
        arg4 = ebp[6];
f010077c:	8b 7e 18             	mov    0x18(%esi),%edi
	
	// Your code here.
    uint32_t *ebp, *eip;
    uint32_t arg0, arg1, arg2, arg3, arg4;
    struct Eipdebuginfo debuginfo;
    struct Eipdebuginfo *eipinfo = &debuginfo;
f010077f:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100782:	89 44 24 04          	mov    %eax,0x4(%esp)
        arg1 = ebp[3];
        arg2 = ebp[4];
        arg3 = ebp[5];
        arg4 = ebp[6];
        
        debuginfo_eip ((uintptr_t) eip, eipinfo);
f0100786:	89 1c 24             	mov    %ebx,(%esp)
f0100789:	e8 10 35 00 00       	call   f0103c9e <debuginfo_eip>

        cprintf ("  ebp %08x  eip %08x  args %08x %08x %08x %08x %08x\n", ebp, eip, arg0, arg1, arg2, arg3, arg4);
f010078e:	89 7c 24 1c          	mov    %edi,0x1c(%esp)
f0100792:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0100795:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100799:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010079c:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007a0:	8b 45 c0             	mov    -0x40(%ebp),%eax
f01007a3:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007a7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f01007aa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007ae:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01007b2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007b6:	c7 04 24 2c 50 10 f0 	movl   $0xf010502c,(%esp)
f01007bd:	e8 88 2f 00 00       	call   f010374a <cprintf>
        cprintf ("         %s:%d: %.*s+%d\n", 
f01007c2:	2b 5d e0             	sub    -0x20(%ebp),%ebx
f01007c5:	89 5c 24 14          	mov    %ebx,0x14(%esp)
f01007c9:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007cc:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01007d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007da:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007de:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007e1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007e5:	c7 04 24 e4 4e 10 f0 	movl   $0xf0104ee4,(%esp)
f01007ec:	e8 59 2f 00 00       	call   f010374a <cprintf>
            eipinfo->eip_line, 
            eipinfo->eip_fn_namelen, eipinfo->eip_fn_name,
            (uint32_t) eip - eipinfo->eip_fn_addr);


        ebp = (uint32_t*) ebp[0];
f01007f1:	8b 36                	mov    (%esi),%esi
    struct Eipdebuginfo *eipinfo = &debuginfo;

    ebp = (uint32_t*) read_ebp ();

    cprintf ("Stack backtrace:\n");
    while (ebp != 0) {
f01007f3:	85 f6                	test   %esi,%esi
f01007f5:	0f 85 66 ff ff ff    	jne    f0100761 <mon_backtrace+0x21>


        ebp = (uint32_t*) ebp[0];
    }
	return 0;
}
f01007fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100800:	83 c4 5c             	add    $0x5c,%esp
f0100803:	5b                   	pop    %ebx
f0100804:	5e                   	pop    %esi
f0100805:	5f                   	pop    %edi
f0100806:	5d                   	pop    %ebp
f0100807:	c3                   	ret    

f0100808 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100808:	55                   	push   %ebp
f0100809:	89 e5                	mov    %esp,%ebp
f010080b:	57                   	push   %edi
f010080c:	56                   	push   %esi
f010080d:	53                   	push   %ebx
f010080e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100811:	c7 04 24 64 50 10 f0 	movl   $0xf0105064,(%esp)
f0100818:	e8 2d 2f 00 00       	call   f010374a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010081d:	c7 04 24 88 50 10 f0 	movl   $0xf0105088,(%esp)
f0100824:	e8 21 2f 00 00       	call   f010374a <cprintf>

	if (tf != NULL)
f0100829:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010082d:	74 0b                	je     f010083a <monitor+0x32>
		print_trapframe(tf);
f010082f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100832:	89 04 24             	mov    %eax,(%esp)
f0100835:	e8 38 30 00 00       	call   f0103872 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f010083a:	c7 04 24 fd 4e 10 f0 	movl   $0xf0104efd,(%esp)
f0100841:	e8 1a 3c 00 00       	call   f0104460 <readline>
f0100846:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100848:	85 c0                	test   %eax,%eax
f010084a:	74 ee                	je     f010083a <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f010084c:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100853:	be 00 00 00 00       	mov    $0x0,%esi
f0100858:	eb 06                	jmp    f0100860 <monitor+0x58>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010085a:	c6 03 00             	movb   $0x0,(%ebx)
f010085d:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100860:	0f b6 03             	movzbl (%ebx),%eax
f0100863:	84 c0                	test   %al,%al
f0100865:	74 6a                	je     f01008d1 <monitor+0xc9>
f0100867:	0f be c0             	movsbl %al,%eax
f010086a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010086e:	c7 04 24 01 4f 10 f0 	movl   $0xf0104f01,(%esp)
f0100875:	e8 3c 3e 00 00       	call   f01046b6 <strchr>
f010087a:	85 c0                	test   %eax,%eax
f010087c:	75 dc                	jne    f010085a <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f010087e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100881:	74 4e                	je     f01008d1 <monitor+0xc9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100883:	83 fe 0f             	cmp    $0xf,%esi
f0100886:	75 16                	jne    f010089e <monitor+0x96>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100888:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010088f:	00 
f0100890:	c7 04 24 06 4f 10 f0 	movl   $0xf0104f06,(%esp)
f0100897:	e8 ae 2e 00 00       	call   f010374a <cprintf>
f010089c:	eb 9c                	jmp    f010083a <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f010089e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01008a2:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01008a5:	0f b6 03             	movzbl (%ebx),%eax
f01008a8:	84 c0                	test   %al,%al
f01008aa:	75 0c                	jne    f01008b8 <monitor+0xb0>
f01008ac:	eb b2                	jmp    f0100860 <monitor+0x58>
			buf++;
f01008ae:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01008b1:	0f b6 03             	movzbl (%ebx),%eax
f01008b4:	84 c0                	test   %al,%al
f01008b6:	74 a8                	je     f0100860 <monitor+0x58>
f01008b8:	0f be c0             	movsbl %al,%eax
f01008bb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008bf:	c7 04 24 01 4f 10 f0 	movl   $0xf0104f01,(%esp)
f01008c6:	e8 eb 3d 00 00       	call   f01046b6 <strchr>
f01008cb:	85 c0                	test   %eax,%eax
f01008cd:	74 df                	je     f01008ae <monitor+0xa6>
f01008cf:	eb 8f                	jmp    f0100860 <monitor+0x58>
			buf++;
	}
	argv[argc] = 0;
f01008d1:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01008d8:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01008d9:	85 f6                	test   %esi,%esi
f01008db:	0f 84 59 ff ff ff    	je     f010083a <monitor+0x32>
f01008e1:	bb 00 51 10 f0       	mov    $0xf0105100,%ebx
f01008e6:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01008eb:	8b 03                	mov    (%ebx),%eax
f01008ed:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008f4:	89 04 24             	mov    %eax,(%esp)
f01008f7:	e8 3f 3d 00 00       	call   f010463b <strcmp>
f01008fc:	85 c0                	test   %eax,%eax
f01008fe:	75 24                	jne    f0100924 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100900:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100903:	8b 55 08             	mov    0x8(%ebp),%edx
f0100906:	89 54 24 08          	mov    %edx,0x8(%esp)
f010090a:	8d 55 a8             	lea    -0x58(%ebp),%edx
f010090d:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100911:	89 34 24             	mov    %esi,(%esp)
f0100914:	ff 14 85 08 51 10 f0 	call   *-0xfefaef8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010091b:	85 c0                	test   %eax,%eax
f010091d:	78 28                	js     f0100947 <monitor+0x13f>
f010091f:	e9 16 ff ff ff       	jmp    f010083a <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100924:	83 c7 01             	add    $0x1,%edi
f0100927:	83 c3 0c             	add    $0xc,%ebx
f010092a:	83 ff 03             	cmp    $0x3,%edi
f010092d:	75 bc                	jne    f01008eb <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f010092f:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100932:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100936:	c7 04 24 23 4f 10 f0 	movl   $0xf0104f23,(%esp)
f010093d:	e8 08 2e 00 00       	call   f010374a <cprintf>
f0100942:	e9 f3 fe ff ff       	jmp    f010083a <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100947:	83 c4 5c             	add    $0x5c,%esp
f010094a:	5b                   	pop    %ebx
f010094b:	5e                   	pop    %esi
f010094c:	5f                   	pop    %edi
f010094d:	5d                   	pop    %ebp
f010094e:	c3                   	ret    

f010094f <read_eip>:
// return EIP of caller.
// does not work if inlined.
// putting at the end of the file seems to prevent inlining.
unsigned
read_eip()
{
f010094f:	55                   	push   %ebp
f0100950:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f0100952:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f0100955:	5d                   	pop    %ebp
f0100956:	c3                   	ret    
	...

f0100958 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100958:	55                   	push   %ebp
f0100959:	89 e5                	mov    %esp,%ebp
f010095b:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010095e:	89 d1                	mov    %edx,%ecx
f0100960:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100963:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100966:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010096b:	f6 c1 01             	test   $0x1,%cl
f010096e:	74 57                	je     f01009c7 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100970:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100976:	89 c8                	mov    %ecx,%eax
f0100978:	c1 e8 0c             	shr    $0xc,%eax
f010097b:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f0100981:	72 20                	jb     f01009a3 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100983:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100987:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f010098e:	f0 
f010098f:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0100996:	00 
f0100997:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010099e:	e8 1b f7 ff ff       	call   f01000be <_panic>
	if (!(p[PTX(va)] & PTE_P))
f01009a3:	c1 ea 0c             	shr    $0xc,%edx
f01009a6:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01009ac:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f01009b3:	89 c2                	mov    %eax,%edx
f01009b5:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f01009b8:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01009bd:	85 d2                	test   %edx,%edx
f01009bf:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01009c4:	0f 44 c2             	cmove  %edx,%eax
}
f01009c7:	c9                   	leave  
f01009c8:	c3                   	ret    

f01009c9 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01009c9:	55                   	push   %ebp
f01009ca:	89 e5                	mov    %esp,%ebp
f01009cc:	83 ec 18             	sub    $0x18,%esp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01009cf:	83 3d 7c d0 17 f0 00 	cmpl   $0x0,0xf017d07c
f01009d6:	75 11                	jne    f01009e9 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01009d8:	ba 2f ed 17 f0       	mov    $0xf017ed2f,%edx
f01009dd:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01009e3:	89 15 7c d0 17 f0    	mov    %edx,0xf017d07c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
    assert((uint32_t)nextfree % PGSIZE == 0);
f01009e9:	8b 15 7c d0 17 f0    	mov    0xf017d07c,%edx
f01009ef:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f01009f5:	74 24                	je     f0100a1b <boot_alloc+0x52>
f01009f7:	c7 44 24 0c 48 51 10 	movl   $0xf0105148,0xc(%esp)
f01009fe:	f0 
f01009ff:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100a06:	f0 
f0100a07:	c7 44 24 04 66 00 00 	movl   $0x66,0x4(%esp)
f0100a0e:	00 
f0100a0f:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100a16:	e8 a3 f6 ff ff       	call   f01000be <_panic>
    result = nextfree;
    nextfree += n;
    nextfree = ROUNDUP(nextfree, PGSIZE);
f0100a1b:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100a22:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100a27:	a3 7c d0 17 f0       	mov    %eax,0xf017d07c

	return result;
}
f0100a2c:	89 d0                	mov    %edx,%eax
f0100a2e:	c9                   	leave  
f0100a2f:	c3                   	ret    

f0100a30 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100a30:	55                   	push   %ebp
f0100a31:	89 e5                	mov    %esp,%ebp
f0100a33:	83 ec 18             	sub    $0x18,%esp
f0100a36:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100a39:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100a3c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 96 2c 00 00       	call   f01036dc <mc146818_read>
f0100a46:	89 c6                	mov    %eax,%esi
f0100a48:	83 c3 01             	add    $0x1,%ebx
f0100a4b:	89 1c 24             	mov    %ebx,(%esp)
f0100a4e:	e8 89 2c 00 00       	call   f01036dc <mc146818_read>
f0100a53:	c1 e0 08             	shl    $0x8,%eax
f0100a56:	09 f0                	or     %esi,%eax
}
f0100a58:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100a5b:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100a5e:	89 ec                	mov    %ebp,%esp
f0100a60:	5d                   	pop    %ebp
f0100a61:	c3                   	ret    

f0100a62 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100a62:	55                   	push   %ebp
f0100a63:	89 e5                	mov    %esp,%ebp
f0100a65:	57                   	push   %edi
f0100a66:	56                   	push   %esi
f0100a67:	53                   	push   %ebx
f0100a68:	83 ec 3c             	sub    $0x3c,%esp
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100a6b:	83 f8 01             	cmp    $0x1,%eax
f0100a6e:	19 f6                	sbb    %esi,%esi
f0100a70:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100a76:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100a79:	8b 1d 80 d0 17 f0    	mov    0xf017d080,%ebx
f0100a7f:	85 db                	test   %ebx,%ebx
f0100a81:	75 1c                	jne    f0100a9f <check_page_free_list+0x3d>
		panic("'page_free_list' is a null pointer!");
f0100a83:	c7 44 24 08 6c 51 10 	movl   $0xf010516c,0x8(%esp)
f0100a8a:	f0 
f0100a8b:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0100a92:	00 
f0100a93:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100a9a:	e8 1f f6 ff ff       	call   f01000be <_panic>

	if (only_low_memory) {
f0100a9f:	85 c0                	test   %eax,%eax
f0100aa1:	74 50                	je     f0100af3 <check_page_free_list+0x91>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
f0100aa3:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100aa6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100aa9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100aac:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aaf:	89 d8                	mov    %ebx,%eax
f0100ab1:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0100ab7:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100aba:	c1 e8 16             	shr    $0x16,%eax
f0100abd:	39 c6                	cmp    %eax,%esi
f0100abf:	0f 96 c0             	setbe  %al
f0100ac2:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100ac5:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100ac9:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100acb:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct Page *pp1, *pp2;
		struct Page **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100acf:	8b 1b                	mov    (%ebx),%ebx
f0100ad1:	85 db                	test   %ebx,%ebx
f0100ad3:	75 da                	jne    f0100aaf <check_page_free_list+0x4d>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100ad5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ad8:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100ade:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ae1:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100ae4:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ae6:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100ae9:	89 1d 80 d0 17 f0    	mov    %ebx,0xf017d080
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100aef:	85 db                	test   %ebx,%ebx
f0100af1:	74 67                	je     f0100b5a <check_page_free_list+0xf8>
f0100af3:	89 d8                	mov    %ebx,%eax
f0100af5:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0100afb:	c1 f8 03             	sar    $0x3,%eax
f0100afe:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100b01:	89 c2                	mov    %eax,%edx
f0100b03:	c1 ea 16             	shr    $0x16,%edx
f0100b06:	39 d6                	cmp    %edx,%esi
f0100b08:	76 4a                	jbe    f0100b54 <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b0a:	89 c2                	mov    %eax,%edx
f0100b0c:	c1 ea 0c             	shr    $0xc,%edx
f0100b0f:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0100b15:	72 20                	jb     f0100b37 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b17:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1b:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0100b22:	f0 
f0100b23:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100b2a:	00 
f0100b2b:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0100b32:	e8 87 f5 ff ff       	call   f01000be <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100b37:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100b3e:	00 
f0100b3f:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100b46:	00 
	return (void *)(pa + KERNBASE);
f0100b47:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100b4c:	89 04 24             	mov    %eax,(%esp)
f0100b4f:	e8 bd 3b 00 00       	call   f0104711 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100b54:	8b 1b                	mov    (%ebx),%ebx
f0100b56:	85 db                	test   %ebx,%ebx
f0100b58:	75 99                	jne    f0100af3 <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100b5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b5f:	e8 65 fe ff ff       	call   f01009c9 <boot_alloc>
f0100b64:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b67:	8b 15 80 d0 17 f0    	mov    0xf017d080,%edx
f0100b6d:	85 d2                	test   %edx,%edx
f0100b6f:	0f 84 f6 01 00 00    	je     f0100d6b <check_page_free_list+0x309>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100b75:	8b 1d 2c dd 17 f0    	mov    0xf017dd2c,%ebx
f0100b7b:	39 da                	cmp    %ebx,%edx
f0100b7d:	72 4d                	jb     f0100bcc <check_page_free_list+0x16a>
		assert(pp < pages + npages);
f0100b7f:	a1 24 dd 17 f0       	mov    0xf017dd24,%eax
f0100b84:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100b87:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100b8a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b8d:	39 c2                	cmp    %eax,%edx
f0100b8f:	73 64                	jae    f0100bf5 <check_page_free_list+0x193>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100b91:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100b94:	89 d0                	mov    %edx,%eax
f0100b96:	29 d8                	sub    %ebx,%eax
f0100b98:	a8 07                	test   $0x7,%al
f0100b9a:	0f 85 82 00 00 00    	jne    f0100c22 <check_page_free_list+0x1c0>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ba0:	c1 f8 03             	sar    $0x3,%eax
f0100ba3:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ba6:	85 c0                	test   %eax,%eax
f0100ba8:	0f 84 a2 00 00 00    	je     f0100c50 <check_page_free_list+0x1ee>
		assert(page2pa(pp) != IOPHYSMEM);
f0100bae:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100bb3:	0f 84 c2 00 00 00    	je     f0100c7b <check_page_free_list+0x219>
static void
check_page_free_list(bool only_low_memory)
{
	struct Page *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100bb9:	be 00 00 00 00       	mov    $0x0,%esi
f0100bbe:	bf 00 00 00 00       	mov    $0x0,%edi
f0100bc3:	e9 d7 00 00 00       	jmp    f0100c9f <check_page_free_list+0x23d>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bc8:	39 da                	cmp    %ebx,%edx
f0100bca:	73 24                	jae    f0100bf0 <check_page_free_list+0x18e>
f0100bcc:	c7 44 24 0c f0 58 10 	movl   $0xf01058f0,0xc(%esp)
f0100bd3:	f0 
f0100bd4:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100bdb:	f0 
f0100bdc:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0100be3:	00 
f0100be4:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100beb:	e8 ce f4 ff ff       	call   f01000be <_panic>
		assert(pp < pages + npages);
f0100bf0:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100bf3:	72 24                	jb     f0100c19 <check_page_free_list+0x1b7>
f0100bf5:	c7 44 24 0c fc 58 10 	movl   $0xf01058fc,0xc(%esp)
f0100bfc:	f0 
f0100bfd:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100c04:	f0 
f0100c05:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0100c0c:	00 
f0100c0d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100c14:	e8 a5 f4 ff ff       	call   f01000be <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c19:	89 d0                	mov    %edx,%eax
f0100c1b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100c1e:	a8 07                	test   $0x7,%al
f0100c20:	74 24                	je     f0100c46 <check_page_free_list+0x1e4>
f0100c22:	c7 44 24 0c 90 51 10 	movl   $0xf0105190,0xc(%esp)
f0100c29:	f0 
f0100c2a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100c31:	f0 
f0100c32:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0100c39:	00 
f0100c3a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100c41:	e8 78 f4 ff ff       	call   f01000be <_panic>
f0100c46:	c1 f8 03             	sar    $0x3,%eax
f0100c49:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100c4c:	85 c0                	test   %eax,%eax
f0100c4e:	75 24                	jne    f0100c74 <check_page_free_list+0x212>
f0100c50:	c7 44 24 0c 10 59 10 	movl   $0xf0105910,0xc(%esp)
f0100c57:	f0 
f0100c58:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100c5f:	f0 
f0100c60:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f0100c67:	00 
f0100c68:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100c6f:	e8 4a f4 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c74:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c79:	75 24                	jne    f0100c9f <check_page_free_list+0x23d>
f0100c7b:	c7 44 24 0c 21 59 10 	movl   $0xf0105921,0xc(%esp)
f0100c82:	f0 
f0100c83:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100c8a:	f0 
f0100c8b:	c7 44 24 04 95 02 00 	movl   $0x295,0x4(%esp)
f0100c92:	00 
f0100c93:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100c9a:	e8 1f f4 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100c9f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ca4:	75 24                	jne    f0100cca <check_page_free_list+0x268>
f0100ca6:	c7 44 24 0c c4 51 10 	movl   $0xf01051c4,0xc(%esp)
f0100cad:	f0 
f0100cae:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100cb5:	f0 
f0100cb6:	c7 44 24 04 96 02 00 	movl   $0x296,0x4(%esp)
f0100cbd:	00 
f0100cbe:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100cc5:	e8 f4 f3 ff ff       	call   f01000be <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cca:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100ccf:	75 24                	jne    f0100cf5 <check_page_free_list+0x293>
f0100cd1:	c7 44 24 0c 3a 59 10 	movl   $0xf010593a,0xc(%esp)
f0100cd8:	f0 
f0100cd9:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100ce0:	f0 
f0100ce1:	c7 44 24 04 97 02 00 	movl   $0x297,0x4(%esp)
f0100ce8:	00 
f0100ce9:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100cf0:	e8 c9 f3 ff ff       	call   f01000be <_panic>
f0100cf5:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100cf7:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100cfc:	76 57                	jbe    f0100d55 <check_page_free_list+0x2f3>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cfe:	c1 e8 0c             	shr    $0xc,%eax
f0100d01:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100d04:	77 20                	ja     f0100d26 <check_page_free_list+0x2c4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d06:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100d0a:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0100d11:	f0 
f0100d12:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100d19:	00 
f0100d1a:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0100d21:	e8 98 f3 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0100d26:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100d2c:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100d2f:	76 29                	jbe    f0100d5a <check_page_free_list+0x2f8>
f0100d31:	c7 44 24 0c e8 51 10 	movl   $0xf01051e8,0xc(%esp)
f0100d38:	f0 
f0100d39:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100d40:	f0 
f0100d41:	c7 44 24 04 98 02 00 	movl   $0x298,0x4(%esp)
f0100d48:	00 
f0100d49:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100d50:	e8 69 f3 ff ff       	call   f01000be <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d55:	83 c7 01             	add    $0x1,%edi
f0100d58:	eb 03                	jmp    f0100d5d <check_page_free_list+0x2fb>
		else
			++nfree_extmem;
f0100d5a:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d5d:	8b 12                	mov    (%edx),%edx
f0100d5f:	85 d2                	test   %edx,%edx
f0100d61:	0f 85 61 fe ff ff    	jne    f0100bc8 <check_page_free_list+0x166>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d67:	85 ff                	test   %edi,%edi
f0100d69:	7f 24                	jg     f0100d8f <check_page_free_list+0x32d>
f0100d6b:	c7 44 24 0c 54 59 10 	movl   $0xf0105954,0xc(%esp)
f0100d72:	f0 
f0100d73:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100d7a:	f0 
f0100d7b:	c7 44 24 04 a0 02 00 	movl   $0x2a0,0x4(%esp)
f0100d82:	00 
f0100d83:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100d8a:	e8 2f f3 ff ff       	call   f01000be <_panic>
	assert(nfree_extmem > 0);
f0100d8f:	85 f6                	test   %esi,%esi
f0100d91:	7f 24                	jg     f0100db7 <check_page_free_list+0x355>
f0100d93:	c7 44 24 0c 66 59 10 	movl   $0xf0105966,0xc(%esp)
f0100d9a:	f0 
f0100d9b:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100da2:	f0 
f0100da3:	c7 44 24 04 a1 02 00 	movl   $0x2a1,0x4(%esp)
f0100daa:	00 
f0100dab:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100db2:	e8 07 f3 ff ff       	call   f01000be <_panic>
}
f0100db7:	83 c4 3c             	add    $0x3c,%esp
f0100dba:	5b                   	pop    %ebx
f0100dbb:	5e                   	pop    %esi
f0100dbc:	5f                   	pop    %edi
f0100dbd:	5d                   	pop    %ebp
f0100dbe:	c3                   	ret    

f0100dbf <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100dbf:	55                   	push   %ebp
f0100dc0:	89 e5                	mov    %esp,%ebp
f0100dc2:	57                   	push   %edi
f0100dc3:	56                   	push   %esi
f0100dc4:	53                   	push   %ebx
f0100dc5:	83 ec 1c             	sub    $0x1c,%esp
	// free pages!
	size_t i;
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
f0100dc8:	c7 05 80 d0 17 f0 00 	movl   $0x0,0xf017d080
f0100dcf:	00 00 00 
    first_free_page = (char *) boot_alloc(0);
f0100dd2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd7:	e8 ed fb ff ff       	call   f01009c9 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ddc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100de1:	77 20                	ja     f0100e03 <page_init+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100de3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100de7:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0100dee:	f0 
f0100def:	c7 44 24 04 1d 01 00 	movl   $0x11d,0x4(%esp)
f0100df6:	00 
f0100df7:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100dfe:	e8 bb f2 ff ff       	call   f01000be <_panic>
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
f0100e03:	8b 15 2c dd 17 f0    	mov    0xf017dd2c,%edx
f0100e09:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
    for (i = 1; i < npages_basemem; i++) {
f0100e0f:	8b 15 78 d0 17 f0    	mov    0xf017d078,%edx
f0100e15:	83 fa 01             	cmp    $0x1,%edx
f0100e18:	76 37                	jbe    f0100e51 <page_init+0x92>
f0100e1a:	8b 3d 80 d0 17 f0    	mov    0xf017d080,%edi
f0100e20:	b9 01 00 00 00       	mov    $0x1,%ecx
        pages[i].pp_ref = 0;
f0100e25:	8d 1c cd 00 00 00 00 	lea    0x0(,%ecx,8),%ebx
f0100e2c:	8b 35 2c dd 17 f0    	mov    0xf017dd2c,%esi
f0100e32:	66 c7 44 1e 04 00 00 	movw   $0x0,0x4(%esi,%ebx,1)
		pages[i].pp_link = page_free_list;
f0100e39:	89 3c ce             	mov    %edi,(%esi,%ecx,8)
		page_free_list = &pages[i];
f0100e3c:	89 df                	mov    %ebx,%edi
f0100e3e:	03 3d 2c dd 17 f0    	add    0xf017dd2c,%edi
    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;

    pages[0].pp_ref = 1;
    for (i = 1; i < npages_basemem; i++) {
f0100e44:	83 c1 01             	add    $0x1,%ecx
f0100e47:	39 d1                	cmp    %edx,%ecx
f0100e49:	72 da                	jb     f0100e25 <page_init+0x66>
f0100e4b:	89 3d 80 d0 17 f0    	mov    %edi,0xf017d080
        pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);
f0100e51:	89 d1                	mov    %edx,%ecx
f0100e53:	c1 e1 0c             	shl    $0xc,%ecx
f0100e56:	81 f9 00 00 0a 00    	cmp    $0xa0000,%ecx
f0100e5c:	74 24                	je     f0100e82 <page_init+0xc3>
f0100e5e:	c7 44 24 0c 54 52 10 	movl   $0xf0105254,0xc(%esp)
f0100e65:	f0 
f0100e66:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0100e6d:	f0 
f0100e6e:	c7 44 24 04 26 01 00 	movl   $0x126,0x4(%esp)
f0100e75:	00 
f0100e76:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100e7d:	e8 3c f2 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100e82:	05 00 00 00 10       	add    $0x10000000,%eax
	char* first_free_page;
    int low_ppn; 

    page_free_list = NULL;
    first_free_page = (char *) boot_alloc(0);
    low_ppn = PADDR(first_free_page)/PGSIZE;
f0100e87:	c1 e8 0c             	shr    $0xc,%eax
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e8a:	39 d0                	cmp    %edx,%eax
f0100e8c:	76 14                	jbe    f0100ea2 <page_init+0xe3>
        pages[i].pp_ref = 1;
f0100e8e:	8b 0d 2c dd 17 f0    	mov    0xf017dd2c,%ecx
f0100e94:	66 c7 44 d1 04 01 00 	movw   $0x1,0x4(%ecx,%edx,8)
		page_free_list = &pages[i];
    }

    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
f0100e9b:	83 c2 01             	add    $0x1,%edx
f0100e9e:	39 d0                	cmp    %edx,%eax
f0100ea0:	77 f2                	ja     f0100e94 <page_init+0xd5>
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100ea2:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f0100ea8:	73 39                	jae    f0100ee3 <page_init+0x124>
f0100eaa:	8b 1d 80 d0 17 f0    	mov    0xf017d080,%ebx
f0100eb0:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100eb7:	8b 0d 2c dd 17 f0    	mov    0xf017dd2c,%ecx
f0100ebd:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = page_free_list;
f0100ec4:	89 1c 11             	mov    %ebx,(%ecx,%edx,1)
		page_free_list = &pages[i];
f0100ec7:	89 d3                	mov    %edx,%ebx
f0100ec9:	03 1d 2c dd 17 f0    	add    0xf017dd2c,%ebx
    assert(npages_basemem * PGSIZE == IOPHYSMEM);

    for (i = npages_basemem; i < low_ppn ;i++)
        pages[i].pp_ref = 1;

	for (i = low_ppn; i < npages; i++) {
f0100ecf:	83 c0 01             	add    $0x1,%eax
f0100ed2:	83 c2 08             	add    $0x8,%edx
f0100ed5:	39 05 24 dd 17 f0    	cmp    %eax,0xf017dd24
f0100edb:	77 da                	ja     f0100eb7 <page_init+0xf8>
f0100edd:	89 1d 80 d0 17 f0    	mov    %ebx,0xf017d080
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}

}
f0100ee3:	83 c4 1c             	add    $0x1c,%esp
f0100ee6:	5b                   	pop    %ebx
f0100ee7:	5e                   	pop    %esi
f0100ee8:	5f                   	pop    %edi
f0100ee9:	5d                   	pop    %ebp
f0100eea:	c3                   	ret    

f0100eeb <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct Page *
page_alloc(int alloc_flags)
{
f0100eeb:	55                   	push   %ebp
f0100eec:	89 e5                	mov    %esp,%ebp
f0100eee:	53                   	push   %ebx
f0100eef:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
    struct Page* pg;
    if (page_free_list == NULL)
f0100ef2:	8b 1d 80 d0 17 f0    	mov    0xf017d080,%ebx
f0100ef8:	85 db                	test   %ebx,%ebx
f0100efa:	74 65                	je     f0100f61 <page_alloc+0x76>
        return NULL;
    pg = page_free_list;
    page_free_list = page_free_list->pp_link;
f0100efc:	8b 03                	mov    (%ebx),%eax
f0100efe:	a3 80 d0 17 f0       	mov    %eax,0xf017d080

    if (alloc_flags & ALLOC_ZERO) {
f0100f03:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100f07:	74 58                	je     f0100f61 <page_alloc+0x76>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f09:	89 d8                	mov    %ebx,%eax
f0100f0b:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0100f11:	c1 f8 03             	sar    $0x3,%eax
f0100f14:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f17:	89 c2                	mov    %eax,%edx
f0100f19:	c1 ea 0c             	shr    $0xc,%edx
f0100f1c:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0100f22:	72 20                	jb     f0100f44 <page_alloc+0x59>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f24:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f28:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0100f2f:	f0 
f0100f30:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0100f37:	00 
f0100f38:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0100f3f:	e8 7a f1 ff ff       	call   f01000be <_panic>
        memset(page2kva(pg), 0, PGSIZE);
f0100f44:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f4b:	00 
f0100f4c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f53:	00 
	return (void *)(pa + KERNBASE);
f0100f54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100f59:	89 04 24             	mov    %eax,(%esp)
f0100f5c:	e8 b0 37 00 00       	call   f0104711 <memset>
    }
    return pg;
}
f0100f61:	89 d8                	mov    %ebx,%eax
f0100f63:	83 c4 14             	add    $0x14,%esp
f0100f66:	5b                   	pop    %ebx
f0100f67:	5d                   	pop    %ebp
f0100f68:	c3                   	ret    

f0100f69 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct Page *pp)
{
f0100f69:	55                   	push   %ebp
f0100f6a:	89 e5                	mov    %esp,%ebp
f0100f6c:	83 ec 18             	sub    $0x18,%esp
f0100f6f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
    if (pp->pp_ref != 0) {
f0100f72:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100f77:	74 20                	je     f0100f99 <page_free+0x30>
        panic("page_free: %p pp_ref error\n", pp);
f0100f79:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f7d:	c7 44 24 08 77 59 10 	movl   $0xf0105977,0x8(%esp)
f0100f84:	f0 
f0100f85:	c7 44 24 04 55 01 00 	movl   $0x155,0x4(%esp)
f0100f8c:	00 
f0100f8d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100f94:	e8 25 f1 ff ff       	call   f01000be <_panic>
    }

    pp->pp_link = page_free_list;
f0100f99:	8b 15 80 d0 17 f0    	mov    0xf017d080,%edx
f0100f9f:	89 10                	mov    %edx,(%eax)
    page_free_list = pp;
f0100fa1:	a3 80 d0 17 f0       	mov    %eax,0xf017d080
}
f0100fa6:	c9                   	leave  
f0100fa7:	c3                   	ret    

f0100fa8 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct Page* pp)
{
f0100fa8:	55                   	push   %ebp
f0100fa9:	89 e5                	mov    %esp,%ebp
f0100fab:	83 ec 18             	sub    $0x18,%esp
f0100fae:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100fb1:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100fb5:	83 ea 01             	sub    $0x1,%edx
f0100fb8:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100fbc:	66 85 d2             	test   %dx,%dx
f0100fbf:	75 08                	jne    f0100fc9 <page_decref+0x21>
		page_free(pp);
f0100fc1:	89 04 24             	mov    %eax,(%esp)
f0100fc4:	e8 a0 ff ff ff       	call   f0100f69 <page_free>
}
f0100fc9:	c9                   	leave  
f0100fca:	c3                   	ret    

f0100fcb <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100fcb:	55                   	push   %ebp
f0100fcc:	89 e5                	mov    %esp,%ebp
f0100fce:	56                   	push   %esi
f0100fcf:	53                   	push   %ebx
f0100fd0:	83 ec 10             	sub    $0x10,%esp
f0100fd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fd6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
    if (pgdir == NULL) {
f0100fd9:	85 c0                	test   %eax,%eax
f0100fdb:	75 1c                	jne    f0100ff9 <pgdir_walk+0x2e>
        panic("pgdir_walk: pgdir is null");
f0100fdd:	c7 44 24 08 93 59 10 	movl   $0xf0105993,0x8(%esp)
f0100fe4:	f0 
f0100fe5:	c7 44 24 04 82 01 00 	movl   $0x182,0x4(%esp)
f0100fec:	00 
f0100fed:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0100ff4:	e8 c5 f0 ff ff       	call   f01000be <_panic>
    }

    pde_t pde;
    pte_t* pt;

    pde = pgdir[PDX(va)];
f0100ff9:	89 f2                	mov    %esi,%edx
f0100ffb:	c1 ea 16             	shr    $0x16,%edx
f0100ffe:	8d 1c 90             	lea    (%eax,%edx,4),%ebx
f0101001:	8b 03                	mov    (%ebx),%eax

    if (pde & PTE_P) {
f0101003:	a8 01                	test   $0x1,%al
f0101005:	74 47                	je     f010104e <pgdir_walk+0x83>
        pt = KADDR(PTE_ADDR(pde));
f0101007:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010100c:	89 c2                	mov    %eax,%edx
f010100e:	c1 ea 0c             	shr    $0xc,%edx
f0101011:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0101017:	72 20                	jb     f0101039 <pgdir_walk+0x6e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101019:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010101d:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0101024:	f0 
f0101025:	c7 44 24 04 8b 01 00 	movl   $0x18b,0x4(%esp)
f010102c:	00 
f010102d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101034:	e8 85 f0 ff ff       	call   f01000be <_panic>
        return &pt[PTX(va)];
f0101039:	c1 ee 0a             	shr    $0xa,%esi
f010103c:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101042:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101049:	e9 85 00 00 00       	jmp    f01010d3 <pgdir_walk+0x108>
    }

    if (!create) {
f010104e:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101052:	74 73                	je     f01010c7 <pgdir_walk+0xfc>
        return NULL;
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
f0101054:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010105b:	e8 8b fe ff ff       	call   f0100eeb <page_alloc>
f0101060:	85 c0                	test   %eax,%eax
f0101062:	74 6a                	je     f01010ce <pgdir_walk+0x103>
        return NULL;
    pp->pp_ref++;
f0101064:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101069:	89 c2                	mov    %eax,%edx
f010106b:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0101071:	c1 fa 03             	sar    $0x3,%edx
f0101074:	c1 e2 0c             	shl    $0xc,%edx

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;
f0101077:	83 ca 07             	or     $0x7,%edx
f010107a:	89 13                	mov    %edx,(%ebx)
f010107c:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0101082:	c1 f8 03             	sar    $0x3,%eax
f0101085:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101088:	89 c2                	mov    %eax,%edx
f010108a:	c1 ea 0c             	shr    $0xc,%edx
f010108d:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0101093:	72 20                	jb     f01010b5 <pgdir_walk+0xea>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101095:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101099:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f01010a0:	f0 
f01010a1:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01010a8:	00 
f01010a9:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f01010b0:	e8 09 f0 ff ff       	call   f01000be <_panic>


	return &((pte_t*) page2kva(pp))[PTX(va)];
f01010b5:	c1 ee 0a             	shr    $0xa,%esi
f01010b8:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01010be:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01010c5:	eb 0c                	jmp    f01010d3 <pgdir_walk+0x108>
        pt = KADDR(PTE_ADDR(pde));
        return &pt[PTX(va)];
    }

    if (!create) {
        return NULL;
f01010c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010cc:	eb 05                	jmp    f01010d3 <pgdir_walk+0x108>
    }

    struct Page* pp;
    if ((pp = page_alloc(ALLOC_ZERO)) == NULL)
        return NULL;
f01010ce:	b8 00 00 00 00       	mov    $0x0,%eax

    pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;


	return &((pte_t*) page2kva(pp))[PTX(va)];
}
f01010d3:	83 c4 10             	add    $0x10,%esp
f01010d6:	5b                   	pop    %ebx
f01010d7:	5e                   	pop    %esi
f01010d8:	5d                   	pop    %ebp
f01010d9:	c3                   	ret    

f01010da <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01010da:	55                   	push   %ebp
f01010db:	89 e5                	mov    %esp,%ebp
f01010dd:	57                   	push   %edi
f01010de:	56                   	push   %esi
f01010df:	53                   	push   %ebx
f01010e0:	83 ec 2c             	sub    $0x2c,%esp
f01010e3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01010e6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01010e9:	89 cf                	mov    %ecx,%edi
f01010eb:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
    assert(size % PGSIZE == 0);
f01010ee:	f7 c1 ff 0f 00 00    	test   $0xfff,%ecx
f01010f4:	75 14                	jne    f010110a <boot_map_region+0x30>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01010f6:	89 d3                	mov    %edx,%ebx
        }

        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
f01010f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01010fb:	83 c8 01             	or     $0x1,%eax
f01010fe:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f0101101:	85 c9                	test   %ecx,%ecx
f0101103:	75 50                	jne    f0101155 <boot_map_region+0x7b>
f0101105:	e9 c0 00 00 00       	jmp    f01011ca <boot_map_region+0xf0>
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
    assert(size % PGSIZE == 0);
f010110a:	c7 44 24 0c ad 59 10 	movl   $0xf01059ad,0xc(%esp)
f0101111:	f0 
f0101112:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101119:	f0 
f010111a:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f0101121:	00 
f0101122:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101129:	e8 90 ef ff ff       	call   f01000be <_panic>
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f010112e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
        if (va < start) { //  need overflow check?
f0101134:	39 5d e0             	cmp    %ebx,-0x20(%ebp)
f0101137:	76 1c                	jbe    f0101155 <boot_map_region+0x7b>
            panic("overflow\n");
f0101139:	c7 44 24 08 c0 59 10 	movl   $0xf01059c0,0x8(%esp)
f0101140:	f0 
f0101141:	c7 44 24 04 b2 01 00 	movl   $0x1b2,0x4(%esp)
f0101148:	00 
f0101149:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101150:	e8 69 ef ff ff       	call   f01000be <_panic>
            break;
        }

        if ((pte = pgdir_walk(pgdir, (void*) va, 1)) == NULL) {
f0101155:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010115c:	00 
f010115d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101161:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101164:	89 04 24             	mov    %eax,(%esp)
f0101167:	e8 5f fe ff ff       	call   f0100fcb <pgdir_walk>
f010116c:	85 c0                	test   %eax,%eax
f010116e:	75 1c                	jne    f010118c <boot_map_region+0xb2>
            panic("fail create\n");
f0101170:	c7 44 24 08 ca 59 10 	movl   $0xf01059ca,0x8(%esp)
f0101177:	f0 
f0101178:	c7 44 24 04 b7 01 00 	movl   $0x1b7,0x4(%esp)
f010117f:	00 
f0101180:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101187:	e8 32 ef ff ff       	call   f01000be <_panic>
        }

        if (*pte & PTE_P) {
f010118c:	f6 00 01             	testb  $0x1,(%eax)
f010118f:	74 20                	je     f01011b1 <boot_map_region+0xd7>
            panic("remapping %p\n", va);
f0101191:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101195:	c7 44 24 08 d7 59 10 	movl   $0xf01059d7,0x8(%esp)
f010119c:	f0 
f010119d:	c7 44 24 04 bb 01 00 	movl   $0x1bb,0x4(%esp)
f01011a4:	00 
f01011a5:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01011ac:	e8 0d ef ff ff       	call   f01000be <_panic>
        }
        *pte = pa | perm | PTE_P;
f01011b1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01011b4:	09 f2                	or     %esi,%edx
f01011b6:	89 10                	mov    %edx,(%eax)
	// Fill this function in
    assert(size % PGSIZE == 0);
    uintptr_t start = va;
    pte_t* pte = NULL;

    for (; size > 0; va += PGSIZE, pa +=PGSIZE, size -=PGSIZE) {
f01011b8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01011be:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f01011c4:	0f 85 64 ff ff ff    	jne    f010112e <boot_map_region+0x54>
        if (*pte & PTE_P) {
            panic("remapping %p\n", va);
        }
        *pte = pa | perm | PTE_P;
    }
}
f01011ca:	83 c4 2c             	add    $0x2c,%esp
f01011cd:	5b                   	pop    %ebx
f01011ce:	5e                   	pop    %esi
f01011cf:	5f                   	pop    %edi
f01011d0:	5d                   	pop    %ebp
f01011d1:	c3                   	ret    

f01011d2 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct Page *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011d2:	55                   	push   %ebp
f01011d3:	89 e5                	mov    %esp,%ebp
f01011d5:	53                   	push   %ebx
f01011d6:	83 ec 14             	sub    $0x14,%esp
f01011d9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f01011dc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01011e3:	00 
f01011e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011eb:	8b 45 08             	mov    0x8(%ebp),%eax
f01011ee:	89 04 24             	mov    %eax,(%esp)
f01011f1:	e8 d5 fd ff ff       	call   f0100fcb <pgdir_walk>
f01011f6:	89 c2                	mov    %eax,%edx

    if (pte == NULL || !(*pte & PTE_P)) {
f01011f8:	85 c0                	test   %eax,%eax
f01011fa:	74 3e                	je     f010123a <page_lookup+0x68>
f01011fc:	8b 00                	mov    (%eax),%eax
f01011fe:	a8 01                	test   $0x1,%al
f0101200:	74 3f                	je     f0101241 <page_lookup+0x6f>
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101202:	c1 e8 0c             	shr    $0xc,%eax
f0101205:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f010120b:	72 1c                	jb     f0101229 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010120d:	c7 44 24 08 7c 52 10 	movl   $0xf010527c,0x8(%esp)
f0101214:	f0 
f0101215:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f010121c:	00 
f010121d:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0101224:	e8 95 ee ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f0101229:	c1 e0 03             	shl    $0x3,%eax
f010122c:	03 05 2c dd 17 f0    	add    0xf017dd2c,%eax
        return NULL;
    }
    
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
f0101232:	85 db                	test   %ebx,%ebx
f0101234:	74 10                	je     f0101246 <page_lookup+0x74>
        *pte_store = pte;
f0101236:	89 13                	mov    %edx,(%ebx)
f0101238:	eb 0c                	jmp    f0101246 <page_lookup+0x74>
{
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);

    if (pte == NULL || !(*pte & PTE_P)) {
        return NULL;
f010123a:	b8 00 00 00 00       	mov    $0x0,%eax
f010123f:	eb 05                	jmp    f0101246 <page_lookup+0x74>
f0101241:	b8 00 00 00 00       	mov    $0x0,%eax
    struct Page* pp = pa2page(PTE_ADDR(*pte));
    if (pte_store) {
        *pte_store = pte;
    }
	return pp;
}
f0101246:	83 c4 14             	add    $0x14,%esp
f0101249:	5b                   	pop    %ebx
f010124a:	5d                   	pop    %ebp
f010124b:	c3                   	ret    

f010124c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010124c:	55                   	push   %ebp
f010124d:	89 e5                	mov    %esp,%ebp
}

static __inline void 
invlpg(void *addr)
{ 
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010124f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101252:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101255:	5d                   	pop    %ebp
f0101256:	c3                   	ret    

f0101257 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101257:	55                   	push   %ebp
f0101258:	89 e5                	mov    %esp,%ebp
f010125a:	83 ec 28             	sub    $0x28,%esp
f010125d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101260:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101263:	8b 75 08             	mov    0x8(%ebp),%esi
f0101266:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
    pte_t* pte;
    struct Page* pp = page_lookup(pgdir, va, &pte);
f0101269:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010126c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101270:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101274:	89 34 24             	mov    %esi,(%esp)
f0101277:	e8 56 ff ff ff       	call   f01011d2 <page_lookup>

    if (pp) {
f010127c:	85 c0                	test   %eax,%eax
f010127e:	74 1d                	je     f010129d <page_remove+0x46>
        page_decref(pp);
f0101280:	89 04 24             	mov    %eax,(%esp)
f0101283:	e8 20 fd ff ff       	call   f0100fa8 <page_decref>
        *pte = 0;
f0101288:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010128b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
        tlb_invalidate(pgdir, va);
f0101291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101295:	89 34 24             	mov    %esi,(%esp)
f0101298:	e8 af ff ff ff       	call   f010124c <tlb_invalidate>
    }
}
f010129d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01012a0:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01012a3:	89 ec                	mov    %ebp,%esp
f01012a5:	5d                   	pop    %ebp
f01012a6:	c3                   	ret    

f01012a7 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct Page *pp, void *va, int perm)
{
f01012a7:	55                   	push   %ebp
f01012a8:	89 e5                	mov    %esp,%ebp
f01012aa:	83 ec 38             	sub    $0x38,%esp
f01012ad:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01012b0:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01012b3:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01012b6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012b9:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
    pte_t* pte = pgdir_walk(pgdir, va, 0);
f01012bc:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01012c3:	00 
f01012c4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01012cb:	89 04 24             	mov    %eax,(%esp)
f01012ce:	e8 f8 fc ff ff       	call   f0100fcb <pgdir_walk>
f01012d3:	89 c3                	mov    %eax,%ebx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01012d5:	a1 2c dd 17 f0       	mov    0xf017dd2c,%eax
f01012da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    physaddr_t ppa = page2pa(pp);

    if (pte != NULL) {
f01012dd:	85 db                	test   %ebx,%ebx
f01012df:	74 25                	je     f0101306 <page_insert+0x5f>
        if (*pte & PTE_P) 
f01012e1:	f6 03 01             	testb  $0x1,(%ebx)
f01012e4:	74 0f                	je     f01012f5 <page_insert+0x4e>
            page_remove(pgdir, va);
f01012e6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01012ea:	8b 45 08             	mov    0x8(%ebp),%eax
f01012ed:	89 04 24             	mov    %eax,(%esp)
f01012f0:	e8 62 ff ff ff       	call   f0101257 <page_remove>
        if (pp == page_free_list)
f01012f5:	3b 35 80 d0 17 f0    	cmp    0xf017d080,%esi
f01012fb:	75 26                	jne    f0101323 <page_insert+0x7c>
            page_free_list = page_free_list->pp_link;
f01012fd:	8b 06                	mov    (%esi),%eax
f01012ff:	a3 80 d0 17 f0       	mov    %eax,0xf017d080
f0101304:	eb 1d                	jmp    f0101323 <page_insert+0x7c>
    } else {
        pte = pgdir_walk(pgdir, va, 1);
f0101306:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010130d:	00 
f010130e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101312:	8b 45 08             	mov    0x8(%ebp),%eax
f0101315:	89 04 24             	mov    %eax,(%esp)
f0101318:	e8 ae fc ff ff       	call   f0100fcb <pgdir_walk>
f010131d:	89 c3                	mov    %eax,%ebx
        if (pte == NULL)
f010131f:	85 c0                	test   %eax,%eax
f0101321:	74 30                	je     f0101353 <page_insert+0xac>
            return -E_NO_MEM;
    }

    *pte = ppa | perm | PTE_P;
f0101323:	8b 55 14             	mov    0x14(%ebp),%edx
f0101326:	83 ca 01             	or     $0x1,%edx
f0101329:	89 f0                	mov    %esi,%eax
f010132b:	2b 45 e4             	sub    -0x1c(%ebp),%eax
f010132e:	c1 f8 03             	sar    $0x3,%eax
f0101331:	c1 e0 0c             	shl    $0xc,%eax
f0101334:	09 d0                	or     %edx,%eax
f0101336:	89 03                	mov    %eax,(%ebx)
    pp->pp_ref++;
f0101338:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
    tlb_invalidate(pgdir, va);
f010133d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101341:	8b 45 08             	mov    0x8(%ebp),%eax
f0101344:	89 04 24             	mov    %eax,(%esp)
f0101347:	e8 00 ff ff ff       	call   f010124c <tlb_invalidate>

	return 0;
f010134c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101351:	eb 05                	jmp    f0101358 <page_insert+0xb1>
        if (pp == page_free_list)
            page_free_list = page_free_list->pp_link;
    } else {
        pte = pgdir_walk(pgdir, va, 1);
        if (pte == NULL)
            return -E_NO_MEM;
f0101353:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
    *pte = ppa | perm | PTE_P;
    pp->pp_ref++;
    tlb_invalidate(pgdir, va);

	return 0;
}
f0101358:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010135b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010135e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101361:	89 ec                	mov    %ebp,%esp
f0101363:	5d                   	pop    %ebp
f0101364:	c3                   	ret    

f0101365 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101365:	55                   	push   %ebp
f0101366:	89 e5                	mov    %esp,%ebp
f0101368:	57                   	push   %edi
f0101369:	56                   	push   %esi
f010136a:	53                   	push   %ebx
f010136b:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010136e:	b8 15 00 00 00       	mov    $0x15,%eax
f0101373:	e8 b8 f6 ff ff       	call   f0100a30 <nvram_read>
f0101378:	c1 e0 0a             	shl    $0xa,%eax
f010137b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101381:	85 c0                	test   %eax,%eax
f0101383:	0f 48 c2             	cmovs  %edx,%eax
f0101386:	c1 f8 0c             	sar    $0xc,%eax
f0101389:	a3 78 d0 17 f0       	mov    %eax,0xf017d078
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010138e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101393:	e8 98 f6 ff ff       	call   f0100a30 <nvram_read>
f0101398:	c1 e0 0a             	shl    $0xa,%eax
f010139b:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01013a1:	85 c0                	test   %eax,%eax
f01013a3:	0f 48 c2             	cmovs  %edx,%eax
f01013a6:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01013a9:	85 c0                	test   %eax,%eax
f01013ab:	74 0e                	je     f01013bb <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01013ad:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01013b3:	89 15 24 dd 17 f0    	mov    %edx,0xf017dd24
f01013b9:	eb 0c                	jmp    f01013c7 <mem_init+0x62>
	else
		npages = npages_basemem;
f01013bb:	8b 15 78 d0 17 f0    	mov    0xf017d078,%edx
f01013c1:	89 15 24 dd 17 f0    	mov    %edx,0xf017dd24

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01013c7:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013ca:	c1 e8 0a             	shr    $0xa,%eax
f01013cd:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01013d1:	a1 78 d0 17 f0       	mov    0xf017d078,%eax
f01013d6:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013d9:	c1 e8 0a             	shr    $0xa,%eax
f01013dc:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01013e0:	a1 24 dd 17 f0       	mov    0xf017dd24,%eax
f01013e5:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013e8:	c1 e8 0a             	shr    $0xa,%eax
f01013eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013ef:	c7 04 24 9c 52 10 f0 	movl   $0xf010529c,(%esp)
f01013f6:	e8 4f 23 00 00       	call   f010374a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01013fb:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101400:	e8 c4 f5 ff ff       	call   f01009c9 <boot_alloc>
f0101405:	a3 28 dd 17 f0       	mov    %eax,0xf017dd28
	memset(kern_pgdir, 0, PGSIZE);
f010140a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101411:	00 
f0101412:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101419:	00 
f010141a:	89 04 24             	mov    %eax,(%esp)
f010141d:	e8 ef 32 00 00       	call   f0104711 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following two lines.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101422:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101427:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010142c:	77 20                	ja     f010144e <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010142e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101432:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0101439:	f0 
f010143a:	c7 44 24 04 8f 00 00 	movl   $0x8f,0x4(%esp)
f0101441:	00 
f0101442:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101449:	e8 70 ec ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010144e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101454:	83 ca 05             	or     $0x5,%edx
f0101457:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct Page's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct Page in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
    n = sizeof(struct Page) * npages;
f010145d:	8b 1d 24 dd 17 f0    	mov    0xf017dd24,%ebx
f0101463:	c1 e3 03             	shl    $0x3,%ebx
    pages = boot_alloc(n);
f0101466:	89 d8                	mov    %ebx,%eax
f0101468:	e8 5c f5 ff ff       	call   f01009c9 <boot_alloc>
f010146d:	a3 2c dd 17 f0       	mov    %eax,0xf017dd2c
    memset(pages, 0, n);
f0101472:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101476:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010147d:	00 
f010147e:	89 04 24             	mov    %eax,(%esp)
f0101481:	e8 8b 32 00 00       	call   f0104711 <memset>


	//////////////////////////////////////////////////////////////////////
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
    envs = boot_alloc(sizeof(struct Env) * NENV);
f0101486:	b8 00 80 01 00       	mov    $0x18000,%eax
f010148b:	e8 39 f5 ff ff       	call   f01009c9 <boot_alloc>
f0101490:	a3 88 d0 17 f0       	mov    %eax,0xf017d088
    memset(envs, 0, sizeof(struct Env) * NENV);
f0101495:	c7 44 24 08 00 80 01 	movl   $0x18000,0x8(%esp)
f010149c:	00 
f010149d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014a4:	00 
f01014a5:	89 04 24             	mov    %eax,(%esp)
f01014a8:	e8 64 32 00 00       	call   f0104711 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01014ad:	e8 0d f9 ff ff       	call   f0100dbf <page_init>

	check_page_free_list(1);
f01014b2:	b8 01 00 00 00       	mov    $0x1,%eax
f01014b7:	e8 a6 f5 ff ff       	call   f0100a62 <check_page_free_list>
	int nfree;
	struct Page *fl;
	char *c;
	int i;

	if (!pages)
f01014bc:	83 3d 2c dd 17 f0 00 	cmpl   $0x0,0xf017dd2c
f01014c3:	75 1c                	jne    f01014e1 <mem_init+0x17c>
		panic("'pages' is a null pointer!");
f01014c5:	c7 44 24 08 e5 59 10 	movl   $0xf01059e5,0x8(%esp)
f01014cc:	f0 
f01014cd:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f01014d4:	00 
f01014d5:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01014dc:	e8 dd eb ff ff       	call   f01000be <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014e1:	a1 80 d0 17 f0       	mov    0xf017d080,%eax
f01014e6:	bb 00 00 00 00       	mov    $0x0,%ebx
f01014eb:	85 c0                	test   %eax,%eax
f01014ed:	74 09                	je     f01014f8 <mem_init+0x193>
		++nfree;
f01014ef:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014f2:	8b 00                	mov    (%eax),%eax
f01014f4:	85 c0                	test   %eax,%eax
f01014f6:	75 f7                	jne    f01014ef <mem_init+0x18a>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01014f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ff:	e8 e7 f9 ff ff       	call   f0100eeb <page_alloc>
f0101504:	89 c6                	mov    %eax,%esi
f0101506:	85 c0                	test   %eax,%eax
f0101508:	75 24                	jne    f010152e <mem_init+0x1c9>
f010150a:	c7 44 24 0c 00 5a 10 	movl   $0xf0105a00,0xc(%esp)
f0101511:	f0 
f0101512:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101519:	f0 
f010151a:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0101521:	00 
f0101522:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101529:	e8 90 eb ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010152e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101535:	e8 b1 f9 ff ff       	call   f0100eeb <page_alloc>
f010153a:	89 c7                	mov    %eax,%edi
f010153c:	85 c0                	test   %eax,%eax
f010153e:	75 24                	jne    f0101564 <mem_init+0x1ff>
f0101540:	c7 44 24 0c 16 5a 10 	movl   $0xf0105a16,0xc(%esp)
f0101547:	f0 
f0101548:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010154f:	f0 
f0101550:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101557:	00 
f0101558:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010155f:	e8 5a eb ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101564:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010156b:	e8 7b f9 ff ff       	call   f0100eeb <page_alloc>
f0101570:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101573:	85 c0                	test   %eax,%eax
f0101575:	75 24                	jne    f010159b <mem_init+0x236>
f0101577:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f010157e:	f0 
f010157f:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101586:	f0 
f0101587:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f010158e:	00 
f010158f:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101596:	e8 23 eb ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010159b:	39 fe                	cmp    %edi,%esi
f010159d:	75 24                	jne    f01015c3 <mem_init+0x25e>
f010159f:	c7 44 24 0c 42 5a 10 	movl   $0xf0105a42,0xc(%esp)
f01015a6:	f0 
f01015a7:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01015ae:	f0 
f01015af:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f01015b6:	00 
f01015b7:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01015be:	e8 fb ea ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015c3:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015c6:	74 05                	je     f01015cd <mem_init+0x268>
f01015c8:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01015cb:	75 24                	jne    f01015f1 <mem_init+0x28c>
f01015cd:	c7 44 24 0c d8 52 10 	movl   $0xf01052d8,0xc(%esp)
f01015d4:	f0 
f01015d5:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01015dc:	f0 
f01015dd:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f01015e4:	00 
f01015e5:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01015ec:	e8 cd ea ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01015f1:	8b 15 2c dd 17 f0    	mov    0xf017dd2c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01015f7:	a1 24 dd 17 f0       	mov    0xf017dd24,%eax
f01015fc:	c1 e0 0c             	shl    $0xc,%eax
f01015ff:	89 f1                	mov    %esi,%ecx
f0101601:	29 d1                	sub    %edx,%ecx
f0101603:	c1 f9 03             	sar    $0x3,%ecx
f0101606:	c1 e1 0c             	shl    $0xc,%ecx
f0101609:	39 c1                	cmp    %eax,%ecx
f010160b:	72 24                	jb     f0101631 <mem_init+0x2cc>
f010160d:	c7 44 24 0c 54 5a 10 	movl   $0xf0105a54,0xc(%esp)
f0101614:	f0 
f0101615:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010161c:	f0 
f010161d:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0101624:	00 
f0101625:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010162c:	e8 8d ea ff ff       	call   f01000be <_panic>
f0101631:	89 f9                	mov    %edi,%ecx
f0101633:	29 d1                	sub    %edx,%ecx
f0101635:	c1 f9 03             	sar    $0x3,%ecx
f0101638:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010163b:	39 c8                	cmp    %ecx,%eax
f010163d:	77 24                	ja     f0101663 <mem_init+0x2fe>
f010163f:	c7 44 24 0c 71 5a 10 	movl   $0xf0105a71,0xc(%esp)
f0101646:	f0 
f0101647:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010164e:	f0 
f010164f:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101656:	00 
f0101657:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010165e:	e8 5b ea ff ff       	call   f01000be <_panic>
f0101663:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101666:	29 d1                	sub    %edx,%ecx
f0101668:	89 ca                	mov    %ecx,%edx
f010166a:	c1 fa 03             	sar    $0x3,%edx
f010166d:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101670:	39 d0                	cmp    %edx,%eax
f0101672:	77 24                	ja     f0101698 <mem_init+0x333>
f0101674:	c7 44 24 0c 8e 5a 10 	movl   $0xf0105a8e,0xc(%esp)
f010167b:	f0 
f010167c:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101683:	f0 
f0101684:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f010168b:	00 
f010168c:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101693:	e8 26 ea ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101698:	a1 80 d0 17 f0       	mov    0xf017d080,%eax
f010169d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016a0:	c7 05 80 d0 17 f0 00 	movl   $0x0,0xf017d080
f01016a7:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016b1:	e8 35 f8 ff ff       	call   f0100eeb <page_alloc>
f01016b6:	85 c0                	test   %eax,%eax
f01016b8:	74 24                	je     f01016de <mem_init+0x379>
f01016ba:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f01016c1:	f0 
f01016c2:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01016c9:	f0 
f01016ca:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f01016d1:	00 
f01016d2:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01016d9:	e8 e0 e9 ff ff       	call   f01000be <_panic>

	// free and re-allocate?
	page_free(pp0);
f01016de:	89 34 24             	mov    %esi,(%esp)
f01016e1:	e8 83 f8 ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f01016e6:	89 3c 24             	mov    %edi,(%esp)
f01016e9:	e8 7b f8 ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f01016ee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016f1:	89 04 24             	mov    %eax,(%esp)
f01016f4:	e8 70 f8 ff ff       	call   f0100f69 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01016f9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101700:	e8 e6 f7 ff ff       	call   f0100eeb <page_alloc>
f0101705:	89 c6                	mov    %eax,%esi
f0101707:	85 c0                	test   %eax,%eax
f0101709:	75 24                	jne    f010172f <mem_init+0x3ca>
f010170b:	c7 44 24 0c 00 5a 10 	movl   $0xf0105a00,0xc(%esp)
f0101712:	f0 
f0101713:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010171a:	f0 
f010171b:	c7 44 24 04 d1 02 00 	movl   $0x2d1,0x4(%esp)
f0101722:	00 
f0101723:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010172a:	e8 8f e9 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f010172f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101736:	e8 b0 f7 ff ff       	call   f0100eeb <page_alloc>
f010173b:	89 c7                	mov    %eax,%edi
f010173d:	85 c0                	test   %eax,%eax
f010173f:	75 24                	jne    f0101765 <mem_init+0x400>
f0101741:	c7 44 24 0c 16 5a 10 	movl   $0xf0105a16,0xc(%esp)
f0101748:	f0 
f0101749:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101750:	f0 
f0101751:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0101758:	00 
f0101759:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101760:	e8 59 e9 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101765:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010176c:	e8 7a f7 ff ff       	call   f0100eeb <page_alloc>
f0101771:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101774:	85 c0                	test   %eax,%eax
f0101776:	75 24                	jne    f010179c <mem_init+0x437>
f0101778:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f010177f:	f0 
f0101780:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101787:	f0 
f0101788:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f010178f:	00 
f0101790:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101797:	e8 22 e9 ff ff       	call   f01000be <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010179c:	39 fe                	cmp    %edi,%esi
f010179e:	75 24                	jne    f01017c4 <mem_init+0x45f>
f01017a0:	c7 44 24 0c 42 5a 10 	movl   $0xf0105a42,0xc(%esp)
f01017a7:	f0 
f01017a8:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01017af:	f0 
f01017b0:	c7 44 24 04 d5 02 00 	movl   $0x2d5,0x4(%esp)
f01017b7:	00 
f01017b8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01017bf:	e8 fa e8 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017c4:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01017c7:	74 05                	je     f01017ce <mem_init+0x469>
f01017c9:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01017cc:	75 24                	jne    f01017f2 <mem_init+0x48d>
f01017ce:	c7 44 24 0c d8 52 10 	movl   $0xf01052d8,0xc(%esp)
f01017d5:	f0 
f01017d6:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01017dd:	f0 
f01017de:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f01017e5:	00 
f01017e6:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01017ed:	e8 cc e8 ff ff       	call   f01000be <_panic>
	assert(!page_alloc(0));
f01017f2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f9:	e8 ed f6 ff ff       	call   f0100eeb <page_alloc>
f01017fe:	85 c0                	test   %eax,%eax
f0101800:	74 24                	je     f0101826 <mem_init+0x4c1>
f0101802:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f0101809:	f0 
f010180a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101811:	f0 
f0101812:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0101819:	00 
f010181a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101821:	e8 98 e8 ff ff       	call   f01000be <_panic>
f0101826:	89 f0                	mov    %esi,%eax
f0101828:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f010182e:	c1 f8 03             	sar    $0x3,%eax
f0101831:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101834:	89 c2                	mov    %eax,%edx
f0101836:	c1 ea 0c             	shr    $0xc,%edx
f0101839:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f010183f:	72 20                	jb     f0101861 <mem_init+0x4fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101841:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101845:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f010184c:	f0 
f010184d:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101854:	00 
f0101855:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f010185c:	e8 5d e8 ff ff       	call   f01000be <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101861:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101868:	00 
f0101869:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101870:	00 
	return (void *)(pa + KERNBASE);
f0101871:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101876:	89 04 24             	mov    %eax,(%esp)
f0101879:	e8 93 2e 00 00       	call   f0104711 <memset>
	page_free(pp0);
f010187e:	89 34 24             	mov    %esi,(%esp)
f0101881:	e8 e3 f6 ff ff       	call   f0100f69 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101886:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010188d:	e8 59 f6 ff ff       	call   f0100eeb <page_alloc>
f0101892:	85 c0                	test   %eax,%eax
f0101894:	75 24                	jne    f01018ba <mem_init+0x555>
f0101896:	c7 44 24 0c ba 5a 10 	movl   $0xf0105aba,0xc(%esp)
f010189d:	f0 
f010189e:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01018a5:	f0 
f01018a6:	c7 44 24 04 dc 02 00 	movl   $0x2dc,0x4(%esp)
f01018ad:	00 
f01018ae:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01018b5:	e8 04 e8 ff ff       	call   f01000be <_panic>
	assert(pp && pp0 == pp);
f01018ba:	39 c6                	cmp    %eax,%esi
f01018bc:	74 24                	je     f01018e2 <mem_init+0x57d>
f01018be:	c7 44 24 0c d8 5a 10 	movl   $0xf0105ad8,0xc(%esp)
f01018c5:	f0 
f01018c6:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01018cd:	f0 
f01018ce:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f01018d5:	00 
f01018d6:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01018dd:	e8 dc e7 ff ff       	call   f01000be <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f01018e2:	89 f2                	mov    %esi,%edx
f01018e4:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f01018ea:	c1 fa 03             	sar    $0x3,%edx
f01018ed:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018f0:	89 d0                	mov    %edx,%eax
f01018f2:	c1 e8 0c             	shr    $0xc,%eax
f01018f5:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f01018fb:	72 20                	jb     f010191d <mem_init+0x5b8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018fd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101901:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0101908:	f0 
f0101909:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0101910:	00 
f0101911:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0101918:	e8 a1 e7 ff ff       	call   f01000be <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f010191d:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101924:	75 11                	jne    f0101937 <mem_init+0x5d2>
f0101926:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010192c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101932:	80 38 00             	cmpb   $0x0,(%eax)
f0101935:	74 24                	je     f010195b <mem_init+0x5f6>
f0101937:	c7 44 24 0c e8 5a 10 	movl   $0xf0105ae8,0xc(%esp)
f010193e:	f0 
f010193f:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101946:	f0 
f0101947:	c7 44 24 04 e0 02 00 	movl   $0x2e0,0x4(%esp)
f010194e:	00 
f010194f:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101956:	e8 63 e7 ff ff       	call   f01000be <_panic>
f010195b:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f010195e:	39 d0                	cmp    %edx,%eax
f0101960:	75 d0                	jne    f0101932 <mem_init+0x5cd>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101962:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101965:	89 15 80 d0 17 f0    	mov    %edx,0xf017d080

	// free the pages we took
	page_free(pp0);
f010196b:	89 34 24             	mov    %esi,(%esp)
f010196e:	e8 f6 f5 ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f0101973:	89 3c 24             	mov    %edi,(%esp)
f0101976:	e8 ee f5 ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f010197b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010197e:	89 04 24             	mov    %eax,(%esp)
f0101981:	e8 e3 f5 ff ff       	call   f0100f69 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101986:	a1 80 d0 17 f0       	mov    0xf017d080,%eax
f010198b:	85 c0                	test   %eax,%eax
f010198d:	74 09                	je     f0101998 <mem_init+0x633>
		--nfree;
f010198f:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101992:	8b 00                	mov    (%eax),%eax
f0101994:	85 c0                	test   %eax,%eax
f0101996:	75 f7                	jne    f010198f <mem_init+0x62a>
		--nfree;
	assert(nfree == 0);
f0101998:	85 db                	test   %ebx,%ebx
f010199a:	74 24                	je     f01019c0 <mem_init+0x65b>
f010199c:	c7 44 24 0c f2 5a 10 	movl   $0xf0105af2,0xc(%esp)
f01019a3:	f0 
f01019a4:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01019ab:	f0 
f01019ac:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f01019b3:	00 
f01019b4:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01019bb:	e8 fe e6 ff ff       	call   f01000be <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01019c0:	c7 04 24 f8 52 10 f0 	movl   $0xf01052f8,(%esp)
f01019c7:	e8 7e 1d 00 00       	call   f010374a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019cc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019d3:	e8 13 f5 ff ff       	call   f0100eeb <page_alloc>
f01019d8:	89 c3                	mov    %eax,%ebx
f01019da:	85 c0                	test   %eax,%eax
f01019dc:	75 24                	jne    f0101a02 <mem_init+0x69d>
f01019de:	c7 44 24 0c 00 5a 10 	movl   $0xf0105a00,0xc(%esp)
f01019e5:	f0 
f01019e6:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01019ed:	f0 
f01019ee:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f01019f5:	00 
f01019f6:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01019fd:	e8 bc e6 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0101a02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a09:	e8 dd f4 ff ff       	call   f0100eeb <page_alloc>
f0101a0e:	89 c7                	mov    %eax,%edi
f0101a10:	85 c0                	test   %eax,%eax
f0101a12:	75 24                	jne    f0101a38 <mem_init+0x6d3>
f0101a14:	c7 44 24 0c 16 5a 10 	movl   $0xf0105a16,0xc(%esp)
f0101a1b:	f0 
f0101a1c:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101a23:	f0 
f0101a24:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0101a2b:	00 
f0101a2c:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101a33:	e8 86 e6 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0101a38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a3f:	e8 a7 f4 ff ff       	call   f0100eeb <page_alloc>
f0101a44:	89 c6                	mov    %eax,%esi
f0101a46:	85 c0                	test   %eax,%eax
f0101a48:	75 24                	jne    f0101a6e <mem_init+0x709>
f0101a4a:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f0101a51:	f0 
f0101a52:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101a59:	f0 
f0101a5a:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f0101a61:	00 
f0101a62:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101a69:	e8 50 e6 ff ff       	call   f01000be <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a6e:	39 fb                	cmp    %edi,%ebx
f0101a70:	75 24                	jne    f0101a96 <mem_init+0x731>
f0101a72:	c7 44 24 0c 42 5a 10 	movl   $0xf0105a42,0xc(%esp)
f0101a79:	f0 
f0101a7a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101a81:	f0 
f0101a82:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f0101a89:	00 
f0101a8a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101a91:	e8 28 e6 ff ff       	call   f01000be <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a96:	39 c7                	cmp    %eax,%edi
f0101a98:	74 04                	je     f0101a9e <mem_init+0x739>
f0101a9a:	39 c3                	cmp    %eax,%ebx
f0101a9c:	75 24                	jne    f0101ac2 <mem_init+0x75d>
f0101a9e:	c7 44 24 0c d8 52 10 	movl   $0xf01052d8,0xc(%esp)
f0101aa5:	f0 
f0101aa6:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101aad:	f0 
f0101aae:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0101ab5:	00 
f0101ab6:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101abd:	e8 fc e5 ff ff       	call   f01000be <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101ac2:	8b 15 80 d0 17 f0    	mov    0xf017d080,%edx
f0101ac8:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101acb:	c7 05 80 d0 17 f0 00 	movl   $0x0,0xf017d080
f0101ad2:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101ad5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101adc:	e8 0a f4 ff ff       	call   f0100eeb <page_alloc>
f0101ae1:	85 c0                	test   %eax,%eax
f0101ae3:	74 24                	je     f0101b09 <mem_init+0x7a4>
f0101ae5:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f0101aec:	f0 
f0101aed:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101af4:	f0 
f0101af5:	c7 44 24 04 58 03 00 	movl   $0x358,0x4(%esp)
f0101afc:	00 
f0101afd:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101b04:	e8 b5 e5 ff ff       	call   f01000be <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b09:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b0c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101b10:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101b17:	00 
f0101b18:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101b1d:	89 04 24             	mov    %eax,(%esp)
f0101b20:	e8 ad f6 ff ff       	call   f01011d2 <page_lookup>
f0101b25:	85 c0                	test   %eax,%eax
f0101b27:	74 24                	je     f0101b4d <mem_init+0x7e8>
f0101b29:	c7 44 24 0c 18 53 10 	movl   $0xf0105318,0xc(%esp)
f0101b30:	f0 
f0101b31:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101b38:	f0 
f0101b39:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f0101b40:	00 
f0101b41:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101b48:	e8 71 e5 ff ff       	call   f01000be <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101b4d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b54:	00 
f0101b55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101b5c:	00 
f0101b5d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101b61:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101b66:	89 04 24             	mov    %eax,(%esp)
f0101b69:	e8 39 f7 ff ff       	call   f01012a7 <page_insert>
f0101b6e:	85 c0                	test   %eax,%eax
f0101b70:	78 24                	js     f0101b96 <mem_init+0x831>
f0101b72:	c7 44 24 0c 50 53 10 	movl   $0xf0105350,0xc(%esp)
f0101b79:	f0 
f0101b7a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101b81:	f0 
f0101b82:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0101b89:	00 
f0101b8a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101b91:	e8 28 e5 ff ff       	call   f01000be <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101b96:	89 1c 24             	mov    %ebx,(%esp)
f0101b99:	e8 cb f3 ff ff       	call   f0100f69 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101b9e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ba5:	00 
f0101ba6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101bad:	00 
f0101bae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101bb2:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101bb7:	89 04 24             	mov    %eax,(%esp)
f0101bba:	e8 e8 f6 ff ff       	call   f01012a7 <page_insert>
f0101bbf:	85 c0                	test   %eax,%eax
f0101bc1:	74 24                	je     f0101be7 <mem_init+0x882>
f0101bc3:	c7 44 24 0c 80 53 10 	movl   $0xf0105380,0xc(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101bd2:	f0 
f0101bd3:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f0101bda:	00 
f0101bdb:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101be2:	e8 d7 e4 ff ff       	call   f01000be <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101be7:	8b 0d 28 dd 17 f0    	mov    0xf017dd28,%ecx
f0101bed:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bf0:	a1 2c dd 17 f0       	mov    0xf017dd2c,%eax
f0101bf5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bf8:	8b 11                	mov    (%ecx),%edx
f0101bfa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101c00:	89 d8                	mov    %ebx,%eax
f0101c02:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101c05:	c1 f8 03             	sar    $0x3,%eax
f0101c08:	c1 e0 0c             	shl    $0xc,%eax
f0101c0b:	39 c2                	cmp    %eax,%edx
f0101c0d:	74 24                	je     f0101c33 <mem_init+0x8ce>
f0101c0f:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0101c16:	f0 
f0101c17:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101c1e:	f0 
f0101c1f:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0101c26:	00 
f0101c27:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101c2e:	e8 8b e4 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101c33:	ba 00 00 00 00       	mov    $0x0,%edx
f0101c38:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c3b:	e8 18 ed ff ff       	call   f0100958 <check_va2pa>
f0101c40:	89 fa                	mov    %edi,%edx
f0101c42:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101c45:	c1 fa 03             	sar    $0x3,%edx
f0101c48:	c1 e2 0c             	shl    $0xc,%edx
f0101c4b:	39 d0                	cmp    %edx,%eax
f0101c4d:	74 24                	je     f0101c73 <mem_init+0x90e>
f0101c4f:	c7 44 24 0c d8 53 10 	movl   $0xf01053d8,0xc(%esp)
f0101c56:	f0 
f0101c57:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101c5e:	f0 
f0101c5f:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101c66:	00 
f0101c67:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101c6e:	e8 4b e4 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f0101c73:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101c78:	74 24                	je     f0101c9e <mem_init+0x939>
f0101c7a:	c7 44 24 0c fd 5a 10 	movl   $0xf0105afd,0xc(%esp)
f0101c81:	f0 
f0101c82:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101c89:	f0 
f0101c8a:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0101c91:	00 
f0101c92:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101c99:	e8 20 e4 ff ff       	call   f01000be <_panic>
	assert(pp0->pp_ref == 1);
f0101c9e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ca3:	74 24                	je     f0101cc9 <mem_init+0x964>
f0101ca5:	c7 44 24 0c 0e 5b 10 	movl   $0xf0105b0e,0xc(%esp)
f0101cac:	f0 
f0101cad:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101cb4:	f0 
f0101cb5:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0101cbc:	00 
f0101cbd:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101cc4:	e8 f5 e3 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101cc9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101cd0:	00 
f0101cd1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101cd8:	00 
f0101cd9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101cdd:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101ce0:	89 14 24             	mov    %edx,(%esp)
f0101ce3:	e8 bf f5 ff ff       	call   f01012a7 <page_insert>
f0101ce8:	85 c0                	test   %eax,%eax
f0101cea:	74 24                	je     f0101d10 <mem_init+0x9ab>
f0101cec:	c7 44 24 0c 08 54 10 	movl   $0xf0105408,0xc(%esp)
f0101cf3:	f0 
f0101cf4:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101cfb:	f0 
f0101cfc:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0101d03:	00 
f0101d04:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101d0b:	e8 ae e3 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d10:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d15:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101d1a:	e8 39 ec ff ff       	call   f0100958 <check_va2pa>
f0101d1f:	89 f2                	mov    %esi,%edx
f0101d21:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0101d27:	c1 fa 03             	sar    $0x3,%edx
f0101d2a:	c1 e2 0c             	shl    $0xc,%edx
f0101d2d:	39 d0                	cmp    %edx,%eax
f0101d2f:	74 24                	je     f0101d55 <mem_init+0x9f0>
f0101d31:	c7 44 24 0c 44 54 10 	movl   $0xf0105444,0xc(%esp)
f0101d38:	f0 
f0101d39:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101d40:	f0 
f0101d41:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f0101d48:	00 
f0101d49:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101d50:	e8 69 e3 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101d55:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d5a:	74 24                	je     f0101d80 <mem_init+0xa1b>
f0101d5c:	c7 44 24 0c 1f 5b 10 	movl   $0xf0105b1f,0xc(%esp)
f0101d63:	f0 
f0101d64:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101d6b:	f0 
f0101d6c:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f0101d73:	00 
f0101d74:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101d7b:	e8 3e e3 ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101d80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d87:	e8 5f f1 ff ff       	call   f0100eeb <page_alloc>
f0101d8c:	85 c0                	test   %eax,%eax
f0101d8e:	74 24                	je     f0101db4 <mem_init+0xa4f>
f0101d90:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f0101d97:	f0 
f0101d98:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101d9f:	f0 
f0101da0:	c7 44 24 04 6e 03 00 	movl   $0x36e,0x4(%esp)
f0101da7:	00 
f0101da8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101daf:	e8 0a e3 ff ff       	call   f01000be <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101db4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dbb:	00 
f0101dbc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101dc3:	00 
f0101dc4:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101dc8:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101dcd:	89 04 24             	mov    %eax,(%esp)
f0101dd0:	e8 d2 f4 ff ff       	call   f01012a7 <page_insert>
f0101dd5:	85 c0                	test   %eax,%eax
f0101dd7:	74 24                	je     f0101dfd <mem_init+0xa98>
f0101dd9:	c7 44 24 0c 08 54 10 	movl   $0xf0105408,0xc(%esp)
f0101de0:	f0 
f0101de1:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101de8:	f0 
f0101de9:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0101df0:	00 
f0101df1:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101df8:	e8 c1 e2 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dfd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e02:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101e07:	e8 4c eb ff ff       	call   f0100958 <check_va2pa>
f0101e0c:	89 f2                	mov    %esi,%edx
f0101e0e:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0101e14:	c1 fa 03             	sar    $0x3,%edx
f0101e17:	c1 e2 0c             	shl    $0xc,%edx
f0101e1a:	39 d0                	cmp    %edx,%eax
f0101e1c:	74 24                	je     f0101e42 <mem_init+0xadd>
f0101e1e:	c7 44 24 0c 44 54 10 	movl   $0xf0105444,0xc(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101e2d:	f0 
f0101e2e:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0101e35:	00 
f0101e36:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101e3d:	e8 7c e2 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101e42:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e47:	74 24                	je     f0101e6d <mem_init+0xb08>
f0101e49:	c7 44 24 0c 1f 5b 10 	movl   $0xf0105b1f,0xc(%esp)
f0101e50:	f0 
f0101e51:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101e58:	f0 
f0101e59:	c7 44 24 04 73 03 00 	movl   $0x373,0x4(%esp)
f0101e60:	00 
f0101e61:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101e68:	e8 51 e2 ff ff       	call   f01000be <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e6d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e74:	e8 72 f0 ff ff       	call   f0100eeb <page_alloc>
f0101e79:	85 c0                	test   %eax,%eax
f0101e7b:	74 24                	je     f0101ea1 <mem_init+0xb3c>
f0101e7d:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f0101e84:	f0 
f0101e85:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101e8c:	f0 
f0101e8d:	c7 44 24 04 77 03 00 	movl   $0x377,0x4(%esp)
f0101e94:	00 
f0101e95:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101e9c:	e8 1d e2 ff ff       	call   f01000be <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ea1:	8b 15 28 dd 17 f0    	mov    0xf017dd28,%edx
f0101ea7:	8b 02                	mov    (%edx),%eax
f0101ea9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101eae:	89 c1                	mov    %eax,%ecx
f0101eb0:	c1 e9 0c             	shr    $0xc,%ecx
f0101eb3:	3b 0d 24 dd 17 f0    	cmp    0xf017dd24,%ecx
f0101eb9:	72 20                	jb     f0101edb <mem_init+0xb76>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ebb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ebf:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0101ec6:	f0 
f0101ec7:	c7 44 24 04 7a 03 00 	movl   $0x37a,0x4(%esp)
f0101ece:	00 
f0101ecf:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101ed6:	e8 e3 e1 ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0101edb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101ee0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101ee3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101eea:	00 
f0101eeb:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ef2:	00 
f0101ef3:	89 14 24             	mov    %edx,(%esp)
f0101ef6:	e8 d0 f0 ff ff       	call   f0100fcb <pgdir_walk>
f0101efb:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101efe:	83 c2 04             	add    $0x4,%edx
f0101f01:	39 d0                	cmp    %edx,%eax
f0101f03:	74 24                	je     f0101f29 <mem_init+0xbc4>
f0101f05:	c7 44 24 0c 74 54 10 	movl   $0xf0105474,0xc(%esp)
f0101f0c:	f0 
f0101f0d:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101f14:	f0 
f0101f15:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101f1c:	00 
f0101f1d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101f24:	e8 95 e1 ff ff       	call   f01000be <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101f29:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101f30:	00 
f0101f31:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f38:	00 
f0101f39:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f3d:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0101f42:	89 04 24             	mov    %eax,(%esp)
f0101f45:	e8 5d f3 ff ff       	call   f01012a7 <page_insert>
f0101f4a:	85 c0                	test   %eax,%eax
f0101f4c:	74 24                	je     f0101f72 <mem_init+0xc0d>
f0101f4e:	c7 44 24 0c b4 54 10 	movl   $0xf01054b4,0xc(%esp)
f0101f55:	f0 
f0101f56:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101f5d:	f0 
f0101f5e:	c7 44 24 04 7e 03 00 	movl   $0x37e,0x4(%esp)
f0101f65:	00 
f0101f66:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101f6d:	e8 4c e1 ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101f72:	8b 0d 28 dd 17 f0    	mov    0xf017dd28,%ecx
f0101f78:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101f7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f80:	89 c8                	mov    %ecx,%eax
f0101f82:	e8 d1 e9 ff ff       	call   f0100958 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0101f87:	89 f2                	mov    %esi,%edx
f0101f89:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0101f8f:	c1 fa 03             	sar    $0x3,%edx
f0101f92:	c1 e2 0c             	shl    $0xc,%edx
f0101f95:	39 d0                	cmp    %edx,%eax
f0101f97:	74 24                	je     f0101fbd <mem_init+0xc58>
f0101f99:	c7 44 24 0c 44 54 10 	movl   $0xf0105444,0xc(%esp)
f0101fa0:	f0 
f0101fa1:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101fa8:	f0 
f0101fa9:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0101fb0:	00 
f0101fb1:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101fb8:	e8 01 e1 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0101fbd:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101fc2:	74 24                	je     f0101fe8 <mem_init+0xc83>
f0101fc4:	c7 44 24 0c 1f 5b 10 	movl   $0xf0105b1f,0xc(%esp)
f0101fcb:	f0 
f0101fcc:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0101fd3:	f0 
f0101fd4:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f0101fdb:	00 
f0101fdc:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0101fe3:	e8 d6 e0 ff ff       	call   f01000be <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101fe8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fef:	00 
f0101ff0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101ff7:	00 
f0101ff8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ffb:	89 04 24             	mov    %eax,(%esp)
f0101ffe:	e8 c8 ef ff ff       	call   f0100fcb <pgdir_walk>
f0102003:	f6 00 04             	testb  $0x4,(%eax)
f0102006:	75 24                	jne    f010202c <mem_init+0xcc7>
f0102008:	c7 44 24 0c f4 54 10 	movl   $0xf01054f4,0xc(%esp)
f010200f:	f0 
f0102010:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102017:	f0 
f0102018:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f010201f:	00 
f0102020:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102027:	e8 92 e0 ff ff       	call   f01000be <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010202c:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102031:	f6 00 04             	testb  $0x4,(%eax)
f0102034:	75 24                	jne    f010205a <mem_init+0xcf5>
f0102036:	c7 44 24 0c 30 5b 10 	movl   $0xf0105b30,0xc(%esp)
f010203d:	f0 
f010203e:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102045:	f0 
f0102046:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f010204d:	00 
f010204e:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102055:	e8 64 e0 ff ff       	call   f01000be <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010205a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102061:	00 
f0102062:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102069:	00 
f010206a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010206e:	89 04 24             	mov    %eax,(%esp)
f0102071:	e8 31 f2 ff ff       	call   f01012a7 <page_insert>
f0102076:	85 c0                	test   %eax,%eax
f0102078:	78 24                	js     f010209e <mem_init+0xd39>
f010207a:	c7 44 24 0c 28 55 10 	movl   $0xf0105528,0xc(%esp)
f0102081:	f0 
f0102082:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102089:	f0 
f010208a:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f0102091:	00 
f0102092:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102099:	e8 20 e0 ff ff       	call   f01000be <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010209e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020a5:	00 
f01020a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020ad:	00 
f01020ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01020b2:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f01020b7:	89 04 24             	mov    %eax,(%esp)
f01020ba:	e8 e8 f1 ff ff       	call   f01012a7 <page_insert>
f01020bf:	85 c0                	test   %eax,%eax
f01020c1:	74 24                	je     f01020e7 <mem_init+0xd82>
f01020c3:	c7 44 24 0c 60 55 10 	movl   $0xf0105560,0xc(%esp)
f01020ca:	f0 
f01020cb:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01020d2:	f0 
f01020d3:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f01020da:	00 
f01020db:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01020e2:	e8 d7 df ff ff       	call   f01000be <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01020e7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020ee:	00 
f01020ef:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020f6:	00 
f01020f7:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f01020fc:	89 04 24             	mov    %eax,(%esp)
f01020ff:	e8 c7 ee ff ff       	call   f0100fcb <pgdir_walk>
f0102104:	f6 00 04             	testb  $0x4,(%eax)
f0102107:	74 24                	je     f010212d <mem_init+0xdc8>
f0102109:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f0102110:	f0 
f0102111:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102118:	f0 
f0102119:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102120:	00 
f0102121:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102128:	e8 91 df ff ff       	call   f01000be <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010212d:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102132:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102135:	ba 00 00 00 00       	mov    $0x0,%edx
f010213a:	e8 19 e8 ff ff       	call   f0100958 <check_va2pa>
f010213f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102142:	89 f8                	mov    %edi,%eax
f0102144:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f010214a:	c1 f8 03             	sar    $0x3,%eax
f010214d:	c1 e0 0c             	shl    $0xc,%eax
f0102150:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102153:	74 24                	je     f0102179 <mem_init+0xe14>
f0102155:	c7 44 24 0c d4 55 10 	movl   $0xf01055d4,0xc(%esp)
f010215c:	f0 
f010215d:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102164:	f0 
f0102165:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f010216c:	00 
f010216d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102174:	e8 45 df ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102179:	ba 00 10 00 00       	mov    $0x1000,%edx
f010217e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102181:	e8 d2 e7 ff ff       	call   f0100958 <check_va2pa>
f0102186:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102189:	74 24                	je     f01021af <mem_init+0xe4a>
f010218b:	c7 44 24 0c 00 56 10 	movl   $0xf0105600,0xc(%esp)
f0102192:	f0 
f0102193:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010219a:	f0 
f010219b:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f01021a2:	00 
f01021a3:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01021aa:	e8 0f df ff ff       	call   f01000be <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f01021af:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f01021b4:	74 24                	je     f01021da <mem_init+0xe75>
f01021b6:	c7 44 24 0c 46 5b 10 	movl   $0xf0105b46,0xc(%esp)
f01021bd:	f0 
f01021be:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01021c5:	f0 
f01021c6:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f01021cd:	00 
f01021ce:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01021d5:	e8 e4 de ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01021da:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021df:	74 24                	je     f0102205 <mem_init+0xea0>
f01021e1:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f01021e8:	f0 
f01021e9:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01021f0:	f0 
f01021f1:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01021f8:	00 
f01021f9:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102200:	e8 b9 de ff ff       	call   f01000be <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102205:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010220c:	e8 da ec ff ff       	call   f0100eeb <page_alloc>
f0102211:	85 c0                	test   %eax,%eax
f0102213:	74 04                	je     f0102219 <mem_init+0xeb4>
f0102215:	39 c6                	cmp    %eax,%esi
f0102217:	74 24                	je     f010223d <mem_init+0xed8>
f0102219:	c7 44 24 0c 30 56 10 	movl   $0xf0105630,0xc(%esp)
f0102220:	f0 
f0102221:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102228:	f0 
f0102229:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f0102230:	00 
f0102231:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102238:	e8 81 de ff ff       	call   f01000be <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010223d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102244:	00 
f0102245:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f010224a:	89 04 24             	mov    %eax,(%esp)
f010224d:	e8 05 f0 ff ff       	call   f0101257 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102252:	8b 15 28 dd 17 f0    	mov    0xf017dd28,%edx
f0102258:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010225b:	ba 00 00 00 00       	mov    $0x0,%edx
f0102260:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102263:	e8 f0 e6 ff ff       	call   f0100958 <check_va2pa>
f0102268:	83 f8 ff             	cmp    $0xffffffff,%eax
f010226b:	74 24                	je     f0102291 <mem_init+0xf2c>
f010226d:	c7 44 24 0c 54 56 10 	movl   $0xf0105654,0xc(%esp)
f0102274:	f0 
f0102275:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010227c:	f0 
f010227d:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102284:	00 
f0102285:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010228c:	e8 2d de ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102291:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102296:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102299:	e8 ba e6 ff ff       	call   f0100958 <check_va2pa>
f010229e:	89 fa                	mov    %edi,%edx
f01022a0:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f01022a6:	c1 fa 03             	sar    $0x3,%edx
f01022a9:	c1 e2 0c             	shl    $0xc,%edx
f01022ac:	39 d0                	cmp    %edx,%eax
f01022ae:	74 24                	je     f01022d4 <mem_init+0xf6f>
f01022b0:	c7 44 24 0c 00 56 10 	movl   $0xf0105600,0xc(%esp)
f01022b7:	f0 
f01022b8:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01022bf:	f0 
f01022c0:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01022c7:	00 
f01022c8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01022cf:	e8 ea dd ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 1);
f01022d4:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01022d9:	74 24                	je     f01022ff <mem_init+0xf9a>
f01022db:	c7 44 24 0c fd 5a 10 	movl   $0xf0105afd,0xc(%esp)
f01022e2:	f0 
f01022e3:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01022ea:	f0 
f01022eb:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01022f2:	00 
f01022f3:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01022fa:	e8 bf dd ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01022ff:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102304:	74 24                	je     f010232a <mem_init+0xfc5>
f0102306:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f010230d:	f0 
f010230e:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102315:	f0 
f0102316:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f010231d:	00 
f010231e:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102325:	e8 94 dd ff ff       	call   f01000be <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010232a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102331:	00 
f0102332:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102335:	89 0c 24             	mov    %ecx,(%esp)
f0102338:	e8 1a ef ff ff       	call   f0101257 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010233d:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102342:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102345:	ba 00 00 00 00       	mov    $0x0,%edx
f010234a:	e8 09 e6 ff ff       	call   f0100958 <check_va2pa>
f010234f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102352:	74 24                	je     f0102378 <mem_init+0x1013>
f0102354:	c7 44 24 0c 54 56 10 	movl   $0xf0105654,0xc(%esp)
f010235b:	f0 
f010235c:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102363:	f0 
f0102364:	c7 44 24 04 9e 03 00 	movl   $0x39e,0x4(%esp)
f010236b:	00 
f010236c:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102373:	e8 46 dd ff ff       	call   f01000be <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102378:	ba 00 10 00 00       	mov    $0x1000,%edx
f010237d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102380:	e8 d3 e5 ff ff       	call   f0100958 <check_va2pa>
f0102385:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102388:	74 24                	je     f01023ae <mem_init+0x1049>
f010238a:	c7 44 24 0c 78 56 10 	movl   $0xf0105678,0xc(%esp)
f0102391:	f0 
f0102392:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102399:	f0 
f010239a:	c7 44 24 04 9f 03 00 	movl   $0x39f,0x4(%esp)
f01023a1:	00 
f01023a2:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01023a9:	e8 10 dd ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f01023ae:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01023b3:	74 24                	je     f01023d9 <mem_init+0x1074>
f01023b5:	c7 44 24 0c 68 5b 10 	movl   $0xf0105b68,0xc(%esp)
f01023bc:	f0 
f01023bd:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01023c4:	f0 
f01023c5:	c7 44 24 04 a0 03 00 	movl   $0x3a0,0x4(%esp)
f01023cc:	00 
f01023cd:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01023d4:	e8 e5 dc ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 0);
f01023d9:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01023de:	74 24                	je     f0102404 <mem_init+0x109f>
f01023e0:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f01023e7:	f0 
f01023e8:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01023ef:	f0 
f01023f0:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f01023f7:	00 
f01023f8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01023ff:	e8 ba dc ff ff       	call   f01000be <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102404:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010240b:	e8 db ea ff ff       	call   f0100eeb <page_alloc>
f0102410:	85 c0                	test   %eax,%eax
f0102412:	74 04                	je     f0102418 <mem_init+0x10b3>
f0102414:	39 c7                	cmp    %eax,%edi
f0102416:	74 24                	je     f010243c <mem_init+0x10d7>
f0102418:	c7 44 24 0c a0 56 10 	movl   $0xf01056a0,0xc(%esp)
f010241f:	f0 
f0102420:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102427:	f0 
f0102428:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f010242f:	00 
f0102430:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102437:	e8 82 dc ff ff       	call   f01000be <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010243c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102443:	e8 a3 ea ff ff       	call   f0100eeb <page_alloc>
f0102448:	85 c0                	test   %eax,%eax
f010244a:	74 24                	je     f0102470 <mem_init+0x110b>
f010244c:	c7 44 24 0c ab 5a 10 	movl   $0xf0105aab,0xc(%esp)
f0102453:	f0 
f0102454:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010245b:	f0 
f010245c:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0102463:	00 
f0102464:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010246b:	e8 4e dc ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102470:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102475:	8b 08                	mov    (%eax),%ecx
f0102477:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010247d:	89 da                	mov    %ebx,%edx
f010247f:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0102485:	c1 fa 03             	sar    $0x3,%edx
f0102488:	c1 e2 0c             	shl    $0xc,%edx
f010248b:	39 d1                	cmp    %edx,%ecx
f010248d:	74 24                	je     f01024b3 <mem_init+0x114e>
f010248f:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0102496:	f0 
f0102497:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010249e:	f0 
f010249f:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f01024a6:	00 
f01024a7:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01024ae:	e8 0b dc ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f01024b3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01024b9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01024be:	74 24                	je     f01024e4 <mem_init+0x117f>
f01024c0:	c7 44 24 0c 0e 5b 10 	movl   $0xf0105b0e,0xc(%esp)
f01024c7:	f0 
f01024c8:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01024cf:	f0 
f01024d0:	c7 44 24 04 ac 03 00 	movl   $0x3ac,0x4(%esp)
f01024d7:	00 
f01024d8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01024df:	e8 da db ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f01024e4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01024ea:	89 1c 24             	mov    %ebx,(%esp)
f01024ed:	e8 77 ea ff ff       	call   f0100f69 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01024f2:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024f9:	00 
f01024fa:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102501:	00 
f0102502:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102507:	89 04 24             	mov    %eax,(%esp)
f010250a:	e8 bc ea ff ff       	call   f0100fcb <pgdir_walk>
f010250f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102512:	8b 0d 28 dd 17 f0    	mov    0xf017dd28,%ecx
f0102518:	8b 51 04             	mov    0x4(%ecx),%edx
f010251b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102521:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102524:	8b 15 24 dd 17 f0    	mov    0xf017dd24,%edx
f010252a:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010252d:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102530:	c1 ea 0c             	shr    $0xc,%edx
f0102533:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102536:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102539:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f010253c:	72 23                	jb     f0102561 <mem_init+0x11fc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010253e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102541:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102545:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f010254c:	f0 
f010254d:	c7 44 24 04 b3 03 00 	movl   $0x3b3,0x4(%esp)
f0102554:	00 
f0102555:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010255c:	e8 5d db ff ff       	call   f01000be <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102561:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102564:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010256a:	39 d0                	cmp    %edx,%eax
f010256c:	74 24                	je     f0102592 <mem_init+0x122d>
f010256e:	c7 44 24 0c 79 5b 10 	movl   $0xf0105b79,0xc(%esp)
f0102575:	f0 
f0102576:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010257d:	f0 
f010257e:	c7 44 24 04 b4 03 00 	movl   $0x3b4,0x4(%esp)
f0102585:	00 
f0102586:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010258d:	e8 2c db ff ff       	call   f01000be <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102592:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102599:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f010259f:	89 d8                	mov    %ebx,%eax
f01025a1:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f01025a7:	c1 f8 03             	sar    $0x3,%eax
f01025aa:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01025ad:	89 c1                	mov    %eax,%ecx
f01025af:	c1 e9 0c             	shr    $0xc,%ecx
f01025b2:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01025b5:	77 20                	ja     f01025d7 <mem_init+0x1272>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01025b7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025bb:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f01025c2:	f0 
f01025c3:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f01025ca:	00 
f01025cb:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f01025d2:	e8 e7 da ff ff       	call   f01000be <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01025d7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025de:	00 
f01025df:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01025e6:	00 
	return (void *)(pa + KERNBASE);
f01025e7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01025ec:	89 04 24             	mov    %eax,(%esp)
f01025ef:	e8 1d 21 00 00       	call   f0104711 <memset>
	page_free(pp0);
f01025f4:	89 1c 24             	mov    %ebx,(%esp)
f01025f7:	e8 6d e9 ff ff       	call   f0100f69 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01025fc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102603:	00 
f0102604:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010260b:	00 
f010260c:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102611:	89 04 24             	mov    %eax,(%esp)
f0102614:	e8 b2 e9 ff ff       	call   f0100fcb <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102619:	89 da                	mov    %ebx,%edx
f010261b:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0102621:	c1 fa 03             	sar    $0x3,%edx
f0102624:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102627:	89 d0                	mov    %edx,%eax
f0102629:	c1 e8 0c             	shr    $0xc,%eax
f010262c:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f0102632:	72 20                	jb     f0102654 <mem_init+0x12ef>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102634:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102638:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f010263f:	f0 
f0102640:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102647:	00 
f0102648:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f010264f:	e8 6a da ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0102654:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010265a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010265d:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102664:	75 11                	jne    f0102677 <mem_init+0x1312>
f0102666:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010266c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102672:	f6 00 01             	testb  $0x1,(%eax)
f0102675:	74 24                	je     f010269b <mem_init+0x1336>
f0102677:	c7 44 24 0c 91 5b 10 	movl   $0xf0105b91,0xc(%esp)
f010267e:	f0 
f010267f:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102686:	f0 
f0102687:	c7 44 24 04 be 03 00 	movl   $0x3be,0x4(%esp)
f010268e:	00 
f010268f:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102696:	e8 23 da ff ff       	call   f01000be <_panic>
f010269b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010269e:	39 d0                	cmp    %edx,%eax
f01026a0:	75 d0                	jne    f0102672 <mem_init+0x130d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f01026a2:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f01026a7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01026ad:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f01026b3:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f01026b6:	89 0d 80 d0 17 f0    	mov    %ecx,0xf017d080

	// free the pages we took
	page_free(pp0);
f01026bc:	89 1c 24             	mov    %ebx,(%esp)
f01026bf:	e8 a5 e8 ff ff       	call   f0100f69 <page_free>
	page_free(pp1);
f01026c4:	89 3c 24             	mov    %edi,(%esp)
f01026c7:	e8 9d e8 ff ff       	call   f0100f69 <page_free>
	page_free(pp2);
f01026cc:	89 34 24             	mov    %esi,(%esp)
f01026cf:	e8 95 e8 ff ff       	call   f0100f69 <page_free>

	cprintf("check_page() succeeded!\n");
f01026d4:	c7 04 24 a8 5b 10 f0 	movl   $0xf0105ba8,(%esp)
f01026db:	e8 6a 10 00 00       	call   f010374a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct Page),
f01026e0:	a1 2c dd 17 f0       	mov    0xf017dd2c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026ea:	77 20                	ja     f010270c <mem_init+0x13a7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01026f0:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01026f7:	f0 
f01026f8:	c7 44 24 04 b9 00 00 	movl   $0xb9,0x4(%esp)
f01026ff:	00 
f0102700:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102707:	e8 b2 d9 ff ff       	call   f01000be <_panic>
f010270c:	8b 15 24 dd 17 f0    	mov    0xf017dd24,%edx
f0102712:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102719:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010271f:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102726:	00 
	return (physaddr_t)kva - KERNBASE;
f0102727:	05 00 00 00 10       	add    $0x10000000,%eax
f010272c:	89 04 24             	mov    %eax,(%esp)
f010272f:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102734:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102739:	e8 9c e9 ff ff       	call   f01010da <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
    boot_map_region(kern_pgdir, UENVS, ROUNDUP(npages * sizeof(struct Env),
f010273e:	a1 88 d0 17 f0       	mov    0xf017d088,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102743:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102748:	77 20                	ja     f010276a <mem_init+0x1405>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010274a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010274e:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0102755:	f0 
f0102756:	c7 44 24 04 c3 00 00 	movl   $0xc3,0x4(%esp)
f010275d:	00 
f010275e:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102765:	e8 54 d9 ff ff       	call   f01000be <_panic>
f010276a:	8b 15 24 dd 17 f0    	mov    0xf017dd24,%edx
f0102770:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0102773:	c1 e1 05             	shl    $0x5,%ecx
f0102776:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f010277c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102782:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102789:	00 
	return (physaddr_t)kva - KERNBASE;
f010278a:	05 00 00 00 10       	add    $0x10000000,%eax
f010278f:	89 04 24             	mov    %eax,(%esp)
f0102792:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102797:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f010279c:	e8 39 e9 ff ff       	call   f01010da <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027a1:	b8 00 10 11 f0       	mov    $0xf0111000,%eax
f01027a6:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01027ab:	77 20                	ja     f01027cd <mem_init+0x1468>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027ad:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01027b1:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01027b8:	f0 
f01027b9:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
f01027c0:	00 
f01027c1:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01027c8:	e8 f1 d8 ff ff       	call   f01000be <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE,
f01027cd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027d4:	00 
f01027d5:	c7 04 24 00 10 11 00 	movl   $0x111000,(%esp)
f01027dc:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027e1:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f01027e6:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f01027eb:	e8 ea e8 ff ff       	call   f01010da <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
    boot_map_region(kern_pgdir, KERNBASE, ~KERNBASE + 1, 0x0, PTE_W);
f01027f0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01027f7:	00 
f01027f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01027ff:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102804:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102809:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f010280e:	e8 c7 e8 ff ff       	call   f01010da <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102813:	8b 1d 28 dd 17 f0    	mov    0xf017dd28,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
f0102819:	8b 15 24 dd 17 f0    	mov    0xf017dd24,%edx
f010281f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102822:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
	for (i = 0; i < n; i += PGSIZE)
f0102829:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f010282f:	0f 84 80 00 00 00    	je     f01028b5 <mem_init+0x1550>
f0102835:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010283a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102840:	89 d8                	mov    %ebx,%eax
f0102842:	e8 11 e1 ff ff       	call   f0100958 <check_va2pa>
f0102847:	8b 15 2c dd 17 f0    	mov    0xf017dd2c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010284d:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102853:	77 20                	ja     f0102875 <mem_init+0x1510>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102855:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102859:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0102860:	f0 
f0102861:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102868:	00 
f0102869:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102870:	e8 49 d8 ff ff       	call   f01000be <_panic>
f0102875:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f010287c:	39 d0                	cmp    %edx,%eax
f010287e:	74 24                	je     f01028a4 <mem_init+0x153f>
f0102880:	c7 44 24 0c c4 56 10 	movl   $0xf01056c4,0xc(%esp)
f0102887:	f0 
f0102888:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010288f:	f0 
f0102890:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102897:	00 
f0102898:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010289f:	e8 1a d8 ff ff       	call   f01000be <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct Page), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f01028a4:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028aa:	39 f7                	cmp    %esi,%edi
f01028ac:	77 8c                	ja     f010283a <mem_init+0x14d5>
f01028ae:	be 00 00 00 00       	mov    $0x0,%esi
f01028b3:	eb 05                	jmp    f01028ba <mem_init+0x1555>
f01028b5:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01028ba:	8d 96 00 00 c0 ee    	lea    -0x11400000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01028c0:	89 d8                	mov    %ebx,%eax
f01028c2:	e8 91 e0 ff ff       	call   f0100958 <check_va2pa>
f01028c7:	8b 15 88 d0 17 f0    	mov    0xf017d088,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028cd:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01028d3:	77 20                	ja     f01028f5 <mem_init+0x1590>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028d5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01028d9:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f01028e8:	00 
f01028e9:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01028f0:	e8 c9 d7 ff ff       	call   f01000be <_panic>
f01028f5:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01028fc:	39 d0                	cmp    %edx,%eax
f01028fe:	74 24                	je     f0102924 <mem_init+0x15bf>
f0102900:	c7 44 24 0c f8 56 10 	movl   $0xf01056f8,0xc(%esp)
f0102907:	f0 
f0102908:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f010290f:	f0 
f0102910:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0102917:	00 
f0102918:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f010291f:	e8 9a d7 ff ff       	call   f01000be <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102924:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010292a:	81 fe 00 80 01 00    	cmp    $0x18000,%esi
f0102930:	75 88                	jne    f01028ba <mem_init+0x1555>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102932:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102935:	c1 e7 0c             	shl    $0xc,%edi
f0102938:	85 ff                	test   %edi,%edi
f010293a:	74 44                	je     f0102980 <mem_init+0x161b>
f010293c:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102941:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102947:	89 d8                	mov    %ebx,%eax
f0102949:	e8 0a e0 ff ff       	call   f0100958 <check_va2pa>
f010294e:	39 c6                	cmp    %eax,%esi
f0102950:	74 24                	je     f0102976 <mem_init+0x1611>
f0102952:	c7 44 24 0c 2c 57 10 	movl   $0xf010572c,0xc(%esp)
f0102959:	f0 
f010295a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102961:	f0 
f0102962:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0102969:	00 
f010296a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102971:	e8 48 d7 ff ff       	call   f01000be <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102976:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010297c:	39 fe                	cmp    %edi,%esi
f010297e:	72 c1                	jb     f0102941 <mem_init+0x15dc>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102980:	ba 00 80 bf ef       	mov    $0xefbf8000,%edx
f0102985:	89 d8                	mov    %ebx,%eax
f0102987:	e8 cc df ff ff       	call   f0100958 <check_va2pa>
f010298c:	be 00 90 bf ef       	mov    $0xefbf9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102991:	bf 00 10 11 f0       	mov    $0xf0111000,%edi
f0102996:	81 c7 00 70 40 20    	add    $0x20407000,%edi
f010299c:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010299f:	39 c2                	cmp    %eax,%edx
f01029a1:	74 24                	je     f01029c7 <mem_init+0x1662>
f01029a3:	c7 44 24 0c 54 57 10 	movl   $0xf0105754,0xc(%esp)
f01029aa:	f0 
f01029ab:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01029b2:	f0 
f01029b3:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01029ba:	00 
f01029bb:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f01029c2:	e8 f7 d6 ff ff       	call   f01000be <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029c7:	81 fe 00 00 c0 ef    	cmp    $0xefc00000,%esi
f01029cd:	0f 85 27 05 00 00    	jne    f0102efa <mem_init+0x1b95>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029d3:	ba 00 00 80 ef       	mov    $0xef800000,%edx
f01029d8:	89 d8                	mov    %ebx,%eax
f01029da:	e8 79 df ff ff       	call   f0100958 <check_va2pa>
f01029df:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029e2:	74 24                	je     f0102a08 <mem_init+0x16a3>
f01029e4:	c7 44 24 0c 9c 57 10 	movl   $0xf010579c,0xc(%esp)
f01029eb:	f0 
f01029ec:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f01029f3:	f0 
f01029f4:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01029fb:	00 
f01029fc:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102a03:	e8 b6 d6 ff ff       	call   f01000be <_panic>
f0102a08:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a0d:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a13:	83 fa 03             	cmp    $0x3,%edx
f0102a16:	77 2e                	ja     f0102a46 <mem_init+0x16e1>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
			assert(pgdir[i] & PTE_P);
f0102a18:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102a1c:	0f 85 aa 00 00 00    	jne    f0102acc <mem_init+0x1767>
f0102a22:	c7 44 24 0c c1 5b 10 	movl   $0xf0105bc1,0xc(%esp)
f0102a29:	f0 
f0102a2a:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102a31:	f0 
f0102a32:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102a39:	00 
f0102a3a:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102a41:	e8 78 d6 ff ff       	call   f01000be <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a46:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a4b:	76 55                	jbe    f0102aa2 <mem_init+0x173d>
				assert(pgdir[i] & PTE_P);
f0102a4d:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102a50:	f6 c2 01             	test   $0x1,%dl
f0102a53:	75 24                	jne    f0102a79 <mem_init+0x1714>
f0102a55:	c7 44 24 0c c1 5b 10 	movl   $0xf0105bc1,0xc(%esp)
f0102a5c:	f0 
f0102a5d:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102a64:	f0 
f0102a65:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102a6c:	00 
f0102a6d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102a74:	e8 45 d6 ff ff       	call   f01000be <_panic>
				assert(pgdir[i] & PTE_W);
f0102a79:	f6 c2 02             	test   $0x2,%dl
f0102a7c:	75 4e                	jne    f0102acc <mem_init+0x1767>
f0102a7e:	c7 44 24 0c d2 5b 10 	movl   $0xf0105bd2,0xc(%esp)
f0102a85:	f0 
f0102a86:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102a8d:	f0 
f0102a8e:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102a95:	00 
f0102a96:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102a9d:	e8 1c d6 ff ff       	call   f01000be <_panic>
			} else
				assert(pgdir[i] == 0);
f0102aa2:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102aa6:	74 24                	je     f0102acc <mem_init+0x1767>
f0102aa8:	c7 44 24 0c e3 5b 10 	movl   $0xf0105be3,0xc(%esp)
f0102aaf:	f0 
f0102ab0:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102ab7:	f0 
f0102ab8:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102abf:	00 
f0102ac0:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102ac7:	e8 f2 d5 ff ff       	call   f01000be <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102acc:	83 c0 01             	add    $0x1,%eax
f0102acf:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102ad4:	0f 85 33 ff ff ff    	jne    f0102a0d <mem_init+0x16a8>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ada:	c7 04 24 cc 57 10 f0 	movl   $0xf01057cc,(%esp)
f0102ae1:	e8 64 0c 00 00       	call   f010374a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ae6:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aeb:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af0:	77 20                	ja     f0102b12 <mem_init+0x17ad>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102af6:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0102afd:	f0 
f0102afe:	c7 44 24 04 e8 00 00 	movl   $0xe8,0x4(%esp)
f0102b05:	00 
f0102b06:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102b0d:	e8 ac d5 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b12:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b17:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b1f:	e8 3e df ff ff       	call   f0100a62 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b24:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102b27:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b2c:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b2f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b39:	e8 ad e3 ff ff       	call   f0100eeb <page_alloc>
f0102b3e:	89 c6                	mov    %eax,%esi
f0102b40:	85 c0                	test   %eax,%eax
f0102b42:	75 24                	jne    f0102b68 <mem_init+0x1803>
f0102b44:	c7 44 24 0c 00 5a 10 	movl   $0xf0105a00,0xc(%esp)
f0102b4b:	f0 
f0102b4c:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102b53:	f0 
f0102b54:	c7 44 24 04 d9 03 00 	movl   $0x3d9,0x4(%esp)
f0102b5b:	00 
f0102b5c:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102b63:	e8 56 d5 ff ff       	call   f01000be <_panic>
	assert((pp1 = page_alloc(0)));
f0102b68:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b6f:	e8 77 e3 ff ff       	call   f0100eeb <page_alloc>
f0102b74:	89 c7                	mov    %eax,%edi
f0102b76:	85 c0                	test   %eax,%eax
f0102b78:	75 24                	jne    f0102b9e <mem_init+0x1839>
f0102b7a:	c7 44 24 0c 16 5a 10 	movl   $0xf0105a16,0xc(%esp)
f0102b81:	f0 
f0102b82:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102b89:	f0 
f0102b8a:	c7 44 24 04 da 03 00 	movl   $0x3da,0x4(%esp)
f0102b91:	00 
f0102b92:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102b99:	e8 20 d5 ff ff       	call   f01000be <_panic>
	assert((pp2 = page_alloc(0)));
f0102b9e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ba5:	e8 41 e3 ff ff       	call   f0100eeb <page_alloc>
f0102baa:	89 c3                	mov    %eax,%ebx
f0102bac:	85 c0                	test   %eax,%eax
f0102bae:	75 24                	jne    f0102bd4 <mem_init+0x186f>
f0102bb0:	c7 44 24 0c 2c 5a 10 	movl   $0xf0105a2c,0xc(%esp)
f0102bb7:	f0 
f0102bb8:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102bbf:	f0 
f0102bc0:	c7 44 24 04 db 03 00 	movl   $0x3db,0x4(%esp)
f0102bc7:	00 
f0102bc8:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102bcf:	e8 ea d4 ff ff       	call   f01000be <_panic>
	page_free(pp0);
f0102bd4:	89 34 24             	mov    %esi,(%esp)
f0102bd7:	e8 8d e3 ff ff       	call   f0100f69 <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bdc:	89 f8                	mov    %edi,%eax
f0102bde:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0102be4:	c1 f8 03             	sar    $0x3,%eax
f0102be7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bea:	89 c2                	mov    %eax,%edx
f0102bec:	c1 ea 0c             	shr    $0xc,%edx
f0102bef:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0102bf5:	72 20                	jb     f0102c17 <mem_init+0x18b2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bf7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bfb:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0102c02:	f0 
f0102c03:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102c0a:	00 
f0102c0b:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0102c12:	e8 a7 d4 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c17:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c1e:	00 
f0102c1f:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102c26:	00 
	return (void *)(pa + KERNBASE);
f0102c27:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c2c:	89 04 24             	mov    %eax,(%esp)
f0102c2f:	e8 dd 1a 00 00       	call   f0104711 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c34:	89 d8                	mov    %ebx,%eax
f0102c36:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0102c3c:	c1 f8 03             	sar    $0x3,%eax
f0102c3f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c42:	89 c2                	mov    %eax,%edx
f0102c44:	c1 ea 0c             	shr    $0xc,%edx
f0102c47:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0102c4d:	72 20                	jb     f0102c6f <mem_init+0x190a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c4f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c53:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0102c5a:	f0 
f0102c5b:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102c62:	00 
f0102c63:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0102c6a:	e8 4f d4 ff ff       	call   f01000be <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c6f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c76:	00 
f0102c77:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c7e:	00 
	return (void *)(pa + KERNBASE);
f0102c7f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c84:	89 04 24             	mov    %eax,(%esp)
f0102c87:	e8 85 1a 00 00       	call   f0104711 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c8c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c93:	00 
f0102c94:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c9b:	00 
f0102c9c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ca0:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102ca5:	89 04 24             	mov    %eax,(%esp)
f0102ca8:	e8 fa e5 ff ff       	call   f01012a7 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cad:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cb2:	74 24                	je     f0102cd8 <mem_init+0x1973>
f0102cb4:	c7 44 24 0c fd 5a 10 	movl   $0xf0105afd,0xc(%esp)
f0102cbb:	f0 
f0102cbc:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102cc3:	f0 
f0102cc4:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f0102ccb:	00 
f0102ccc:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102cd3:	e8 e6 d3 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102cd8:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102cdf:	01 01 01 
f0102ce2:	74 24                	je     f0102d08 <mem_init+0x19a3>
f0102ce4:	c7 44 24 0c ec 57 10 	movl   $0xf01057ec,0xc(%esp)
f0102ceb:	f0 
f0102cec:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102cf3:	f0 
f0102cf4:	c7 44 24 04 e1 03 00 	movl   $0x3e1,0x4(%esp)
f0102cfb:	00 
f0102cfc:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102d03:	e8 b6 d3 ff ff       	call   f01000be <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d08:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d0f:	00 
f0102d10:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d17:	00 
f0102d18:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d1c:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102d21:	89 04 24             	mov    %eax,(%esp)
f0102d24:	e8 7e e5 ff ff       	call   f01012a7 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d29:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d30:	02 02 02 
f0102d33:	74 24                	je     f0102d59 <mem_init+0x19f4>
f0102d35:	c7 44 24 0c 10 58 10 	movl   $0xf0105810,0xc(%esp)
f0102d3c:	f0 
f0102d3d:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102d44:	f0 
f0102d45:	c7 44 24 04 e3 03 00 	movl   $0x3e3,0x4(%esp)
f0102d4c:	00 
f0102d4d:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102d54:	e8 65 d3 ff ff       	call   f01000be <_panic>
	assert(pp2->pp_ref == 1);
f0102d59:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d5e:	74 24                	je     f0102d84 <mem_init+0x1a1f>
f0102d60:	c7 44 24 0c 1f 5b 10 	movl   $0xf0105b1f,0xc(%esp)
f0102d67:	f0 
f0102d68:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102d6f:	f0 
f0102d70:	c7 44 24 04 e4 03 00 	movl   $0x3e4,0x4(%esp)
f0102d77:	00 
f0102d78:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102d7f:	e8 3a d3 ff ff       	call   f01000be <_panic>
	assert(pp1->pp_ref == 0);
f0102d84:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d89:	74 24                	je     f0102daf <mem_init+0x1a4a>
f0102d8b:	c7 44 24 0c 68 5b 10 	movl   $0xf0105b68,0xc(%esp)
f0102d92:	f0 
f0102d93:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102d9a:	f0 
f0102d9b:	c7 44 24 04 e5 03 00 	movl   $0x3e5,0x4(%esp)
f0102da2:	00 
f0102da3:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102daa:	e8 0f d3 ff ff       	call   f01000be <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102daf:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102db6:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102db9:	89 d8                	mov    %ebx,%eax
f0102dbb:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0102dc1:	c1 f8 03             	sar    $0x3,%eax
f0102dc4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dc7:	89 c2                	mov    %eax,%edx
f0102dc9:	c1 ea 0c             	shr    $0xc,%edx
f0102dcc:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0102dd2:	72 20                	jb     f0102df4 <mem_init+0x1a8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102dd4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dd8:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0102ddf:	f0 
f0102de0:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f0102de7:	00 
f0102de8:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0102def:	e8 ca d2 ff ff       	call   f01000be <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102df4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102dfb:	03 03 03 
f0102dfe:	74 24                	je     f0102e24 <mem_init+0x1abf>
f0102e00:	c7 44 24 0c 34 58 10 	movl   $0xf0105834,0xc(%esp)
f0102e07:	f0 
f0102e08:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102e0f:	f0 
f0102e10:	c7 44 24 04 e7 03 00 	movl   $0x3e7,0x4(%esp)
f0102e17:	00 
f0102e18:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102e1f:	e8 9a d2 ff ff       	call   f01000be <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e24:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102e2b:	00 
f0102e2c:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102e31:	89 04 24             	mov    %eax,(%esp)
f0102e34:	e8 1e e4 ff ff       	call   f0101257 <page_remove>
	assert(pp2->pp_ref == 0);
f0102e39:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102e3e:	74 24                	je     f0102e64 <mem_init+0x1aff>
f0102e40:	c7 44 24 0c 57 5b 10 	movl   $0xf0105b57,0xc(%esp)
f0102e47:	f0 
f0102e48:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102e4f:	f0 
f0102e50:	c7 44 24 04 e9 03 00 	movl   $0x3e9,0x4(%esp)
f0102e57:	00 
f0102e58:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102e5f:	e8 5a d2 ff ff       	call   f01000be <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e64:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0102e69:	8b 08                	mov    (%eax),%ecx
f0102e6b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct Page *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e71:	89 f2                	mov    %esi,%edx
f0102e73:	2b 15 2c dd 17 f0    	sub    0xf017dd2c,%edx
f0102e79:	c1 fa 03             	sar    $0x3,%edx
f0102e7c:	c1 e2 0c             	shl    $0xc,%edx
f0102e7f:	39 d1                	cmp    %edx,%ecx
f0102e81:	74 24                	je     f0102ea7 <mem_init+0x1b42>
f0102e83:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f0102e8a:	f0 
f0102e8b:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102e92:	f0 
f0102e93:	c7 44 24 04 ec 03 00 	movl   $0x3ec,0x4(%esp)
f0102e9a:	00 
f0102e9b:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102ea2:	e8 17 d2 ff ff       	call   f01000be <_panic>
	kern_pgdir[0] = 0;
f0102ea7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102ead:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102eb2:	74 24                	je     f0102ed8 <mem_init+0x1b73>
f0102eb4:	c7 44 24 0c 0e 5b 10 	movl   $0xf0105b0e,0xc(%esp)
f0102ebb:	f0 
f0102ebc:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0102ec3:	f0 
f0102ec4:	c7 44 24 04 ee 03 00 	movl   $0x3ee,0x4(%esp)
f0102ecb:	00 
f0102ecc:	c7 04 24 c1 58 10 f0 	movl   $0xf01058c1,(%esp)
f0102ed3:	e8 e6 d1 ff ff       	call   f01000be <_panic>
	pp0->pp_ref = 0;
f0102ed8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102ede:	89 34 24             	mov    %esi,(%esp)
f0102ee1:	e8 83 e0 ff ff       	call   f0100f69 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ee6:	c7 04 24 60 58 10 f0 	movl   $0xf0105860,(%esp)
f0102eed:	e8 58 08 00 00       	call   f010374a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102ef2:	83 c4 3c             	add    $0x3c,%esp
f0102ef5:	5b                   	pop    %ebx
f0102ef6:	5e                   	pop    %esi
f0102ef7:	5f                   	pop    %edi
f0102ef8:	5d                   	pop    %ebp
f0102ef9:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102efa:	89 f2                	mov    %esi,%edx
f0102efc:	89 d8                	mov    %ebx,%eax
f0102efe:	e8 55 da ff ff       	call   f0100958 <check_va2pa>
f0102f03:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f09:	e9 8e fa ff ff       	jmp    f010299c <mem_init+0x1637>

f0102f0e <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102f0e:	55                   	push   %ebp
f0102f0f:	89 e5                	mov    %esp,%ebp
	// LAB 3: Your code here.

	return 0;
}
f0102f11:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f16:	5d                   	pop    %ebp
f0102f17:	c3                   	ret    

f0102f18 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f18:	55                   	push   %ebp
f0102f19:	89 e5                	mov    %esp,%ebp
f0102f1b:	53                   	push   %ebx
f0102f1c:	83 ec 14             	sub    $0x14,%esp
f0102f1f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f22:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f25:	83 c8 04             	or     $0x4,%eax
f0102f28:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f2c:	8b 45 10             	mov    0x10(%ebp),%eax
f0102f2f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f33:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f36:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f3a:	89 1c 24             	mov    %ebx,(%esp)
f0102f3d:	e8 cc ff ff ff       	call   f0102f0e <user_mem_check>
f0102f42:	85 c0                	test   %eax,%eax
f0102f44:	79 23                	jns    f0102f69 <user_mem_assert+0x51>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f46:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102f4d:	00 
f0102f4e:	8b 43 48             	mov    0x48(%ebx),%eax
f0102f51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f55:	c7 04 24 8c 58 10 f0 	movl   $0xf010588c,(%esp)
f0102f5c:	e8 e9 07 00 00       	call   f010374a <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f61:	89 1c 24             	mov    %ebx,(%esp)
f0102f64:	e8 a9 06 00 00       	call   f0103612 <env_destroy>
	}
}
f0102f69:	83 c4 14             	add    $0x14,%esp
f0102f6c:	5b                   	pop    %ebx
f0102f6d:	5d                   	pop    %ebp
f0102f6e:	c3                   	ret    
	...

f0102f70 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f70:	55                   	push   %ebp
f0102f71:	89 e5                	mov    %esp,%ebp
f0102f73:	57                   	push   %edi
f0102f74:	56                   	push   %esi
f0102f75:	53                   	push   %ebx
f0102f76:	83 ec 1c             	sub    $0x1c,%esp
f0102f79:	89 c6                	mov    %eax,%esi
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
    uintptr_t left, right, i;
    struct Page* p;
    left = ROUNDDOWN((uintptr_t)va, PGSIZE); 
f0102f7b:	89 d3                	mov    %edx,%ebx
f0102f7d:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    right = ROUNDUP((uintptr_t)va + len, PGSIZE);
f0102f83:	8d bc 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%edi
f0102f8a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    for (i = left; i <= right; i+=PGSIZE) {
f0102f90:	39 fb                	cmp    %edi,%ebx
f0102f92:	77 75                	ja     f0103009 <region_alloc+0x99>
        p = page_alloc(0);
f0102f94:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102f9b:	e8 4b df ff ff       	call   f0100eeb <page_alloc>
        if (p == NULL)
f0102fa0:	85 c0                	test   %eax,%eax
f0102fa2:	75 1c                	jne    f0102fc0 <region_alloc+0x50>
            panic("region_alloc fail");
f0102fa4:	c7 44 24 08 f1 5b 10 	movl   $0xf0105bf1,0x8(%esp)
f0102fab:	f0 
f0102fac:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0102fb3:	00 
f0102fb4:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0102fbb:	e8 fe d0 ff ff       	call   f01000be <_panic>
        int r = page_insert(e->env_pgdir, p, (void*)i, PTE_U | PTE_W);
f0102fc0:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102fc7:	00 
f0102fc8:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102fcc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fd0:	8b 46 5c             	mov    0x5c(%esi),%eax
f0102fd3:	89 04 24             	mov    %eax,(%esp)
f0102fd6:	e8 cc e2 ff ff       	call   f01012a7 <page_insert>
        if (r != 0)
f0102fdb:	85 c0                	test   %eax,%eax
f0102fdd:	74 20                	je     f0102fff <region_alloc+0x8f>
            panic("page_insert failed() : %e", r);
f0102fdf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102fe3:	c7 44 24 08 0e 5c 10 	movl   $0xf0105c0e,0x8(%esp)
f0102fea:	f0 
f0102feb:	c7 44 24 04 23 01 00 	movl   $0x123,0x4(%esp)
f0102ff2:	00 
f0102ff3:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0102ffa:	e8 bf d0 ff ff       	call   f01000be <_panic>
	//   (Watch out for corner-cases!)
    uintptr_t left, right, i;
    struct Page* p;
    left = ROUNDDOWN((uintptr_t)va, PGSIZE); 
    right = ROUNDUP((uintptr_t)va + len, PGSIZE);
    for (i = left; i <= right; i+=PGSIZE) {
f0102fff:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103005:	39 df                	cmp    %ebx,%edi
f0103007:	73 8b                	jae    f0102f94 <region_alloc+0x24>
            panic("region_alloc fail");
        int r = page_insert(e->env_pgdir, p, (void*)i, PTE_U | PTE_W);
        if (r != 0)
            panic("page_insert failed() : %e", r);
    }
}
f0103009:	83 c4 1c             	add    $0x1c,%esp
f010300c:	5b                   	pop    %ebx
f010300d:	5e                   	pop    %esi
f010300e:	5f                   	pop    %edi
f010300f:	5d                   	pop    %ebp
f0103010:	c3                   	ret    

f0103011 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0103011:	55                   	push   %ebp
f0103012:	89 e5                	mov    %esp,%ebp
f0103014:	53                   	push   %ebx
f0103015:	8b 45 08             	mov    0x8(%ebp),%eax
f0103018:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f010301b:	85 c0                	test   %eax,%eax
f010301d:	75 0e                	jne    f010302d <envid2env+0x1c>
		*env_store = curenv;
f010301f:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103024:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103026:	b8 00 00 00 00       	mov    $0x0,%eax
f010302b:	eb 57                	jmp    f0103084 <envid2env+0x73>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010302d:	89 c2                	mov    %eax,%edx
f010302f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0103035:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103038:	c1 e2 05             	shl    $0x5,%edx
f010303b:	03 15 88 d0 17 f0    	add    0xf017d088,%edx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103041:	83 7a 54 00          	cmpl   $0x0,0x54(%edx)
f0103045:	74 05                	je     f010304c <envid2env+0x3b>
f0103047:	39 42 48             	cmp    %eax,0x48(%edx)
f010304a:	74 0d                	je     f0103059 <envid2env+0x48>
		*env_store = 0;
f010304c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0103052:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103057:	eb 2b                	jmp    f0103084 <envid2env+0x73>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103059:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010305d:	74 1e                	je     f010307d <envid2env+0x6c>
f010305f:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103064:	39 c2                	cmp    %eax,%edx
f0103066:	74 15                	je     f010307d <envid2env+0x6c>
f0103068:	8b 58 48             	mov    0x48(%eax),%ebx
f010306b:	39 5a 4c             	cmp    %ebx,0x4c(%edx)
f010306e:	74 0d                	je     f010307d <envid2env+0x6c>
		*env_store = 0;
f0103070:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		return -E_BAD_ENV;
f0103076:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010307b:	eb 07                	jmp    f0103084 <envid2env+0x73>
	}

	*env_store = e;
f010307d:	89 11                	mov    %edx,(%ecx)
	return 0;
f010307f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103084:	5b                   	pop    %ebx
f0103085:	5d                   	pop    %ebp
f0103086:	c3                   	ret    

f0103087 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103087:	55                   	push   %ebp
f0103088:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010308a:	b8 00 b3 11 f0       	mov    $0xf011b300,%eax
f010308f:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103092:	b8 23 00 00 00       	mov    $0x23,%eax
f0103097:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0103099:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010309b:	b0 10                	mov    $0x10,%al
f010309d:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f010309f:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030a1:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030a3:	ea aa 30 10 f0 08 00 	ljmp   $0x8,$0xf01030aa
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030aa:	b0 00                	mov    $0x0,%al
f01030ac:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030af:	5d                   	pop    %ebp
f01030b0:	c3                   	ret    

f01030b1 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030b1:	55                   	push   %ebp
f01030b2:	89 e5                	mov    %esp,%ebp
f01030b4:	56                   	push   %esi
f01030b5:	53                   	push   %ebx
	// LAB 3: Your code here.
    ssize_t i;
    env_free_list = NULL;
    
    for (i = NENV -1; i >= 0; i--) {
        envs[i].env_link = env_free_list;
f01030b6:	8b 35 88 d0 17 f0    	mov    0xf017d088,%esi
// Make sure the environments are in the free list in the same order
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
f01030bc:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01030c2:	ba 00 04 00 00       	mov    $0x400,%edx
f01030c7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01030cc:	eb 02                	jmp    f01030d0 <env_init+0x1f>
    for (i = NENV -1; i >= 0; i--) {
        envs[i].env_link = env_free_list;
        envs[i].env_id = 0;
        envs[i].env_parent_id = 0;
        envs[i].env_status = ENV_FREE;
        env_free_list = &envs[i];
f01030ce:	89 d9                	mov    %ebx,%ecx
	// LAB 3: Your code here.
    ssize_t i;
    env_free_list = NULL;
    
    for (i = NENV -1; i >= 0; i--) {
        envs[i].env_link = env_free_list;
f01030d0:	89 c3                	mov    %eax,%ebx
f01030d2:	89 48 44             	mov    %ecx,0x44(%eax)
        envs[i].env_id = 0;
f01030d5:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
        envs[i].env_parent_id = 0;
f01030dc:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
        envs[i].env_status = ENV_FREE;
f01030e3:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
f01030ea:	83 e8 60             	sub    $0x60,%eax
	// Set up envs array
	// LAB 3: Your code here.
    ssize_t i;
    env_free_list = NULL;
    
    for (i = NENV -1; i >= 0; i--) {
f01030ed:	83 ea 01             	sub    $0x1,%edx
f01030f0:	75 dc                	jne    f01030ce <env_init+0x1d>
f01030f2:	89 35 8c d0 17 f0    	mov    %esi,0xf017d08c
        envs[i].env_parent_id = 0;
        envs[i].env_status = ENV_FREE;
        env_free_list = &envs[i];
    }
	// Per-CPU part of the initialization
	env_init_percpu();
f01030f8:	e8 8a ff ff ff       	call   f0103087 <env_init_percpu>
}
f01030fd:	5b                   	pop    %ebx
f01030fe:	5e                   	pop    %esi
f01030ff:	5d                   	pop    %ebp
f0103100:	c3                   	ret    

f0103101 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103101:	55                   	push   %ebp
f0103102:	89 e5                	mov    %esp,%ebp
f0103104:	53                   	push   %ebx
f0103105:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103108:	8b 1d 8c d0 17 f0    	mov    0xf017d08c,%ebx
f010310e:	85 db                	test   %ebx,%ebx
f0103110:	0f 84 9b 01 00 00    	je     f01032b1 <env_alloc+0x1b0>
{
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103116:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010311d:	e8 c9 dd ff ff       	call   f0100eeb <page_alloc>
f0103122:	85 c0                	test   %eax,%eax
f0103124:	0f 84 8e 01 00 00    	je     f01032b8 <env_alloc+0x1b7>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
    p->pp_ref++;
f010312a:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f010312f:	2b 05 2c dd 17 f0    	sub    0xf017dd2c,%eax
f0103135:	c1 f8 03             	sar    $0x3,%eax
f0103138:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010313b:	89 c2                	mov    %eax,%edx
f010313d:	c1 ea 0c             	shr    $0xc,%edx
f0103140:	3b 15 24 dd 17 f0    	cmp    0xf017dd24,%edx
f0103146:	72 20                	jb     f0103168 <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103148:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010314c:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f0103153:	f0 
f0103154:	c7 44 24 04 56 00 00 	movl   $0x56,0x4(%esp)
f010315b:	00 
f010315c:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f0103163:	e8 56 cf ff ff       	call   f01000be <_panic>
	return (void *)(pa + KERNBASE);
f0103168:	2d 00 00 00 10       	sub    $0x10000000,%eax
    e->env_pgdir = page2kva(p);
f010316d:	89 43 5c             	mov    %eax,0x5c(%ebx)
    memset(page2kva(p), 0, PGSIZE);
f0103170:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103177:	00 
f0103178:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010317f:	00 
f0103180:	89 04 24             	mov    %eax,(%esp)
f0103183:	e8 89 15 00 00       	call   f0104711 <memset>

    memmove(e->env_pgdir, kern_pgdir, PGSIZE);
f0103188:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010318f:	00 
f0103190:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
f0103195:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103199:	8b 43 5c             	mov    0x5c(%ebx),%eax
f010319c:	89 04 24             	mov    %eax,(%esp)
f010319f:	e8 c8 15 00 00       	call   f010476c <memmove>
    memset(e->env_pgdir, 0, sizeof(pde_t) * PDX(UTOP));
f01031a4:	c7 44 24 08 ec 0e 00 	movl   $0xeec,0x8(%esp)
f01031ab:	00 
f01031ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01031b3:	00 
f01031b4:	8b 43 5c             	mov    0x5c(%ebx),%eax
f01031b7:	89 04 24             	mov    %eax,(%esp)
f01031ba:	e8 52 15 00 00       	call   f0104711 <memset>

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01031bf:	8b 43 5c             	mov    0x5c(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031c2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031c7:	77 20                	ja     f01031e9 <env_alloc+0xe8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031cd:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01031d4:	f0 
f01031d5:	c7 44 24 04 c4 00 00 	movl   $0xc4,0x4(%esp)
f01031dc:	00 
f01031dd:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f01031e4:	e8 d5 ce ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01031e9:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031ef:	83 ca 05             	or     $0x5,%edx
f01031f2:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031f8:	8b 43 48             	mov    0x48(%ebx),%eax
f01031fb:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103200:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103205:	ba 00 10 00 00       	mov    $0x1000,%edx
f010320a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010320d:	89 da                	mov    %ebx,%edx
f010320f:	2b 15 88 d0 17 f0    	sub    0xf017d088,%edx
f0103215:	c1 fa 05             	sar    $0x5,%edx
f0103218:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010321e:	09 d0                	or     %edx,%eax
f0103220:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103223:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103226:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103229:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103230:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
	e->env_runs = 0;
f0103237:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010323e:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103245:	00 
f0103246:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010324d:	00 
f010324e:	89 1c 24             	mov    %ebx,(%esp)
f0103251:	e8 bb 14 00 00       	call   f0104711 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103256:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f010325c:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103262:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103268:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f010326f:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// commit the allocation
	env_free_list = e->env_link;
f0103275:	8b 43 44             	mov    0x44(%ebx),%eax
f0103278:	a3 8c d0 17 f0       	mov    %eax,0xf017d08c
	*newenv_store = e;
f010327d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103280:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103282:	8b 4b 48             	mov    0x48(%ebx),%ecx
f0103285:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f010328a:	ba 00 00 00 00       	mov    $0x0,%edx
f010328f:	85 c0                	test   %eax,%eax
f0103291:	74 03                	je     f0103296 <env_alloc+0x195>
f0103293:	8b 50 48             	mov    0x48(%eax),%edx
f0103296:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010329a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010329e:	c7 04 24 28 5c 10 f0 	movl   $0xf0105c28,(%esp)
f01032a5:	e8 a0 04 00 00       	call   f010374a <cprintf>
	return 0;
f01032aa:	b8 00 00 00 00       	mov    $0x0,%eax
f01032af:	eb 0c                	jmp    f01032bd <env_alloc+0x1bc>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f01032b1:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01032b6:	eb 05                	jmp    f01032bd <env_alloc+0x1bc>
	int i;
	struct Page *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f01032b8:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f01032bd:	83 c4 14             	add    $0x14,%esp
f01032c0:	5b                   	pop    %ebx
f01032c1:	5d                   	pop    %ebp
f01032c2:	c3                   	ret    

f01032c3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, size_t size, enum EnvType type)
{
f01032c3:	55                   	push   %ebp
f01032c4:	89 e5                	mov    %esp,%ebp
f01032c6:	57                   	push   %edi
f01032c7:	56                   	push   %esi
f01032c8:	53                   	push   %ebx
f01032c9:	83 ec 3c             	sub    $0x3c,%esp
f01032cc:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
    struct Env* env;
    int r = env_alloc(&env, 0);
f01032cf:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01032d6:	00 
f01032d7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01032da:	89 04 24             	mov    %eax,(%esp)
f01032dd:	e8 1f fe ff ff       	call   f0103101 <env_alloc>
    
    if (r != 0)
f01032e2:	85 c0                	test   %eax,%eax
f01032e4:	74 20                	je     f0103306 <env_create+0x43>
        panic("env_alloc failed() : %e", r);
f01032e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032ea:	c7 44 24 08 3d 5c 10 	movl   $0xf0105c3d,0x8(%esp)
f01032f1:	f0 
f01032f2:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
f01032f9:	00 
f01032fa:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0103301:	e8 b8 cd ff ff       	call   f01000be <_panic>
    
    load_icode(env, binary, size);
f0103306:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103309:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	//  to make sure that the environment starts executing there.
	//  What?  (See env_run() and env_pop_tf() below.)

	// LAB 3: Your code here.
    struct Elf* elf = (struct Elf*)binary;     
	if (elf->e_magic != ELF_MAGIC)
f010330c:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103312:	0f 85 f6 00 00 00    	jne    f010340e <env_create+0x14b>
		goto bad;

	// load each program segment (ignores ph flags)
	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0103318:	8b 5f 1c             	mov    0x1c(%edi),%ebx
	eph = ph + elf->e_phnum;
f010331b:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
    lcr3(PADDR(e->env_pgdir));
f010331f:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103322:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103327:	77 20                	ja     f0103349 <env_create+0x86>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103329:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010332d:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0103334:	f0 
f0103335:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f010333c:	00 
f010333d:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0103344:	e8 75 cd ff ff       	call   f01000be <_panic>
	if (elf->e_magic != ELF_MAGIC)
		goto bad;

	// load each program segment (ignores ph flags)
	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
f0103349:	01 fb                	add    %edi,%ebx
	eph = ph + elf->e_phnum;
f010334b:	0f b7 f6             	movzwl %si,%esi
f010334e:	c1 e6 05             	shl    $0x5,%esi
f0103351:	01 de                	add    %ebx,%esi
	return (physaddr_t)kva - KERNBASE;
f0103353:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103358:	0f 22 d8             	mov    %eax,%cr3
    lcr3(PADDR(e->env_pgdir));
	for (; ph < eph; ph++) {
f010335b:	39 f3                	cmp    %esi,%ebx
f010335d:	73 4f                	jae    f01033ae <env_create+0xeb>
        if (ph->p_type == ELF_PROG_LOAD) {
f010335f:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103362:	75 43                	jne    f01033a7 <env_create+0xe4>
            region_alloc(e, (void*)ph->p_va, ph->p_memsz);
f0103364:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103367:	8b 53 08             	mov    0x8(%ebx),%edx
f010336a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010336d:	e8 fe fb ff ff       	call   f0102f70 <region_alloc>
            memset((void*)ph->p_va, 0, ph->p_memsz); 
f0103372:	8b 43 14             	mov    0x14(%ebx),%eax
f0103375:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103379:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103380:	00 
f0103381:	8b 43 08             	mov    0x8(%ebx),%eax
f0103384:	89 04 24             	mov    %eax,(%esp)
f0103387:	e8 85 13 00 00       	call   f0104711 <memset>
            memmove((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz);
f010338c:	8b 43 10             	mov    0x10(%ebx),%eax
f010338f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103393:	89 f8                	mov    %edi,%eax
f0103395:	03 43 04             	add    0x4(%ebx),%eax
f0103398:	89 44 24 04          	mov    %eax,0x4(%esp)
f010339c:	8b 43 08             	mov    0x8(%ebx),%eax
f010339f:	89 04 24             	mov    %eax,(%esp)
f01033a2:	e8 c5 13 00 00       	call   f010476c <memmove>
	// load each program segment (ignores ph flags)
	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *) ((uint8_t *) elf + elf->e_phoff);
	eph = ph + elf->e_phnum;
    lcr3(PADDR(e->env_pgdir));
	for (; ph < eph; ph++) {
f01033a7:	83 c3 20             	add    $0x20,%ebx
f01033aa:	39 de                	cmp    %ebx,%esi
f01033ac:	77 b1                	ja     f010335f <env_create+0x9c>
            region_alloc(e, (void*)ph->p_va, ph->p_memsz);
            memset((void*)ph->p_va, 0, ph->p_memsz); 
            memmove((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz);
        }
    }
    lcr3(PADDR(kern_pgdir));
f01033ae:	a1 28 dd 17 f0       	mov    0xf017dd28,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033b8:	77 20                	ja     f01033da <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033be:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01033c5:	f0 
f01033c6:	c7 44 24 04 6d 01 00 	movl   $0x16d,0x4(%esp)
f01033cd:	00 
f01033ce:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f01033d5:	e8 e4 cc ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033da:	05 00 00 00 10       	add    $0x10000000,%eax
f01033df:	0f 22 d8             	mov    %eax,%cr3

    e->env_tf.tf_eip = elf->e_entry;
f01033e2:	8b 47 18             	mov    0x18(%edi),%eax
f01033e5:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01033e8:	89 42 30             	mov    %eax,0x30(%edx)
	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
    region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f01033eb:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01033f0:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01033f5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01033f8:	e8 73 fb ff ff       	call   f0102f70 <region_alloc>
    
    if (r != 0)
        panic("env_alloc failed() : %e", r);
    
    load_icode(env, binary, size);
    env->env_type = type;
f01033fd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103400:	8b 55 10             	mov    0x10(%ebp),%edx
f0103403:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103406:	83 c4 3c             	add    $0x3c,%esp
f0103409:	5b                   	pop    %ebx
f010340a:	5e                   	pop    %esi
f010340b:	5f                   	pop    %edi
f010340c:	5d                   	pop    %ebp
f010340d:	c3                   	ret    

	// LAB 3: Your code here.
    region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
    return ;
bad:
    panic("load_icode() failed");
f010340e:	c7 44 24 08 55 5c 10 	movl   $0xf0105c55,0x8(%esp)
f0103415:	f0 
f0103416:	c7 44 24 04 77 01 00 	movl   $0x177,0x4(%esp)
f010341d:	00 
f010341e:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0103425:	e8 94 cc ff ff       	call   f01000be <_panic>

f010342a <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f010342a:	55                   	push   %ebp
f010342b:	89 e5                	mov    %esp,%ebp
f010342d:	57                   	push   %edi
f010342e:	56                   	push   %esi
f010342f:	53                   	push   %ebx
f0103430:	83 ec 2c             	sub    $0x2c,%esp
f0103433:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103436:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f010343b:	39 c7                	cmp    %eax,%edi
f010343d:	75 37                	jne    f0103476 <env_free+0x4c>
		lcr3(PADDR(kern_pgdir));
f010343f:	8b 15 28 dd 17 f0    	mov    0xf017dd28,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103445:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f010344b:	77 20                	ja     f010346d <env_free+0x43>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010344d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103451:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f0103458:	f0 
f0103459:	c7 44 24 04 9d 01 00 	movl   $0x19d,0x4(%esp)
f0103460:	00 
f0103461:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0103468:	e8 51 cc ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f010346d:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103473:	0f 22 da             	mov    %edx,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103476:	8b 4f 48             	mov    0x48(%edi),%ecx
f0103479:	ba 00 00 00 00       	mov    $0x0,%edx
f010347e:	85 c0                	test   %eax,%eax
f0103480:	74 03                	je     f0103485 <env_free+0x5b>
f0103482:	8b 50 48             	mov    0x48(%eax),%edx
f0103485:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103489:	89 54 24 04          	mov    %edx,0x4(%esp)
f010348d:	c7 04 24 69 5c 10 f0 	movl   $0xf0105c69,(%esp)
f0103494:	e8 b1 02 00 00       	call   f010374a <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103499:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01034a0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034a3:	c1 e0 02             	shl    $0x2,%eax
f01034a6:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01034a9:	8b 47 5c             	mov    0x5c(%edi),%eax
f01034ac:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034af:	8b 34 90             	mov    (%eax,%edx,4),%esi
f01034b2:	f7 c6 01 00 00 00    	test   $0x1,%esi
f01034b8:	0f 84 b8 00 00 00    	je     f0103576 <env_free+0x14c>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f01034be:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034c4:	89 f0                	mov    %esi,%eax
f01034c6:	c1 e8 0c             	shr    $0xc,%eax
f01034c9:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01034cc:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f01034d2:	72 20                	jb     f01034f4 <env_free+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01034d4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01034d8:	c7 44 24 08 24 51 10 	movl   $0xf0105124,0x8(%esp)
f01034df:	f0 
f01034e0:	c7 44 24 04 ac 01 00 	movl   $0x1ac,0x4(%esp)
f01034e7:	00 
f01034e8:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f01034ef:	e8 ca cb ff ff       	call   f01000be <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01034f4:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01034f7:	c1 e2 16             	shl    $0x16,%edx
f01034fa:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034fd:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103502:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103509:	01 
f010350a:	74 17                	je     f0103523 <env_free+0xf9>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010350c:	89 d8                	mov    %ebx,%eax
f010350e:	c1 e0 0c             	shl    $0xc,%eax
f0103511:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103514:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103518:	8b 47 5c             	mov    0x5c(%edi),%eax
f010351b:	89 04 24             	mov    %eax,(%esp)
f010351e:	e8 34 dd ff ff       	call   f0101257 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103523:	83 c3 01             	add    $0x1,%ebx
f0103526:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f010352c:	75 d4                	jne    f0103502 <env_free+0xd8>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f010352e:	8b 47 5c             	mov    0x5c(%edi),%eax
f0103531:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103534:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010353b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010353e:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f0103544:	72 1c                	jb     f0103562 <env_free+0x138>
		panic("pa2page called with invalid pa");
f0103546:	c7 44 24 08 7c 52 10 	movl   $0xf010527c,0x8(%esp)
f010354d:	f0 
f010354e:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f0103555:	00 
f0103556:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f010355d:	e8 5c cb ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f0103562:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103565:	c1 e0 03             	shl    $0x3,%eax
f0103568:	03 05 2c dd 17 f0    	add    0xf017dd2c,%eax
		page_decref(pa2page(pa));
f010356e:	89 04 24             	mov    %eax,(%esp)
f0103571:	e8 32 da ff ff       	call   f0100fa8 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103576:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010357a:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103581:	0f 85 19 ff ff ff    	jne    f01034a0 <env_free+0x76>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103587:	8b 47 5c             	mov    0x5c(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010358a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010358f:	77 20                	ja     f01035b1 <env_free+0x187>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103591:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103595:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f010359c:	f0 
f010359d:	c7 44 24 04 ba 01 00 	movl   $0x1ba,0x4(%esp)
f01035a4:	00 
f01035a5:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f01035ac:	e8 0d cb ff ff       	call   f01000be <_panic>
	e->env_pgdir = 0;
f01035b1:	c7 47 5c 00 00 00 00 	movl   $0x0,0x5c(%edi)
	return (physaddr_t)kva - KERNBASE;
f01035b8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct Page*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01035bd:	c1 e8 0c             	shr    $0xc,%eax
f01035c0:	3b 05 24 dd 17 f0    	cmp    0xf017dd24,%eax
f01035c6:	72 1c                	jb     f01035e4 <env_free+0x1ba>
		panic("pa2page called with invalid pa");
f01035c8:	c7 44 24 08 7c 52 10 	movl   $0xf010527c,0x8(%esp)
f01035cf:	f0 
f01035d0:	c7 44 24 04 4f 00 00 	movl   $0x4f,0x4(%esp)
f01035d7:	00 
f01035d8:	c7 04 24 e2 58 10 f0 	movl   $0xf01058e2,(%esp)
f01035df:	e8 da ca ff ff       	call   f01000be <_panic>
	return &pages[PGNUM(pa)];
f01035e4:	c1 e0 03             	shl    $0x3,%eax
f01035e7:	03 05 2c dd 17 f0    	add    0xf017dd2c,%eax
	page_decref(pa2page(pa));
f01035ed:	89 04 24             	mov    %eax,(%esp)
f01035f0:	e8 b3 d9 ff ff       	call   f0100fa8 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01035f5:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01035fc:	a1 8c d0 17 f0       	mov    0xf017d08c,%eax
f0103601:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103604:	89 3d 8c d0 17 f0    	mov    %edi,0xf017d08c
}
f010360a:	83 c4 2c             	add    $0x2c,%esp
f010360d:	5b                   	pop    %ebx
f010360e:	5e                   	pop    %esi
f010360f:	5f                   	pop    %edi
f0103610:	5d                   	pop    %ebp
f0103611:	c3                   	ret    

f0103612 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103612:	55                   	push   %ebp
f0103613:	89 e5                	mov    %esp,%ebp
f0103615:	83 ec 18             	sub    $0x18,%esp
	env_free(e);
f0103618:	8b 45 08             	mov    0x8(%ebp),%eax
f010361b:	89 04 24             	mov    %eax,(%esp)
f010361e:	e8 07 fe ff ff       	call   f010342a <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103623:	c7 04 24 8c 5c 10 f0 	movl   $0xf0105c8c,(%esp)
f010362a:	e8 1b 01 00 00       	call   f010374a <cprintf>
	while (1)
		monitor(NULL);
f010362f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103636:	e8 cd d1 ff ff       	call   f0100808 <monitor>
f010363b:	eb f2                	jmp    f010362f <env_destroy+0x1d>

f010363d <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f010363d:	55                   	push   %ebp
f010363e:	89 e5                	mov    %esp,%ebp
f0103640:	83 ec 18             	sub    $0x18,%esp
	__asm __volatile("movl %0,%%esp\n"
f0103643:	8b 65 08             	mov    0x8(%ebp),%esp
f0103646:	61                   	popa   
f0103647:	07                   	pop    %es
f0103648:	1f                   	pop    %ds
f0103649:	83 c4 08             	add    $0x8,%esp
f010364c:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f010364d:	c7 44 24 08 7f 5c 10 	movl   $0xf0105c7f,0x8(%esp)
f0103654:	f0 
f0103655:	c7 44 24 04 e2 01 00 	movl   $0x1e2,0x4(%esp)
f010365c:	00 
f010365d:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f0103664:	e8 55 ca ff ff       	call   f01000be <_panic>

f0103669 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103669:	55                   	push   %ebp
f010366a:	89 e5                	mov    %esp,%ebp
f010366c:	83 ec 18             	sub    $0x18,%esp
f010366f:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
    if (e != curenv) {
f0103672:	8b 15 84 d0 17 f0    	mov    0xf017d084,%edx
f0103678:	39 d0                	cmp    %edx,%eax
f010367a:	74 53                	je     f01036cf <env_run+0x66>
        if (curenv != NULL && curenv->env_status == ENV_RUNNING)
f010367c:	85 d2                	test   %edx,%edx
f010367e:	74 0d                	je     f010368d <env_run+0x24>
f0103680:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0103684:	75 07                	jne    f010368d <env_run+0x24>
            curenv->env_status = ENV_RUNNABLE;
f0103686:	c7 42 54 01 00 00 00 	movl   $0x1,0x54(%edx)
        curenv = e;
f010368d:	a3 84 d0 17 f0       	mov    %eax,0xf017d084
        curenv->env_status = ENV_RUNNING;
f0103692:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
        curenv->env_runs++ ;
f0103699:	83 40 58 01          	addl   $0x1,0x58(%eax)
        lcr3(PADDR(curenv->env_pgdir));
f010369d:	8b 40 5c             	mov    0x5c(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036a0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036a5:	77 20                	ja     f01036c7 <env_run+0x5e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01036ab:	c7 44 24 08 30 52 10 	movl   $0xf0105230,0x8(%esp)
f01036b2:	f0 
f01036b3:	c7 44 24 04 06 02 00 	movl   $0x206,0x4(%esp)
f01036ba:	00 
f01036bb:	c7 04 24 03 5c 10 f0 	movl   $0xf0105c03,(%esp)
f01036c2:	e8 f7 c9 ff ff       	call   f01000be <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036c7:	05 00 00 00 10       	add    $0x10000000,%eax
f01036cc:	0f 22 d8             	mov    %eax,%cr3
    }

    env_pop_tf(&curenv->env_tf);
f01036cf:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f01036d4:	89 04 24             	mov    %eax,(%esp)
f01036d7:	e8 61 ff ff ff       	call   f010363d <env_pop_tf>

f01036dc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036dc:	55                   	push   %ebp
f01036dd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036df:	ba 70 00 00 00       	mov    $0x70,%edx
f01036e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036e7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036e8:	b2 71                	mov    $0x71,%dl
f01036ea:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036eb:	0f b6 c0             	movzbl %al,%eax
}
f01036ee:	5d                   	pop    %ebp
f01036ef:	c3                   	ret    

f01036f0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036f0:	55                   	push   %ebp
f01036f1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036f3:	ba 70 00 00 00       	mov    $0x70,%edx
f01036f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01036fb:	ee                   	out    %al,(%dx)
f01036fc:	b2 71                	mov    $0x71,%dl
f01036fe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103701:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103702:	5d                   	pop    %ebp
f0103703:	c3                   	ret    

f0103704 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103704:	55                   	push   %ebp
f0103705:	89 e5                	mov    %esp,%ebp
f0103707:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010370a:	8b 45 08             	mov    0x8(%ebp),%eax
f010370d:	89 04 24             	mov    %eax,(%esp)
f0103710:	e8 0d cf ff ff       	call   f0100622 <cputchar>
	*cnt++;
}
f0103715:	c9                   	leave  
f0103716:	c3                   	ret    

f0103717 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103717:	55                   	push   %ebp
f0103718:	89 e5                	mov    %esp,%ebp
f010371a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010371d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103724:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103727:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010372b:	8b 45 08             	mov    0x8(%ebp),%eax
f010372e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103732:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103735:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103739:	c7 04 24 04 37 10 f0 	movl   $0xf0103704,(%esp)
f0103740:	e8 c5 08 00 00       	call   f010400a <vprintfmt>
	return cnt;
}
f0103745:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103748:	c9                   	leave  
f0103749:	c3                   	ret    

f010374a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010374a:	55                   	push   %ebp
f010374b:	89 e5                	mov    %esp,%ebp
f010374d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103750:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103753:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103757:	8b 45 08             	mov    0x8(%ebp),%eax
f010375a:	89 04 24             	mov    %eax,(%esp)
f010375d:	e8 b5 ff ff ff       	call   f0103717 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103762:	c9                   	leave  
f0103763:	c3                   	ret    

f0103764 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103764:	55                   	push   %ebp
f0103765:	89 e5                	mov    %esp,%ebp
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103767:	c7 05 a4 d8 17 f0 00 	movl   $0xefc00000,0xf017d8a4
f010376e:	00 c0 ef 
	ts.ts_ss0 = GD_KD;
f0103771:	66 c7 05 a8 d8 17 f0 	movw   $0x10,0xf017d8a8
f0103778:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f010377a:	66 c7 05 48 b3 11 f0 	movw   $0x68,0xf011b348
f0103781:	68 00 
f0103783:	b8 a0 d8 17 f0       	mov    $0xf017d8a0,%eax
f0103788:	66 a3 4a b3 11 f0    	mov    %ax,0xf011b34a
f010378e:	89 c2                	mov    %eax,%edx
f0103790:	c1 ea 10             	shr    $0x10,%edx
f0103793:	88 15 4c b3 11 f0    	mov    %dl,0xf011b34c
f0103799:	c6 05 4e b3 11 f0 40 	movb   $0x40,0xf011b34e
f01037a0:	c1 e8 18             	shr    $0x18,%eax
f01037a3:	a2 4f b3 11 f0       	mov    %al,0xf011b34f
					sizeof(struct Taskstate), 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01037a8:	c6 05 4d b3 11 f0 89 	movb   $0x89,0xf011b34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01037af:	b8 28 00 00 00       	mov    $0x28,%eax
f01037b4:	0f 00 d8             	ltr    %ax
}  

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01037b7:	b8 50 b3 11 f0       	mov    $0xf011b350,%eax
f01037bc:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01037bf:	5d                   	pop    %ebp
f01037c0:	c3                   	ret    

f01037c1 <trap_init>:
}


void
trap_init(void)
{
f01037c1:	55                   	push   %ebp
f01037c2:	89 e5                	mov    %esp,%ebp
	extern struct Segdesc gdt[];

	// LAB 3: Your code here.

	// Per-CPU setup 
	trap_init_percpu();
f01037c4:	e8 9b ff ff ff       	call   f0103764 <trap_init_percpu>
}
f01037c9:	5d                   	pop    %ebp
f01037ca:	c3                   	ret    

f01037cb <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01037cb:	55                   	push   %ebp
f01037cc:	89 e5                	mov    %esp,%ebp
f01037ce:	53                   	push   %ebx
f01037cf:	83 ec 14             	sub    $0x14,%esp
f01037d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01037d5:	8b 03                	mov    (%ebx),%eax
f01037d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037db:	c7 04 24 c2 5c 10 f0 	movl   $0xf0105cc2,(%esp)
f01037e2:	e8 63 ff ff ff       	call   f010374a <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01037e7:	8b 43 04             	mov    0x4(%ebx),%eax
f01037ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037ee:	c7 04 24 d1 5c 10 f0 	movl   $0xf0105cd1,(%esp)
f01037f5:	e8 50 ff ff ff       	call   f010374a <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01037fa:	8b 43 08             	mov    0x8(%ebx),%eax
f01037fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103801:	c7 04 24 e0 5c 10 f0 	movl   $0xf0105ce0,(%esp)
f0103808:	e8 3d ff ff ff       	call   f010374a <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f010380d:	8b 43 0c             	mov    0xc(%ebx),%eax
f0103810:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103814:	c7 04 24 ef 5c 10 f0 	movl   $0xf0105cef,(%esp)
f010381b:	e8 2a ff ff ff       	call   f010374a <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103820:	8b 43 10             	mov    0x10(%ebx),%eax
f0103823:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103827:	c7 04 24 fe 5c 10 f0 	movl   $0xf0105cfe,(%esp)
f010382e:	e8 17 ff ff ff       	call   f010374a <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103833:	8b 43 14             	mov    0x14(%ebx),%eax
f0103836:	89 44 24 04          	mov    %eax,0x4(%esp)
f010383a:	c7 04 24 0d 5d 10 f0 	movl   $0xf0105d0d,(%esp)
f0103841:	e8 04 ff ff ff       	call   f010374a <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103846:	8b 43 18             	mov    0x18(%ebx),%eax
f0103849:	89 44 24 04          	mov    %eax,0x4(%esp)
f010384d:	c7 04 24 1c 5d 10 f0 	movl   $0xf0105d1c,(%esp)
f0103854:	e8 f1 fe ff ff       	call   f010374a <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103859:	8b 43 1c             	mov    0x1c(%ebx),%eax
f010385c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103860:	c7 04 24 2b 5d 10 f0 	movl   $0xf0105d2b,(%esp)
f0103867:	e8 de fe ff ff       	call   f010374a <cprintf>
}
f010386c:	83 c4 14             	add    $0x14,%esp
f010386f:	5b                   	pop    %ebx
f0103870:	5d                   	pop    %ebp
f0103871:	c3                   	ret    

f0103872 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103872:	55                   	push   %ebp
f0103873:	89 e5                	mov    %esp,%ebp
f0103875:	56                   	push   %esi
f0103876:	53                   	push   %ebx
f0103877:	83 ec 10             	sub    $0x10,%esp
f010387a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p\n", tf);
f010387d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103881:	c7 04 24 61 5e 10 f0 	movl   $0xf0105e61,(%esp)
f0103888:	e8 bd fe ff ff       	call   f010374a <cprintf>
	print_regs(&tf->tf_regs);
f010388d:	89 1c 24             	mov    %ebx,(%esp)
f0103890:	e8 36 ff ff ff       	call   f01037cb <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103895:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103899:	89 44 24 04          	mov    %eax,0x4(%esp)
f010389d:	c7 04 24 7c 5d 10 f0 	movl   $0xf0105d7c,(%esp)
f01038a4:	e8 a1 fe ff ff       	call   f010374a <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f01038a9:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f01038ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038b1:	c7 04 24 8f 5d 10 f0 	movl   $0xf0105d8f,(%esp)
f01038b8:	e8 8d fe ff ff       	call   f010374a <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038bd:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01038c0:	83 f8 13             	cmp    $0x13,%eax
f01038c3:	77 09                	ja     f01038ce <print_trapframe+0x5c>
		return excnames[trapno];
f01038c5:	8b 14 85 40 60 10 f0 	mov    -0xfef9fc0(,%eax,4),%edx
f01038cc:	eb 10                	jmp    f01038de <print_trapframe+0x6c>
	if (trapno == T_SYSCALL)
		return "System call";
f01038ce:	83 f8 30             	cmp    $0x30,%eax
f01038d1:	ba 3a 5d 10 f0       	mov    $0xf0105d3a,%edx
f01038d6:	b9 46 5d 10 f0       	mov    $0xf0105d46,%ecx
f01038db:	0f 45 d1             	cmovne %ecx,%edx
{
	cprintf("TRAP frame at %p\n", tf);
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01038de:	89 54 24 08          	mov    %edx,0x8(%esp)
f01038e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038e6:	c7 04 24 a2 5d 10 f0 	movl   $0xf0105da2,(%esp)
f01038ed:	e8 58 fe ff ff       	call   f010374a <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01038f2:	3b 1d 08 d9 17 f0    	cmp    0xf017d908,%ebx
f01038f8:	75 19                	jne    f0103913 <print_trapframe+0xa1>
f01038fa:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01038fe:	75 13                	jne    f0103913 <print_trapframe+0xa1>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103900:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103903:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103907:	c7 04 24 b4 5d 10 f0 	movl   $0xf0105db4,(%esp)
f010390e:	e8 37 fe ff ff       	call   f010374a <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f0103913:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103916:	89 44 24 04          	mov    %eax,0x4(%esp)
f010391a:	c7 04 24 c3 5d 10 f0 	movl   $0xf0105dc3,(%esp)
f0103921:	e8 24 fe ff ff       	call   f010374a <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103926:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f010392a:	75 51                	jne    f010397d <print_trapframe+0x10b>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f010392c:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010392f:	89 c2                	mov    %eax,%edx
f0103931:	83 e2 01             	and    $0x1,%edx
f0103934:	ba 55 5d 10 f0       	mov    $0xf0105d55,%edx
f0103939:	b9 60 5d 10 f0       	mov    $0xf0105d60,%ecx
f010393e:	0f 45 ca             	cmovne %edx,%ecx
f0103941:	89 c2                	mov    %eax,%edx
f0103943:	83 e2 02             	and    $0x2,%edx
f0103946:	ba 6c 5d 10 f0       	mov    $0xf0105d6c,%edx
f010394b:	be 72 5d 10 f0       	mov    $0xf0105d72,%esi
f0103950:	0f 44 d6             	cmove  %esi,%edx
f0103953:	83 e0 04             	and    $0x4,%eax
f0103956:	b8 77 5d 10 f0       	mov    $0xf0105d77,%eax
f010395b:	be 8c 5e 10 f0       	mov    $0xf0105e8c,%esi
f0103960:	0f 44 c6             	cmove  %esi,%eax
f0103963:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103967:	89 54 24 08          	mov    %edx,0x8(%esp)
f010396b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010396f:	c7 04 24 d1 5d 10 f0 	movl   $0xf0105dd1,(%esp)
f0103976:	e8 cf fd ff ff       	call   f010374a <cprintf>
f010397b:	eb 0c                	jmp    f0103989 <print_trapframe+0x117>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010397d:	c7 04 24 bf 5b 10 f0 	movl   $0xf0105bbf,(%esp)
f0103984:	e8 c1 fd ff ff       	call   f010374a <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103989:	8b 43 30             	mov    0x30(%ebx),%eax
f010398c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103990:	c7 04 24 e0 5d 10 f0 	movl   $0xf0105de0,(%esp)
f0103997:	e8 ae fd ff ff       	call   f010374a <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010399c:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f01039a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039a4:	c7 04 24 ef 5d 10 f0 	movl   $0xf0105def,(%esp)
f01039ab:	e8 9a fd ff ff       	call   f010374a <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01039b0:	8b 43 38             	mov    0x38(%ebx),%eax
f01039b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039b7:	c7 04 24 02 5e 10 f0 	movl   $0xf0105e02,(%esp)
f01039be:	e8 87 fd ff ff       	call   f010374a <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01039c3:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01039c7:	74 27                	je     f01039f0 <print_trapframe+0x17e>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01039c9:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01039cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039d0:	c7 04 24 11 5e 10 f0 	movl   $0xf0105e11,(%esp)
f01039d7:	e8 6e fd ff ff       	call   f010374a <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01039dc:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01039e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039e4:	c7 04 24 20 5e 10 f0 	movl   $0xf0105e20,(%esp)
f01039eb:	e8 5a fd ff ff       	call   f010374a <cprintf>
	}
}
f01039f0:	83 c4 10             	add    $0x10,%esp
f01039f3:	5b                   	pop    %ebx
f01039f4:	5e                   	pop    %esi
f01039f5:	5d                   	pop    %ebp
f01039f6:	c3                   	ret    

f01039f7 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f01039f7:	55                   	push   %ebp
f01039f8:	89 e5                	mov    %esp,%ebp
f01039fa:	57                   	push   %edi
f01039fb:	56                   	push   %esi
f01039fc:	83 ec 10             	sub    $0x10,%esp
f01039ff:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103a02:	fc                   	cld    

static __inline uint32_t
read_eflags(void)
{
        uint32_t eflags;
        __asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103a03:	9c                   	pushf  
f0103a04:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103a05:	f6 c4 02             	test   $0x2,%ah
f0103a08:	74 24                	je     f0103a2e <trap+0x37>
f0103a0a:	c7 44 24 0c 33 5e 10 	movl   $0xf0105e33,0xc(%esp)
f0103a11:	f0 
f0103a12:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0103a19:	f0 
f0103a1a:	c7 44 24 04 a7 00 00 	movl   $0xa7,0x4(%esp)
f0103a21:	00 
f0103a22:	c7 04 24 4c 5e 10 f0 	movl   $0xf0105e4c,(%esp)
f0103a29:	e8 90 c6 ff ff       	call   f01000be <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103a2e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103a32:	c7 04 24 58 5e 10 f0 	movl   $0xf0105e58,(%esp)
f0103a39:	e8 0c fd ff ff       	call   f010374a <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103a3e:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103a42:	83 e0 03             	and    $0x3,%eax
f0103a45:	83 f8 03             	cmp    $0x3,%eax
f0103a48:	75 3c                	jne    f0103a86 <trap+0x8f>
		// Trapped from user mode.
		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		assert(curenv);
f0103a4a:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103a4f:	85 c0                	test   %eax,%eax
f0103a51:	75 24                	jne    f0103a77 <trap+0x80>
f0103a53:	c7 44 24 0c 73 5e 10 	movl   $0xf0105e73,0xc(%esp)
f0103a5a:	f0 
f0103a5b:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0103a62:	f0 
f0103a63:	c7 44 24 04 b0 00 00 	movl   $0xb0,0x4(%esp)
f0103a6a:	00 
f0103a6b:	c7 04 24 4c 5e 10 f0 	movl   $0xf0105e4c,(%esp)
f0103a72:	e8 47 c6 ff ff       	call   f01000be <_panic>
		curenv->env_tf = *tf;
f0103a77:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103a7c:	89 c7                	mov    %eax,%edi
f0103a7e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103a80:	8b 35 84 d0 17 f0    	mov    0xf017d084,%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103a86:	89 35 08 d9 17 f0    	mov    %esi,0xf017d908
{
	// Handle processor exceptions.
	// LAB 3: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103a8c:	89 34 24             	mov    %esi,(%esp)
f0103a8f:	e8 de fd ff ff       	call   f0103872 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0103a94:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103a99:	75 1c                	jne    f0103ab7 <trap+0xc0>
		panic("unhandled trap in kernel");
f0103a9b:	c7 44 24 08 7a 5e 10 	movl   $0xf0105e7a,0x8(%esp)
f0103aa2:	f0 
f0103aa3:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f0103aaa:	00 
f0103aab:	c7 04 24 4c 5e 10 f0 	movl   $0xf0105e4c,(%esp)
f0103ab2:	e8 07 c6 ff ff       	call   f01000be <_panic>
	else {
		env_destroy(curenv);
f0103ab7:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103abc:	89 04 24             	mov    %eax,(%esp)
f0103abf:	e8 4e fb ff ff       	call   f0103612 <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0103ac4:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103ac9:	85 c0                	test   %eax,%eax
f0103acb:	74 06                	je     f0103ad3 <trap+0xdc>
f0103acd:	83 78 54 02          	cmpl   $0x2,0x54(%eax)
f0103ad1:	74 24                	je     f0103af7 <trap+0x100>
f0103ad3:	c7 44 24 0c d8 5f 10 	movl   $0xf0105fd8,0xc(%esp)
f0103ada:	f0 
f0103adb:	c7 44 24 08 cd 58 10 	movl   $0xf01058cd,0x8(%esp)
f0103ae2:	f0 
f0103ae3:	c7 44 24 04 be 00 00 	movl   $0xbe,0x4(%esp)
f0103aea:	00 
f0103aeb:	c7 04 24 4c 5e 10 f0 	movl   $0xf0105e4c,(%esp)
f0103af2:	e8 c7 c5 ff ff       	call   f01000be <_panic>
	env_run(curenv);
f0103af7:	89 04 24             	mov    %eax,(%esp)
f0103afa:	e8 6a fb ff ff       	call   f0103669 <env_run>

f0103aff <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103aff:	55                   	push   %ebp
f0103b00:	89 e5                	mov    %esp,%ebp
f0103b02:	53                   	push   %ebx
f0103b03:	83 ec 14             	sub    $0x14,%esp
f0103b06:	8b 5d 08             	mov    0x8(%ebp),%ebx

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103b09:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b0c:	8b 53 30             	mov    0x30(%ebx),%edx
f0103b0f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103b13:	89 44 24 08          	mov    %eax,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103b17:	a1 84 d0 17 f0       	mov    0xf017d084,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103b1c:	8b 40 48             	mov    0x48(%eax),%eax
f0103b1f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b23:	c7 04 24 04 60 10 f0 	movl   $0xf0106004,(%esp)
f0103b2a:	e8 1b fc ff ff       	call   f010374a <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103b2f:	89 1c 24             	mov    %ebx,(%esp)
f0103b32:	e8 3b fd ff ff       	call   f0103872 <print_trapframe>
	env_destroy(curenv);
f0103b37:	a1 84 d0 17 f0       	mov    0xf017d084,%eax
f0103b3c:	89 04 24             	mov    %eax,(%esp)
f0103b3f:	e8 ce fa ff ff       	call   f0103612 <env_destroy>
}
f0103b44:	83 c4 14             	add    $0x14,%esp
f0103b47:	5b                   	pop    %ebx
f0103b48:	5d                   	pop    %ebp
f0103b49:	c3                   	ret    
	...

f0103b4c <syscall>:
f0103b4c:	55                   	push   %ebp
f0103b4d:	89 e5                	mov    %esp,%ebp
f0103b4f:	83 ec 18             	sub    $0x18,%esp
f0103b52:	c7 44 24 08 90 60 10 	movl   $0xf0106090,0x8(%esp)
f0103b59:	f0 
f0103b5a:	c7 44 24 04 49 00 00 	movl   $0x49,0x4(%esp)
f0103b61:	00 
f0103b62:	c7 04 24 a8 60 10 f0 	movl   $0xf01060a8,(%esp)
f0103b69:	e8 50 c5 ff ff       	call   f01000be <_panic>
	...

f0103b70 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103b70:	55                   	push   %ebp
f0103b71:	89 e5                	mov    %esp,%ebp
f0103b73:	57                   	push   %edi
f0103b74:	56                   	push   %esi
f0103b75:	53                   	push   %ebx
f0103b76:	83 ec 14             	sub    $0x14,%esp
f0103b79:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103b7c:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103b7f:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103b82:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b85:	8b 1a                	mov    (%edx),%ebx
f0103b87:	8b 01                	mov    (%ecx),%eax
f0103b89:	89 45 ec             	mov    %eax,-0x14(%ebp)
	
	while (l <= r) {
f0103b8c:	39 c3                	cmp    %eax,%ebx
f0103b8e:	0f 8f 9c 00 00 00    	jg     f0103c30 <stab_binsearch+0xc0>
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
f0103b94:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103b9b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103b9e:	01 d8                	add    %ebx,%eax
f0103ba0:	89 c7                	mov    %eax,%edi
f0103ba2:	c1 ef 1f             	shr    $0x1f,%edi
f0103ba5:	01 c7                	add    %eax,%edi
f0103ba7:	d1 ff                	sar    %edi
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ba9:	39 df                	cmp    %ebx,%edi
f0103bab:	7c 33                	jl     f0103be0 <stab_binsearch+0x70>
f0103bad:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103bb0:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0103bb3:	0f b6 44 82 04       	movzbl 0x4(%edx,%eax,4),%eax
f0103bb8:	39 f0                	cmp    %esi,%eax
f0103bba:	0f 84 bc 00 00 00    	je     f0103c7c <stab_binsearch+0x10c>
f0103bc0:	8d 44 7f fd          	lea    -0x3(%edi,%edi,2),%eax
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103bc4:	8d 54 82 04          	lea    0x4(%edx,%eax,4),%edx
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103bc8:	89 f8                	mov    %edi,%eax
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0103bca:	83 e8 01             	sub    $0x1,%eax
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
		
		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103bcd:	39 d8                	cmp    %ebx,%eax
f0103bcf:	7c 0f                	jl     f0103be0 <stab_binsearch+0x70>
f0103bd1:	0f b6 0a             	movzbl (%edx),%ecx
f0103bd4:	83 ea 0c             	sub    $0xc,%edx
f0103bd7:	39 f1                	cmp    %esi,%ecx
f0103bd9:	75 ef                	jne    f0103bca <stab_binsearch+0x5a>
f0103bdb:	e9 9e 00 00 00       	jmp    f0103c7e <stab_binsearch+0x10e>
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103be0:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103be3:	eb 3c                	jmp    f0103c21 <stab_binsearch+0xb1>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103be5:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103be8:	89 02                	mov    %eax,(%edx)
			l = true_m + 1;
f0103bea:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103bed:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103bf4:	eb 2b                	jmp    f0103c21 <stab_binsearch+0xb1>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103bf6:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103bf9:	76 14                	jbe    f0103c0f <stab_binsearch+0x9f>
			*region_right = m - 1;
f0103bfb:	83 e8 01             	sub    $0x1,%eax
f0103bfe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103c01:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c04:	89 01                	mov    %eax,(%ecx)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c06:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
f0103c0d:	eb 12                	jmp    f0103c21 <stab_binsearch+0xb1>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103c0f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c12:	89 02                	mov    %eax,(%edx)
			l = m;
			addr++;
f0103c14:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103c18:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103c1a:	c7 45 e4 01 00 00 00 	movl   $0x1,-0x1c(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
f0103c21:	39 5d ec             	cmp    %ebx,-0x14(%ebp)
f0103c24:	0f 8d 71 ff ff ff    	jge    f0103b9b <stab_binsearch+0x2b>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103c2a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c2e:	75 0f                	jne    f0103c3f <stab_binsearch+0xcf>
		*region_right = *region_left - 1;
f0103c30:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c33:	8b 02                	mov    (%edx),%eax
f0103c35:	83 e8 01             	sub    $0x1,%eax
f0103c38:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c3b:	89 01                	mov    %eax,(%ecx)
f0103c3d:	eb 57                	jmp    f0103c96 <stab_binsearch+0x126>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c3f:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103c42:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103c44:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c47:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c49:	39 c1                	cmp    %eax,%ecx
f0103c4b:	7d 28                	jge    f0103c75 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103c4d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c50:	8b 5d f0             	mov    -0x10(%ebp),%ebx
f0103c53:	0f b6 54 93 04       	movzbl 0x4(%ebx,%edx,4),%edx
f0103c58:	39 f2                	cmp    %esi,%edx
f0103c5a:	74 19                	je     f0103c75 <stab_binsearch+0x105>
f0103c5c:	8d 54 40 fd          	lea    -0x3(%eax,%eax,2),%edx
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103c60:	8d 54 93 04          	lea    0x4(%ebx,%edx,4),%edx
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103c64:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103c67:	39 c1                	cmp    %eax,%ecx
f0103c69:	7d 0a                	jge    f0103c75 <stab_binsearch+0x105>
		     l > *region_left && stabs[l].n_type != type;
f0103c6b:	0f b6 1a             	movzbl (%edx),%ebx
f0103c6e:	83 ea 0c             	sub    $0xc,%edx
f0103c71:	39 f3                	cmp    %esi,%ebx
f0103c73:	75 ef                	jne    f0103c64 <stab_binsearch+0xf4>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103c75:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103c78:	89 02                	mov    %eax,(%edx)
f0103c7a:	eb 1a                	jmp    f0103c96 <stab_binsearch+0x126>
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;
	
	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;
f0103c7c:	89 f8                	mov    %edi,%eax
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103c7e:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103c81:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0103c84:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103c88:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0103c8b:	0f 82 54 ff ff ff    	jb     f0103be5 <stab_binsearch+0x75>
f0103c91:	e9 60 ff ff ff       	jmp    f0103bf6 <stab_binsearch+0x86>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
			/* do nothing */;
		*region_left = l;
	}
}
f0103c96:	83 c4 14             	add    $0x14,%esp
f0103c99:	5b                   	pop    %ebx
f0103c9a:	5e                   	pop    %esi
f0103c9b:	5f                   	pop    %edi
f0103c9c:	5d                   	pop    %ebp
f0103c9d:	c3                   	ret    

f0103c9e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103c9e:	55                   	push   %ebp
f0103c9f:	89 e5                	mov    %esp,%ebp
f0103ca1:	57                   	push   %edi
f0103ca2:	56                   	push   %esi
f0103ca3:	53                   	push   %ebx
f0103ca4:	83 ec 4c             	sub    $0x4c,%esp
f0103ca7:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103caa:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103cad:	c7 06 b7 60 10 f0    	movl   $0xf01060b7,(%esi)
	info->eip_line = 0;
f0103cb3:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0103cba:	c7 46 08 b7 60 10 f0 	movl   $0xf01060b7,0x8(%esi)
	info->eip_fn_namelen = 9;
f0103cc1:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0103cc8:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0103ccb:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103cd2:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0103cd8:	77 23                	ja     f0103cfd <debuginfo_eip+0x5f>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0103cda:	8b 1d 00 00 20 00    	mov    0x200000,%ebx
f0103ce0:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
		stab_end = usd->stab_end;
f0103ce3:	8b 15 04 00 20 00    	mov    0x200004,%edx
		stabstr = usd->stabstr;
f0103ce9:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0103cef:	89 5d cc             	mov    %ebx,-0x34(%ebp)
		stabstr_end = usd->stabstr_end;
f0103cf2:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0103cf8:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0103cfb:	eb 1a                	jmp    f0103d17 <debuginfo_eip+0x79>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103cfd:	c7 45 d0 2f 0c 11 f0 	movl   $0xf0110c2f,-0x30(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103d04:	c7 45 cc 55 e1 10 f0 	movl   $0xf010e155,-0x34(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103d0b:	ba 54 e1 10 f0       	mov    $0xf010e154,%edx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103d10:	c7 45 d4 d0 62 10 f0 	movl   $0xf01062d0,-0x2c(%ebp)
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103d17:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103d1c:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103d1f:	39 5d cc             	cmp    %ebx,-0x34(%ebp)
f0103d22:	0f 83 7d 01 00 00    	jae    f0103ea5 <debuginfo_eip+0x207>
f0103d28:	80 7b ff 00          	cmpb   $0x0,-0x1(%ebx)
f0103d2c:	0f 85 73 01 00 00    	jne    f0103ea5 <debuginfo_eip+0x207>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103d32:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103d39:	2b 55 d4             	sub    -0x2c(%ebp),%edx
f0103d3c:	c1 fa 02             	sar    $0x2,%edx
f0103d3f:	69 c2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%eax
f0103d45:	83 e8 01             	sub    $0x1,%eax
f0103d48:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103d4b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103d4f:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103d56:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103d59:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103d5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103d5f:	e8 0c fe ff ff       	call   f0103b70 <stab_binsearch>
	if (lfile == 0)
f0103d64:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103d67:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103d6c:	85 d2                	test   %edx,%edx
f0103d6e:	0f 84 31 01 00 00    	je     f0103ea5 <debuginfo_eip+0x207>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103d74:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103d77:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d7a:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103d7d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103d81:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103d88:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103d8b:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103d8e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103d91:	e8 da fd ff ff       	call   f0103b70 <stab_binsearch>

	if (lfun <= rfun) {
f0103d96:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103d99:	3b 5d d8             	cmp    -0x28(%ebp),%ebx
f0103d9c:	7f 23                	jg     f0103dc1 <debuginfo_eip+0x123>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103d9e:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103da1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103da4:	8d 04 87             	lea    (%edi,%eax,4),%eax
f0103da7:	8b 10                	mov    (%eax),%edx
f0103da9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103dac:	2b 4d cc             	sub    -0x34(%ebp),%ecx
f0103daf:	39 ca                	cmp    %ecx,%edx
f0103db1:	73 06                	jae    f0103db9 <debuginfo_eip+0x11b>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103db3:	03 55 cc             	add    -0x34(%ebp),%edx
f0103db6:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103db9:	8b 40 08             	mov    0x8(%eax),%eax
f0103dbc:	89 46 10             	mov    %eax,0x10(%esi)
f0103dbf:	eb 06                	jmp    f0103dc7 <debuginfo_eip+0x129>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103dc1:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0103dc4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103dc7:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103dce:	00 
f0103dcf:	8b 46 08             	mov    0x8(%esi),%eax
f0103dd2:	89 04 24             	mov    %eax,(%esp)
f0103dd5:	e8 10 09 00 00       	call   f01046ea <strfind>
f0103dda:	2b 46 08             	sub    0x8(%esi),%eax
f0103ddd:	89 46 0c             	mov    %eax,0xc(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103de0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103de3:	39 fb                	cmp    %edi,%ebx
f0103de5:	7c 63                	jl     f0103e4a <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0103de7:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103dea:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103ded:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0103df0:	0f b6 41 04          	movzbl 0x4(%ecx),%eax
f0103df4:	88 45 c7             	mov    %al,-0x39(%ebp)
f0103df7:	3c 84                	cmp    $0x84,%al
f0103df9:	74 37                	je     f0103e32 <debuginfo_eip+0x194>
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103dfb:	8d 54 5b fd          	lea    -0x3(%ebx,%ebx,2),%edx
f0103dff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103e02:	8d 04 90             	lea    (%eax,%edx,4),%eax
f0103e05:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0103e08:	0f b6 55 c7          	movzbl -0x39(%ebp),%edx
f0103e0c:	eb 15                	jmp    f0103e23 <debuginfo_eip+0x185>
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103e0e:	83 eb 01             	sub    $0x1,%ebx
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103e11:	39 df                	cmp    %ebx,%edi
f0103e13:	7f 35                	jg     f0103e4a <debuginfo_eip+0x1ac>
	       && stabs[lline].n_type != N_SOL
f0103e15:	89 c1                	mov    %eax,%ecx
f0103e17:	83 e8 0c             	sub    $0xc,%eax
f0103e1a:	0f b6 50 10          	movzbl 0x10(%eax),%edx
f0103e1e:	80 fa 84             	cmp    $0x84,%dl
f0103e21:	74 0f                	je     f0103e32 <debuginfo_eip+0x194>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103e23:	80 fa 64             	cmp    $0x64,%dl
f0103e26:	75 e6                	jne    f0103e0e <debuginfo_eip+0x170>
f0103e28:	83 79 08 00          	cmpl   $0x0,0x8(%ecx)
f0103e2c:	74 e0                	je     f0103e0e <debuginfo_eip+0x170>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103e2e:	39 fb                	cmp    %edi,%ebx
f0103e30:	7c 18                	jl     f0103e4a <debuginfo_eip+0x1ac>
f0103e32:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0103e35:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103e38:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0103e3b:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0103e3e:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0103e41:	39 d0                	cmp    %edx,%eax
f0103e43:	73 05                	jae    f0103e4a <debuginfo_eip+0x1ac>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103e45:	03 45 cc             	add    -0x34(%ebp),%eax
f0103e48:	89 06                	mov    %eax,(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e4a:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0103e4d:	8b 7d d8             	mov    -0x28(%ebp),%edi
f0103e50:	89 7d cc             	mov    %edi,-0x34(%ebp)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103e53:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103e58:	39 fb                	cmp    %edi,%ebx
f0103e5a:	7d 49                	jge    f0103ea5 <debuginfo_eip+0x207>
		for (lline = lfun + 1;
f0103e5c:	8d 53 01             	lea    0x1(%ebx),%edx
f0103e5f:	39 d7                	cmp    %edx,%edi
f0103e61:	7e 42                	jle    f0103ea5 <debuginfo_eip+0x207>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e63:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103e66:	89 45 d0             	mov    %eax,-0x30(%ebp)
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103e69:	b8 00 00 00 00       	mov    $0x0,%eax

	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e6e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0103e71:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103e74:	80 7c 8f 04 a0       	cmpb   $0xa0,0x4(%edi,%ecx,4)
f0103e79:	75 2a                	jne    f0103ea5 <debuginfo_eip+0x207>
f0103e7b:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
//	instruction address, 'addr'.  Returns 0 if information was found, and
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
f0103e7e:	8d 44 87 1c          	lea    0x1c(%edi,%eax,4),%eax
f0103e82:	8b 4d cc             	mov    -0x34(%ebp),%ecx
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0103e85:	83 46 14 01          	addl   $0x1,0x14(%esi)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103e89:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103e8c:	39 d1                	cmp    %edx,%ecx
f0103e8e:	7e 10                	jle    f0103ea0 <debuginfo_eip+0x202>
f0103e90:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103e93:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0103e97:	74 ec                	je     f0103e85 <debuginfo_eip+0x1e7>
		     lline++)
			info->eip_fn_narg++;
	
	return 0;
f0103e99:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e9e:	eb 05                	jmp    f0103ea5 <debuginfo_eip+0x207>
f0103ea0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103ea5:	83 c4 4c             	add    $0x4c,%esp
f0103ea8:	5b                   	pop    %ebx
f0103ea9:	5e                   	pop    %esi
f0103eaa:	5f                   	pop    %edi
f0103eab:	5d                   	pop    %ebp
f0103eac:	c3                   	ret    
f0103ead:	00 00                	add    %al,(%eax)
	...

f0103eb0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103eb0:	55                   	push   %ebp
f0103eb1:	89 e5                	mov    %esp,%ebp
f0103eb3:	57                   	push   %edi
f0103eb4:	56                   	push   %esi
f0103eb5:	53                   	push   %ebx
f0103eb6:	83 ec 3c             	sub    $0x3c,%esp
f0103eb9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103ebc:	89 d7                	mov    %edx,%edi
f0103ebe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ec1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103ec4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ec7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103eca:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0103ecd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103ed0:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ed5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103ed8:	72 11                	jb     f0103eeb <printnum+0x3b>
f0103eda:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103edd:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103ee0:	76 09                	jbe    f0103eeb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103ee2:	83 eb 01             	sub    $0x1,%ebx
f0103ee5:	85 db                	test   %ebx,%ebx
f0103ee7:	7f 51                	jg     f0103f3a <printnum+0x8a>
f0103ee9:	eb 5e                	jmp    f0103f49 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0103eeb:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103eef:	83 eb 01             	sub    $0x1,%ebx
f0103ef2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103ef6:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ef9:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103efd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103f01:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103f05:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103f0c:	00 
f0103f0d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103f10:	89 04 24             	mov    %eax,(%esp)
f0103f13:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f16:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f1a:	e8 41 0a 00 00       	call   f0104960 <__udivdi3>
f0103f1f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103f23:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103f27:	89 04 24             	mov    %eax,(%esp)
f0103f2a:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103f2e:	89 fa                	mov    %edi,%edx
f0103f30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f33:	e8 78 ff ff ff       	call   f0103eb0 <printnum>
f0103f38:	eb 0f                	jmp    f0103f49 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103f3a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f3e:	89 34 24             	mov    %esi,(%esp)
f0103f41:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103f44:	83 eb 01             	sub    $0x1,%ebx
f0103f47:	75 f1                	jne    f0103f3a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103f49:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f4d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103f51:	8b 45 10             	mov    0x10(%ebp),%eax
f0103f54:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103f58:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0103f5f:	00 
f0103f60:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103f63:	89 04 24             	mov    %eax,(%esp)
f0103f66:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f6d:	e8 1e 0b 00 00       	call   f0104a90 <__umoddi3>
f0103f72:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103f76:	0f be 80 c1 60 10 f0 	movsbl -0xfef9f3f(%eax),%eax
f0103f7d:	89 04 24             	mov    %eax,(%esp)
f0103f80:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103f83:	83 c4 3c             	add    $0x3c,%esp
f0103f86:	5b                   	pop    %ebx
f0103f87:	5e                   	pop    %esi
f0103f88:	5f                   	pop    %edi
f0103f89:	5d                   	pop    %ebp
f0103f8a:	c3                   	ret    

f0103f8b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0103f8b:	55                   	push   %ebp
f0103f8c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0103f8e:	83 fa 01             	cmp    $0x1,%edx
f0103f91:	7e 0e                	jle    f0103fa1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103f93:	8b 10                	mov    (%eax),%edx
f0103f95:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103f98:	89 08                	mov    %ecx,(%eax)
f0103f9a:	8b 02                	mov    (%edx),%eax
f0103f9c:	8b 52 04             	mov    0x4(%edx),%edx
f0103f9f:	eb 22                	jmp    f0103fc3 <getuint+0x38>
	else if (lflag)
f0103fa1:	85 d2                	test   %edx,%edx
f0103fa3:	74 10                	je     f0103fb5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103fa5:	8b 10                	mov    (%eax),%edx
f0103fa7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103faa:	89 08                	mov    %ecx,(%eax)
f0103fac:	8b 02                	mov    (%edx),%eax
f0103fae:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fb3:	eb 0e                	jmp    f0103fc3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103fb5:	8b 10                	mov    (%eax),%edx
f0103fb7:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103fba:	89 08                	mov    %ecx,(%eax)
f0103fbc:	8b 02                	mov    (%edx),%eax
f0103fbe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103fc3:	5d                   	pop    %ebp
f0103fc4:	c3                   	ret    

f0103fc5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103fc5:	55                   	push   %ebp
f0103fc6:	89 e5                	mov    %esp,%ebp
f0103fc8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103fcb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103fcf:	8b 10                	mov    (%eax),%edx
f0103fd1:	3b 50 04             	cmp    0x4(%eax),%edx
f0103fd4:	73 0a                	jae    f0103fe0 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103fd6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103fd9:	88 0a                	mov    %cl,(%edx)
f0103fdb:	83 c2 01             	add    $0x1,%edx
f0103fde:	89 10                	mov    %edx,(%eax)
}
f0103fe0:	5d                   	pop    %ebp
f0103fe1:	c3                   	ret    

f0103fe2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103fe2:	55                   	push   %ebp
f0103fe3:	89 e5                	mov    %esp,%ebp
f0103fe5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103fe8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103feb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103fef:	8b 45 10             	mov    0x10(%ebp),%eax
f0103ff2:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ff6:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ff9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ffd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104000:	89 04 24             	mov    %eax,(%esp)
f0104003:	e8 02 00 00 00       	call   f010400a <vprintfmt>
	va_end(ap);
}
f0104008:	c9                   	leave  
f0104009:	c3                   	ret    

f010400a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010400a:	55                   	push   %ebp
f010400b:	89 e5                	mov    %esp,%ebp
f010400d:	57                   	push   %edi
f010400e:	56                   	push   %esi
f010400f:	53                   	push   %ebx
f0104010:	83 ec 4c             	sub    $0x4c,%esp
f0104013:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104016:	8b 75 10             	mov    0x10(%ebp),%esi
f0104019:	eb 12                	jmp    f010402d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010401b:	85 c0                	test   %eax,%eax
f010401d:	0f 84 a9 03 00 00    	je     f01043cc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0104023:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104027:	89 04 24             	mov    %eax,(%esp)
f010402a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010402d:	0f b6 06             	movzbl (%esi),%eax
f0104030:	83 c6 01             	add    $0x1,%esi
f0104033:	83 f8 25             	cmp    $0x25,%eax
f0104036:	75 e3                	jne    f010401b <vprintfmt+0x11>
f0104038:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010403c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0104043:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0104048:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010404f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104054:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104057:	eb 2b                	jmp    f0104084 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104059:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010405c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104060:	eb 22                	jmp    f0104084 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104062:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104065:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0104069:	eb 19                	jmp    f0104084 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010406b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010406e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104075:	eb 0d                	jmp    f0104084 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0104077:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010407a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010407d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104084:	0f b6 06             	movzbl (%esi),%eax
f0104087:	0f b6 d0             	movzbl %al,%edx
f010408a:	8d 7e 01             	lea    0x1(%esi),%edi
f010408d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0104090:	83 e8 23             	sub    $0x23,%eax
f0104093:	3c 55                	cmp    $0x55,%al
f0104095:	0f 87 0b 03 00 00    	ja     f01043a6 <vprintfmt+0x39c>
f010409b:	0f b6 c0             	movzbl %al,%eax
f010409e:	ff 24 85 4c 61 10 f0 	jmp    *-0xfef9eb4(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01040a5:	83 ea 30             	sub    $0x30,%edx
f01040a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01040ab:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01040af:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040b2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01040b5:	83 fa 09             	cmp    $0x9,%edx
f01040b8:	77 4a                	ja     f0104104 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040ba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01040bd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01040c0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01040c3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01040c7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01040ca:	8d 50 d0             	lea    -0x30(%eax),%edx
f01040cd:	83 fa 09             	cmp    $0x9,%edx
f01040d0:	76 eb                	jbe    f01040bd <vprintfmt+0xb3>
f01040d2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01040d5:	eb 2d                	jmp    f0104104 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01040d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01040da:	8d 50 04             	lea    0x4(%eax),%edx
f01040dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01040e0:	8b 00                	mov    (%eax),%eax
f01040e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040e5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01040e8:	eb 1a                	jmp    f0104104 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01040ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01040f1:	79 91                	jns    f0104084 <vprintfmt+0x7a>
f01040f3:	e9 73 ff ff ff       	jmp    f010406b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01040f8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01040fb:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0104102:	eb 80                	jmp    f0104084 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0104104:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104108:	0f 89 76 ff ff ff    	jns    f0104084 <vprintfmt+0x7a>
f010410e:	e9 64 ff ff ff       	jmp    f0104077 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104113:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104116:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104119:	e9 66 ff ff ff       	jmp    f0104084 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010411e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104121:	8d 50 04             	lea    0x4(%eax),%edx
f0104124:	89 55 14             	mov    %edx,0x14(%ebp)
f0104127:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010412b:	8b 00                	mov    (%eax),%eax
f010412d:	89 04 24             	mov    %eax,(%esp)
f0104130:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104133:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104136:	e9 f2 fe ff ff       	jmp    f010402d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010413b:	8b 45 14             	mov    0x14(%ebp),%eax
f010413e:	8d 50 04             	lea    0x4(%eax),%edx
f0104141:	89 55 14             	mov    %edx,0x14(%ebp)
f0104144:	8b 00                	mov    (%eax),%eax
f0104146:	89 c2                	mov    %eax,%edx
f0104148:	c1 fa 1f             	sar    $0x1f,%edx
f010414b:	31 d0                	xor    %edx,%eax
f010414d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010414f:	83 f8 06             	cmp    $0x6,%eax
f0104152:	7f 0b                	jg     f010415f <vprintfmt+0x155>
f0104154:	8b 14 85 a4 62 10 f0 	mov    -0xfef9d5c(,%eax,4),%edx
f010415b:	85 d2                	test   %edx,%edx
f010415d:	75 23                	jne    f0104182 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010415f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104163:	c7 44 24 08 d9 60 10 	movl   $0xf01060d9,0x8(%esp)
f010416a:	f0 
f010416b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010416f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104172:	89 3c 24             	mov    %edi,(%esp)
f0104175:	e8 68 fe ff ff       	call   f0103fe2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010417a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010417d:	e9 ab fe ff ff       	jmp    f010402d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0104182:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104186:	c7 44 24 08 df 58 10 	movl   $0xf01058df,0x8(%esp)
f010418d:	f0 
f010418e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104192:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104195:	89 3c 24             	mov    %edi,(%esp)
f0104198:	e8 45 fe ff ff       	call   f0103fe2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010419d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01041a0:	e9 88 fe ff ff       	jmp    f010402d <vprintfmt+0x23>
f01041a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01041a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01041ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01041ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01041b1:	8d 50 04             	lea    0x4(%eax),%edx
f01041b4:	89 55 14             	mov    %edx,0x14(%ebp)
f01041b7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01041b9:	85 f6                	test   %esi,%esi
f01041bb:	ba d2 60 10 f0       	mov    $0xf01060d2,%edx
f01041c0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01041c3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01041c7:	7e 06                	jle    f01041cf <vprintfmt+0x1c5>
f01041c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01041cd:	75 10                	jne    f01041df <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01041cf:	0f be 06             	movsbl (%esi),%eax
f01041d2:	83 c6 01             	add    $0x1,%esi
f01041d5:	85 c0                	test   %eax,%eax
f01041d7:	0f 85 86 00 00 00    	jne    f0104263 <vprintfmt+0x259>
f01041dd:	eb 76                	jmp    f0104255 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01041df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01041e3:	89 34 24             	mov    %esi,(%esp)
f01041e6:	e8 60 03 00 00       	call   f010454b <strnlen>
f01041eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01041ee:	29 c2                	sub    %eax,%edx
f01041f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01041f3:	85 d2                	test   %edx,%edx
f01041f5:	7e d8                	jle    f01041cf <vprintfmt+0x1c5>
					putch(padc, putdat);
f01041f7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01041fb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01041fe:	89 d6                	mov    %edx,%esi
f0104200:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0104203:	89 c7                	mov    %eax,%edi
f0104205:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104209:	89 3c 24             	mov    %edi,(%esp)
f010420c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010420f:	83 ee 01             	sub    $0x1,%esi
f0104212:	75 f1                	jne    f0104205 <vprintfmt+0x1fb>
f0104214:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0104217:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010421a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010421d:	eb b0                	jmp    f01041cf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010421f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104223:	74 18                	je     f010423d <vprintfmt+0x233>
f0104225:	8d 50 e0             	lea    -0x20(%eax),%edx
f0104228:	83 fa 5e             	cmp    $0x5e,%edx
f010422b:	76 10                	jbe    f010423d <vprintfmt+0x233>
					putch('?', putdat);
f010422d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104231:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104238:	ff 55 08             	call   *0x8(%ebp)
f010423b:	eb 0a                	jmp    f0104247 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010423d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104241:	89 04 24             	mov    %eax,(%esp)
f0104244:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104247:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010424b:	0f be 06             	movsbl (%esi),%eax
f010424e:	83 c6 01             	add    $0x1,%esi
f0104251:	85 c0                	test   %eax,%eax
f0104253:	75 0e                	jne    f0104263 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104255:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104258:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010425c:	7f 16                	jg     f0104274 <vprintfmt+0x26a>
f010425e:	e9 ca fd ff ff       	jmp    f010402d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104263:	85 ff                	test   %edi,%edi
f0104265:	78 b8                	js     f010421f <vprintfmt+0x215>
f0104267:	83 ef 01             	sub    $0x1,%edi
f010426a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104270:	79 ad                	jns    f010421f <vprintfmt+0x215>
f0104272:	eb e1                	jmp    f0104255 <vprintfmt+0x24b>
f0104274:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104277:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010427a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010427e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104285:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104287:	83 ee 01             	sub    $0x1,%esi
f010428a:	75 ee                	jne    f010427a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010428c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010428f:	e9 99 fd ff ff       	jmp    f010402d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104294:	83 f9 01             	cmp    $0x1,%ecx
f0104297:	7e 10                	jle    f01042a9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0104299:	8b 45 14             	mov    0x14(%ebp),%eax
f010429c:	8d 50 08             	lea    0x8(%eax),%edx
f010429f:	89 55 14             	mov    %edx,0x14(%ebp)
f01042a2:	8b 30                	mov    (%eax),%esi
f01042a4:	8b 78 04             	mov    0x4(%eax),%edi
f01042a7:	eb 26                	jmp    f01042cf <vprintfmt+0x2c5>
	else if (lflag)
f01042a9:	85 c9                	test   %ecx,%ecx
f01042ab:	74 12                	je     f01042bf <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01042ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01042b0:	8d 50 04             	lea    0x4(%eax),%edx
f01042b3:	89 55 14             	mov    %edx,0x14(%ebp)
f01042b6:	8b 30                	mov    (%eax),%esi
f01042b8:	89 f7                	mov    %esi,%edi
f01042ba:	c1 ff 1f             	sar    $0x1f,%edi
f01042bd:	eb 10                	jmp    f01042cf <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01042bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01042c2:	8d 50 04             	lea    0x4(%eax),%edx
f01042c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01042c8:	8b 30                	mov    (%eax),%esi
f01042ca:	89 f7                	mov    %esi,%edi
f01042cc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01042cf:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01042d4:	85 ff                	test   %edi,%edi
f01042d6:	0f 89 8c 00 00 00    	jns    f0104368 <vprintfmt+0x35e>
				putch('-', putdat);
f01042dc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01042e0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01042e7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01042ea:	f7 de                	neg    %esi
f01042ec:	83 d7 00             	adc    $0x0,%edi
f01042ef:	f7 df                	neg    %edi
			}
			base = 10;
f01042f1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01042f6:	eb 70                	jmp    f0104368 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01042f8:	89 ca                	mov    %ecx,%edx
f01042fa:	8d 45 14             	lea    0x14(%ebp),%eax
f01042fd:	e8 89 fc ff ff       	call   f0103f8b <getuint>
f0104302:	89 c6                	mov    %eax,%esi
f0104304:	89 d7                	mov    %edx,%edi
			base = 10;
f0104306:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010430b:	eb 5b                	jmp    f0104368 <vprintfmt+0x35e>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
            num = getuint(&ap, lflag);
f010430d:	89 ca                	mov    %ecx,%edx
f010430f:	8d 45 14             	lea    0x14(%ebp),%eax
f0104312:	e8 74 fc ff ff       	call   f0103f8b <getuint>
f0104317:	89 c6                	mov    %eax,%esi
f0104319:	89 d7                	mov    %edx,%edi
            base = 8;
f010431b:	b8 08 00 00 00       	mov    $0x8,%eax
            goto number;
f0104320:	eb 46                	jmp    f0104368 <vprintfmt+0x35e>

		// pointer
		case 'p':
			putch('0', putdat);
f0104322:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104326:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010432d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104330:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104334:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010433b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010433e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104341:	8d 50 04             	lea    0x4(%eax),%edx
f0104344:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104347:	8b 30                	mov    (%eax),%esi
f0104349:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010434e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104353:	eb 13                	jmp    f0104368 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104355:	89 ca                	mov    %ecx,%edx
f0104357:	8d 45 14             	lea    0x14(%ebp),%eax
f010435a:	e8 2c fc ff ff       	call   f0103f8b <getuint>
f010435f:	89 c6                	mov    %eax,%esi
f0104361:	89 d7                	mov    %edx,%edi
			base = 16;
f0104363:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104368:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010436c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0104370:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104373:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104377:	89 44 24 08          	mov    %eax,0x8(%esp)
f010437b:	89 34 24             	mov    %esi,(%esp)
f010437e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104382:	89 da                	mov    %ebx,%edx
f0104384:	8b 45 08             	mov    0x8(%ebp),%eax
f0104387:	e8 24 fb ff ff       	call   f0103eb0 <printnum>
			break;
f010438c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010438f:	e9 99 fc ff ff       	jmp    f010402d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104394:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104398:	89 14 24             	mov    %edx,(%esp)
f010439b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010439e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01043a1:	e9 87 fc ff ff       	jmp    f010402d <vprintfmt+0x23>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01043a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01043aa:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01043b1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01043b4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01043b8:	0f 84 6f fc ff ff    	je     f010402d <vprintfmt+0x23>
f01043be:	83 ee 01             	sub    $0x1,%esi
f01043c1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01043c5:	75 f7                	jne    f01043be <vprintfmt+0x3b4>
f01043c7:	e9 61 fc ff ff       	jmp    f010402d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01043cc:	83 c4 4c             	add    $0x4c,%esp
f01043cf:	5b                   	pop    %ebx
f01043d0:	5e                   	pop    %esi
f01043d1:	5f                   	pop    %edi
f01043d2:	5d                   	pop    %ebp
f01043d3:	c3                   	ret    

f01043d4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01043d4:	55                   	push   %ebp
f01043d5:	89 e5                	mov    %esp,%ebp
f01043d7:	83 ec 28             	sub    $0x28,%esp
f01043da:	8b 45 08             	mov    0x8(%ebp),%eax
f01043dd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01043e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01043e3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01043e7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01043ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01043f1:	85 c0                	test   %eax,%eax
f01043f3:	74 30                	je     f0104425 <vsnprintf+0x51>
f01043f5:	85 d2                	test   %edx,%edx
f01043f7:	7e 2c                	jle    f0104425 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01043f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01043fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104400:	8b 45 10             	mov    0x10(%ebp),%eax
f0104403:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104407:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010440a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010440e:	c7 04 24 c5 3f 10 f0 	movl   $0xf0103fc5,(%esp)
f0104415:	e8 f0 fb ff ff       	call   f010400a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010441a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010441d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104420:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104423:	eb 05                	jmp    f010442a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104425:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010442a:	c9                   	leave  
f010442b:	c3                   	ret    

f010442c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010442c:	55                   	push   %ebp
f010442d:	89 e5                	mov    %esp,%ebp
f010442f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104432:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104435:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104439:	8b 45 10             	mov    0x10(%ebp),%eax
f010443c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104440:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104443:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104447:	8b 45 08             	mov    0x8(%ebp),%eax
f010444a:	89 04 24             	mov    %eax,(%esp)
f010444d:	e8 82 ff ff ff       	call   f01043d4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104452:	c9                   	leave  
f0104453:	c3                   	ret    
	...

f0104460 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104460:	55                   	push   %ebp
f0104461:	89 e5                	mov    %esp,%ebp
f0104463:	57                   	push   %edi
f0104464:	56                   	push   %esi
f0104465:	53                   	push   %ebx
f0104466:	83 ec 1c             	sub    $0x1c,%esp
f0104469:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010446c:	85 c0                	test   %eax,%eax
f010446e:	74 10                	je     f0104480 <readline+0x20>
		cprintf("%s", prompt);
f0104470:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104474:	c7 04 24 df 58 10 f0 	movl   $0xf01058df,(%esp)
f010447b:	e8 ca f2 ff ff       	call   f010374a <cprintf>

	i = 0;
	echoing = iscons(0);
f0104480:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104487:	e8 b7 c1 ff ff       	call   f0100643 <iscons>
f010448c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010448e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104493:	e8 9a c1 ff ff       	call   f0100632 <getchar>
f0104498:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010449a:	85 c0                	test   %eax,%eax
f010449c:	79 17                	jns    f01044b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010449e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044a2:	c7 04 24 c0 62 10 f0 	movl   $0xf01062c0,(%esp)
f01044a9:	e8 9c f2 ff ff       	call   f010374a <cprintf>
			return NULL;
f01044ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01044b3:	eb 6d                	jmp    f0104522 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01044b5:	83 f8 08             	cmp    $0x8,%eax
f01044b8:	74 05                	je     f01044bf <readline+0x5f>
f01044ba:	83 f8 7f             	cmp    $0x7f,%eax
f01044bd:	75 19                	jne    f01044d8 <readline+0x78>
f01044bf:	85 f6                	test   %esi,%esi
f01044c1:	7e 15                	jle    f01044d8 <readline+0x78>
			if (echoing)
f01044c3:	85 ff                	test   %edi,%edi
f01044c5:	74 0c                	je     f01044d3 <readline+0x73>
				cputchar('\b');
f01044c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01044ce:	e8 4f c1 ff ff       	call   f0100622 <cputchar>
			i--;
f01044d3:	83 ee 01             	sub    $0x1,%esi
f01044d6:	eb bb                	jmp    f0104493 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01044d8:	83 fb 1f             	cmp    $0x1f,%ebx
f01044db:	7e 1f                	jle    f01044fc <readline+0x9c>
f01044dd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01044e3:	7f 17                	jg     f01044fc <readline+0x9c>
			if (echoing)
f01044e5:	85 ff                	test   %edi,%edi
f01044e7:	74 08                	je     f01044f1 <readline+0x91>
				cputchar(c);
f01044e9:	89 1c 24             	mov    %ebx,(%esp)
f01044ec:	e8 31 c1 ff ff       	call   f0100622 <cputchar>
			buf[i++] = c;
f01044f1:	88 9e 20 d9 17 f0    	mov    %bl,-0xfe826e0(%esi)
f01044f7:	83 c6 01             	add    $0x1,%esi
f01044fa:	eb 97                	jmp    f0104493 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01044fc:	83 fb 0a             	cmp    $0xa,%ebx
f01044ff:	74 05                	je     f0104506 <readline+0xa6>
f0104501:	83 fb 0d             	cmp    $0xd,%ebx
f0104504:	75 8d                	jne    f0104493 <readline+0x33>
			if (echoing)
f0104506:	85 ff                	test   %edi,%edi
f0104508:	74 0c                	je     f0104516 <readline+0xb6>
				cputchar('\n');
f010450a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104511:	e8 0c c1 ff ff       	call   f0100622 <cputchar>
			buf[i] = 0;
f0104516:	c6 86 20 d9 17 f0 00 	movb   $0x0,-0xfe826e0(%esi)
			return buf;
f010451d:	b8 20 d9 17 f0       	mov    $0xf017d920,%eax
		}
	}
}
f0104522:	83 c4 1c             	add    $0x1c,%esp
f0104525:	5b                   	pop    %ebx
f0104526:	5e                   	pop    %esi
f0104527:	5f                   	pop    %edi
f0104528:	5d                   	pop    %ebp
f0104529:	c3                   	ret    
f010452a:	00 00                	add    %al,(%eax)
f010452c:	00 00                	add    %al,(%eax)
	...

f0104530 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104530:	55                   	push   %ebp
f0104531:	89 e5                	mov    %esp,%ebp
f0104533:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104536:	b8 00 00 00 00       	mov    $0x0,%eax
f010453b:	80 3a 00             	cmpb   $0x0,(%edx)
f010453e:	74 09                	je     f0104549 <strlen+0x19>
		n++;
f0104540:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104543:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104547:	75 f7                	jne    f0104540 <strlen+0x10>
		n++;
	return n;
}
f0104549:	5d                   	pop    %ebp
f010454a:	c3                   	ret    

f010454b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010454b:	55                   	push   %ebp
f010454c:	89 e5                	mov    %esp,%ebp
f010454e:	53                   	push   %ebx
f010454f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104552:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104555:	b8 00 00 00 00       	mov    $0x0,%eax
f010455a:	85 c9                	test   %ecx,%ecx
f010455c:	74 1a                	je     f0104578 <strnlen+0x2d>
f010455e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0104561:	74 15                	je     f0104578 <strnlen+0x2d>
f0104563:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0104568:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010456a:	39 ca                	cmp    %ecx,%edx
f010456c:	74 0a                	je     f0104578 <strnlen+0x2d>
f010456e:	83 c2 01             	add    $0x1,%edx
f0104571:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0104576:	75 f0                	jne    f0104568 <strnlen+0x1d>
		n++;
	return n;
}
f0104578:	5b                   	pop    %ebx
f0104579:	5d                   	pop    %ebp
f010457a:	c3                   	ret    

f010457b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010457b:	55                   	push   %ebp
f010457c:	89 e5                	mov    %esp,%ebp
f010457e:	53                   	push   %ebx
f010457f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104582:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104585:	ba 00 00 00 00       	mov    $0x0,%edx
f010458a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010458e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0104591:	83 c2 01             	add    $0x1,%edx
f0104594:	84 c9                	test   %cl,%cl
f0104596:	75 f2                	jne    f010458a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0104598:	5b                   	pop    %ebx
f0104599:	5d                   	pop    %ebp
f010459a:	c3                   	ret    

f010459b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010459b:	55                   	push   %ebp
f010459c:	89 e5                	mov    %esp,%ebp
f010459e:	53                   	push   %ebx
f010459f:	83 ec 08             	sub    $0x8,%esp
f01045a2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01045a5:	89 1c 24             	mov    %ebx,(%esp)
f01045a8:	e8 83 ff ff ff       	call   f0104530 <strlen>
	strcpy(dst + len, src);
f01045ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045b0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01045b4:	01 d8                	add    %ebx,%eax
f01045b6:	89 04 24             	mov    %eax,(%esp)
f01045b9:	e8 bd ff ff ff       	call   f010457b <strcpy>
	return dst;
}
f01045be:	89 d8                	mov    %ebx,%eax
f01045c0:	83 c4 08             	add    $0x8,%esp
f01045c3:	5b                   	pop    %ebx
f01045c4:	5d                   	pop    %ebp
f01045c5:	c3                   	ret    

f01045c6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01045c6:	55                   	push   %ebp
f01045c7:	89 e5                	mov    %esp,%ebp
f01045c9:	56                   	push   %esi
f01045ca:	53                   	push   %ebx
f01045cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01045ce:	8b 55 0c             	mov    0xc(%ebp),%edx
f01045d1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01045d4:	85 f6                	test   %esi,%esi
f01045d6:	74 18                	je     f01045f0 <strncpy+0x2a>
f01045d8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01045dd:	0f b6 1a             	movzbl (%edx),%ebx
f01045e0:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01045e3:	80 3a 01             	cmpb   $0x1,(%edx)
f01045e6:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01045e9:	83 c1 01             	add    $0x1,%ecx
f01045ec:	39 f1                	cmp    %esi,%ecx
f01045ee:	75 ed                	jne    f01045dd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01045f0:	5b                   	pop    %ebx
f01045f1:	5e                   	pop    %esi
f01045f2:	5d                   	pop    %ebp
f01045f3:	c3                   	ret    

f01045f4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01045f4:	55                   	push   %ebp
f01045f5:	89 e5                	mov    %esp,%ebp
f01045f7:	57                   	push   %edi
f01045f8:	56                   	push   %esi
f01045f9:	53                   	push   %ebx
f01045fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01045fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104600:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104603:	89 f8                	mov    %edi,%eax
f0104605:	85 f6                	test   %esi,%esi
f0104607:	74 2b                	je     f0104634 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104609:	83 fe 01             	cmp    $0x1,%esi
f010460c:	74 23                	je     f0104631 <strlcpy+0x3d>
f010460e:	0f b6 0b             	movzbl (%ebx),%ecx
f0104611:	84 c9                	test   %cl,%cl
f0104613:	74 1c                	je     f0104631 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104615:	83 ee 02             	sub    $0x2,%esi
f0104618:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010461d:	88 08                	mov    %cl,(%eax)
f010461f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104622:	39 f2                	cmp    %esi,%edx
f0104624:	74 0b                	je     f0104631 <strlcpy+0x3d>
f0104626:	83 c2 01             	add    $0x1,%edx
f0104629:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010462d:	84 c9                	test   %cl,%cl
f010462f:	75 ec                	jne    f010461d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0104631:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104634:	29 f8                	sub    %edi,%eax
}
f0104636:	5b                   	pop    %ebx
f0104637:	5e                   	pop    %esi
f0104638:	5f                   	pop    %edi
f0104639:	5d                   	pop    %ebp
f010463a:	c3                   	ret    

f010463b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010463b:	55                   	push   %ebp
f010463c:	89 e5                	mov    %esp,%ebp
f010463e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104641:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104644:	0f b6 01             	movzbl (%ecx),%eax
f0104647:	84 c0                	test   %al,%al
f0104649:	74 16                	je     f0104661 <strcmp+0x26>
f010464b:	3a 02                	cmp    (%edx),%al
f010464d:	75 12                	jne    f0104661 <strcmp+0x26>
		p++, q++;
f010464f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104652:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0104656:	84 c0                	test   %al,%al
f0104658:	74 07                	je     f0104661 <strcmp+0x26>
f010465a:	83 c1 01             	add    $0x1,%ecx
f010465d:	3a 02                	cmp    (%edx),%al
f010465f:	74 ee                	je     f010464f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104661:	0f b6 c0             	movzbl %al,%eax
f0104664:	0f b6 12             	movzbl (%edx),%edx
f0104667:	29 d0                	sub    %edx,%eax
}
f0104669:	5d                   	pop    %ebp
f010466a:	c3                   	ret    

f010466b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010466b:	55                   	push   %ebp
f010466c:	89 e5                	mov    %esp,%ebp
f010466e:	53                   	push   %ebx
f010466f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104672:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104675:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104678:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010467d:	85 d2                	test   %edx,%edx
f010467f:	74 28                	je     f01046a9 <strncmp+0x3e>
f0104681:	0f b6 01             	movzbl (%ecx),%eax
f0104684:	84 c0                	test   %al,%al
f0104686:	74 24                	je     f01046ac <strncmp+0x41>
f0104688:	3a 03                	cmp    (%ebx),%al
f010468a:	75 20                	jne    f01046ac <strncmp+0x41>
f010468c:	83 ea 01             	sub    $0x1,%edx
f010468f:	74 13                	je     f01046a4 <strncmp+0x39>
		n--, p++, q++;
f0104691:	83 c1 01             	add    $0x1,%ecx
f0104694:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104697:	0f b6 01             	movzbl (%ecx),%eax
f010469a:	84 c0                	test   %al,%al
f010469c:	74 0e                	je     f01046ac <strncmp+0x41>
f010469e:	3a 03                	cmp    (%ebx),%al
f01046a0:	74 ea                	je     f010468c <strncmp+0x21>
f01046a2:	eb 08                	jmp    f01046ac <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01046a4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01046a9:	5b                   	pop    %ebx
f01046aa:	5d                   	pop    %ebp
f01046ab:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01046ac:	0f b6 01             	movzbl (%ecx),%eax
f01046af:	0f b6 13             	movzbl (%ebx),%edx
f01046b2:	29 d0                	sub    %edx,%eax
f01046b4:	eb f3                	jmp    f01046a9 <strncmp+0x3e>

f01046b6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01046b6:	55                   	push   %ebp
f01046b7:	89 e5                	mov    %esp,%ebp
f01046b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01046bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046c0:	0f b6 10             	movzbl (%eax),%edx
f01046c3:	84 d2                	test   %dl,%dl
f01046c5:	74 1c                	je     f01046e3 <strchr+0x2d>
		if (*s == c)
f01046c7:	38 ca                	cmp    %cl,%dl
f01046c9:	75 09                	jne    f01046d4 <strchr+0x1e>
f01046cb:	eb 1b                	jmp    f01046e8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01046cd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01046d0:	38 ca                	cmp    %cl,%dl
f01046d2:	74 14                	je     f01046e8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01046d4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01046d8:	84 d2                	test   %dl,%dl
f01046da:	75 f1                	jne    f01046cd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01046dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01046e1:	eb 05                	jmp    f01046e8 <strchr+0x32>
f01046e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01046e8:	5d                   	pop    %ebp
f01046e9:	c3                   	ret    

f01046ea <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01046ea:	55                   	push   %ebp
f01046eb:	89 e5                	mov    %esp,%ebp
f01046ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01046f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01046f4:	0f b6 10             	movzbl (%eax),%edx
f01046f7:	84 d2                	test   %dl,%dl
f01046f9:	74 14                	je     f010470f <strfind+0x25>
		if (*s == c)
f01046fb:	38 ca                	cmp    %cl,%dl
f01046fd:	75 06                	jne    f0104705 <strfind+0x1b>
f01046ff:	eb 0e                	jmp    f010470f <strfind+0x25>
f0104701:	38 ca                	cmp    %cl,%dl
f0104703:	74 0a                	je     f010470f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104705:	83 c0 01             	add    $0x1,%eax
f0104708:	0f b6 10             	movzbl (%eax),%edx
f010470b:	84 d2                	test   %dl,%dl
f010470d:	75 f2                	jne    f0104701 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010470f:	5d                   	pop    %ebp
f0104710:	c3                   	ret    

f0104711 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104711:	55                   	push   %ebp
f0104712:	89 e5                	mov    %esp,%ebp
f0104714:	83 ec 0c             	sub    $0xc,%esp
f0104717:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010471a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010471d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104720:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104723:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104726:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104729:	85 c9                	test   %ecx,%ecx
f010472b:	74 30                	je     f010475d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010472d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104733:	75 25                	jne    f010475a <memset+0x49>
f0104735:	f6 c1 03             	test   $0x3,%cl
f0104738:	75 20                	jne    f010475a <memset+0x49>
		c &= 0xFF;
f010473a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010473d:	89 d3                	mov    %edx,%ebx
f010473f:	c1 e3 08             	shl    $0x8,%ebx
f0104742:	89 d6                	mov    %edx,%esi
f0104744:	c1 e6 18             	shl    $0x18,%esi
f0104747:	89 d0                	mov    %edx,%eax
f0104749:	c1 e0 10             	shl    $0x10,%eax
f010474c:	09 f0                	or     %esi,%eax
f010474e:	09 d0                	or     %edx,%eax
f0104750:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104752:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104755:	fc                   	cld    
f0104756:	f3 ab                	rep stos %eax,%es:(%edi)
f0104758:	eb 03                	jmp    f010475d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010475a:	fc                   	cld    
f010475b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010475d:	89 f8                	mov    %edi,%eax
f010475f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104762:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104765:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104768:	89 ec                	mov    %ebp,%esp
f010476a:	5d                   	pop    %ebp
f010476b:	c3                   	ret    

f010476c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010476c:	55                   	push   %ebp
f010476d:	89 e5                	mov    %esp,%ebp
f010476f:	83 ec 08             	sub    $0x8,%esp
f0104772:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104775:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104778:	8b 45 08             	mov    0x8(%ebp),%eax
f010477b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010477e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104781:	39 c6                	cmp    %eax,%esi
f0104783:	73 36                	jae    f01047bb <memmove+0x4f>
f0104785:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104788:	39 d0                	cmp    %edx,%eax
f010478a:	73 2f                	jae    f01047bb <memmove+0x4f>
		s += n;
		d += n;
f010478c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010478f:	f6 c2 03             	test   $0x3,%dl
f0104792:	75 1b                	jne    f01047af <memmove+0x43>
f0104794:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010479a:	75 13                	jne    f01047af <memmove+0x43>
f010479c:	f6 c1 03             	test   $0x3,%cl
f010479f:	75 0e                	jne    f01047af <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01047a1:	83 ef 04             	sub    $0x4,%edi
f01047a4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01047a7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01047aa:	fd                   	std    
f01047ab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047ad:	eb 09                	jmp    f01047b8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01047af:	83 ef 01             	sub    $0x1,%edi
f01047b2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01047b5:	fd                   	std    
f01047b6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01047b8:	fc                   	cld    
f01047b9:	eb 20                	jmp    f01047db <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01047bb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01047c1:	75 13                	jne    f01047d6 <memmove+0x6a>
f01047c3:	a8 03                	test   $0x3,%al
f01047c5:	75 0f                	jne    f01047d6 <memmove+0x6a>
f01047c7:	f6 c1 03             	test   $0x3,%cl
f01047ca:	75 0a                	jne    f01047d6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01047cc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01047cf:	89 c7                	mov    %eax,%edi
f01047d1:	fc                   	cld    
f01047d2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01047d4:	eb 05                	jmp    f01047db <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01047d6:	89 c7                	mov    %eax,%edi
f01047d8:	fc                   	cld    
f01047d9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01047db:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01047de:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01047e1:	89 ec                	mov    %ebp,%esp
f01047e3:	5d                   	pop    %ebp
f01047e4:	c3                   	ret    

f01047e5 <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01047e5:	55                   	push   %ebp
f01047e6:	89 e5                	mov    %esp,%ebp
f01047e8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01047eb:	8b 45 10             	mov    0x10(%ebp),%eax
f01047ee:	89 44 24 08          	mov    %eax,0x8(%esp)
f01047f2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01047f5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01047f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01047fc:	89 04 24             	mov    %eax,(%esp)
f01047ff:	e8 68 ff ff ff       	call   f010476c <memmove>
}
f0104804:	c9                   	leave  
f0104805:	c3                   	ret    

f0104806 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104806:	55                   	push   %ebp
f0104807:	89 e5                	mov    %esp,%ebp
f0104809:	57                   	push   %edi
f010480a:	56                   	push   %esi
f010480b:	53                   	push   %ebx
f010480c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010480f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104812:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104815:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010481a:	85 ff                	test   %edi,%edi
f010481c:	74 37                	je     f0104855 <memcmp+0x4f>
		if (*s1 != *s2)
f010481e:	0f b6 03             	movzbl (%ebx),%eax
f0104821:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104824:	83 ef 01             	sub    $0x1,%edi
f0104827:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010482c:	38 c8                	cmp    %cl,%al
f010482e:	74 1c                	je     f010484c <memcmp+0x46>
f0104830:	eb 10                	jmp    f0104842 <memcmp+0x3c>
f0104832:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104837:	83 c2 01             	add    $0x1,%edx
f010483a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010483e:	38 c8                	cmp    %cl,%al
f0104840:	74 0a                	je     f010484c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0104842:	0f b6 c0             	movzbl %al,%eax
f0104845:	0f b6 c9             	movzbl %cl,%ecx
f0104848:	29 c8                	sub    %ecx,%eax
f010484a:	eb 09                	jmp    f0104855 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010484c:	39 fa                	cmp    %edi,%edx
f010484e:	75 e2                	jne    f0104832 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104850:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104855:	5b                   	pop    %ebx
f0104856:	5e                   	pop    %esi
f0104857:	5f                   	pop    %edi
f0104858:	5d                   	pop    %ebp
f0104859:	c3                   	ret    

f010485a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010485a:	55                   	push   %ebp
f010485b:	89 e5                	mov    %esp,%ebp
f010485d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104860:	89 c2                	mov    %eax,%edx
f0104862:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104865:	39 d0                	cmp    %edx,%eax
f0104867:	73 19                	jae    f0104882 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104869:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010486d:	38 08                	cmp    %cl,(%eax)
f010486f:	75 06                	jne    f0104877 <memfind+0x1d>
f0104871:	eb 0f                	jmp    f0104882 <memfind+0x28>
f0104873:	38 08                	cmp    %cl,(%eax)
f0104875:	74 0b                	je     f0104882 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104877:	83 c0 01             	add    $0x1,%eax
f010487a:	39 d0                	cmp    %edx,%eax
f010487c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104880:	75 f1                	jne    f0104873 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104882:	5d                   	pop    %ebp
f0104883:	c3                   	ret    

f0104884 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104884:	55                   	push   %ebp
f0104885:	89 e5                	mov    %esp,%ebp
f0104887:	57                   	push   %edi
f0104888:	56                   	push   %esi
f0104889:	53                   	push   %ebx
f010488a:	8b 55 08             	mov    0x8(%ebp),%edx
f010488d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104890:	0f b6 02             	movzbl (%edx),%eax
f0104893:	3c 20                	cmp    $0x20,%al
f0104895:	74 04                	je     f010489b <strtol+0x17>
f0104897:	3c 09                	cmp    $0x9,%al
f0104899:	75 0e                	jne    f01048a9 <strtol+0x25>
		s++;
f010489b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010489e:	0f b6 02             	movzbl (%edx),%eax
f01048a1:	3c 20                	cmp    $0x20,%al
f01048a3:	74 f6                	je     f010489b <strtol+0x17>
f01048a5:	3c 09                	cmp    $0x9,%al
f01048a7:	74 f2                	je     f010489b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01048a9:	3c 2b                	cmp    $0x2b,%al
f01048ab:	75 0a                	jne    f01048b7 <strtol+0x33>
		s++;
f01048ad:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01048b0:	bf 00 00 00 00       	mov    $0x0,%edi
f01048b5:	eb 10                	jmp    f01048c7 <strtol+0x43>
f01048b7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01048bc:	3c 2d                	cmp    $0x2d,%al
f01048be:	75 07                	jne    f01048c7 <strtol+0x43>
		s++, neg = 1;
f01048c0:	83 c2 01             	add    $0x1,%edx
f01048c3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01048c7:	85 db                	test   %ebx,%ebx
f01048c9:	0f 94 c0             	sete   %al
f01048cc:	74 05                	je     f01048d3 <strtol+0x4f>
f01048ce:	83 fb 10             	cmp    $0x10,%ebx
f01048d1:	75 15                	jne    f01048e8 <strtol+0x64>
f01048d3:	80 3a 30             	cmpb   $0x30,(%edx)
f01048d6:	75 10                	jne    f01048e8 <strtol+0x64>
f01048d8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01048dc:	75 0a                	jne    f01048e8 <strtol+0x64>
		s += 2, base = 16;
f01048de:	83 c2 02             	add    $0x2,%edx
f01048e1:	bb 10 00 00 00       	mov    $0x10,%ebx
f01048e6:	eb 13                	jmp    f01048fb <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f01048e8:	84 c0                	test   %al,%al
f01048ea:	74 0f                	je     f01048fb <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01048ec:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01048f1:	80 3a 30             	cmpb   $0x30,(%edx)
f01048f4:	75 05                	jne    f01048fb <strtol+0x77>
		s++, base = 8;
f01048f6:	83 c2 01             	add    $0x1,%edx
f01048f9:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01048fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0104900:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104902:	0f b6 0a             	movzbl (%edx),%ecx
f0104905:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104908:	80 fb 09             	cmp    $0x9,%bl
f010490b:	77 08                	ja     f0104915 <strtol+0x91>
			dig = *s - '0';
f010490d:	0f be c9             	movsbl %cl,%ecx
f0104910:	83 e9 30             	sub    $0x30,%ecx
f0104913:	eb 1e                	jmp    f0104933 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104915:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104918:	80 fb 19             	cmp    $0x19,%bl
f010491b:	77 08                	ja     f0104925 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010491d:	0f be c9             	movsbl %cl,%ecx
f0104920:	83 e9 57             	sub    $0x57,%ecx
f0104923:	eb 0e                	jmp    f0104933 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104925:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104928:	80 fb 19             	cmp    $0x19,%bl
f010492b:	77 14                	ja     f0104941 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010492d:	0f be c9             	movsbl %cl,%ecx
f0104930:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104933:	39 f1                	cmp    %esi,%ecx
f0104935:	7d 0e                	jge    f0104945 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104937:	83 c2 01             	add    $0x1,%edx
f010493a:	0f af c6             	imul   %esi,%eax
f010493d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010493f:	eb c1                	jmp    f0104902 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104941:	89 c1                	mov    %eax,%ecx
f0104943:	eb 02                	jmp    f0104947 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104945:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104947:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010494b:	74 05                	je     f0104952 <strtol+0xce>
		*endptr = (char *) s;
f010494d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104950:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104952:	89 ca                	mov    %ecx,%edx
f0104954:	f7 da                	neg    %edx
f0104956:	85 ff                	test   %edi,%edi
f0104958:	0f 45 c2             	cmovne %edx,%eax
}
f010495b:	5b                   	pop    %ebx
f010495c:	5e                   	pop    %esi
f010495d:	5f                   	pop    %edi
f010495e:	5d                   	pop    %ebp
f010495f:	c3                   	ret    

f0104960 <__udivdi3>:
f0104960:	83 ec 1c             	sub    $0x1c,%esp
f0104963:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104967:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010496b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010496f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104973:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104977:	8b 74 24 24          	mov    0x24(%esp),%esi
f010497b:	85 ff                	test   %edi,%edi
f010497d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104981:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104985:	89 cd                	mov    %ecx,%ebp
f0104987:	89 44 24 04          	mov    %eax,0x4(%esp)
f010498b:	75 33                	jne    f01049c0 <__udivdi3+0x60>
f010498d:	39 f1                	cmp    %esi,%ecx
f010498f:	77 57                	ja     f01049e8 <__udivdi3+0x88>
f0104991:	85 c9                	test   %ecx,%ecx
f0104993:	75 0b                	jne    f01049a0 <__udivdi3+0x40>
f0104995:	b8 01 00 00 00       	mov    $0x1,%eax
f010499a:	31 d2                	xor    %edx,%edx
f010499c:	f7 f1                	div    %ecx
f010499e:	89 c1                	mov    %eax,%ecx
f01049a0:	89 f0                	mov    %esi,%eax
f01049a2:	31 d2                	xor    %edx,%edx
f01049a4:	f7 f1                	div    %ecx
f01049a6:	89 c6                	mov    %eax,%esi
f01049a8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01049ac:	f7 f1                	div    %ecx
f01049ae:	89 f2                	mov    %esi,%edx
f01049b0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01049b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01049b8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01049bc:	83 c4 1c             	add    $0x1c,%esp
f01049bf:	c3                   	ret    
f01049c0:	31 d2                	xor    %edx,%edx
f01049c2:	31 c0                	xor    %eax,%eax
f01049c4:	39 f7                	cmp    %esi,%edi
f01049c6:	77 e8                	ja     f01049b0 <__udivdi3+0x50>
f01049c8:	0f bd cf             	bsr    %edi,%ecx
f01049cb:	83 f1 1f             	xor    $0x1f,%ecx
f01049ce:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01049d2:	75 2c                	jne    f0104a00 <__udivdi3+0xa0>
f01049d4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f01049d8:	76 04                	jbe    f01049de <__udivdi3+0x7e>
f01049da:	39 f7                	cmp    %esi,%edi
f01049dc:	73 d2                	jae    f01049b0 <__udivdi3+0x50>
f01049de:	31 d2                	xor    %edx,%edx
f01049e0:	b8 01 00 00 00       	mov    $0x1,%eax
f01049e5:	eb c9                	jmp    f01049b0 <__udivdi3+0x50>
f01049e7:	90                   	nop
f01049e8:	89 f2                	mov    %esi,%edx
f01049ea:	f7 f1                	div    %ecx
f01049ec:	31 d2                	xor    %edx,%edx
f01049ee:	8b 74 24 10          	mov    0x10(%esp),%esi
f01049f2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01049f6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01049fa:	83 c4 1c             	add    $0x1c,%esp
f01049fd:	c3                   	ret    
f01049fe:	66 90                	xchg   %ax,%ax
f0104a00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104a05:	b8 20 00 00 00       	mov    $0x20,%eax
f0104a0a:	89 ea                	mov    %ebp,%edx
f0104a0c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104a10:	d3 e7                	shl    %cl,%edi
f0104a12:	89 c1                	mov    %eax,%ecx
f0104a14:	d3 ea                	shr    %cl,%edx
f0104a16:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104a1b:	09 fa                	or     %edi,%edx
f0104a1d:	89 f7                	mov    %esi,%edi
f0104a1f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104a23:	89 f2                	mov    %esi,%edx
f0104a25:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104a29:	d3 e5                	shl    %cl,%ebp
f0104a2b:	89 c1                	mov    %eax,%ecx
f0104a2d:	d3 ef                	shr    %cl,%edi
f0104a2f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104a34:	d3 e2                	shl    %cl,%edx
f0104a36:	89 c1                	mov    %eax,%ecx
f0104a38:	d3 ee                	shr    %cl,%esi
f0104a3a:	09 d6                	or     %edx,%esi
f0104a3c:	89 fa                	mov    %edi,%edx
f0104a3e:	89 f0                	mov    %esi,%eax
f0104a40:	f7 74 24 0c          	divl   0xc(%esp)
f0104a44:	89 d7                	mov    %edx,%edi
f0104a46:	89 c6                	mov    %eax,%esi
f0104a48:	f7 e5                	mul    %ebp
f0104a4a:	39 d7                	cmp    %edx,%edi
f0104a4c:	72 22                	jb     f0104a70 <__udivdi3+0x110>
f0104a4e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104a52:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104a57:	d3 e5                	shl    %cl,%ebp
f0104a59:	39 c5                	cmp    %eax,%ebp
f0104a5b:	73 04                	jae    f0104a61 <__udivdi3+0x101>
f0104a5d:	39 d7                	cmp    %edx,%edi
f0104a5f:	74 0f                	je     f0104a70 <__udivdi3+0x110>
f0104a61:	89 f0                	mov    %esi,%eax
f0104a63:	31 d2                	xor    %edx,%edx
f0104a65:	e9 46 ff ff ff       	jmp    f01049b0 <__udivdi3+0x50>
f0104a6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104a70:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104a73:	31 d2                	xor    %edx,%edx
f0104a75:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104a79:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104a7d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104a81:	83 c4 1c             	add    $0x1c,%esp
f0104a84:	c3                   	ret    
	...

f0104a90 <__umoddi3>:
f0104a90:	83 ec 1c             	sub    $0x1c,%esp
f0104a93:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104a97:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0104a9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0104a9f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104aa3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104aa7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0104aab:	85 ed                	test   %ebp,%ebp
f0104aad:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104ab1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ab5:	89 cf                	mov    %ecx,%edi
f0104ab7:	89 04 24             	mov    %eax,(%esp)
f0104aba:	89 f2                	mov    %esi,%edx
f0104abc:	75 1a                	jne    f0104ad8 <__umoddi3+0x48>
f0104abe:	39 f1                	cmp    %esi,%ecx
f0104ac0:	76 4e                	jbe    f0104b10 <__umoddi3+0x80>
f0104ac2:	f7 f1                	div    %ecx
f0104ac4:	89 d0                	mov    %edx,%eax
f0104ac6:	31 d2                	xor    %edx,%edx
f0104ac8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104acc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104ad0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104ad4:	83 c4 1c             	add    $0x1c,%esp
f0104ad7:	c3                   	ret    
f0104ad8:	39 f5                	cmp    %esi,%ebp
f0104ada:	77 54                	ja     f0104b30 <__umoddi3+0xa0>
f0104adc:	0f bd c5             	bsr    %ebp,%eax
f0104adf:	83 f0 1f             	xor    $0x1f,%eax
f0104ae2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ae6:	75 60                	jne    f0104b48 <__umoddi3+0xb8>
f0104ae8:	3b 0c 24             	cmp    (%esp),%ecx
f0104aeb:	0f 87 07 01 00 00    	ja     f0104bf8 <__umoddi3+0x168>
f0104af1:	89 f2                	mov    %esi,%edx
f0104af3:	8b 34 24             	mov    (%esp),%esi
f0104af6:	29 ce                	sub    %ecx,%esi
f0104af8:	19 ea                	sbb    %ebp,%edx
f0104afa:	89 34 24             	mov    %esi,(%esp)
f0104afd:	8b 04 24             	mov    (%esp),%eax
f0104b00:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104b04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104b08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104b0c:	83 c4 1c             	add    $0x1c,%esp
f0104b0f:	c3                   	ret    
f0104b10:	85 c9                	test   %ecx,%ecx
f0104b12:	75 0b                	jne    f0104b1f <__umoddi3+0x8f>
f0104b14:	b8 01 00 00 00       	mov    $0x1,%eax
f0104b19:	31 d2                	xor    %edx,%edx
f0104b1b:	f7 f1                	div    %ecx
f0104b1d:	89 c1                	mov    %eax,%ecx
f0104b1f:	89 f0                	mov    %esi,%eax
f0104b21:	31 d2                	xor    %edx,%edx
f0104b23:	f7 f1                	div    %ecx
f0104b25:	8b 04 24             	mov    (%esp),%eax
f0104b28:	f7 f1                	div    %ecx
f0104b2a:	eb 98                	jmp    f0104ac4 <__umoddi3+0x34>
f0104b2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104b30:	89 f2                	mov    %esi,%edx
f0104b32:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104b36:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104b3a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104b3e:	83 c4 1c             	add    $0x1c,%esp
f0104b41:	c3                   	ret    
f0104b42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104b48:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b4d:	89 e8                	mov    %ebp,%eax
f0104b4f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104b54:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104b58:	89 fa                	mov    %edi,%edx
f0104b5a:	d3 e0                	shl    %cl,%eax
f0104b5c:	89 e9                	mov    %ebp,%ecx
f0104b5e:	d3 ea                	shr    %cl,%edx
f0104b60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b65:	09 c2                	or     %eax,%edx
f0104b67:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104b6b:	89 14 24             	mov    %edx,(%esp)
f0104b6e:	89 f2                	mov    %esi,%edx
f0104b70:	d3 e7                	shl    %cl,%edi
f0104b72:	89 e9                	mov    %ebp,%ecx
f0104b74:	d3 ea                	shr    %cl,%edx
f0104b76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0104b7f:	d3 e6                	shl    %cl,%esi
f0104b81:	89 e9                	mov    %ebp,%ecx
f0104b83:	d3 e8                	shr    %cl,%eax
f0104b85:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104b8a:	09 f0                	or     %esi,%eax
f0104b8c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104b90:	f7 34 24             	divl   (%esp)
f0104b93:	d3 e6                	shl    %cl,%esi
f0104b95:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104b99:	89 d6                	mov    %edx,%esi
f0104b9b:	f7 e7                	mul    %edi
f0104b9d:	39 d6                	cmp    %edx,%esi
f0104b9f:	89 c1                	mov    %eax,%ecx
f0104ba1:	89 d7                	mov    %edx,%edi
f0104ba3:	72 3f                	jb     f0104be4 <__umoddi3+0x154>
f0104ba5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104ba9:	72 35                	jb     f0104be0 <__umoddi3+0x150>
f0104bab:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104baf:	29 c8                	sub    %ecx,%eax
f0104bb1:	19 fe                	sbb    %edi,%esi
f0104bb3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104bb8:	89 f2                	mov    %esi,%edx
f0104bba:	d3 e8                	shr    %cl,%eax
f0104bbc:	89 e9                	mov    %ebp,%ecx
f0104bbe:	d3 e2                	shl    %cl,%edx
f0104bc0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104bc5:	09 d0                	or     %edx,%eax
f0104bc7:	89 f2                	mov    %esi,%edx
f0104bc9:	d3 ea                	shr    %cl,%edx
f0104bcb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104bcf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104bd3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104bd7:	83 c4 1c             	add    $0x1c,%esp
f0104bda:	c3                   	ret    
f0104bdb:	90                   	nop
f0104bdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104be0:	39 d6                	cmp    %edx,%esi
f0104be2:	75 c7                	jne    f0104bab <__umoddi3+0x11b>
f0104be4:	89 d7                	mov    %edx,%edi
f0104be6:	89 c1                	mov    %eax,%ecx
f0104be8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0104bec:	1b 3c 24             	sbb    (%esp),%edi
f0104bef:	eb ba                	jmp    f0104bab <__umoddi3+0x11b>
f0104bf1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104bf8:	39 f5                	cmp    %esi,%ebp
f0104bfa:	0f 82 f1 fe ff ff    	jb     f0104af1 <__umoddi3+0x61>
f0104c00:	e9 f8 fe ff ff       	jmp    f0104afd <__umoddi3+0x6d>
