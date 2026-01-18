FROM mcr.microsoft.com/dotnet/core/aspnet:2.1-stretch-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.1-stretch AS build
WORKDIR /src
# Copie des fichiers de projet pour la restauration des dépendances
COPY ["Services/Jobs.Api/jobs.api.csproj", "Services/Jobs.Api/"]
COPY ["Foundation/Events/Events.csproj", "Foundation/Events/"]

RUN dotnet restore "Services/Jobs.Api/jobs.api.csproj"
COPY . .
WORKDIR "/src/Services/Jobs.Api"
RUN dotnet build "jobs.api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "jobs.api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "jobs.api.dll"]