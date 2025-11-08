# Sets up LiteX as needed by bedrock, specifically projects/trigger_capture
# It's a monster!
# Definitely needs network access
# Expect to start this in a blank directory, where you have write access
# Probably use a python venv
# Total disk space consumed: about 658 MB
# How to use litex_setup_freeze_repos()?
set -e

rm -f litex_setup.py
# Commit 05ddccb206 is tag: 2025.08, dated 2025-10-03
# See https://github.com/enjoy-digital/litex
wget https://raw.githubusercontent.com/enjoy-digital/litex/05ddccb206ffd02e0efc/litex_setup.py
echo "ac835dfa7631357de28326e0c8b8dec46d1fbdab46e59679a2e6b1e709e90938  litex_setup.py" | sha256sum -c
# patch two lines, to keep picorv32 in "standard" config, and disable auto-update
patch litex_setup.py << EOT
157c157
< standard_repos.remove("pythondata-cpu-picorv32")
---
> # standard_repos.remove("pythondata-cpu-picorv32")
526c526
<     if not args.dev:
---
>     if False and not args.dev:
EOT
echo "d859db819bc3dba4a7120be7e2c4b60fea107fa22b54aebb5678ccc8c6a13666  litex_setup.py" | sha256sum -c

# Now that we're quite sure we have the litex_setup we want,
# go ahead and run it.
python3 litex_setup.py --init --update --tag 2025.08 --install --config standard
echo "DONE"
