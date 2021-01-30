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
import org.xtext.example.mydsl.domainmodel.Processing
import java.nio.file.StandardCopyOption

class SimConfGenerator extends AbstractGenerator {
	var String path
	var Mode mode

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val wsRoot = ResourcesPlugin.workspace.root
		val path = new org.eclipse.core.runtime.Path(fsa.getURI("").toPlatformString(true))
		val file = wsRoot.getFile(path)
		path = file.location.toPortableString

		// Ensure that the src-gen folder is there
		fsa.generateFile("empty", "")

		if (Files.isDirectory(Path.of(this.path))) {
			Files.walk(Path.of(this.path))
				.map[it.toFile()]
				.forEach[it.directory ? FileUtils.deleteDir(it) : it.delete()]
		}

		val domainmodel = resource.contents.get(0) as Domainmodel

		mode = domainmodel.mode ?: Mode.SIMPLE

		for (config : domainmodel.config) {
			if (config.name === Simulator.SUMO) {
				// Generate static files
				if (mode == Mode.SIMPLE) {
					fsa.generateFile("start-sumo.sh", StaticSumoFiles.START_SH)
					fsa.generateFile("start-sumo-gui.sh", StaticSumoFiles.START_GUI_SH)
					fsa.generateFile("start-sumo-traci.sh", StaticSumoFiles.START_TRACI_SH)
					fsa.generateFile("README.md", StaticSumoFiles.README)
				}

				if (mode == Mode.DOCKER || mode == Mode.DOCKER_TRA_CI) {
					fsa.generateFile("README.md", StaticSumoFiles.getDockerReadme(mode))
					fsa.generateFile("Dockerfile", StaticSumoFiles.getDockerfile(mode))
				}
				
				if (mode == Mode.MOSAIC || mode == Mode.MOSAIC_DOCKER) {
					Files.createDirectories(Path.of(this.path.toString() + "/mapping"))
					Files.createDirectory(Path.of(this.path.toString() + "/sumo"))
					Files.createDirectory(Path.of(this.path.toString() + "/application"))
					fsa.generateFile("scenario_config.json", StaticMosaicFiles.SCENARIO_CONFIG)
					fsa.generateFile("runtime.json", StaticMosaicFiles.RUNTIME_JSON)
					fsa.generateFile("mapping/mapping_config.json", StaticMosaicFiles.MAPPING_CONFIG)
					fsa.generateFile("application/application_config.json", StaticMosaicFiles.APPLICATION_CONFIG)
				}
				
				if(mode == Mode.MOSAIC) {
					fsa.generateFile("README.md", StaticMosaicFiles.README)
				}
				
				if(mode == Mode.MOSAIC_DOCKER) {
					fsa.generateFile("Dockerfile", StaticMosaicFiles.DOCKERFILE)
					fsa.generateFile("README.md", StaticMosaicFiles.README_DOCKER)
				}
				
				// Generate the actual sumocfg
				val sumoCfgPath = mode == Mode.MOSAIC || mode == Mode.MOSAIC_DOCKER ? "sumo/generated.sumocfg" : "generated.sumocfg"
				fsa.generateFile(sumoCfgPath, config.compile)
				
			}
		}
	}

	def compile(Config config) '''
		<configuration
			« IF mode != Mode.MOSAIC »
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
				xsi:noNamespaceSchemaLocation="http://sumo.dlr.de/xsd/sumoConfiguration.xsd"
			« ENDIF »
		>
			
			«config.input.compile»
		
			«config.output.compile»
			
			«config.processing.compile»
		
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

			if (mode != Mode.SIMPLE) {
				val targetPath = mode == Mode.MOSAIC || mode == Mode.MOSAIC_DOCKER ? path + "/sumo/" : "path" + "/"
				
				if (fileInput.netFile !== null) {
					if (fileInput.netFile.indexOf("/") > -1) {
						Files.copy(
							Path.of(fileInput.netFile),
							Path.of(targetPath + new File(fileInput.netFile).name),
							StandardCopyOption.REPLACE_EXISTING
						)
					}

					fileInput.routeFiles.list.forEach [
						if (it.indexOf("/") > -1) {
							Files.copy(
								Path.of(it),
								Path.of(targetPath + new File(it).name),
								StandardCopyOption.REPLACE_EXISTING
							)
						}
					]

					fileInput.additionalFiles.list.forEach [
						if (it.indexOf("/") > -1) {
							Files.copy(
								Path.of(it),
								Path.of(targetPath + new File(it).name),
								StandardCopyOption.REPLACE_EXISTING
							)
						}
					]

					return '''
						<input>
							«IF fileInput.netFile !== null »
								<net-file value="« new File(fileInput.netFile).name»"/>
							«ENDIF»
							«IF fileInput.routeFiles !== null »
								<route-files value="«fileInput.routeFiles.list.map[new File(it).name].join(",")»"/>
							«ENDIF»
							«IF fileInput.additionalFiles !== null »
								<additional-files value="«fileInput.additionalFiles.list.map[new File(it).name].join(",")»"/>
							«ENDIF»
						</input>
					'''

				}
			}

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
			val localPath = mode == Mode.MOSAIC || mode == Mode.MOSAIC_DOCKER ?  path + "/sumo" : path
			val NET_FILE = localPath + "/" + NET_NAME
			val ROUTE_FILE = localPath + "/" + ROUTE_NAME

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
					«IF mode == Mode.DOCKER || mode == Mode.DOCKER_TRA_CI ||
						mode == Mode.MOSAIC || mode == Mode.MOSAIC_DOCKER »
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
			</time>
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

	def compile(Processing processing) {
		if (processing === null) {
			return ""
		}

		return '''
			<processing>
				<scale value="«processing.scale > 0.0 ? processing.scale»"/>
			</processing>
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
