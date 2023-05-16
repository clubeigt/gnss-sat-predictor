# GNSS Satellites Predictor

## _A way to know where they are_

Corentin Lubeigt -- corentin.lubeigt@tesa.prd.fr

GNSS Sat Predictor is a Matlab toolbox implementing a SGP4 orbit propagator to predict GNSS satellites position based on current TLE. It allows the user to select a time window either in the past or in the future and to generate comprehensive figures (elevation plots or skyplots) to visualize the position of the considered satellites at the moment of interest.

## Quick tutorial

- run _main.m_
- in Configuration panel, select a Time window, Receiver position and a Constellation
- compute the satellites positions hitting **Load** button
- in Plot generator, select the satellites to be plotted in the Constellation list
- hit either **Skyplot** or **Elevation plot** to generate the corresponding figure for the selected satellites

# Acknowledgements

The following contributors should be thanked for sharing their code:
- David Vallado for providing most of the functions in the SGP4 original package
- Meysam Mahooti for providing the [SGP4 original package](https://www.mathworks.com/matlabcentral/fileexchange/62013-sgp4)
- Moein Mehrtash for providing computeAzimuthElevation.m 
- Eric Calais for providing skyplot.m, a function from the [GPS geodesy](http://www.geologie.ens.fr/~ecalais/teaching/gps-geodesy/solutions-to-gps-geodesy/) classe
- Serge Fabre and Benoît Priot for their precious feedbacks