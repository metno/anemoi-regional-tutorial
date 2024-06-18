import datetime
from copy import deepcopy

from climetlab import load_source
from climetlab.utils.availability import Availability

from anemoi.datasets.create.utils import to_datetime_list

DEBUG = False


def to_list(x):
    if isinstance(x, (list, tuple)):
        return x
    return [x]


def _date_to_datetime(d):
    if isinstance(d, datetime.datetime):
        return d
    if isinstance(d, (list, tuple)):
        return [_date_to_datetime(x) for x in d]
    return datetime.datetime.fromisoformat(d)


def normalise_time_delta(t):
    if isinstance(t, datetime.timedelta):
        assert t == datetime.timedelta(hours=t.hours), t

    assert t.endswith("h"), t

    t = int(t[:-1])
    t = datetime.timedelta(hours=t)
    return t


def _expand_cds_request(request, date):
    requests = []
    step = to_list(request.get("step", [0]))
    for s in step:
        r = deepcopy(request)
        base = date - datetime.timedelta(hours=int(s))
        r.update(
            {
                "year": base.strftime("%Y"),
                "month": base.strftime("%m"),
                "day": base.strftime("%d"),
                "time": base.strftime("%H:%M"),
                # "step": s,
            }
        )

        for pproc in ("grid", "rotation", "frame", "area", "bitmap", "resol"):
            if pproc in r:
                if isinstance(r[pproc], (list, tuple)):
                    r[pproc] = "/".join(str(x) for x in r[pproc])

        requests.append(r)

    return requests


def factorise_requests(dates, *requests):
    updates = []
    for req in requests:
        # req = normalise_request(req)

        for d in dates:
            updates += _expand_cds_request(req, date=d)

    compressed = Availability(updates)
    for r in compressed.iterate():
        for k, v in r.items():
            if isinstance(v, (list, tuple)) and len(v) == 1:
                r[k] = v[0]
        yield r


def cds(context, dates, *requests, **kwargs):
    if not requests:
        requests = [kwargs]

    requests = factorise_requests(dates, *requests)
    ds = load_source("empty")
    for r in requests:
        r = {k: v for k, v in r.items() if v != ("-",)}
        if DEBUG:
            context.trace("✅", f"load_source(cds, {r}")

        ds = ds + load_source("cds", **r)
    return ds


execute = cds
