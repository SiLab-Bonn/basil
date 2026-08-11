import functools
import struct
import warnings
from typing import Callable, Iterable, Optional, Sequence, Union, Dict, Literal, Any, Tuple
from types import ModuleType

np: Optional[ModuleType]
try:
    import numpy

    np = numpy
except ImportError:
    print("There was an numpy import error")
    np = None

def _use_numpy_routines(container: Callable) -> bool:
    return True
    return np is not None and isinstance(container, np.ndarray)


DEFAULT_LENGTH_BEFORE_BLOCK = 25

_converters: Dict[str, Callable[[str], Any]] = {
    "s": str,
    "b": functools.partial(int, base=2),
    "c": ord,
    "d": int,
    "o": functools.partial(int, base=8),
    "x": functools.partial(int, base=16),
    "X": functools.partial(int, base=16),
    "h": functools.partial(int, base=16),
    "H": functools.partial(int, base=16),
    "e": float,
    "E": float,
    "f": float,
    "F": float,
    "g": float,
    "G": float,
}

_np_converters = {
    "d": "i",
    "e": "d",
    "E": "d",
    "f": "d",
    "F": "d",
    "g": "d",
    "G": "d",
}

#: Valid binary header when reading/writing binary block of data from an instrument
BINARY_HEADERS = Literal["ieee", "hp", "rs", "empty"]

#: Valid datatype for binary block. See Python standard library struct module for more
#: details.
BINARY_DATATYPES = Literal[
    "s", "b", "B", "h", "H", "i", "I", "l", "L", "q", "Q", "f", "d"
]

#: Valid output containers for storing the parsed binary data
BINARY_CONTAINERS = Union[type, Callable]


def parse_ieee_block_header(
        block: Union[bytes, bytearray],
        length_before_block: Optional[int] = None,
        raise_on_late_block: bool = False,
) -> Tuple[int, int]:
    """Parse the header of a IEEE block.

    Definite Length Arbitrary Block:
    #<header_length><data_length><data>

    The header_length specifies the size of the data_length field.
    And the data_length field specifies the size of the data.

    Indefinite Length Arbitrary Block:
    #0<data>

    In this case the data length returned will be 0. The actual length can be
    deduced from the block and the offset.

    Parameters
    ----------
    block : Union[bytes, bytearray]
        IEEE formatted block of data.
    length_before_block : Optional[int], optional
        Number of bytes before the actual start of the block. Default to None,
        which means that number will be inferred.
    raise_on_late_block : bool, optional
        Raise an error in the beginning of the block is not found before
        DEFAULT_LENGTH_BEFORE_BLOCK, if False use a warning. Default to False.

    Returns
    -------
    int
        Offset at which the actual data starts
    int
        Length of the data in bytes.

    """
    begin = block.find(b"#")
    if begin < 0:
        raise ValueError(
            'Could not find hash sign ("#") indicating the start of the block. '
            "The block begins with %r" % block[:25]
        )
    length_before_block = (
        DEFAULT_LENGTH_BEFORE_BLOCK
        if length_before_block is None
        else length_before_block
    )
    if begin > length_before_block:
        msg = (
                  "The beginning of the block has been found at %d which "
                  "is an unexpectedly large value. The actual block may "
                  "have been missing a beginning marker but the block "
                  "contained one:\n%s"
              ) % (begin, repr(block[: begin + 25]))
        if raise_on_late_block:
            raise RuntimeError(msg)
        else:
            warnings.warn(msg, UserWarning)

    try:
        # int(block[begin+1]) != int(block[begin+1:begin+2]) in Python 3
        header_length = int(block[begin + 1: begin + 2], base=16)
    except ValueError:
        header_length = 0

    offset = begin + 2 + header_length

    if header_length > 0:
        # #3100DATA
        # 012345

        if header_length == 10 and len(block[begin:]) < (2 ** 16) + 4:
            # Detect an HP formatted block, which starts with "A"
            msg = (
                "Header length in IEEE format was indicated as 0xA (10d) but the "
                "block length was less than 64 KiB. It appears the block may be "
                "using the HP format instead of IEEE. If so, you will need to use "
                'the `header_fmt = "hp"` argument.'
            )
            raise ValueError(msg)

        data_length = int(block[begin + 2: offset])

    else:
        # #0DATA
        # 012
        data_length = -1

    return offset, data_length


def from_binary_block(
        block: Union[bytes, bytearray],
        offset: int = 0,
        data_length: Optional[int] = None,
        datatype: BINARY_DATATYPES = "f",
        is_big_endian: bool = False,
        container: Callable[
            [Iterable[Union[int, float]]], Sequence[Union[int, float]]
        ] = list,
) -> Sequence[Union[int, float]]:
    """Convert a binary block into an iterable of numbers.


    Parameters
    ----------
    block : Union[bytes, bytearray]
        HP formatted block of data.
    offset : int
        Offset at which the actual data starts
    data_length : int
        Length of the data in bytes.
    datatype : BINARY_DATATYPES, optional
        Format string for a single element. See struct module. 'f' by default.
    is_big_endian : bool, optional
        Are the data in big or little endian order.
    container : Union[Type, Callable[[Iterable], Sequence]], optional
        Container type to use for the output data. Possible values are: list,
        tuple, np.ndarray, etc, Default to list.

    Returns
    -------
    Sequence[Union[int, float]]
        Parsed data.

    """
    if data_length is None or data_length < 0:
        data_length = len(block) - offset

    element_length = struct.calcsize(datatype)
    array_length = int(data_length / element_length)
    endianess = ">" if is_big_endian else "<"

    if _use_numpy_routines(container):
        assert np  # for typing
        res = np.frombuffer(block, endianess + datatype, array_length, offset)
        return res

    fullfmt = "%s%d%s" % (endianess, array_length, datatype)

    try:
        raw_data = struct.unpack_from(fullfmt, block, offset)
    except struct.error:
        raise ValueError("Binary data was malformed")

    if datatype in "sp":
        raw_data = raw_data[0]

    return container(raw_data)
