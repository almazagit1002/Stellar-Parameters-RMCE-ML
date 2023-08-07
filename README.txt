PREDICTABLE-YSOs
****************

This package contains C++, Fortran, and Python interfaces to
   "predict stellar parameters for accreting young stellar objects using neural networks"

Authors:  Alejandro Maza Villalpando alemazav1002@gmail.com (neural networks, C++, Python interfaces)
          Troels Haugboelle haugboel@nbi.ku.dk (Fortran interface)

License: BSD 3-clause, see LICENSE.txt

The background for the package is described in
  "Predicting stellar parameters for accreting YSOs with machine learning methods"
  Alejandro Maza Villalpando
  Msc Thesis, Niels Bohr Institute, University of Copenhagen
  August 2023

The newest version of the package together with the thesis can be found on GitHub:
  https://github.com/almazagit1002/Stellar-Parameters-RMCE-ML.git

For each of the languages the package contains:
  (1) internal routines specific to handling the neural networks
  (2) support for loading the weights for the neural networks need to do the computation
  (3) interface to calculate stellar properties
  (4) test and example of how to use the routines 

(2) only has to be called once, while (3) can be called everytime a prediction
for the stellar parameters are needed.

The test function (4) also constitutes an example of how to use the package.

To integrate the module in to a larger compiled code framework only the C++ or Fortran modules
('predict_stellar_properties.cxx' or 'predict_stellar_properties.f90') and the folder with the
data files ('networks') are needed. Please retain this README together with those files for
reference and to make it possible to track updates to the networks.

**********************
C++ interface
**********************
To compile and run the C++ test use your favourite compile. E.g. with g++:

g++ predict_stellar_properties.cxx test_predict_stellar_properties.cxx -o psp.x
./psp.x

**********************
Fortran interface
**********************
To compile and run the fortran test use your favourite compile. E.g. with gfortran:

gfortran predict_stellar_properties.f90 test_predict_stellar_properties.f90 -o psp.x
./psp.x

**********************
Python interface
**********************
To run the python test call it directly:

python predict_stellar_properties.py -l "1000000., 0.5, 1e-8"
