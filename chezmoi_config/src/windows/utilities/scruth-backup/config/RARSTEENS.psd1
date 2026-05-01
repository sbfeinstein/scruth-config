@{
    destination_root_path = "\\Rarsteens\e-backup\backups"
    mac_address = "FC:B0:DE:38:5E:CF"

    # Overrides of defaults go here
    name = 'RARSTEENS'
    backup_tasks = @(
        @{SourceDrive = 'C'; FilterFile = 'C-source-filter.txt' }
        @{SourceDrive = 'D'; FilterFile = 'D-source-filter.txt' }
    )
}
