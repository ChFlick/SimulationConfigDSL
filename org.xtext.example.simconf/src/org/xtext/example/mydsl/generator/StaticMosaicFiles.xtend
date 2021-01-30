package org.xtext.example.mydsl.generator

class StaticMosaicFiles {
	public static final String RUNTIME_JSON = '''
		{
		    "threads": 1,
		    "federates": [
		    	{
		    	       "id": "mapping",
		    	       "classname": "org.eclipse.mosaic.fed.mapping.ambassador.MappingAmbassador",
		    	       "configuration": "mapping_config.json",
		    	       "priority": 50,
		    	       "host": "local",
		    	       "port": 0,
		    	       "deploy": false,
		    	       "start": false,
		    	       "subscriptions": [
		    	           "VehicleRoutesInitialization",
		    	           "ScenarioTrafficLightRegistration",
		    	           "ScenarioVehicleRegistration"
		    	       ],
		    	       "javaClasspathEntries": []
		    	   },
		    	   {
		    	       "id": "application",
		    	       "classname": "org.eclipse.mosaic.fed.application.ambassador.ApplicationAmbassador",
		    	       "configuration": "application_config.json",
		    	       "priority": 50,
		    	       "host": "local",
		    	       "port": 0,
		    	       "deploy": false,
		    	       "start": false,
		    	       "subscriptions": [
		    	           "RsuRegistration",
		    	           "TmcRegistration",
		    	           "ServerRegistration",
		    	           "ChargingStationRegistration",
		    	           "TrafficLightRegistration",
		    	           "VehicleRegistration",
		    	           "ApplicationInteraction",
		    	           "ChargingStationUpdates",
		    	           "ChargingDenialResponse",
		    	           "VehicleElectricityUpdates",
		    	           "VehicleRouteRegistration",
		    	           "V2xMessageReception",
		    	           "V2xFullMessageReception",
		    	           "V2xMessageAcknowledgement",
		    	           "EnvironmentSensorUpdates",
		    	           "SumoTraciResponse",
		    	           "TrafficDetectorUpdates",
		    	           "TrafficLightUpdates",
		    	           "VehicleUpdates",
		    	           "VehicleRoutesInitialization",
		    	           "VehicleTypesInitialization",
		    	           "VehicleSeenTrafficSignsUpdate"
		    	       ],
		    	   	   "javaClasspathEntries": []
		    	   },
		    	   {
		    	       "id": "sumo",
		    	       "classname": "org.eclipse.mosaic.fed.sumo.ambassador.SumoScenarioAmbassador",
		    	       "priority": 50,
		    	       "host": "local",
		    	       "port": 0,
		    	       "deploy": true,
		    	       "start": true,
		    	       "subscriptions": [
		    	           "VehicleSlowDown",
		    	           "VehicleRouteChange",
		    	           "VehicleLaneChange",
		    	           "TrafficLightStateChange",
		    	           "VehicleStop",
		    	           "VehicleResume",
		    	           "SumoTraciRequest",
		    	           "VehicleDistanceSensorActivation",
		    	           "VehicleParametersChange",
		    	           "VehicleSpeedChange",
		    	           "VehicleFederateAssignment",
		    	           "VehicleUpdates",
		    	           "InductionLoopDetectorSubscription",
		    	           "LaneAreaDetectorSubscription",
		    	           "TrafficLightSubscription"
		    	       ],
		    	       "javaClasspathEntries": []
		    	   },
		    	   {
		    	       "id": "output",
		    	       "classname": "org.eclipse.mosaic.fed.output.ambassador.OutputAmbassador",
		    	       "configuration": "output_config.xml",
		    	       "priority": 50,
		    	       "deploy": false,
		    	       "start": false,
		    	       "subscriptions": [
		    	           "ChargingStationRegistration",
		    	           "RsuRegistration",
		    	           "TrafficLightRegistration",
		    	           "TrafficSignRegistration",
		    	           "VehicleRegistration",
		    	           "ItefLogging",
		    	           "VehicleLaneChange",
		    	           "LanePropertyChange",
		    	           "VehicleRouteChange",
		    	           "TrafficLightStateChange",
		    	           "TrafficSignSpeedLimitChange",
		    	           "TrafficSignLaneAssignmentChange",
		    	           "ChargingStationUpdates",
		    	           "AdHocCommunicationConfiguration",
		    	           "CellularCommunicationConfiguration",
		    	           "V2xMessageRemoval",
		    	           "V2xMessageReception",
		    	           "V2xMessageTransmission",
		    	           "EnvironmentSensorUpdates",
		    	           "VehicleSlowDown",
		    	           "TrafficDetectorUpdates",
		    	           "TrafficLightUpdates",
		    	           "VehicleElectricityUpdates",
		    	           "CellularHandoverUpdates",
		    	           "VehicleUpdates",
		    	           "VehicleRoutesInitialization",
		    	           "VehicleTypesInitialization"
		    	       ],
		    	       "javaClasspathEntries": []
		    	  }
		    ]
		}
	'''

	public static final String SCENARIO_CONFIG = '''
		{
		    "simulation": {
		        "id": "generated",
		        "duration": "1000s",
		        "randomSeed": 268965854,
		        "projection": {
		            "centerCoordinates": {
		                "latitude": 52.23,
		                "longitude": 11.82
		            },
		            "cartesianOffset": {
		                "x": -691174.08,
		                "y": -5789894.65
		            }
		        },
		        "network": {
		            "netMask": "255.255.0.0",
		            "vehicleNet": "10.1.0.0",
		            "rsuNet": "10.2.0.0",
		            "tlNet": "10.3.0.0",
		            "csNet": "10.4.0.0",
		            "serverNet": "10.5.0.0",
		            "tmcNet": "10.6.0.0"
		        }
		    },
		    "federates": {
		        "application": true,
		        "output": true,
		        "sumo": true
		    }
		}
	'''

	public static final String MAPPING_CONFIG = '''
		{
		    "prototypes": [
		       {
		            "name":"car",
		            "applications":[
		            ]
				}
				  ]
		}
	'''
	
	public static final String APPLICATION_CONFIG = '''
	{
	    "navigationConfiguration" : {
	        "type": "no-routing"
	    }
	}
	'''

	public static final String DOCKERFILE = '''
		FROM adoptopenjdk/openjdk11
		
		ENV WORKDIR /mosaic
		
		RUN apt-get update && \
			apt-get install -y software-properties-common && \ 
			add-apt-repository ppa:sumo/stable && \
			apt-get update && \	
				apt-get install -y \
				  wget \
				  unzip \
				  sumo
		
		WORKDIR $WORKDIR
		
		RUN wget https://www.dcaiti.tu-berlin.de/research/simulation/download/get/eclipse-mosaic-20.0.zip \
			&& unzip eclipse-mosaic-20.0.zip \
			&& rm eclipse-mosaic-20.0.zip \
			&& chmod +x ./mosaic.sh
			
		COPY . $WORKDIR/mosaic/scenarios/Generated
			
		CMD $WORKDIR/mosaic.sh -s Generated
	'''

	public static final String README = '''
		# Generated SUMO Scenario running with MOSAIC using the SumoScenarioAmbassador
		To run the scenario with MOSAIC you must first copy all the scenario files into the MOSAIC scenario folder.
		This should usually be `<path-to-mosaic-executable>/scenarios/<scenario-name>`
		
		When the scenario is placed correctly, you can run it using 
		```
		./mosaic.sh -s Generated --runtime ./scenarios/Generated/runtime.json
		```
	'''

	public static final String README_DOCKER = '''
		# Dockerfile to run the SUMO Scneario with MOSIAC using the SumoScenarioAmbassador
					
		## build						
		To build the docker image run:
		```
		docker build -t mosaic:latest .
		```
		
		## run
		To execute the docker image after it is built run:						
		```
		docker run mosaic
		```
		If you like to persist the logs of the simulation you can achieve that using
		```
		docker run -v $pwd/logs:/mosaic/logs mosaic
		```
	'''
}
