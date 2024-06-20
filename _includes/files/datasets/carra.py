from climetlab.indexing.fieldset import FieldArray

class NewDataField:
    def __init__(self, field, data):
        self.field = field
        self.data = data

    def to_numpy(self, *args, **kwargs):
        return self.data

    def __getattr__(self, name):
        return getattr(self.field, name)


def execute(context, input):
    results = FieldArray()

    for f in input:
        key = f.as_mars()
        param = key.pop("param")
        if param == "orography":
            orog = f.to_numpy(reshape=False)
            geopotential = orog * 9.81
            results.append(NewDataField(f, geopotential))
        else:
            results.append(f)
    return results
