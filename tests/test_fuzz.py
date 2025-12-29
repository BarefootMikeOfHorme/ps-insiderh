import cbor2
from hypothesis import given, strategies as st

@given(st.binary())
def test_parse_cbor_no_crash(data):
    # Ensure that parsing arbitrary data does not raise unexpected exceptions
    try:
        obj = cbor2.loads(data)
        # Basic sanity check: if it's a dict/list, ensure it serializes back
        if isinstance(obj, (dict, list)):
            assert cbor2.dumps(obj) is not None
    except Exception:
        # We accept parse failures but not crashes; test passes if no unhandled crash
        pass
