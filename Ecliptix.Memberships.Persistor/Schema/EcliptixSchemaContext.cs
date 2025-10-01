using Microsoft.EntityFrameworkCore;
using Ecliptix.Memberships.Persistor.Schema.Entities;
using Ecliptix.Memberships.Persistor.Schema.Configurations;

namespace Ecliptix.Memberships.Persistor.Schema;

public class EcliptixSchemaContext : DbContext
{
    public EcliptixSchemaContext(DbContextOptions<EcliptixSchemaContext> options) : base(options)
    {
    }

    public DbSet<MobileNumber> MobileNumbers { get; set; }
    public DbSet<Device> Devices { get; set; }
    public DbSet<VerificationFlow> VerificationFlows { get; set; }
    public DbSet<OtpCode> OtpCodes { get; set; }
    public DbSet<FailedOtpAttempt> FailedOtpAttempts { get; set; }
    public DbSet<Membership> Memberships { get; set; }
    public DbSet<MembershipAttempt> MembershipAttempts { get; set; }
    public DbSet<LoginAttempt> LoginAttempts { get; set; }
    public DbSet<EventLog> EventLogs { get; set; }
    public DbSet<MobileDevice> MobileDevices { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.AddConfiguration(new MobileNumberConfiguration());
        modelBuilder.AddConfiguration(new DeviceConfiguration());
        modelBuilder.AddConfiguration(new VerificationFlowConfiguration());
        modelBuilder.AddConfiguration(new OtpCodeConfiguration());
        modelBuilder.AddConfiguration(new FailedOtpAttemptConfiguration());
        modelBuilder.AddConfiguration(new MasterKeyShareConfiguration());
        modelBuilder.AddConfiguration(new MembershipConfiguration());
        modelBuilder.AddConfiguration(new MembershipAttemptConfiguration());
        modelBuilder.AddConfiguration(new LoginAttemptConfiguration());
        modelBuilder.AddConfiguration(new EventLogConfiguration());
        modelBuilder.AddConfiguration(new MobileDeviceConfiguration());
    }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            throw new InvalidOperationException(
                "DbContext is not configured. Ensure connection string is provided through dependency injection or design-time factory.");
        }
    }
}