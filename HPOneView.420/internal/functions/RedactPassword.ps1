function RedactPassword
{

	[CmdletBinding ()]
	Param 
	(

		[Hashtable]$BoundParameters

	)

    $Caller = (Get-PSCallStack)[1].Command

    '[{0}] Redacting users Password from Verbose Output' -f $Caller | Write-Verbose 

	$_Params = @{}

	$PSBoundParameters.BoundParameters.GetEnumerator() | ForEach-Object {

        if ($_Params.($_.Key) -is [PSCustomObject])
        {

			$_Params.Add($_.Key,$PSBoundParameters.BoundParameters.($_.Key).PSObject.Copy())

        }

        else
        {

            $_Params.Add($_.Key,$_.Value)


        }

        # Handle Level 1
        if ($_Params.password)
        {


            $_Params.password = '[*****REDACTED******]'

        } 

        # Handle Level 2
        if ($_Params.($_.Key).password)
        {

            $_Params.($_.Key).password = '[*****REDACTED******]'

        }

	}

	"[{0}] Bound PS Parameters: {1}" -f $Caller, ($_Params | out-string) | Write-Verbose

}
