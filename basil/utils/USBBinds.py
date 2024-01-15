from pathlib import Path

import pyvisa

def queryIdentification(rm, resource, baud_rate, read_termination="\n", write_termination="\n", timeout=1000 * 5, verbose=False):
    inst = rm.open_resource(resource)
    inst.timeout = timeout
    inst.baud_rate = baud_rate
    inst.read_termination = read_termination
    inst.write_termination = write_termination

    return inst.query("*IDN?", delay=0.5)

def findUSBBinds(rm, log,
    instruments,
    binds_to_skip=[],
    memorized_binds=[],
    timeout=1000 * 4,
    verbose=False,
):
    """
    Finds the USB bind for each instrument in the given list of instruments.

    Args:
        rm (pyvisa.ResourceManager): The pyvisa resource manager.
        log (logging.Logger): The logger object for logging messages.
        instruments (list): List of dictionaries representing the instruments.
            Each dictionary should contain the following keys:
            - 'baud_rate': The baud rate for the instrument.
            - 'read_termination': The read termination character for the instrument.
            - 'write_termination' (optional): The write termination character for the instrument.
            - 'identification': The identification string for the instrument.
        binds_to_skip (list, optional): List of binds to skip during the search.
            Defaults to an empty list.
        memorized_binds (list, optional): List of memorized binds.
            Defaults to an empty list.
        timeout (int, optional): Timeout value in milliseconds.
            Defaults to 4000.
        verbose (bool, optional): Flag indicating whether to log verbose messages.
            Defaults to False.

    Returns:
        dict: A dictionary mapping the identification strings of the instruments
            to their corresponding USB binds.
    """
    skip_binds = binds_to_skip + [
        str(Path(f"/dev/{bind}").resolve()) for bind in binds_to_skip
    ]

    results = {}

    for instrument in instruments:    
        for res in rm.list_resources():
            if "USB" not in res: # Only search for USB devices
                continue

            if any(bind in res for bind in skip_binds):
                if verbose:
                    log.info(f"Skipping USB bind {res}")
                continue

            try:                
                if verbose:
                    log.info(f"Trying {res} with baud rate {instrument['baud_rate']}")

                if any(res in bind for bind in memorized_binds):
                    if verbose:
                        log.info(f"Found memorized bind {res}")
                    result = memorized_binds[res]
                else:
                    result = queryIdentification(rm, res, instrument['baud_rate'], instrument['read_termination'], instrument['write_termination'], timeout=timeout, verbose=verbose)

                    memorized_binds.append({res, result})

                    if verbose:
                        log.info(f"Found {result.strip()}")                              
                
                if result.lower().strip() in [inst["identification"].lower().strip() for inst in instruments]:
                    substring = res.split("/")[2].split("::")[0]

                    log.info(f"Matched instrument {instrument['identification']} to /dev/{str(substring)}")
                    skip_binds.append(f"/dev/{str(substring)}")

                    results[result.lower().strip()] = f"/dev/{str(substring)}"
                    
                    if len(results) == len(instruments):
                        return results
                
            except pyvisa.VisaIOError:
                pass

    return results
