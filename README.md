# engine-drop-in

Example app to modify the systemd service of balena engine on disk.

This is useful for adding debug flags, adjusting the systemd watchdog, or providing new args to the engine.

After applying the changes for the first time the engine service will be restarted so use with caution!

The service is expected to remain in the `Exited` state after performing it's task.

This is for testing and can be repurposed but the current
iteration is to disable the systemd watchdog for the engine to avoid
being killed during yocto builds.

Previously these customizations would have to be made manually on the
host OS without any history or reproducability.

These changes are also intentionally cleared on reboot, and reapplied
if this service still exists. The easiest way to recover the system is
to set an env var `DISABLE_ENGINE_DROPIN` to any value and reboot.
