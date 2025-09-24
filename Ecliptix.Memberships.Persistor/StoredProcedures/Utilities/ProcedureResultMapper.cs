using System.Text.RegularExpressions;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;
using Microsoft.Extensions.Logging;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

public static class ProcedureResultMapper
{
    public static ProcedureOutcome ToProcedureOutcome(string? value, ILogger logger) => 
        ParseEnum(value, ProcedureOutcome.Error, logger);

    public static MembershipActivityStatus ToActivityStatus(string? value, ILogger logger) =>
        ParseEnum(value, MembershipActivityStatus.Error, logger);

    public static MembershipCreationStatus ToCreationStatus(string? value, ILogger logger) =>
        ParseEnum(value, MembershipCreationStatus.SecureKeySet, logger);
    
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

    public static T ParseEnum<T>(string? value, T fallback, ILogger logger) where T : struct, Enum
    {
        string normalized = NormalizeEnumValue(value);
        
        if (Enum.TryParse(normalized, true, out T parsed))
            return parsed;
        
        logger.LogError("Failed to parse enum value '{Value}' for type {EnumType}. Falling back to {Fallback}.",
            value, typeof(T).Name, fallback);
        
        return fallback;
    }
}
