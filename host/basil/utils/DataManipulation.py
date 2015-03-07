#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import numpy as np


def convert_data_array(arr, filter_func=None, converter_func=None):
    '''Filter and convert any given data array of any dtype.

    Parameters
    ----------
    arr : numpy.array
        Data array of any dtype.
    filter_func : function
        Function that takes array and returns true or false for each item in array.
    converter_func : function
        Function that takes array and returns an array or tuple of arrays.

    Returns
    -------
    array of specified dimension (converter_func) and content (filter_func)
    '''
#     if filter_func != None:
#         if not hasattr(filter_func, '__call__'):
#             raise ValueError('Filter is not callable')
    if filter_func:
        array = arr[filter_func(arr)]  # Indexing with Boolean Arrays
#     if converter_func != None:
#         if not hasattr(converter_func, '__call__'):
#             raise ValueError('Converter is not callable')
    if converter_func:
        arr = converter_func(arr)
    return array


# Below are some examples for filter functions and converter functions

# Filter functions

def logical_and(f1, f2):  # function factory
    '''Logical and from functions.

    Parameters
    ----------
    f1, f2 : function
        Function that takes array and returns true or false for each item in array.

    Returns
    -------
    Function

    Examples
    --------
    filter_func=logical_and(is_data_record, is_data_from_channel(4))  # new filter function
    filter_func(array) # array that has Data Records from channel 4
    '''
    def f_and(arr):
        return np.logical_and(f1(arr), f2(arr))
    f_and.__name__ = f1.__name__ + "_and_" + f2.__name__
    return f_and


def logical_or(f1, f2):  # function factory
    '''Logical or from functions.

    Parameters
    ----------
    f1, f2 : function
        Function that takes array and returns true or false for each item in array.

    Returns
    -------
    Function
    '''
    def f_or(arr):
        return np.logical_or(f1(arr), f2(arr))
    f_or.__name__ = f1.__name__ + "_or_" + f2.__name__
    return f_or


def logical_not(f):  # function factory
    '''Logical not from functions.

    Parameters
    ----------
    f1, f2 : function
        Function that takes array and returns true or false for each item in array.

    Returns
    -------
    Function
    '''
    def f_not(arr):
        return np.logical_not(f(arr))
    f_not.__name__ = "not_" + f.__name__
    return f_not


def logical_xor(f1, f2):  # function factory
    '''Logical xor from functions.

    Parameters
    ----------
    f1, f2 : function
        Function that takes array and returns true or false for each item in array.

    Returns
    -------
    Function
    '''
    def f_xor(arr):
        return np.logical_xor(f1(arr), f2(arr))
    f_xor.__name__ = f1.__name__ + "_xor_" + f2.__name__
    return f_xor


def arr_select(value):  # function factory
    '''Selecting array elements by bitwise and comparison to a given value.

    Parameters:
    value : int
        Value to which array elements are compared to.

    Returns:
    array : np.array
    '''
    def f_eq(arr):
        return np.equal(np.bitwise_and(arr, value), value)
    f_eq.__name__ = "arr_bitwise_and_" + str(value)  # or use inspect module: inspect.stack()[0][3]
    return f_eq


# Converter functions

def arr_astype(arr_type):  # function factory
    '''Change dtype of array.

    Parameters:
    arr_type : str, np.dtype
        Character codes (e.g. 'b', '>H'), type strings (e.g. 'i4', 'f8'), Python types (e.g. float, int) and numpy dtypes (e.g. np.uint32) are allowed.

    Returns:
    array : np.array
    '''
    def f_astype(arr):
        return arr.astype(arr_type)
    f_astype.__name__ = "arr_astype_" + str(arr_type)  # or use inspect module: inspect.stack()[0][3]
    return f_astype
