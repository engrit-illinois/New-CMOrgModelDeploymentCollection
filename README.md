# Summary

This is a module that takes a target application name, creates _standardized_ collections based, and deploys the target application to those collections.  
The org standards being implemented are documented here: https://uofi.atlassian.net/wiki/spaces/engritprivate/pages/36185162/MECM+-+Org+shared+collections+and+deployments?src=search.  
This is not official MECM terminology, but we call these "deployment collections" because the collection's sole purpose is to be the single point of deployment for a given app, and any collections which should receive this deployment should simply be added as an include rule in the collection's membership rules. As described on the wiki page above, this prevents the same application from being redundantly deployed to many scattered collections.  

For creating ad-hoc collections with a standardized evaluation schedule, but without any deployments special naming rules, see: https://github.com/engrit-illinois/New-CMOrgModelCollection.  

### Org-specific warning
Note: this module is currently written specifically for use in the College of Engineering of the University of Illinois. It's published mostly for reference and requires refactoring for use in other organizations.  

# Behavior

- By default, the module creates nothing; you must specify one or more of the following switch parameters to create the relevant collection(s)/deployment(s).
  - `-Available`: Creates an Available collection with the `Install` action.
  - `-Required`: Creates a Required collection with the `Install` action.
  - `-Uninstall`: Creates a Required collection with the `Uninstall` action.
- All collections will be created with a standard membership evaluation schedule of 1am daily.  
- All deployments will be configured to respect supersedence, if the app package has supersedence configured. If it doesn't, then you will see a benign warning that supersedence conditions were not met.  
  - Supersedence is preferred. If you must deploy without supersedence, please do so manually.  
- By default, the created collections will have a limiting collection of `UIUC-ENGR-All Systems`, unless the `-ISOnly` switch parameter is specified.  
- Created collections will have a standard name format of `UIUC-ENGR-Deploy <app> (<purpose>)`, unless the `-ISOnly` switch parameter is specified.  
- By default, created collections will show up in the root of `\Assets and Compliance\Overview\Device Collections`.
  - Specifying the `-MoveCollectionsToFolder` switch and `-CollectionsFolder` parameter will automatically move (all) the created collections to the specified folder.
  - For org-level collections, the appropriate folder is `\DeviceCollection\UIUC-ENGR\.Org shared collections\Deployments`.
  - For IS collections, the appropriate folder is `\DeviceCollection\UIUC-ENGR\Instructional\Deployment Collections\Software\Installs`.
- Note: The target app must be distributed to your distribution point before running this module to create collections. If it's not, the collections will be created, but the deployments to those collections will not. If this happens, simply delete the newly-created collections, distribute the app, and run the module again.

# Requirements
- Only supports PowerShell 5.1.

# Example usage

1. Download `New-CMOrgModelDeploymentCollection.psm1` to the appropriate subdirectory of your PowerShell [modules directory](https://github.com/engrit-illinois/how-to-install-a-custom-powershell-module).
2. Make sure to distribute the app to your DPs/DP group first.
3. Run it, e.g.: `New-CMOrgModelDeploymentCollection -App "Slack - Latest" -Available`
4. Take note of the output logged to the console.

# Parameters

### -App
Required string.  
The exact name of the application package for which to create collections and which to deploy to those collections.  
Supports Tab-Completion, though it can take a while depending on your MECM environment.  
Recommend the following workflow:  
1. `Prep-MECM`
2. Start typing your partial desired result.
3. Tab.
4. Ctrl-Space to display the full list.
5. Navigate the list with arrow keys and select your desired application.

### -isAppGroup
Optional switch.  
If specified, the module will create a new Application Group deployment, rather than a deployment for just an Application.

### -ISOnly
Optional switch.  
If specified, the behavior will change per the following:
- The created collections will have a name format of `UIUC-ENGR-IS Deploy <app> (<purpose>)` instead of `UIUC-ENGR-Deploy <app> (<purpose>)`.  
- The created collections will have a limiting collection of `UIUC-ENGR-Instructional`, instead of `UIUC-ENGR-All Systems`.

### -Available
Optional switch.  
If specified, an "Available" deployment/collection with the "Install" action will be created.  
Collection will be named like `UIUC-ENGR-IS Deploy <app> (Available)`.  

### -Required
Optional switch.  
If specified, a "Required" deployment/collection with the "Install" action will be created.  
Collection will be named like `UIUC-ENGR-IS Deploy <app> (Required)`.  

### -Uninstall
Optional switch.  
If specified, a "Required" collection/deployment with the "Uninstall" action will be created.  
Collection will be named like `UIUC-ENGR-IS Uninstall <app> (Required)`.  

### -AutoCloseExecutable
Optional switch.  
If specified, the created deployment will have the Install Behavior setting enabled, which will automatically stop the process specified on the "Install Behavior" tab of the given application deployment.  
Only valid for Required deployments.

### -MoveCollectionsToFolder
Optional string.  
If specified, (all of) the created collections will be moved to the folder specified, after their deployment has been created.  
The specified value should look something like `\DeviceCollection\UIUC-ENGR\.Org shared collections\Deployments\...`.  
The actual folder path which gets used is based on the specified path value as well as the value of `-SiteCode`, e.g. `MP0:\DeviceCollection\UIUC-ENGR\etc...`.  

### -MoveCollectionsToISFolder
Optional switch.  
If specified, (all of) the created collections will be moved to the folder specified by `-ISCollectionsFolder`, after their deployment has been created.  
Has no effect if `-MoveCollectionsToFolder` is specified.  

### -ISCollectionsFolder
Optional string.  
The folder to which created collections will be moved, if `-MoveCollectionsToISFolder` is specified.  
Default is `\DeviceCollection\UIUC-ENGR\Instructional\Deployment Collections\Software\Installs`.  

### -Prefix
Optional string.  
Specifies the prefix which the script assumes that all collections and apps have.  
Default value is `UIUC-ENGR-`.  
Script behavior is undefined if your unit's collections/deployments do not use a consistent prefix.  
This prefix methodology is probably somewhat unique to the mutli-tenant design of the UofI MECM infrastructure.  

### - DeploymentDelaySec
Optional integer.  
The number of seconds to wait after creating a collection to deploy the app to that collection.  
Default is `10`.  
If you are getting errors with deployments, raise this value to e.g. `30` or so. It's possible MECM is being slow and not recognizing that the newly created collection exists before the script tries to deploy to it.  

### -SiteCode
Optional string. Recommend leaving default.  
The site code of the MECM site to connect to.  
Default is `MP0`.  

### -Provider
Optional string. Recommend leaving default.  
The SMS provider machine name.  
Default is `sccmcas.ad.uillinois.edu`.  

### -CMPSModulePath
Optional string. Recommend leaving default.  
The path to the ConfigurationManager Powershell module installed on the local machine (as part of the admin console).  
Default is `$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1`.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
