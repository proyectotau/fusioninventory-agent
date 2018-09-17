'
'  ------------------------------------------------------------------------
'  fusioninventory-agent-deployment.vbs
'  Copyright (C) 2010-2017 by the FusionInventory Development Team.
'
'  http://www.fusioninventory.org/ http://forge.fusioninventory.org/
'  ------------------------------------------------------------------------
'
'  LICENSE
'
'  This file is part of FusionInventory project.
'
'  This file is free software; you can redistribute it and/or modify it
'  under the terms of the GNU General Public License as published by the
'  Free Software Foundation; either version 2 of the License, or (at your
'  option) any later version.
'
'
'  This file is distributed in the hope that it will be useful, but WITHOUT
'  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
'  FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
'  more details.
'
'  You should have received a copy of the GNU General Public License
'  along with this program; if not, write to the Free Software Foundation,
'  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA,
'  or see <http://www.gnu.org/licenses/>.
'
'  ------------------------------------------------------------------------
'
'  @package   FusionInventory Agent
'  @file      .\contrib\windows\fusioninventory-agent-deployment.vbs
'  @author(s) Benjamin Accary <meldrone@orange.fr>
'             Christophe Pujol <chpujol@gmail.com>
'             Marc Caissial <marc.caissial@zenitique.fr>
'             Tomas Abad <tabadgp@gmail.com>
'             Guillaume Bougard <gbougard@teclib.com>
'  @copyright Copyright (c) 2010-2017 FusionInventory Team
'  @license   GNU GPL version 2 or (at your option) any later version
'             http://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html
'  @link      http://www.fusioninventory.org/
'  @link      http://forge.fusioninventory.org/projects/fusioninventory-agent
'  @since     2012
'
'  ------------------------------------------------------------------------
'

'
'
' Purpose:
'     FusionInventory Agent Unatended Deployment.
'
'

Option Explicit
Dim Force, Verbose
Dim Setup, SetupArchitecture, SetupLocation, SetupOptions, SetupVersion

'
'
' USER SETTINGS
'
'

' SetupVersion
'    Setup version with the pattern <major>.<minor>.<release>[-<package>]
'
SetupVersion = "2.4"

' SetupLocation
'    Depending on your needs or your environment, you can use either a HTTP or
'    CIFS/SMB.
'
'    If you use HTTP, please, set to SetupLocation a URL:
'
'       SetupLocation = "http://host[:port]/[absolut_path]" or
'       SetupLocation = "https://host[:port]/[absolut_path]"
'
'    If you use CIFS, please, set to SetupLocation a UNC path name:
'
'       SetupLocation = "\\host\share\[path]"
'
'       You also must be sure that you have removed the "Open File Security Warning"
'       from programs accessed from that UNC.
'
' Location for Release Candidates
' SetupLocation = "https://github.com/TECLIB/fusioninventory-agent-windows-installer/releases/download/" & SetupVersion
SetupLocation = "https://github.com/fusioninventory/fusioninventory-agent/releases/download/" & SetupVersion


' SetupArchitecture
'    The setup architecture can be 'x86', 'x64' or 'Auto'
'
'    If you set SetupArchitecture = "Auto" be sure that both installers are in
'    the same SetupLocation.
'
SetupArchitecture = "Auto"

' SetupOptions
'    Consult the installer documentation to know its list of options.
'
'    You should use simple quotes (') to set between quotation marks those values
'    that require it; double quotes (") doesn't work with UNCs.
'
SetupOptions = "/acceptlicense /runnow /server='http://glpi.yourcompany.com/glpi/plugins/fusioninventory/' /S"

' Setup
'    The installer file name. You should not have to modify this variable ever.
'
Setup = "fusioninventory-agent_windows-" & SetupArchitecture & "_" & SetupVersion & ".exe"

' Force
'    Force the installation even whether Setup is previously installed.
'
Force = "No"

' Verbose
'    Enable or disable the information messages.
'
'    It's advisable to use Verbose = "Yes" with 'cscript //nologo ...'.
'
Verbose = "No"

'
' Minimalist version of getopts
' Usage:
' Set args = Wscript.Arguments
' Verbose = GetOpt(args, "/Verbose", "No")
' See: MAIN section!
'
Function GetOpt(args, opt, def)
Dim LString, LArray, arg

	GetOpt = def
	For Each arg In args
		LArray = Split(arg, "=")
		If (LCase(LArray(0)) = LCase(opt)) Then
			If(Ubound(LArray) = 0) Then
				GetOpt = "Yes"
			Else
				GetOpt = LArray(1)
			End If
			If LCase(LArray(0)) = "/advance" And Not IsNumeric(GetOpt) Then
				ShowMessage("/Advance must be an Integer value.")
				ShowMessage("Deployment aborted!")
				WScript.Quit 4
			End If
			If LCase(LArray(0)) = "/options" Then
				If GetOpt = "Yes" Then
					ShowMessage("/Options must have value.")
					ShowMessage("Deployment aborted!")
					WScript.Quit 5
				Else
					GetOpt = Right(arg, Len(arg)-Len("/options="))
				End If
			End If
			Exit Function
		End If
	Next
End Function

Function RunOrDie(strCmd)
Dim intReturn

	intReturn = 0
	' ShowMessage(strCmd)
	If (LCase(DryRun) = "no") Then
		intReturn = WshShell.Run(strCmd, 0, True)
	End If
	If intReturn <> 0 Then
		ShowMessage("Error running program: " & intReturn)
		WScript.Quit intReturn
	End If
End Function

' For debuging purpose only !!
Function DumpParamsAndDie()
Wscript.Echo "SetupVersion: " & 	SetupVersion
Wscript.Echo "SetupLocation: " & 	SetupLocation
Wscript.Echo "SetupArchitecture: " & SetupArchitecture
Wscript.Echo "Force: " & 			Force
Wscript.Echo "nMinutesToAdvance: " & nMinutesToAdvance
Wscript.Echo "Verbose: " & 			Verbose
Wscript.Echo "DryRun: " & 			DryRun
Wscript.Echo "Setup: " & 			Setup
Wscript.Echo "Help: " & 			Help
Wscript.Echo "Options: " & 			SetupOptions
WScript.Quit 0
End Function

Function Usage()
Verbose="Yes"
ShowMessage("Usage: fusioninventory-agent-deployment [options ...]")
ShowMessage(" ")
ShowMessage("	/Version=X.Y.Z")
ShowMessage("	/Location=" & Chr(34) & "http[s]://host[:port]/[absolut_path]" & Chr(34) & " | " & Chr(34) & "\\host\share\[path]" & Chr(34))
ShowMessage("	/Arch=x86 | x64 | Auto")
ShowMessage("	/Force[=Yes or No]")
ShowMessage("	/Advance=Minutes")
ShowMessage("	/Verbose[=Yes or No]")
ShowMessage("	/DryRun[=Yes or No]")
ShowMessage("	/Help")
ShowMessage("	/Options=/S /acceptlicense /runnow etc ...")
ShowMessage(" ")
ShowMessage("Missing options take the default value defined within the Script.")
ShowMessage("Present options without explicit value take the value Yes.")
ShowMessage(" ")
ShowMessage("Examples:")
ShowMessage("	fusioninventory-agent-deployment /help							just this usage")
ShowMessage("	fusioninventory-agent-deployment /advance=15						must be an Integer value")
ShowMessage("	fusioninventory-agent-deployment /verbose /dryrun					for verbose dummy run")
ShowMessage("	fusioninventory-agent-deployment /dryrun						for silenced dummy run")
ShowMessage("	fusioninventory-agent-deployment /dryrun /options=" & Chr(34) & "/S /acceptlicense /runnow etc ..." & Chr(34) & "	testing your options!")
End Function

'
'
' DO NOT EDIT BELOW
'
'

Function AdvanceTime(nMinutes)
   Dim nMinimalMinutes, dtmTimeFuture
   ' As protection
   nMinimalMinutes = 5
   If nMinutes < nMinimalMinutes Then
      nMinutes = nMinimalMinutes
   End If
   ' Add nMinutes to the current time
   dtmTimeFuture = DateAdd ("n", nMinutes, Time)
   ' Format the result value
   '    The command AT accepts 'HH:MM' values only
   AdvanceTime = Hour(dtmTimeFuture) & ":" & Minute(dtmTimeFuture)
End Function

Function baseName (strng)
   Dim regEx, ret
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = ".*[/\\]([^/\\]+)$"
   baseName = regEx.Replace(strng,"$1")
End Function

Function GetSystemArchitecture()
   Dim strSystemArchitecture
   Err.Clear
   ' Get operative system architecture
   On Error Resume Next
   strSystemArchitecture = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%")
   If Err.Number = 0 Then
      ' Check the operative system architecture
      Select Case strSystemArchitecture
         Case "x86"
            ' The system architecture is 32-bit
            GetSystemArchitecture = "x86"
         Case "AMD64"
            ' The system architecture is 64-bit
            GetSystemArchitecture = "x64"
         Case Else
            ' The system architecture is not supported
            GetSystemArchitecture = "NotSupported"
      End Select
   Else
      ' It has been not possible to get the system architecture
      GetSystemArchitecture = "Unknown"
   End If
End Function

Function isHttp(strng)
   Dim regEx, matches
   Set regEx = New RegExp
   regEx.Global = true
   regEx.IgnoreCase = True
   regEx.Pattern = "^(http(s?)).*"
   If regEx.Execute(strng).count > 0 Then
      isHttp = True
   Else
      isHttp = False
   End If
   Exit Function
End Function

Function IsInstallationNeeded(strSetupVersion, strSetupArchitecture, strSystemArchitecture)
   Dim strCurrentSetupVersion
   ' Compare the current version, whether it exists, with strSetupVersion
   If strSystemArchitecture = "x86" Then
      ' The system architecture is 32-bit
      ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
      '    This subkey is now deprecated
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\DisplayVersion")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' doesn't exist
         Err.Clear
         ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
         On error resume next
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
         If Err.Number = 0 Then
         ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            If strCurrentSetupVersion <> strSetupVersion Then
               ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
            Err.Clear
            ShowMessage("Installation needed: " & strSetupVersion)
            IsInstallationNeeded = True
         End If
      End If
   Else
      ' The system architecture is 64-bit
      ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
      '    This subkey is now deprecated
      On error resume next
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent\DisplayVersion")
      If Err.Number = 0 Then
      ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' exists
         If strCurrentSetupVersion <> strSetupVersion Then
            ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory Agent' doesn't exist
         Err.Clear
         ' Check if the subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
         On error resume next
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
         If Err.Number = 0 Then
         ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            If strCurrentSetupVersion <> strSetupVersion Then
               ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            ' The subkey 'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
            Err.Clear
            ' Check if the subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
            On error resume next
            strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\DisplayVersion")
            If Err.Number = 0 Then
            ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' exists
               If strCurrentSetupVersion <> strSetupVersion Then
                  ShowMessage("Installation needed: " & strCurrentSetupVersion & " -> " & strSetupVersion)
                  IsInstallationNeeded = True
               End If
               Exit Function
            Else
               ' The subkey 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent' doesn't exist
               Err.Clear
               ShowMessage("Installation needed: " & strSetupVersion)
               IsInstallationNeeded = True
            End If
         End If
      End If
   End If
End Function

Function IsSelectedForce()
   If LCase(Force) <> "no" Then
      ShowMessage("Installation forced: " & SetupVersion)
      IsSelectedForce = True
   Else
      IsSelectedForce = False
   End If
End Function

' http://www.ericphelps.com/scripting/samples/wget/index.html
Function SaveWebBinary(strSetupLocation, strSetup)
   Const adTypeBinary = 1
   Const adSaveCreateOverWrite = 2
   Const ForWriting = 2
   Dim web, varByteArray, strData, strBuffer, lngCounter, ado, strUrl
   strUrl = strSetupLocation & "/" & strSetup
   'On Error Resume Next
   'Download the file with any available object
   Err.Clear
   Set web = Nothing
   Set web = CreateObject("WinHttp.WinHttpRequest.5.1")
   If web Is Nothing Then Set web = CreateObject("WinHttp.WinHttpRequest")
   If web Is Nothing Then Set web = CreateObject("MSXML2.ServerXMLHTTP")
   If web Is Nothing Then Set web = CreateObject("Microsoft.XMLHTTP")
   web.Open "GET", strURL, False
   web.Send
   If Err.Number <> 0 Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   If web.Status <> "200" Then
      SaveWebBinary = False
      Set web = Nothing
      Exit Function
   End If
   varByteArray = web.ResponseBody
   Set web = Nothing
   'Now save the file with any available method
   On Error Resume Next
   Set ado = Nothing
   Set ado = CreateObject("ADODB.Stream")
   If ado Is Nothing Then
      Set fs = CreateObject("Scripting.FileSystemObject")
      Set ts = fs.OpenTextFile(baseName(strUrl), ForWriting, True)
      strData = ""
      strBuffer = ""
      For lngCounter = 0 to UBound(varByteArray)
         ts.Write Chr(255 And Ascb(Midb(varByteArray,lngCounter + 1, 1)))
      Next
      ts.Close
   Else
      ado.Type = adTypeBinary
      ado.Open
      ado.Write varByteArray
      ado.SaveToFile CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\" & strSetup, adSaveCreateOverWrite
      ado.Close
   End If
   SaveWebBinary = True
End Function

Function ShowMessage(strMessage)
   If LCase(Verbose) <> "no" Then
      WScript.Echo strMessage
   End If
End Function

'
'
' MAIN
'
'

Dim nMinutesToAdvance, strCmd, strSystemArchitecture, strTempDir, WshShell
Dim args, DryRun, Help, Saved
Set WshShell = WScript.CreateObject("WScript.shell")

DryRun = "No"
Help = "No"

nMinutesToAdvance = 5

Set args = Wscript.Arguments
Verbose           = GetOpt(args, "/Verbose", Verbose)
Help              = GetOpt(args, "/Help",    Help)
DryRun            = GetOpt(args, "/DryRun",  DryRun)
SetupVersion      = GetOpt(args, "/Version", SetupVersion)
SetupLocation     = GetOpt(args, "/Location",SetupLocation)
SetupArchitecture = GetOpt(args, "/Arch",    SetupArchitecture)
Force             = GetOpt(args, "/Force",   Force)
nMinutesToAdvance = GetOpt(args, "/Advance", nMinutesToAdvance)
SetupOptions      = GetOpt(args, "/Options", SetupOptions)
'ReRun Setup:
Setup = "fusioninventory-agent_windows-" & SetupArchitecture & "_" & SetupVersion & ".exe"

If LCase(Help) = "yes" Then
	Usage()
	WScript.Quit 0
End If

' Retaining Wall
' DumpParamsAndDie()

' Get system architecture
strSystemArchitecture = GetSystemArchitecture()
If (strSystemArchitecture <> "x86") And (strSystemArchitecture <> "x64") Then
   ShowMessage("The system architecture is unknown or not supported.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 1
Else
   ShowMessage("System architecture detected: " & strSystemArchitecture)
End If

' Check and auto detect SetupArchitecture
Select Case LCase(SetupArchitecture)
   Case "x86"
      ' The setup architecture is 32-bit
      SetupArchitecture = "x86"
      Setup = Replace(Setup, "x86", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "x64"
      ' The setup architecture is 64-bit
      SetupArchitecture = "x64"
      Setup = Replace(Setup, "x64", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture: " & SetupArchitecture)
   Case "auto"
      ' Auto detection of SetupArchitecture
      SetupArchitecture = strSystemArchitecture
      Setup = Replace(Setup, "Auto", SetupArchitecture, 1, 1, vbTextCompare)
      ShowMessage("Setup architecture detected: " & SetupArchitecture)
   Case Else
      ' The setup architecture is not supported
      ShowMessage("The setup architecture '" & SetupArchitecture & "' is not supported.")
      WScript.Quit 2
End Select

' Check the relation between strSystemArchitecture and SetupArchitecture
If (strSystemArchitecture = "x86") And (SetupArchitecture = "x64") Then
   ' It isn't possible to execute a 64-bit setup on a 32-bit operative system
   ShowMessage("It isn't possible to execute a 64-bit setup on a 32-bit operative system.")
   ShowMessage("Deployment aborted!")
   WScript.Quit 3
End If

If IsSelectedForce() Or IsInstallationNeeded(SetupVersion, SetupArchitecture, strSystemArchitecture) Then
   If isHttp(SetupLocation) Then
      ShowMessage("Downloading: " & SetupLocation & "/" & Setup)
      If (LCase(DryRun) = "no") Then
        Saved = SaveWebBinary(SetupLocation, Setup)
      Else
        Saved = True
      End If
      If Saved Then
         strCmd = WshShell.ExpandEnvironmentStrings("%ComSpec%")
         strTempDir = WshShell.ExpandEnvironmentStrings("%TEMP%")
         ShowMessage("Running: """ & strTempDir & "\" & Setup & """ " & SetupOptions)
         RunOrDie("""" & strTempDir & "\" & Setup & """ " & SetupOptions)
         ShowMessage("Scheduling: DEL /Q /F """ & strTempDir & "\" & Setup & """")
         RunOrDie("AT.EXE " & AdvanceTime(nMinutesToAdvance) & " " & strCmd & " /C ""DEL /Q /F """"" & strTempDir & "\" & Setup & """""")
         ShowMessage("Deployment done!")
      Else
         ShowMessage("Error downloading '" & SetupLocation & "\" & Setup & "'!")
      End If
   Else
      ShowMessage("Running: """ & SetupLocation & "\" & Setup & """ " & SetupOptions)
      RunOrDie("CMD.EXE /C """ & SetupLocation & "\" & Setup & """ " & SetupOptions)
      ShowMessage("Deployment done!")
   End If
Else
   ShowMessage("It isn't needed the installation of '" & Setup & "'.")
End If
