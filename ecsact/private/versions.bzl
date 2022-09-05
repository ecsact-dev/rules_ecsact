"""Mirror of release info

TODO: generate this file from GitHub API"""

LATEST_TOOL_VERSION = "0.3.2"

# The integrity hashes can be computed with
# shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64
TOOL_VERSIONS = {
    "0.3.2": {
        # "x86_64-apple-darwin": "",
        # "aarch64-apple-darwin": "",
        "x86_64-pc-windows-msvc": "sha384-35YN6TKpT0L9qyRBmq48NucvyXEtHnkeC+txf2YZmmJTmOzrAKREA74BA0EZvpar",
        # "x86_64-unknown-linux-gnu": "",
    },
}
