Write-host "Installing Buffer-manager.nvim....."

$url = "https://github.com/xsoder/buffer-manager.nvim.git" 
$pathToCheck = "$env:LOCALAPPDATA\nvim-data\site\pack\manual\start\buffer-manager.nvim"

Write-host "Checking if it is installed" -foreground yellow

if (Test-Path -Path $pathToCheck) {
    Write-host "It is installed..."
    Remove-Item -Path $pathToCheck -force
    Write-Host "'Buffer-manager.nvim' has been removed."
    Write-host "Reinstalling Buffer-manager.nvim..." -foreground green
	git clone $url "$pathtocheck"
} else {
	git clone $url "$pathtocheck"
}

Write-host "Checking Dependencies......." -foreground yellow


$1 = "$env:LOCALAPPDATA\nvim-data\site\pack\manual\start\nvim-web-devicons"
$2 = "$env:LOCALAPPDATA\nvim-data\site\pack\manual\start\fzf-lua"
$3 = "$env:LOCALAPPDATA\nvim-data\site\pack\manual\start\lf"

$1u = "https://github.com/nvim-tree/nvim-web-devicons.git" 
$2u = "https://github.com/ibhagwan/fzf-lua.git"
$3u = "https://github.com/gokcehan/lf.git"

if (Test-Path -Path $1) {
    Write-host "nvim-web-devicons is installed" -foreground green

} else {
    Write-Host "nvim-web-devicons is not installed" -foreground red
    Write-host "Installing nvim-web-devicons..." -foreground yellow
	git clone $1u "$1"
}
if (Test-Path -Path $2) {
    Write-host "fzf-lua is installed" -foreground green

} else {
    Write-Host "fzf-lua is not installed" -foreground red
    Write-host "Installing fzf-lua..." -foreground yellow
	git clone $2u "$2"
}
if (Test-Path -Path $3) {
    Write-host "lf is installed" -foreground green

} else {
    Write-Host "lf is not installed" -foreground red
    Write-host "Installing lf..." -foreground yellow
	git clone $3u "$3"
}
