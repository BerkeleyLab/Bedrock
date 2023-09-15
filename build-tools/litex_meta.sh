# Sets up LiteX as needed by bedrock, specifically projects/trigger_capture
# It's a monster!
# Definitely needs network access
# Expect to start this in a blank directory, where you have write access
# Probably use a python venv
# Total disk space consumed: about 474 MB
# How to use litex_setup_freeze_repos()?
set -e

rm -f litex_setup.py
wget https://raw.githubusercontent.com/enjoy-digital/litex/639462ce465540fd9ce8/litex_setup.py
echo "54597b452644db21ecea9081ce9e191a7bd3b5d38610f5e7ccee60cb17d9150d  litex_setup.py" | sha256sum -c
# patch two lines, to keep picorv32 in "standard" config, and disable auto-update
patch litex_setup.py << EOT
149c149
< standard_repos.remove("pythondata-cpu-picorv32")
---
> # standard_repos.remove("pythondata-cpu-picorv32")
447c447
<     if not args.dev:
---
>     if False and not args.dev:
EOT
echo "d77081080f0c5109adc92d2730145228cb19633de7f2ff50ca3a4ec0cb341532  litex_setup.py" | sha256sum -c

# Now that we're quite sure we have the litex_setup we want,
# go ahead and run it.
python3 litex_setup.py init install --config standard
echo "DONE"
