#ifndef _TIME_H
#define _TIME_H

#include <stdc_common.h>
#define CLK_TCK 1000000000 // doesnt matter; clock() will always fail.

typedef long clock_t;

clock_t clock(void) {
	// "If the processor time used is not available or its value cannot be represented, the function returns the value (clock_t)-1." C89 § 4.12.2.1
	return -1;
}

double difftime(time_t time1, time_t time0) {
	return (double)(time1 - time0);
}

time_t time(time_t *timer) {
	struct timespec ts = {0};
	if (clock_gettime(CLOCK_REALTIME, &ts) != 0) return -1;
	if (timer) *timer = ts.tv_sec;
	return ts.tv_sec;
}


// @NONSTANDARD(except in UTC+0): we don't support local time in timezones other than UTC+0.

struct tm {
         int tm_sec;   /*  seconds after the minute --- [0, 60] */
         int tm_min;   /*  minutes after the hour --- [0, 59] */
         int tm_hour;  /*  hours since midnight --- [0, 23] */
         int tm_mday;  /*  day of the month --- [1, 31] */
         int tm_mon;   /*  months since January --- [0, 11] */
         int tm_year;  /*  years since 1900 */
         int tm_wday;  /*  days since Sunday --- [0, 6] */
         int tm_yday;  /*  days since January 1 --- [0, 365] */
         int tm_isdst; /*  Daylight Saving Time flag */
};


void _gmtime_r(const time_t *timer, struct tm *tm) {
	time_t t = *timer;
	int year = 1970;
	int days = t / 86400;
	int leap_year;
	int month;
	
	tm->tm_isdst = 0;
	tm->tm_wday = (4 + days) % 7; // jan 1 1970 was a thursday
	while (1) {
		leap_year = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
		int ydays = leap_year ? 366 : 365;
		if (days < ydays) break;
		days -= ydays;
		++year;
	}
	tm->tm_year = year - 1900;
	tm->tm_yday = days;
	for (month = 0; month < 12; ++month) {
		int mdays;
		switch (month) {
		case 0: case 2: case 4: case 6: case 7: case 9: case 11:
			mdays = 31;
			break;
		case 3: case 5: case 8: case 10:
			mdays = 30;
			break;
		case 1:
			mdays = 28 + leap_year;
			break;
		}
		if (days < mdays) break;
		days -= mdays;
	}
	tm->tm_mday = days + 1;
	tm->tm_mon = month;
	t %= 86400;
	tm->tm_hour = t / 3600;
	t %= 3600;
	tm->tm_min = t / 60;
	tm->tm_sec = t % 60;
}

time_t mktime(struct tm *tm) {
	// @NONSTANDARD-ish.
	// not implementing this -- note that the implementation has to support tm_* values
	// outside of their proper ranges.
	return (time_t)-1;
	
}

struct tm *gmtime(const time_t *timer) {
	static struct tm result;
	_gmtime_r(timer, &result);
	return &result;
}

struct tm *localtime(const time_t *timer) {
	static struct tm result;
	_gmtime_r(timer, &result);
	return &result;
}

static const char _wday_name[7][4] = {
	"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"
};
static const char _weekday_name[7][16] = {
	"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
};
static const char _mon_name[12][4] = {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};
static const char _month_name[12][16] = {
	"January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December"
};

char *asctime(const struct tm *timeptr) {
	// lifted from the (draft of the) C standard
	static char result[32];
	sprintf(result, "%.3s %.3s%3d %.2d:%.2d:%.2d %d\n",
		_wday_name[timeptr->tm_wday],
		_mon_name[timeptr->tm_mon],
		timeptr->tm_mday, timeptr->tm_hour,
		timeptr->tm_min, timeptr->tm_sec,
		1900 + timeptr->tm_year);
	return result;
}

char *ctime(const time_t *timer) {
	return asctime(localtime(timer));
}

size_t strftime(char *s, size_t maxsize, const char *format, const struct tm *tm) {
	size_t n = 0, l;
	char *name;
	
	while (*format) {
		if (*format == '%') {
			++format;
			int c = *format++;
			switch (c) {
			case 'a':
				if (n+4 >= maxsize) return 0;
				strcpy(s, _wday_name[tm->tm_wday]);
				s += 3;
				n += 3;
				break;
			case 'A':
				name = _weekday_name[tm->tm_wday];
				l = strlen(name);
				if (n+l+1 >= maxsize) return 0;
				strcpy(s, name);
				s += l;
				n += l;
				break;
			case 'b':
				if (n+4 >= maxsize) return 0;
				strcpy(s, _mon_name[tm->tm_mon]);
				s += 3;
				n += 3;
				break;
			case 'B':
				name = _month_name[tm->tm_mon];
				l = strlen(name);
				if (n+l+1 >= maxsize) return 0;
				strcpy(s, name);
				s += l;
				n += l;
				break;
			case 'c':
				if (n+32 >= maxsize) return 0;
				sprintf(s, "%s %02d %s %d %02d:%02d:%02d %s UTC",
					_wday_name[tm->tm_wday], tm->tm_mday, _mon_name[tm->tm_mon],
					1900+tm->tm_year, (tm->tm_hour + 11) % 12 + 1, tm->tm_min, tm->tm_sec,
					tm->tm_hour >= 12 ? "PM" : "AM");
				s += 31;
				n += 31;
				break;
			case 'd':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_mday);
				s += 2;
				n += 2;
				break;
			case 'H':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_hour);
				s += 2;
				n += 2;
				break;
			case 'I':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", (tm->tm_hour + 11) % 12 + 1);
				s += 2;
				n += 2;
				break;
			case 'j':
				if (n+4 >= maxsize) return 0;
				sprintf(s, "%03d", tm->tm_yday + 1);
				s += 3;
				n += 3;
				break;
			case 'm':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_mon + 1);
				s += 2;
				n += 2;
				break;
			case 'M':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_min);
				s += 2;
				n += 2;
				break;
			case 'p':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%s", tm->tm_hour >= 12 ? "PM" : "AM");
				s += 2;
				n += 2;
				break;
			case 'S':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_sec);
				s += 2;
				n += 2;
				break;
			case 'w':
				if (n+2 >= maxsize) return 0;
				sprintf(s, "%d", tm->tm_wday);
				s += 1;
				n += 1;
				break;
			case 'x':
				if (n+16 >= maxsize) return 0;
				sprintf(s, "%s %02d %s %d",
					_wday_name[tm->tm_wday], tm->tm_mday, _mon_name[tm->tm_mon],
					1900+tm->tm_year);
				s += 15;
				n += 15;
				break;
			case 'X':
				if (n+16 >= maxsize) return 0;
				sprintf(s, "%02d:%02d:%02d %s UTC",
					(tm->tm_hour + 11) % 12 + 1, tm->tm_min, tm->tm_sec,
					tm->tm_hour >= 12 ? "PM" : "AM");
				s += 15;
				n += 15;
				break;
			case 'y':
				if (n+3 >= maxsize) return 0;
				sprintf(s, "%02d", tm->tm_year % 100);
				s += 2;
				n += 2;
				break;
			case 'Y':
				if (n+5 >= maxsize) return 0;
				sprintf(s, "%d", tm->tm_year + 1900);
				s += 4;
				n += 4;
				break;
			case 'Z':
				if (n+4 >= maxsize) return 0;
				strcpy(s, "UTC");
				s += 3;
				n += 3;
				break;
			case '%':
				if (n >= maxsize) return 0;
				*s++ = '%';
				n += 1;
				break;
			case 'U': // WEEK NUMBER OF THE YEAR? WHO GIVES A SHIT?
			case 'W': // WEEK NUMBER OF THE YEAR MONDAY-BASED EDITION. IF YOU DIDNT ALREADY GET ENOUGH WEEK NUMBERS. FUCK YOU
			default:
				fprintf(stderr, "Bad strftime format.\n");
				abort();
			
			}
		} else {
			if (n >= maxsize) return 0;
			*s++ = *format++;
			n += 1;
		}
	}
	if (n >= maxsize) return 0;
	*s = 0;
	#undef _Push_str
	return n;
}

#endif // _TIME_H
