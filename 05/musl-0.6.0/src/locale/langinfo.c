#include <locale.h>
#include <langinfo.h>

static const char c_time[] =
	"Sun\0" "Mon\0" "Tue\0" "Wed\0" "Thu\0" "Fri\0" "Sat\0"
	"Sunday\0" "Monday\0" "Tuesday\0" "Wednesday\0"
	"Thursday\0" "Friday\0" "Saturday\0"
	"Jan\0" "Feb\0" "Mar\0" "Apr\0" "May\0" "Jun\0"
	"Jul\0" "Aug\0" "Sep\0" "Oct\0" "Nov\0" "Dec\0"
	"January\0"   "February\0" "March\0"    "April\0"
	"May\0"       "June\0"     "July\0"     "August\0"
	"September\0" "October\0"  "November\0" "December\0"
	"AM\0" "PM\0"
	"%a %b %e %T %Y\0"
	"%m/%d/%y\0"
	"%H:%M:%S\0"
	"%I:%M:%S %p\0"
	"\0"
	"%m/%d/%y\0"
	"0123456789"
	"%a %b %e %T %Y\0"
	"%H:%M:%S";

static const char c_messages[] = "^[yY]\0" "^[nN]";
static const char c_numeric[] = ".\0" "";

const char *__langinfo(nl_item item)
{
	int cat = item >> 16;
	int idx = item & 65535;
	const char *str;

	if (item == CODESET) return "UTF-8";
	
	switch (cat) {
	case LC_NUMERIC:
		if (idx > 1) return NULL;
		str = c_numeric;
		break;
	case LC_TIME:
		if (idx > 0x31) return NULL;
		str = c_time;
		break;
	case LC_MONETARY:
		if (idx > 0) return NULL;
		str = "";
		break;
	case LC_MESSAGES:
		if (idx > 1) return NULL;
		str = c_messages;
		break;
	default:
		return NULL;
	}

	for (; idx; idx--, str++) for (; *str; str++);
	return str;
}
