#Set Current Script Directory
if($psISE){$script:ScriptDir = Split-Path -Path $psISE.CurrentFile.FullPath}
if((Get-Host).Version.Major -gt "5"){$script:ScriptDir = $PSScriptRoot}else{$script:ScriptDir = $PSScriptRoot}
if($env:TERM_PROGRAM -eq "vscode"){$script:ScriptDir = "C:\Users\marcel\Desktop\StarCitizen Tools\Projekt Jericho (3D Navigation)_V6"}
if($env:TERM_PROGRAM -eq "vscode"){$script:ScriptDir = "C:\Users\marcel\Desktop\StarCitizen Tools\Project The Verse Mapper"}
Set-Location $script:ScriptDir


#Load the location history
$CsvFilename =  (Get-ChildItem -Path "Logs" | Sort-Object LastAccessTime -Descending | Select-Object -First 1).FullName
$LogFilename = "Logs\Logfile.csv"

#DEFINE CURRENT PLANET ONCE
$Table = Import-Csv -Path $LogFilename
$TablePlanetData  = $Table | Select-Object Planetname, Latitude, Longitude, "Date (Epoch)" | Where-Object {$_.Planetname -notcontains "none" -AND $_.Planetname -notcontains "Planetname"} | Sort-Object "Date (Epoch)"
$CurrentPlanet = $TablePlanetData.Planetname | Select-Object -First 1
$CurrentSystem = "Stanton"
$CurrentLocal = "porttraessler"
$script:i = 0


#######################################################
### START OF WINDOW SETTINGS, BUILDING GUI AND MORE ###
#######################################################

#PreRequests
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles() | out-null

#DEFINE WINDOW SETTINGS
$Form = New-Object system.Windows.Forms.Form -Property @{
    MaximizeBox = $true                                             #SHOW BUTTON MAXIMIZE
    MinimizeBox = $true                                             #SHOW BUTTON MINIMIZE
    StartPosition = "Manual"                                        #MANUAL POSITIONING
    Location= New-Object System.Drawing.Size(-1910,10)              #POSITION
    Name = "Live Mapping"                                           #FORM TITLE
    Size= New-Object System.Drawing.Size(1400,900)                  #WINDOWS SIZE
    #WindowState = "normal"                                          #window mode
    WindowState = "maximized"                                       #FIT TO SCREEN
    #Visible = $true                                                #SHOW FORM WHILE BUILDING CONTENTS, MIGHT BUG DRAW FUNCTION
    Enabled = $true
    #backcolor = [System.Drawing.Color]::FromArgb(255,240,240,240)
    Icon = "$script:ScriptDir\data\Icon-Project-Jericho.ico"
    Text = " The Verse Mapper"                                       #TITEL
}  

#CHECK SCREEN SIZES
$ScreenResolution = [System.Windows.Forms.Screen]::AllScreens | Where-Object {$_.DeviceName -like "*DISPLAY2"}  #GET MAX SCREEN RESOLUTION
$MaxFormSizeWidth = $ScreenResolution[0].WorkingArea.Width         #GET MAX WIDTH FROM PRIMARY SCREEN
$MaxFormSizeHeight = $ScreenResolution[0].WorkingArea.Height       #GET MAX HEIGHT FROM PRIMARY SCREEN
#IF FORM EXCEEDS SCREEN SIZE, GIVE A wARNING ON CONSOLE
if ($Form.Size.Width -gt $MaxFormSizeWidth -OR $Form.Size.Height -gt $MaxFormSizeHeight){
    Write-Warning "Current window will exceed screen limits $($MaxFormSizeWidth):$($MaxFormSizeHeight) Windows $($Form.Size.Width):$($Form.Size.Height)"
}

#DEFINE STATUS BAR AT BOTTOM OF THE WINDOW
$Progress = [System.Windows.Forms.ToolStripLabel]::new()
$Progress.Name = 'Progress'
#$Progress.Text = $null
#$Progress.Text = "$script:i                                                                                              "
$Progress.Text = "Count $script:i"
$Progress.Width = 250
$Progress.Visible = $true

$ProgressBar = [System.Windows.Forms.ToolStripProgressBar]::new()
$ProgressBar.Name = 'ProgressBar'
$ProgressBar.Width = 250
$ProgressBar.Visible = $false

$SupportInfo = [System.Windows.Forms.ToolStripLabel]::new()
$SupportInfo.Name = 'Left Panel'
$SupportInfo.Text = 'The Verse Mapper V1.0.3, Support & Updates @'
$SupportInfo.Width = 400
$SupportInfo.Visible = $true

$SupportLink = [System.Windows.Forms.ToolStripLabel]::new()
$SupportLink.Name = 'CentrePanel'
$SupportLink.IsLink = $true
#$SupportLink.LinkBehavior = System.Windows.Forms.LinkBehavior.AlwaysUnderline
$SupportLink.Text = "Meridian Discord"
$SupportLink.Tag = "https://discord.gg/WMh5YCeQVS"
$SupportLink.Width = 50
$SupportLink.Visible = $true
$SupportLink.add_Click({Invoke-Expression "explorer.exe $($SupportLink.Text)"})

$StatusStrip = New-Object System.Windows.Forms.StatusStrip
$StatusStrip.Name = 'StatusStrip'
#$StatusStrip.AutoSize = $true
$StatusStrip.AutoSize = $false
$StatusStrip.Left = 0
#$StatusStrip.Visible = $true
$StatusStrip.Enabled = $true
$StatusStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom
$StatusStrip.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
#$StatusStrip.LayoutStyle = [System.Windows.Forms.ToolStripLayoutStyle]::Table
$StatusStrip.LayoutStyle = [System.Windows.Forms.ToolStripLayoutStyle]::HorizontalStackWithOverflow
#$StatusStrip.BorderSides = "Left"
#$StatusStrip.BorderStyle = "Etched"
#DEFINE COPYRIGHT INFO
$Copyright = [System.Windows.Forms.ToolStripLabel]::new()
$Copyright.Name = 'Copyright, Right Panel'
$Copyright.Text = "© Graupunkt, Meridian"
$Copyright.Width = 200
$Copyright.Visible = $true

#ADD STATUS BAR TO MAIN FORM
$StatusStrip.Items.AddRange(
    [System.Windows.Forms.ToolStripItem[]]@(
        $SupportInfo,
        $SupportLink,
        $Progress,
        $ProgressBar,
        $Copyright
    )
)

$Form.Controls.Add($StatusStrip) 



#Create Tabs
$TabControl = New-object System.Windows.Forms.TabControl
$TabSystem  = New-Object System.Windows.Forms.TabPage
$TabPlanet  = New-Object System.Windows.Forms.TabPage
$TabLocal   = New-Object System.Windows.Forms.TabPage

#Tab Settings
$tabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 70
$tabControl.Location = $System_Drawing_Point
$tabControl.Name = "tabControl"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = $Form.Height #- $FormExtraHeightTabs
$System_Drawing_Size.Width  = $Form.Width
$tabControl.Size = $System_Drawing_Size
$Form.Controls.Add($tabControl)

#TAB SYSTEM
$TabSystem.DataBindings.DefaultDataSourceUpdateMode = 0
#$TabSystem.UseVisualStyleBackColor = $True
$TabSystem.Name = "System"
$TabSystem.Text = "System"
#$TabSystem.AutoScroll = $True
#SET CORRECT HEIGHT AND WIDTH
$TabSystem.AutoScrollMinSize = New-Object System.Drawing.Size($Form.Size.Height,($Form.Size.Width-$tabControl.Size.Height))
$tabControl.Controls.Add($TabSystem)

#TAB PLANET
$TabPlanet.DataBindings.DefaultDataSourceUpdateMode = 0
$TabPlanet.UseVisualStyleBackColor = $True
$TabPlanet.Name = "Planet"
$TabPlanet.Text = "Planet"
$TabPlanet.AutoScroll = $false
#SET CORRECT HEIGHT AND WIDTH
$TabPlanet.AutoScrollMinSize = New-Object System.Drawing.Size($Form.Size.Height,($Form.Size.Width-$tabControl.Size.Height))
$tabControl.Controls.Add($TabPlanet)

#TAB LOCAL
$TabLocal.DataBindings.DefaultDataSourceUpdateMode = 0
$TabLocal.UseVisualStyleBackColor = $True
$TabLocal.Name = "Local"
$TabLocal.Text = "Local"
$TabLocal.AutoScroll = $True
#SET CORRECT HEIGHT AND WIDTH
$TabLocal.AutoScrollMinSize = New-Object System.Drawing.Size($Form.Height,$Form.Width)
$tabControl.Controls.Add($TabLocal)


#SET BACKGROUND IMAGE FOR PLANET
$PlanetImage = [system.drawing.image]::FromFile("$script:ScriptDir\maps\planets\$CurrentPlanet.jpg")
$TabPlanet.BackgroundImage = $PlanetImage
$TabPlanet.BackgroundImageLayout = "center"
#$formGraphicsPlanet = $TabPlanet.createGraphics()

#SET BACKGROUND IMAGE FOR LOCAL
$LocalImage = [system.drawing.image]::FromFile("$script:ScriptDir\maps\local\$CurrentLocal.jpg")
$TabLocal.BackgroundImage = $LocalImage
$TabLocal.BackgroundImageLayout = "center"
#$formGraphicsLocal = $TabLocal.createGraphics()


#CONTENT / PANEL FOR SYSTEM TAB
$SystemImage = [system.drawing.image]::FromFile("$script:ScriptDir\maps\systems\$CurrentSystem.jpg")
$SystemCanvas = New-Object System.Windows.Forms.Panel 
$SystemCanvas.Location = "1,1"
$SystemCanvas.Size = "$($SystemImage.Width),$($SystemImage.Height)"
$SystemCanvas.Size = "800,800"
$SystemCanvas.BorderStyle = "FixedSingle"
$SystemCanvas.BackgroundImageLayout = "center"
$TabSystem.Controls.Add($SystemCanvas)

#LINE SETTINGS FOR SYSTEM
$SystemLineSettings = new-object Drawing.Pen red
$SystemLineSettings.width = 5
#DRAW LINE ON SYSTEM
$SystemGraphics = $SystemCanvas.createGraphics()
$TabSystem.add_paint({$SystemGraphics.DrawLine($SystemLineSettings, 1, 1, 800, 800)})
$SystemCanvas.BackgroundImage = $SystemImage


$SystemBrushSettings = new-object Drawing.SolidBrush green


#Define what to change while updating ui
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$script:i = 0
$starttick={
    $script:i++
    #write-host $script:i
    $Progress.Text = "Count: $script:i"
    switch ($script:i){
        {$_ -gt 100}{$SystemLineSettings.Color = "black"}
        {$_ -gt 200}{$SystemLineSettings.Color = "red"}
        {$_ -gt 300}{$SystemLineSettings.Color = "green"}
    }
    $TabSystem.Invalidate()
    $TabSystem.add_paint({$SystemGraphics.DrawLine($SystemLineSettings, 10, 500, $script:i, $script:i)})

    #keep updating tab system
    $TabSystem.update()

    #updates the whole form
    $form.update()

    #causes flickering on each refresh, so dont use it !!!
    #$script:form.refresh()
}

#create timer
$timer = new-object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]"0:0:0.0010"
$timer.Add_Tick($starttick)
$timer.Start()

#Show Form to User, wiat until window is closed
$form.ShowDialog()| Out-Null

#Stop Timer
$timer.stop()
#remove from memory
$form.Dispose()

<#
$timer = New-Object System.Windows.Forms.Timer -Property @{Interval = 1000} #Forms.Timer doesn't support AutoReset property
$script:num=0 #scope must be at script level to increment in event handler 
$timer.start()
$timer.add_Tick({
    $script:num +=1
    write-host "test $script:num"
    $heading.text=$script:num
})


$heading = New-Object System.Windows.Forms.Label -Property @{
    Location = ("0,0")
}
$form.Controls.Add($heading)

$timer.stop() #This will keep running in the background unless you stop it











##########################################################

$form.add_Load($OnLoadForm_StateCorrection)
$form.ShowDialog()| Out-Null

Start-Sleep -s 2

$rs = [Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
$rs.Open()
$rs.SessionStateProxy.SetVariable("Form", $Form)
$data = [hashtable]::Synchronized(@{text=""})
$rs.SessionStateProxy.SetVariable("data", $data)
$p = $rs.CreatePipeline({ [void] $Form.ShowDialog()})
$p.Input.Close()
$p.InvokeAsync()

## Enter the rest of your script here while you want the form to display
Start-Sleep -s 2

$Form.close()

######################################################################################













$FormOpen = $true
$counta = 1
while($FormOpen){
    Clear-Host
    Write-Host "Updating current map"
    Write-Host "close this window to stop"
    Write-Host "select map from taskbar and use WIN + SHIFT + ARROW LEFT/RIGHT TO MOVE MAP"

    #Get-Content -Path $CsvFilename
    $Table = Import-Csv -Path $LogFilename
    $TablePlanetData  = $Table | Select-Object Planetname, Latitude, Longitude, "Date (Epoch)" | Where-Object {$_.Planetname -notcontains "none" -AND $_.Planetname -notcontains "Planetname"} | Sort-Object "Date (Epoch)"
    $CurrentPlanet = $TablePlanetData.Planetname | Select-Object -First 1
    $PlanetData  = $Table | Select-Object Planetname, Latitude, Longitude, "Date (Epoch)" | Where-Object {$_.Planetname -contains $CurrentPlanet} | Sort-Object "Date (Epoch)"
    $TableStantonData = $Table | Select-Object Systemname, "Global X (m)", "Global Y (m)", "Global Z (m)", "Date (Epoch)" | Where-Object {$_.Planetname -contains "none"} | Sort-Object "Date (Epoch)" -Descending

    foreach ($dataset in $PlanetData){
        $xValue = $MapCentreX + ([double]$dataset.Longitude * $LongPix)
        $yValue = $MapCentreY - ([double]$dataset.Latitude  * $LatPix)
        
        if($global:PrevXvalue -and $global:PrevYvalue){
            $form.add_paint({$formGraphics.DrawLine($LineSettings, $PrevXvalue, $PrevYvalue, $xValue, $yValue)}.GetNewClosure())  
            $HistorySettings = new-object Drawing.SolidBrush ("black")
            $Historysizedot = 7
            $form.add_paint({$formGraphics.FillEllipse($HistorySettings, $xValue-($Historysizedot/2), $yValue-($Historysizedot/2), $Historysizedot, $Historysizedot )}.GetNewClosure())
        }
        #Add a big dot on the current position
        if ($count -eq $TablePlanetData.Count){
            $Lastobject = $true
            #MAKRS THE CURRENT POSITION
            $PosSettings = new-object Drawing.SolidBrush ("red", "green")[$Lastobject]
            $Possizedot = 15
            $form.add_paint({$formGraphics.FillEllipse($PosSettings, $xValue-($Possizedot/2), $yValue-($Possizedot/2), $Possizedot, $Possizedot )})
            #MARKS AN UPDATE
            $DotSettings = new-object Drawing.SolidBrush ("black")
            $sizedot = 7

            $formGraphics = $form.createGraphics()
            $form.add_paint({$formGraphics.FillEllipse($DotSettings, $xValue-($sizedot/2), $yValue-($sizedot/2), $sizedot, $sizedot )}.GetNewClosure())
        }else{$Lastobject = $false}



        #give previous data for origin of the next line
        $PrevXvalue = $xValue 
        $PrevYvalue = $yValue 
        #write-host $count $global:PrevXvalue $global:PrevYvalue
        $count ++
        #Refresh map
        #start-sleep -Milliseconds 10
        

    }

    ## Enter the rest of your script here while you want the form to display
    Start-Sleep -s 2

}
$Form.close()



$FormOpen = $true
$counta = 1
while($FormOpen){
    Clear-Host
    Write-Host "Updating current map"
    Write-Host "close this window to stop"
    Write-Host "select map from taskbar and use WIN + SHIFT + ARROW LEFT/RIGHT TO MOVE MAP"

    #Get-Content -Path $CsvFilename
    $Table = Import-Csv -Path $LogFilename
    $TablePlanetData  = $Table | Select-Object Planetname, Latitude, Longitude, "Date (Epoch)" | Where-Object {$_.Planetname -notcontains "none" -AND $_.Planetname -notcontains "Planetname"} | Sort-Object "Date (Epoch)"
    $CurrentPlanet = $TablePlanetData.Planetname | Select-Object -First 1
    $PlanetData  = $Table | Select-Object Planetname, Latitude, Longitude, "Date (Epoch)" | Where-Object {$_.Planetname -contains $CurrentPlanet} | Sort-Object "Date (Epoch)"
    $TableStantonData = $Table | Select-Object Systemname, "Global X (m)", "Global Y (m)", "Global Z (m)", "Date (Epoch)" | Where-Object {$_.Planetname -contains "none"} | Sort-Object "Date (Epoch)" -Descending

    #IN CASE THE PLAYER CHANGES THE PLANET OR ON FIRST RUN
    if ($PreviousPlanet -ne $CurrentPlanet){
        if($form.ishandlecreated){$form.close()}
        #Load Current ;Map of Detected Planet
        $Image = [system.drawing.image]::FromFile("$script:ScriptDir\maps\$CurrentPlanet.jpg")

        #Create pen
        $LineSettings = new-object Drawing.Pen red
        $LineSettings.width = 2

        #Create Form
        $form = New-Object Windows.Forms.Form
        $form.Width = 1920
        $form.Height = 1080
        #$form.Width = $Image.Width
        #$form.Height = $Image.Height
        $form.BackgroundImage = $Image
        $form.BackgroundImageLayout = "center"
        $formGraphics = $form.createGraphics()
        
        #DEFINE THE MAPS BORDERS IN PXIELS
        $MarginLeft = 95
        $MarginTop = 56
        $MarginRight = 96 #1247
        $marginBottom = 186 #630

        #Convert Lat / Long into  pixels
        $MapXpixels = $Image.Width - $MarginLeft - $MarginRight
        $MapYpixels = $Image.Height - $MarginTop - $marginBottom
        $MapCentreX = ($MapXpixels/2) + $MarginLeft
        $MapCentreY = ($MapYpixels/2) + $MarginTop

        $LongPix = $MapXpixels/360
        $LatPix = $MapYpixels/180

        $form.show()
    }

    $count  = 1

    $PrevXvalue = ""
    $PrevYvalue = ""
    
    #PLOT ROUTE
    foreach ($dataset in $PlanetData){
        $xValue = $MapCentreX + ([double]$dataset.Longitude * $LongPix)
        $yValue = $MapCentreY - ([double]$dataset.Latitude  * $LatPix)
        
        if($global:PrevXvalue -and $global:PrevYvalue){
            $form.add_paint({$formGraphics.DrawLine($LineSettings, $PrevXvalue, $PrevYvalue, $xValue, $yValue)}.GetNewClosure())  
            $HistorySettings = new-object Drawing.SolidBrush ("black")
            $Historysizedot = 7
            $form.add_paint({$formGraphics.FillEllipse($HistorySettings, $xValue-($Historysizedot/2), $yValue-($Historysizedot/2), $Historysizedot, $Historysizedot )}.GetNewClosure())
        }
        #Add a big dot on the current position
        if ($count -eq $TablePlanetData.Count){
            $Lastobject = $true
            #MAKRS THE CURRENT POSITION
            $PosSettings = new-object Drawing.SolidBrush ("red", "green")[$Lastobject]
            $Possizedot = 15
            $form.add_paint({$formGraphics.FillEllipse($PosSettings, $xValue-($Possizedot/2), $yValue-($Possizedot/2), $Possizedot, $Possizedot )})
            #MARKS AN UPDATE
            $DotSettings = new-object Drawing.SolidBrush ("black")
            $sizedot = 7
            $form.add_paint({$formGraphics.FillEllipse($DotSettings, $xValue-($sizedot/2), $yValue-($sizedot/2), $sizedot, $sizedot )}.GetNewClosure())
        }else{$Lastobject = $false}



        #give previous data for origin of the next line
        $PrevXvalue = $xValue 
        $PrevYvalue = $yValue 
        #write-host $count $global:PrevXvalue $global:PrevYvalue
        $count ++
        #Refresh map
        #start-sleep -Milliseconds 10
        

    }
    $form.refresh()
    Start-Sleep -Seconds 5
    if($form.ishandlecreated){$FormOpen = $true}else{$FormOpen = $false}
    $counta ++
    $PreviousPlanet = $CurrentPlanet
    ### END PLANET MAP ###
}
$form.close()
Write-Host "Please restart tool since planet has changed"


#X First Spot, Y First Spot, X Second Sport, Y Second Spot
#debug functions
# show top left of the map
#$form.add_paint({$formGraphics.DrawLine($mypen, 1, 1, $MarginLeft, $MarginTop)})#

#show bottom right of the map
#$form.add_paint({$formGraphics.DrawLine($mypen, $Image.Width, $Image.Height, ($Image.Width - $MarginRight), ($Image.Height - $marginBottom))})

# show map centre or long, lat = 0,0
#$form.add_paint({$formGraphics.DrawLine($mypen, 1, 1, $MapCentreX, $MapCentreY)})

# show testspot
#$form.add_paint({$formGraphics.DrawLine($mypen, 1, 1, $xValue, $yValue)})

#$form.ShowDialog()
#>