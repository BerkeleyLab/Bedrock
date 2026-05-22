# Sets up LiteX as needed by bedrock, specifically projects/trigger_capture
# It's a monster!
# Definitely needs network access
# Expect to start this in a blank directory, where you have write access
# Probably use a python venv
# Total disk space consumed: about 658 MB
# How to use litex_setup_freeze_repos()?
set -e

rm -f litex_setup.py
# See https://github.com/enjoy-digital/litex
wget https://raw.githubusercontent.com/enjoy-digital/litex/4b67db328dba1076751e7bf3250f9c2fdca0093e/litex_setup.py
echo "396fd82e6fc584eadf2e4bb6005e361b62225583bac903aff0026fedf03e33ee litex_setup.py" | sha256sum -c
# patch one line to disable auto-update
patch litex_setup.py << EOT
526c526
<     if not args.dev:
---
>     if False and not args.dev:
EOT

# Now that we're quite sure we have the litex_setup we want,
# go ahead and run it.
python3 litex_setup.py --init --update --tag 2025.08 --config standard
cd pythondata-software-picolibc && git checkout 2025.08 && git submodule update --init --recursive && cd ..
python3 litex_setup.py install --break-system-packages
git clone https://github.com/litex-hub/pythondata-cpu-picorv32.git
cd pythondata-cpu-picorv32 && PYTHONPATH=. pip3 install --no-build-isolation --break-system-packages -e . && cd ..

echo "DONE"
