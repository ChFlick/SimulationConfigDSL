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
}
