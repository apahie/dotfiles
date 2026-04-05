# Windows Terminal でペイン分割・新タブ時にカレントディレクトリを引き継ぐ (OSC 9;9)
# https://learn.microsoft.com/en-us/windows/terminal/tutorials/new-tab-same-directory
function prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation;

    $out = ""
    if ($loc.Provider.Name -eq "FileSystem") {
        $out += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    }
    $out += "PS $loc$('>' * ($nestedPromptLevel + 1)) ";
    return $out
}
