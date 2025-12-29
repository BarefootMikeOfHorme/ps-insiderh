import glob
import pytest

try:
    import h5py
except Exception:
    h5py = None

HDF5_FILES = glob.glob('**/*.h5', recursive=True) + glob.glob('**/*.hdf5', recursive=True)

@pytest.mark.skipif(h5py is None, reason='h5py not installed')
def test_hdf5_contains_ps_insider_group():
    if not HDF5_FILES:
        pytest.skip('No HDF5 files found in repository; schema checks skipped')

    for path in HDF5_FILES:
        with h5py.File(path, 'r') as f:
            assert '/core' in f, f"{path} missing /core group"
            assert '/core/ps_insider' in f, f"{path} missing /core/ps_insider group"

@pytest.mark.skipif(h5py is None, reason='h5py not installed')
def test_templates_have_signature_metadata():
    if not HDF5_FILES:
        pytest.skip('No HDF5 files found in repository; signature checks skipped')

    for path in HDF5_FILES:
        with h5py.File(path, 'r') as f:
            if '/core/ps_insider/templates' in f:
                templates = f['/core/ps_insider/templates']
                for name, item in templates.items():
                    # Check for some form of signature metadata on template groups/datasets
                    attrs = item.attrs
                    has_sig = any(k.lower() in ('signature', 'signer', 'signature_digest', 'signed') for k in attrs.keys())
                    assert has_sig, f"Template {name} in {path} missing signature metadata"
