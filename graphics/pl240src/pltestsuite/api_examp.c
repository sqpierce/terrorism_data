/* This demonstrates the libploticus API.
 *
 * SEE ALSO ../src/api_test.c, which demonstrates multiple plot jobs.
 * 
 * To compile this example: 
 *    cc api_examp.c -lploticus -lpng -lz (etc..) -lm -o api_examp
 *
 * or, if standard libs not available, something like this:
 *    cc api_examp.c /home/scg/ploticus/src/libploticus.a /home/scg/lib/libpng.a /home/scg/lib/libz.a -lm -o api_examp
 */

#include <stdio.h>

main()
{
int stat;

stat = ploticus_init( "png", "test1.png" );
if( stat != 0 ) { fprintf( stderr, "error on init\n" ); exit( 1 ); }

stat = ploticus_arg( "-debug", "" );

stat = ploticus_begin();

ploticus_execline( "#proc getdata" );
ploticus_execline( "showresults: yes" );
ploticus_execline( "data:" );
ploticus_execline( "A 1 2" );
ploticus_execline( "B 3 4" );
ploticus_execline( "#endproc" );

ploticus_execline( "#proc areadef" );
ploticus_execline( "rectangle: 1 1 3 4" );
ploticus_execline( "xrange: 0 10" );
ploticus_execline( "yrange: 0 10" );
ploticus_execline( "xaxis.stubs inc" );
ploticus_execline( "yaxis.stubs inc" );

ploticus_end();

PL_do_x_button( "Quit" );

}

