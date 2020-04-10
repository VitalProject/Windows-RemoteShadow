$baseDir = Split-Path $myinvocation.mycommand.path -Parent
#https://github.com/Mentaleak/Show-LoadingScreen
import-module (Join-Path -Path $baseDir -ChildPath "Show-LoadingScreen.ps1")

function get-ADSIComputers(){
param(
$LastlogonDays
)
    if($LastlogonDays){
        $minLogonTime = $(((Get-Date).AddDays(-$LastlogonDays)).ToFileTime())
        $filter="(&(objectCategory=computer)(lastlogontimestamp>=$($minLogonTime)))"
    }
    else
    {
    $filter="(objectCategory=computer)"
    }
        $ls=show-LoadingScreen -note "AD Computers"
            $forest=(Get-WmiObject win32_ComputerSystem).domain.split(".")

            $domain = New-Object DirectoryServices.DirectoryEntry("LDAP://DC=$($forest[0]),DC=$($forest[1])")
            $searchRoot = New-Object System.DirectoryServices.DirectoryEntry
            $adSearcher = New-Object System.DirectoryServices.DirectorySearcher
            $adSearcher.PageSize=100000
            $adSearcher.SearchRoot = $domain
            $adSearcher.Filter = $filter
            $adSearcher.PropertiesToLoad.Add("cn") |Out-Null
            $adSearcher.PropertiesToLoad.Add("distinguishedname") |Out-Null
            $adSearcher.PropertiesToLoad.Add("dnshostname") |Out-Null

            $results=@()
            $cnResult = $adSearcher.FindAll()
            $ls.updateNote("Gathering OU")
                $cnResult |foreach{
                    $OrgData=$_.Properties.distinguishedname.Split(',=') | Where-Object {$_ -ne "CN" -and $_ -ne "OU" -and  $_ -ne "DC"}
                    $comp=new-object psobject -Property $_.Properties
                    $comp |Add-Member -MemberType NoteProperty -Name OU -Value $OrgData[($OrgData.length-3)]
                    $results+=$comp
                }
        $ls.close()
    return $results
    }
   
function get-RemoteComputer(){
param(
[Parameter(Mandatory=$true)]$computers
)
    #uses  https://www.compart.com/en/unicode/U+2800 to expand the label field
    $computer = $computers|select `
    @{Label= "HostName                 ⠀";Expression={ $_.cn} },
    @{Label= "OU                                         ⠀";Expression={ $_.OU} },
    @{Label= "FQDN                                                         ⠀";Expression={ $_.dnshostname} } `
    |Out-GridView -OutputMode Single -Title "Select Machine"|select `
    @{Label= "HostName";Expression={ $_."HostName                 ⠀"} },
    @{Label= "OU";Expression={ $_."OU                                         ⠀"} },
    @{Label= "FQDN";Expression={ $_."FQDN                                                         ⠀"} }

    return $computer
}

function get-RDPSession(){
    prarm(
    [Parameter(Mandatory=$true)]$fqdn
    )
    $ls=show-LoadingScreen -note "Sessions"
    $sessions= Invoke-Command -ComputerName $fqdn -ScriptBlock { query session console } -credential $cred
    $sessions=$sessions[1..$sessions.Length]
    $sesionParse=@()
    $sessions|foreach{
    $ssp=$sessions.Split(" ")|where {$_ -ne ""}
        if($ssp.count -ge 4){
            $sesionParse+=[pscustomobject]@{
            SessionName=$ssp[0]
            Username=$ssp[1]
            ID=$ssp[2]
            State=$ssp[3]
            }
        }
}
$ls.close()
$session=$sesionParse|Out-GridView -OutputMode Single

}

function connect-rdpSession(){
    param(
    [Parameter(Mandatory=$true)]$fqdn,
    $sessionID=1,
    [switch]$control,
    [switch]$noConsent
    )
    $command="/prompt /V:$($fqdn) /shadow:$($sessionID)"
    if($control){
    $command+=" /control /admin"
    }

    if($noConsent){
    $command+=" /noConsentPrompt"
    }


    Start-Process -FilePath mstsc -ArgumentList "$command"

}


$script:computers=$null
Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$form                            = New-Object system.Windows.Forms.Form
$form.ClientSize                 = '350,90'
$form.text                       = "RDP Shadow"
$form.BackColor                  = "#4a4a4a"
#$form.TopMost                    = $true
$iconBase64      = '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'
$iconBytes       = [Convert]::FromBase64String($iconBase64)
$stream          = New-Object IO.MemoryStream($iconBytes, 0, $iconBytes.Length)
$stream.Write($iconBytes, 0, $iconBytes.Length);
$iconImage       = [System.Drawing.Image]::FromStream($stream, $true)
$form.Icon       = [System.Drawing.Icon]::FromHandle((New-Object System.Drawing.Bitmap -Argument $stream).GetHIcon())


$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Enter Machine Name"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(5,10)
$Label1.Font                     = 'Microsoft Sans Serif,10'
$Label1.ForeColor                = "#ffffff"

$HostInput                       = New-Object system.Windows.Forms.TextBox
$HostInput.multiline             = $false
$HostInput.width                 = 250
$HostInput.height                = 20
$HostInput.location              = New-Object System.Drawing.Point(5,35)
$HostInput.Font                  = 'Microsoft Sans Serif,10'

$BtnBrowse                       = New-Object system.Windows.Forms.Button
$BtnBrowse.text                  = "Browse"
$BtnBrowse.width                 = 65
$BtnBrowse.height                = 30
$BtnBrowse.location              = New-Object System.Drawing.Point(275,10)
$BtnBrowse.Font                  = 'Microsoft Sans Serif,10'
$BtnBrowse.ForeColor             = "#ffffff"

$BtnConnect                       = New-Object system.Windows.Forms.Button
$BtnConnect.text                  = "Connect"
$BtnConnect.width                 = 65
$BtnConnect.height                = 30
$BtnConnect.location              = New-Object System.Drawing.Point(275,50)
$BtnConnect.Font                  = 'Microsoft Sans Serif,10'
$BtnConnect.ForeColor             = "#ffffff"


$CheckBoxControl                 = New-Object system.Windows.Forms.CheckBox
$CheckBoxControl.text            = "Control"
$CheckBoxControl.AutoSize        = $false
$CheckBoxControl.width           = 71
$CheckBoxControl.height          = 20
$CheckBoxControl.location        = New-Object System.Drawing.Point(13,64)
$CheckBoxControl.Font            = 'Microsoft Sans Serif,10'
$CheckBoxControl.ForeColor       = "#ffffff"
$CheckBoxControl.Checked         = $true

$CheckBoxnoConsent               = New-Object system.Windows.Forms.CheckBox
$CheckBoxnoConsent.text          = "No Consent"
$CheckBoxnoConsent.AutoSize      = $false
$CheckBoxnoConsent.width         = 120
$CheckBoxnoConsent.height        = 20
$CheckBoxnoConsent.location      = New-Object System.Drawing.Point(93,64)
$CheckBoxnoConsent.Font          = 'Microsoft Sans Serif,10'
$CheckBoxnoConsent.ForeColor     = "#ffffff"
$CheckBoxnoConsent.Checked         = $true

$form.controls.AddRange(@($Label1,$HostInput,$BtnBrowse,$BtnConnect, $CheckBoxControl,$CheckBoxnoConsent))


$BtnBrowse.Add_Click(
        {    
            if(!$script:computers){
                $script:computers=get-ADSIComputers
            }
                $computer=get-RemoteComputer -computers $computers
                $HostInput.text=$computer.fqdn
        }
    )

$BtnConnect.Add_Click(
        {    
            if($HostInput.Text){
                        $computername=$HostInput.Text

                if($CheckBoxControl.Checked -and $CheckBoxnoConsent.Checked){
                    connect-rdpSession -fqdn $computername -sessionID 1 -control -noConsent
                    }elseif($CheckBoxControl.Checked){
                    connect-rdpSession -fqdn $computername -sessionID 1 -control
                    }
                    elseif($CheckBoxnoConsent.Checked){
                    connect-rdpSession -fqdn $computername -sessionID 1 -noConsent
                    }
                    else{
                    connect-rdpSession -fqdn $computername -sessionID 1
                    }
                                            $form.Dispose()
            }else{
                [System.Windows.Forms.MessageBox]::Show("No machine Selected." , "ERROR")
                }
        }
    )

$form.BringToFront()
$form.ShowDialog()
$form.BringToFront()
