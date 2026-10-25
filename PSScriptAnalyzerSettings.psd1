@{
    ExcludeRules = @(
        # These are interactive operator scripts; coloured console output is the point.
        'PSAvoidUsingWriteHost',
        # New-LabPassword only returns a string; it changes no state.
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
