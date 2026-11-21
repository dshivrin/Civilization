# Non-QA terminal failures

- Initial `git switch -c economy-first-era-integration-review` failed to create the Git metadata lock outside the workspace sandbox. Authorized retry succeeded; no earlier checkout changed.
- Initial sandbox `xcrun simctl list devices available` failed with CoreSimulator connection and log permission errors. Authorized inventory succeeded. No reset or new runtime/tool was installed.
- A read-only `ps` check was sandbox-denied. It was not needed to verify test results; runner reports and logs are the evidence.
- Initial external completion install found the original iPad destination Shutdown; preflight also returned Shutdown, so no claim of confirmed absence is based on that attempt. Install failed before directory/fixture creation. Corrected booted retry required the specific No such file or directory absent-identity result before installation and checked that Civilization did not exist before copying.

- A preparatory phone `simctl boot` returned Already Booted. No reset, shutdown or progress mutation was attempted. Subsequent native results determine success.

- Initial phone capture archive attempted to read the export manifest while `xcresulttool` was still running; it failed before copying any phone PNG. After waiting for export completion, all15selected phone frames copied successfully. No native test failed.
