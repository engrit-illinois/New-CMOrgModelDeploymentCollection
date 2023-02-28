# Script and script documentation home: https://github.com/engrit-illinois/org-shared-mecm-deployments
# Org shared deployment model documentation home: https://wiki.illinois.edu/wiki/display/engritprivate/SCCM+-+Org+shared+collections+and+deployments
# By mseng3

function New-CMOrgModelDeploymentCollection {

	param(
		[Parameter(Position=0,Mandatory=$true)]
		[string]$App,
		
		[switch]$ISOnly,
		
		[switch]$Available,
		
		[switch]$Required,
		
		[switch]$Uninstall,
		
		# Prefix that all unit's apps and collections have
		# This is probably unique to the UofI environment
		# Script assumes this is consistent
		# i.e. "UIUC-ENGR-" assumes all collections and apps have exactly this prefix, and none have a prefix of e.g. "ENGR-UIUC"
		[string]$Prefix="UIUC-ENGR-",
		
		[int]$DeploymentDelaySec=10,
		
		[string]$SiteCode="MP0",
		
		[string]$Provider="sccmcas.ad.uillinois.edu",
		
		[string]$CMPSModulePath="$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1"
	)
	
	function log {
		param(
			[string]$msg,
			[int]$L
		)
		for($i = 0; $i -lt $L; $i += 1) {
			$msg = "    $msg"
		}
		$ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss:ffff"
		Write-Host "[$ts] $msg"
	}

	function Test-SupportedPowershellVersion {
		log "This custom module (and the overall ConfigurationManager Powershell module) only support Powershell v5.1. Checking Powershell version..."
		
		$ver = $Host.Version
		log "Powershell version is `"$($ver.Major).$($ver.Minor)`"." -L 1
		if(
			($ver.Major -eq 5) -and
			($ver.Minor -eq 1)
		) {
			return $true
		}
		return $false
	}
	
	function Prep-MECM {
		log "Preparing connection to MECM..."
		$initParams = @{}
		if((Get-Module ConfigurationManager) -eq $null) {
			# The ConfigurationManager Powershell module switched filepaths at some point around CB 18##
			# So you may need to modify this to match your local environment
			Import-Module $CMPSModulePath @initParams -Scope Global
		}
		if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
			New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $Provider @initParams
		}
		Set-Location "$($SiteCode):\" @initParams
		log "Done prepping connection to MECM." -L 1
	}
	
	function App-Exists {
		log "Checking that specified application exists..."
		$appResult = Get-CMApplication -Fast -Name $App
		if($appResult) {
			log "Result returned." -L 1
			if($appResult.LocalizedDisplayName -eq $App) {
				log "Looks good." -L 1
				$exists = $true
			}
			else {
				log "Result does not contain expected data!" -L 1
				log ($result | Out-String)
			}
		}
		else {
			log "No result was returned! Are you sure this app exists, and is an app (as opposed to a package)?" -L 1
		}
		$exists
	}
	
	function Get-AppName {
		log "Getting name of underlying application..." -L 1
		
		$appName = $App.Replace($Prefix,"")
		$regex = "$($Prefix)-*"
		if($App -match $regex) {
			log "App has `"$Prefix`" prefix. Removing this and taking the core app name: `"$appName`"." -L 2
		}
		else {
			log "App does not have `"$Prefix`" prefix. Probably a campus app." -L 2
		}
		
		log "App name: `"$appName`"." -L 2
		
		$appName
	}
	
	function Get-BaseCollName($appName, $action) {
		
		log "Getting base name of new collection..." -L 1
		
		$collNamePrefix = "$($Prefix)"
		if($ISOnly) {
			log "-ISOnly was specified." -L 2
			$collNamePrefix = "$($Prefix)IS "
		}
		else {
			log "-ISOnly was not specified." -L 2
		}
		
		$collNamePrefixAction = "$($collNamePrefix)Deploy"
		if($action -eq "Uninstall") {
			$collNamePrefixAction = "$($collNamePrefix)Uninstall"
		}
		
		$collNameBase = "$collNamePrefixAction $appName"
		log "New collection's base name will be `"$collNameBase (<purpose>)`"." -L 2
		
		$collNameBase
	}
	
	function Get-LimitingColl {
		log "Getting name of appropriate limiting collection..." -L 1
		
		$limitingColl = "$($Prefix)All Systems"
		if($ISOnly) {
			$limitingColl = "$($Prefix)Instructional"
		}
		
		log "Limiting collection will be `"$limitingColl`"." -L 2
		
		$limitingColl
	}
	
	# Builds schedule object to send to New-CMDeviceCollection
	# Hard coded to be 1am daily, as defined by the design decisions documented on the wiki
	function Get-Sched {
		log "Building schedule object for new collection's membership evaluation schedule (i.e. daily at 1am)..." -L 1
		
		$schedStartDate = Get-Date -Format "yyyy-MM-dd"
		$schedStartTime = "01:00"
		$sched = New-CMSchedule -Start "$schedStartDate $schedStartTime" -RecurInterval "Days" -RecurCount 1
		
		$sched
	}
		
	function New-Coll($type) {
		log "Creating `"$type`" collection/deployment..."
		
		# Define "action" and "purpose" (in MECM parlance) for new deployment
		if($type -eq "Available") {
			$action = "Install"
			$purpose = "Available"
		}
		elseif($type -eq "Required") {
			$action = "Install"
			$purpose = "Required"
		}
		elseif($type -eq "Uninstall") {
			$action = "Uninstall"
			$purpose = "Required"
		}
		else {
			throw "Incorrect type sent to New-Coll function!"
		}
		log "Purpose: `"$purpose`"." -L 1
		log "Action: `"$action`"." -L 1
		
		# Get core app name
		$appName = Get-AppName
		
		# Build base name of collection
		$collNameBase = Get-BaseCollName $appName $action
		
		# Build full name of collection
		$coll = "$collNameBase ($purpose)"
		log "New collection's full name will be `"$coll`"." -L 1
		
		# Get name of appropriate limiting collection
		$limitingColl = Get-LimitingColl
		
		# Build membership evaluation schedule
		$sched = Get-Sched
		
		# Make new collection
		log "Creating new collection: `"$coll`"..." -L 1
		$collResult = New-CMDeviceCollection -Name $coll -LimitingCollectionName $limitingColl -RefreshType "Periodic" -RefreshSchedule $sched
		
		if($collResult) {
			log "Result returned" -L 2
			log "Collection name: `"$($collResult.Name)`"" -L 3
			log "Collection ID: `"$($collResult.CollectionID)`"" -L 3
			log "Limiting collection: `"$($collResult.LimitToCollectionName)`"" -L 3
			if($collResult.Name -eq $coll) {
				log "Looks successful." -L 3
			}
			else {
				log "Result does not contain expected data!" -L 3
				log ($collResult | Out-String)
			}
		}
		else {
			log "No result was returned! Something went wrong :/" -L 2
		}
		
		# Wait to make sure collection is created before trying to deploy to it
		log "Waiting $DeploymentDelaySec seconds before deploying to new collection..." -L 1
		Start-Sleep -Seconds 10
		
		# Make deployment to new collection
		log "Creating deployment..." -L 1
		$depResult = New-CMApplicationDeployment -Name $App -CollectionName $coll -DeployAction $action -DeployPurpose $purpose -UpdateSupersedence $true
		
		if($depResult) {
			log "Result returned" -L 2
			if($depResult.AssignmentName -eq "$($App)_$($coll)_$action") {
				log "Looks successful." -L 3
			}
			else {
				log "Result does not contain expected data!" -L 3
				log ($depResult | Out-String)
			}
		}
		else {
			log "No result was returned! Something went wrong :/" -L 2
		}
	}
	
	function Do-Stuff {
		
		# Check that supported Powershell version is being used
		if(Test-SupportedPowershellVersion) {
			
			$myPWD = $pwd.path
			Prep-MECM
		
			# Check that the specified app exists
			$exists = App-Exists
			
			# TODO: Check if app is distributed
			# https://github.com/engrit-illinois/New-CMOrgModelDeploymentCollection/issues/3
			
			if($exists) {
					
				# Create specified collections/deployments
				if($Available) {
					New-Coll "Available"
				}
				if($Required) {
					New-Coll "Required"
				}
				if($Uninstall) {
					New-Coll "Uninstall"
				}
				
				if((-not $Available) -and (-not $Required) -and (-not $Uninstall)) {
					log "You must specify at least one of the following parameters: -Available, -Required, -Uninstall"
				}
			}
			
			Set-Location $myPWD
		}
	}
	
	Do-Stuff
	log "EOF"
}