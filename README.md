# scruth-config
Config, dotfiles and other customizations for Feinstein family computers.

***Scruth*** == **Sc**ott + **Ruth**

# Quick Start
The `setup.sh` script manages the installation and configuration of our systems from "scratch"; no other software must be manually installed before running `scruth-config`.  This makes it a delight to set up new machines or reset / restore existing ones.  

At this time, only Mac computers are supported and a "developer" configuration is assumed.  The system is designed to be flexible and may be extended to our Windows (and non-developer) machines in the future.

Download and execute the script in one step!

```sh
curl -sfL https://raw.githubusercontent.com/sbfeinstein/scruth-config/refs/heads/chezmoi-initial/setup.sh | bash
```

# How it works
The script bootstraps everything it needs, with the key components being:
* [homebrew](https://brew.sh/) for package management
* [chezmoi](https://www.chezmoi.io/) for managing configuration such as dotfiles
* [1password CLI](https://developer.1password.com/docs/cli/) for secrets, including as a secrets source for chezmoi

