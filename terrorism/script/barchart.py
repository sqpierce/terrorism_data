import matplotlib
matplotlib.use('agg')
from pylab import *

datafile = sys.argv[1]
outfile = datafile.split('.')[0]
x_labels = sys.argv[2].split(',')
y_labels = sys.argv[3].split(',')

data = load(datafile, delimiter=',')

rows = len(y_labels)
cols = len(x_labels)
acols = arange(cols)
width = .7
axes([0.1,0.3,0.8,0.6])

bars=[]
yoff = array( [0.0] * cols )
for row in xrange(rows):
	bars.append(bar(acols, data[row], width, bottom=yoff, xerr=None, yerr=None, color=matplotlib.colors.cnames.keys()[row]))
	yoff = yoff + data[row]
	legend(map(lambda x: x[0], bars), y_labels, shadow=True)
	xticks( acols+(width/2), x_labels )

labels = getp(gca(), 'xticklabels')
setp(labels, fontsize=10, rotation=-90)
savefig(outfile+'.png', dpi=90, format='png')
