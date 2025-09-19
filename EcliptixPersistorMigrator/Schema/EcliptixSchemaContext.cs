using Microsoft.EntityFrameworkCore;
using EcliptixPersistorMigrator.Schema.Entities;
using EcliptixPersistorMigrator.Schema.Configurations;

namespace EcliptixPersistorMigrator.Schema;

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

        modelBuilder.ApplyConfiguration(new MobileNumberConfiguration());
        modelBuilder.ApplyConfiguration(new DeviceConfiguration());
        modelBuilder.ApplyConfiguration(new VerificationFlowConfiguration());
        modelBuilder.ApplyConfiguration(new OtpCodeConfiguration());
        modelBuilder.ApplyConfiguration(new FailedOtpAttemptConfiguration());
        modelBuilder.ApplyConfiguration(new MembershipConfiguration());
        modelBuilder.ApplyConfiguration(new MembershipAttemptConfiguration());
        modelBuilder.ApplyConfiguration(new LoginAttemptConfiguration());
        modelBuilder.ApplyConfiguration(new EventLogConfiguration());
        modelBuilder.ApplyConfiguration(new MobileDeviceConfiguration());
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