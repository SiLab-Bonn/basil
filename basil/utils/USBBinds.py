import os

from pathlib import Path

from six import string_types

import pyvisa

import ruamel.yaml


def query_identification(rm, resource, baud_rate, read_termination=None, write_termination=None, timeout=1000 * 5):
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
    try:
        reply = inst.query("*IDN?", delay=0.1)
    except pyvisa.VisaIOError:
        # This retries the query a second time, since some devices do not answer the first time.
        # If a second exception arrises, it will be handled in calling function.
        reply = inst.query("*IDN?", delay=0.1)
    return reply


def find_usb_binds(rm, log,
                   instruments,
                   binds_to_skip=[],
                   memorized_binds={},
                   timeout=1000 * 4
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
        memorized_binds (dict, optional): Dictionary of memorized binds.
            Defaults to an empty dictionary.
        timeout (int, optional): Timeout value in milliseconds.
            Defaults to 4000.

    Returns:
        dict: A dictionary mapping the identification strings of the instruments
            to their corresponding USB binds.
    """
    skip_binds = binds_to_skip + [
        str(Path(f"/dev/{bind}").resolve()) for bind in binds_to_skip
    ]

    results = {}

    for instrument in instruments:
        log.info(f"Searching for {instrument['identification']}")

        resources = rm.list_resources()

        if "port" in instrument.keys():
            port = instrument.get("port")

            if 'ASRL' not in port:
                port = f'ASRL{port}::INSTR'
            if port in resources:
                resources = (port,) + resources

        for i, res in enumerate(resources):
            log.debug(f"[{i}] Trying {res}")

            if "USB" not in res:  # Only search for USB devices
                log.debug(f"Skipping non USB bind {res}")
                continue

            if any(bind in res for bind in skip_binds):
                log.debug(f"Skipping USB bind {res}")
                continue

            try:
                log.debug(f"Trying {res} with baud rate {instrument['baud_rate']}")

                if memorized_binds.get(res):
                    log.debug(f"Found memorized bind {res}")
                    result = memorized_binds[res]
                else:
                    result = query_identification(rm, res, instrument['baud_rate'], instrument['read_termination'], instrument['write_termination'], timeout=timeout)

                    memorized_binds[res] = result
                    log.debug(f"Found {result.strip()}")

                for inst in instruments:
                    if result.lower().strip() in inst["identification"].lower().strip():
                        substring = res.split("/")[2].split("::")[0]

                        log.info(f"Matched instrument {inst['identification']} to /dev/{str(substring)}")
                        skip_binds.append(f"/dev/{str(substring)}")

                        results[result.lower().strip()] = f"/dev/{str(substring)}"

                        if len(results) == len(instruments):
                            return results

                        log.debug(f"Found {len(results)} out of {len(instruments)}")

                        break
                else:
                    continue

                if inst["identification"].lower().strip() in instrument["identification"].lower().strip():
                    break

            except pyvisa.VisaIOError:
                pass

    return results


def get_baudrate(dictionary):
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


def load_yaml_with_comments(conf):
    """
    Load YAML configuration file with comments.

    Args:
        conf: The YAML configuration file path or a file-like object containing YAML content.

    Returns:
        dict: A dictionary containing the parsed YAML configuration.

    """
    conf_dict = {}

    if not conf:
        pass
    elif isinstance(conf, string_types):  # parse the first YAML document in a stream
        yaml = ruamel.yaml.YAML()
        if os.path.isfile(conf):
            with open(conf, 'r') as f:
                yaml = ruamel.yaml.YAML()
                conf_dict.update(yaml.load(f))
        else:  # YAML string
            try:
                conf_dict.update(yaml.load(conf))
            except ValueError:  # invalid path/filename
                raise IOError("File not found: %s" % conf)
    elif hasattr(conf, 'read'):  # parse the first YAML document in a stream
        yaml = ruamel.yaml.YAML()
        conf_dict.update(yaml.load(conf))
        conf.close()
    else:  # conf is already a dict
        conf_dict.update(conf)

    return conf_dict


def modify_basil_config(conf, log, skip_binds=[], save_modified=None):
    """
    Modifies the basil configuration file by finding USB binds for devices.

    Args:
        conf (dict): The basil configuration dictionary.
        log: The logger object for logging messages.
        skip_binds (list, optional): List of USB binds to skip. Defaults to [].
        save_modified (str, optional): Path to save the modified basil configuration file. Defaults to None.

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
            log.debug(f"Skipping {tf['type']} transfer layer with name {tf['name']}")
            continue

        instrument = tf["init"]["identification"]
        baud_rate = get_baudrate(tf["init"])
        read_termination = tf["init"]["read_termination"]
        write_termination = tf["init"]["write_termination"] if "write_termination" in tf["init"].keys() else "\n"
        if "port" in tf["init"].keys():
            port = tf["init"]["port"]
        elif "resource_name" in tf["init"].keys():
            port = tf["init"]["resource_name"]
        else:
            port = None

        instruments.append({
            "identification": instrument,
            "baud_rate": baud_rate,
            "read_termination": read_termination,
            "write_termination": write_termination,
            "port": port,
        })

        insts_idx_map[instrument.lower().strip()] = i

    found_binds = find_usb_binds(rm, log=log, instruments=instruments, binds_to_skip=skip_binds)

    for inst in found_binds.keys():
        if found_binds[inst] is None:
            raise LookupError(f"Could not find USB bind for {inst.title().replace('_', '')}")

        if conf["transfer_layer"][insts_idx_map[inst]]["type"].lower() == "serial":
            conf["transfer_layer"][insts_idx_map[inst]]["init"]["port"] = found_binds[inst]
        elif conf["transfer_layer"][insts_idx_map[inst]]["type"].lower() == "visa":
            conf["transfer_layer"][insts_idx_map[inst]]["init"]["resource_name"] = f"ASRL{found_binds[inst]}::INSTR"

    if save_modified is not None:
        yaml = ruamel.yaml.YAML()
        log.info(f'Saving modified periphery file: {save_modified}')
        with open(save_modified, 'w') as f:
            yaml.dump(conf, f)

    for inst in found_binds.keys():
        del conf["transfer_layer"][insts_idx_map[inst]]["init"]["identification"]

    return conf
