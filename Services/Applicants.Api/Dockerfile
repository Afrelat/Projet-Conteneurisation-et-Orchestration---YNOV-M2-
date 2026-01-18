FROM mcr.microsoft.com/dotnet/core/aspnet:2.1-stretch-slim AS base
WORKDIR /app
EXPOSE 80

FROM mcr.microsoft.com/dotnet/core/sdk:2.1-stretch AS build
WORKDIR /src
# On copie d'abord les .csproj pour optimiser le cache Docker
COPY ["Services/Applicants.Api/applicants.api.csproj", "Services/Applicants.Api/"]
COPY ["Foundation/Events/Events.csproj", "Foundation/Events/"] 

RUN dotnet restore "Services/Applicants.Api/applicants.api.csproj"
COPY . .
WORKDIR "/src/Services/Applicants.Api"
RUN dotnet build "applicants.api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "applicants.api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "applicants.api.dll"]