function New-ErrorRecord 
{

	<#  
		.Synopsis
		Creates an custom ErrorRecord that can be used to report a terminating or non-terminating error.  
		
		.Description
		Creates an custom ErrorRecord that can be used to report a terminating or non-terminating error.  
		
		.Parameter Exception      
		The Exception that will be associated with the ErrorRecord. 
		
		.Parameter ErrorID      
		A scripter-defined identifier of the error. This identifier must be a non-localized string for a specific error type.  
		
		.Parameter ErrorCategory      
		An ErrorCategory enumeration that defines the category of the error.  The supported Category Members are (from: http://msdn.microsoft.com/en-us/library/system.management.automation.errorcategory(v=vs.85).aspx) :
			
			* AuthenticationError - An error that occurs when the user cannot be authenticated by the service. This could mean that the credentials are invalid or that the authentication system is not functioning properly. 
			* CloseError - An error that occurs during closing. 
			* ConnectionError - An error that occurs when a network connection that the operation depEnds on cannot be established or maintained. 
			* DeadlockDetected - An error that occurs when a deadlock is detected. 
			* DeviceError - An error that occurs when a device reports an error. 
			* FromStdErr - An error that occurs when a non-Windows PowerShell command reports an error to its STDERR pipe. 
			* InvalidArgument - An error that occurs when an argument that is not valid is specified. 
			* InvalidData - An error that occurs when data that is not valid is specified. 
			* InvalidOperation - An error that occurs when an operation that is not valid is requested. 
			* InvalidResult - An error that occurs when a result that is not valid is returned. 
			* InvalidType - An error that occurs when a .NET Framework type that is not valid is specified. 
			* LimitsExceeded - An error that occurs when internal limits prevent the operation from being executed. 
			* MetadataError - An error that occurs when metadata contains an error.  
			* NotEnabled - An error that occurs when the operation attempts to use functionality that is currently disabled. 
			* NotImplemented - An error that occurs when a referenced application programming interface (API) is not implemented. 
			* NotInstalled - An error that occurs when an item is not installed. 
			* NotSpecified - An unspecified error. Use only when not enough is known about the error to assign it to another error category. Avoid using this category if you have any information about the error, even if that information is incomplete. 
			* ObjectNotFound - An error that occurs when an object cannot be found. 
			* OpenError - An error that occurs during opening. 
			* OperationStopped - An error that occurs when an operation has stopped. For example, the user interrupts the operation. 
			* OperationTimeout - An error that occurs when an operation has exceeded its timeout limit. 
			* ParserError - An error that occurs when a parser encounters an error. 
			* PermissionDenied - An error that occurs when an operation is not permitted. 
			* ProtocolError An error that occurs when the contract of a protocol is not being followed. This error should not happen with well-behaved components. 
			* QuotaExceeded An error that occurs when controls on the use of traffic or resources prevent the operation from being executed. 
			* ReadError An error that occurs during reading. 
			* ResourceBusy An error that occurs when a resource is busy. 
			* ResourceExists An error that occurs when a resource already exists. 
			* ResourceUnavailable An error that occurs when a resource is unavailable. 
			* SecurityError An error that occurs when a security violation occurs. This field is introduced in Windows PowerShell 2.0. 
			* SyntaxError An error that occurs when a command is syntactically incorrect. 
			* WriteError An error that occurs during writing. 
		
		.Parameter TargetObject      
		The object that was being Processed when the error took place.  
		
		.Parameter Message      
		Describes the Exception to the user.  
		
		.Parameter InnerException      
		The Exception instance that caused the Exception association with the ErrorRecord.  
		.Parameter TargetType
		To customize the TargetType value, specify the appropriate Target object type.  Values can be "Array", "PSObject", "HashTable", etc.  Can be provided by ${ParameterName}.GetType().Name.
		
		.Example     
	#>

	[CmdletBinding ()]
	Param
	(

		[Parameter (Mandatory, Position = 0)]
		[System.String]$Exception,

		[Parameter (Mandatory, Position = 1)]
		[Alias ('ID')]
		[System.String]$ErrorId,

		[Parameter (Mandatory, Position = 2)]
		[Alias ('Category')]
		[ValidateSet ('AuthenticationError','ConnectionError','NotSpecified', 'OpenError', 'CloseError', 'DeviceError',
			'DeadlockDetected', 'InvalidArgument', 'InvalidData', 'InvalidOperation',
				'InvalidResult', 'InvalidType', 'MetadataError', 'NotImplemented',
					'NotInstalled', 'ObjectNotFound', 'OperationStopped', 'OperationTimeout',
						'SyntaxError', 'ParserError', 'PermissionDenied', 'ResourceBusy',
							'ResourceExists', 'ResourceUnavailable', 'ReadError', 'WriteError',
								'FromStdErr', 'SecurityError')]
		[System.Management.Automation.ErrorCategory]$ErrorCategory,

		[Parameter (Mandatory, Position = 3)]
		[System.Object]$TargetObject,

		[Parameter (Mandatory)]
		[System.String]$Message,

		[Parameter (Mandatory = $false)]
		[System.Exception]$InnerException,

		[Parameter (Mandatory = $false)]
		[System.String]$TargetType = "String"

	)

	Process 
	{

		# ...build and save the new Exception depending on present arguments, if it...
		$_exception = if ($Message -and $InnerException) {
			# ...includes a custom message and an inner exception
			New-Object $Exception $Message, $InnerException
		} elseif ($Message) {
			# ...includes a custom message only
			New-Object $Exception $Message
		} else {
			# ...is just the exception full name
			New-Object $Exception
		}

		# now build and output the new ErrorRecord
		"[{0}] Building ErrorRecord object" -f $MyInvocation.InvocationName.ToString().ToUpper() | Write-Verbose

		$record = New-Object Management.Automation.ErrorRecord $_exception, $ErrorID, $ErrorCategory, $TargetObject

		$record.CategoryInfo.TargetType = $TargetType

		Return $record
	}

}
