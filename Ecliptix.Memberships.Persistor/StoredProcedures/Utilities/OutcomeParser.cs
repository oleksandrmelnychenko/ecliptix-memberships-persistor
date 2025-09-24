using System.Text.RegularExpressions;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

public static class ProcedureResultMapper
{
    private static string NormalizeEnumValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return string.Empty;

        // Converts snake_case or lower_case to PascalCase
        string normalized = Regex.Replace(value, "_([a-z])", m => m.Groups[1].Value.ToUpper());
        
        if (string.IsNullOrEmpty(normalized)) 
            return string.Empty;
        
        normalized = char.ToUpper(normalized[0]) + normalized.Substring(1);
        
        return normalized;
    }

    public static ProcedureOutcome ToProcedureOutcome(string? value)
    {
        string normalized = NormalizeEnumValue(value);
        if (Enum.TryParse<ProcedureOutcome>(normalized, true, out ProcedureOutcome parsed))
            return parsed;
        return ProcedureOutcome.Error;
    }

    public static MembershipActivityStatus ToActivityStatus(string? value)
    {
        string normalized = NormalizeEnumValue(value);
        if (Enum.TryParse<MembershipActivityStatus>(normalized, true, out MembershipActivityStatus parsed))
            return parsed;
        return MembershipActivityStatus.Inactive;
    }

    public static MembershipCreationStatus ToCreationStatus(string? value)
    {
        string normalized = NormalizeEnumValue(value);
        if (Enum.TryParse<MembershipCreationStatus>(normalized, true, out MembershipCreationStatus parsed))
            return parsed;
        return MembershipCreationStatus.OtpVerified;
    }
}
