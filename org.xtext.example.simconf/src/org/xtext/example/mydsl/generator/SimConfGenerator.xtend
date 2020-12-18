package org.xtext.example.mydsl.generator

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.nio.file.Files
import java.nio.file.Path
import org.eclipse.core.resources.ResourcesPlugin
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.example.mydsl.domainmodel.Config
import org.xtext.example.mydsl.domainmodel.Domainmodel
import org.xtext.example.mydsl.domainmodel.FileBasedInput
import org.xtext.example.mydsl.domainmodel.GeneratorInput
import org.xtext.example.mydsl.domainmodel.GeneratorType
import org.xtext.example.mydsl.domainmodel.Input
import org.xtext.example.mydsl.domainmodel.Mode
import org.xtext.example.mydsl.domainmodel.Output
import org.xtext.example.mydsl.domainmodel.Report
import org.xtext.example.mydsl.domainmodel.Routing
import org.xtext.example.mydsl.domainmodel.Simulator
import org.xtext.example.mydsl.domainmodel.Time

class SimConfGenerator extends AbstractGenerator {
	var String path
	var Mode mode
	var String scenarioConvertPath

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val wsRoot = ResourcesPlugin.workspace.root
		val path = new org.eclipse.core.runtime.Path(fsa.getURI("").toPlatformString(true))
		val file = wsRoot.getFile(path)
		path = file.location.toPortableString
		
		Files.walk(Path.of(this.path))
			.map[it.toFile()]
			.forEach[it.delete()]

		val domainmodel = resource.contents.get(0) as Domainmodel

		mode = domainmodel.mode ?: Mode.SIMPLE
		scenarioConvertPath = domainmodel.scenarioConvertPath ?: "scenario-convert.jar"

		if (mode == Mode.MOSAIC) {
			fsa.generateFile("scenario_config.json", '''
				{
				    "simulation": {
				        "id": "Generation",
				        "duration": "60s",
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
				        "application": false,
				        "output": false,
				        "sns": false,
				        "cell": false,
				        "sumo": «domainmodel.config.findFirst[it.name == Simulator.SUMO] === null ? "true" : "false"»
				    }
				}					
			''')

			fsa.generateFile("mapping/mapping_config.json", '''
				{
				    "prototypes": [
				        {
				            "name": "car",
				            "accel": 2.6,
				            "decel": 4.5,
				            "length": 5.00,
				            "maxSpeed": 70.0,
				            "minGap": 2.5,
				            "sigma": 0.5,
				            "tau": 1,
				            "deviations": {
				                "speedFactor": 0.1
				            }
				        }
				    ],
				    "vehicles": [
				        {
				            "startingTime": 1.0,
				            "targetFlow": 6000,
				            "maxNumberVehicles": 400,
				            "route": "1",
				            "types": [
				                {
				                    "name": "car"
				                }
				            ]
				        }
					]
				}
			''')
		}

		for (config : domainmodel.config) {
			if (config.name === Simulator.SUMO) {
				val sumoCfgPath = mode == Mode.MOSAIC ? "sumo/generated.sumocfg" : "generated.sumocfg"
				fsa.generateFile(sumoCfgPath, config.compile)
				
				if(mode == Mode.DOCKER) {
					fsa.generateFile("README.md", '''
					Dockerfile to run SUMO
					======================
					
					build
					-----
					
					`docker build -t sumo:latest .`
					
					run
					---
					
					`docker run -it sumo`
					''')
					
					fsa.generateFile("Dockerfile", '''
					FROM ubuntu:bionic
					
					ENV SCRIPT_FOLDER /app
					ENV SUMO_VERSION 1.8.0
					ENV SUMO_HOME /usr/share/sumo
					
					RUN apt-get update && apt-get install -y \
					    cmake \
					    python3-pip \
					    g++ \
					    libxerces-c-dev libfox-1.6-dev libgdal-dev libproj-dev libgl2ps-dev \
					    swig \
					    wget
					RUN wget http://downloads.sourceforge.net/project/sumo/sumo/version%20$SUMO_VERSION/sumo-src-$SUMO_VERSION.tar.gz
					RUN tar xzf sumo-src-$SUMO_VERSION.tar.gz && \
					    mv sumo-$SUMO_VERSION $SUMO_HOME && \
					    rm sumo-src-$SUMO_VERSION.tar.gz
					
					RUN cd $SUMO_HOME  && \
					    mkdir build/cmake-build && cd build/cmake-build  && \
					    cmake ../..  && \
					    make -j$(nproc)
					
					ENV PATH "$PATH:/$SUMO_HOME/bin"
					
					WORKDIR $SCRIPT_FOLDER
										
					COPY . .
					''')
				}
			}
		}
	}

	def compile(Config config) '''
		«IF mode != Mode.MOSAIC »
			<?xml version="1.0" encoding="UTF-8"?>
		«ENDIF»
		
		<configuration
			«IF mode != Mode.MOSAIC »
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://sumo.dlr.de/xsd/sumoConfiguration.xsd"
			«ENDIF»
		>
			
			«config.input.compile»
		
			«config.output.compile»
		
			«config.time.compile»
		
			«config.routing.compile»
		
			«config.report.compile»
		</configuration>
	'''

	def compile(Input input) {
		if (input === null) {
			return "";
		}

		if (input.input instanceof FileBasedInput) {
			var fileInput = input.input as FileBasedInput
			return '''
				<input>
					«IF fileInput.netFile !== null »
						<net-file value="«fileInput.netFile»"/>
					«ENDIF»
					«IF fileInput.routeFiles !== null »
						<route-files value="«fileInput.routeFiles.list.join(",")»"/>
					«ENDIF»
					«IF fileInput.additionalFiles !== null »
						<additional-files value="«fileInput.additionalFiles.list.join(",")»"/>
					«ENDIF»
				</input>
			'''
		} else {
			val NET_FILE = path + (mode == Mode.MOSAIC ? "/sumo/generated.net.xml" : "/generated.net.xml")
			val ROUTE_FILE = path + (mode == Mode.MOSAIC ? "/sumo/generated.rou.xml" : "/generated.rou.xml")
			if(mode == Mode.MOSAIC) {
				new File(path + "/sumo").mkdir()
			}
			
			val generatorInput = input.input as GeneratorInput
			val type = generatorInput.type
			val size = generatorInput.size

			// Net
			val generationProcess = switch type {
				case GeneratorType.GRID:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--grid", "--grid.number", String.valueOf(size)).
						start()
				case GeneratorType.RANDOM:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--rand", "--rand.iterations",
						String.valueOf(size)).start()
				case GeneratorType.SPIDER:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--spider", "--spider.arm-number",
						String.valueOf(size)).start()
			}

			val generatorOutput = new BufferedReader(new InputStreamReader(generationProcess.errorStream));
			
			generatorOutput.readLine()

			while (generationProcess.alive) {
			}

			var message = "";
			var line = "";
			while ((line = generatorOutput.readLine()) !== null) {
				message = message + line + "\n";
			}
			if (message.contains("Quitting (on error)")) {
				throw new RuntimeException("Error generating a network: " + message);
			}

			// Trips
			if(mode == Mode.MOSAIC) {
				val tripsProcess = new ProcessBuilder("java", "-jar", scenarioConvertPath,
					"--sumo2db", "-d", path + "/application/generated.db", "-i", ROUTE_FILE
				).start()

				val tripsOutput = new BufferedReader(new InputStreamReader(tripsProcess.errorStream));
	
				while (tripsProcess.alive) {
				}
	
				message = "";
				line = "";
				while ((line = tripsOutput.readLine()) !== null) {
					message = message + line + "\n";
				}
				if (!message.empty) {
					throw new RuntimeException(message);
				}
			} else {
				val tripsProcess = new ProcessBuilder(System.getenv("SUMO_HOME") + "/tools/randomTrips.py", "-o",
				ROUTE_FILE, "-n", NET_FILE).start()

				val tripsOutput = new BufferedReader(new InputStreamReader(tripsProcess.errorStream));
	
				while (tripsProcess.alive) {
				}
	
				message = "";
				line = "";
				while ((line = tripsOutput.readLine()) !== null) {
					message = message + line + "\n";
				}
				if (message.contains("Quitting (on error)")) {
					throw new RuntimeException(message);
				}
			}

			return '''
				<input>
					<net-file value="«NET_FILE»"/>
					<route-files value="«ROUTE_FILE»"/>
				</input>
			'''
		}
	}

	def compile(Output output) {
		if (output === null) {
			return ""
		}

		return '''
			<output>
				«IF output.statisticFile !== null »
					<statistic-output value="«output.statisticFile»"/>
				«ENDIF»
				«IF output.summaryFile !== null »
					<summary-output value="«output.summaryFile»"/>
				«ENDIF»
				«IF output.humanReadable »
					<human-readable-time value="true"/>
				«ENDIF»
			</output>
		'''
	}

	def compile(Time time) {
		if (time === null) {
			return ""
		}

		return '''
			<time>
				<begin value="«time.start»"/>
				«IF time.end > 0 »
					<end value="«time.end»"/>
				«ENDIF»
				«IF time.steplength > 0 »
					<step-length value="«time.steplength»"/>
				«ENDIF»
			</output>
		'''
	}

	def compile(Routing routing) {
		if (routing === null) {
			return ""
		}

		return '''
			<routing>
				<routing-algorithm value="«routing.algorithm !== null ? routing.algorithm.literal : "dijkstra"»"/>
			</routing>
		'''
	}

	def compile(Report report) {
		if (report === null) {
			return ""
		}

		return '''
			<report>
				<verbose value="«report.verbose ? "true" : "false"»"/>
				«IF report.logFile !== null»
					<log value="«report.logFile»"/>
				«ENDIF»
			</report>
		'''
	}
}
