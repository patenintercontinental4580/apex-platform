using Azure.Identity;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Serilog;
using Serilog.Events;

var builder = WebApplication.CreateBuilder(args);

// ── Azure Credential ─────────────────────────────────────────────────────────
var credential = new DefaultAzureCredential();

// ── Key Vault Configuration ───────────────────────────────────────────────────
var keyVaultUri = builder.Configuration["KeyVault:Uri"];
if (!string.IsNullOrEmpty(keyVaultUri))
{
    builder.Configuration.AddAzureKeyVault(new Uri(keyVaultUri), credential);
}

// ── Azure App Configuration ───────────────────────────────────────────────────
var appConfigUri = builder.Configuration["AppConfig:Endpoint"];
if (!string.IsNullOrEmpty(appConfigUri))
{
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options
            .Connect(new Uri(appConfigUri), credential)
            .ConfigureRefresh(refresh =>
            {
                refresh.Register("ApexService:Sentinel", refreshAll: true)
                       .SetCacheExpiration(TimeSpan.FromMinutes(5));
            });
    });
    builder.Services.AddAzureAppConfiguration();
}

// ── Serilog Structured Logging ────────────────────────────────────────────────
var appInsightsConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .MinimumLevel.Override("System", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithEnvironmentName()
    .Enrich.WithThreadId()
    .WriteTo.Console(outputTemplate:
        "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext}: {Message:lj}{NewLine}{Exception}")
    .WriteTo.ApplicationInsights(
        appInsightsConnectionString ?? string.Empty,
        TelemetryConverter.Traces)
    .CreateLogger();

builder.Host.UseSerilog();

// ── OpenTelemetry Tracing ─────────────────────────────────────────────────────
builder.Services.AddOpenTelemetry()
    .WithTracing(tracing =>
    {
        tracing
            .AddAspNetCoreInstrumentation()
            .AddHttpClientInstrumentation();
    })
    .UseAzureMonitor(options =>
    {
        options.ConnectionString = appInsightsConnectionString;
    });

// ── Health Checks ─────────────────────────────────────────────────────────────
builder.Services.AddHealthChecks()
    .AddCheck("liveness", () => HealthCheckResult.Healthy("Service is alive."), tags: ["live"])
    .AddSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection") ?? string.Empty,
        name: "database",
        tags: ["ready"])
    .AddAzureBlobStorage(
        builder.Configuration["Storage:ConnectionString"] ?? string.Empty,
        name: "blob-storage",
        tags: ["ready"]);

// ── Services ──────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new()
    {
        Title   = "Apex Service API",
        Version = "v1",
    });
});

builder.Services.AddHttpClient();

var app = builder.Build();

// ── Middleware Pipeline ───────────────────────────────────────────────────────
app.UseSerilogRequestLogging();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

if (!string.IsNullOrEmpty(appConfigUri))
{
    app.UseAzureAppConfiguration();
}

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ── Health Check Endpoints ────────────────────────────────────────────────────
app.MapHealthChecks("/healthz", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("live"),
});

app.MapHealthChecks("/ready", new HealthCheckOptions
{
    Predicate = check => check.Tags.Contains("ready"),
});

try
{
    Log.Information("Starting Apex Service");
    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application terminated unexpectedly");
}
finally
{
    Log.CloseAndFlush();
}
