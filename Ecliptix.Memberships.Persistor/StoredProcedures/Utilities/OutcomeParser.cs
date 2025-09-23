using System.Text.RegularExpressions;
using Ecliptix.Memberships.Persistor.StoredProcedures.Models.Enums;

namespace Ecliptix.Memberships.Persistor.StoredProcedures.Utilities;

public static class OutcomeParser
{
    public static ProcedureOutcome Parse(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return ProcedureOutcome.Error;

        string normalized = Regex.Replace(value, "_([a-z])", m => m.Groups[1].Value.ToUpper());
        normalized = char.ToUpper(normalized[0]) + normalized.Substring(1);

        if (Enum.TryParse<ProcedureOutcome>(normalized, true, out var parsed))
            return parsed;

        return ProcedureOutcome.Error;
    }
}
