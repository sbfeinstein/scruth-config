1. Capture machine-specific manual instructions into other docs in this same directory; 
basically as a reminder for the future in case they need to be done manually again or as things to look into automating eventually.
2. Implement `chezmoi_config/src/windows/.chezmoiscripts/2_run_onchange/run_onchange_after_350_wake_on_LAN.ps1.tmpl`
   - Disable Fast Startup
   - Some other windows change I'm forgetting
   - Point out BIOS may need to checked to allow wake from LAN
3. Mac: automate enabling SMB so that windows boxes can access
   - System Preferences > File Sharing > "i" icon > "Options…" > SMB enabled and Scott Feinstein account checked
4. Mac: automate `setopt hash_list_all` since this fixed python3 discovery after path was changed from `uv install`
5. Windows: script creation of folder with shortcuts to all other ScruthSystems computers
6. Mac: similar scripted creation of something to access the Windows machines 
7. Windows:  a "send to plex other videos" context menu option that creates a hardlink to a sharedfolder that plex would map to over the network?