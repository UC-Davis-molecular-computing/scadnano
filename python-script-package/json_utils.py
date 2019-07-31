##############################################################################
# JSON serialization defaults
# This is a much more primitive version of https://jsonpickle.github.io/,
# In particular, it does not handle the case of circular object references
# (and in fact has an infinite loop if they exist), but I don't want any
# external package dependencies, and this is good enough for our case.

from abc import abstractmethod, ABC
from _ctypes import PyObj_FromPtr
import json
import re


class JSONSerializable(ABC):

    @abstractmethod
    def to_json_serializable(self):
        raise NotImplementedError()


def json_encode(obj: JSONSerializable):
    return json.dumps(obj.to_json_serializable(), cls=SuppressableIndentEncoder, indent=2)


##############################################################################
# SuppressableIndentEncoder


class NoIndent(object):
    """ Value wrapper. """

    def __init__(self, value):
        self.value = value


class SuppressableIndentEncoder(json.JSONEncoder):
    """
    This lets us control the indentation to get a nice balance between the fully indented
    option given by :func:`json.dumps` with argument `indent` set
    (which is unreadably sparse since it puts every single container item in
    the whole JSON tree on a separate line),
    and the (also unreadable) default with no whitespace.
    Classes should define themselves as a subclass of :any:`json_utils.JSONSerializable`,
    define a `to_json_serializable` method,
    and wrap anything that should not be indented in :any:`json_utils.NoIndent`.
    The subtree underneath cannot contain another :any:`json_utils.NoIndent`,
    i.e., every root-to-left path should contain at most one :any:`json_utils.NoIndent`.
    Taken from
    https://stackoverflow.com/questions/13249415/how-to-implement-custom-indentation-when-pretty-printing-with-the-json-module
    """

    FORMAT_SPEC = '@@{}@@'
    regex = re.compile(FORMAT_SPEC.format(r'(\d+)'))

    def __init__(self, **kwargs):
        # Save copy of any keyword argument values needed for use here.
        self.__sort_keys = kwargs.get('sort_keys', None)
        super(SuppressableIndentEncoder, self).__init__(**kwargs)

    def default(self, obj):
        return (self.FORMAT_SPEC.format(id(obj)) if isinstance(obj, NoIndent)
                else super(SuppressableIndentEncoder, self).default(obj))

    def encode(self, obj):
        format_spec = self.FORMAT_SPEC  # Local var to expedite access.
        json_repr = super(SuppressableIndentEncoder, self).encode(obj)  # Default JSON.

        # Replace any marked-up object ids in the JSON repr with the
        # value returned from the json.dumps() of the corresponding
        # wrapped Python object.
        for match in self.regex.finditer(json_repr):
            # see https://stackoverflow.com/a/15012814/355230
            _id = int(match.group(1))
            no_indent = PyObj_FromPtr(_id)
            json_obj_repr = json.dumps(no_indent.value, sort_keys=self.__sort_keys)

            # Replace the matched id string with json formatted representation
            # of the corresponding Python object.
            json_repr = json_repr.replace(
                '"{}"'.format(format_spec.format(_id)), json_obj_repr)

        return json_repr


if __name__ == '__main__':
    from string import ascii_lowercase as letters

    data_structure = {
        'layer1': {
            'layer2': {
                'layer3_1': NoIndent([{"x": 1, "y": 7}, {"x": 0, "y": 4}, {"x": 5, "y": 3},
                                      {"x": 6, "y": 9},
                                      {k: v for v, k in enumerate(letters)}]),
                'layer3_2': 'string',
                'layer3_3': NoIndent([{"x": 2, "y": 8, "z": 3}, {"x": 1, "y": 5, "z": 4},
                                      {"x": 6, "y": 9, "z": 8}]),
                'layer3_4': NoIndent(list(range(20))),
            }
        }
    }

    print(json.dumps(data_structure, cls=SuppressableIndentEncoder, sort_keys=True, indent=2))

# END CustomIndentEncoder
##############################################################################


# old code below here

# def _is_json_serializable(obj):
#     # This check is based on the following table:
#     # https://docs.python.org/3/library/json.html#py-to-json-table
#     return (obj is None
#             or type(obj) in [str, int, float, bool, list, tuple, dict]
#             or issubclass(type(obj), enum.Enum))
#
#
# def _default_json_encode(obj):
#     # This check is based on the following table:
#     # https://docs.python.org/3/library/json.html#py-to-json-table
#     obj_type = type(obj)
#     if obj is None or obj_type in [str, int, float, bool] or issubclass(obj_type, enum.Enum):
#         return obj
#     elif obj_type == list:
#         return [_default_json_encode(elt) for elt in obj]
#     elif obj_type == tuple:
#         return (_default_json_encode(elt) for elt in obj)
#     elif obj_type == dict:
#         return {key: _default_json_encode(val) for (key, val) in obj.items()}
#     else:
#         fields = dict(obj.__dict__)
#         non_serializable_fields = {}
#         for (key, val) in fields.items():
#             if not _is_json_serializable(val):
#                 non_serializable_fields[key] = _default_json_encode(val)
#         fields.update(non_serializable_fields)
#         return fields
#
#
# class _ObjectTreeJSONEncoder(json.JSONEncoder):
# # class _ObjectTreeJSONEncoder(jci.CustomIndentEncoder):
#     """Assumes that object containment is a tree (XXX: has infinite recursion otherwise!!)
#     and makes a default JSON encoder for each object that is not already serializable,
#     using the object's __dict__."""
#
#     def default(self, obj):
#         obj_custom_indent = _default_json_encode(obj)
#
#         return super(obj_custom_indent)
#
#
# class JSONMixin:
#     """Gives the class a method called to_json() that uses the _ObjectTreeJSONEncoder
#     to create JSON.
#
#     This is a mixin class intended to be subclassed.
#
#     WARNING: it assumes the object hierarchy is a tree and will have an infinite loop
#     if there is a cycle in the object graph."""
#
#     def to_json(self, indent=2) -> str:
#         """Return a JSON string representing this object.
#
#         Default indent is 2; use indent=i to make it i or None to turn it off."""
#         json_str = json.dumps(self, cls=_ObjectTreeJSONEncoder, indent=indent)
#         return json_str
#         # return remove_indent_beyond(js=json_str, indent=indent, max_level=2, max_line_length=120)
#
#
# def remove_indent_beyond(js: str, indent: int, max_level: int, max_line_length: int):
#     """Kludgy way to remove indents from JSON strings formatted with the `indent` argument.
#
#     Replaces newlines followed by too many spaces (more than indent*max_level)
#     with empty string."""
#
#     pattern_spaces = r'\s' * (indent * max_level) + r'\s*'
#     pattern_end_dict = r'\s' * (indent * (max_level - 1)) + '}'
#     pattern_end_list = r'\s' * (indent * (max_level - 1)) + ']'
#     pattern_full = '^(' + pattern_spaces + ')|(' + pattern_end_dict + ')|(' + pattern_end_list + ')'
#     pattern_end_container = '^(' + pattern_end_dict + ')|(' + pattern_end_list + ')'
#
#     def chop(line):
#         return re.sub(r'^\s*', '', line)
#
#     new_lines = []
#     merged_line_builder = []
#
#     for line in js.split('\n'):
#         if not re.match(pattern_full, line):
#             new_lines.append(line)
#         else:
#             merged_line_builder.append(line)
#             if re.match(pattern_end_container, line):
#                 chopped_line_builder = [chop(l) for l in merged_line_builder]
#                 merged_line = ''.join(chopped_line_builder)
#                 merged_line_builder = []
#                 if len(merged_line) < max_line_length:
#                     new_lines.append(merged_line)
#                 else:
#                     new_lines.extend(merged_line_builder)
#
#     return '\n'.join(new_lines)
