---
title: "Remote Sensing of Deserts and Desertification
"
author: "Arnon Karnieli and Micha Silver"
date: "12 March, 2025"
output: html_document
---


## Pre-requisites


* Register on Copernicus DataSpace: (https://dataspace.copernicus.eu/)
* Prepare OpenEO client id) and secret);
* Save these) to a text file on your computer.
* Register on GitLab: (https://gitlab.com/users/sign_in)
* Send me your GitLab username ((silverm@post.bgu.ac.il)) to get authorized for the class repo;


## Getting started
	
* Install git client from: (https://git-scm.com/downloads)
* Install `R` and RStudio:  (https://posit.co/download/rstudio-desktop/)
* Clone class repo (https://gitlab.com/rs-course/rs-arid-regions) to your computer;
* Start R project (using RStudio) `rs-arid-regions`;
* Enter your name and email into `participants.md` document;
* Commit locally;
* After I authorize your GitLab user for the class repo, push your change.


## Class Project
	
#### Coding groups:

* **Setup**: R packages, directories, parameters, looping;
* **Water surfaces**: Prepare time series of water surface rasters (hint: NDWI);
* **Soil moisture**: Prepare time series of soil moisture rasters (hint: OPTRAM)
* **Plot maps**.

#### Each student:

* Prepare polygon GIS file of your Area of Interest
* Save into GIS sub-directory, and push to class repo;
* Commit and push to class repo.
* Prepare individual `parameters.csv` file: with name of AOI file, and dates;
* (Only local, *Not* shared on git repo)
* When all functions are written and tested, run the code on your AOI.

