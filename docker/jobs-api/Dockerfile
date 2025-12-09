FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Jobs.Api/Jobs.Api.csproj", "Jobs.Api/"]
RUN dotnet restore "Jobs.Api/Jobs.Api.csproj"
COPY src/Jobs.Api/ Jobs.Api/
WORKDIR "/src/Jobs.Api"
RUN dotnet build "Jobs.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Jobs.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "Jobs.Api.dll"]
