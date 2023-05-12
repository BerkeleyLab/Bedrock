set -e
git clone --depth 1 --branch 0.7.0+3 https://gitlab.com/qf2-pre/users.git qf2_users
(cd qf2_users/qf2_python/QF2_pre/ &&
# when was this symbolic link needed?
# ln -s dev_runtime.py v_c268ccebd9ebe93221f75afdb9c67eb28973662dda472bb81d43d81d0731899a.py)
ls -l dev_runtime.py v_c268ccebd9ebe93221f75afdb9c67eb28973662dda472bb81d43d81d0731899a.py || true)
