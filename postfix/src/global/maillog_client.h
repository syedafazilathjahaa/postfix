#ifndef _MAILLOG_CLIENT_H_INCLUDED_
#define _MAILLOG_CLIENT_H_INCLUDED_

/*++
/* NAME
/*	maillog_client 3h
/* SUMMARY
/*	log manager
/* SYNOPSIS
/*	#include <maillog_client.h>
/* DESCRIPTION
/* .nf

 /*
  * External interface.
  */
#define MAILLOG_CLIENT_FLAG_NONE		(0)
#define MAILLOG_CLIENT_FLAG_LOGWRITER_FALLBACK	(1<<0)

extern void maillog_client_init(const char *, int);

/* LICENSE
/* .ad
/* .fi
/*	The Secure Mailer license must be distributed with this software.
/* AUTHOR(S)
/*	Wietse Venema
/*	Google, Inc.
/*	111 8th Avenue
/*	New York, NY 10011, USA
/*--*/

#endif
