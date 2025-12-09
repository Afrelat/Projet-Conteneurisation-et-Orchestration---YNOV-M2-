FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["src/Applicants.Api/Applicants.Api.csproj", "Applicants.Api/"]
RUN dotnet restore "Applicants.Api/Applicants.Api.csproj"
COPY src/Applicants.Api/ Applicants.Api/
WORKDIR "/src/Applicants.Api"
RUN dotnet build "Applicants.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Applicants.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/health || exit 1

ENTRYPOINT ["dotnet", "Applicants.Api.dll"]
