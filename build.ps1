param (
    [string]$inp = $( Read-Host "Model name or path (leave empty to have a list of CrtVehicleTesting classes)" ),
    [switch]$fmu = $false,
    [switch]$donotnotify = $false
)


# functions
function prepareBuildEnv([string]$workfolder = $(Mandatory=$true)){
    Remove-Item -Path $workfolder -ErrorAction Ignore -Force -Recurse
    New-Item -Path $workfolder -ItemType Directory -Force | Out-Null
    $script:scriptfile = $workfolder+'build.mos';
    New-Item -Path $scriptfile -ItemType File | Out-Null
}

function loadModelicaFile([string]$scriptfile = $(Mandatory=$true), [string]$filename = $(Mandatory=$true)){
    Add-Content $scriptfile 'loadModel(Modelica);'
    Add-Content $scriptfile -value('loadFile("'+$filename+'");')
}

function loadAltairLibrary([string]$scriptfile = $(Mandatory=$true)){
    $CRTVEHDIR='../../..'
    Add-Content $scriptfile -value('loadFile("'+$CRTVEHDIR+'/CrtVehicle/package.mo");')
    Add-Content $scriptfile -value('loadFile("'+$CRTVEHDIR+'/CrtVehicleTesting/package.mo");')
}

function buildModelFMU([string]$modelname = $(Mandatory=$true), [string]$shortmodelname = $(Mandatory=$true)){
    Add-Content $scriptfile -value('res:=buildModelFMU('+$modelname+', version="2.0", fileNamePrefix="'+$shortmodelname+'", fmuType="cs", platforms={"static"}, includeResources=true);')
    Add-Content $scriptfile 'getErrorString();'
}

function buildModel([string]$modelname = $(Mandatory=$true), [string]$shortmodelname = $(Mandatory=$true)){
    Add-Content $scriptfile -value('res:=buildModel('+$modelname+', fileNamePrefix="'+$shortmodelname+'", startTime=0, stopTime=1, numberOfIntervals=1000, tolerance=1e-5, method="dassl", variableFilter=".*", cflags="", outputFormat="mat", simflags="-lv=LOG_STATS,LOG_SIMULATION");')
    Add-Content $scriptfile 'getErrorString();'
}

function getErrorOnReturn(){
    Add-Content $scriptfile 'fileexist:=regularFileExists(res[1]+".exe");'
    Add-Content $scriptfile 'exitval:= if fileexist then 0 else 1;'
    Add-Content $scriptfile 'exit(exitval);'
}

function runOpenModelicaScript([string]$workfolder = $(Mandatory=$true), [string]$shortmodelname = $(Mandatory=$true)){
    $stopWatch = [system.diagnostics.stopwatch]::StartNew();
    $OmcProcess = Start-Process -FilePath "$env:OPENMODELICAHOME\bin\omc.exe" -ArgumentList "-d=initialization,infoXmlOperations,graphml,visxml,aliasConflicts,stateselection,bltmatrixdump build.mos" -WorkingDirectory $workfolder -NoNewWindow -Wait -PassThru
    Write-Host "Elapsed time:" $stopWatch.Elapsed.TotalSeconds "s"
    return $OmcProcess.ExitCode
}

function runOpenModelicaScriptFMU([string]$workfolder = $(Mandatory=$true), [string]$shortmodelname = $(Mandatory=$true)){
    $stopWatch = [system.diagnostics.stopwatch]::StartNew();
    $OmcProcess = Start-Process -FilePath "$env:OPENMODELICAHOME\bin\omc.exe" -ArgumentList "-d=aliasConflicts build.mos" -WorkingDirectory $workfolder -PassThru -Wait -NoNewWindow
    Write-Host "Elapsed time:" $stopWatch.Elapsed.TotalSeconds "s"
    Remove-Item -Path $workfolder$shortmodelname -ErrorAction Ignore -Force -Recurse
    New-Item -Path $workfolder$shortmodelname -ItemType Directory -Force | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path $workfolder$shortmodelname'.fmu'), (Resolve-Path $workfolder$shortmodelname))
    Start-Process -FilePath "tools\fmuCheck.win64" -ArgumentList "-o nul -l 3 $shortmodelname.fmu" -WorkingDirectory $workfolder -Wait -NoNewWindow
    return $OmcProcess.ExitCode
}

# main script
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName PresentationFramework

# if $inp has been left empty, the user is asked to choose from the classes contained into CrtVehicleTesting
if([string]::IsNullOrEmpty($inp)){
    if ($donotnotify){
        Write-Host "Wrong input"
        exit 1
    }
    Write-Host "No input is provided; looking into CrtVehicleTesting classes..."
    # prepare the MOS file to get the classes names
    $parseFilename = 'parseLibrary.mos';
    New-Item -Path $parseFilename -ItemType File -Force | Out-Null
    $CRTVEHDIR='../'
    Add-Content $parseFilename -value('ok:=loadFile("'+$CRTVEHDIR+'CrtVehicle/package.mo");')
    Add-Content $parseFilename -value('ok:=loadFile("'+$CRTVEHDIR+'CrtVehicleTesting/package.mo");')
    Add-Content $parseFilename -value('getClassNames(class_=CrtVehicleTesting, recursive = true, sort = true)')
    Start-Process -FilePath "$env:OPENMODELICAHOME\bin\omc.exe" -ArgumentList "parseLibrary.mos" -RedirectStandardOutput "parsedLibrary.txt" -NoNewWindow -Wait

    # extract classes names
    $parsedLib = Get-Content -Path parsedLibrary.txt
    $namePattern = [Regex]::new('[\w\.^]+')
    $matches = $namePattern.Matches($parsedLib)

    Remove-Item "parsedLibrary.txt"
    Remove-Item $parseFilename

    # print the hashtable index and the corresponding class name
    for ($cn = 0; $cn -lt $matches.count; $cn++) {
        Write-Host $cn ':' $matches[$cn].Value
    }

    # catch the user input and tries to get the corresponding class name
    $choice = Read-Host "Choose class to build"
    try{
        $inp = $matches[[int]$choice].Value
        Write-Host "Chosen class is" $matches[[int]$choice].Value
    }
    catch{
        Write-Host "Wrong input"
        exit 1
    }
}


$inp = $inp -replace '\\', '/'
if(Test-Path $inp){ # build without including CrtVehicle
    $modelname_found = $inp -match "(\w+)\.mo$"
    if(!$modelname_found){
        Write-Host "Cannot infer model name"
        exit 2
    }
    $filename = $inp;
    $modelname = $matches[1]
    $shortmodelname = $modelname
    if($fmu){ #noAltair FMU
        Write-Host "Building noAltair FMU"
        $workfolder = "_fmu_temp\$shortmodelname\"
        prepareBuildEnv -workfolder $workfolder
        loadModelicaFile -scriptfile $scriptfile -filename $filename
        buildModelFMU -modelname $modelname -shortmodelname $shortmodelname
        getErrorOnReturn
        $omcerrorflag = runOpenModelicaScriptFMU -workfolder $workfolder -shortmodelname $shortmodelname
    }else{ #noAltair compile
        Write-Host "Building noAltair executable"
        $workfolder = "_build_temp\$shortmodelname\"
        prepareBuildEnv -workfolder $workfolder
        loadModelicaFile -scriptfile $scriptfile -filename $filename
        buildModel -modelname $modelname -shortmodelname $shortmodelname
        getErrorOnReturn
        $omcerrorflag = runOpenModelicaScript -workfolder $workfolder -shortmodelname $shortmodelname
    }
} else {
    $script:CrtVehicle_found = $inp -match "CrtVehicle"
    if ($CrtVehicle_found) {
        $modelname = $inp
        $shortmodelname_found = $modelname -match "\.(\w+)$"
        if($shortmodelname_found){
            $shortmodelname = $matches[1]
            if($fmu){ #Altair FMU
                Write-Host "Building Altair FMU"
                $workfolder = "_fmu_temp\$shortmodelname\"
                prepareBuildEnv -workfolder $workfolder
                loadAltairLibrary -scriptfile $scriptfile
                buildModelFMU -modelname $modelname -shortmodelname $shortmodelname
                $omcerrorflag = runOpenModelicaScriptFMU -workfolder $workfolder -shortmodelname $shortmodelname
            }else{ #Altair compile
                Write-Host "Building Altair executable"
                $workfolder = "_build_temp\$shortmodelname\"
                prepareBuildEnv -workfolder $workfolder
                loadAltairLibrary -scriptfile $scriptfile
                buildModel -modelname $modelname -shortmodelname $shortmodelname
                $omcerrorflag = runOpenModelicaScript -workfolder $workfolder -shortmodelname $shortmodelname
            }
        }
        else { # if no model has been found
            Write-Host "Bad -inp argument"
            exit 1
        }
    }
}

if(!$donotnotify){
    [System.Windows.MessageBox]::Show("Build of $shortmodelname complete", 'Build Status')
}

exit $omcerrorflag

