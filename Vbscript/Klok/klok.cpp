#include	<dos.h>
#include <process.h>
#include	<stdio.h>
#include	<string.h>

// prototypes:
void		about();

struct	time t;
struct 	date d;

int main (int argc, char *argv[])
{
	if (argc < 2)
	{		
		about();
	}

	// Correct letter case
	strlwr(argv[1]);
	
	// Get date and time.
	getdate(&d);
	gettime(&t);

	// Date strings
	if (strcmp(argv[1],"/?") == 0)
	{
		about();
	}
	else if (strcmp(argv[1],"-?") == 0)
	{
		about();
	}
	
	else if (strcmp(argv[1],"datum") == 0)
	{
		printf("%4d-%02d-%02d ",	d.da_year, d.da_mon, d.da_day);
	}
	else if (strcmp(argv[1],"date") == 0)
	{
		printf("%4d-%02d-%02d ",	d.da_year, d.da_mon, d.da_day);
	}
	else if (strcmp(argv[1],"sdatum") == 0)
	{
		printf("%04d%02d%02d ",	d.da_year, d.da_mon, d.da_day);
	}
	else if (strcmp(argv[1],"sdate") == 0)
	{
		printf("%04d%02d%02d ",	d.da_year, d.da_mon, d.da_day);
	}
	else if (strcmp(argv[1],"rdatum") == 0)
	{
		printf("%02d%02d%04d ",	d.da_day, d.da_mon, d.da_year);
	}
	else if (strcmp(argv[1],"rdate") == 0)
	{
		printf("%02d%02d%04d ",	d.da_day, d.da_mon, d.da_year);
	}
	else if (strcmp(argv[1],"udatum") == 0)
	{
		printf("%02d/%02d/%04d ",	d.da_day, d.da_mon, d.da_year);
	}
	else if (strcmp(argv[1],"udate") == 0)
	{
		printf("%02d/%02d/%04d ",	d.da_day, d.da_mon, d.da_year);
	}
	
	
	else if (strcmp(argv[1],"year") == 0)
	{
		printf("%4d", d.da_year);
	}
	else if (strcmp(argv[1],"syear") == 0)
	{
		printf("%04d", d.da_year);
	}
	else if (strcmp(argv[1],"month") == 0)
	{
		printf("%2d", d.da_mon);
	}
	else if (strcmp(argv[1],"smonth") == 0)
	{
		printf("%02d", d.da_mon);
	}
	else if (strcmp(argv[1],"day") == 0)
	{
		printf("%2d", d.da_day);
	}
	else if (strcmp(argv[1],"sday") == 0)
	{
		printf("%02d", d.da_day);
	}
	
	// Time strings
	else if (strcmp(argv[1],"tijd") == 0)
	{
		printf("%02d:%02d:%02d ",	t.ti_hour, t.ti_min, t.ti_sec);
	}	
	else if (strcmp(argv[1],"tyd") == 0)
	{
		printf("%02d:%02d:%02d ",	t.ti_hour, t.ti_min, t.ti_sec);
	}
	else if (strcmp(argv[1],"stijd") == 0)
	{
		printf("%02d%02d%02d ",	t.ti_hour, t.ti_min, t.ti_sec);
	}	
	else if (strcmp(argv[1],"styd") == 0)
	{
		printf("%02d%02d%02d ",	t.ti_hour, t.ti_min, t.ti_sec);
	}	
	
	else if (strcmp(argv[1],"hour") == 0)
	{
		printf("%2d",	t.ti_hour);
	}
	else if (strcmp(argv[1],"shour") == 0)
	{
		printf("%02d",	t.ti_hour);
	}
	else if (strcmp(argv[1],"min") == 0)
	{
		printf("%2d",	t.ti_min);
	}
	else if (strcmp(argv[1],"smin") == 0)
	{
		printf("%02d",	t.ti_min);
	}
	else if (strcmp(argv[1],"sec") == 0)
	{
		printf("%2d",	t.ti_sec);
	}
	else if (strcmp(argv[1],"ssec") == 0)
	{
		printf("%02d",	t.ti_sec);
	}
	
	// Date and time combinations
	else if (strcmp(argv[1],"nu") == 0)
	{
		printf("%d%02d%02d-%02d%02d%02d ", d.da_year, d.da_mon, d.da_day, t.ti_hour, t.ti_min, t.ti_sec);
	}
	else if (strcmp(argv[1],"now") == 0)
	{
		printf("%d%02d%02d-%02d%02d%02d ", d.da_year, d.da_mon, d.da_day, t.ti_hour, t.ti_min, t.ti_sec);
	}
	
	else
	{		
		fprintf(stderr,"Error: parameter value invalid\n");		
		about();
	}

	return 0;
}

void about()
{
	fprintf(stderr,"KLOK.EXE - versie 2008-07-14\n"
						"\nSyntax:\n"
						"    klok <option>\n"
						"\nValid options are:\n"
						"    datum|date               Current date in yyyy-mm-dd \n"
						"    sdatum|sdate             Current date in yyyymmdd \n"
						"    rdatum|rdate             Current date in dd-mm-yyyy \n"
						"    udatum|udate             Current date in dd/mm/yyyy \n"
						"\n"
						"    year|month|day           Current date in parts (not padded with zeros)\n"
						"    syear|smonth|sday        Current date in parts (padded with zeros)\n"
						"    tijd|tyd                 Current time with deviders\n" 
						"    stijd|styd               Current time without deviders\n"
						"    hour|min|sec             Current time in parts (not padded with zeros)\n"
						"    shour|smin|ssec          Current time in parts (padded with zeros)\n"
						"\n" 
						"    nu|now                   Current date and time in log format\n"
						);
	exit (3);
}