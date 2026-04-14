from abc import abstractmethod, ABC
import json


class JSONSerializable(ABC):

    @abstractmethod
    def to_json_serializable(self, suppress_indent=True):
        raise NotImplementedError()


def json_encode(obj: JSONSerializable, suppress_indent: bool = True) -> str:
    encoder = SuppressableIndentEncoder if suppress_indent else json.JSONEncoder
    serializable = obj.to_json_serializable(suppress_indent=suppress_indent)
    return json.dumps(serializable, cls=encoder, indent=2)


class NoIndent:
    """ Value wrapper. """

    def __init__(self, value):
        self.value = value


class SuppressableIndentEncoder(json.JSONEncoder):
    def __init__(self, *args, **kwargs):
        self.unique_id = 0
        super(SuppressableIndentEncoder, self).__init__(*args, **kwargs)
        self.kwargs = dict(kwargs)
        del self.kwargs['indent']
        self._replacement_map = {}

    def default(self, obj):
        if isinstance(obj, NoIndent):
            # key = uuid.uuid1().hex # this caused problems with Brython.
            key = self.unique_id
            self.unique_id += 1
            self._replacement_map[key] = json.dumps(obj.value, **self.kwargs)
            return "@@%s@@" % (key,)
        else:
            return super().default(obj)

    def encode(self, obj):
        result = super().encode(obj)
        for k, v in self._replacement_map.items():
            result = result.replace('"@@%s@@"' % (k,), v)
        return result


# class KeepIndentEncoder(json.JSONEncoder):
#     def __init__(self, *args, **kwargs):
#         self.unique_id = 0
#         super(KeepIndentEncoder, self).__init__(*args, **kwargs)
#         self.kwargs = dict(kwargs)
#         del self.kwargs['indent']
#         self._replacement_map = {}
#
#     def default(self, o):
#         if isinstance(o, NoIndent):
#             return o.value
#         else:
#             return super(KeepIndentEncoder, self).default(o)


# class SuppressableIndentEncoder(json.JSONEncoder):
#     """
#     This lets us control the indentation to get a nice balance between the fully indented
#     option given by :func:`json.dumps` with argument `indent` set
#     (which is unreadably sparse since it puts every single container item in
#     the whole JSON tree on a separate line),
#     and the (also unreadable) minified default with no whitespace.
#     Classes should define themselves as a subclass of :any:`json_utils.JSONSerializable`,
#     define a `to_json_serializable` method (which should return a serializable Python object
#     as defined here: https://docs.python.org/3/library/json.html#py-to-json-table),
#     and wrap anything that should not be indented in :any:`json_utils.NoIndent`.
#     The subtree underneath cannot contain another :any:`json_utils.NoIndent`,
#     i.e., every root-to-left path should contain at most one :any:`json_utils.NoIndent`.
#     Code taken from
#     https://stackoverflow.com/questions/13249415/how-to-implement-custom-indentation-when-pretty-printing-with-the-json-module
#     """
#
#     FORMAT_SPEC = '@@{}@@'
#     regex = re.compile(FORMAT_SPEC.format(r'(\d+)'))
#
#     def __init__(self, **kwargs):
#         # Save copy of any keyword argument values needed for use here.
#         self.__sort_keys = kwargs.get('sort_keys', None)
#         super(SuppressableIndentEncoder, self).__init__(**kwargs)
#
#     def default(self, obj):
#         return (self.FORMAT_SPEC.format(id(obj)) if isinstance(obj, NoIndent)
#                 else super(SuppressableIndentEncoder, self).default(obj))
#
#     def encode(self, obj):
#         format_spec = self.FORMAT_SPEC  # Local var to expedite access.
#         json_repr = super(SuppressableIndentEncoder, self).encode(obj)  # Default JSON.
#
#         # Replace any marked-up object ids in the JSON repr with the
#         # value returned from the json.dumps() of the corresponding
#         # wrapped Python object.
#         for match in self.regex.finditer(json_repr):
#             # see https://stackoverflow.com/a/15012814/355230
#             _id = int(match.group(1))
#             no_indent = PyObj_FromPtr(_id)
#             json_obj_repr = json.dumps(no_indent.value, sort_keys=self.__sort_keys)
#
#             # Replace the matched id string with json formatted representation
#             # of the corresponding Python object.
#             json_repr = json_repr.replace(
#                 '"{}"'.format(format_spec.format(_id)), json_obj_repr)
#
#         return json_repr


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

