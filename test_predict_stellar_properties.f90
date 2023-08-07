program Test
  use neural_network_inference_m
  implicit none
  !
  real(kind=8) :: age, mass, mdot, Lacc, Lstellar, radius, temperature
  !
  ! Load neural networks
  call init_predict_stellar_properties(datadir='networks')
  
  ! Test values
  age = 1e6
  mass = 0.5
  mdot = 1e-8
 
  ! Predict
  call predict_stellar_properties(age,mass,mdot,Lacc,Lstellar,radius,temperature)
 
  ! write out results
  write(*,*) 'Age: ', age
  write(*,*) 'Mass: ', mass
  write(*,*) 'Mdot: ', mdot
  write(*,*) 'Lacc: ', Lacc
  write(*,*) 'Lstellar: ', Lstellar
  write(*,*) 'Radius: ', radius
  write(*,*) 'Temperature: ', temperature
end
