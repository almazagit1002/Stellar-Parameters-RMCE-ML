module neural_network_inference_m
  implicit none
  
  ! a single layer of a neural network
  type layer_t
    integer :: params,neurons
    real(kind=8), allocatable :: bias(:), weight(:,:)
  end type

  ! a neural network
  type neural_network_t
    integer :: layers
    type(layer_t), allocatable, dimension(:) :: l
  end type

  ! definitions for stellar structure
  logical :: networks_loaded = .false.
  integer, parameter :: n_networks = 7
  type(neural_network_t), dimension(n_networks) :: networks

contains

function load_neural_network(filename,verbose) result(net)
  character(len=255), intent(in) :: filename
  logical, optional, intent(in) :: verbose
  type(neural_network_t) :: net
  !
  integer :: unit, ilayer
  integer, allocatable, dimension(:,:) :: shape
  logical :: verbose_
  !
  if (present(verbose)) then
    verbose_ = verbose
  else
    verbose_ = .false.
  endif

  ! open the data file with the neural network parameters for reading
  open(newunit=unit, file=filename, status="old", form='unformatted')

  ! get the number of layers and allocate data types
  read(unit) net%layers
  allocate(net%l(net%layers),shape(2,net%layers))
  if (verbose_) &
    print '(a,i5)', 'Number of layers: ', net%layers

  ! read the shapes of each layer, store them in structure, and allocate memory
  read(unit) shape
  do ilayer=1,net%layers
    net%l(ilayer)%params  = shape(2,ilayer)
    net%l(ilayer)%neurons = shape(1,ilayer)
    allocate(net%l(ilayer)%bias  (net%l(ilayer)%neurons), &
             net%l(ilayer)%weight(net%l(ilayer)%neurons,net%l(ilayer)%params))
    if (verbose_) &
      print '(a,3i5)', 'Layer, Parameters, Neurons : ', &
                       ilayer, net%l(ilayer)%params, net%l(ilayer)%neurons
  enddo

  ! read the weights and then the bias for each layer
  do ilayer=1,net%layers
    read(unit) net%l(ilayer)%weight
  enddo
  do ilayer=1,net%layers
    read(unit) net%l(ilayer)%bias
  enddo

  close(unit)
end function

elemental real(kind=8) function relu(x)
  real(kind=8), intent(in) :: x
  relu = max(0.0_8, x)
end function relu

function inference_neural_network(input,net) result(output)
  type(neural_network_t), intent(in) :: net
  real(kind=8), dimension(net%l(1)%params), intent(in) :: input
  real(kind=8) :: output
  !
  integer :: ilayer, i, j, nmax,lp, ln
  real(kind=8), dimension(:), allocatable :: linput, loutput

  ! allocate buffers for passing the layers
  nmax = maxval(net%l(:)%neurons)
  allocate(linput(nmax),loutput(nmax))

  ! pass thorugh layers of neural network
  linput(1:net%l(1)%params) = input
  do ilayer = 1, net%layers
    ln = net%l(ilayer)%neurons
    loutput(1:ln) = 0.
    do j = 1, net%l(ilayer)%params
      loutput(1:ln) = loutput(1:ln) + net%l(ilayer)%weight(:,j) * linput(j)
    enddo
    loutput(1:ln) = loutput(1:ln) + net%l(ilayer)%bias
    if (ilayer < net%layers) then
      loutput(1:ln) = relu(loutput(1:ln))
      linput(1:ln) = loutput(1:ln)
    endif
  enddo
  output = loutput(1)
end function

subroutine init_predict_stellar_properties(datadir)
  character(len=*), intent(in), optional :: datadir
  !
  character(len=255) :: datadir_
  character(len=255), dimension(n_networks) :: filenames
  integer :: inet
  !
  if (present(datadir)) then
    datadir_ = trim(datadir)
  else
    datadir_ = 'UNF_records'
  endif

  ! Networks for accreting YSOs
  filenames(1) = 'Acc_Lum_Acc_records.unf'
  filenames(2) = 'Lum_Acc_records.unf'
  filenames(3) = 'Radius_Acc_records.unf'
  filenames(4) = 'T_eff_Acc_records.unf'

  ! Networks for non-accreting YSOs
  filenames(5) = 'Lum_N_acc_records.unf'
  filenames(6) = 'Radius_N_acc_records.unf'
  filenames(7) = 'T_eff_N_acc_records.unf'

  ! Add the datadir to the filenames and load the neural networks
  do inet=1,n_networks
    filenames(inet) = trim(datadir_) // '/' // trim(filenames(inet))
    networks(inet) = load_neural_network(filenames(inet))
  enddo

  networks_loaded = .true.

end subroutine

real(kind=8) function min_max_scaler(x,xmin,xmax) result(y)
  real(kind=8), intent(in) :: x, xmin, xmax
  y = (x - xmin) / (xmax - xmin)
end function min_max_scaler

subroutine predict_stellar_properties(age,mass,mdot,Lacc,Lstellar,radius,temperature)
  real(kind=8), intent(in)  :: age, mass, mdot
  real(kind=8), intent(out) :: radius,temperature,Lstellar,Lacc
  !
  logical      :: accretion
  real(kind=8) :: scaled_age, scaled_mass, scaled_mdot
  real(kind=8) :: input_acc(3), input_nacc(2)
  !
  if (.not. networks_loaded) then
    write(*,*) 'Fatal error in predict_stellar_properties: Neural networks not loaded yet.'
    write(*,*) 'Fatal error in predict_stellar_properties: Please call init_predict_stellar_properties(datadir) first.'
    stop
  endif
  !
  ! Start by scaling the input parameters and selecting neural networks
  !
  scaled_age = min_max_scaler(log10(age),-4.1981_8,8.0_8)
  scaled_mass = min_max_scaler(mass,0.01_8,10.567092_8)

  accretion = mdot > 1e-40
  if (accretion) then
    scaled_mdot = min_max_scaler(log10(mdot),-99.0_8,-3.7644_8)
    input_acc = (/ scaled_age, scaled_mass, scaled_mdot /)
  else
    input_nacc = (/ scaled_age, scaled_mass /)
  endif

  if (accretion) then
    Lacc = inference_neural_network(input_acc,networks(1))
    Lacc = Lacc * (3.1700734273350384 + 99.) - 99. ! inverse min_max scaler
    Lacc = 10.**Lacc
    Lstellar = inference_neural_network(input_acc,networks(2))
    radius = inference_neural_network(input_acc,networks(3))
    temperature = inference_neural_network(input_acc,networks(4))
  else
    Lacc = 0.
    Lstellar = inference_neural_network(input_nacc,networks(5))
    radius = inference_neural_network(input_nacc,networks(6))
    temperature = inference_neural_network(input_nacc,networks(7))
  endif

  Lstellar = 10.**Lstellar
  
end subroutine

end module neural_network_inference_m