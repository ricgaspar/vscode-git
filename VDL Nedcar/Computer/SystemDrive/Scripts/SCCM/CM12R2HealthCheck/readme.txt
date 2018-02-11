Running the tool

The tool contain 2 PowerShell script files and 2 xml files (settings files).

xml – has information about queries to run in the environment, it is divided in 5 sections
section 1 is to report/collect information about each site.
section 2 is to report/collect information about each server in the environment
section 3 is to report/collect information about each database server
section 4 is to report/collect summary information about the SCCM environment
section 5 is to report/collect detailed information about the SCCM environment
ps1 – collect data from the environment and write the return in a xml format
ps1 – export the collected data for a word format
xml – has information about messages to write as well as possible solutions
When running the script, you need to specify some parameters, however, if you don’t specify the parameters it will ask you for the required information or use the default settings. The following list shows what parameters can be used on each script:

ps1
Smsprovider – SMS Provider address (can be IP, Netbios name or FQDN name).
NumberofDays – how far back the tool will check for problems. Default is 7 days
Healthcheckfilename – name of the query xml file – default is cm12r2healthcheck.xml
Healthcheckdebug – print log messages on the screen – default true
ps1
Reportfolder – full path for the collected folder
detailed – report will export section 5. Default true
Healthcheckfilename – name of the query xml file – default is cm12r2healthcheck.xml
Healthcheckdebug – print log messages on the screen – default true