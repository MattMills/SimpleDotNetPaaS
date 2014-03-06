*Note:* This is alpha quality software.


SimpleDotNetPaaS
================

Simplistic implemenation of a .Net PaaS solution using Powershell and HAProxy

This is currently a proof of concept to investigate the possibility of using Powershell, Bash, IIS and HAProxy (on linux) to build a .Net Platform as a Service offering. 

Current capabilities
====================

 * Provision and deprovision site on load balancer
 * Provision and deprovision server->site on load balancer
 * provision and deprovision site->server from container (Zip File ATM)
 * provision and deprovision full site (a-z provision, load balancer, all servers, etc)
 * Scale instance count for site up or down
 * Autoscale based on CPU load


Requirements
============

 * plink.exe (Putty)
 * IIS WebAdministration Commandlets
 * 7zip installed in default path
 * Other stuff I'm forgetting
