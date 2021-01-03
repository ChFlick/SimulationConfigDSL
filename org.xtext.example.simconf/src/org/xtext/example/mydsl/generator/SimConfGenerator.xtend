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

		// Ensure that the src-gen folder is there
		fsa.generateFile("empty", "")

		if (Files.isDirectory(Path.of(this.path))) {
			Files.walk(Path.of(this.path)).map[it.toFile()].forEach[it.delete()]
		}

		val domainmodel = resource.contents.get(0) as Domainmodel

		mode = domainmodel.mode ?: Mode.SIMPLE
		scenarioConvertPath = domainmodel.scenarioConvertPath ?: "scenario-convert.jar"

		for (config : domainmodel.config) {
			if (config.name === Simulator.SUMO) {
				if (mode == Mode.SIMPLE) {
					fsa.generateFile("start-sumo.sh", '''
						#!/bin/bash
						sumo -c ./generated.sumocfg
					''')
					fsa.generateFile("start-sumo-gui.sh", '''
						#!/bin/bash
						sumo-gui -c ./generated.sumocfg
					''')

					fsa.generateFile("start-sumo-traci.sh", '''
						#!/bin/bash
						sumo -c ./generated.sumocfg --remote-port 8081
					''')

					fsa.generateFile("README.md", '''
						# SUMO Scenario
						- Execute `start-sumo.sh` to run the scenario in SUMO
						- Execute `start-sumo-gui.sh` to run the scenario in SUMO with GUI
						- Execute `start-sumo-traci.sh` to run the scenario in SUMO with a TraCI Server listening on Port `8081`
					''')
				}

				val sumoCfgPath = "generated.sumocfg"
				fsa.generateFile(sumoCfgPath, config.compile)

				if (mode == Mode.DOCKER || mode == Mode.DOCKER_TRA_CI) {
					fsa.generateFile("README.md", '''
						Dockerfile to run SUMO
						======================
						
						build
						-----
						
						`docker build -t sumo:latest .`
						
						run
						---
						
						`docker run -i «IF mode == Mode.DOCKER_TRA_CI» -p 8081:8081 «ENDIF» sumo`
						
						«IF mode == Mode.DOCKER_TRA_CI»
							When the container has started, you can connect your TraCI application at the container on port 8081.
						«ENDIF»								
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
						
						CMD ["sumo","-c","generated.sumocfg"«IF mode == Mode.DOCKER_TRA_CI»,"--remote-port","8081"«ENDIF»]
					''')
				}
			}
		}
	}

	def compile(Config config) '''
		<configuration
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				xsi:noNamespaceSchemaLocation="http://sumo.dlr.de/xsd/sumoConfiguration.xsd"
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
			val NET_NAME = "generated.net.xml"
			val ROUTE_NAME = "generated.rou.xml"
			val NET_FILE = path + "/" + NET_NAME
			val ROUTE_FILE = path + "/" + ROUTE_NAME

			val generatorInput = input.input as GeneratorInput
			val type = generatorInput.type
			val size = generatorInput.size

			// Net
			var seed = 23423
			if (generatorInput.randomSeed > 0) {
				seed = generatorInput.randomSeed
			}

			val generationProcess = switch type {
				case GeneratorType.GRID:
					new ProcessBuilder(
						"netgenerate",
						"-o",
						NET_FILE,
						"--grid",
						"--grid.number",
						String.valueOf(size),
						"--seed",
						Integer.toString(seed)
					).start()
				case GeneratorType.RANDOM:
					new ProcessBuilder(
						"netgenerate",
						"-o",
						NET_FILE,
						"--rand",
						"--rand.iterations",
						String.valueOf(size),
						"--seed",
						Integer.toString(seed)
					).start()
				case GeneratorType.SPIDER:
					new ProcessBuilder(
						"netgenerate",
						"-o",
						NET_FILE,
						"--spider",
						"--spider.arm-number",
						String.valueOf(size),
						"--seed",
						Integer.toString(seed)
					).start()
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

			return '''
				<input>
					«IF mode == Mode.DOCKER || mode == Mode.DOCKER_TRA_CI »
						<net-file value="«NET_NAME»"/>
						<route-files value="«ROUTE_NAME»"/>
					«ELSE»
						<net-file value="«NET_FILE»"/>
						<route-files value="«ROUTE_FILE»"/>
					«ENDIF»
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
				«IF report.logFile !== null && mode !== Mode.DOCKER && mode !== Mode.DOCKER_TRA_CI»
					<log value="«report.logFile»"/>
				«ENDIF»
			</report>
		'''
	}
}
