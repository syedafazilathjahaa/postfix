/*++
/* NAME
/*	mail_conf_time 3
/* SUMMARY
/*	time interval configuration parameter support
/* SYNOPSIS
/*	#include <mail_conf.h>
/*
/*	int	get_mail_conf_time(name, defval, min, max);
/*	const char *name;
/*	const char *defval;
/*	int	min;
/*	int	max;
/*
/*	void	set_mail_conf_time(name, value)
/*	const char *name;
/*	const char *value;
/*
/*	void	get_mail_conf_time_table(table)
/*	CONFIG_TIME_TABLE *table;
/* AUXILIARY FUNCTIONS
/*	int	get_mail_conf_time2(name1, name2, defval, min, max);
/*	const char *name1;
/*	const char *name2;
/*	int	def_unit;
/*	int	min;
/*	int	max;
/* DESCRIPTION
/*	This module implements configuration parameter support
/*	for time interval values. The conversion routines understand
/*	one-letter suffixes to specify an explicit time unit: s
/*	(seconds), m (minutes), h (hours), d (days) or w (weeks).
/*	Internally, time is represented in seconds.
/*
/*	get_mail_conf_time() looks up the named entry in the global
/*	configuration dictionary. The default value is returned
/*	when no value was found. \fIdef_unit\fR supplies the default
/*	time unit for numbers numbers specified without explicit unit.
/*	\fImin\fR is zero or specifies a lower limit on the integer
/*	value or string length; \fImax\fR is zero or specifies an
/*	upper limit on the integer value or string length.
/*
/*	set_mail_conf_time() updates the named entry in the global
/*	configuration dictionary. This has no effect on values that
/*	have been looked up earlier via the get_mail_conf_XXX() routines.
/*
/*	get_mail_conf_time_table() and get_mail_conf_time_fn_table() initialize
/*	lists of variables, as directed by their table arguments. A table
/*	must be terminated by a null entry.
/* DIAGNOSTICS
/*	Fatal errors: malformed numerical value, unknown time unit.
/* BUGS
/*	Values and defaults are given in any unit; upper and lower
/*	bounds are given in seconds.
/* SEE ALSO
/*	config(3) general configuration
/*	mail_conf_str(3) string-valued configuration parameters
/* LICENSE
/* .ad
/* .fi
/*	The Secure Mailer license must be distributed with this software.
/* AUTHOR(S)
/*	Wietse Venema
/*	IBM T.J. Watson Research
/*	P.O. Box 704
/*	Yorktown Heights, NY 10598, USA
/*--*/

/* System library. */

#include <sys_defs.h>
#include <stdlib.h>
#include <stdio.h>			/* sscanf() */
#include <ctype.h>

/* Utility library. */

#include <msg.h>
#include <mymalloc.h>
#include <dict.h>
#include <stringops.h>

/* Global library. */

#include "mail_conf.h"

#define MINUTE	(60)
#define HOUR	(60 * MINUTE)
#define DAY	(24 * HOUR)
#define WEEK	(7 * DAY)

/* convert_mail_conf_time - look up and convert integer parameter value */

static int convert_mail_conf_time(const char *name, int *intval, int def_unit)
{
    const char *strval;
    char    unit;
    char    junk;

    if ((strval = mail_conf_lookup_eval(name)) == 0)
	return (0);

    switch (sscanf(strval, "%d%c%c", intval, &unit, &junk)) {
    case 1:
	unit = def_unit;
    case 2:
	switch (unit) {
	case 'w':
	    *intval *= WEEK;
	    return (1);
	case 'd':
	    *intval *= DAY;
	    return (1);
	case 'h':
	    *intval *= HOUR;
	    return (1);
	case 'm':
	    *intval *= MINUTE;
	    return (1);
	case 's':
	    return (1);
	}
    }
    msg_fatal("bad time parameter configuration: %s = %s", name, strval);
}

/* check_mail_conf_time - validate integer value */

static void check_mail_conf_time(const char *name, int intval, int min, int max)
{
    if (min && intval < min)
	msg_fatal("invalid %s: %d (min %d)", name, intval, min);
    if (max && intval > max)
	msg_fatal("invalid %s: %d (max %d)", name, intval, max);
}

/* get_def_time_unit - extract time unit from default value */

static int get_def_time_unit(const char *name, const char *defval)
{
    const char *cp;

    for (cp = defval; /* void */ ; cp++) {
	if (*cp == 0)
	    msg_panic("parameter %s: missing time unit in default value: %s",
		      name, defval);
	if (ISALPHA(*cp)) {
	    if (cp[1] != 0)
		msg_panic("parameter %s: bad time unit in default value: %s",
			  name, defval);
	    return (*cp);
	}
    }
}

/* get_mail_conf_time - evaluate integer-valued configuration variable */

int     get_mail_conf_time(const char *name, const char *defval, int min, int max)
{
    int     intval;
    int     def_unit;

    def_unit = get_def_time_unit(name, defval);
    if (convert_mail_conf_time(name, &intval, def_unit) == 0)
	set_mail_conf_time(name, defval);
    if (convert_mail_conf_time(name, &intval, def_unit) == 0)
	msg_panic("get_mail_conf_time: parameter not found: %s", name);
    check_mail_conf_time(name, intval, min, max);
    return (intval);
}

/* get_mail_conf_time2 - evaluate integer-valued configuration variable */

int     get_mail_conf_time2(const char *name1, const char *name2,
			            const char *defval, int min, int max)
{
    int     intval;
    char   *name;
    int     def_unit;

    name = concatenate(name1, name2, (char *) 0);
    def_unit = get_def_time_unit(name, defval);
    if (convert_mail_conf_time(name, &intval, def_unit) == 0)
	set_mail_conf_time(name, defval);
    if (convert_mail_conf_time(name, &intval, def_unit) == 0)
	msg_panic("get_mail_conf_time2: parameter not found: %s", name);
    check_mail_conf_time(name, intval, min, max);
    myfree(name);
    return (intval);
}

/* set_mail_conf_time - update integer-valued configuration dictionary entry */

void    set_mail_conf_time(const char *name, const char *value)
{
    mail_conf_update(name, value);
}

/* get_mail_conf_time_table - look up table of integers */

void    get_mail_conf_time_table(CONFIG_TIME_TABLE *table)
{
    while (table->name) {
	table->target[0] = get_mail_conf_time(table->name, table->defval,
					      table->min, table->max);
	table++;
    }
}

#ifdef TEST

 /*
  * Stand-alone driver program for regression testing.
  */
#include <vstream.h>

int     main(int unused_argc, char **unused_argv)
{
    static int seconds;
    static int minutes;
    static int hours;
    static int days;
    static int weeks;
    static CONFIG_TIME_TABLE time_table1[] = {
	"seconds", "10s", &seconds, 's', 0, 0,
	"minutes", "10m", &minutes, 'm', 0, 0,
	"hours", "10h", &hours, 'h', 0, 0,
	"days", "10d", &days, 'd', 0, 0,
	"weeks", "10w", &weeks, 'w', 0, 0,
	0,
    };
    static CONFIG_TIME_TABLE time_table2[] = {
	"seconds", "10", &seconds, 's', 0, 0,
	"minutes", "10", &minutes, 'm', 0, 0,
	"hours", "10", &hours, 'h', 0, 0,
	"days", "10", &days, 'd', 0, 0,
	"weeks", "10", &weeks, 'w', 0, 0,
	0,
    };

    get_mail_conf_time_table(time_table1);
    vstream_printf("seconds = %d\n", seconds);
    vstream_printf("minutes = %d\n", minutes);
    vstream_printf("hours = %d\n", hours);
    vstream_printf("days = %d\n", days);
    vstream_printf("weeks = %d\n", weeks);

    get_mail_conf_time_table(time_table2);
    vstream_printf("seconds = %d\n", seconds);
    vstream_printf("minutes = %d\n", minutes);
    vstream_printf("hours = %d\n", hours);
    vstream_printf("days = %d\n", days);
    vstream_printf("weeks = %d\n", weeks);
    vstream_fflush(VSTREAM_OUT);
}

#endif
