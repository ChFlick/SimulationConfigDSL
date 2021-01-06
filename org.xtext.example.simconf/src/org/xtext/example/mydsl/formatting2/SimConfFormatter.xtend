/*
 * generated by Xtext 2.23.0
 */
package org.xtext.example.mydsl.formatting2

import com.google.inject.Inject
import org.eclipse.xtext.formatting2.AbstractFormatter2
import org.eclipse.xtext.formatting2.IFormattableDocument
import org.xtext.example.mydsl.domainmodel.Config
import org.xtext.example.mydsl.domainmodel.Domainmodel
import org.xtext.example.mydsl.services.SimConfGrammarAccess
import org.xtext.example.mydsl.domainmodel.Input
import org.eclipse.emf.ecore.EObject
import org.xtext.example.mydsl.domainmodel.Time
import org.xtext.example.mydsl.domainmodel.Output
import org.eclipse.xtext.formatting2.internal.HiddenRegionFormatting
import org.xtext.example.mydsl.domainmodel.GeneratorInput
import org.xtext.example.mydsl.domainmodel.FileBasedInput
import org.xtext.example.mydsl.domainmodel.Routing
import org.xtext.example.mydsl.domainmodel.Report

class SimConfFormatter extends AbstractFormatter2 {

	@Inject extension SimConfGrammarAccess

	def dispatch void format(Domainmodel domainmodel, extension IFormattableDocument document) {
		for (config : domainmodel.config) {
			interior(
				config.regionFor.keyword("{").prepend[oneSpace].append[newLine],
				config.regionFor.keyword("}"),
				[indent]
			)

			config.input.format
			config.output.format
			config.time.format
			config.routing.format
			config.report.format
		}
	}

	def dispatch void format(Input input, extension IFormattableDocument document) {
		interior(
			input.regionFor.keyword("{").prepend[oneSpace].append[newLine],
			input.regionFor.keyword("}"),
			[indent]
		)

		val inputValue = input.input;
		if (input.input instanceof FileBasedInput) {
			var fileInput = input.input as FileBasedInput
			fileInput.regionFor.assignment(fileBasedInputAccess.netFileAssignment_1_0_1).append[newLine]
			fileInput.regionFor.assignment(fileBasedInputAccess.routeFilesAssignment_1_1_1).append[newLine]
			fileInput.regionFor.assignment(fileBasedInputAccess.additionalFilesAssignment_1_2_1).append[newLine]
		} else {
			var generatorInput = input.input as GeneratorInput
		}

		input.append[setNewLines(1, 1, 2)]
	}

	def dispatch void format(Output output, extension IFormattableDocument document) {
		interior(
			output.regionFor.keyword("{").prepend[oneSpace].append[newLine],
			output.regionFor.keyword("}"),
			[indent]
		)

		output.append[setNewLines(1, 1, 2)]
	}

	def dispatch void format(Time time, extension IFormattableDocument document) {
		interior(
			time.regionFor.keyword("{").prepend[oneSpace].append[newLine],
			time.regionFor.keyword("}"),
			[indent]
		)

		time.append[setNewLines(1, 1, 2)]
	}

	def dispatch void format(Routing routing, extension IFormattableDocument document) {
		interior(
			routing.regionFor.keyword("{").prepend[oneSpace].append[newLine],
			routing.regionFor.keyword("}"),
			[indent]
		)

		routing.append[setNewLines(1, 1, 2)]
	}

	def dispatch void format(Report report, extension IFormattableDocument document) {
		interior(
			report.regionFor.keyword("{").prepend[oneSpace].append[newLine],
			report.regionFor.keyword("}"),
			[indent]
		)

		report.append[setNewLines(1, 1, 2)]
	}
}