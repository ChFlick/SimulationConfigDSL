package org.xtext.example.mydsl.generator

import java.io.BufferedReader
import java.io.InputStreamReader
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.example.mydsl.domainmodel.Config
import org.xtext.example.mydsl.domainmodel.FileBasedInput
import org.xtext.example.mydsl.domainmodel.GeneratorInput
import org.xtext.example.mydsl.domainmodel.GeneratorType
import org.xtext.example.mydsl.domainmodel.Input
import org.xtext.example.mydsl.domainmodel.Output
import org.xtext.example.mydsl.domainmodel.Report
import org.xtext.example.mydsl.domainmodel.Routing
import org.xtext.example.mydsl.domainmodel.Simulator
import org.xtext.example.mydsl.domainmodel.Time

class SimConfGenerator extends AbstractGenerator {
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		for (config : resource.getAllContents().toIterable.filter(Config)) {
			if (config.name === Simulator.SUMO) {
				fsa.generateFile("run.sumocfg", config.compile)
			}
		}
	}

	def compile(Config config) '''
		<?xml version="1.0" encoding="UTF-8"?>
		
		<configuration xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://sumo.dlr.de/xsd/sumoConfiguration.xsd">
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
			val NET_FILE = "generated.net.xml"
			val TRIP_FILE = "generated.trips.xml"
			val generatorInput = input.input as GeneratorInput
			val type = generatorInput.type
			val size = generatorInput.size

			// Net
			val generationProcess = switch type {
				case GeneratorType.GRID:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--grid", "--grid.number", String.valueOf(size)).
						start()
				case RANDOM:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--rand", "--rand.iterations",
						String.valueOf(size)).start()
				case SPRIDER:
					new ProcessBuilder("netgenerate", "-o", NET_FILE, "--spider", "--spider.arm-number",
						String.valueOf(size)).start()
			}

			val generatorOutput = new BufferedReader(new InputStreamReader(generationProcess.errorStream));

			while (generationProcess.alive) {
			}

			var message = "";
			var line = "";
			while ((line = generatorOutput.readLine()) !== null) {
				message = message + line + "\n";
			}
			if (message.contains("Quitting (on error)")) {
				throw new RuntimeException(message);
			}

			// Trips
			val tripsProcess = new ProcessBuilder(System.getenv("SUMO_HOME") + "/tools/randomTrips.py", "-o", TRIP_FILE,
				"-n", NET_FILE).start()

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
					<net-file value="«NET_FILE»"/>
					<route-files value="«TRIP_FILE»"/>
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
