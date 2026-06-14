FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY backend/ .

WORKDIR /src/JumpIn.API
RUN dotnet restore "JumpIn.API.csproj"

RUN dotnet build "JumpIn.API.csproj" -c Release -o /app/build

FROM build AS publish
WORKDIR /src/JumpIn.API
RUN dotnet publish "JumpIn.API.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
RUN mkdir -p /app/wwwroot/uploads
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "JumpIn.API.dll"]
