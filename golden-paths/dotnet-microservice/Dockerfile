# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project file and restore dependencies (layer cache optimisation)
COPY ["ApexService.csproj", "."]
RUN dotnet restore "ApexService.csproj"

# Copy source and build
COPY . .
RUN dotnet build "ApexService.csproj" \
    --configuration Release \
    --no-restore \
    --output /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "ApexService.csproj" \
    --configuration Release \
    --no-restore \
    --no-build \
    --output /app/publish \
    /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install curl for health check in container orchestrators
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Run as non-root user
USER app

COPY --from=publish /app/publish .

EXPOSE 8080
EXPOSE 8081

ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl --fail http://localhost:8080/healthz || exit 1

ENTRYPOINT ["dotnet", "ApexService.dll"]
