# ForestGEOCaseStudy

This repository houses the code for a case study demonstrating how to approximate ForestGEO survey data (size abundance distributions) from remote sensing of the forest canopy.

The code is broken into 4 parts:

1. How to download FIA data using the rFIA package. FIA data is used to create the randomforest model that allows for us to predict the alpha parameter for the power law distribution model, which is needed to estimate the full size-abundance distribution from the remote sensing data.
2. FIA provides a bunch of different tables that can be confusing to work with. The second code file combines the tables into a single csv.
3. How to calculate alpha for each of the FIA plots, using STAN code. The stan code is also included in this repository.
4. Finally, the actual code for creating the random forest model and then estimating the full abundance distribution for the ForestGEO plots.

We also include a Google Earth Engine link to a snapshot of how we calculated the raster for Stand Age across the United States using pre-existing data. You may need a Google Earth Engine account to access this.
