
<#
.Synopsis
	Tests 'remove'.

.Example
	Invoke-Build * Remove.test.ps1
#>

# Synopsis: Errors on invalid arguments.
task InvalidArgument {
	($r = try {remove ''} catch {$_})
	equals $r.FullyQualifiedErrorId 'ParameterArgumentValidationErrorEmptyStringNotAllowed,Remove-BuildItem'

	($r = try {remove @()} catch {$_})
	equals $r.FullyQualifiedErrorId 'ParameterArgumentValidationErrorEmptyArrayNotAllowed,Remove-BuildItem'

	($r = try {remove *} catch {$_})
	equals "$r" '* is not allowed.'

	($r = try {remove Remove.test.ps1, *} catch {$_})
	assert (Test-Path Remove.test.ps1)
	equals "$r" '* is not allowed.'
}

# Synopsis: Errors on "cannot remove" items.
task ErrorLockedFile {
	# create a locked file
	$writer = [IO.File]::CreateText("$BuildRoot\z.txt")
	try {
		## terminating error
		($r1 = try {remove z.txt} catch {$_})
		equals $r1.FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'

		## non-terminating error
		# this will be removed
		Set-Content z.2.txt 42
		assert (Test-Path z.2.txt)
		# call with good and locked files
		remove z.2.txt, z.txt -ea 2 -ev r2
		# good is removed
		assert (!(Test-Path z.2.txt))
		# locked causes an error
		equals $r2[0].FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'
	}
	finally {
		$writer.Close()
		remove z.txt
	}
}
