"""Mirror of release info

TODO: generate this file from GitHub API"""

LATEST_TOOL_VERSION = "0.3.3"

# The integrity hashes can be computed with
# shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64
TOOL_VERSIONS = {
    "0.3.3": {
        "windows_x64": "",
    },
}
