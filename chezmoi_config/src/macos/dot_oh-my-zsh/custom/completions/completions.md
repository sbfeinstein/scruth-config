# Overview
This directory (~/.oh-my-zsh) is managed by scruth-config.

It contains configuration and other artifacts referenced by omz/zsh,
as well as some customizations explicitly managed in scruth-config.

Any changes required should happen via scruth-config and not manually / adhoc, 
or else they may be lost or overwritten.

# Dynamic completions
Oftentimes tools will provide a way to dynamically generate completions.
In many cases an oh-my-zsh plugin exists for the tool and may be added to the list in
`dot_ohmyzshell.tmpl`.
That is the preferred approach.

However, if a tool provides a generated completions file, e.g. that calls `compdef`,
it can simply be placed in this directory (via scruth-config) and it will be used.

You'll need to restart the shell for it to take effect.

You can also consider creating a custom oh-my-zsh plugin to accomplish the same thing.
