import matplotlib
matplotlib.use('agg')
from pylab import *

if len(sys.argv) <= 3:
	print 'usage barchart.py datafile interval_var categorical_var categorical_labels'
	sys.exit(1)

datafile = sys.argv[1]
outfile = datafile.split('.')[0]
int_var = sys.argv[2]
cat_var = sys.argv[3]
x_labels = sys.argv[4].split(',')

data = load(datafile, delimiter=',')

# must fix problem with single record instances being single-dimensional arrays
if data[0].size == 1: # this test wouldn't work if we weren't printing to fields to file (mean and std. dev.)
	bar_data = array([data[0]])
	xlocations = arange(1)
else:
	bar_data = data[:,0]
	xlocations = arange(len(data))

width = .7
axes([0.1,0.3,0.8,0.6])

bar(xlocations, bar_data, width=width, xerr=None, yerr=None)

ylabel('Mean '+int_var)
xticks(xlocations+(width/2), x_labels, rotation=-90 )
#title('Relationship Graph')
savefig(outfile+'.png', dpi=90, format='png')


