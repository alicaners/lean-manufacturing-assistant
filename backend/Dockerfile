# ---------- Stage 1: build ----------
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy only project files first, so NuGet restore is cached
# and re-runs only when dependencies change.
COPY Directory.Build.props ./
COPY src/LeanAssistant.Domain/LeanAssistant.Domain.csproj src/LeanAssistant.Domain/
COPY src/LeanAssistant.Application/LeanAssistant.Application.csproj src/LeanAssistant.Application/
COPY src/LeanAssistant.Infrastructure/LeanAssistant.Infrastructure.csproj src/LeanAssistant.Infrastructure/
COPY src/LeanAssistant.Api/LeanAssistant.Api.csproj src/LeanAssistant.Api/
RUN dotnet restore src/LeanAssistant.Api/LeanAssistant.Api.csproj

# Copy the source code and publish a release build.
COPY src/ src/
RUN dotnet publish src/LeanAssistant.Api/LeanAssistant.Api.csproj \
    --configuration Release \
    --no-restore \
    --output /app/publish

# ---------- Stage 2: runtime ----------
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

COPY --from=build /app/publish .

# Run as the built-in non-root user, never as root.
USER $APP_UID

EXPOSE 8080
ENTRYPOINT ["dotnet", "LeanAssistant.Api.dll"]