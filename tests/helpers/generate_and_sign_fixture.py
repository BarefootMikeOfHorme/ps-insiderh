from pathlib import Path
from .gpg_fixture_utils import create_hdf5_fixture, generate_key_and_sign


def build_fixture(base_dir: str = 'tests/fixtures'):
    Path(base_dir).mkdir(parents=True, exist_ok=True)
    h5_path = Path(base_dir) / 'canonical_unsigned.h5'
    sig_path = Path(base_dir) / 'canonical_unsigned.h5.sig'
    pubkey_path = Path(base_dir) / 'signer_pubkey.asc'

    create_hdf5_fixture(str(h5_path))
    generate_key_and_sign(str(h5_path), str(sig_path), str(pubkey_path))
    return str(h5_path), str(sig_path), str(pubkey_path)


if __name__ == '__main__':
    build_fixture()
    print('fixture built')