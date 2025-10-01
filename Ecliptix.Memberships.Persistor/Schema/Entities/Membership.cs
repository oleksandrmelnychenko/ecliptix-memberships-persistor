namespace Ecliptix.Memberships.Persistor.Schema.Entities;

public class Membership : EntityBase
{
    public Guid MobileNumberId { get; set; }
    public Guid AppDeviceId { get; set; }
    public Guid VerificationFlowId { get; set; }
    public byte[]? SecureKey { get; set; }

    public byte[]? MaskingKey { get; set; }
    public byte[]? Mac { get; set; } 

    public string Status { get; set; } = "inactive";
    public string? CreationStatus { get; set; }

    public virtual MobileNumber MobileNumber { get; set; } = null!;
    public virtual Device AppDevice { get; set; } = null!;
    public virtual VerificationFlow VerificationFlow { get; set; } = null!;

    public virtual ICollection<MembershipAttempt> MembershipAttempts { get; set; } = new List<MembershipAttempt>();
    public virtual ICollection<LoginAttempt> LoginAttempts { get; set; } = new List<LoginAttempt>();
    public virtual ICollection<MasterKeyShare> MasterKeyShares { get; set; } = new List<MasterKeyShare>();
}