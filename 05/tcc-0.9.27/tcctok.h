/* keywords */
     DEF(TOK_INT, "int")
     DEF(TOK_VOID, "void")
     DEF(TOK_CHAR, "char")
     DEF(TOK_IF, "if")
     DEF(TOK_ELSE, "else")
     DEF(TOK_WHILE, "while")
     DEF(TOK_BREAK, "break")
     DEF(TOK_RETURN, "return")
     DEF(TOK_FOR, "for")
     DEF(TOK_EXTERN, "extern")
     DEF(TOK_STATIC, "static")
     DEF(TOK_UNSIGNED, "unsigned")
     DEF(TOK_GOTO, "goto")
     DEF(TOK_DO, "do")
     DEF(TOK_CONTINUE, "continue")
     DEF(TOK_SWITCH, "switch")
     DEF(TOK_CASE, "case")

     DEF(TOK_CONST1, "const")
     DEF(TOK_CONST2, "__const") /* gcc keyword */
     DEF(TOK_CONST3, "__const__") /* gcc keyword */
     DEF(TOK_VOLATILE1, "volatile")
     DEF(TOK_VOLATILE2, "__volatile") /* gcc keyword */
     DEF(TOK_VOLATILE3, "__volatile__") /* gcc keyword */
     DEF(TOK_LONG, "long")
     DEF(TOK_REGISTER, "register")
     DEF(TOK_SIGNED1, "signed")
     DEF(TOK_SIGNED2, "__signed") /* gcc keyword */
     DEF(TOK_SIGNED3, "__signed__") /* gcc keyword */
     DEF(TOK_AUTO, "auto")
     DEF(TOK_INLINE1, "inline")
     DEF(TOK_INLINE2, "__inline") /* gcc keyword */
     DEF(TOK_INLINE3, "__inline__") /* gcc keyword */
     DEF(TOK_RESTRICT1, "restrict")
     DEF(TOK_RESTRICT2, "__restrict")
     DEF(TOK_RESTRICT3, "__restrict__")
     DEF(TOK_EXTENSION, "__extension__") /* gcc keyword */

     DEF(TOK_GENERIC, "_Generic")

     DEF(TOK_FLOAT, "float")
     DEF(TOK_DOUBLE, "double")
     DEF(TOK_BOOL, "_Bool")
     DEF(TOK_SHORT, "short")
     DEF(TOK_STRUCT, "struct")
     DEF(TOK_UNION, "union")
     DEF(TOK_TYPEDEF, "typedef")
     DEF(TOK_DEFAULT, "default")
     DEF(TOK_ENUM, "enum")
     DEF(TOK_SIZEOF, "sizeof")
     DEF(TOK_ATTRIBUTE1, "__attribute")
     DEF(TOK_ATTRIBUTE2, "__attribute__")
     DEF(TOK_ALIGNOF1, "__alignof")
     DEF(TOK_ALIGNOF2, "__alignof__")
     DEF(TOK_TYPEOF1, "typeof")
     DEF(TOK_TYPEOF2, "__typeof")
     DEF(TOK_TYPEOF3, "__typeof__")
     DEF(TOK_LABEL, "__label__")
     DEF(TOK_ASM1, "asm")
     DEF(TOK_ASM2, "__asm")
     DEF(TOK_ASM3, "__asm__")

#ifdef TCC_TARGET_ARM64
     DEF(TOK_UINT128, "__uint128_t")
#endif

/*********************************************************************/
/* the following are not keywords. They are included to ease parsing */
/* preprocessor only */
     DEF(TOK_DEFINE, "define")
     DEF(TOK_INCLUDE, "include")
     DEF(TOK_INCLUDE_NEXT, "include_next")
     DEF(TOK_IFDEF, "ifdef")
     DEF(TOK_IFNDEF, "ifndef")
     DEF(TOK_ELIF, "elif")
     DEF(TOK_ENDIF, "endif")
     DEF(TOK_DEFINED, "defined")
     DEF(TOK_UNDEF, "undef")
     DEF(TOK_ERROR, "error")
     DEF(TOK_WARNING, "warning")
     DEF(TOK_LINE, "line")
     DEF(TOK_PRAGMA, "pragma")
     DEF(TOK___LINE__, "__LINE__")
     DEF(TOK___FILE__, "__FILE__")
     DEF(TOK___DATE__, "__DATE__")
     DEF(TOK___TIME__, "__TIME__")
     DEF(TOK___FUNCTION__, "__FUNCTION__")
     DEF(TOK___VA_ARGS__, "__VA_ARGS__")
     DEF(TOK___COUNTER__, "__COUNTER__")

/* special identifiers */
     DEF(TOK___FUNC__, "__func__")

/* special floating point values */
     DEF(TOK___NAN__, "__nan__")
     DEF(TOK___SNAN__, "__snan__")
     DEF(TOK___INF__, "__inf__")

/* attribute identifiers */
/* XXX: handle all tokens generically since speed is not critical */
     DEF(TOK_SECTION1, "section")
     DEF(TOK_SECTION2, "__section__")
     DEF(TOK_ALIGNED1, "aligned")
     DEF(TOK_ALIGNED2, "__aligned__")
     DEF(TOK_PACKED1, "packed")
     DEF(TOK_PACKED2, "__packed__")
     DEF(TOK_WEAK1, "weak")
     DEF(TOK_WEAK2, "__weak__")
     DEF(TOK_ALIAS1, "alias")
     DEF(TOK_ALIAS2, "__alias__")
     DEF(TOK_UNUSED1, "unused")
     DEF(TOK_UNUSED2, "__unused__")
     DEF(TOK_CDECL1, "cdecl")
     DEF(TOK_CDECL2, "__cdecl")
     DEF(TOK_CDECL3, "__cdecl__")
     DEF(TOK_STDCALL1, "stdcall")
     DEF(TOK_STDCALL2, "__stdcall")
     DEF(TOK_STDCALL3, "__stdcall__")
     DEF(TOK_FASTCALL1, "fastcall")
     DEF(TOK_FASTCALL2, "__fastcall")
     DEF(TOK_FASTCALL3, "__fastcall__")
     DEF(TOK_REGPARM1, "regparm")
     DEF(TOK_REGPARM2, "__regparm__")

     DEF(TOK_MODE, "__mode__")
     DEF(TOK_MODE_QI, "__QI__")
     DEF(TOK_MODE_DI, "__DI__")
     DEF(TOK_MODE_HI, "__HI__")
     DEF(TOK_MODE_SI, "__SI__")
     DEF(TOK_MODE_word, "__word__")

     DEF(TOK_DLLEXPORT, "dllexport")
     DEF(TOK_DLLIMPORT, "dllimport")
     DEF(TOK_NORETURN1, "noreturn")
     DEF(TOK_NORETURN2, "__noreturn__")
     DEF(TOK_VISIBILITY1, "visibility")
     DEF(TOK_VISIBILITY2, "__visibility__")

     DEF(TOK_builtin_types_compatible_p, "__builtin_types_compatible_p")
     DEF(TOK_builtin_choose_expr, "__builtin_choose_expr")
     DEF(TOK_builtin_constant_p, "__builtin_constant_p")
     DEF(TOK_builtin_frame_address, "__builtin_frame_address")
     DEF(TOK_builtin_return_address, "__builtin_return_address")
     DEF(TOK_builtin_expect, "__builtin_expect")
     /*DEF(TOK_builtin_va_list, "__builtin_va_list")*/
#if defined TCC_TARGET_PE && defined TCC_TARGET_X86_64
     DEF(TOK_builtin_va_start, "__builtin_va_start")
#elif defined TCC_TARGET_X86_64
     DEF(TOK_builtin_va_arg_types, "__builtin_va_arg_types")
#elif defined TCC_TARGET_ARM64
     DEF(TOK___va_start, "__va_start")
     DEF(TOK___va_arg, "__va_arg")
#endif

/* pragma */
     DEF(TOK_pack, "pack")
#if !defined(TCC_TARGET_I386) && !defined(TCC_TARGET_X86_64)
     /* already defined for assembler */
     DEF(TOK_ASM_push, "push")
     DEF(TOK_ASM_pop, "pop")
#endif
     DEF(TOK_comment, "comment")
     DEF(TOK_lib, "lib")
     DEF(TOK_push_macro, "push_macro")
     DEF(TOK_pop_macro, "pop_macro")
     DEF(TOK_once, "once")
     DEF(TOK_option, "option")

/* builtin functions or variables */
#ifndef TCC_ARM_EABI
     DEF(TOK_memcpy, "memcpy")
     DEF(TOK_memmove, "memmove")
     DEF(TOK_memset, "memset")
     DEF(TOK___divdi3, "__divdi3")
     DEF(TOK___moddi3, "__moddi3")
     DEF(TOK___udivdi3, "__udivdi3")
     DEF(TOK___umoddi3, "__umoddi3")
     DEF(TOK___ashrdi3, "__ashrdi3")
     DEF(TOK___lshrdi3, "__lshrdi3")
     DEF(TOK___ashldi3, "__ashldi3")
     DEF(TOK___floatundisf, "__floatundisf")
     DEF(TOK___floatundidf, "__floatundidf")
# ifndef TCC_ARM_VFP
     DEF(TOK___floatundixf, "__floatundixf")
     DEF(TOK___fixunsxfdi, "__fixunsxfdi")
# endif
     DEF(TOK___fixunssfdi, "__fixunssfdi")
     DEF(TOK___fixunsdfdi, "__fixunsdfdi")
#endif

#if defined TCC_TARGET_ARM
# ifdef TCC_ARM_EABI
     DEF(TOK_memcpy, "__aeabi_memcpy")
     DEF(TOK_memcpy4, "__aeabi_memcpy4")
     DEF(TOK_memcpy8, "__aeabi_memcpy8")
     DEF(TOK_memmove, "__aeabi_memmove")
     DEF(TOK_memset, "__aeabi_memset")
     DEF(TOK___aeabi_ldivmod, "__aeabi_ldivmod")
     DEF(TOK___aeabi_uldivmod, "__aeabi_uldivmod")
     DEF(TOK___aeabi_idivmod, "__aeabi_idivmod")
     DEF(TOK___aeabi_uidivmod, "__aeabi_uidivmod")
     DEF(TOK___divsi3, "__aeabi_idiv")
     DEF(TOK___udivsi3, "__aeabi_uidiv")
     DEF(TOK___floatdisf, "__aeabi_l2f")
     DEF(TOK___floatdidf, "__aeabi_l2d")
     DEF(TOK___fixsfdi, "__aeabi_f2lz")
     DEF(TOK___fixdfdi, "__aeabi_d2lz")
     DEF(TOK___ashrdi3, "__aeabi_lasr")
     DEF(TOK___lshrdi3, "__aeabi_llsr")
     DEF(TOK___ashldi3, "__aeabi_llsl")
     DEF(TOK___floatundisf, "__aeabi_ul2f")
     DEF(TOK___floatundidf, "__aeabi_ul2d")
     DEF(TOK___fixunssfdi, "__aeabi_f2ulz")
     DEF(TOK___fixunsdfdi, "__aeabi_d2ulz")
# else
     DEF(TOK___modsi3, "__modsi3")
     DEF(TOK___umodsi3, "__umodsi3")
     DEF(TOK___divsi3, "__divsi3")
     DEF(TOK___udivsi3, "__udivsi3")
     DEF(TOK___floatdisf, "__floatdisf")
     DEF(TOK___floatdidf, "__floatdidf")
#  ifndef TCC_ARM_VFP
     DEF(TOK___floatdixf, "__floatdixf")
     DEF(TOK___fixunssfsi, "__fixunssfsi")
     DEF(TOK___fixunsdfsi, "__fixunsdfsi")
     DEF(TOK___fixunsxfsi, "__fixunsxfsi")
     DEF(TOK___fixxfdi, "__fixxfdi")
#  endif
     DEF(TOK___fixsfdi, "__fixsfdi")
     DEF(TOK___fixdfdi, "__fixdfdi")
# endif
#endif

#if defined TCC_TARGET_C67
     DEF(TOK__divi, "_divi")
     DEF(TOK__divu, "_divu")
     DEF(TOK__divf, "_divf")
     DEF(TOK__divd, "_divd")
     DEF(TOK__remi, "_remi")
     DEF(TOK__remu, "_remu")
#endif

#if defined TCC_TARGET_I386
     DEF(TOK___fixsfdi, "__fixsfdi")
     DEF(TOK___fixdfdi, "__fixdfdi")
     DEF(TOK___fixxfdi, "__fixxfdi")
#endif

#if defined TCC_TARGET_I386 || defined TCC_TARGET_X86_64
     DEF(TOK_alloca, "alloca")
#endif

#if defined TCC_TARGET_PE
     DEF(TOK___chkstk, "__chkstk")
#endif
#ifdef TCC_TARGET_ARM64
     DEF(TOK___arm64_clear_cache, "__arm64_clear_cache")
     DEF(TOK___addtf3, "__addtf3")
     DEF(TOK___subtf3, "__subtf3")
     DEF(TOK___multf3, "__multf3")
     DEF(TOK___divtf3, "__divtf3")
     DEF(TOK___extendsftf2, "__extendsftf2")
     DEF(TOK___extenddftf2, "__extenddftf2")
     DEF(TOK___trunctfsf2, "__trunctfsf2")
     DEF(TOK___trunctfdf2, "__trunctfdf2")
     DEF(TOK___fixtfsi, "__fixtfsi")
     DEF(TOK___fixtfdi, "__fixtfdi")
     DEF(TOK___fixunstfsi, "__fixunstfsi")
     DEF(TOK___fixunstfdi, "__fixunstfdi")
     DEF(TOK___floatsitf, "__floatsitf")
     DEF(TOK___floatditf, "__floatditf")
     DEF(TOK___floatunsitf, "__floatunsitf")
     DEF(TOK___floatunditf, "__floatunditf")
     DEF(TOK___eqtf2, "__eqtf2")
     DEF(TOK___netf2, "__netf2")
     DEF(TOK___lttf2, "__lttf2")
     DEF(TOK___letf2, "__letf2")
     DEF(TOK___gttf2, "__gttf2")
     DEF(TOK___getf2, "__getf2")
#endif

/* bound checking symbols */
#ifdef CONFIG_TCC_BCHECK
     DEF(TOK___bound_ptr_add, "__bound_ptr_add")
     DEF(TOK___bound_ptr_indir1, "__bound_ptr_indir1")
     DEF(TOK___bound_ptr_indir2, "__bound_ptr_indir2")
     DEF(TOK___bound_ptr_indir4, "__bound_ptr_indir4")
     DEF(TOK___bound_ptr_indir8, "__bound_ptr_indir8")
     DEF(TOK___bound_ptr_indir12, "__bound_ptr_indir12")
     DEF(TOK___bound_ptr_indir16, "__bound_ptr_indir16")
     DEF(TOK___bound_main_arg, "__bound_main_arg")
     DEF(TOK___bound_local_new, "__bound_local_new")
     DEF(TOK___bound_local_delete, "__bound_local_delete")
# ifdef TCC_TARGET_PE
     DEF(TOK_malloc, "malloc")
     DEF(TOK_free, "free")
     DEF(TOK_realloc, "realloc")
     DEF(TOK_memalign, "memalign")
     DEF(TOK_calloc, "calloc")
# endif
     DEF(TOK_strlen, "strlen")
     DEF(TOK_strcpy, "strcpy")
#endif

/* Tiny Assembler */
 DEF_ASMDIR(byte)              /* must be first directive */
 DEF_ASMDIR(word)
 DEF_ASMDIR(align)
 DEF_ASMDIR(balign)
 DEF_ASMDIR(p2align)
 DEF_ASMDIR(set)
 DEF_ASMDIR(skip)
 DEF_ASMDIR(space)
 DEF_ASMDIR(string)
 DEF_ASMDIR(asciz)
 DEF_ASMDIR(ascii)
 DEF_ASMDIR(file)
 DEF_ASMDIR(globl)
 DEF_ASMDIR(global)
 DEF_ASMDIR(weak)
 DEF_ASMDIR(hidden)
 DEF_ASMDIR(ident)
 DEF_ASMDIR(size)
 DEF_ASMDIR(type)
 DEF_ASMDIR(text)
 DEF_ASMDIR(data)
 DEF_ASMDIR(bss)
 DEF_ASMDIR(previous)
 DEF_ASMDIR(pushsection)
 DEF_ASMDIR(popsection)
 DEF_ASMDIR(fill)
 DEF_ASMDIR(rept)
 DEF_ASMDIR(endr)
 DEF_ASMDIR(org)
 DEF_ASMDIR(quad)
#if defined(TCC_TARGET_I386)
 DEF_ASMDIR(code16)
 DEF_ASMDIR(code32)
#elif defined(TCC_TARGET_X86_64)
 DEF_ASMDIR(code64)
#endif
 DEF_ASMDIR(short)
 DEF_ASMDIR(long)
 DEF_ASMDIR(int)
 DEF_ASMDIR(section)            /* must be last directive */

#if defined TCC_TARGET_I386 || defined TCC_TARGET_X86_64

/* register */
 DEF_ASM(al)
 DEF_ASM(cl)
 DEF_ASM(dl)
 DEF_ASM(bl)
 DEF_ASM(ah)
 DEF_ASM(ch)
 DEF_ASM(dh)
 DEF_ASM(bh)
 DEF_ASM(ax)
 DEF_ASM(cx)
 DEF_ASM(dx)
 DEF_ASM(bx)
 DEF_ASM(sp)
 DEF_ASM(bp)
 DEF_ASM(si)
 DEF_ASM(di)
 DEF_ASM(eax)
 DEF_ASM(ecx)
 DEF_ASM(edx)
 DEF_ASM(ebx)
 DEF_ASM(esp)
 DEF_ASM(ebp)
 DEF_ASM(esi)
 DEF_ASM(edi)
#ifdef TCC_TARGET_X86_64
 DEF_ASM(rax)
 DEF_ASM(rcx)
 DEF_ASM(rdx)
 DEF_ASM(rbx)
 DEF_ASM(rsp)
 DEF_ASM(rbp)
 DEF_ASM(rsi)
 DEF_ASM(rdi)
#endif
 DEF_ASM(mm0)
 DEF_ASM(mm1)
 DEF_ASM(mm2)
 DEF_ASM(mm3)
 DEF_ASM(mm4)
 DEF_ASM(mm5)
 DEF_ASM(mm6)
 DEF_ASM(mm7)
 DEF_ASM(xmm0)
 DEF_ASM(xmm1)
 DEF_ASM(xmm2)
 DEF_ASM(xmm3)
 DEF_ASM(xmm4)
 DEF_ASM(xmm5)
 DEF_ASM(xmm6)
 DEF_ASM(xmm7)
 DEF_ASM(cr0)
 DEF_ASM(cr1)
 DEF_ASM(cr2)
 DEF_ASM(cr3)
 DEF_ASM(cr4)
 DEF_ASM(cr5)
 DEF_ASM(cr6)
 DEF_ASM(cr7)
 DEF_ASM(tr0)
 DEF_ASM(tr1)
 DEF_ASM(tr2)
 DEF_ASM(tr3)
 DEF_ASM(tr4)
 DEF_ASM(tr5)
 DEF_ASM(tr6)
 DEF_ASM(tr7)
 DEF_ASM(db0)
 DEF_ASM(db1)
 DEF_ASM(db2)
 DEF_ASM(db3)
 DEF_ASM(db4)
 DEF_ASM(db5)
 DEF_ASM(db6)
 DEF_ASM(db7)
 DEF_ASM(dr0)
 DEF_ASM(dr1)
 DEF_ASM(dr2)
 DEF_ASM(dr3)
 DEF_ASM(dr4)
 DEF_ASM(dr5)
 DEF_ASM(dr6)
 DEF_ASM(dr7)
 DEF_ASM(es)
 DEF_ASM(cs)
 DEF_ASM(ss)
 DEF_ASM(ds)
 DEF_ASM(fs)
 DEF_ASM(gs)
 DEF_ASM(st)
 DEF_ASM(rip)

#ifdef TCC_TARGET_X86_64
 /* The four low parts of sp/bp/si/di that exist only on
    x86-64 (encoding aliased to ah,ch,dh,dh when not using REX). */
 DEF_ASM(spl)
 DEF_ASM(bpl)
 DEF_ASM(sil)
 DEF_ASM(dil)
#endif
 /* generic two operands */
 DEF_BWLX(mov)

 DEF_BWLX(add)
 DEF_BWLX(or)
 DEF_BWLX(adc)
 DEF_BWLX(sbb)
 DEF_BWLX(and)
 DEF_BWLX(sub)
 DEF_BWLX(xor)
 DEF_BWLX(cmp)

 /* unary ops */
 DEF_BWLX(inc)
 DEF_BWLX(dec)
 DEF_BWLX(not)
 DEF_BWLX(neg)
 DEF_BWLX(mul)
 DEF_BWLX(imul)
 DEF_BWLX(div)
 DEF_BWLX(idiv)

 DEF_BWLX(xchg)
 DEF_BWLX(test)

 /* shifts */
 DEF_BWLX(rol)
 DEF_BWLX(ror)
 DEF_BWLX(rcl)
 DEF_BWLX(rcr)
 DEF_BWLX(shl)
 DEF_BWLX(shr)
 DEF_BWLX(sar)

 DEF_WLX(shld)
 DEF_WLX(shrd)

 DEF_ASM(pushw)
 DEF_ASM(pushl)
#ifdef TCC_TARGET_X86_64
 DEF_ASM(pushq)
#endif
 DEF_ASM(push)

 DEF_ASM(popw)
 DEF_ASM(popl)
#ifdef TCC_TARGET_X86_64
 DEF_ASM(popq)
#endif
 DEF_ASM(pop)

 DEF_BWL(in)
 DEF_BWL(out)

 DEF_WLX(movzb)
 DEF_ASM(movzwl)
 DEF_ASM(movsbw)
 DEF_ASM(movsbl)
 DEF_ASM(movswl)
#ifdef TCC_TARGET_X86_64
 DEF_ASM(movsbq)
 DEF_ASM(movswq)
 DEF_ASM(movzwq)
 DEF_ASM(movslq)
#endif

 DEF_WLX(lea)

 DEF_ASM(les)
 DEF_ASM(lds)
 DEF_ASM(lss)
 DEF_ASM(lfs)
 DEF_ASM(lgs)

 DEF_ASM(call)
 DEF_ASM(jmp)
 DEF_ASM(lcall)
 DEF_ASM(ljmp)

 DEF_ASMTEST1(j)

 DEF_ASMTEST1(set)
 DEF_ASMTEST(set,b)
 DEF_ASMTEST1(cmov)

 DEF_WLX(bsf)
 DEF_WLX(bsr)
 DEF_WLX(bt)
 DEF_WLX(bts)
 DEF_WLX(btr)
 DEF_WLX(btc)

 DEF_WLX(lar)
 DEF_WLX(lsl)

 /* generic FP ops */
 DEF_FP(add)
 DEF_FP(mul)

 DEF_ASM(fcom)
 DEF_ASM(fcom_1) /* non existent op, just to have a regular table */
 DEF_FP1(com)

 DEF_FP(comp)
 DEF_FP(sub)
 DEF_FP(subr)
 DEF_FP(div)
 DEF_FP(divr)

 DEF_BWLX(xadd)
 DEF_BWLX(cmpxchg)

 /* string ops */
 DEF_BWLX(cmps)
 DEF_BWLX(scmp)
 DEF_BWL(ins)
 DEF_BWL(outs)
 DEF_BWLX(lods)
 DEF_BWLX(slod)
 DEF_BWLX(movs)
 DEF_BWLX(smov)
 DEF_BWLX(scas)
 DEF_BWLX(ssca)
 DEF_BWLX(stos)
 DEF_BWLX(ssto)

#define ALT(x)
#define DEF_ASM_OP0(name, opcode) DEF_ASM(name)
#define DEF_ASM_OP0L(name, opcode, group, instr_type)
#define DEF_ASM_OP1(name, opcode, group, instr_type, op0)
#define DEF_ASM_OP2(name, opcode, group, instr_type, op0, op1)
#define DEF_ASM_OP3(name, opcode, group, instr_type, op0, op1, op2)
     DEF_ASM_OP0(clc, 0xf8) /* must be first OP0 */
     DEF_ASM_OP0(cld, 0xfc)
     DEF_ASM_OP0(cli, 0xfa)
     DEF_ASM_OP0(clts, 0x0f06)
     DEF_ASM_OP0(cmc, 0xf5)
     DEF_ASM_OP0(lahf, 0x9f)
     DEF_ASM_OP0(sahf, 0x9e)
     DEF_ASM_OP0(pushfq, 0x9c)
     DEF_ASM_OP0(popfq, 0x9d)
     DEF_ASM_OP0(pushf, 0x9c)
     DEF_ASM_OP0(popf, 0x9d)
     DEF_ASM_OP0(stc, 0xf9)
     DEF_ASM_OP0(std, 0xfd)
     DEF_ASM_OP0(sti, 0xfb)
     DEF_ASM_OP0(aaa, 0x37)
     DEF_ASM_OP0(aas, 0x3f)
     DEF_ASM_OP0(daa, 0x27)
     DEF_ASM_OP0(das, 0x2f)
     DEF_ASM_OP0(aad, 0xd50a)
     DEF_ASM_OP0(aam, 0xd40a)
     DEF_ASM_OP0(cbw, 0x6698)
     DEF_ASM_OP0(cwd, 0x6699)
     DEF_ASM_OP0(cwde, 0x98)
     DEF_ASM_OP0(cdq, 0x99)
     DEF_ASM_OP0(cbtw, 0x6698)
     DEF_ASM_OP0(cwtl, 0x98)
     DEF_ASM_OP0(cwtd, 0x6699)
     DEF_ASM_OP0(cltd, 0x99)
     DEF_ASM_OP0(cqto, 0x4899)
     DEF_ASM_OP0(int3, 0xcc)
     DEF_ASM_OP0(into, 0xce)
     DEF_ASM_OP0(iret, 0xcf)
     DEF_ASM_OP0(rsm, 0x0faa)
     DEF_ASM_OP0(hlt, 0xf4)
     DEF_ASM_OP0(wait, 0x9b)
     DEF_ASM_OP0(nop, 0x90)
     DEF_ASM_OP0(pause, 0xf390)
     DEF_ASM_OP0(xlat, 0xd7)

     /* strings */
ALT(DEF_ASM_OP0L(cmpsb, 0xa6, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(scmpb, 0xa6, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(insb, 0x6c, 0, OPC_BWL))
ALT(DEF_ASM_OP0L(outsb, 0x6e, 0, OPC_BWL))

ALT(DEF_ASM_OP0L(lodsb, 0xac, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(slodb, 0xac, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(movsb, 0xa4, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(smovb, 0xa4, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(scasb, 0xae, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(sscab, 0xae, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(stosb, 0xaa, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(sstob, 0xaa, 0, OPC_BWLX))

     /* bits */

ALT(DEF_ASM_OP2(bsfw, 0x0fbc, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(bsrw, 0x0fbd, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))

ALT(DEF_ASM_OP2(btw, 0x0fa3, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btw, 0x0fba, 4, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btsw, 0x0fab, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btsw, 0x0fba, 5, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btrw, 0x0fb3, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btrw, 0x0fba, 6, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btcw, 0x0fbb, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btcw, 0x0fba, 7, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

     /* prefixes */
     DEF_ASM_OP0(lock, 0xf0)
     DEF_ASM_OP0(rep, 0xf3)
     DEF_ASM_OP0(repe, 0xf3)
     DEF_ASM_OP0(repz, 0xf3)
     DEF_ASM_OP0(repne, 0xf2)
     DEF_ASM_OP0(repnz, 0xf2)

     DEF_ASM_OP0(invd, 0x0f08)
     DEF_ASM_OP0(wbinvd, 0x0f09)
     DEF_ASM_OP0(cpuid, 0x0fa2)
     DEF_ASM_OP0(wrmsr, 0x0f30)
     DEF_ASM_OP0(rdtsc, 0x0f31)
     DEF_ASM_OP0(rdmsr, 0x0f32)
     DEF_ASM_OP0(rdpmc, 0x0f33)

     DEF_ASM_OP0(syscall, 0x0f05)
     DEF_ASM_OP0(sysret, 0x0f07)
     DEF_ASM_OP0L(sysretq, 0x480f07, 0, 0)
     DEF_ASM_OP0(ud2, 0x0f0b)

     /* NOTE: we took the same order as gas opcode definition order */
/* Right now we can't express the fact that 0xa1/0xa3 can't use $eax and a 
   32 bit moffset as operands.
ALT(DEF_ASM_OP2(movb, 0xa0, 0, OPC_BWLX, OPT_ADDR, OPT_EAX))
ALT(DEF_ASM_OP2(movb, 0xa2, 0, OPC_BWLX, OPT_EAX, OPT_ADDR)) */
ALT(DEF_ASM_OP2(movb, 0x88, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(movb, 0x8a, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
/* The moves are special: the 0xb8 form supports IM64 (the only insn that
   does) with REG64.  It doesn't support IM32 with REG64, it would use
   the full movabs form (64bit immediate).  For IM32->REG64 we prefer
   the 0xc7 opcode.  So disallow all 64bit forms and code the rest by hand. */
ALT(DEF_ASM_OP2(movb, 0xb0, 0, OPC_REG | OPC_BWLX, OPT_IM, OPT_REG))
ALT(DEF_ASM_OP2(mov,  0xb8, 0, OPC_REG, OPT_IM64, OPT_REG64))
ALT(DEF_ASM_OP2(movq, 0xb8, 0, OPC_REG, OPT_IM64, OPT_REG64))
ALT(DEF_ASM_OP2(movb, 0xc6, 0, OPC_MODRM | OPC_BWLX, OPT_IM, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP2(movw, 0x8c, 0, OPC_MODRM | OPC_WLX, OPT_SEG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(movw, 0x8e, 0, OPC_MODRM | OPC_WLX, OPT_EA | OPT_REG, OPT_SEG))

ALT(DEF_ASM_OP2(movw, 0x0f20, 0, OPC_MODRM | OPC_WLX, OPT_CR, OPT_REG64))
ALT(DEF_ASM_OP2(movw, 0x0f21, 0, OPC_MODRM | OPC_WLX, OPT_DB, OPT_REG64))
ALT(DEF_ASM_OP2(movw, 0x0f22, 0, OPC_MODRM | OPC_WLX, OPT_REG64, OPT_CR))
ALT(DEF_ASM_OP2(movw, 0x0f23, 0, OPC_MODRM | OPC_WLX, OPT_REG64, OPT_DB))

ALT(DEF_ASM_OP2(movsbw, 0x660fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REG16))
ALT(DEF_ASM_OP2(movsbl, 0x0fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movsbq, 0x0fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(movswl, 0x0fbf, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movswq, 0x0fbf, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP2(movslq, 0x63, 0, OPC_MODRM, OPT_REG32 | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP2(movzbw, 0x0fb6, 0, OPC_MODRM | OPC_WLX, OPT_REG8 | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(movzwl, 0x0fb7, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movzwq, 0x0fb7, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG))

ALT(DEF_ASM_OP1(pushq, 0x6a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(push, 0x6a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(pushw, 0x666a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(pushw, 0x50, 0, OPC_REG | OPC_WLX, OPT_REG64))
ALT(DEF_ASM_OP1(pushw, 0x50, 0, OPC_REG | OPC_WLX, OPT_REG16))
ALT(DEF_ASM_OP1(pushw, 0xff, 6, OPC_MODRM | OPC_WLX, OPT_REG64 | OPT_EA))
ALT(DEF_ASM_OP1(pushw, 0x6668, 0, 0, OPT_IM16))
ALT(DEF_ASM_OP1(pushw, 0x68, 0, OPC_WLX, OPT_IM32))
ALT(DEF_ASM_OP1(pushw, 0x06, 0, OPC_WLX, OPT_SEG))

ALT(DEF_ASM_OP1(popw, 0x58, 0, OPC_REG | OPC_WLX, OPT_REG64))
ALT(DEF_ASM_OP1(popw, 0x58, 0, OPC_REG | OPC_WLX, OPT_REG16))
ALT(DEF_ASM_OP1(popw, 0x8f, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP1(popw, 0x07, 0, OPC_WLX, OPT_SEG))

ALT(DEF_ASM_OP2(xchgw, 0x90, 0, OPC_REG | OPC_WLX, OPT_REGW, OPT_EAX))
ALT(DEF_ASM_OP2(xchgw, 0x90, 0, OPC_REG | OPC_WLX, OPT_EAX, OPT_REGW))
ALT(DEF_ASM_OP2(xchgb, 0x86, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(xchgb, 0x86, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))

ALT(DEF_ASM_OP2(inb, 0xe4, 0, OPC_BWL, OPT_IM8, OPT_EAX))
ALT(DEF_ASM_OP1(inb, 0xe4, 0, OPC_BWL, OPT_IM8))
ALT(DEF_ASM_OP2(inb, 0xec, 0, OPC_BWL, OPT_DX, OPT_EAX))
ALT(DEF_ASM_OP1(inb, 0xec, 0, OPC_BWL, OPT_DX))

ALT(DEF_ASM_OP2(outb, 0xe6, 0, OPC_BWL, OPT_EAX, OPT_IM8))
ALT(DEF_ASM_OP1(outb, 0xe6, 0, OPC_BWL, OPT_IM8))
ALT(DEF_ASM_OP2(outb, 0xee, 0, OPC_BWL, OPT_EAX, OPT_DX))
ALT(DEF_ASM_OP1(outb, 0xee, 0, OPC_BWL, OPT_DX))

ALT(DEF_ASM_OP2(leaw, 0x8d, 0, OPC_MODRM | OPC_WLX, OPT_EA, OPT_REG))

ALT(DEF_ASM_OP2(les, 0xc4, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lds, 0xc5, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lss, 0x0fb2, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lfs, 0x0fb4, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lgs, 0x0fb5, 0, OPC_MODRM, OPT_EA, OPT_REG32))

     /* arith */
ALT(DEF_ASM_OP2(addb, 0x00, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG)) /* XXX: use D bit ? */
ALT(DEF_ASM_OP2(addb, 0x02, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
ALT(DEF_ASM_OP2(addb, 0x04, 0, OPC_ARITH | OPC_BWLX, OPT_IM, OPT_EAX))
ALT(DEF_ASM_OP2(addw, 0x83, 0, OPC_ARITH | OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(addb, 0x80, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_IM, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP2(testb, 0x84, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(testb, 0x84, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
ALT(DEF_ASM_OP2(testb, 0xa8, 0, OPC_BWLX, OPT_IM, OPT_EAX))
ALT(DEF_ASM_OP2(testb, 0xf6, 0, OPC_MODRM | OPC_BWLX, OPT_IM, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP1(incb, 0xfe, 0, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(decb, 0xfe, 1, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP1(notb, 0xf6, 2, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(negb, 0xf6, 3, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP1(mulb, 0xf6, 4, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(imulb, 0xf6, 5, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP2(imulw, 0x0faf, 0, OPC_MODRM | OPC_WLX, OPT_REG | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP3(imulw, 0x6b, 0, OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(imulw, 0x6b, 0, OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_REGW))
ALT(DEF_ASM_OP3(imulw, 0x69, 0, OPC_MODRM | OPC_WLX, OPT_IMW, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(imulw, 0x69, 0, OPC_MODRM | OPC_WLX, OPT_IMW, OPT_REGW))

ALT(DEF_ASM_OP1(divb, 0xf6, 6, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP2(divb, 0xf6, 6, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA, OPT_EAX))
ALT(DEF_ASM_OP1(idivb, 0xf6, 7, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP2(idivb, 0xf6, 7, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA, OPT_EAX))

     /* shifts */
ALT(DEF_ASM_OP2(rolb, 0xc0, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_IM8, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(rolb, 0xd2, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_CL, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP1(rolb, 0xd0, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP3(shldw, 0x0fa4, 0, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shldw, 0x0fa5, 0, OPC_MODRM | OPC_WLX, OPT_CL, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(shldw, 0x0fa5, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shrdw, 0x0fac, 0, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shrdw, 0x0fad, 0, OPC_MODRM | OPC_WLX, OPT_CL, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(shrdw, 0x0fad, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_EA | OPT_REGW))

ALT(DEF_ASM_OP1(call, 0xff, 2, OPC_MODRM, OPT_INDIR))
ALT(DEF_ASM_OP1(call, 0xe8, 0, 0, OPT_DISP))
ALT(DEF_ASM_OP1(jmp, 0xff, 4, OPC_MODRM, OPT_INDIR))
ALT(DEF_ASM_OP1(jmp, 0xeb, 0, 0, OPT_DISP8))

ALT(DEF_ASM_OP1(lcall, 0xff, 3, OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(ljmp, 0xff, 5, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(ljmpw, 0x66ff, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(ljmpl, 0xff, 5, OPC_MODRM, OPT_EA)

ALT(DEF_ASM_OP1(int, 0xcd, 0, 0, OPT_IM8))
ALT(DEF_ASM_OP1(seto, 0x0f90, 0, OPC_MODRM | OPC_TEST, OPT_REG8 | OPT_EA))
ALT(DEF_ASM_OP1(setob, 0x0f90, 0, OPC_MODRM | OPC_TEST, OPT_REG8 | OPT_EA))
    DEF_ASM_OP2(enter, 0xc8, 0, 0, OPT_IM16, OPT_IM8)
    DEF_ASM_OP0(leave, 0xc9)
    DEF_ASM_OP0(ret, 0xc3)
    DEF_ASM_OP0(retq, 0xc3)
ALT(DEF_ASM_OP1(retq, 0xc2, 0, 0, OPT_IM16))
ALT(DEF_ASM_OP1(ret, 0xc2, 0, 0, OPT_IM16))
    DEF_ASM_OP0(lret, 0xcb)
ALT(DEF_ASM_OP1(lret, 0xca, 0, 0, OPT_IM16))

ALT(DEF_ASM_OP1(jo, 0x70, 0, OPC_TEST, OPT_DISP8))
    DEF_ASM_OP1(loopne, 0xe0, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loopnz, 0xe0, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loope, 0xe1, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loopz, 0xe1, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loop, 0xe2, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(jecxz, 0x67e3, 0, 0, OPT_DISP8)

     /* float */
     /* specific fcomp handling */
ALT(DEF_ASM_OP0L(fcomp, 0xd8d9, 0, 0))

ALT(DEF_ASM_OP1(fadd, 0xd8c0, 0, OPC_FARITH | OPC_REG, OPT_ST))
ALT(DEF_ASM_OP2(fadd, 0xd8c0, 0, OPC_FARITH | OPC_REG, OPT_ST, OPT_ST0))
ALT(DEF_ASM_OP2(fadd, 0xdcc0, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP2(fmul, 0xdcc8, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP0L(fadd, 0xdec1, 0, OPC_FARITH))
ALT(DEF_ASM_OP1(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST))
ALT(DEF_ASM_OP2(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST, OPT_ST0))
ALT(DEF_ASM_OP2(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP0L(faddp, 0xdec1, 0, OPC_FARITH))
ALT(DEF_ASM_OP1(fadds, 0xd8, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(fiaddl, 0xda, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(faddl, 0xdc, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(fiadds, 0xde, 0, OPC_FARITH | OPC_MODRM, OPT_EA))

     DEF_ASM_OP0(fucompp, 0xdae9)
     DEF_ASM_OP0(ftst, 0xd9e4)
     DEF_ASM_OP0(fxam, 0xd9e5)
     DEF_ASM_OP0(fld1, 0xd9e8)
     DEF_ASM_OP0(fldl2t, 0xd9e9)
     DEF_ASM_OP0(fldl2e, 0xd9ea)
     DEF_ASM_OP0(fldpi, 0xd9eb)
     DEF_ASM_OP0(fldlg2, 0xd9ec)
     DEF_ASM_OP0(fldln2, 0xd9ed)
     DEF_ASM_OP0(fldz, 0xd9ee)

     DEF_ASM_OP0(f2xm1, 0xd9f0)
     DEF_ASM_OP0(fyl2x, 0xd9f1)
     DEF_ASM_OP0(fptan, 0xd9f2)
     DEF_ASM_OP0(fpatan, 0xd9f3)
     DEF_ASM_OP0(fxtract, 0xd9f4)
     DEF_ASM_OP0(fprem1, 0xd9f5)
     DEF_ASM_OP0(fdecstp, 0xd9f6)
     DEF_ASM_OP0(fincstp, 0xd9f7)
     DEF_ASM_OP0(fprem, 0xd9f8)
     DEF_ASM_OP0(fyl2xp1, 0xd9f9)
     DEF_ASM_OP0(fsqrt, 0xd9fa)
     DEF_ASM_OP0(fsincos, 0xd9fb)
     DEF_ASM_OP0(frndint, 0xd9fc)
     DEF_ASM_OP0(fscale, 0xd9fd)
     DEF_ASM_OP0(fsin, 0xd9fe)
     DEF_ASM_OP0(fcos, 0xd9ff)
     DEF_ASM_OP0(fchs, 0xd9e0)
     DEF_ASM_OP0(fabs, 0xd9e1)
     DEF_ASM_OP0(fninit, 0xdbe3)
     DEF_ASM_OP0(fnclex, 0xdbe2)
     DEF_ASM_OP0(fnop, 0xd9d0)
     DEF_ASM_OP0(fwait, 0x9b)

    /* fp load */
    DEF_ASM_OP1(fld, 0xd9c0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fldl, 0xd9c0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(flds, 0xd9, 0, OPC_MODRM, OPT_EA)
ALT(DEF_ASM_OP1(fldl, 0xdd, 0, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(fildl, 0xdb, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fildq, 0xdf, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fildll, 0xdf, 5, OPC_MODRM,OPT_EA)
    DEF_ASM_OP1(fldt, 0xdb, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fbld, 0xdf, 4, OPC_MODRM, OPT_EA)

    /* fp store */
    DEF_ASM_OP1(fst, 0xddd0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fstl, 0xddd0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fsts, 0xd9, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fstps, 0xd9, 3, OPC_MODRM, OPT_EA)
ALT(DEF_ASM_OP1(fstl, 0xdd, 2, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(fstpl, 0xdd, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fist, 0xdf, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistp, 0xdf, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistl, 0xdb, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistpl, 0xdb, 3, OPC_MODRM, OPT_EA)

    DEF_ASM_OP1(fstp, 0xddd8, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fistpq, 0xdf, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistpll, 0xdf, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fstpt, 0xdb, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fbstp, 0xdf, 6, OPC_MODRM, OPT_EA)

    /* exchange */
    DEF_ASM_OP0(fxch, 0xd9c9)
ALT(DEF_ASM_OP1(fxch, 0xd9c8, 0, OPC_REG, OPT_ST))

    /* misc FPU */
    DEF_ASM_OP1(fucom, 0xdde0, 0, OPC_REG, OPT_ST )
    DEF_ASM_OP1(fucomp, 0xdde8, 0, OPC_REG, OPT_ST )

    DEF_ASM_OP0L(finit, 0xdbe3, 0, OPC_FWAIT)
    DEF_ASM_OP1(fldcw, 0xd9, 5, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fnstcw, 0xd9, 7, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fstcw, 0xd9, 7, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP0(fnstsw, 0xdfe0)
ALT(DEF_ASM_OP1(fnstsw, 0xdfe0, 0, 0, OPT_EAX ))
ALT(DEF_ASM_OP1(fnstsw, 0xdd, 7, OPC_MODRM, OPT_EA ))
    DEF_ASM_OP1(fstsw, 0xdfe0, 0, OPC_FWAIT, OPT_EAX )
ALT(DEF_ASM_OP0L(fstsw, 0xdfe0, 0, OPC_FWAIT))
ALT(DEF_ASM_OP1(fstsw, 0xdd, 7, OPC_MODRM | OPC_FWAIT, OPT_EA ))
    DEF_ASM_OP0L(fclex, 0xdbe2, 0, OPC_FWAIT)
    DEF_ASM_OP1(fnstenv, 0xd9, 6, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fstenv, 0xd9, 6, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP1(fldenv, 0xd9, 4, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fnsave, 0xdd, 6, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fsave, 0xdd, 6, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP1(frstor, 0xdd, 4, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(ffree, 0xddc0, 4, OPC_REG, OPT_ST )
    DEF_ASM_OP1(ffreep, 0xdfc0, 4, OPC_REG, OPT_ST )
    DEF_ASM_OP1(fxsave, 0x0fae, 0, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fxrstor, 0x0fae, 1, OPC_MODRM, OPT_EA )
    /* The *q forms of fxrstor/fxsave use a REX prefix.
       If the operand would use extended registers we would have to modify
       it instead of generating a second one.  Currently that's no
       problem with TCC, we don't use extended registers.  */
    DEF_ASM_OP1(fxsaveq, 0x0fae, 0, OPC_MODRM | OPC_48, OPT_EA )
    DEF_ASM_OP1(fxrstorq, 0x0fae, 1, OPC_MODRM | OPC_48, OPT_EA )

    /* segments */
    DEF_ASM_OP2(arpl, 0x63, 0, OPC_MODRM, OPT_REG16, OPT_REG16 | OPT_EA)
ALT(DEF_ASM_OP2(larw, 0x0f02, 0, OPC_MODRM | OPC_WLX, OPT_REG | OPT_EA, OPT_REG))
    DEF_ASM_OP1(lgdt, 0x0f01, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lgdtq, 0x0f01, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lidt, 0x0f01, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lidtq, 0x0f01, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lldt, 0x0f00, 2, OPC_MODRM, OPT_EA | OPT_REG)
    DEF_ASM_OP1(lmsw, 0x0f01, 6, OPC_MODRM, OPT_EA | OPT_REG)
ALT(DEF_ASM_OP2(lslw, 0x0f03, 0, OPC_MODRM | OPC_WLX, OPT_EA | OPT_REG, OPT_REG))
    DEF_ASM_OP1(ltr, 0x0f00, 3, OPC_MODRM, OPT_EA | OPT_REG16)
    DEF_ASM_OP1(sgdt, 0x0f01, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sgdtq, 0x0f01, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sidt, 0x0f01, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sidtq, 0x0f01, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sldt, 0x0f00, 0, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(smsw, 0x0f01, 4, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(str, 0x0f00, 1, OPC_MODRM, OPT_REG32 | OPT_EA)
ALT(DEF_ASM_OP1(str, 0x660f00, 1, OPC_MODRM, OPT_REG16))
ALT(DEF_ASM_OP1(str, 0x0f00, 1, OPC_MODRM | OPC_48, OPT_REG64))
    DEF_ASM_OP1(verr, 0x0f00, 4, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(verw, 0x0f00, 5, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP0L(swapgs, 0x0f01, 7, OPC_MODRM)

    /* 486 */
    /* bswap can't be applied to 16bit regs */
    DEF_ASM_OP1(bswap, 0x0fc8, 0, OPC_REG, OPT_REG32 )
    DEF_ASM_OP1(bswapl, 0x0fc8, 0, OPC_REG, OPT_REG32 )
    DEF_ASM_OP1(bswapq, 0x0fc8, 0, OPC_REG | OPC_48, OPT_REG64 )

ALT(DEF_ASM_OP2(xaddb, 0x0fc0, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_REG | OPT_EA ))
ALT(DEF_ASM_OP2(cmpxchgb, 0x0fb0, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_REG | OPT_EA ))
    DEF_ASM_OP1(invlpg, 0x0f01, 7, OPC_MODRM, OPT_EA )

    /* pentium */
    DEF_ASM_OP1(cmpxchg8b, 0x0fc7, 1, OPC_MODRM, OPT_EA )

    /* AMD 64 */
    DEF_ASM_OP1(cmpxchg16b, 0x0fc7, 1, OPC_MODRM | OPC_48, OPT_EA )

    /* pentium pro */
ALT(DEF_ASM_OP2(cmovo, 0x0f40, 0, OPC_MODRM | OPC_TEST | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))

    DEF_ASM_OP2(fcmovb, 0xdac0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmove, 0xdac8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovbe, 0xdad0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovu, 0xdad8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnb, 0xdbc0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovne, 0xdbc8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnbe, 0xdbd0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnu, 0xdbd8, 0, OPC_REG, OPT_ST, OPT_ST0 )

    DEF_ASM_OP2(fucomi, 0xdbe8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcomi, 0xdbf0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fucomip, 0xdfe8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcomip, 0xdff0, 0, OPC_REG, OPT_ST, OPT_ST0 )

    /* mmx */
    DEF_ASM_OP0(emms, 0x0f77) /* must be last OP0 */
    DEF_ASM_OP2(movd, 0x0f6e, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_MMXSSE )
    /* movd shouldn't accept REG64, but AMD64 spec uses it for 32 and 64 bit
       moves, so let's be compatible. */
ALT(DEF_ASM_OP2(movd, 0x0f6e, 0, OPC_MODRM, OPT_EA | OPT_REG64, OPT_MMXSSE ))
ALT(DEF_ASM_OP2(movq, 0x0f6e, 0, OPC_MODRM | OPC_48, OPT_REG64, OPT_MMXSSE ))
ALT(DEF_ASM_OP2(movq, 0x0f6f, 0, OPC_MODRM, OPT_EA | OPT_MMX, OPT_MMX ))
ALT(DEF_ASM_OP2(movd, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG32 ))
ALT(DEF_ASM_OP2(movd, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG64 ))
ALT(DEF_ASM_OP2(movq, 0x0f7f, 0, OPC_MODRM, OPT_MMX, OPT_EA | OPT_MMX ))
ALT(DEF_ASM_OP2(movq, 0x660fd6, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_SSE ))
ALT(DEF_ASM_OP2(movq, 0xf30f7e, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE ))
ALT(DEF_ASM_OP2(movq, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG64 ))

    DEF_ASM_OP2(packssdw, 0x0f6b, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(packsswb, 0x0f63, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(packuswb, 0x0f67, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddb, 0x0ffc, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddw, 0x0ffd, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddd, 0x0ffe, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddsb, 0x0fec, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddsw, 0x0fed, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddusb, 0x0fdc, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddusw, 0x0fdd, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pand, 0x0fdb, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pandn, 0x0fdf, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqb, 0x0f74, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqw, 0x0f75, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqd, 0x0f76, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtb, 0x0f64, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtw, 0x0f65, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtd, 0x0f66, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmaddwd, 0x0ff5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmulhw, 0x0fe5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmullw, 0x0fd5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(por, 0x0feb, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psllw, 0x0ff1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psllw, 0x0f71, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(pslld, 0x0ff2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(pslld, 0x0f72, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psllq, 0x0ff3, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psllq, 0x0f73, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psraw, 0x0fe1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psraw, 0x0f71, 4, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrad, 0x0fe2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrad, 0x0f72, 4, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrlw, 0x0fd1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrlw, 0x0f71, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrld, 0x0fd2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrld, 0x0f72, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrlq, 0x0fd3, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrlq, 0x0f73, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psubb, 0x0ff8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubw, 0x0ff9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubd, 0x0ffa, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubsb, 0x0fe8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubsw, 0x0fe9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubusb, 0x0fd8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubusw, 0x0fd9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhbw, 0x0f68, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhwd, 0x0f69, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhdq, 0x0f6a, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpcklbw, 0x0f60, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpcklwd, 0x0f61, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckldq, 0x0f62, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pxor, 0x0fef, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )

    /* sse */
    DEF_ASM_OP2(movups, 0x0f10, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movups, 0x0f11, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(movaps, 0x0f28, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movaps, 0x0f29, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(movhps, 0x0f16, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movhps, 0x0f17, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(addps, 0x0f58, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(cvtpi2ps, 0x0f2a, 0, OPC_MODRM, OPT_EA | OPT_MMX, OPT_SSE )
    DEF_ASM_OP2(cvtps2pi, 0x0f2d, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_MMX )
    DEF_ASM_OP2(cvttps2pi, 0x0f2c, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_MMX )
    DEF_ASM_OP2(divps, 0x0f5e, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(maxps, 0x0f5f, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(minps, 0x0f5d, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(mulps, 0x0f59, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pavgb, 0x0fe0, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pavgw, 0x0fe3, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pmaxsw, 0x0fee, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmaxub, 0x0fde, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pminsw, 0x0fea, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pminub, 0x0fda, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(rcpss, 0x0f53, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(rsqrtps, 0x0f52, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(sqrtps, 0x0f51, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(subps, 0x0f5c, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )

    DEF_ASM_OP1(prefetchnta, 0x0f18, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht0, 0x0f18, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht1, 0x0f18, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht2, 0x0f18, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetchw, 0x0f0d, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP0L(lfence, 0x0fae, 5, OPC_MODRM)
    DEF_ASM_OP0L(mfence, 0x0fae, 6, OPC_MODRM)
    DEF_ASM_OP0L(sfence, 0x0fae, 7, OPC_MODRM)
    DEF_ASM_OP1(clflush, 0x0fae, 7, OPC_MODRM, OPT_EA)
#undef ALT
#undef DEF_ASM_OP0
#undef DEF_ASM_OP0L
#undef DEF_ASM_OP1
#undef DEF_ASM_OP2
#undef DEF_ASM_OP3

#define ALT(x)
#define DEF_ASM_OP0(name, opcode)
#define DEF_ASM_OP0L(name, opcode, group, instr_type) DEF_ASM(name)
#define DEF_ASM_OP1(name, opcode, group, instr_type, op0) DEF_ASM(name)
#define DEF_ASM_OP2(name, opcode, group, instr_type, op0, op1) DEF_ASM(name)
#define DEF_ASM_OP3(name, opcode, group, instr_type, op0, op1, op2) DEF_ASM(name)
     DEF_ASM_OP0(clc, 0xf8) /* must be first OP0 */
     DEF_ASM_OP0(cld, 0xfc)
     DEF_ASM_OP0(cli, 0xfa)
     DEF_ASM_OP0(clts, 0x0f06)
     DEF_ASM_OP0(cmc, 0xf5)
     DEF_ASM_OP0(lahf, 0x9f)
     DEF_ASM_OP0(sahf, 0x9e)
     DEF_ASM_OP0(pushfq, 0x9c)
     DEF_ASM_OP0(popfq, 0x9d)
     DEF_ASM_OP0(pushf, 0x9c)
     DEF_ASM_OP0(popf, 0x9d)
     DEF_ASM_OP0(stc, 0xf9)
     DEF_ASM_OP0(std, 0xfd)
     DEF_ASM_OP0(sti, 0xfb)
     DEF_ASM_OP0(aaa, 0x37)
     DEF_ASM_OP0(aas, 0x3f)
     DEF_ASM_OP0(daa, 0x27)
     DEF_ASM_OP0(das, 0x2f)
     DEF_ASM_OP0(aad, 0xd50a)
     DEF_ASM_OP0(aam, 0xd40a)
     DEF_ASM_OP0(cbw, 0x6698)
     DEF_ASM_OP0(cwd, 0x6699)
     DEF_ASM_OP0(cwde, 0x98)
     DEF_ASM_OP0(cdq, 0x99)
     DEF_ASM_OP0(cbtw, 0x6698)
     DEF_ASM_OP0(cwtl, 0x98)
     DEF_ASM_OP0(cwtd, 0x6699)
     DEF_ASM_OP0(cltd, 0x99)
     DEF_ASM_OP0(cqto, 0x4899)
     DEF_ASM_OP0(int3, 0xcc)
     DEF_ASM_OP0(into, 0xce)
     DEF_ASM_OP0(iret, 0xcf)
     DEF_ASM_OP0(rsm, 0x0faa)
     DEF_ASM_OP0(hlt, 0xf4)
     DEF_ASM_OP0(wait, 0x9b)
     DEF_ASM_OP0(nop, 0x90)
     DEF_ASM_OP0(pause, 0xf390)
     DEF_ASM_OP0(xlat, 0xd7)

     /* strings */
ALT(DEF_ASM_OP0L(cmpsb, 0xa6, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(scmpb, 0xa6, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(insb, 0x6c, 0, OPC_BWL))
ALT(DEF_ASM_OP0L(outsb, 0x6e, 0, OPC_BWL))

ALT(DEF_ASM_OP0L(lodsb, 0xac, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(slodb, 0xac, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(movsb, 0xa4, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(smovb, 0xa4, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(scasb, 0xae, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(sscab, 0xae, 0, OPC_BWLX))

ALT(DEF_ASM_OP0L(stosb, 0xaa, 0, OPC_BWLX))
ALT(DEF_ASM_OP0L(sstob, 0xaa, 0, OPC_BWLX))

     /* bits */

ALT(DEF_ASM_OP2(bsfw, 0x0fbc, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(bsrw, 0x0fbd, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))

ALT(DEF_ASM_OP2(btw, 0x0fa3, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btw, 0x0fba, 4, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btsw, 0x0fab, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btsw, 0x0fba, 5, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btrw, 0x0fb3, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btrw, 0x0fba, 6, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

ALT(DEF_ASM_OP2(btcw, 0x0fbb, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP2(btcw, 0x0fba, 7, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW | OPT_EA))

     /* prefixes */
     DEF_ASM_OP0(lock, 0xf0)
     DEF_ASM_OP0(rep, 0xf3)
     DEF_ASM_OP0(repe, 0xf3)
     DEF_ASM_OP0(repz, 0xf3)
     DEF_ASM_OP0(repne, 0xf2)
     DEF_ASM_OP0(repnz, 0xf2)

     DEF_ASM_OP0(invd, 0x0f08)
     DEF_ASM_OP0(wbinvd, 0x0f09)
     DEF_ASM_OP0(cpuid, 0x0fa2)
     DEF_ASM_OP0(wrmsr, 0x0f30)
     DEF_ASM_OP0(rdtsc, 0x0f31)
     DEF_ASM_OP0(rdmsr, 0x0f32)
     DEF_ASM_OP0(rdpmc, 0x0f33)

     DEF_ASM_OP0(syscall, 0x0f05)
     DEF_ASM_OP0(sysret, 0x0f07)
     DEF_ASM_OP0L(sysretq, 0x480f07, 0, 0)
     DEF_ASM_OP0(ud2, 0x0f0b)

     /* NOTE: we took the same order as gas opcode definition order */
/* Right now we can't express the fact that 0xa1/0xa3 can't use $eax and a 
   32 bit moffset as operands.
ALT(DEF_ASM_OP2(movb, 0xa0, 0, OPC_BWLX, OPT_ADDR, OPT_EAX))
ALT(DEF_ASM_OP2(movb, 0xa2, 0, OPC_BWLX, OPT_EAX, OPT_ADDR)) */
ALT(DEF_ASM_OP2(movb, 0x88, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(movb, 0x8a, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
/* The moves are special: the 0xb8 form supports IM64 (the only insn that
   does) with REG64.  It doesn't support IM32 with REG64, it would use
   the full movabs form (64bit immediate).  For IM32->REG64 we prefer
   the 0xc7 opcode.  So disallow all 64bit forms and code the rest by hand. */
ALT(DEF_ASM_OP2(movb, 0xb0, 0, OPC_REG | OPC_BWLX, OPT_IM, OPT_REG))
ALT(DEF_ASM_OP2(mov,  0xb8, 0, OPC_REG, OPT_IM64, OPT_REG64))
ALT(DEF_ASM_OP2(movq, 0xb8, 0, OPC_REG, OPT_IM64, OPT_REG64))
ALT(DEF_ASM_OP2(movb, 0xc6, 0, OPC_MODRM | OPC_BWLX, OPT_IM, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP2(movw, 0x8c, 0, OPC_MODRM | OPC_WLX, OPT_SEG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(movw, 0x8e, 0, OPC_MODRM | OPC_WLX, OPT_EA | OPT_REG, OPT_SEG))

ALT(DEF_ASM_OP2(movw, 0x0f20, 0, OPC_MODRM | OPC_WLX, OPT_CR, OPT_REG64))
ALT(DEF_ASM_OP2(movw, 0x0f21, 0, OPC_MODRM | OPC_WLX, OPT_DB, OPT_REG64))
ALT(DEF_ASM_OP2(movw, 0x0f22, 0, OPC_MODRM | OPC_WLX, OPT_REG64, OPT_CR))
ALT(DEF_ASM_OP2(movw, 0x0f23, 0, OPC_MODRM | OPC_WLX, OPT_REG64, OPT_DB))

ALT(DEF_ASM_OP2(movsbw, 0x660fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REG16))
ALT(DEF_ASM_OP2(movsbl, 0x0fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movsbq, 0x0fbe, 0, OPC_MODRM, OPT_REG8 | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(movswl, 0x0fbf, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movswq, 0x0fbf, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP2(movslq, 0x63, 0, OPC_MODRM, OPT_REG32 | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP2(movzbw, 0x0fb6, 0, OPC_MODRM | OPC_WLX, OPT_REG8 | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(movzwl, 0x0fb7, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(movzwq, 0x0fb7, 0, OPC_MODRM, OPT_REG16 | OPT_EA, OPT_REG))

ALT(DEF_ASM_OP1(pushq, 0x6a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(push, 0x6a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(pushw, 0x666a, 0, 0, OPT_IM8S))
ALT(DEF_ASM_OP1(pushw, 0x50, 0, OPC_REG | OPC_WLX, OPT_REG64))
ALT(DEF_ASM_OP1(pushw, 0x50, 0, OPC_REG | OPC_WLX, OPT_REG16))
ALT(DEF_ASM_OP1(pushw, 0xff, 6, OPC_MODRM | OPC_WLX, OPT_REG64 | OPT_EA))
ALT(DEF_ASM_OP1(pushw, 0x6668, 0, 0, OPT_IM16))
ALT(DEF_ASM_OP1(pushw, 0x68, 0, OPC_WLX, OPT_IM32))
ALT(DEF_ASM_OP1(pushw, 0x06, 0, OPC_WLX, OPT_SEG))

ALT(DEF_ASM_OP1(popw, 0x58, 0, OPC_REG | OPC_WLX, OPT_REG64))
ALT(DEF_ASM_OP1(popw, 0x58, 0, OPC_REG | OPC_WLX, OPT_REG16))
ALT(DEF_ASM_OP1(popw, 0x8f, 0, OPC_MODRM | OPC_WLX, OPT_REGW | OPT_EA))
ALT(DEF_ASM_OP1(popw, 0x07, 0, OPC_WLX, OPT_SEG))

ALT(DEF_ASM_OP2(xchgw, 0x90, 0, OPC_REG | OPC_WLX, OPT_REGW, OPT_EAX))
ALT(DEF_ASM_OP2(xchgw, 0x90, 0, OPC_REG | OPC_WLX, OPT_EAX, OPT_REGW))
ALT(DEF_ASM_OP2(xchgb, 0x86, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(xchgb, 0x86, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))

ALT(DEF_ASM_OP2(inb, 0xe4, 0, OPC_BWL, OPT_IM8, OPT_EAX))
ALT(DEF_ASM_OP1(inb, 0xe4, 0, OPC_BWL, OPT_IM8))
ALT(DEF_ASM_OP2(inb, 0xec, 0, OPC_BWL, OPT_DX, OPT_EAX))
ALT(DEF_ASM_OP1(inb, 0xec, 0, OPC_BWL, OPT_DX))

ALT(DEF_ASM_OP2(outb, 0xe6, 0, OPC_BWL, OPT_EAX, OPT_IM8))
ALT(DEF_ASM_OP1(outb, 0xe6, 0, OPC_BWL, OPT_IM8))
ALT(DEF_ASM_OP2(outb, 0xee, 0, OPC_BWL, OPT_EAX, OPT_DX))
ALT(DEF_ASM_OP1(outb, 0xee, 0, OPC_BWL, OPT_DX))

ALT(DEF_ASM_OP2(leaw, 0x8d, 0, OPC_MODRM | OPC_WLX, OPT_EA, OPT_REG))

ALT(DEF_ASM_OP2(les, 0xc4, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lds, 0xc5, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lss, 0x0fb2, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lfs, 0x0fb4, 0, OPC_MODRM, OPT_EA, OPT_REG32))
ALT(DEF_ASM_OP2(lgs, 0x0fb5, 0, OPC_MODRM, OPT_EA, OPT_REG32))

     /* arith */
ALT(DEF_ASM_OP2(addb, 0x00, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG)) /* XXX: use D bit ? */
ALT(DEF_ASM_OP2(addb, 0x02, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
ALT(DEF_ASM_OP2(addb, 0x04, 0, OPC_ARITH | OPC_BWLX, OPT_IM, OPT_EAX))
ALT(DEF_ASM_OP2(addw, 0x83, 0, OPC_ARITH | OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(addb, 0x80, 0, OPC_ARITH | OPC_MODRM | OPC_BWLX, OPT_IM, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP2(testb, 0x84, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(testb, 0x84, 0, OPC_MODRM | OPC_BWLX, OPT_EA | OPT_REG, OPT_REG))
ALT(DEF_ASM_OP2(testb, 0xa8, 0, OPC_BWLX, OPT_IM, OPT_EAX))
ALT(DEF_ASM_OP2(testb, 0xf6, 0, OPC_MODRM | OPC_BWLX, OPT_IM, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP1(incb, 0xfe, 0, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(decb, 0xfe, 1, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP1(notb, 0xf6, 2, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(negb, 0xf6, 3, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP1(mulb, 0xf6, 4, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP1(imulb, 0xf6, 5, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))

ALT(DEF_ASM_OP2(imulw, 0x0faf, 0, OPC_MODRM | OPC_WLX, OPT_REG | OPT_EA, OPT_REG))
ALT(DEF_ASM_OP3(imulw, 0x6b, 0, OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(imulw, 0x6b, 0, OPC_MODRM | OPC_WLX, OPT_IM8S, OPT_REGW))
ALT(DEF_ASM_OP3(imulw, 0x69, 0, OPC_MODRM | OPC_WLX, OPT_IMW, OPT_REGW | OPT_EA, OPT_REGW))
ALT(DEF_ASM_OP2(imulw, 0x69, 0, OPC_MODRM | OPC_WLX, OPT_IMW, OPT_REGW))

ALT(DEF_ASM_OP1(divb, 0xf6, 6, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP2(divb, 0xf6, 6, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA, OPT_EAX))
ALT(DEF_ASM_OP1(idivb, 0xf6, 7, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA))
ALT(DEF_ASM_OP2(idivb, 0xf6, 7, OPC_MODRM | OPC_BWLX, OPT_REG | OPT_EA, OPT_EAX))

     /* shifts */
ALT(DEF_ASM_OP2(rolb, 0xc0, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_IM8, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP2(rolb, 0xd2, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_CL, OPT_EA | OPT_REG))
ALT(DEF_ASM_OP1(rolb, 0xd0, 0, OPC_MODRM | OPC_BWLX | OPC_SHIFT, OPT_EA | OPT_REG))

ALT(DEF_ASM_OP3(shldw, 0x0fa4, 0, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shldw, 0x0fa5, 0, OPC_MODRM | OPC_WLX, OPT_CL, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(shldw, 0x0fa5, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shrdw, 0x0fac, 0, OPC_MODRM | OPC_WLX, OPT_IM8, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP3(shrdw, 0x0fad, 0, OPC_MODRM | OPC_WLX, OPT_CL, OPT_REGW, OPT_EA | OPT_REGW))
ALT(DEF_ASM_OP2(shrdw, 0x0fad, 0, OPC_MODRM | OPC_WLX, OPT_REGW, OPT_EA | OPT_REGW))

ALT(DEF_ASM_OP1(call, 0xff, 2, OPC_MODRM, OPT_INDIR))
ALT(DEF_ASM_OP1(call, 0xe8, 0, 0, OPT_DISP))
ALT(DEF_ASM_OP1(jmp, 0xff, 4, OPC_MODRM, OPT_INDIR))
ALT(DEF_ASM_OP1(jmp, 0xeb, 0, 0, OPT_DISP8))

ALT(DEF_ASM_OP1(lcall, 0xff, 3, OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(ljmp, 0xff, 5, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(ljmpw, 0x66ff, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(ljmpl, 0xff, 5, OPC_MODRM, OPT_EA)

ALT(DEF_ASM_OP1(int, 0xcd, 0, 0, OPT_IM8))
ALT(DEF_ASM_OP1(seto, 0x0f90, 0, OPC_MODRM | OPC_TEST, OPT_REG8 | OPT_EA))
ALT(DEF_ASM_OP1(setob, 0x0f90, 0, OPC_MODRM | OPC_TEST, OPT_REG8 | OPT_EA))
    DEF_ASM_OP2(enter, 0xc8, 0, 0, OPT_IM16, OPT_IM8)
    DEF_ASM_OP0(leave, 0xc9)
    DEF_ASM_OP0(ret, 0xc3)
    DEF_ASM_OP0(retq, 0xc3)
ALT(DEF_ASM_OP1(retq, 0xc2, 0, 0, OPT_IM16))
ALT(DEF_ASM_OP1(ret, 0xc2, 0, 0, OPT_IM16))
    DEF_ASM_OP0(lret, 0xcb)
ALT(DEF_ASM_OP1(lret, 0xca, 0, 0, OPT_IM16))

ALT(DEF_ASM_OP1(jo, 0x70, 0, OPC_TEST, OPT_DISP8))
    DEF_ASM_OP1(loopne, 0xe0, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loopnz, 0xe0, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loope, 0xe1, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loopz, 0xe1, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(loop, 0xe2, 0, 0, OPT_DISP8)
    DEF_ASM_OP1(jecxz, 0x67e3, 0, 0, OPT_DISP8)

     /* float */
     /* specific fcomp handling */
ALT(DEF_ASM_OP0L(fcomp, 0xd8d9, 0, 0))

ALT(DEF_ASM_OP1(fadd, 0xd8c0, 0, OPC_FARITH | OPC_REG, OPT_ST))
ALT(DEF_ASM_OP2(fadd, 0xd8c0, 0, OPC_FARITH | OPC_REG, OPT_ST, OPT_ST0))
ALT(DEF_ASM_OP2(fadd, 0xdcc0, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP2(fmul, 0xdcc8, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP0L(fadd, 0xdec1, 0, OPC_FARITH))
ALT(DEF_ASM_OP1(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST))
ALT(DEF_ASM_OP2(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST, OPT_ST0))
ALT(DEF_ASM_OP2(faddp, 0xdec0, 0, OPC_FARITH | OPC_REG, OPT_ST0, OPT_ST))
ALT(DEF_ASM_OP0L(faddp, 0xdec1, 0, OPC_FARITH))
ALT(DEF_ASM_OP1(fadds, 0xd8, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(fiaddl, 0xda, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(faddl, 0xdc, 0, OPC_FARITH | OPC_MODRM, OPT_EA))
ALT(DEF_ASM_OP1(fiadds, 0xde, 0, OPC_FARITH | OPC_MODRM, OPT_EA))

     DEF_ASM_OP0(fucompp, 0xdae9)
     DEF_ASM_OP0(ftst, 0xd9e4)
     DEF_ASM_OP0(fxam, 0xd9e5)
     DEF_ASM_OP0(fld1, 0xd9e8)
     DEF_ASM_OP0(fldl2t, 0xd9e9)
     DEF_ASM_OP0(fldl2e, 0xd9ea)
     DEF_ASM_OP0(fldpi, 0xd9eb)
     DEF_ASM_OP0(fldlg2, 0xd9ec)
     DEF_ASM_OP0(fldln2, 0xd9ed)
     DEF_ASM_OP0(fldz, 0xd9ee)

     DEF_ASM_OP0(f2xm1, 0xd9f0)
     DEF_ASM_OP0(fyl2x, 0xd9f1)
     DEF_ASM_OP0(fptan, 0xd9f2)
     DEF_ASM_OP0(fpatan, 0xd9f3)
     DEF_ASM_OP0(fxtract, 0xd9f4)
     DEF_ASM_OP0(fprem1, 0xd9f5)
     DEF_ASM_OP0(fdecstp, 0xd9f6)
     DEF_ASM_OP0(fincstp, 0xd9f7)
     DEF_ASM_OP0(fprem, 0xd9f8)
     DEF_ASM_OP0(fyl2xp1, 0xd9f9)
     DEF_ASM_OP0(fsqrt, 0xd9fa)
     DEF_ASM_OP0(fsincos, 0xd9fb)
     DEF_ASM_OP0(frndint, 0xd9fc)
     DEF_ASM_OP0(fscale, 0xd9fd)
     DEF_ASM_OP0(fsin, 0xd9fe)
     DEF_ASM_OP0(fcos, 0xd9ff)
     DEF_ASM_OP0(fchs, 0xd9e0)
     DEF_ASM_OP0(fabs, 0xd9e1)
     DEF_ASM_OP0(fninit, 0xdbe3)
     DEF_ASM_OP0(fnclex, 0xdbe2)
     DEF_ASM_OP0(fnop, 0xd9d0)
     DEF_ASM_OP0(fwait, 0x9b)

    /* fp load */
    DEF_ASM_OP1(fld, 0xd9c0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fldl, 0xd9c0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(flds, 0xd9, 0, OPC_MODRM, OPT_EA)
ALT(DEF_ASM_OP1(fldl, 0xdd, 0, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(fildl, 0xdb, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fildq, 0xdf, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fildll, 0xdf, 5, OPC_MODRM,OPT_EA)
    DEF_ASM_OP1(fldt, 0xdb, 5, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fbld, 0xdf, 4, OPC_MODRM, OPT_EA)

    /* fp store */
    DEF_ASM_OP1(fst, 0xddd0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fstl, 0xddd0, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fsts, 0xd9, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fstps, 0xd9, 3, OPC_MODRM, OPT_EA)
ALT(DEF_ASM_OP1(fstl, 0xdd, 2, OPC_MODRM, OPT_EA))
    DEF_ASM_OP1(fstpl, 0xdd, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fist, 0xdf, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistp, 0xdf, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistl, 0xdb, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistpl, 0xdb, 3, OPC_MODRM, OPT_EA)

    DEF_ASM_OP1(fstp, 0xddd8, 0, OPC_REG, OPT_ST)
    DEF_ASM_OP1(fistpq, 0xdf, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fistpll, 0xdf, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fstpt, 0xdb, 7, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(fbstp, 0xdf, 6, OPC_MODRM, OPT_EA)

    /* exchange */
    DEF_ASM_OP0(fxch, 0xd9c9)
ALT(DEF_ASM_OP1(fxch, 0xd9c8, 0, OPC_REG, OPT_ST))

    /* misc FPU */
    DEF_ASM_OP1(fucom, 0xdde0, 0, OPC_REG, OPT_ST )
    DEF_ASM_OP1(fucomp, 0xdde8, 0, OPC_REG, OPT_ST )

    DEF_ASM_OP0L(finit, 0xdbe3, 0, OPC_FWAIT)
    DEF_ASM_OP1(fldcw, 0xd9, 5, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fnstcw, 0xd9, 7, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fstcw, 0xd9, 7, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP0(fnstsw, 0xdfe0)
ALT(DEF_ASM_OP1(fnstsw, 0xdfe0, 0, 0, OPT_EAX ))
ALT(DEF_ASM_OP1(fnstsw, 0xdd, 7, OPC_MODRM, OPT_EA ))
    DEF_ASM_OP1(fstsw, 0xdfe0, 0, OPC_FWAIT, OPT_EAX )
ALT(DEF_ASM_OP0L(fstsw, 0xdfe0, 0, OPC_FWAIT))
ALT(DEF_ASM_OP1(fstsw, 0xdd, 7, OPC_MODRM | OPC_FWAIT, OPT_EA ))
    DEF_ASM_OP0L(fclex, 0xdbe2, 0, OPC_FWAIT)
    DEF_ASM_OP1(fnstenv, 0xd9, 6, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fstenv, 0xd9, 6, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP1(fldenv, 0xd9, 4, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fnsave, 0xdd, 6, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fsave, 0xdd, 6, OPC_MODRM | OPC_FWAIT, OPT_EA )
    DEF_ASM_OP1(frstor, 0xdd, 4, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(ffree, 0xddc0, 4, OPC_REG, OPT_ST )
    DEF_ASM_OP1(ffreep, 0xdfc0, 4, OPC_REG, OPT_ST )
    DEF_ASM_OP1(fxsave, 0x0fae, 0, OPC_MODRM, OPT_EA )
    DEF_ASM_OP1(fxrstor, 0x0fae, 1, OPC_MODRM, OPT_EA )
    /* The *q forms of fxrstor/fxsave use a REX prefix.
       If the operand would use extended registers we would have to modify
       it instead of generating a second one.  Currently that's no
       problem with TCC, we don't use extended registers.  */
    DEF_ASM_OP1(fxsaveq, 0x0fae, 0, OPC_MODRM | OPC_48, OPT_EA )
    DEF_ASM_OP1(fxrstorq, 0x0fae, 1, OPC_MODRM | OPC_48, OPT_EA )

    /* segments */
    DEF_ASM_OP2(arpl, 0x63, 0, OPC_MODRM, OPT_REG16, OPT_REG16 | OPT_EA)
ALT(DEF_ASM_OP2(larw, 0x0f02, 0, OPC_MODRM | OPC_WLX, OPT_REG | OPT_EA, OPT_REG))
    DEF_ASM_OP1(lgdt, 0x0f01, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lgdtq, 0x0f01, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lidt, 0x0f01, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lidtq, 0x0f01, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(lldt, 0x0f00, 2, OPC_MODRM, OPT_EA | OPT_REG)
    DEF_ASM_OP1(lmsw, 0x0f01, 6, OPC_MODRM, OPT_EA | OPT_REG)
ALT(DEF_ASM_OP2(lslw, 0x0f03, 0, OPC_MODRM | OPC_WLX, OPT_EA | OPT_REG, OPT_REG))
    DEF_ASM_OP1(ltr, 0x0f00, 3, OPC_MODRM, OPT_EA | OPT_REG16)
    DEF_ASM_OP1(sgdt, 0x0f01, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sgdtq, 0x0f01, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sidt, 0x0f01, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sidtq, 0x0f01, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(sldt, 0x0f00, 0, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(smsw, 0x0f01, 4, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(str, 0x0f00, 1, OPC_MODRM, OPT_REG32 | OPT_EA)
ALT(DEF_ASM_OP1(str, 0x660f00, 1, OPC_MODRM, OPT_REG16))
ALT(DEF_ASM_OP1(str, 0x0f00, 1, OPC_MODRM | OPC_48, OPT_REG64))
    DEF_ASM_OP1(verr, 0x0f00, 4, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP1(verw, 0x0f00, 5, OPC_MODRM, OPT_REG | OPT_EA)
    DEF_ASM_OP0L(swapgs, 0x0f01, 7, OPC_MODRM)

    /* 486 */
    /* bswap can't be applied to 16bit regs */
    DEF_ASM_OP1(bswap, 0x0fc8, 0, OPC_REG, OPT_REG32 )
    DEF_ASM_OP1(bswapl, 0x0fc8, 0, OPC_REG, OPT_REG32 )
    DEF_ASM_OP1(bswapq, 0x0fc8, 0, OPC_REG | OPC_48, OPT_REG64 )

ALT(DEF_ASM_OP2(xaddb, 0x0fc0, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_REG | OPT_EA ))
ALT(DEF_ASM_OP2(cmpxchgb, 0x0fb0, 0, OPC_MODRM | OPC_BWLX, OPT_REG, OPT_REG | OPT_EA ))
    DEF_ASM_OP1(invlpg, 0x0f01, 7, OPC_MODRM, OPT_EA )

    /* pentium */
    DEF_ASM_OP1(cmpxchg8b, 0x0fc7, 1, OPC_MODRM, OPT_EA )

    /* AMD 64 */
    DEF_ASM_OP1(cmpxchg16b, 0x0fc7, 1, OPC_MODRM | OPC_48, OPT_EA )

    /* pentium pro */
ALT(DEF_ASM_OP2(cmovo, 0x0f40, 0, OPC_MODRM | OPC_TEST | OPC_WLX, OPT_REGW | OPT_EA, OPT_REGW))

    DEF_ASM_OP2(fcmovb, 0xdac0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmove, 0xdac8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovbe, 0xdad0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovu, 0xdad8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnb, 0xdbc0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovne, 0xdbc8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnbe, 0xdbd0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcmovnu, 0xdbd8, 0, OPC_REG, OPT_ST, OPT_ST0 )

    DEF_ASM_OP2(fucomi, 0xdbe8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcomi, 0xdbf0, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fucomip, 0xdfe8, 0, OPC_REG, OPT_ST, OPT_ST0 )
    DEF_ASM_OP2(fcomip, 0xdff0, 0, OPC_REG, OPT_ST, OPT_ST0 )

    /* mmx */
    DEF_ASM_OP0(emms, 0x0f77) /* must be last OP0 */
    DEF_ASM_OP2(movd, 0x0f6e, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_MMXSSE )
    /* movd shouldn't accept REG64, but AMD64 spec uses it for 32 and 64 bit
       moves, so let's be compatible. */
ALT(DEF_ASM_OP2(movd, 0x0f6e, 0, OPC_MODRM, OPT_EA | OPT_REG64, OPT_MMXSSE ))
ALT(DEF_ASM_OP2(movq, 0x0f6e, 0, OPC_MODRM | OPC_48, OPT_REG64, OPT_MMXSSE ))
ALT(DEF_ASM_OP2(movq, 0x0f6f, 0, OPC_MODRM, OPT_EA | OPT_MMX, OPT_MMX ))
ALT(DEF_ASM_OP2(movd, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG32 ))
ALT(DEF_ASM_OP2(movd, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG64 ))
ALT(DEF_ASM_OP2(movq, 0x0f7f, 0, OPC_MODRM, OPT_MMX, OPT_EA | OPT_MMX ))
ALT(DEF_ASM_OP2(movq, 0x660fd6, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_SSE ))
ALT(DEF_ASM_OP2(movq, 0xf30f7e, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE ))
ALT(DEF_ASM_OP2(movq, 0x0f7e, 0, OPC_MODRM, OPT_MMXSSE, OPT_EA | OPT_REG64 ))

    DEF_ASM_OP2(packssdw, 0x0f6b, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(packsswb, 0x0f63, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(packuswb, 0x0f67, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddb, 0x0ffc, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddw, 0x0ffd, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddd, 0x0ffe, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddsb, 0x0fec, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddsw, 0x0fed, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddusb, 0x0fdc, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(paddusw, 0x0fdd, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pand, 0x0fdb, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pandn, 0x0fdf, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqb, 0x0f74, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqw, 0x0f75, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpeqd, 0x0f76, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtb, 0x0f64, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtw, 0x0f65, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pcmpgtd, 0x0f66, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmaddwd, 0x0ff5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmulhw, 0x0fe5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmullw, 0x0fd5, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(por, 0x0feb, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psllw, 0x0ff1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psllw, 0x0f71, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(pslld, 0x0ff2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(pslld, 0x0f72, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psllq, 0x0ff3, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psllq, 0x0f73, 6, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psraw, 0x0fe1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psraw, 0x0f71, 4, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrad, 0x0fe2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrad, 0x0f72, 4, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrlw, 0x0fd1, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrlw, 0x0f71, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrld, 0x0fd2, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrld, 0x0f72, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psrlq, 0x0fd3, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
ALT(DEF_ASM_OP2(psrlq, 0x0f73, 2, OPC_MODRM, OPT_IM8, OPT_MMXSSE ))
    DEF_ASM_OP2(psubb, 0x0ff8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubw, 0x0ff9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubd, 0x0ffa, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubsb, 0x0fe8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubsw, 0x0fe9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubusb, 0x0fd8, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(psubusw, 0x0fd9, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhbw, 0x0f68, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhwd, 0x0f69, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckhdq, 0x0f6a, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpcklbw, 0x0f60, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpcklwd, 0x0f61, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(punpckldq, 0x0f62, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pxor, 0x0fef, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )

    /* sse */
    DEF_ASM_OP2(movups, 0x0f10, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movups, 0x0f11, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(movaps, 0x0f28, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movaps, 0x0f29, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(movhps, 0x0f16, 0, OPC_MODRM, OPT_EA | OPT_REG32, OPT_SSE )
ALT(DEF_ASM_OP2(movhps, 0x0f17, 0, OPC_MODRM, OPT_SSE, OPT_EA | OPT_REG32 ))
    DEF_ASM_OP2(addps, 0x0f58, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(cvtpi2ps, 0x0f2a, 0, OPC_MODRM, OPT_EA | OPT_MMX, OPT_SSE )
    DEF_ASM_OP2(cvtps2pi, 0x0f2d, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_MMX )
    DEF_ASM_OP2(cvttps2pi, 0x0f2c, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_MMX )
    DEF_ASM_OP2(divps, 0x0f5e, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(maxps, 0x0f5f, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(minps, 0x0f5d, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(mulps, 0x0f59, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pavgb, 0x0fe0, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pavgw, 0x0fe3, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(pmaxsw, 0x0fee, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pmaxub, 0x0fde, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pminsw, 0x0fea, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(pminub, 0x0fda, 0, OPC_MODRM, OPT_EA | OPT_MMXSSE, OPT_MMXSSE )
    DEF_ASM_OP2(rcpss, 0x0f53, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(rsqrtps, 0x0f52, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(sqrtps, 0x0f51, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )
    DEF_ASM_OP2(subps, 0x0f5c, 0, OPC_MODRM, OPT_EA | OPT_SSE, OPT_SSE )

    DEF_ASM_OP1(prefetchnta, 0x0f18, 0, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht0, 0x0f18, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht1, 0x0f18, 2, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetcht2, 0x0f18, 3, OPC_MODRM, OPT_EA)
    DEF_ASM_OP1(prefetchw, 0x0f0d, 1, OPC_MODRM, OPT_EA)
    DEF_ASM_OP0L(lfence, 0x0fae, 5, OPC_MODRM)
    DEF_ASM_OP0L(mfence, 0x0fae, 6, OPC_MODRM)
    DEF_ASM_OP0L(sfence, 0x0fae, 7, OPC_MODRM)
    DEF_ASM_OP1(clflush, 0x0fae, 7, OPC_MODRM, OPT_EA)
#undef ALT
#undef DEF_ASM_OP0
#undef DEF_ASM_OP0L
#undef DEF_ASM_OP1
#undef DEF_ASM_OP2
#undef DEF_ASM_OP3


#endif // target i386 or x86 64
