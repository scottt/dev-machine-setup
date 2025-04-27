# Toolbox

Run `toolbox create -d fedora -r 41`.  On Bazzite 41, `toolbox create` defaults to fedora 40.

# VS Code

* Install vscode by layering it on top of Bazzite (Fedora Atomic)
* Use the "Dev Containers" extension (ms-vscode-remote.remote-containers) and change Dev > Containers: Docker Path to `podman`
* This simplified from
  * https://hackandslash.blog/how-to-run-vs-code-flatpak-with-a-toolbox-with-code-completion/
  * https://github.com/daw1012345/vscode-for-toolbox?tab=readme-ov-file
