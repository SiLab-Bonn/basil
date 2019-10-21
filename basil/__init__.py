from pkg_resources import get_distribution, DistributionNotFound
import collections
import yaml


__version__ = None  # required for initial installation

try:
    __version__ = get_distribution("basil_daq").version
except DistributionNotFound:
    __version__ = "(local)"


# Have OrderedDict
def dict_representer(dumper, data):
    return dumper.represent_dict(data.items())


def dict_constructor(loader, node):
    return collections.OrderedDict(loader.construct_pairs(node))


yaml.add_representer(collections.OrderedDict, dict_representer)
yaml.add_constructor(yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, dict_constructor)
