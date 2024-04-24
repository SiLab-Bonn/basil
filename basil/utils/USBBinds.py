from pathlib import Path

import pyvisa

def queryIdentification(rm, resource, baud_rate, read_termination="\n", write_termination="\n", timeout=1000 * 5):
    """
    Queries the identification of the instrument connected via USB.

    Args:
        rm (pyvisa.ResourceManager): The pyvisa resource manager.
        resource (str): The resource name or address of the instrument.
        baud_rate (int): The baud rate for communication with the instrument.
        read_termination (str, optional): The read termination character(s). Defaults to "\n".
        write_termination (str, optional): The write termination character(s). Defaults to "\n".
        timeout (int, optional): The timeout value in milliseconds. Defaults to 5000.

    Returns:
        str: The identification string of the instrument.

    """
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
        # try first ASRL port
        if instrument.get("port") and 'ASRL' not in instrument.get("port"):
            instrument["port"] = f'ASRL{instrument["port"]}::INSTR'
        resources = (instrument["port"],) + rm.list_resources() if instrument.get("port") else rm.list_resources()

        for res in resources:
            if "USB" not in res:  # Only search for USB devices
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

def getBaudrate(dictionary):
    """
    Gets the baud rate from the given dictionary.

    Args:
        dict (dict): The dictionary to get the baud rate from.

    Returns:
        int: The baud rate.
    """
    if "baud_rate" in dictionary.keys():
        return dictionary["baud_rate"]
    elif "baudrate" in dictionary.keys():
        return dictionary["baudrate"]
    else:
        return 9600

def modify_basil_config(conf, log, skip_binds=[], verbose=False):
    """
    Modifies the basil configuration file by finding USB binds for devices.

    Args:
        conf (dict): The basil configuration dictionary.
        log: The logger object for logging messages.
        skip_binds (list, optional): List of USB binds to skip. Defaults to [].
        verbose (bool, optional): Flag to enable verbose logging. Defaults to False.

    Returns:
        dict: The modified basil configuration dictionary.
    """
    log.info("Trying to find USB binds for devices in basil configuration file")

    rm = pyvisa.ResourceManager()

    instruments = []
    insts_idx_map = {}

    # Iterate over transfer layers in the configuration
    for i, tf in enumerate(conf["transfer_layer"]):
        if (
            "identification" not in tf["init"].keys()
            or "read_termination" not in tf["init"].keys()
            or not any(e in tf["init"].keys() for e in ["baud_rate", "baudrate"])
        ):
            if verbose:
                log.debug(f"Skipping {tf['type']} transfer layer with name {tf['name']}")
            continue

        instrument = tf["init"]["identification"]
        baud_rate = getBaudrate(tf["init"])
        read_termination = tf["init"]["read_termination"]
        write_termination = tf["init"]["write_termination"] if "write_termination" in tf["init"].keys() else "\n"
        
        instruments.append({
            "identification": instrument,
            "baud_rate": baud_rate,
            "read_termination": read_termination,
            "write_termination": write_termination,
        })

        insts_idx_map[instrument.lower().strip()] = i

    found_binds = findUSBBinds(rm, log=log, instruments=instruments, binds_to_skip=skip_binds, verbose=verbose)

    for inst in found_binds.keys():
        if found_binds[inst] is None:
            raise LookupError(f"Could not find USB bind for {inst.title().replace('_', '')}")

        if conf["transfer_layer"][insts_idx_map[inst]]["type"].lower() == "serial":
            conf["transfer_layer"][insts_idx_map[inst]]["init"]["port"] = found_binds[inst]
        elif conf["transfer_layer"][insts_idx_map[inst]]["type"].lower() == "visa":
            conf["transfer_layer"][insts_idx_map[inst]]["init"]["resource_name"] = f"ASRL{found_binds[inst]}::INSTR"

        del conf["transfer_layer"][insts_idx_map[inst]]["init"]["identification"]

    return conf