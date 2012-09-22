import matplotlib
matplotlib.use('agg')
from pylab import *

if len(sys.argv) <= 3:
	print 'usage scatter.py datafile xlabel ylabel'
	sys.exit(1)

datafile = sys.argv[1]
outfile = datafile.split('.')[0]

data = load(datafile, delimiter=',')
x = data[:,0]
y = data[:,1]

_xlabel = sys.argv[2]
_ylabel = sys.argv[3]

#scatter(x, y)
m,b = polyfit(x, y, 1)
plot( x, y, 'bo', x, m*x+b, 'g-', linewidth=2 )
#coeffs = polyfit(x, y, 2)
#besty = polyval( coeffs, x )
#plot( x, y, 'bo', x, besty, 'g-', linewidth=2 )

#title('Relationship Graph')
xlabel(_xlabel)
ylabel(_ylabel)
grid(True)
#savefig(outfile+'.png', dpi=72, format='png')
savefig(outfile+'.png', dpi=90, format='png')

