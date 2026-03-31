using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace ApexService.Controllers;

[ApiController]
[Route("api/[controller]")]
public class WeatherController : ControllerBase
{
    private static readonly string[] Summaries =
    [
        "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching",
    ];

    private readonly ILogger<WeatherController> _logger;

    public WeatherController(ILogger<WeatherController> logger)
    {
        _logger = logger;
    }

    [HttpGet(Name = "GetWeatherForecast")]
    [ProducesResponseType(typeof(IEnumerable<WeatherForecast>), StatusCodes.Status200OK)]
    public IActionResult Get()
    {
        using var activity = Activity.Current?.Source.StartActivity("GetWeatherForecast");
        activity?.SetTag("operation", "get-weather");

        _logger.LogInformation("Fetching weather forecast");

        var forecasts = Enumerable.Range(1, 5).Select(index => new WeatherForecast
        {
            Date         = DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary      = Summaries[Random.Shared.Next(Summaries.Length)],
        });

        return Ok(forecasts);
    }

    [HttpGet("{id:int}", Name = "GetWeatherForecastById")]
    [ProducesResponseType(typeof(WeatherForecast), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult GetById(int id)
    {
        using var activity = Activity.Current?.Source.StartActivity("GetWeatherForecastById");
        activity?.SetTag("forecast.id", id);

        _logger.LogInformation("Fetching weather forecast for ID {ForecastId}", id);

        if (id < 1 || id > 5)
        {
            _logger.LogWarning("Weather forecast {ForecastId} not found", id);
            return NotFound(new { message = $"Forecast with ID {id} was not found." });
        }

        var forecast = new WeatherForecast
        {
            Date         = DateOnly.FromDateTime(DateTime.Now.AddDays(id)),
            TemperatureC = Random.Shared.Next(-20, 55),
            Summary      = Summaries[Random.Shared.Next(Summaries.Length)],
        };

        return Ok(forecast);
    }
}

public record WeatherForecast
{
    public DateOnly Date         { get; init; }
    public int      TemperatureC { get; init; }
    public int      TemperatureF => 32 + (int)(TemperatureC / 0.5556);
    public string?  Summary      { get; init; }
}
