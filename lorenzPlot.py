import csv
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
mpl.use('Qt5Agg')

def loadTrainingDataset(recs):
    data = np.empty([60, len(recs)], dtype=np.int16)
    fnames = ['training_dat/' + f + '.dat' for f in recs]
    for n, fname in enumerate(fnames):
        data[::, n] = np.loadtxt(fname, dtype=np.int16)

    return data

def scatter_hist(x, y, ax, ax_histx, ax_histy):
    # no labels
    ax_histx.tick_params(axis="x", labelbottom=False)
    ax_histy.tick_params(axis="y", labelleft=False)

    # the scatter plot:
    ax.scatter(x, y)
    ax.grid(True, 'major')
    ax.minorticks_on()
    # ax.grid(True, 'minor')

    # now determine nice limits by hand:
    binwidth = 10
    xymax = max(np.max(np.abs(x)), np.max(np.abs(y)))
    lim = (int(xymax/binwidth) + 1) * binwidth

    bins = np.arange(-lim, lim + binwidth, binwidth)
    ax_histx.hist(x, bins=bins)
    ax_histy.hist(y, bins=bins, orientation='horizontal')

def plotLorenz(scatter_data, rec):
    left, width, bottom, height, spacing = 0.1, 0.65, 0.1, 0.65, 0.02
    rect_scatter = [left, bottom, width, height]
    rect_histx = [left, bottom + height + spacing, width, 0.2]
    rect_histy = [left + width + spacing, bottom, 0.2, height]

    # Set Figure and Axes
    f = plt.figure(figsize=(8, 8))
    ax = f.add_axes(rect_scatter)
    ax_hx = f.add_axes(rect_histx, sharex=ax)
    ax_hy = f.add_axes(rect_histy, sharey=ax)
    ax.set_xlim([-512, +512])
    ax.set_ylim([-512, +512])

    # Plot
    scatter_hist(scatter_data[::, 0, rec], scatter_data[::, 1, rec], ax, ax_hx, ax_hy)


if __name__ == "__main__":
    # Import CSV file
    with open('training_dat/annotations.csv') as csv_file:
        ann_data = np.asarray(list(csv.reader(csv_file, delimiter=',')))
    ann_data = np.delete(ann_data, obj=0, axis=0) # remove .csv header

    # Load Training Data
    data = loadTrainingDataset(ann_data[::, 0])
    fs = 250

    # Process Data for scatter plot
    nrr, recs = data.shape
    scatter_data = np.empty([nrr-2, 2, recs])
    for rec in range(recs):
        scatter_data[::, ::, rec] = (1000/fs)*np.array([[data[n, rec] - data[n-1, rec],
                                                         data[n-1, rec] - data[n-2, rec]]
                                                        for n in range(2, nrr)])

    # Scatter Plot with Histogram
    rec = 20075
    plotLorenz(scatter_data, rec)
    plotLorenz(scatter_data, rec-500)

    plt.show()
