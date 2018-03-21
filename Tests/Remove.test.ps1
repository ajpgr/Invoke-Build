
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

	($r = try {remove .} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove *} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove '...***///\\\'} catch {$_})
	equals "$r" 'Not allowed paths.'

	($r = try {remove Remove.test.ps1, *} catch {$_})
	assert (Test-Path Remove.test.ps1)
	equals "$r" 'Not allowed paths.'
}

# Synopsis: Errors on locked items.
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
		$r = remove z.2.txt, z.txt -ea 2 -ev r2 2>&1
		$r | Out-String
		# good is removed
		assert (!(Test-Path z.2.txt))
		# locked error, two ways of catching
		equals $r.FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'
		equals $r2[0].FullyQualifiedErrorId 'RemoveFileSystemItemIOError,Microsoft.PowerShell.Commands.RemoveItemCommand'
	}
	finally {
		$writer.Close()
		remove z.txt
	}
}
