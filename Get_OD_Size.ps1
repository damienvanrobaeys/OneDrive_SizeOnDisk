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

Function OD_SizeOnDisk
	{
		param(
		$Folder_to_check	
		)	

		$Global:Get_All_Files = Get-ChildItem $Folder_to_check -recurse -ea silentlycontinue | Where-Object {! $_.PSIsContainer} 
		$OD_Files_Array = @()
		ForEach($File in $Get_All_Files)  
			{
				If((test-path $File.FullName))
					{
						$SizeOnDisk = [Disk.Size]::SizeOnDisk($File.FullName) 						
						$total_SizeOnSisk +=  $SizeOnDisk
						$total_size +=  $File.Length									
						$Return_Array = $total_size, $total_SizeOnSisk
					}
			}
		return $Return_Array				
	}

$OD_Folder_Path = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1").UserFolder
$OD_Main_Size = (OD_SizeOnDisk -Folder_to_check $OD_Folder_Path)
$OD_SizeDisk = $OD_Main_Size[1]
$OD_FullSize = $OD_Main_Size[0]			
	
$Formated_FullSize = Format_Size -size $OD_FullSize
$Formated_SizeOnDisk = Format_Size -size $OD_SizeDisk

# Getting Documents folder size
$Documents_Path = [System.Environment]::GetFolderPath("MyDocuments")
$Documents_Size = (OD_SizeOnDisk -Folder_to_check $Documents_Path)
$Documents_FullSize = $Documents_Size[0]	
$Documents_SizeOnDisk = $Documents_Size[1]	
$Documents_FullSize_Formated = Format_Size -size $Documents_FullSize		
$Documents_SizeOnDisk_Formated = Format_Size -size $Documents_SizeOnDisk		

# Getting Desktop folder size
$Desktop_Path = [System.Environment]::GetFolderPath("Desktop")
$Desktop_Size = (OD_SizeOnDisk -Folder_to_check $Desktop_Path)	
$Desktop_FullSize = $Desktop_Size[0]		
$Desktop_SizeOnDisk = $Desktop_Size[1]		
$Desktop_FullSize_Formated = Format_Size -size $Desktop_FullSize
$Desktop_SizeOnDisk_Formated = Format_Size -size $Desktop_SizeOnDisk

# Getting Pictures folder size
$Pictures_Path = [System.Environment]::GetFolderPath("MyPictures")
$Pictures_Size = (OD_SizeOnDisk -Folder_to_check $Pictures_Path)
$Pictures_FullSize = $Pictures_Size[0]		
$Pictures_SizeOnDisk = $Pictures_Size[1]		
$Pictures_FullSize_Formated = Format_Size -size $Pictures_FullSize
$Pictures_SizeOnDisk_Formated = Format_Size -size $Pictures_SizeOnDisk	


# Get Hard disk size info
$Win32_LogicalDisk = Get-ciminstance Win32_LogicalDisk | where {$_.DeviceID -eq "C:"}
$Disk_Full_Size = $Win32_LogicalDisk.size
$Disk_Free_Space = $Win32_LogicalDisk.Freespace

$OD_UsageOnDisk_Percent = '{0:N0}' -f (($OD_FullSize / $Disk_Full_Size * 100),1)	
""
"Full OneDrive size: $Formated_FullSize"
"OneDrive size on disk: $Formated_SizeOnDisk"
"OneDrive disk usage percentage: $OD_UsageOnDisk_Percent%"
""
"Documents size: $Documents_FullSize_Formated"
"Documents size on disk: $Documents_SizeOnDisk_Formated"
""
"Desktop size: $Desktop_FullSize_Formated"
"Desktop size on disk: $Desktop_SizeOnDisk_Formated"
""
"Pictures size $Pictures_FullSize_Formated"
"Pictures size on disk: $Pictures_SizeOnDisk_Formated"

