Scripts placed in this directory will be run by the `osconfig` playbook when
building target QCOWs. This is useful if you have some build instructions you
only want to run on the target images, but not for the ephemeral ISO.

This is a useful alternative to keep them separate instead of putting them all
in the same overrides file.

Scripts execution ordering is based on the sorted filenames of the scripts. Ex,
005-script1.sh runs before 050-script2.sh.
