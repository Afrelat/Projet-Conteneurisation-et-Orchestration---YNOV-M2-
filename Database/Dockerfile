FROM mcr.microsoft.com/mssql/server:2017-latest
ENV SA_PASSWORD=Pass@word
ENV ACCEPT_EULA=Y

# On indique à Docker d'aller chercher les fichiers dans le dossier Database
COPY Database/entrypoint.sh entrypoint.sh
COPY Database/SqlCmdStartup.sh SqlCmdStartup.sh
COPY Database/SqlCmdScript.sql SqlCmdScript.sql

RUN chmod +x ./SqlCmdStartup.sh
CMD ["/bin/bash", "./entrypoint.sh"]