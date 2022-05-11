#Set Current Script Directory
if($psISE){$script:ScriptDir = Split-Path -Path $psISE.CurrentFile.FullPath}
if((Get-Host).Version.Major -gt "5"){$script:ScriptDir = $PSScriptRoot}else{$script:ScriptDir = $PSScriptRoot}
if($env:TERM_PROGRAM -eq "vscode"){$script:ScriptDir = "C:\Users\marcel\Desktop\StarCitizen Tools\Projekt Jericho (3D Navigation)_V6"}
Set-Location $script:ScriptDir


#Load the location history
$CsvFilename =  (Get-ChildItem -Path "Logs" | Sort-Object LastAccessTime -Descending | Select-Object -First 1).FullName
$LogFilename = "Logs\Logfile.csv"

#PreRequests
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$FormOpen = $true
$counta = 1
while($FormOpen){
    Clear-Host
    Write-Host "Updating current map"
    Write-Host "close this window to stop"
    Write-Host "select map from taskbar and use WIN + SHIFT + ARROW LEFT/RIGHT TO MOVE MAP"
    ### START PLANET MAP ###
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
