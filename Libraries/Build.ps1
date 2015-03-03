﻿Push-Location $PSScriptRoot
. .\Libraries\Settings.ps1

ForEach ($p in $client_projects) {
    ForEach ($b in $client_build_configurations) {
        $isPclClient = ($($p.Name) -eq "Exceptionless") -or ($($p.Name) -eq "Exceptionless.Signed")
        If (($isPclClient -and ($($b.NuGetDir) -ne "portable-net40+sl50+win+wpa81+wp80")) -or (!$isPclClient -and ($($b.NuGetDir) -eq "portable-net40+sl50+win+wpa81+wp80"))) {
            Continue;
        }

        $outputDirectory = "$build_dir\$configuration\$($p.Name)\lib\$($b.NuGetDir)"

        Write-Host "Building $($p.Name) ($($b.TargetFrameworkVersionProperty))" 

        If ($($p.Name).EndsWith(".Signed")) {
            $name = $($p.Name).Replace(".Signed", "");
            exec { & msbuild "$($p.SourceDir)\$name.csproj" `
                        /p:SignAssembly=true `
                        /p:AssemblyOriginatorKeyFile="$sign_file" `
                        /p:Configuration="$configuration" `
                        /p:Platform="AnyCPU" `
                        /p:DefineConstants="`"TRACE;SIGNED;$($b.Constants)`"" `
                        /p:OutputPath="$outputDirectory" `
                        /p:TargetFrameworkVersionProperty="$($b.TargetFrameworkVersionProperty)" `
                        /t:"Rebuild" }
        } else {
            exec { & msbuild "$($p.SourceDir)\$($p.Name).csproj" `
                        /p:SignAssembly=false `
                        /p:Configuration="$configuration" `
                        /p:Platform="AnyCPU" `
                        /p:DefineConstants="`"TRACE;$($b.Constants)`"" `
                        /p:OutputPath="$outputDirectory" `
                        /p:TargetFrameworkVersionProperty="$($b.TargetFrameworkVersionProperty)" `
                        /t:"Rebuild" }
        }

        Write-Host "Finished building $($p.Name) ($($b.TargetFrameworkVersionProperty))"
    }
}

Write-Host "Building Client Tests" 

exec { & msbuild "$source_dir\Exceptionless.Tests.csproj" /p:Configuration="$configuration" /t:"Rebuild" }

Write-Host "Finished building Client Tests"

Pop-Location