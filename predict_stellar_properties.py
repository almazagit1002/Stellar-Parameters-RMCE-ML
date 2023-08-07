import numpy as np
from scipy.io import FortranFile
from pickle import load
import argparse
import time



def neural_network_(pred_param,acc_type):
    """
    pred_param :arry of strings
    acc_type:string
    takes the prediction parameter ('Radius','Lum', 'T_eff','Acc_Lum'), read the neural network arquitecture from .unf files
    returns neural network arquitecture
    """
    f = FortranFile(f'networks/{pred_param}_{acc_type}_records.unf', 'r')
    layers = f.read_ints(np.int32)[0]
#     print(f'{pred_param} neural network')
#     print('Number of Layers:')
#     print(layers)
    Shapes = f.read_ints(np.int32).reshape(layers,2)
#     print('Layers shape')
#     print(Shapes)
    weights = []
    bias=[]
    for i in range(layers):
        weights.append(f.read_reals(float).reshape((Shapes[i][0], Shapes[i][1]), order="F"))
    for i in range(layers):
        bias.append(f.read_reals(float))
    f.close()
    
    return layers, weights, bias


def relu(x):
    """
    x: array
    take x returns max(0, x)
    """
    return np.array(max(0, x) if isinstance(x, (int, float)) else [max(0, val) for val in x])



def forwar_pass(input_, layers, weights, bias):
    """
    input_:array
    layers:int
    weights:array
    bias_array
    takes input vector and the NN parameters returns single value output
    """
    for i in range(layers-1):

        Layer_pass = relu(input_@weights[i].T + bias[i])  #taking the transpose of weights
        input_ = Layer_pass
    output = input_@weights[-1].T + bias[-1]
    return output   

def min_max_scaler_(input_,acc_type):
    """
    Takes input_ :array
    acc_type:string
    Using the max and min from the each input parameter, hardcoded as mins,and maxs,
    returns the scaled input_ :array
    """
    
    mins = np.array([-4.1981, 0.01, -99])   #[age,mass,mdot] mins
    maxs = np.array([8.0, 10.567092, -3.7644])  # [age,mass,mdot] maxs
    if acc_type == 'N_acc':  # if acc_type = N_acc no need to scale mdot
        mins = mins[:2]
        maxs = maxs[:2]
        
    scaled_vec = (input_ - mins) / (maxs - mins)
    return scaled_vec

          
def input_manipluation(input_):
    """
    takes input_:array 
    returns:
        input_:array,
        acc_type:string,
        PRED_PARAMS:array of strings,
        LEN_PRED_PARAMS:int
    """
                    
    input_[0] = np.log10(input_[0])
    acc_type = 'Acc'
    if input_[2] <1e-40:
        input_ = input_[:2]
        acc_type = 'N_acc'
        PRED_PARAMS = ['Radius','Lum', 'T_eff']
        LEN_PRED_PARAMS = len(PRED_PARAMS)
    else:
        input_[2] = np.log10(input_[2])
        PRED_PARAMS = ['Radius','Lum', 'T_eff','Acc_Lum']
        LEN_PRED_PARAMS = len(PRED_PARAMS)
        
    input_ = min_max_scaler_(input_,acc_type)
    return input_,acc_type,PRED_PARAMS,LEN_PRED_PARAMS


def inverse_minmax_scaling(scaled_val):
    """
    scaled_val:float
    return inverse_scaled:float
    """
    min_value = -99.0
    max_value = 3.1700734273350384
    
    inverse_scaled = scaled_val * (max_value - min_value) + min_value
    return inverse_scaled

def predict_stellar_properties(input_,acc_type,PRED_PARAMS,LEN_PRED_PARAMS):
    """
    input_:array
    acc_type:string
    PRED_PARAMS:array of strings
    LEN_PRED_PARAMS:int
    return predcitions:array 
    """
    


    predictions = np.zeros(LEN_PRED_PARAMS)      
    
    for i,pred_param in enumerate(PRED_PARAMS):
        layers, weights, bias = neural_network_(pred_param,acc_type)
        pred = forwar_pass(input_, layers, weights, bias)
        predictions[i] = pred[0]
    
    if LEN_PRED_PARAMS>3:
        predictions[3] = inverse_minmax_scaling(predictions[3])
        
    return  predictions   
        
    
        
    
    


if __name__ =='__main__':
    
    t0 = time.time()
    parser = argparse.ArgumentParser(description="Given an input vector [age,mass,mdot] returns [radius,Lstellar,temperature,Lacc] using a neural network",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-l', '--list', help='delimited list input, example: "1866331.3016338805, 5.95185857, 5.196092096677678e-08"', type=str)
    args = parser.parse_args()
    #get input into an array
    input_ = np.array([float(item) for item in args.list.split(',')])

    #get input into correct format
    input_,acc_type,PRED_PARAMS,LEN_PRED_PARAMS = input_manipluation(input_)
    
    #predict
    predcitions_vect = predict_stellar_properties(input_,acc_type,PRED_PARAMS,LEN_PRED_PARAMS)
    print(predcitions_vect)
    print(f'Time taken {time.time() - t0}')
  