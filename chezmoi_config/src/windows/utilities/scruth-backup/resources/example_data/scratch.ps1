$Table = @(
    [PSCustomObject] @{
        Name         = 'Process1'
        BasePriority = 1
        Company      = 'Company1'
        CompanyName  = 'Company Name 1', "Teest"
    }
    [PSCustomObject] @{
        Name         = 'Process1'
        BasePriority = 1
        Company      = 'Company1'
        CompanyName  = @('Company Name 1', "Teest")
    }
    [PSCustomObject] @{
        Name         = 'Process1'
        BasePriority = 1
        Company      = 'Company1'
        CompanyName  = "Teest"
    }
)

$Output = EmailBody -FontSize 15px -FontFamily 'Tahoma' {
    EmailTableOption -PrettifyObject -PrettifyObjectSeparator "::"
    EmailText -Text 'This should be font 8pt, table should also be font 8pt'
    EmailTable -Table $Table -HideFooter # this will use PrettifyObject from above

    EmailText -LineBreak

    EmailTable -DataTable {
        # Define the header column
        EmailTableHeader -Items 'Header 1', 'Header 2', 'Header 3'
        
        # Add rows to the table
        EmailTableRow -Items 'Row 1', 'Data 1', 'Data 2'
        EmailTableRow -Items 'Row 2', 'Data 3', 'Data 4'
        EmailTableRow -Items 'Row 3', 'Data 5', 'Data 6'
    }

    EmailText -LineBreak

    EmailTextBox -FontFamily 'Calibri' -Size 17 -TextDecoration underline -Color DarkSalmon -Alignment center {
        'Demonstration'
    }
    EmailText -LineBreak
}

Save-HTML -ShowHTML -HTML $Output