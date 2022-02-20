
#include <stdarg.h>

#if defined(__NEED_size_t) && !defined(__DEFINED_size_t)
typedef unsigned long size_t;
#define __DEFINED_size_t
#endif

#if defined(__NEED_ssize_t) && !defined(__DEFINED_ssize_t)
typedef long ssize_t;
#define __DEFINED_ssize_t
#endif

#if defined(__NEED_ptrdiff_t) && !defined(__DEFINED_ptrdiff_t)
typedef long ptrdiff_t;
#define __DEFINED_ptrdiff_t
#endif

#if 0
#if defined(__NEED_va_list) && !defined(__DEFINED_va_list)
typedef __builtin_va_list va_list;
#define __DEFINED_va_list
#endif

#endif

#if defined(__NEED_wchar_t) && !defined(__DEFINED_wchar_t)
typedef int wchar_t;
#define __DEFINED_wchar_t
#endif

#if defined(__NEED_wint_t) && !defined(__DEFINED_wint_t)
typedef int wint_t;
#define __DEFINED_wint_t
#endif

#if defined(__NEED_wctrans_t) && !defined(__DEFINED_wctrans_t)
typedef int wctrans_t;
#define __DEFINED_wctrans_t
#endif

#if defined(__NEED_wctype_t) && !defined(__DEFINED_wctype_t)
typedef int wctype_t;
#define __DEFINED_wctype_t
#endif


#if defined(__NEED_int8_t) && !defined(__DEFINED_int8_t)
typedef char      int8_t;
#define __DEFINED_int8_t
#endif

#if defined(__NEED_int16_t) && !defined(__DEFINED_int16_t)
typedef short     int16_t;
#define __DEFINED_int16_t
#endif

#if defined(__NEED_int32_t) && !defined(__DEFINED_int32_t)
typedef int       int32_t;
#define __DEFINED_int32_t
#endif

#if defined(__NEED_int64_t) && !defined(__DEFINED_int64_t)
typedef long      int64_t;
#define __DEFINED_int64_t
#endif


#if defined(__NEED_uint8_t) && !defined(__DEFINED_uint8_t)
typedef unsigned char      uint8_t;
#define __DEFINED_uint8_t
#endif

#if defined(__NEED_uint16_t) && !defined(__DEFINED_uint16_t)
typedef unsigned short     uint16_t;
#define __DEFINED_uint16_t
#endif

#if defined(__NEED_uint32_t) && !defined(__DEFINED_uint32_t)
typedef unsigned int       uint32_t;
#define __DEFINED_uint32_t
#endif

#if defined(__NEED_uint64_t) && !defined(__DEFINED_uint64_t)
typedef unsigned long      uint64_t;
#define __DEFINED_uint64_t
#endif


#if defined(__NEED___uint8_t) && !defined(__DEFINED___uint8_t)
typedef unsigned char      __uint8_t;
#define __DEFINED___uint8_t
#endif

#if defined(__NEED___uint16_t) && !defined(__DEFINED___uint16_t)
typedef unsigned short     __uint16_t;
#define __DEFINED___uint16_t
#endif

#if defined(__NEED___uint32_t) && !defined(__DEFINED___uint32_t)
typedef unsigned int       __uint32_t;
#define __DEFINED___uint32_t
#endif

#if defined(__NEED___uint64_t) && !defined(__DEFINED___uint64_t)
typedef unsigned long      __uint64_t;
#define __DEFINED___uint64_t
#endif


#if defined(__NEED_int_least8_t) && !defined(__DEFINED_int_least8_t)
typedef int8_t  int_least8_t;
#define __DEFINED_int_least8_t
#endif

#if defined(__NEED_int_least16_t) && !defined(__DEFINED_int_least16_t)
typedef int16_t int_least16_t;
#define __DEFINED_int_least16_t
#endif

#if defined(__NEED_int_least32_t) && !defined(__DEFINED_int_least32_t)
typedef int32_t int_least32_t;
#define __DEFINED_int_least32_t
#endif

#if defined(__NEED_int_least64_t) && !defined(__DEFINED_int_least64_t)
typedef int64_t int_least64_t;
#define __DEFINED_int_least64_t
#endif


#if defined(__NEED_uint_least8_t) && !defined(__DEFINED_uint_least8_t)
typedef uint8_t  uint_least8_t;
#define __DEFINED_uint_least8_t
#endif

#if defined(__NEED_uint_least16_t) && !defined(__DEFINED_uint_least16_t)
typedef uint16_t uint_least16_t;
#define __DEFINED_uint_least16_t
#endif

#if defined(__NEED_uint_least32_t) && !defined(__DEFINED_uint_least32_t)
typedef uint32_t uint_least32_t;
#define __DEFINED_uint_least32_t
#endif

#if defined(__NEED_uint_least64_t) && !defined(__DEFINED_uint_least64_t)
typedef uint64_t uint_least64_t;
#define __DEFINED_uint_least64_t
#endif


#if defined(__NEED_int_fast8_t) && !defined(__DEFINED_int_fast8_t)
typedef int8_t    int_fast8_t;
#define __DEFINED_int_fast8_t
#endif

#if defined(__NEED_int_fast16_t) && !defined(__DEFINED_int_fast16_t)
typedef int       int_fast16_t;
#define __DEFINED_int_fast16_t
#endif

#if defined(__NEED_int_fast32_t) && !defined(__DEFINED_int_fast32_t)
typedef int       int_fast32_t;
#define __DEFINED_int_fast32_t
#endif

#if defined(__NEED_int_fast64_t) && !defined(__DEFINED_int_fast64_t)
typedef int64_t   int_fast64_t;
#define __DEFINED_int_fast64_t
#endif


#if defined(__NEED_uint_fast8_t) && !defined(__DEFINED_uint_fast8_t)
typedef unsigned char      uint_fast8_t;
#define __DEFINED_uint_fast8_t
#endif

#if defined(__NEED_uint_fast16_t) && !defined(__DEFINED_uint_fast16_t)
typedef unsigned int       uint_fast16_t;
#define __DEFINED_uint_fast16_t
#endif

#if defined(__NEED_uint_fast32_t) && !defined(__DEFINED_uint_fast32_t)
typedef unsigned int       uint_fast32_t;
#define __DEFINED_uint_fast32_t
#endif

#if defined(__NEED_uint_fast64_t) && !defined(__DEFINED_uint_fast64_t)
typedef uint64_t           uint_fast64_t;
#define __DEFINED_uint_fast64_t
#endif


#if defined(__NEED_intptr_t) && !defined(__DEFINED_intptr_t)
typedef long          intptr_t;
#define __DEFINED_intptr_t
#endif

#if defined(__NEED_uintptr_t) && !defined(__DEFINED_uintptr_t)
typedef unsigned long uintptr_t;
#define __DEFINED_uintptr_t
#endif


#if defined(__NEED_intmax_t) && !defined(__DEFINED_intmax_t)
typedef long long          intmax_t;
#define __DEFINED_intmax_t
#endif

#if defined(__NEED_uintmax_t) && !defined(__DEFINED_uintmax_t)
typedef unsigned long long uintmax_t;
#define __DEFINED_uintmax_t
#endif


#if defined(__NEED_time_t) && !defined(__DEFINED_time_t)
typedef long time_t;
#define __DEFINED_time_t
#endif

#if defined(__NEED_useconds_t) && !defined(__DEFINED_useconds_t)
typedef long useconds_t;
#define __DEFINED_useconds_t
#endif

#if defined(__NEED_suseconds_t) && !defined(__DEFINED_suseconds_t)
typedef long suseconds_t;
#define __DEFINED_suseconds_t
#endif

#if defined(__NEED_struct_timeval) && !defined(__DEFINED_struct_timeval)
struct timeval { time_t tv_sec; int tv_usec; };
#define __DEFINED_struct_timeval
#endif

#if defined(__NEED_struct_timespec) && !defined(__DEFINED_struct_timespec)
struct timespec { time_t tv_sec; unsigned long tv_nsec; };
#define __DEFINED_struct_timespec
#endif


#if defined(__NEED_pid_t) && !defined(__DEFINED_pid_t)
typedef int pid_t;
#define __DEFINED_pid_t
#endif

#if defined(__NEED_id_t) && !defined(__DEFINED_id_t)
typedef int id_t;
#define __DEFINED_id_t
#endif

#if defined(__NEED_uid_t) && !defined(__DEFINED_uid_t)
typedef unsigned int uid_t;
#define __DEFINED_uid_t
#endif

#if defined(__NEED_gid_t) && !defined(__DEFINED_gid_t)
typedef unsigned int gid_t;
#define __DEFINED_gid_t
#endif

#if defined(__NEED_key_t) && !defined(__DEFINED_key_t)
typedef int key_t;
#define __DEFINED_key_t
#endif


#if defined(__NEED_pthread_t) && !defined(__DEFINED_pthread_t)
typedef struct __pthread * pthread_t;
#define __DEFINED_pthread_t
#endif

#if defined(__NEED_pthread_once_t) && !defined(__DEFINED_pthread_once_t)
typedef int pthread_once_t;
#define __DEFINED_pthread_once_t
#endif

#if defined(__NEED_pthread_key_t) && !defined(__DEFINED_pthread_key_t)
typedef int pthread_key_t;
#define __DEFINED_pthread_key_t
#endif

#if defined(__NEED_pthread_spinlock_t) && !defined(__DEFINED_pthread_spinlock_t)
typedef int pthread_spinlock_t;
#define __DEFINED_pthread_spinlock_t
#endif


#if defined(__NEED_pthread_attr_t) && !defined(__DEFINED_pthread_attr_t)
typedef struct { union { int __i[14]; size_t __s[2]; } __u; } pthread_attr_t;
#define __DEFINED_pthread_attr_t
#endif

#if defined(__NEED_pthread_mutexattr_t) && !defined(__DEFINED_pthread_mutexattr_t)
typedef unsigned pthread_mutexattr_t;
#define __DEFINED_pthread_mutexattr_t
#endif

#if defined(__NEED_pthread_condattr_t) && !defined(__DEFINED_pthread_condattr_t)
typedef unsigned pthread_condattr_t;
#define __DEFINED_pthread_condattr_t
#endif

#if defined(__NEED_pthread_barrierattr_t) && !defined(__DEFINED_pthread_barrierattr_t)
typedef unsigned pthread_barrierattr_t;
#define __DEFINED_pthread_barrierattr_t
#endif

#if defined(__NEED_pthread_rwlockattr_t) && !defined(__DEFINED_pthread_rwlockattr_t)
typedef struct { unsigned __attr[2]; } pthread_rwlockattr_t;
#define __DEFINED_pthread_rwlockattr_t
#endif


#if defined(__NEED_pthread_mutex_t) && !defined(__DEFINED_pthread_mutex_t)
typedef struct { union { int __i[10]; void *__p[1]; } __u; } pthread_mutex_t;
#define __DEFINED_pthread_mutex_t
#endif

#if defined(__NEED_pthread_cond_t) && !defined(__DEFINED_pthread_cond_t)
typedef struct { union { int __i[12]; void *__p[1]; } __u; } pthread_cond_t;
#define __DEFINED_pthread_cond_t
#endif

#if defined(__NEED_pthread_rwlock_t) && !defined(__DEFINED_pthread_rwlock_t)
typedef struct { union { int __i[14]; void *__p[1]; } __u; } pthread_rwlock_t;
#define __DEFINED_pthread_rwlock_t
#endif

#if defined(__NEED_pthread_barrier_t) && !defined(__DEFINED_pthread_barrier_t)
typedef struct { union { int __i[8]; void *__p[1]; } __u; } pthread_barrier_t;
#define __DEFINED_pthread_barrier_t
#endif


#if defined(__NEED_off_t) && !defined(__DEFINED_off_t)
typedef long off_t;
#define __DEFINED_off_t
#endif


#if defined(__NEED_mode_t) && !defined(__DEFINED_mode_t)
typedef unsigned int mode_t;
#define __DEFINED_mode_t
#endif


#if defined(__NEED_nlink_t) && !defined(__DEFINED_nlink_t)
typedef unsigned long nlink_t;
#define __DEFINED_nlink_t
#endif

#if defined(__NEED_ino_t) && !defined(__DEFINED_ino_t)
typedef unsigned long long ino_t;
#define __DEFINED_ino_t
#endif

#if defined(__NEED_dev_t) && !defined(__DEFINED_dev_t)
typedef unsigned long dev_t;
#define __DEFINED_dev_t
#endif

#if defined(__NEED_blksize_t) && !defined(__DEFINED_blksize_t)
typedef long blksize_t;
#define __DEFINED_blksize_t
#endif

#if defined(__NEED_blkcnt_t) && !defined(__DEFINED_blkcnt_t)
typedef long long blkcnt_t;
#define __DEFINED_blkcnt_t
#endif

#if defined(__NEED_fsblkcnt_t) && !defined(__DEFINED_fsblkcnt_t)
typedef unsigned long long fsblkcnt_t;
#define __DEFINED_fsblkcnt_t
#endif

#if defined(__NEED_fsfilcnt_t) && !defined(__DEFINED_fsfilcnt_t)
typedef unsigned long long fsfilcnt_t;
#define __DEFINED_fsfilcnt_t
#endif


#if defined(__NEED_timer_t) && !defined(__DEFINED_timer_t)
typedef void * timer_t;
#define __DEFINED_timer_t
#endif

#if defined(__NEED_clockid_t) && !defined(__DEFINED_clockid_t)
typedef int clockid_t;
#define __DEFINED_clockid_t
#endif

#if defined(__NEED_clock_t) && !defined(__DEFINED_clock_t)
typedef long clock_t;
#define __DEFINED_clock_t
#endif


#if defined(__NEED_sigset_t) && !defined(__DEFINED_sigset_t)
typedef struct { unsigned long __bits[128/sizeof(long)]; } sigset_t;
#define __DEFINED_sigset_t
#endif

#if 1
#if defined(__NEED_siginfo_t) && !defined(__DEFINED_siginfo_t)
typedef struct __siginfo siginfo_t;
#define __DEFINED_siginfo_t
#endif

#else
#if defined(__NEED_siginfo_t) && !defined(__DEFINED_siginfo_t)
#define siginfo_t struct __siginfo
#define __DEFINED_siginfo_t
#endif
#endif

#if defined(__NEED_socklen_t) && !defined(__DEFINED_socklen_t)
typedef unsigned int socklen_t;
#define __DEFINED_socklen_t
#endif

#if defined(__NEED_sa_family_t) && !defined(__DEFINED_sa_family_t)
typedef unsigned short sa_family_t;
#define __DEFINED_sa_family_t
#endif

#if defined(__NEED_in_port_t) && !defined(__DEFINED_in_port_t)
typedef unsigned short in_port_t;
#define __DEFINED_in_port_t
#endif

#if defined(__NEED_in_addr_t) && !defined(__DEFINED_in_addr_t)
typedef unsigned int in_addr_t;
#define __DEFINED_in_addr_t
#endif

#if defined(__NEED_struct_in_addr) && !defined(__DEFINED_struct_in_addr)
struct in_addr { in_addr_t s_addr; };
#define __DEFINED_struct_in_addr
#endif


#if defined(__NEED_FILE) && !defined(__DEFINED_FILE)
typedef struct __FILE_s FILE;
#define __DEFINED_FILE
#endif


#if defined(__NEED_nl_item) && !defined(__DEFINED_nl_item)
typedef int nl_item;
#define __DEFINED_nl_item
#endif


#if defined(__NEED_locale_t) && !defined(__DEFINED_locale_t)
typedef struct __locale * locale_t;
#define __DEFINED_locale_t
#endif


#if defined(__NEED_struct_iovec) && !defined(__DEFINED_struct_iovec)
struct iovec { void *iov_base; size_t iov_len; };
#define __DEFINED_struct_iovec
#endif


