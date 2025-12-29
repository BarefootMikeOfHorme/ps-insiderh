ps-insider patches

Files:
- `docs.patch` — docs-first retargeting changes (branch: docs/ps-insider)
- `ci.patch` — CI implementation changes (branch: feat/ci/ps-insider-security)
- `hdf5.patch` — HDF5 schema tests and dependency changes (branch: feat/hdf5-schema-tests)
- `ps-insider-all.patch` — concatenation of the above patches for easy application

How to apply:
- git apply patches/ps-insider-all.patch
- Review changes, run tests, and commit as necessary
