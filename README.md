# Summary

This is a module that takes a target application name, creates _standardized_ collections and deploys the target application to those collections.  
This is not official MECM terminology, but we call these "deployment collections" because the collection's sole purpose is to be the single point of deployment for a given app, and any collections which should receive this deployment should simply be added as an include rule in the collection's membership rules. As described on the wiki page above, this prevents the same application from being redundantly deployed to many scattered collections.  

### Behavior

- By default, the module creates two collections, one for an "Available" purpose deployment, and one for a "Required" purpose deployment. This behavior can be changed with the parameters documented below.  
- All collections will be created with a standard membership evaluation schedule of 1am daily.  
- All deployments will be configured to respect supersedence, if the app package has supersedence configured. If it doesn't, then you will see a benign warning that supersedence conditions were not met.  
  - Supersedence is preferred. If you must deploy without supersedence, please do so manually.  
- By default, the created collections will have a limiting collection of `UIUC-ENGR-All Systems`, unless the `-ISOnly` switch parameter is specified.  
- Created collections will have a standard name format of `UIUC-ENGR-Deploy <app> (<purpose>)`, unless the `-ISOnly` switch parameter is specified.  
- Created collections will show up in the root of `\Assets and Compliance\Overview\Device Collections` because the ConfigurationManager Powershell module is incapable of knowing about or manipulating folders. You must manually move them to the appropriate folder using the admin console.  
  - For org-level collections, this is the appropriate subfolder of `\Assets and Compliance\Overview\Device Collections\UIUC-ENGR\Org shared collections\Deployments`.
  - For IS collections, this is `\Assets and Compliance\Overview\Device Collections\UIUC-ENGR\Instructional\Deployment Collections\Software\Installs`.
- Note: The target app must be distributed to your distribution point before running this module to create collections. If it's not, the collections will be created, but the deployments to those collections will not. If this happens, simply delete the newly-created collections, distribute the app, and run the module again.

### Example usage

1. Download `New-CMOrgModelDeploymentCollection.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\New-CMOrgModelDeploymentCollection\New-CMOrgModelDeploymentCollection.psm1`.
2. Make sure to distribute the app to your DPs/DP group first.
3. Run it, e.g.: `New-CMOrgModelDeploymentCollection -App "Slack - Latest"`
4. Take note of the output logged to the console.

### Parameters

#### -App
Required string.  
The exact name of the application package for which to create collections and which to deploy to those collections.  

#### -ISOnly
Optional switch.  
If specified, the behavior will change per the following:
- The created collections will have a name format of `UIUC-ENGR-IS Deploy <app> (<purpose>)` instead of `UIUC-ENGR-Deploy <app> (<purpose>)`.  
- The created collections will have a limiting collection of `UIUC-ENGR-Instructional`, instead of `UIUC-ENGR-All Systems`.

#### -SkipAvailable
Optional switch.  
If specified, creation of the "Available" deployment/collection will be skipped.  

#### -SkipRequired
Optional switch.  
If specified, creation of the "Required" deployment/collection will be skipped.  

#### -Uninstall
Optional switch.  
If specified, skips creation of "Available" and "Required" collections/deployments with "Install" action, and instead creates one "Required" collection/deployment with "Uninstall" action.  
Collection will be named like `UIUC-ENGR-IS Uninstall <app> (Required)`.  

#### -Prefix
Optional string.  
Specifies the prefix which the script assumes that all collections and apps have.  
Default value is `UIUC-ENGR-`.  
Script behavior is undefined if your unit's collections/deployments do not use a consistent prefix.  
This prefix methodology is probably somewhat unique to the mutli-tenant design of the UofI MECM infrastructure.  

#### - DeploymentDelaySec
Optional integer.  
The number of seconds to wait after creating a collection to deploy the app to that collection.  
Default is `10`.  
If you are getting errors with deployments, raise this value to e.g. `30` or so. It's possible MECM is being slow and not recognizing that the newly created collection exists before the script tries to deploy to it.  

#### -SiteCode
Optional string. Recommend leaving default.  
The site code of the MECM site to connect to.  
Default is `MP0`.  

#### -Provider
Optional string. Recommend leaving default.  
The SMS provider machine name.  
Default is `sccmcas.ad.uillinois.edu`.  

#### -CMPSModulePath
Optional string. Recommend leaving default.  
The path to the ConfigurationManager Powershell module installed on the local machine (as part of the admin console).  
Default is `$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1`.  

# Notes
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
