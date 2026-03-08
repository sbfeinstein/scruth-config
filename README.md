# scruth-config
`scruth-config` is a scripted framework that manages the configuration of **_ScruthSystems_** ™️

🚀 Its mission is to make it a delight to set up and maintain our family computers 😎!

***Scruth*** == <u>Sc</u>ott + <u>Ruth</u>

Windows and MacOS systems are supported and in both cases only a single, zero-parameter command is needed to run it.

Overview:
1. The script only relies on commands that are available out-of-the-box and so is runnable on fresh operating system installs or newly purchased computers.
2. It is built around the [chezmoi](https://www.chezmoi.io/) framework with [1password CLI](https://developer.1password.com/docs/cli/) for secrets management.
3. The script installs minimal dependencies so that chezmoi (with 1password support) can execute.
4. chezmoi is used to render configuration files as well as execute commands to configure and customize the system.
5. The chezmoi configuration detects the host operating system, host/computer name and other environment information in order to determine what customizations to make.
6. A public GitHub repo is used so that the repo may be cloned without authentication and using HTTPS; no secrets are published in the repo!

# Quick Start - MacOS
The `setup.sh` script is the entry point!  In a shell, execute:

```sh
curl -sfL https://raw.githubusercontent.com/sbfeinstein/scruth-config/refs/heads/main/setup.sh | bash
```

The script installs minimal dependencies including [homebrew](https://brew.sh/) for package management. 

# Quick Start - Windows
The `setup.ps1` script is the entry point!  In a Windows Terminal, execute:

```powershell
Invoke-Expression "& { $(Invoke-RestMethod https://raw.githubusercontent.com/sbfeinstein/scruth-config/refs/heads/main/setup.ps1) }"
```

⚠️ **WARNING**:
The legacy Windows "console", Command Prompt, Windows PowerShell and Windows PowerShell ISE are **not** ideal for this purpose.  
They have quirks related to Unicode character handling and chains of command calls.  
It is likely that the emojis output by `scruth-config` will not render correctly though functionality isn't affected.


For Windows systems, the scripts rely on the built-in [WinGet](https://learn.microsoft.com/en-us/windows/package-manager/winget/) for package management.
