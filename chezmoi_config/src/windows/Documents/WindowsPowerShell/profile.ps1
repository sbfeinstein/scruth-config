# Common functionality across all versions of PowerShell

# Remove collisions with existing PowerShell aliases that I don't want to deal with
Remove-Item Alias:gc -Force
Remove-Item Alias:gp -Force

# Aliases
function chez { chezmoi apply }

function gaa { git add --all @args }
function gst { git status @args }
function gb  { git branch @args }
function gba { git branch -a @args }
function gbd { git branch -d @args }
function gbD { git branch -D @args }
function gc  { git commit -v @args }
function gcb { git checkout -b @args }
function gco { git checkout @args }
function gfa { git fetch --all --prune @args }
function glog { git log --oneline --decorate --graph @args }
function gp  { git push @args }
function gpr { git pull --rebase @args }
function grb  { git rebase @args }
function grba { git rebase --abort @args }
function grbc { git rebase --continue @args }
function grbi { git rebase -i @args }
function groh {
    git reset origin/$(git_current_branch) --hard @args
}

function st  { subl @args }

# Alias helpers
function git_current_branch {
    git rev-parse --abbrev-ref HEAD
}

# Utilities
function Get-MakeMKVBetaKey {
    $url = "https://forum.makemkv.com/forum/viewtopic.php?f=5&t=1053"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing
    if ($response.Content -match '<code>(.*?)</code>') {
        Write-Output $Matches[1].Trim()
    }
}