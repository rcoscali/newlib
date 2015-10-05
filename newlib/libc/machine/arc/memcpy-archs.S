#include "asm.h"

#if defined (__HS__)

#ifdef __LITTLE_ENDIAN__
# define SHIFT_1(RX,RY,IMM)	asl	RX, RY, IMM	; <<
# define SHIFT_2(RX,RY,IMM)	lsr	RX, RY, IMM	; >>
# define MERGE_1(RX,RY,IMM)	asl	RX, RY, IMM
# define MERGE_2(RX,RY,IMM)
# define EXTRACT_1(RX,RY,IMM)	and	RX, RY, 0xFFFF
# define EXTRACT_2(RX,RY,IMM)	lsr	RX, RY, IMM
#else
# define SHIFT_1(RX,RY,IMM)	lsr	RX, RY, IMM	; >>
# define SHIFT_2(RX,RY,IMM)	asl	RX, RY, IMM	; <<
# define MERGE_1(RX,RY,IMM)	asl	RX, RY, IMM	; <<
# define MERGE_2(RX,RY,IMM)	asl	RX, RY, IMM	; <<
# define EXTRACT_1(RX,RY,IMM)	lsr	RX, RY, IMM
# define EXTRACT_2(RX,RY,IMM)	lsr	RX, RY, 0x08
#endif

#ifdef __LL64__
# define PREFETCH_READ(RX)	prefetch	[RX, 56]
# define PREFETCH_WRITE(RX)	prefetchw	[RX, 64]
# define LOADX(DST,RX)		ldd.ab	DST, [RX, 8]
# define STOREX(SRC,RX)		std.ab	SRC, [RX, 8]
# define ZOLSHFT		5
# define ZOLAND			0x1F
#else
# define PREFETCH_READ(RX)	prefetch	[RX, 28]
# define PREFETCH_WRITE(RX)	prefetchw	[RX, 32]
# define LOADX(DST,RX)		ld.ab	DST, [RX, 4]
# define STOREX(SRC,RX)		st.ab	SRC, [RX, 4]
# define ZOLSHFT		4
# define ZOLAND			0xF
#endif

ENTRY(memcpy)
	prefetch  [r1]		; Prefetch the read location
	prefetchw [r0]		; Prefetch the write location
	mov.f	0, r2
;;; if size is zero
	jz.d	[blink]
	mov	r3, r0		; don;t clobber ret val

;;; if size <= 8
	cmp	r2, 8
	bls.d	@.Lsmallchunk
	mov.f	lp_count, r2

;;; Convert len to Dwords, unfold x4
	lsr.f	lp_count, r2, ZOLSHFT
	lpnz	@.Lcopyfast
	;; LOOP START
	LOADX (r6, r1)
	PREFETCH_READ (r1)
	PREFETCH_WRITE (r3)
	LOADX (r8, r1)
	LOADX (r10, r1)
	LOADX (r4, r1)
	STOREX (r6, r3)
	STOREX (r8, r3)
	STOREX (r10, r3)
	STOREX (r4, r3)
.Lcopyfast:

#ifdef __LL64__
	and     r2, r2, ZOLAND	;Remaining 31 bytes
	lsr.f   lp_count, r2, 3	;Convert to 64-bit words.
	lpnz	@.Lcopy64b
	;; LOOP START
	ldd.ab	r6,[r1,8]
	std.ab	r6,[r3,8]
.Lcopy64b:

	and.f	lp_count, r2, 0x07 ; Last 7 bytes
#else
	and.f	lp_count, r2, ZOLAND
#endif

.Lsmallchunk:
	lpnz	@.Lcopyremainingbytes
	;; LOOP START
	ldb.ab	r5, [r1,1]
	stb.ab	r5, [r3,1]
.Lcopyremainingbytes:

	j	[blink]

ENDFUNC(memcpy)
#endif /* ARCHS */
