"""Expose the Codex primary runtime paths to local CLI skills."""
import json
from pathlib import Path

from mcp.server.fastmcp import FastMCP

server = FastMCP("workspace-runtime")


@server.tool()
def load_workspace_dependencies() -> str:
    """Locate installed workspace runtime executables and libraries for artifact skills."""
    root = (Path.home() / ".local/share/codex-cli-runtime/current").resolve(strict=True)
    version = json.loads((root / "runtime.json").read_text())["bundleVersion"]
    deps = root / "dependencies"
    locations = {
        "Node.js executable (RUNTIME_NODE)": "node/bin/node",
        "Node.js packages (RUNTIME_NODE_MODULES)": "node/node_modules",
        "Override binaries (RUNTIME_BIN_DIR)": "bin/override",
        "LibreOffice": "bin/override/soffice",
        "PDF renderer": "bin/override/pdftoppm",
        "Fallback binaries": "bin/fallback",
        "Python executable": "python/bin/python3",
        "Python libraries": "python",
        "Git executable": "bin/fallback/git",
    }
    lines = [f"Bundle version: {version}"]
    for label, relative in locations.items():
        path = deps / relative
        if path.exists():
            lines.append(f"{label}: {path}")
    return "\n".join(lines)


if __name__ == "__main__":
    server.run()
