/* ploticus data display engine.  Software, documentation, and examples.  
 * Copyright 1998-2008 Stephen C. Grubb  (scg@jax.org).
 * Covered by GPL; see the file ./Copyright for details. */
#ifndef PLHEAD

#define PLHEAD 1

#include <stdlib.h>
#include "plg.h"


#define PLVERSION "2.40-Jan'08" 	/* see also the Copyright page, and page headers and footers */

/* =========== working limits.. ============ */
#define CPULIMIT 30		/* default max amount of cpu (seconds) - setrlimit() - may be overridden */

#define MAXD 200000  		/* default max total # of data fields - may be overridden using -maxfields */
#define MAXDROWS 10000		/* default max # data rows - may be overridden using -maxrows */
#define MAXDAT 100000 		/* default max # of members in PLV vector - may be overridden */

#define MAXPROCLINES 5000	/* max # of proc lines in current proc plus all #saved 
					procs - may be overridden using -maxproclines */

#define MAXBIGBUF  10000 	/* size of PL_bigbuf (chars) (was 100K .. scg 11/27/07) */
#define MAXNCATS 250		/* default max # of categories - may be overriden using proc categories listsize */

#define MAXOBJ 40		/* max # of currently "active" procs.. includes all #saved procs and #proc getdata with inline data */
#define MAXDS 5			/* max # of stacked datasets in memory - maintain code instances when raising */
#define MAXCLONES 5		/* max # of #clone that may be used in one proc */

#define MAXPATH 256		/* pathname max */
#define MAXURL 256		/* url max */

#define MAXTT 1500		/* max size of a tooltip text chunk */

#define NORMAL 0

#define NAMEMAXLEN  50		/* also in tdhkit.h */

/* ============ other defines ============= */
#define dat2d(i,j)	(PLV[((i)*2)+(j)])    /* access PLV vector as an Nx2 array */
#define dat3d(i,j)      (PLV[((i)*3)+(j)])    /* access PLV vector as an NX3 array */

#define Nfields		PLD.nfields[ PLD.curds ]
#define Nrecords	PLD.nrecords[ PLD.curds ]

#ifndef Eerr
  #define Eerr(a,b,c) TDH_err(a,b,c)
#endif


#define X 'x'
#define Y 'y'
#define PIVOTYEAR 70
#define PLHUGE 	999999999999999.0
#define NEGHUGE -999999999999999.0
#define YESANS "y"   

/* legend entry types */
#define LEGEND_COLOR 1
#define LEGEND_LINE 2
#define LEGEND_SYMBOL 4
#define LEGEND_TEXT 8
#define LEGEND_LINEMARK 16

#ifndef URL_ENCODED
  #define URL_ENCODED 2
#endif

/* ============ pathname portability ============ */
#ifdef WIN32
  #define TMPDIR "c:\\temp"
  #define PATH_SLASH '\\'
#else
  #define TMPDIR "/tmp"		/* temp file directory */
  #define PATH_SLASH  '/'	/* slash as used in path name; unix uses '/'  */
#endif




/* ================ structures ====================== */

struct plstate {
	int debug;		/* indicates extra diagnostic output should be generated */
	char device;		/* c p e g or x */
	char *prefabsdir;	/* set from env var PLOTICUS_PREFABS */
	int npages;		/* page count */
	char outfile[MAXPATH];	/* output file as specified by user */
	char mapfile[MAXPATH];	/* clickmap file name */
	char cmdlineparms[300];	/* command line parms that need to override proc page settings */
	int eready;		/* indicates that Einit has been called */
	int usingcm;		/* indicates that units are centimeters */
	int skipout;		/* indicates fatal error and remainder of current script should be skipped */
	int landscape;		/* allows -landscape to be set on command line before Einit() */
	int bkcolorgiven;	/* needed so that we know whether or not to Eclr in certain places */
	int winsizegiven;	/* accomodate specification of window size on command line */
	double winw, winh;	/* accomodate specification of window size on command line */
	int winx, winy;		/* accomodate specification of window location on command line */
	int clickmap;		/* indicates whether we are doing a clickmap or not */
	char viewer[80];	/* viewer program as specified by user, eg ghostscript */
	int bignumspacer;	/* character to use in making large numbers readable (usually comma) */
	int bignumthres;	
	char tmpname[MAXPATH];	/* base name for generating temp file names */
	FILE *diagfp;		/* diagnostic output stream */
	FILE *errfp;		/* error message stream */
	char *cgiargs;		/* CGI args */
	int echolines;		/* echo evaluated script lines to 1 = stdout  2 = stderr */
	int noshell;		/* 1 if shell command deployment is prohibited */
	};

struct proclines {
	char **procline; 	/* array of pointers to lines of proc code */
	int maxproclines;	/* total malloc'ed size of procline array */
	int nlines;		/* next available cell when filling procline array */
	int curline;		/* next available cell when getting from procline array */

	int nobj;		/* current number of objects being stored */
	char objname[ MAXOBJ ][ 30 ];	/* list of object names for clone/saveas */
	int objstart[ MAXOBJ ];	/* which cell in procline array the object starts in */
	int objlen[ MAXOBJ ];	/* number of lines in procline array the object occupies */
	};

struct pldata {
	char **datarow; 	/* array of pointers to malloc'ed data row buffers */
	int currow;		/* current number of members in datarow array */
	int maxrows;		/* total malloc'ed size of datarow array */
				/* note: in-script data is stored in persistent proclines, not data rows */

	char **df;		/* array of field pointers */
	int curdf;		/* next available field pointer in df array */
	int maxdf;		/* total malloc'ed size of df array; */
				/* note: field pointers point into datarows (or into proclines for in-script data) */

	/* data sets are managed as a stack of up to MAXDS elements.  proc getdata always clears the stack and fills at ds=0.  */
	int curds;		/* identifies the current dataset (or stack size).  First is 0 */
	int dsfirstdf[MAXDS];	/* where a dataset begins in the df array */
	int dsfirstrow[MAXDS];	/* where a dataset begins in the datarow array.. if data set in procline array this is -1 */
	int nrecords[ MAXDS ];	/* number of records in a dataset */
	int nfields[ MAXDS ];	/* number of fields in a dataset */
	};
	


/* ================ global vars ================================= */

extern struct plstate PLS;
extern struct pldata PLD;
extern struct proclines PLL;
extern double *PLV;
extern int PLVsize, PLVhalfsize, PLVthirdsize;
extern char PL_bigbuf[];




/* ================ function redefines =========================== */
/* internally, functions usually don't use the PL_ prefix.. */
#define getmultiline(firstline,mode)			PL_getmultiline(firstline,mode)
#define getnextattr(flag,attr,valpos) 			PL_getnextattr(flag,attr,valpos)
#define tokncpy(val,lineval,maxlen)			PL_tokncpy(val,lineval,maxlen)
#define itokncpy(lineval)				PL_itokncpy(lineval)
#define ftokncpy(lineval)				PL_ftokncpy(lineval)
#define newattr(lineval,len)				PL_newattr(lineval,len)

#define da( r, c )					PL_da( r, c )
#define fda( r, a, ax )					PL_fda( r, a, ax )
#define num( s, result ) 				PL_num( s, result )
#define getcoords( p, v, x, y )				PL_getcoords( p, v, x, y )
#define getbox( p, v, x1, y1, x2, y2 )			PL_getbox( p, v, x1, y1, x2, y2 )
#define getrange( v, l, h, ax, dl, dh )			PL_getrange( v, l, h, ax, dl, dh )
#define getyn( s )					PL_getyn( s )
#define file_to_buf( f, m, r, b )			PL_file_to_buf( f, m, r, b )
#define setfloatvar( v, f, m )				PL_setfloatvar( v, f, m )
#define setintvar( v, n )				PL_setintvar( v, n )
#define setcharvar( v, s )				PL_setcharvar( v, s )
#define conv_msg( r, c, a )				PL_conv_msg( r, c, a )
#define suppress_convmsg( m )				PL_suppress_convmsg( m )
#define zero_convmsgcount()				PL_zero_convmsgcount()
#define report_convmsgcount()				PL_report_convmsgcount()
#define scalebeenset()					PL_scalebeenset()
#define catitem( s, d, avail )				PL_catitem( s, d, avail )
#define defaultinc( min, max, inc )			PL_defaultinc( min, max, inc )
#define rewritenums( num )				PL_rewritenums( num )
#define convertnl( s )					PL_convertnl( s )
#define measuretext( txt, nlines, maxlen )		PL_measuretext( txt, nlines, maxlen )

#define clickmap_init( nbytes, debug )			PL_clickmap_init( nbytes, debug )
#define clickmap_inprogress()				PL_clickmap_inprogress()
#define clickmap_debug()				PL_clickmap_debug()
#define clickmap_setdefaulturl( url )			PL_clickmap_setdefaulturl( url )
#define clickmap_seturlt( url )				PL_clickmap_seturlt( url )
#define clickmap_entry( t, u, p, x1, y1, x2, y2, tp, cm, tit )  PL_clickmap_entry( t, u, p, x1, y1, x2, y2, tp, cm, tit )
#define clickmap_out( tx, ty )				PL_clickmap_out( tx, ty )
#define clickmap_show( dev )				PL_clickmap_show( dev )

#define textdet( p, s, a, adjx, adjy, szh, sth, seph )	PL_textdet( p, s, a, adjx, adjy, szh, sth, seph )
#define linedet( p, s, d )				PL_linedet( p, s, d )
#define symdet( p, s, sc, r )				PL_symdet( p, s, sc, r )

#define devavail( dev )					PL_devavail( dev )
#define devnamemap( s, t, mode )			PL_devnamemap( s, t, mode )
#define makeoutfilename( s, o, d, p )			PL_makeoutfilename( s, o, d, p )

#define definefieldnames( list )			PL_definefieldnames( list )
#define fref( name )					PL_fref( name )
#define getfname( n, result )				PL_getfname( n, result )
#define fref_error()					PL_fref_error()
#define fref_showerr( mode )				PL_fref_showerr( mode )

#define do_select( selectex, row, result )		PL_do_select( selectex, row, result )
#define do_subst( out, in, row, mode )			PL_do_subst( out, in, row, mode )

#define	Esetunits( axis, s )				PL_setunits( axis, s )
#define Egetunits( axis, s )				PL_getunits( axis, s )
#define Egetunitsubtype( axis, result )			PL_getunitsubtype( axis, result )
#define Esetscale( axis, alo, ahi, scalelo, scalehi )	PL_setscale( axis, alo, ahi, scalelo, scalehi )
#define Econv( axis, s )				PL_conv( axis, s )
#define Econv_error()					PL_conv_error()
#define Euprint( result, axis, f, format )		PL_uprint( result, axis, f, format )
#define Eposex( val, axis, result )			PL_posex( val, axis, result )
#define Elenex( val, axis, result )			PL_lenex( val, axis, result )
#define Eevalbound( val, axis, result )			PL_evalbound( val, axis, result )
#define Esetdatesub( tok, desc )			PL_setdatesub( tok, desc )
#define Esetcatslide( axis, amount )			PL_setcatslide( axis, amount )
#define Es_inr( axis, val )				PL_s_inr( axis, val )
#define Ef_inr( axis, val )				PL_f_inr( axis, val )

/* ================ non-int functions ======================= */
extern char *PL_da();
extern double PL_fda(), PL_conv(), PL_u();
extern char *PL_getnextattr();
extern double PL_ftokncpy();
extern char *PL_newattr();
extern char *PL_getmultiline();
extern char *PL_get_legent();
extern char *PL_get_legent_rg();

/* ================ int functions =========================== */
extern int PL_tokncpy();
extern int PL_itokncpy();
extern int PL_num();
extern int PL_getcoords();
extern int PL_getbox();
extern int PL_getrange();
extern int PL_file_to_buf();
extern int PL_setfloatvar();
extern int PL_setintvar();
extern int PL_setcharvar();
extern int PL_conv_msg();
extern int PL_suppress_convmsg();
extern int PL_zero_convmsgcount();
extern int PL_report_convmsgcount();
extern int PL_scalebeenset();
extern int PL_catitem();
extern int PL_defaultinc();
extern int PL_rewritenums();
extern int PL_convertnl();
extern int PL_measuretext();
extern int PL_clickmap_init();
extern int PL_clickmap_inprogress();
extern int PL_clickmap_debug();
extern int PL_clickmap_setdefaulturl();
extern int PL_clickmap_seturlt();
extern int PL_clickmap_entry();
extern int PL_clickmap_out();
extern int PL_clickmap_show();
extern int PL_textdet();
extern int PL_linedet();
extern int PL_symdet();
extern int PL_devavail();
extern int PL_devnamemap();
extern int PL_makeoutfilename();
extern int PL_definefieldnames();
extern int PL_fref();
extern int PL_getfname();
extern int PL_fref_error();
extern int PL_fref_showerr();
extern int PL_do_select();
extern int PL_do_subst();
extern int PL_setunits();
extern int PL_getunits();
extern int PL_getunitsubtype();
extern int PL_setscale();
extern int PL_conv_error();
extern int PL_uprint();
extern int PL_posex();
extern int PL_lenex();
extern int PL_evalbound();
extern int PL_setdatesub();
extern int PL_setcatslide();
extern int PL_s_inr();
extern int PL_f_inr();
extern int PL_addcat();
extern int PL_begin();
extern int PL_catfree();
extern int PL_clickmap_demomode();
extern int PL_clickmap_free();
extern int PL_clickmap_getdemomode();
extern int PL_clickmap_inprogress();
extern int PL_clickmap_out();
extern int PL_clickmap_adjust();
extern int PL_custom_function();
extern int PL_devstring();
extern int PL_do_preliminaries();
extern int PL_do_x_button();
extern int PL_encode_fnames();
extern int PL_enddatarow();
extern int PL_exec_scriptfile();
extern int PL_execline();
extern int PL_execline_initstatic();
extern int PL_fieldnames_initstatic();
extern int PL_findcat();
extern int PL_free();
extern int PL_getcat();
extern int PL_holdmem();
extern int PL_init_mem();
extern int PL_lib_initstatic();
extern int PL_ncats();
extern int PL_nextcat();
extern int PL_parsedata();
extern int PL_process_arg();
extern int PL_setcatparms();
extern int PL_setcats();
extern int PL_sharedsettings();
extern int PL_smoothfit();
extern int PL_startdatarow();
extern int PL_units_initstatic();
extern int PL_value_subst();
extern int PL_add_legent();
extern int PL_resetstacklist();
extern int PL_getyn();
extern int PL_cleardatasets();
extern int PL_begindataset();
extern int PL_finishdataset();
extern int PL_popdataset();

extern int PLP_annotate();
extern int PLP_areadef();
extern int PLP_autorange();
extern int PLP_axis();
extern int PLP_bars();
extern int PLP_bars_initstatic();
extern int PLP_breakaxis();
extern int PLP_categories();
extern int PLP_catlines();
extern int PLP_curvefit();
extern int PLP_defineunits();
extern int PLP_drawcommands();
extern int PLP_getdata();
extern int PLP_getdata_initstatic();
extern int PLP_image();
extern int PLP_legend();
extern int PLP_legend_initstatic();
extern int PLP_legendentry();
extern int PLP_line();
extern int PLP_lineplot();
extern int PLP_page();
extern int PLP_pie();
extern int PLP_print();
extern int PLP_processdata();
extern int PLP_processdata_initstatic();
extern int PLP_boxplot();
extern int PLP_rangesweep();
extern int PLP_rect();
extern int PLP_scatterplot();
extern int PLP_settings();
extern int PLP_symbol();
extern int PLP_tabulate();
extern int PLP_tree();
extern int PLP_usedata();
extern int PLP_vector();
extern int PLP_venndisk();
extern int PLP_findnearest();

extern int GL_addmember();
extern int GL_changechars();
extern int GL_close_to();
extern int GL_commonmembers();
extern int GL_contains();
extern int GL_deletechars();
extern int GL_deletemember();
extern int GL_encode();
extern int GL_getcgiarg();
extern int GL_getchunk();
extern int GL_getseg();
extern int GL_goodnum();
extern int GL_initstatic();
extern int GL_make_unique_string();
extern int GL_member();
extern int GL_ranger();
extern int GL_slmember();
extern int GL_smember();
extern int GL_smemberi();
extern int GL_substitute();
extern int GL_substring();
extern int GL_sysdate();
extern int GL_systime();
extern int GL_varsub();
extern int GL_wildcmp();
extern int GL_wraptext();
extern double GL_numgroup();
extern int GL_urlencode();
extern int GL_urldecode();

extern int DT_build_dt();
extern int DT_checkdatelengths();
extern int DT_datefunctions();
extern int DT_datetime2days();
extern int DT_datetime_initstatic();
extern int DT_days2datetime();
extern int DT_formatdate();
extern int DT_formatdatetime();
extern int DT_formattime();
extern int DT_frame_mins();
extern int DT_fromjul();
extern int DT_frommin();
extern int DT_getdatefmt();
extern int DT_gethms();
extern int DT_getmdy();
extern int DT_getwin();
extern int DT_initstatic();
extern int DT_jdate();
extern int DT_makedate();
extern int DT_maketime();
extern int DT_setdatefmt();
extern int DT_setdateparms();
extern int DT_setdatetimefmt();
extern int DT_setdtsep();
extern int DT_setlazydates();
extern int DT_settimefmt();
extern int DT_time_initstatic();
extern int DT_timefunctions();
extern int DT_tomin();
extern int DT_weekday();
extern int DT_suppress_twin_warn();
extern int DT_reasonable();
extern int DT_getdtparts();
extern int DT_dateadd();

extern int TDH_condex();
extern int TDH_condex_initstatics();
extern int TDH_condex_listsep();
extern int TDH_dequote();
extern int TDH_err();
extern int TDH_err_initstatic();
extern int TDH_errfile();
extern int TDH_errmode();
extern int TDH_errprog();
extern int TDH_errprogsticky();
extern int TDH_function_call();
extern int TDH_function_listsep();
extern int TDH_functioncall_initstatic();
extern int TDH_geterrprog();
extern int TDH_getvalue();
extern int TDH_getvar();
extern int TDH_readconfig();
extern int TDH_readconfig_initstatic();
extern int TDH_reslimits();
extern int TDH_secondaryops();
extern int TDH_setvalue();
extern int TDH_setvar();
extern int TDH_setvar_initstatic();
extern int TDH_setvarcon();
extern int TDH_shell_initstatic();
extern int TDH_shellclose();
extern int TDH_shellcommand();
extern int TDH_shellresultrow();
extern int TDH_shfunctions();
extern int TDH_sinterp();
extern int TDH_sinterp_open();
extern int TDH_sinterp_openmem();
extern int TDH_sqlcommand();
extern int TDH_sqlnames();
extern int TDH_sqlrow();
extern int TDH_value_subst();
extern int TDH_valuesubst_initstatic();
extern int TDH_valuesubst_settings();
extern int TDH_setspecialincdir();
extern int TDH_prohibit_shell();

#endif /* PLHEAD */
