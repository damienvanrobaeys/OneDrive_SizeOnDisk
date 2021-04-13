param (
 [string]$OD_Path,
 [switch]$Files_Size
)

Function Format_Size
	{
		param(
		$size	
		)	
		If($size -eq $null){$FormatedSize = "0"}
		ElseIf( $size -lt 1KB ){$FormatedSize = "$("{0:N2}" -f $size) B"}
		ElseIf( $size -lt 1MB ){$FormatedSize = "$("{0:N2}" -f ($size / 1KB)) KB"}
		ElseIf( $size -lt 1GB ){$FormatedSize = "$("{0:N2}" -f ($size / 1MB)) MB"}
		ElseIf( $size -lt 1TB ){$FormatedSize = "$("{0:N2}" -f ($size / 1GB)) GB"}
		ElseIf( $size -lt 1PB ){$FormatedSize = "$("{0:N2}" -f ($size / 1TB)) TB"}
		return $FormatedSize
	}

add-type -type  @"
	using System;
	using System.Runtime.InteropServices;
	using System.ComponentModel;
	using System.IO;

	namespace Disk
	{
		public class Size
		{				
			[DllImport("kernel32.dll")]
			static extern uint GetCompressedFileSizeW([In, MarshalAs(UnmanagedType.LPWStr)] string lpFileName,
			out uint lpFileSizeHigh);
						
			public static ulong SizeOnDisk(string filename)
			{
			  uint High_Order;
			  uint Low_Order;
			  ulong GetSize;

			  FileInfo CurrentFile = new FileInfo(filename);
			  Low_Order = GetCompressedFileSizeW(CurrentFile.FullName, out High_Order);
			  int GetError = Marshal.GetLastWin32Error();

			 if (High_Order == 0 && Low_Order == 0xFFFFFFFF && GetError != 0)
				{
					throw new Win32Exception(GetError);
				}
			 else 
				{ 
					GetSize = ((ulong)High_Order << 32) + Low_Order;
					return GetSize;
				}
			}
		}
	}
"@


$Get_All_Files = Get-ChildItem $OD_Path -recurse -ea silentlycontinue | Where-Object {! $_.PSIsContainer} 
$OD_Files_Array = @()
ForEach($File in $Get_All_Files)  
	{
		If((test-path $File.FullName))
			{
				$SizeOnDisk = [Disk.Size]::SizeOnDisk($File.FullName) 	
				If($Files_Size)
					{
						$OD_Obj = New-Object PSObject
						Add-Member -InputObject $OD_Obj -MemberType NoteProperty -Name "File name" -Value $File.Name
						Add-Member -InputObject $OD_Obj -MemberType NoteProperty -Name "Path" -Value $File.DirectoryName	
						Add-Member -InputObject $OD_Obj -MemberType NoteProperty -Name "Size" -Value $File.Length
						Add-Member -InputObject $OD_Obj -MemberType NoteProperty -Name "Size on Disk" -Value $SizeOnDisk
						$OD_Files_Array += $OD_Obj					
					}
				
				$total_disk_size +=  $SizeOnDisk
				$total_size +=  $File.Length	
			}
	}

$Formated_FullSize = Format_Size -size $total_size
$Formated_SizeOnDisk = Format_Size -size $total_disk_size
"OneDrive usage size ($Formated_FullSize) - OneDrive usage on disk size  ($Formated_SizeOnDisk)"

$OD_Obj2 = New-Object PSObject
Add-Member -InputObject $OD_Obj2 -MemberType NoteProperty -Name "File name" -Value " OneDrive resume"
Add-Member -InputObject $OD_Obj2 -MemberType NoteProperty -Name "Path" -Value $OD_Path
Add-Member -InputObject $OD_Obj2 -MemberType NoteProperty -Name "Size" -Value $Formated_FullSize
Add-Member -InputObject $OD_Obj2 -MemberType NoteProperty -Name "Size on disk" -Value $Formated_SizeOnDisk	
$OD_Files_Array += $OD_Obj2	

If($Files_Size)
	{
		$OD_Files_Array | out-gridview	
	}
